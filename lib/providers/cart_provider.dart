import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/api_error.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  Cart? _cart;
  bool _isLoading = false;
  String? _errorMessage;

  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Вычисляемые свойства
  int get totalItems => _cart?.cartItems.fold<int>(0, (sum, item) => sum + item.quantity) ?? 0;
  double get totalAmount => _cart?.totalAmount ?? 0.0;
  bool get isEmpty => _cart?.cartItems.isEmpty ?? true;

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

  Future<void> loadCart() async {
    _setLoading(true);
    _setError(null);

    try {
      final cart = await ApiService.getCart();
      if (cart != null) {
        _cart = cart;
      } else {
        // Не показываем ошибку для null-ответа, так как это может быть пустая корзина
        print('CartProvider: пустая корзина или ошибка загрузки');
      }
    } catch (e) {
      // Не показываем ошибки авторизации пользователю при загрузке корзины
      if (e is ApiException && e.statusCode == 401) {
        print('CartProvider: пользователь не авторизован для загрузки корзины');
        // Очищаем корзину для неавторизованного пользователя
        _cart = null;
      } else {
        _setError('Ошибка подключения к серверу');
        print('CartProvider: ошибка загрузки корзины: $e');
      }
    }

    _setLoading(false);
  }

  Future<void> increaseQuantity(int cartItemId) async {
    _setError(null);

    try {
      final response = await ApiService.increaseCartItemQuantity(cartItemId);
      // Обновляем локальное состояние без полной перезагрузки
      _updateCartItemLocally(cartItemId, response.newQuantity);
    } catch (e) {
      if (e is ApiException) {
        _setError(e.message);
      } else {
        _setError('Ошибка подключения к серверу');
      }
      print('CartProvider: ошибка увеличения количества: $e');
    }
  }

  Future<void> decreaseQuantity(int cartItemId) async {
    _setError(null);

    try {
      final response = await ApiService.decreaseCartItemQuantity(cartItemId);
      // Обновляем локальное состояние без полной перезагрузки
      _updateCartItemLocally(cartItemId, response.newQuantity);
    } catch (e) {
      if (e is ApiException) {
        _setError(e.message);
      } else {
        _setError('Ошибка подключения к серверу');
      }
      print('CartProvider: ошибка уменьшения количества: $e');
    }
  }

  Future<void> removeFromCart(int cartItemId) async {
    _setError(null);

    try {
      await ApiService.removeFromCart(cartItemId);
      // Обновляем локальное состояние без полной перезагрузки
      _removeCartItemLocally(cartItemId);
    } catch (e) {
      if (e is ApiException) {
        _setError(e.message);
      } else {
        _setError('Ошибка подключения к серверу');
      }
      print('CartProvider: ошибка удаления из корзины: $e');
    }
  }

  Future<void> addToCart(int productId) async {
    _setError(null);

    try {
      final response = await ApiService.addToCart(productId);
      if (response != null) {
        // Обновляем локальное состояние
        await loadCart(); // Перезагружаем корзину для получения актуальных данных
      } else {
        _setError('Ошибка добавления товара в корзину');
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.message);
      } else {
        _setError('Ошибка подключения к серверу');
      }
      print('CartProvider: ошибка добавления в корзину: $e');
    }
  }

  Future<void> refresh() async {
    await loadCart();
  }

  void clear() {
    _cart = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearCart() {
    _cart = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Метод для очистки при смене пользователя  
  void clearForUserChange() {
    _cart = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Метод для локального обновления количества товара без перезагрузки корзины
  void _updateCartItemLocally(int cartItemId, int newQuantity) {
    if (_cart != null) {
      final index = _cart!.cartItems.indexWhere((item) => item.id == cartItemId);
      if (index != -1) {
        // Создаем новый CartItem с обновленным количеством
        final oldItem = _cart!.cartItems[index];
        final updatedItem = CartItem(
          id: oldItem.id,
          cartId: oldItem.cartId,
          productId: oldItem.productId,
          quantity: newQuantity,
          product: oldItem.product,
        );
        
        // Заменяем элемент в списке, сохраняя порядок
        final newCartItems = List<CartItem>.from(_cart!.cartItems);
        newCartItems[index] = updatedItem;
        
        // Пересчитываем общую сумму корзины
        final newTotalAmount = newCartItems.fold<double>(
          0.0, 
          (sum, item) => sum + (item.quantity * item.product.price)
        );
        
        // Создаем новую корзину с обновленными элементами
        _cart = Cart(
          id: _cart!.id,
          userId: _cart!.userId,
          cartItems: newCartItems,
          totalAmount: newTotalAmount,
        );
        
        notifyListeners();
      }
    }
  }

  // Метод для локального удаления товара из корзины
  void _removeCartItemLocally(int cartItemId) {
    if (_cart != null) {
      final newCartItems = _cart!.cartItems.where((item) => item.id != cartItemId).toList();
      
      // Пересчитываем общую сумму корзины
      final newTotalAmount = newCartItems.fold<double>(
        0.0, 
        (sum, item) => sum + (item.quantity * item.product.price)
      );
      
      // Создаем новую корзину без удаленного элемента
      _cart = Cart(
        id: _cart!.id,
        userId: _cart!.userId,
        cartItems: newCartItems,
        totalAmount: newTotalAmount,
      );
      
      notifyListeners();
    }
  }
}
