// Layar konsumen untuk melihat laporan pada peta.
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/websocket_service.dart';
import '../theme/app_theme.dart';

class MapScreen extends StatelessWidget {
  // Terima layanan laporan dan pembaruan agar batas dependensi terlihat pada scaffold.
  // Peta, marker, pemusatan lokasi, dan akses lokasi belum dijalankan.
  final ApiClient api;
  final CoordinationSocket socket;

  const MapScreen({
    super.key,
    required this.api,
    required this.socket,
  });

  // Tampilkan area peta sasaran tanpa koordinat atau insiden buatan.
  // Implementasi kelak meminta izin, membaca data berakses, dan menjelaskan akurasi lokasi.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Peta insiden')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.infoSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 38, color: AppColors.info),
                SizedBox(height: 12),
                Text(
                  'Ruang peta Commencys',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    'Peta, penanda laporan, dan pemusatan lokasi menunggu layanan lokasi dan data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.secondary, height: 1.4),
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
