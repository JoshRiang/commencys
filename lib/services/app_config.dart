/// Runtime backend endpoint configuration.
///
/// Defaults target the Android emulator (`10.0.2.2` routes to the host
/// loopback). On a physical phone, open the server setting (app-bar icon on
/// the home screen) and enter the backend address on the local network, e.g.
/// `http://192.168.1.10:8000`. A compile-time default can also be baked in:
///
/// ```sh
/// flutter build apk --release --dart-define=API_BASE=http://192.168.1.10:8000
/// ```
class AppConfig {
  static const defaultBaseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static String baseUrl = defaultBaseUrl;

  /// `http(s)://host:port` → `ws(s)://host:port/ws/alerts`.
  static String wsUrlFor(String base) {
    final uri = Uri.parse(base);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final host = uri.host.isEmpty ? '10.0.2.2' : uri.host;
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '$scheme://$host$port/ws/alerts';
  }

  static String get wsUrl => wsUrlFor(baseUrl);

  static void setBaseUrl(String value) {
    baseUrl = value.trim().replaceAll(RegExp(r'/+$'), '');
  }
}
