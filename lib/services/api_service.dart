import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';
import '../models/product.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator, 127.0.0.1 for iOS simulator, localhost for web
  static const String baseUrl = 'http://127.0.0.1:3000'; // Измените на ваш API URL
  
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
        return null;
      }
    } catch (e) {
      print('Ошибка в toggleFavorite: $e');
      return null;
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
        return null;
      }
    } catch (e) {
      print('Ошибка в getFavorites: $e');
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
}
