import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/database/database_helper.dart';
import '../../data/models/empleado_model.dart';
import 'package:frontend/core/network/api_client.dart';

class EmployeeProvider with ChangeNotifier {
  final ApiClient _apiClient;
  List<Empleado> _employees = [];
  bool _isLoading = false;
  String? _error;

  EmployeeProvider(this._apiClient);

  List<Empleado> get employees => _employees;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Get Mechanics (Role or Cargo based?)
  List<Empleado> get mechanics => _employees
      .where((e) => e.cargo?.toLowerCase().contains('mecanico') ?? false)
      .toList();
  List<Empleado> get operators => _employees
      .where((e) => e.cargo?.toLowerCase().contains('operador') ?? false)
      .toList();
  List<Empleado> get all => _employees;

  Future<void> loadEmployees() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Try local first
      await _loadLocalEmployees();

      // 2. Fetch from API
      // Using ApiClient which already has baseUrl configured
      final response = await _apiClient.dio.get('/empleados');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _employees = data.map((json) => Empleado.fromJson(json)).toList();

        // Save to local DB
        await _dbHelper.saveEmpleados(data);
      }
    } catch (e) {
      if (e is DioException) {
        _error = 'Error fetching employees: ${e.message}';
      } else {
        _error = 'Error loading employees: $e';
      }
      // If offline, we already loaded local
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadLocalEmployees() async {
    final data = await _dbHelper.getEmpleados();
    _employees = data.map((json) => Empleado.fromJson(json)).toList();
    notifyListeners();
  }

  Future<bool> createEmployee(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        '/empleados',
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201) {
        final newEmployee = Empleado.fromJson(response.data);
        _employees.add(newEmployee);
        // Save just the new one or reload all?
        // Ideally we should adhere to list.
        // Also save to DB
        await _dbHelper.saveEmpleados([response.data]);
        notifyListeners();
        return true;
      } else {
        _error = 'Error creating employee: ${response.statusCode}';
        return false;
      }
    } catch (e) {
      _error = 'Error creating employee: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateEmployee(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.dio.put(
        '/empleados/$id',
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final updatedEmployee = Empleado.fromJson(response.data);
        final index = _employees.indexWhere((e) => e.id == id);
        if (index != -1) {
          _employees[index] = updatedEmployee;
        }
        await _dbHelper.saveEmpleados([response.data]);
        notifyListeners();
        return true;
      } else {
        _error = 'Error updating employee: ${response.statusCode}';
        return false;
      }
    } catch (e) {
      _error = 'Error updating employee: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Empleado? getEmployeeById(int id) {
    try {
      return _employees.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
