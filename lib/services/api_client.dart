// Batas REST aplikasi Flutter pelapor dan API Commencys.
// Dashboard admin memiliki klien JavaScript; widget relawan memiliki batas Android native.
// Metode di sini hanya mencakup baca/pengiriman konsumen dan rute pascapenerimaan tugas.
import 'package:http/http.dart' as http;

import 'app_config.dart';

class ApiClient {
  // Batas waktu rancangan untuk permintaan REST; belum diterapkan tanpa transport aktif.
  static const requestTimeout = Duration(seconds: 10);

  final String? _baseUrlOverride;
  final http.Client _client;

  // Terima URL dasar dan klien HTTP agar dependensi mudah diganti saat pengujian.
  // Klien yang diberikan menjadi milik instance ini dan ditutup melalui dispose().
  ApiClient({String? baseUrl, http.Client? client})
      : _baseUrlOverride = baseUrl,
        _client = client ?? http.Client();

  // Pilih URL khusus instance terlebih dahulu, lalu gunakan konfigurasi aplikasi.
  // Nilai ini belum menjamin server dapat dijangkau atau mendukung rute Commencys.
  String get baseUrl => _baseUrlOverride ?? AppConfig.baseUrl;

  // GET /api/incidents; kembalikan daftar laporan yang boleh dilihat pengguna.
  // Kredensial berasal dari sesi pengguna; server membatasi laporan dan lokasi yang terlihat.
  // Implementasi kelak menangani status HTTP, batas waktu, dan bentuk respons API.
  Future<List<Map<String, dynamic>>> fetchIncidents({
    required String authorizationHeader,
  }) async {
    throw UnimplementedError(
        'Pembacaan daftar laporan belum diimplementasikan');
  }

  // GET /api/incidents/{ticketId}; ambil satu laporan yang dapat diakses pemanggil.
  // Kredensial berasal dari sesi pengguna; ID pada rute tidak membuktikan hak akses.
  // Implementasi kelak membedakan respons tidak ditemukan dan kegagalan layanan.
  Future<Map<String, dynamic>> fetchIncident({
    required String ticketId,
    required String authorizationHeader,
  }) async {
    throw UnimplementedError(
        'Pembacaan rincian laporan belum diimplementasikan');
  }

  // POST /api/incidents dengan isi, tingkat keparahan, dan sumber koordinat pelapor.
  // Respons JSON hanya boleh dianggap tanda terima setelah server menyimpan laporan.
  // Isian GPS atau manual harus berasal dari pilihan yang dapat dijelaskan kepada pengguna.
  Future<Map<String, dynamic>> createIncident({
    required String title,
    required String description,
    required String category,
    required double latitude,
    required double longitude,
    double? accuracyM,
    required String locationSource,
    required String severity,
    required String reporterName,
  }) async {
    throw UnimplementedError('Pengiriman laporan belum diimplementasikan');
  }

  // POST /api/sos dan kirim idempotencyKey agar percobaan ulang tidak membuat SOS ganda.
  // Tanda terima berarti laporan tersimpan; tidak membuktikan pemberitahuan atau bantuan.
  // Jalur ini tidak boleh menunggu triase AI, pengelompokan, atau layanan rute.
  Future<Map<String, dynamic>> sendSos({
    required String idempotencyKey,
    required double latitude,
    required double longitude,
    double? accuracyM,
    required String locationSource,
    String? description,
    required String reporterName,
  }) async {
    throw UnimplementedError('Pengiriman SOS belum diimplementasikan');
  }

  // GET /api/eta untuk peta setelah widget relawan mengonfirmasi penerimaan tugas.
  // Sertakan kredensial sesi; server memeriksa tugas yang diterima sebelum menghitung rute.
  // Handoff intent dari widget ke layar peta belum tersedia; ETA tetap sebuah perkiraan.
  Future<Map<String, dynamic>> fetchEta({
    required String incidentId,
    required double fromLatitude,
    required double fromLongitude,
    required String authorizationHeader,
  }) async {
    throw UnimplementedError('Estimasi rute belum diimplementasikan');
  }

  // Tutup klien HTTP instance ini agar koneksi dan sumber daya transport dilepas.
  // Pemanggil tidak boleh memakai kembali klien setelah shell aplikasi dibuang.
  void dispose() {
    _client.close();
  }
}
