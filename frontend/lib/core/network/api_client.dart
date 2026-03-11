import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/core/constants/api_constants.dart';

class ApiClient {
  static const String _authTokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _deviceNameKey = 'device_name';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final VoidCallback? onUnauthorized;

  Completer<String?>? _refreshCompleter;

  ApiClient({this.onUnauthorized}) {
    _configureTlsPinningIfEnabled();

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _authTokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (_shouldAttemptRefresh(e)) {
            final refreshedToken = await _refreshAccessToken();
            if (refreshedToken != null) {
              try {
                final retryOptions = _buildRetryOptions(
                  original: e.requestOptions,
                  newToken: refreshedToken,
                );
                final response = await _dio.fetch<dynamic>(retryOptions);
                return handler.resolve(response);
              } catch (retryError) {
                debugPrint('ApiClient: retry after refresh failed: $retryError');
              }
            }
          }

          if (e.response?.statusCode == 401) {
            await _clearSessionAndNotify();
          }

          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;

  bool _shouldAttemptRefresh(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode != 401) return false;

    final path = e.requestOptions.path;
    if (path == ApiConstants.login ||
        path == ApiConstants.refresh ||
        path == ApiConstants.logout ||
        path == ApiConstants.logoutAll) {
      return false;
    }

    if (e.requestOptions.extra['retried_after_refresh'] == true) {
      return false;
    }

    return true;
  }

  RequestOptions _buildRetryOptions({
    required RequestOptions original,
    required String newToken,
  }) {
    final headers = Map<String, dynamic>.from(original.headers);
    headers['Authorization'] = 'Bearer $newToken';

    return original.copyWith(
      headers: headers,
      extra: {
        ...original.extra,
        'retried_after_refresh': true,
      },
    );
  }

  Future<String?> _refreshAccessToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();

    try {
      final currentToken = await _storage.read(key: _authTokenKey);
      if (currentToken == null || currentToken.isEmpty) {
        _refreshCompleter!.complete(null);
        return _refreshCompleter!.future;
      }

      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $currentToken',
          },
        ),
      );

      final deviceName =
          (await _storage.read(key: _deviceNameKey)) ?? 'flutter_app';

      final response = await refreshDio.post(
        ApiConstants.refresh,
        data: {'device_name': deviceName},
      );

      if (response.statusCode == 200 && response.data?['token'] != null) {
        final String newToken = response.data['token'].toString();
        await _storage.write(key: _authTokenKey, value: newToken);

        if (response.data?['user'] != null) {
          await _storage.write(
            key: _userDataKey,
            value: jsonEncode(response.data['user']),
          );
        }

        _refreshCompleter!.complete(newToken);
        return _refreshCompleter!.future;
      }

      _refreshCompleter!.complete(null);
      return _refreshCompleter!.future;
    } catch (e) {
      debugPrint('ApiClient: token refresh failed: $e');
      _refreshCompleter!.complete(null);
      return _refreshCompleter!.future;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> _clearSessionAndNotify() async {
    await _storage.delete(key: _authTokenKey);
    await _storage.delete(key: _userDataKey);
    await _storage.delete(key: _deviceNameKey);
    onUnauthorized?.call();
  }

  void _configureTlsPinningIfEnabled() {
    final bool enabled =
        (dotenv.env['TLS_PINNING_ENABLED'] ?? 'false').toLowerCase() == 'true';
    if (!enabled || kIsWeb) return;

    final Set<String> configuredPins =
        (dotenv.env['TLS_PIN_SHA256'] ?? '')
            .split(',')
            .map((e) => e.trim().toUpperCase())
            .where((e) => e.isNotEmpty)
            .toSet();

    if (configuredPins.isEmpty) {
      debugPrint(
        'ApiClient: TLS pinning enabled but TLS_PIN_SHA256 is empty. Skipping pinning.',
      );
      return;
    }

    final Set<String> pinHosts =
        (dotenv.env['TLS_PIN_HOSTS'] ?? '')
            .split(',')
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toSet();

    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient(context: SecurityContext(withTrustedRoots: false));
        client.badCertificateCallback = (cert, host, port) {
          if (pinHosts.isNotEmpty && !pinHosts.contains(host.toLowerCase())) {
            return false;
          }

          final fingerprint = sha256.convert(cert.der).toString().toUpperCase();
          return configuredPins.contains(fingerprint);
        };
        return client;
      },
    );
  }
}
