class ApiConstants {
  static const String BASE_URL = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1/',
  );
}