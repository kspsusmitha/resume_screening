import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/firebase_database_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  final FirebaseDatabaseService _databaseService = FirebaseDatabaseService();

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Login for HR and Candidate
  Future<bool> login(String email, String password, UserRole role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _databaseService.loginUser(email, password, role);
      
      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid email or password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Login failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Admin login
  Future<bool> loginAdmin(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _databaseService.loginAdmin(email, password);
      
      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid admin credentials';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Login failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register for HR and Candidate
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
    String? company,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final error = await _databaseService.registerUser(
        email: email,
        password: password,
        name: name,
        role: role,
        phone: phone,
        company: company,
      );

      if (error != null) {
        _errorMessage = error;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Auto-login after registration
      final user = await _databaseService.loginUser(email, password, role);
      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Registration successful but login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Registration failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

