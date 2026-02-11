import 'package:flutter/foundation.dart';
import 'package:frontend/features/auth/data/models/user_model.dart';
import 'package:frontend/features/auth/data/repositories/user_repository.dart';
import 'package:frontend/core/database/database_helper.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _repository;
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  UserProvider(this._repository);

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUsers({String? role}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _repository.getUsers(role: role);

      // Cachear usuarios localmente para offline (ej. Checklists)
      try {
        final usersJson = _users.map((u) => u.toJson()).toList();
        await DatabaseHelper().saveUsers(usersJson);
      } catch (e) {
        if (kDebugMode) {
          print('Error cacheando usuarios: $e');
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Intentar cargar de local si falla API
      try {
        if (kDebugMode) {
          print('Error API users, intentando local: $e');
        }
        final localData = await DatabaseHelper().getUsers();
        if (localData.isNotEmpty) {
          _users = localData.map((json) => User.fromJson(json)).toList();
          // Si filtramos por rol y estamos offline, filtrar manual
          if (role != null) {
            _users = _users.where((u) => u.role == role).toList();
          }
        } else {
          _error = e.toString();
        }
      } catch (localError) {
        _error = e.toString();
      }

      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createUser(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newUser = await _repository.createUser(data);
      _users.add(newUser);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateUser(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updatedUser = await _repository.updateUser(id, data);
      final index = _users.indexWhere((u) => u.id == id);
      if (index != -1) {
        _users[index] = updatedUser;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteUser(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.deleteUser(id);
      _users.removeWhere((u) => u.id == id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
