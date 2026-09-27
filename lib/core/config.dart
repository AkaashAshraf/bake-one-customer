/// Where the app talks to the Bake One server.
///
/// Defaults to the live server. For local testing, run with:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.27:8100
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://www.bake-one.com',
  );
}
