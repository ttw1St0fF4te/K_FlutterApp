import 'package:flutter/foundation.dart';
import '../models/profile.dart';
import '../services/api_service.dart';

class ProfileProvider extends ChangeNotifier {
  UserProfile? _userProfile;
  List<OrderHistoryItem> _orderHistory = [];
  LoyaltyProgram? _loyaltyProgram;
  UserWallet? _userWallet;
  bool _isLoading = false;
  String? _error;

  // История заказов пагинация
  int _currentPage = 1;
  bool _hasMoreOrders = true;
  bool _loadingMoreOrders = false;

  // Getters
  UserProfile? get userProfile => _userProfile;
  List<OrderHistoryItem> get orderHistory => _orderHistory;
  LoyaltyProgram? get loyaltyProgram => _loyaltyProgram;
  UserWallet? get userWallet => _userWallet;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMoreOrders => _hasMoreOrders;
  bool get loadingMoreOrders => _loadingMoreOrders;

  // Метод для очистки ошибок
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Метод для очистки всех данных при выходе пользователя
  void clearAllData() {
    _userProfile = null;
    _orderHistory = [];
    _loyaltyProgram = null;
    _userWallet = null;
    _isLoading = false;
    _error = null;
    _currentPage = 1;
    _hasMoreOrders = true;
    _loadingMoreOrders = false;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final profileResponse = await ApiService.getProfile();
      if (profileResponse != null) {
        _userProfile = profileResponse.user;
      } else {
        _error = 'Не удалось загрузить профиль';
      }
    } catch (e) {
      _error = 'Ошибка загрузки профиля: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(ProfileRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.updateProfile(request);
      if (result.success) {
        _userProfile = result.data!.user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.error!.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Ошибка обновления профиля: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = ResetPasswordRequest(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      final result = await ApiService.changePassword(request);
      if (result.success) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.error!.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Ошибка сброса пароля: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPasswordFromProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.resetPasswordFromProfile();
      if (result.success) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.error!.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Ошибка сброса пароля: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadOrderHistory({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreOrders = true;
      _orderHistory.clear();
    }

    if (!_hasMoreOrders || _loadingMoreOrders) return;

    _loadingMoreOrders = true;
    if (refresh) {
      _isLoading = true;
      _error = null;
    }
    notifyListeners();

    try {
      final response = await ApiService.getOrderHistory(
        page: _currentPage,
        limit: 10,
      );
      
      if (response != null) {
        if (refresh) {
          _orderHistory = response.orders;
        } else {
          _orderHistory.addAll(response.orders);
        }
        
        _hasMoreOrders = response.hasMore;
        _currentPage++;
      } else {
        if (refresh) {
          _error = 'Не удалось загрузить историю заказов';
        }
      }
    } catch (e) {
      if (refresh) {
        _error = 'Ошибка загрузки истории заказов: $e';
      }
    } finally {
      _isLoading = false;
      _loadingMoreOrders = false;
      notifyListeners();
    }
  }

  Future<OrderDetails?> getOrderDetails(int orderId) async {
    try {
      return await ApiService.getOrderDetails(orderId);
    } catch (e) {
      _error = 'Ошибка загрузки деталей заказа: $e';
      notifyListeners();
      return null;
    }
  }

  Future<void> loadLoyaltyProgram() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final loyaltyProgram = await ApiService.getLoyaltyProgram();
      if (loyaltyProgram != null) {
        _loyaltyProgram = loyaltyProgram;
      } else {
        _error = 'Не удалось загрузить программу лояльности';
      }
    } catch (e) {
      _error = 'Ошибка загрузки программы лояльности: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserWallet() async {
    // Проверяем доступность кошелька перед загрузкой
    if (_loyaltyProgram == null || _loyaltyProgram!.currentLevel == 'Нет уровня') {
      // Если кошелек недоступен, просто не загружаем его без ошибки
      _userWallet = null;
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final wallet = await ApiService.getUserWallet();
      if (wallet != null) {
        _userWallet = wallet;
      } else {
        // Не показываем ошибку, если кошелек просто недоступен
        _userWallet = null;
      }
    } catch (e) {
      // Логируем ошибку, но не показываем пользователю если это ошибка доступа
      print('Ошибка загрузки кошелька: $e');
      if (e.toString().contains('Кошелек недоступен') || e.toString().contains('BadRequestException')) {
        // Если кошелек недоступен по уровню лояльности - не показываем ошибку
        _userWallet = null;
      } else {
        _error = 'Ошибка загрузки кошелька: $e';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearData() {
    _userProfile = null;
    _orderHistory.clear();
    _loyaltyProgram = null;
    _userWallet = null;
    _currentPage = 1;
    _hasMoreOrders = true;
    _loadingMoreOrders = false;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
