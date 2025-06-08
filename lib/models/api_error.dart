class ApiError {
  final String message;
  final int statusCode;
  final String? error;

  ApiError({
    required this.message,
    required this.statusCode,
    this.error,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    String message = 'Неизвестная ошибка';
    
    if (json['message'] != null) {
      if (json['message'] is List) {
        // Если message - это массив (ошибки валидации от NestJS)
        final List<dynamic> messages = json['message'];
        message = messages.join(', ');
      } else {
        // Если message - это строка
        message = json['message'].toString();
      }
    }
    
    return ApiError(
      message: message,
      statusCode: json['statusCode'] ?? 0,
      error: json['error'],
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiResult<T> {
  final T? data;
  final ApiError? error;
  final bool success;

  ApiResult.success(this.data) : error = null, success = true;
  ApiResult.failure(this.error) : data = null, success = false;
}
