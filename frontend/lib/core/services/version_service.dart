import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Modelo que representa la respuesta del endpoint de versiones.
class AppVersionInfo {
  final String latestVersion;
  final String minVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate;

  const AppVersionInfo({
    required this.latestVersion,
    required this.minVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.forceUpdate,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      latestVersion: json['latest_version'] as String? ?? '0.0.0',
      minVersion: json['min_version'] as String? ?? '0.0.0',
      downloadUrl: json['download_url'] as String? ?? '',
      releaseNotes: json['release_notes'] as String? ?? '',
      forceUpdate: json['force_update'] as bool? ?? false,
    );
  }
}

/// Servicio para consultar la versión de la app y comparar con el backend.
class VersionService {
  final Dio _dio;

  VersionService({Dio? dio}) : _dio = dio ?? Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  /// Obtiene la versión actual instalada en el dispositivo.
  Future<PackageInfo> getCurrentVersion() async {
    return PackageInfo.fromPlatform();
  }

  /// Consulta al backend la última versión disponible.
  Future<AppVersionInfo?> checkForUpdates(String baseUrl) async {
    try {
      final url = '$baseUrl/app/version';
      debugPrint('VersionService: Requesting $url');
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        return AppVersionInfo.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('VersionService: Error checking updates: $e');
    }
    return null;
  }

  /// Compara dos versiones semánticas con soporte para pre-release tags.
  /// Soporta formatos: "1.0.0", "0.5.0-alpha", "0.5.0-beta.2", "v0.5.0-rc.1"
  ///
  /// Reglas semver:
  ///   0.5.0-alpha < 0.5.0-beta < 0.5.0-rc.1 < 0.5.0
  ///   (pre-release tiene menor precedencia que la versión normal)
  ///
  /// Retorna:
  ///   1  si a > b
  ///   0  si a == b
  ///  -1  si a < b
  static int compareVersions(String a, String b) {
    // Normalizar: quitar 'v' o 'V' inicial
    a = a.toLowerCase().replaceAll(RegExp(r'^v'), '');
    b = b.toLowerCase().replaceAll(RegExp(r'^v'), '');

    // Separar pre-release tag (todo después del '-')
    final aParts = a.split('-');
    final bParts = b.split('-');

    final aCore = aParts[0];
    final bCore = bParts[0];
    final aPre = aParts.length > 1 ? aParts.sublist(1).join('-') : '';
    final bPre = bParts.length > 1 ? bParts.sublist(1).join('-') : '';

    // Comparar major.minor.patch
    final coreCompare = _compareCore(aCore, bCore);
    if (coreCompare != 0) return coreCompare;

    // Mismo core: comparar pre-release
    // Sin pre-release > con pre-release (0.5.0 > 0.5.0-alpha)
    if (aPre.isEmpty && bPre.isNotEmpty) return 1;
    if (aPre.isNotEmpty && bPre.isEmpty) return -1;
    if (aPre.isEmpty && bPre.isEmpty) return 0;

    return _comparePreRelease(aPre, bPre);
  }

  /// Compara la parte core (major.minor.patch).
  static int _compareCore(String a, String b) {
    final aParts = a.split('.').map(int.tryParse).toList();
    final bParts = b.split('.').map(int.tryParse).toList();
    final maxLen = aParts.length > bParts.length ? aParts.length : bParts.length;

    for (int i = 0; i < maxLen; i++) {
      final aVal = i < aParts.length ? (aParts[i] ?? 0) : 0;
      final bVal = i < bParts.length ? (bParts[i] ?? 0) : 0;
      if (aVal > bVal) return 1;
      if (aVal < bVal) return -1;
    }
    return 0;
  }

  /// Compara identificadores de pre-release según semver.
  /// Orden: alpha < beta < rc < (release)
  /// Números se comparan como enteros, strings léxicamente.
  static int _comparePreRelease(String a, String b) {
    if (a == b) return 0;

    final aIdentifiers = a.split('.');
    final bIdentifiers = b.split('.');
    final maxLen = aIdentifiers.length > bIdentifiers.length
        ? aIdentifiers.length
        : bIdentifiers.length;

    for (int i = 0; i < maxLen; i++) {
      if (i >= aIdentifiers.length) return -1; // más corto = menor
      if (i >= bIdentifiers.length) return 1;

      final aId = aIdentifiers[i];
      final bId = bIdentifiers[i];

      // Ambos numéricos → comparar como enteros
      final aNum = int.tryParse(aId);
      final bNum = int.tryParse(bId);
      if (aNum != null && bNum != null) {
        if (aNum > bNum) return 1;
        if (aNum < bNum) return -1;
        continue;
      }

      // Ambos strings → comparar léxicamente
      // Prioridad conocida: alpha < beta < rc
      final aRank = _preReleaseRank(aId);
      final bRank = _preReleaseRank(bId);
      if (aRank != bRank) return aRank.compareTo(bRank);

      // Fallback: comparación léxica
      final cmp = aId.compareTo(bId);
      if (cmp != 0) return cmp;
    }

    return 0;
  }

  /// Asigna un rank numérico a identificadores comunes de pre-release.
  /// Menor rank = menor precedencia.
  static int _preReleaseRank(String id) {
    switch (id.toLowerCase()) {
      case 'alpha':
      case 'a':
        return 1;
      case 'beta':
      case 'b':
        return 2;
      case 'rc':
      case 'rc1':
        return 3;
      default:
        return 10; // desconocido → mayor que los conocidos
    }
  }
}
