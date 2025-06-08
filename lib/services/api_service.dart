import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';
import '../models/product.dart';
import '../models/api_error.dart';
import '../models/checkout.dart';
import '../models/profile.dart' as profile;
import '../config/api_config.dart';

class ApiService {
  // Use API configuration for different environments
  static String get baseUrl => ApiConfig.baseUrl;
  
  // Для хранения cookie сессии
  static String? sessionCookie;

  static Map<String, String> get headers {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    if (sessionCookie != null) {
      headers['Cookie'] = sessionCookie!;
    }
    return headers;
  }

  static void _handleSetCookie(http.Response response) {
    String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      sessionCookie = (index == -1) ? rawCookie : rawCookie.substring(0, index);
      _saveCookie();
    }
  }

  static Future<void> _saveCookie() async {
    if (sessionCookie != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('session_cookie', sessionCookie!);
      print('Cookie сохранен: $sessionCookie');
    }
  }

  static Future<void> loadCookie() async {
    final prefs = await SharedPreferences.getInstance();
    sessionCookie = prefs.getString('session_cookie');
    if (sessionCookie != null) {
      print('Cookie загружен: $sessionCookie');
    } else {
      print('Сохраненный cookie не найден');
    }
  }

  static Future<void> clearCookie() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_cookie');
    sessionCookie = null;
    print('Cookie очищен');
  }

  static Future<AuthResponse> register(RegisterRequest request) async {
    try {
      print('Отправка запроса регистрации: ${request.toJson()}');
      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      print('Статус ответа регистрации: ${response.statusCode}');
      print('Тело ответа регистрации: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _handleSetCookie(response);
        return AuthResponse.fromJson(responseData);
      } else {
        // Обрабатываем ошибки валидации от NestJS
        String errorMessage = 'Ошибка регистрации';
        if (responseData['message'] != null) {
          if (responseData['message'] is List) {
            // Если message - это массив (ошибки валидации)
            final List<dynamic> messages = responseData['message'];
            errorMessage = messages.join(', ');
          } else {
            // Если message - это строка
            errorMessage = responseData['message'].toString();
          }
        }
        
        return AuthResponse(
          message: '',
          error: errorMessage,
        );
      }
    } catch (e) {
      print('Ошибка в register: $e');
      String errorMessage = 'Ошибка подключения к серверу';
      
      if (e.toString().contains('XMLHttpRequest')) {
        errorMessage = 'CORS ошибка: проверьте настройки сервера';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Не удается подключиться к серверу (проверьте URL и доступность сервера)';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Превышено время ожидания ответа от сервера';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Ошибка формата ответа от сервера';
      }
      
      return AuthResponse(
        message: '',
        error: '$errorMessage: ${e.toString()}',
      );
    }
  }

  static Future<AuthResponse> login(LoginRequest request) async {
    try {
      print('Отправка запроса логина: ${request.toJson()}');
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      print('Статус ответа: ${response.statusCode}');
      print('Тело ответа: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _handleSetCookie(response);
        return AuthResponse.fromJson(responseData);
      } else {
        // Обрабатываем ошибки валидации от NestJS
        String errorMessage = 'Неверное имя пользователя или пароль';
        if (responseData['message'] != null) {
          if (responseData['message'] is List) {
            // Если message - это массив (ошибки валидации)
            final List<dynamic> messages = responseData['message'];
            errorMessage = messages.join(', ');
          } else {
            // Если message - это строка
            errorMessage = responseData['message'].toString();
          }
        }
        
        return AuthResponse(
          message: '',
          error: errorMessage,
        );
      }
    } catch (e) {
      print('Ошибка в login: $e');
      String errorMessage = 'Ошибка подключения к серверу';
      
      if (e.toString().contains('XMLHttpRequest')) {
        errorMessage = 'CORS ошибка: проверьте настройки сервера';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Не удается подключиться к серверу (проверьте URL и доступность сервера)';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Превышено время ожидания ответа от сервера';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Ошибка формата ответа от сервера';
      }
      
      return AuthResponse(
        message: '',
        error: '$errorMessage: ${e.toString()}',
      );
    }
  }

  static Future<AuthResponse> resetPassword(ResetPasswordRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/reset-password'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResponse(
          message: responseData['message'] ?? 'Новый пароль отправлен на email',
        );
      } else {
        // Обрабатываем ошибки валидации от NestJS
        String errorMessage = 'Ошибка восстановления пароля';
        if (responseData['message'] != null) {
          if (responseData['message'] is List) {
            // Если message - это массив (ошибки валидации)
            final List<dynamic> messages = responseData['message'];
            errorMessage = messages.join(', ');
          } else {
            // Если message - это строка
            errorMessage = responseData['message'].toString();
          }
        }
        
        return AuthResponse(
          message: '',
          error: errorMessage,
        );
      }
    } catch (e) {
      return AuthResponse(
        message: '',
        error: 'Ошибка подключения к серверу',
      );
    }
  }

  static Future<AuthResponse> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/logout'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        await clearCookie();
        return AuthResponse(
          message: 'Выход успешен',
        );
      } else {
        return AuthResponse(
          message: '',
          error: 'Ошибка выхода',
        );
      }
    } catch (e) {
      return AuthResponse(
        message: '',
        error: 'Ошибка подключения к серверу',
      );
    }
  }

  // Products API methods
  static Future<ProductsResponse?> getProducts({
    String? search,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (sortBy != null) {
        queryParams['sortBy'] = sortBy;
      }
      if (sortOrder != null) {
        queryParams['sortOrder'] = sortOrder;
      }

      final uri = Uri.parse('$baseUrl/products/catalog').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri, headers: headers);

      print('Статус ответа каталога: ${response.statusCode}');
      print('Тело ответа каталога: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return ProductsResponse.fromJson(responseData);
      } else {
        print('Ошибка получения каталога: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Ошибка в getProducts: $e');
      return null;
    }
  }

  static Future<ToggleFavoriteResponse?> toggleFavorite(int productId) async {
    try {
      final request = ToggleFavoriteRequest(productId: productId);
      final response = await http.post(
        Uri.parse('$baseUrl/favorites/toggle'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      print('Статус ответа избранного: ${response.statusCode}');
      print('Тело ответа избранного: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return ToggleFavoriteResponse.fromJson(responseData);
      } else {
        print('Ошибка переключения избранного: ${response.statusCode}');
        // Парсим детальную ошибку от сервера
        String errorMessage = 'Неизвестная ошибка';
        
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? 'Неизвестная ошибка';
          } catch (jsonError) {
            // Если не удалось распарсить JSON, используем тело ответа как есть
            errorMessage = response.body;
          }
        }
        
        throw ApiException(errorMessage, response.statusCode);
      }
    } catch (e) {
      print('Ошибка в toggleFavorite: $e');
      // Если это уже ApiException, просто перебрасываем
      if (e is ApiException) {
        rethrow;
      }
      // Иначе создаем новое исключение
      throw ApiException('Ошибка подключения к серверу', 0);
    }
  }

  static Future<List<FavoriteItem>?> getFavorites() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/favorites'),
        headers: headers,
      );

      print('Статус ответа избранного: ${response.statusCode}');
      print('Тело ответа избранного: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        return responseData
            .map((item) => FavoriteItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        print('Ошибка получения избранного: ${response.statusCode}');
        // Для ошибок авторизации бросаем ApiException
        if (response.statusCode == 401) {
          String errorMessage = 'Требуется авторизация';
          
          if (response.body.isNotEmpty) {
            try {
              final errorData = jsonDecode(response.body);
              errorMessage = errorData['message'] ?? 'Требуется авторизация';
            } catch (jsonError) {
              // Если не удалось распарсить JSON, используем дефолтное сообщение
            }
          }
          
          throw ApiException(errorMessage, response.statusCode);
        }
        return null;
      }
    } catch (e) {
      print('Ошибка в getFavorites: $e');
      // Если это уже ApiException, просто перебрасываем
      if (e is ApiException) {
        rethrow;
      }
      // Иначе возвращаем null для других ошибок
      return null;
    }
  }

  static Future<Set<int>?> getFavoriteIds() async {
    try {
      final favorites = await getFavorites();
      if (favorites != null) {
        return favorites.map((item) => item.product.id).toSet();
      }
      return null;
    } catch (e) {
      print('Ошибка в getFavoriteIds: $e');
      return null;
    }
  }

  // Product details API methods
  static Future<ProductDetails?> getProductDetails(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId/details-with-cart'),
        headers: headers,
      );

      print('Статус ответа деталей товара: ${response.statusCode}');
      print('Тело ответа деталей товара: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return ProductDetails.fromJson(responseData);
      } else {
        print('Ошибка получения деталей товара: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Ошибка в getProductDetails: $e');
      return null;
    }
  }

  static Future<AddToCartResponse?> addToCart(int productId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart-items/add/$productId'),
        headers: headers,
      );

      print('Статус ответа добавления в корзину: ${response.statusCode}');
      print('Тело ответа добавления в корзину: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return AddToCartResponse.fromJson(responseData);
      } else {
        print('Ошибка добавления в корзину: ${response.statusCode}');
        // Парсим детальную ошибку от сервера
        String errorMessage = 'Неизвестная ошибка';
        
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? 'Неизвестная ошибка';
          } catch (jsonError) {
            // Если не удалось распарсить JSON, используем тело ответа как есть
            errorMessage = response.body;
          }
        }
        
        throw ApiException(errorMessage, response.statusCode);
      }
    } catch (e) {
      print('Ошибка в addToCart: $e');
      // Если это уже ApiException, просто перебрасываем
      if (e is ApiException) {
        rethrow;
      }
      // Иначе создаем новое исключение
      throw ApiException('Ошибка подключения к серверу', 0);
    }
  }

  static Future<List<Review>?> getProductReviews(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/product/$productId'),
        headers: headers,
      );

      print('Статус ответа отзывов: ${response.statusCode}');
      print('Тело ответа отзывов: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        return responseData
            .map((item) => Review.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        print('Ошибка получения отзывов: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Ошибка в getProductReviews: $e');
      return null;
    }
  }

  static Future<ApiResult<CreateReviewResponse>> createReview(CreateReviewRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      print('Статус ответа создания отзыва: ${response.statusCode}');
      print('Тело ответа создания отзыва: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return ApiResult.success(CreateReviewResponse.fromJson(responseData));
      } else {
        // Обрабатываем ошибку от сервера
        final responseData = jsonDecode(response.body);
        final apiError = ApiError.fromJson(responseData);
        return ApiResult.failure(apiError);
      }
    } catch (e) {
      print('Ошибка в createReview: $e');
      return ApiResult.failure(ApiError(
        message: 'Ошибка подключения к серверу',
        statusCode: 0,
      ));
    }
  }

  // Cart API methods
  // Cart API methods
  static Future<Cart?> getCart() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/carts/my-cart'),
        headers: headers,
      );

      print('Статус ответа корзины: ${response.statusCode}');
      print('Тело ответа корзины: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return Cart.fromJson(responseData);
      } else {
        print('Ошибка получения корзины: ${response.statusCode}');
        // Для ошибок авторизации бросаем ApiException
        if (response.statusCode == 401) {
          String errorMessage = 'Требуется авторизация';
          
          if (response.body.isNotEmpty) {
            try {
              final errorData = jsonDecode(response.body);
              errorMessage = errorData['message'] ?? 'Требуется авторизация';
            } catch (jsonError) {
              // Если не удалось распарсить JSON, используем дефолтное сообщение
            }
          }
          
          throw ApiException(errorMessage, response.statusCode);
        }
        return null;
      }
    } catch (e) {
      print('Ошибка в getCart: $e');
      // Если это уже ApiException, просто перебрасываем
      if (e is ApiException) {
        rethrow;
      }
      // Иначе возвращаем null для других ошибок
      return null;
    }
  }

  static Future<Set<int>?> getCartProductIds() async {
    try {
      final cart = await getCart();
      if (cart != null && cart.cartItems.isNotEmpty) {
        return cart.cartItems.map((item) => item.productId).toSet();
      }
      return <int>{};
    } catch (e) {
      print('Ошибка в getCartProductIds: $e');
      return null;
    }
  }

  static Future<CartUpdateResponse> increaseCartItemQuantity(int cartItemId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/cart-items/$cartItemId/increase'),
        headers: headers,
      );

      print('Статус ответа увеличения количества: ${response.statusCode}');
      print('Тело ответа увеличения количества: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return CartUpdateResponse.fromJson(responseData);
      } else {
        print('Ошибка увеличения количества: ${response.statusCode}');
        // Парсим детальную ошибку от сервера
        String errorMessage = 'Неизвестная ошибка';
        
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? 'Неизвестная ошибка';
          } catch (jsonError) {
            // Если не удалось распарсить JSON, используем тело ответа как есть
            errorMessage = response.body;
          }
        }
        
        throw ApiException(errorMessage, response.statusCode);
      }
    } catch (e) {
      print('Ошибка в increaseCartItemQuantity: $e');
      // Если это уже ApiException, просто перебрасываем
      if (e is ApiException) {
        rethrow;
      }
      // Иначе создаем новое исключение
      throw ApiException('Ошибка подключения к серверу', 0);
    }
  }

  static Future<CartUpdateResponse> decreaseCartItemQuantity(int cartItemId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/cart-items/$cartItemId/decrease'),
        headers: headers,
      );

      print('Статус ответа уменьшения количества: ${response.statusCode}');
      print('Тело ответа уменьшения количества: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return CartUpdateResponse.fromJson(responseData);
      } else {
        print('Ошибка уменьшения количества: ${response.statusCode}');
        // Парсим детальную ошибку от сервера
        String errorMessage = 'Неизвестная ошибка';
        
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? 'Неизвестная ошибка';
          } catch (jsonError) {
            // Если не удалось распарсить JSON, используем тело ответа как есть
            errorMessage = response.body;
          }
        }
        
        throw ApiException(errorMessage, response.statusCode);
      }
    } catch (e) {
      print('Ошибка в decreaseCartItemQuantity: $e');
      // Если это уже ApiException, просто перебрасываем
      if (e is ApiException) {
        rethrow;
      }
      // Иначе создаем новое исключение
      throw ApiException('Ошибка подключения к серверу', 0);
    }
  }

  static Future<RemoveFromCartResponse> removeFromCart(int cartItemId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cart-items/$cartItemId'),
        headers: headers,
      );

      print('Статус ответа удаления из корзины: ${response.statusCode}');
      print('Тело ответа удаления из корзины: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return RemoveFromCartResponse.fromJson(responseData);
      } else {
        print('Ошибка удаления из корзины: ${response.statusCode}');
        // Парсим детальную ошибку от сервера
        String errorMessage = 'Неизвестная ошибка';
        
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? 'Неизвестная ошибка';
          } catch (jsonError) {
            // Если не удалось распарсить JSON, используем тело ответа как есть
            errorMessage = response.body;
          }
        }
        
        throw ApiException(errorMessage, response.statusCode);
      }
    } catch (e) {
      print('Ошибка в removeFromCart: $e');
      // Если это уже ApiException, просто перебрасываем
      if (e is ApiException) {
        rethrow;
      }
      // Иначе создаем новое исключение
      throw ApiException('Ошибка подключения к серверу', 0);
    }
  }

  // Получение информации для оформления заказа
  static Future<CheckoutInfo?> getCheckoutInfo() async {
    try {
      print('Отправка запроса checkout: $baseUrl/orders/checkout');
      print('Headers: $headers');
      final response = await http.get(
        Uri.parse('$baseUrl/orders/checkout'),
        headers: headers,
      );

      print('Статус ответа checkout: ${response.statusCode}');
      print('Тело ответа checkout: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return CheckoutInfo.fromJson(responseData);
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(
          errorData['message'] ?? 'Ошибка получения данных для оформления',
          response.statusCode
        );
      }
    } catch (e) {
      print('Ошибка в getCheckoutInfo: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Ошибка подключения к серверу', 0);
    }
  }

  // Создание заказа
  static Future<ApiResult<CreatedOrder>> createOrderNew(CreateOrderRequest request) async {
    try {
      print('Отправка запроса создания заказа: $baseUrl/orders');
      print('Headers: $headers');
      print('Body: ${jsonEncode(request.toJson())}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      print('Статус ответа создания заказа: ${response.statusCode}');
      print('Тело ответа создания заказа: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return ApiResult.success(CreatedOrder.fromJson(responseData));
      } else {
        // Для ошибок валидации и других HTTP ошибок
        String errorMessage = 'Ошибка создания заказа';
        
        if (responseData['message'] is List) {
          // Если сервер отправляет массив ошибок валидации
          errorMessage = (responseData['message'] as List).join(', ');
        } else if (responseData['message'] is String) {
          errorMessage = responseData['message'];
        }
        
        return ApiResult.failure(ApiError(
          message: errorMessage,
          statusCode: response.statusCode,
        ));
      }
    } catch (e) {
      print('Ошибка в createOrderNew: $e');
      // Для любых других ошибок (сетевые, парсинг JSON и т.д.)
      return ApiResult.failure(ApiError(
        message: 'Ошибка подключения к серверу',
        statusCode: 0,
      ));
    }
  }

  // Profile API methods
  static Future<profile.ProfileResponse?> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: headers,
      );

      print('Статус ответа профиля: ${response.statusCode}');
      print('Тело ответа профиля: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return profile.ProfileResponse.fromJson(responseData);
      } else {
        print('Ошибка получения профиля: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Ошибка в getProfile: $e');
      return null;
    }
  }

  static Future<ApiResult<profile.ProfileResponse>> updateProfile(profile.ProfileRequest request) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/update-contact-data'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      print('Статус ответа обновления профиля: ${response.statusCode}');
      print('Тело ответа обновления профиля: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return ApiResult.success(profile.ProfileResponse.fromJson(responseData));
      } else {
        // Обрабатываем ошибку от сервера
        try {
          final responseData = jsonDecode(response.body);
          final apiError = ApiError.fromJson(responseData);
          return ApiResult.failure(apiError);
        } catch (parseError) {
          // Если не удалось распарсить ответ сервера
          print('Ошибка парсинга ответа сервера: $parseError');
          return ApiResult.failure(ApiError(
            message: 'Ошибка сервера (${response.statusCode})',
            statusCode: response.statusCode,
          ));
        }
      }
    } catch (e) {
      print('Ошибка в updateProfile: $e');
      // Проверяем, является ли это сетевой ошибкой
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection') ||
          e.toString().contains('timeout')) {
        return ApiResult.failure(ApiError(
          message: 'Ошибка подключения к серверу',
          statusCode: 0,
        ));
      } else {
        return ApiResult.failure(ApiError(
          message: 'Неожиданная ошибка: ${e.toString()}',
          statusCode: 0,
        ));
      }
    }
  }

  static Future<ApiResult<bool>> changePassword(profile.ResetPasswordRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      print('Статус ответа смены пароля: ${response.statusCode}');
      print('Тело ответа смены пароля: ${response.body}');

      if (response.statusCode == 200) {
        return ApiResult.success(true);
      } else {
        // Обрабатываем ошибку от сервера
        try {
          final responseData = jsonDecode(response.body);
          final apiError = ApiError.fromJson(responseData);
          return ApiResult.failure(apiError);
        } catch (parseError) {
          print('Ошибка парсинга ответа сервера: $parseError');
          return ApiResult.failure(ApiError(
            message: 'Ошибка сервера (${response.statusCode})',
            statusCode: response.statusCode,
          ));
        }
      }
    } catch (e) {
      print('Ошибка в changePassword: $e');
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection') ||
          e.toString().contains('timeout')) {
        return ApiResult.failure(ApiError(
          message: 'Ошибка подключения к серверу',
          statusCode: 0,
        ));
      } else {
        return ApiResult.failure(ApiError(
          message: 'Неожиданная ошибка: ${e.toString()}',
          statusCode: 0,
        ));
      }
    }
  }

  static Future<ApiResult<String>> resetPasswordFromProfile() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/reset-password-from-profile'),
        headers: headers,
      );

      print('Статус ответа сброса пароля из профиля: ${response.statusCode}');
      print('Тело ответа сброса пароля из профиля: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return ApiResult.success(responseData['message'] ?? 'Новый пароль отправлен на email');
      } else {
        // Обрабатываем ошибку от сервера
        try {
          final responseData = jsonDecode(response.body);
          final apiError = ApiError.fromJson(responseData);
          return ApiResult.failure(apiError);
        } catch (parseError) {
          print('Ошибка парсинга ответа сервера: $parseError');
          return ApiResult.failure(ApiError(
            message: 'Ошибка сервера (${response.statusCode})',
            statusCode: response.statusCode,
          ));
        }
      }
    } catch (e) {
      print('Ошибка в resetPasswordFromProfile: $e');
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection') ||
          e.toString().contains('timeout')) {
        return ApiResult.failure(ApiError(
          message: 'Ошибка подключения к серверу',
          statusCode: 0,
        ));
      } else {
        return ApiResult.failure(ApiError(
          message: 'Неожиданная ошибка: ${e.toString()}',
          statusCode: 0,
        ));
      }
    }
  }

  static Future<profile.OrderHistoryResponse?> getOrderHistory({int page = 1, int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/order-history?page=$page&limit=$limit'),
        headers: headers,
      );

      print('Статус ответа истории заказов: ${response.statusCode}');
      print('Тело ответа истории заказов: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return profile.OrderHistoryResponse.fromJson(responseData);
      } else {
        print('Ошибка получения истории заказов: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Ошибка в getOrderHistory: $e');
      return null;
    }
  }

  static Future<profile.OrderDetails?> getOrderDetails(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/orders/$orderId/details'),
        headers: headers,
      );

      print('Статус ответа деталей заказа: ${response.statusCode}');
      print('Тело ответа деталей заказа: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return profile.OrderDetails.fromJson(responseData);
      } else {
        print('Ошибка получения деталей заказа: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Ошибка в getOrderDetails: $e');
      return null;
    }
  }

  static Future<profile.LoyaltyProgram?> getLoyaltyProgram() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/loyalty-program'),
        headers: headers,
      );

      print('Статус ответа программы лояльности: ${response.statusCode}');
      print('Тело ответа программы лояльности: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return profile.LoyaltyProgram.fromJson(responseData);
      } else {
        print('Ошибка получения программы лояльности: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Ошибка в getLoyaltyProgram: $e');
      return null;
    }
  }

  static Future<profile.UserWallet?> getUserWallet() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/wallet'),
        headers: headers,
      );

      print('Статус ответа кошелька: ${response.statusCode}');
      print('Тело ответа кошелька: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return profile.UserWallet.fromJson(responseData);
      } else {
        print('Ошибка получения кошелька: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Ошибка в getUserWallet: $e');
      return null;
    }
  }
}
