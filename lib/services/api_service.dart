import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_models.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator, 127.0.0.1 for iOS simulator, localhost for web
  static const String baseUrl = 'http://localhost:3000'; // Измените на ваш API URL
  
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
    }
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
        sessionCookie = null;
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
}
