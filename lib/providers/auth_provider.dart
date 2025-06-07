import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/auth_models.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      // Сначала загружаем cookie для API
      await ApiService.loadCookie();
      // Затем загружаем данные пользователя
      await _loadUserData();
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final request = LoginRequest(username: username, password: password);
      final response = await ApiService.login(request);

      if (response.error != null) {
        _setError(response.error);
        _setLoading(false);
        return false;
      }

      if (response.user != null) {
        _user = response.user;
        await _saveUserData();
        _setLoading(false);
        notifyListeners();
        return true;
      }

      _setError('Неизвестная ошибка');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Ошибка подключения к серверу');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(String username, String password, String confirmPassword, String? email) async {
    _setLoading(true);
    _setError(null);

    // Валидация на клиенте
    if (password != confirmPassword) {
      _setError('Пароли не совпадают');
      _setLoading(false);
      return false;
    }

    if (password.length < 6) {
      _setError('Пароль должен содержать минимум 6 символов');
      _setLoading(false);
      return false;
    }

    try {
      final request = RegisterRequest(
        username: username,
        password: password,
        confirmPassword: confirmPassword,
        email: email,
      );
      final response = await ApiService.register(request);

      if (response.error != null) {
        _setError(response.error);
        _setLoading(false);
        return false;
      }

      if (response.user != null) {
        _user = response.user;
        await _saveUserData();
        _setLoading(false);
        notifyListeners();
        return true;
      }

      _setError('Неизвестная ошибка');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Ошибка подключения к серверу');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _setError(null);

    try {
      final request = ResetPasswordRequest(email: email);
      final response = await ApiService.resetPassword(request);

      if (response.error != null) {
        _setError(response.error);
        _setLoading(false);
        return false;
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Ошибка подключения к серверу');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (e) {
      // Игнорируем ошибки при выходе
    }
    
    _user = null;
    await _clearUserData();
    // Cookie очищается в ApiService.logout()
    notifyListeners();
  }

  Future<void> _saveUserData() async {
    if (_user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', _user!.id);
      await prefs.setString('user_username', _user!.username);
      
      if (_user!.userRoleId != null) {
        await prefs.setInt('user_userRoleId', _user!.userRoleId!);
      }
      if (_user!.email != null) {
        await prefs.setString('user_email', _user!.email!);
      }
      if (_user!.loyaltyLevel != null) {
        await prefs.setString('user_loyaltyLevel', _user!.loyaltyLevel!);
      }
      if (_user!.totalSpent != null) {
        await prefs.setDouble('user_totalSpent', _user!.totalSpent!);
      }
      if (_user!.walletBalance != null) {
        await prefs.setDouble('user_walletBalance', _user!.walletBalance!);
      }
      if (_user!.userRole != null) {
        await prefs.setInt('user_role_id', _user!.userRole!.id);
        await prefs.setString('user_role_role', _user!.userRole!.role);
      }
      
      print('Данные пользователя сохранены: ${_user!.username}');
    }
  }

  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_username');
    await prefs.remove('user_email');
    await prefs.remove('user_userRoleId');
    await prefs.remove('user_loyaltyLevel');
    await prefs.remove('user_totalSpent');
    await prefs.remove('user_walletBalance');
    await prefs.remove('user_role_id');
    await prefs.remove('user_role_role');
    
    print('Данные пользователя очищены');
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final username = prefs.getString('user_username');
    
    if (userId != null && username != null) {
      // Загружаем UserRole если есть
      UserRole? userRole;
      final userRoleId = prefs.getInt('user_role_id');
      final userRoleRole = prefs.getString('user_role_role');
      if (userRoleId != null && userRoleRole != null) {
        userRole = UserRole(id: userRoleId, role: userRoleRole);
      }
      
      _user = User(
        id: userId,
        username: username,
        email: prefs.getString('user_email'),
        userRoleId: prefs.getInt('user_userRoleId'),
        loyaltyLevel: prefs.getString('user_loyaltyLevel'),
        totalSpent: prefs.getDouble('user_totalSpent'),
        walletBalance: prefs.getDouble('user_walletBalance'),
        userRole: userRole,
      );
      
      print('Данные пользователя загружены: ${_user!.username}');
      notifyListeners();
    } else {
      print('Сохраненные данные пользователя не найдены');
    }
  }
}
