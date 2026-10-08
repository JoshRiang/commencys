// Layar konsumen untuk membuat laporan insiden biasa.
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';

class ReportScreen extends StatelessWidget {
  // Terima API dan callback navigasi yang kelak dijalankan setelah tanda terima sah.
  // Keduanya dipertahankan sebagai kontrak; formulir saat ini tidak mengirim data.
  final ApiClient api;
  final VoidCallback onSubmitted;

  const ReportScreen({
    super.key,
    required this.api,
    required this.onSubmitted,
  });

  // Tampilkan bidang laporan yang direncanakan dengan kontrol nonaktif.
  // Implementasi kelak memvalidasi isi dan lokasi, lalu mengirim hanya melalui API.
  // Navigasi ke daftar laporan dilakukan setelah server mengonfirmasi penyimpanan.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat laporan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            Text(
              'Formulir laporan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              'Kerangka antarmuka. Pengiriman laporan belum tersedia.',
              style: TextStyle(color: AppColors.secondary),
            ),
            SizedBox(height: 18),
            TextField(
              enabled: false,
              decoration: InputDecoration(labelText: 'Judul kejadian'),
            ),
            SizedBox(height: 12),
            TextField(
              enabled: false,
              maxLines: 3,
              decoration: InputDecoration(labelText: 'Ringkasan kejadian'),
            ),
            SizedBox(height: 12),
            TextField(
              enabled: false,
              decoration: InputDecoration(labelText: 'Kategori'),
            ),
            SizedBox(height: 12),
            TextField(
              enabled: false,
              decoration: InputDecoration(labelText: 'Lokasi kejadian'),
            ),
            SizedBox(height: 20),
            FilledButton(
              onPressed: null,
              child: Text('Pengiriman belum tersedia'),
            ),
          ],
        ),
      ),
    );
  }
}
