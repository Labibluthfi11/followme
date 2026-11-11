class AppException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;
  final Object? errors;

  AppException({
    required this.message,
    this.statusCode,
    this.isNetworkError = false,
    this.errors,
  });

  @override
  String toString() =>
      'AppException(message: $message, statusCode: $statusCode, isNetworkError: $isNetworkError)';
}
