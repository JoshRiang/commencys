// Layar konsumen untuk alur SOS; bukan kanal layanan darurat yang telah beroperasi.
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/websocket_service.dart';
import '../theme/app_theme.dart';

class SosScreen extends StatelessWidget {
  // Terima API dan stream status yang direncanakan untuk tanda terima serta pembaruan.
  // Tidak ada panggilan layanan sampai penyimpanan dan kebijakan penerima tersedia.
  final ApiClient api;
  final CoordinationSocket? socket;

  const SosScreen({
    super.key,
    required this.api,
    this.socket,
  });

  // Jelaskan batas scaffold dan pertahankan tindakan kirim dalam keadaan nonaktif.
  // Versi operasional harus mendukung lokasi manual, tanda terima setelah simpan,
  // percobaan ulang idempoten, dan status yang tidak menjanjikan bantuan.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOS')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sos, size: 48, color: AppColors.accent),
                const SizedBox(height: 16),
                Text(
                  'Laporan SOS',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kerangka ini belum mengambil lokasi atau mengirim laporan. Hubungi layanan darurat resmi bila membutuhkan bantuan segera.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.secondary, height: 1.45),
                ),
                const SizedBox(height: 20),
                const SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: null,
                    child: Text('Pengiriman belum tersedia'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
