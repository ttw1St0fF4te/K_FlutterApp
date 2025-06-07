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
    return ApiError(
      message: json['message'] ?? 'Неизвестная ошибка',
      statusCode: json['statusCode'] ?? 0,
      error: json['error'],
    );
  }
}

class ApiResult<T> {
  final T? data;
  final ApiError? error;
  final bool success;

  ApiResult.success(this.data) : error = null, success = true;
  ApiResult.failure(this.error) : data = null, success = false;
}
