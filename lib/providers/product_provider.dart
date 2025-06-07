import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = true;
  String _searchQuery = '';
  String _sortBy = 'id';
  String _sortOrder = 'desc';

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasMoreData => _hasMoreData;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;

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

  Future<void> loadProducts({
    bool refresh = false,
    String? search,
    String? sortBy,
    String? sortOrder,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _products.clear();
      _hasMoreData = true;
    }

    if (!_hasMoreData && !refresh) return;

    _setLoading(true);
    _setError(null);

    // Обновляем параметры поиска и сортировки
    if (search != null) _searchQuery = search;
    if (sortBy != null) _sortBy = sortBy;
    if (sortOrder != null) _sortOrder = sortOrder;

    try {
      final response = await ApiService.getProducts(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        page: _currentPage,
        limit: 10,
      );

      if (response != null) {
        if (refresh) {
          _products = response.products;
        } else {
          _products.addAll(response.products);
        }
        
        _totalPages = response.totalPages;
        _currentPage++;
        _hasMoreData = _currentPage <= _totalPages;
        
        notifyListeners();
      } else {
        _setError('Ошибка загрузки каталога');
      }
    } catch (e) {
      _setError('Ошибка подключения к серверу');
    }

    _setLoading(false);
  }

  Future<void> toggleFavorite(int productId) async {
    try {
      final response = await ApiService.toggleFavorite(productId);
      
      if (response != null) {
        // Обновляем статус избранного для продукта в списке
        final productIndex = _products.indexWhere((p) => p.id == productId);
        if (productIndex != -1) {
          _products[productIndex] = _products[productIndex].copyWith(
            isInFavorites: response.isInFavorites,
          );
          notifyListeners();
        }
      } else {
        _setError('Ошибка изменения избранного');
      }
    } catch (e) {
      _setError('Ошибка подключения к серверу');
    }
  }

  void search(String query) {
    _searchQuery = query;
    loadProducts(refresh: true, search: query);
  }

  void sort(String sortBy, String sortOrder) {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    loadProducts(refresh: true, sortBy: sortBy, sortOrder: sortOrder);
  }

  void refresh() {
    loadProducts(refresh: true);
  }
}
