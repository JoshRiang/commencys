// Layar konsumen untuk melihat pemberitahuan dan laporan yang tersedia.
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/websocket_service.dart';
import '../theme/app_theme.dart';

class AlertsScreen extends StatelessWidget {
  // Terima batas baca REST dan stream status untuk implementasi berikutnya.
  // Layar saat ini tidak memanggil kedua dependensi dan tidak menyajikan data contoh.
  final ApiClient api;
  final CoordinationSocket socket;

  const AlertsScreen({
    super.key,
    required this.api,
    required this.socket,
  });

  // Tampilkan keadaan awal antrean; daftar, status kosong, dan pembaruan belum terhubung.
  // Implementasi kelak membedakan tanda terima, pemberitahuan, dan tugas yang diterima.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.inbox_outlined,
                  size: 38,
                  color: AppColors.secondary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Daftar laporan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pembacaan API dan pembaruan langsung belum diimplementasikan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.secondary, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
