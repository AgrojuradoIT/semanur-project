import 'package:flutter/foundation.dart';
import 'package:frontend/features/auth/data/models/user_model.dart';
import 'package:frontend/features/auth/data/repositories/user_repository.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _repository;
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  UserProvider(this._repository);

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _repository.getUsers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
}
