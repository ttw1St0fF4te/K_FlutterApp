import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class FavoritesProvider with ChangeNotifier {
  List<FavoriteItem> _favorites = [];
  bool _isLoading = false;
  String? _errorMessage;
  VoidCallback? _onFavoritesChanged;

  List<FavoriteItem> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setOnFavoritesChangedCallback(VoidCallback? callback) {
    _onFavoritesChanged = callback;
  }

  void _notifyFavoritesChanged() {
    if (_onFavoritesChanged != null) {
      _onFavoritesChanged!();
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

  Future<void> loadFavorites() async {
    print('FavoritesProvider.loadFavorites: начинаем загрузку избранного');
    _setLoading(true);
    _setError(null);

    try {
      final response = await ApiService.getFavorites();
      
      if (response != null) {
        print('FavoritesProvider.loadFavorites: получено ${response.length} избранных товаров');
        _favorites = response;
        notifyListeners();
      } else {
        print('FavoritesProvider.loadFavorites: response равен null');
        _setError('Ошибка загрузки избранного');
      }
    } catch (e) {
      print('FavoritesProvider.loadFavorites: исключение - $e');
      _setError('Ошибка подключения к серверу');
    }

    _setLoading(false);
  }

  Future<void> toggleFavorite(int productId) async {
    print('FavoritesProvider.toggleFavorite вызван для продукта $productId');
    try {
      final response = await ApiService.toggleFavorite(productId);
      
      if (response != null) {
        print('FavoritesProvider: получен ответ - ${response.message}, isInFavorites: ${response.isInFavorites}');
        if (response.isInFavorites) {
          // Товар добавлен в избранное - перезагружаем список
          await loadFavorites();
        } else {
          // Товар удален из избранного - удаляем из локального списка
          _favorites.removeWhere((item) => item.product.id == productId);
          print('FavoritesProvider: удален продукт $productId из локального списка');
          notifyListeners();
        }
        
        // Уведомляем ProductProvider об изменении
        _notifyFavoritesChanged();
      } else {
        print('FavoritesProvider.toggleFavorite: response равен null');
        _setError('Ошибка изменения избранного');
      }
    } catch (e) {
      print('FavoritesProvider.toggleFavorite: исключение - $e');
      _setError('Ошибка подключения к серверу');
    }
  }

  void refresh() {
    loadFavorites();
  }
}
