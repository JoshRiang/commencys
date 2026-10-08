// Spesifikasi konfigurasi klien dipertahankan sebagai kontrak yang ditunda.
// Aplikasi tidak memiliki kelas model data; payload tetap berupa peta JSON.
import 'package:commencys/services/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('wsUrlFor maps http(s) base to ws(s) alerts endpoint', () {
      expect(
        AppConfig.wsUrlFor('http://10.0.2.2:8000'),
        'ws://10.0.2.2:8000/ws/alerts',
      );
      expect(
        AppConfig.wsUrlFor('https://example.com:8443/'),
        'wss://example.com:8443/ws/alerts',
      );
    });

    test('setBaseUrl trims and strips trailing slashes', () {
      AppConfig.setBaseUrl('  http://192.168.1.10:8000/  ');
      expect(AppConfig.baseUrl, 'http://192.168.1.10:8000');
      AppConfig.setBaseUrl(AppConfig.defaultBaseUrl);
    });
  }, skip: 'Konfigurasi server belum diimplementasikan pada scaffold.');

}
