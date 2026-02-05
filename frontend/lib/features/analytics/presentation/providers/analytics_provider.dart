import 'package:flutter/foundation.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:dio/dio.dart';

class AnalyticsProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  Map<String, dynamic>? _summary;
  List<dynamic>? _fuelStats;
  List<dynamic>? _maintenanceStats;

  bool _isLoading = false;
  String? _error;

  AnalyticsProvider(this._apiClient);

  Map<String, dynamic>? get summary => _summary;
  List<dynamic>? get fuelStats => _fuelStats;
  List<dynamic>? get maintenanceStats => _maintenanceStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiClient.dio.get('/analytics/summary'),
        _apiClient.dio.get('/analytics/fuel'),
        _apiClient.dio.get('/analytics/maintenance'),
      ]);

      _summary = results[0].data;
      _fuelStats = results[1].data;
      _maintenanceStats = results[2].data;

      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      _error = e.response?.data['message'] ?? e.message;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
}
