import 'user.dart';

class AuthResponse {
  final String message;
  final User? user;
  final String? error;

  AuthResponse({
    required this.message,
    this.user,
    this.error,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      error: json['error'],
    );
  }
}

class RegisterRequest {
  final String username;
  final String password;
  final String confirmPassword;
  final String? email;

  RegisterRequest({
    required this.username,
    required this.password,
    required this.confirmPassword,
    this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'confirmPassword': confirmPassword,
      if (email != null && email!.isNotEmpty) 'email': email,
    };
  }
}

class LoginRequest {
  final String username;
  final String password;

  LoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

class ResetPasswordRequest {
  final String email;

  ResetPasswordRequest({
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}
