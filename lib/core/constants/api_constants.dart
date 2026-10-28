class ApiConstants {
  static const String BASE_URL = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://192.168.100.218:8000/api/v1/',
  );
}