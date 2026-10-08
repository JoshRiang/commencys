// Konfigurasi alamat layanan yang dibaca oleh adapter REST dan WebSocket.
// Penyimpanan pilihan pengguna dan pemetaan URL per platform belum diputuskan.
class AppConfig {
  // Nilai awal untuk emulator Android; bukan alamat produksi atau bukti server aktif.
  // Dapat diganti saat proses build melalui argumen API_BASE.
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:8000',
  );

  // Baca alamat yang dikompilasi sampai penyimpanan konfigurasi disepakati.
  // Saat ini setter tidak menyimpan perubahan dan getter selalu memakai nilai awal.
  static String get baseUrl => defaultBaseUrl;

  // Simpan URL pilihan pengguna setelah format, persistensi, dan validasinya disepakati.
  // Parameter value adalah alamat backend; setter saat ini sengaja tidak mengubah state.
  static void setBaseUrl(String value) {
    throw UnimplementedError(
        'Penyimpanan alamat server belum diimplementasikan');
  }

  // Ubah skema HTTP(S) menjadi WS(S) dan pertahankan host serta path yang diperlukan.
  // Kebijakan path, query, dan validasi URL harus ditetapkan sebelum implementasi.
  static String wsUrlFor(String baseUrl) {
    throw UnimplementedError(
        'Pembentukan alamat WebSocket belum diimplementasikan');
  }
}
