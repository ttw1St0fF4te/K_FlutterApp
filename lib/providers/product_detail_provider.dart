import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductDetailProvider extends ChangeNotifier {
  ProductDetails? _productDetails;
  List<Review> _reviews = [];
  bool _isLoading = false;
  bool _isLoadingReviews = false;
  bool _isSubmittingReview = false;
  bool _isAddingToCart = false;
  bool _isTogglingFavorite = false;
  String? _errorMessage;
  String? _reviewErrorMessage;

  ProductDetails? get productDetails => _productDetails;
  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;
  bool get isLoadingReviews => _isLoadingReviews;
  bool get isSubmittingReview => _isSubmittingReview;
  bool get isAddingToCart => _isAddingToCart;
  bool get isTogglingFavorite => _isTogglingFavorite;
  String? get errorMessage => _errorMessage;
  String? get reviewErrorMessage => _reviewErrorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setLoadingReviews(bool loading) {
    _isLoadingReviews = loading;
    notifyListeners();
  }

  void _setSubmittingReview(bool submitting) {
    _isSubmittingReview = submitting;
    notifyListeners();
  }

  void _setAddingToCart(bool adding) {
    _isAddingToCart = adding;
    notifyListeners();
  }

  void _setTogglingFavorite(bool toggling) {
    _isTogglingFavorite = toggling;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _setReviewError(String? error) {
    _reviewErrorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearReviewError() {
    _reviewErrorMessage = null;
    notifyListeners();
  }

  Future<void> loadProductDetails(int productId) async {
    _setLoading(true);
    _setError(null);
    // Очищаем ошибку отзыва при загрузке нового товара
    _setReviewError(null);

    try {
      final details = await ApiService.getProductDetails(productId);
      if (details != null) {
        _productDetails = details;
        
        // Синхронизируем статус избранного с сервером для авторизованных пользователей
        await _syncFavoriteStatus(productId);
        // Синхронизируем статус корзины с сервером для авторизованных пользователей
        await _syncCartStatus(productId);
        
        notifyListeners();
      } else {
        _setError('Ошибка загрузки деталей товара');
      }
    } catch (e) {
      _setError('Ошибка подключения к серверу');
    }

    _setLoading(false);
  }

  Future<void> _syncFavoriteStatus(int productId) async {
    try {
      // Получаем актуальный список избранного
      final favoriteIds = await ApiService.getFavoriteIds();
      if (favoriteIds != null && _productDetails != null) {
        final isInFavorites = favoriteIds.contains(productId);
        
        // Обновляем статус только если он отличается
        if (_productDetails!.isInFavorites != isInFavorites) {
          print('ProductDetailProvider: синхронизация избранного для товара $productId: $isInFavorites');
          _productDetails = ProductDetails(
            id: _productDetails!.id,
            name: _productDetails!.name,
            description: _productDetails!.description,
            price: _productDetails!.price,
            image: _productDetails!.image,
            category: _productDetails!.category,
            isInCart: _productDetails!.isInCart,
            isInFavorites: isInFavorites,
            averageRating: _productDetails!.averageRating,
            reviewsCount: _productDetails!.reviewsCount,
          );
        }
      }
    } catch (e) {
      print('ProductDetailProvider: ошибка синхронизации избранного: $e');
      // Не показываем ошибку пользователю, так как это не критично
    }
  }

  Future<void> _syncCartStatus(int productId) async {
    try {
      // Получаем актуальный список товаров в корзине
      final cartProductIds = await ApiService.getCartProductIds();
      if (cartProductIds != null && _productDetails != null) {
        final isInCart = cartProductIds.contains(productId);
        
        // Обновляем статус только если он отличается
        if (_productDetails!.isInCart != isInCart) {
          print('ProductDetailProvider: синхронизация корзины для товара $productId: $isInCart');
          _productDetails = ProductDetails(
            id: _productDetails!.id,
            name: _productDetails!.name,
            description: _productDetails!.description,
            price: _productDetails!.price,
            image: _productDetails!.image,
            category: _productDetails!.category,
            isInCart: isInCart,
            isInFavorites: _productDetails!.isInFavorites,
            averageRating: _productDetails!.averageRating,
            reviewsCount: _productDetails!.reviewsCount,
          );
          notifyListeners(); // Уведомляем об изменении
        }
      }
    } catch (e) {
      print('ProductDetailProvider: ошибка синхронизации корзины: $e');
      // Не показываем ошибку пользователю, так как это не критично
    }
  }

  Future<void> loadReviews(int productId) async {
    _setLoadingReviews(true);
    _setError(null);

    try {
      final reviews = await ApiService.getProductReviews(productId);
      if (reviews != null) {
        _reviews = reviews;
        notifyListeners();
      } else {
        _setError('Ошибка загрузки отзывов');
      }
    } catch (e) {
      _setError('Ошибка подключения к серверу');
    }

    _setLoadingReviews(false);
  }

  Future<bool> addToCart(int productId) async {
    if (_isAddingToCart) return false;

    _setAddingToCart(true);
    _setError(null);

    try {
      final response = await ApiService.addToCart(productId);
      if (response != null) {
        // Обновляем статус корзины в деталях товара
        if (_productDetails != null) {
          _productDetails = ProductDetails(
            id: _productDetails!.id,
            name: _productDetails!.name,
            description: _productDetails!.description,
            price: _productDetails!.price,
            image: _productDetails!.image,
            category: _productDetails!.category,
            isInCart: true,
            isInFavorites: _productDetails!.isInFavorites,
            averageRating: _productDetails!.averageRating,
            reviewsCount: _productDetails!.reviewsCount,
          );
          notifyListeners();
        }
        _setAddingToCart(false);
        return true;
      } else {
        _setError('Ошибка добавления в корзину');
        _setAddingToCart(false);
        return false;
      }
    } catch (e) {
      _setError('Ошибка подключения к серверу');
      _setAddingToCart(false);
      return false;
    }
  }

  Future<bool> toggleFavorite(int productId) async {
    if (_isTogglingFavorite) return false;

    _setTogglingFavorite(true);
    _setError(null);

    try {
      final response = await ApiService.toggleFavorite(productId);
      if (response != null) {
        // Обновляем статус избранного в деталях товара
        if (_productDetails != null) {
          _productDetails = ProductDetails(
            id: _productDetails!.id,
            name: _productDetails!.name,
            description: _productDetails!.description,
            price: _productDetails!.price,
            image: _productDetails!.image,
            category: _productDetails!.category,
            isInCart: _productDetails!.isInCart,
            isInFavorites: response.isInFavorites,
            averageRating: _productDetails!.averageRating,
            reviewsCount: _productDetails!.reviewsCount,
          );
          notifyListeners();
        }
        _setTogglingFavorite(false);
        return true;
      } else {
        _setError('Ошибка переключения избранного');
        _setTogglingFavorite(false);
        return false;
      }
    } catch (e) {
      _setError('Ошибка подключения к серверу');
      _setTogglingFavorite(false);
      return false;
    }
  }

  Future<bool> submitReview(int productId, int rating, String text) async {
    if (_isSubmittingReview) return false;

    _setSubmittingReview(true);
    _setReviewError(null);

    try {
      final request = CreateReviewRequest(
        productId: productId,
        rating: rating,
        text: text,
      );

      final result = await ApiService.createReview(request);
      
      if (result.success && result.data != null) {
        // Перезагружаем отзывы и детали товара для обновления статистики
        await loadReviews(productId);
        await loadProductDetails(productId);
        _setSubmittingReview(false);
        return true;
      } else {
        // Используем сообщение об ошибке от сервера
        final errorMessage = result.error?.message ?? 'Ошибка отправки отзыва';
        _setReviewError(errorMessage);
        _setSubmittingReview(false);
        return false;
      }
    } catch (e) {
      _setReviewError('Ошибка подключения к серверу');
      _setSubmittingReview(false);
      return false;
    }
  }

  void reset() {
    _productDetails = null;
    _reviews = [];
    _isLoading = false;
    _isLoadingReviews = false;
    _isSubmittingReview = false;
    _isAddingToCart = false;
    _isTogglingFavorite = false;
    _errorMessage = null;
    _reviewErrorMessage = null;
    notifyListeners();
  }

  // Метод для очистки только ошибок отзывов при переходе на новый товар
  void clearReviewErrors() {
    _reviewErrorMessage = null;
    notifyListeners();
  }
}
