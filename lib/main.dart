// Titik masuk aplikasi konsumen Commencys; bukan dashboard operator.
import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'theme/app_theme.dart';

void main() {
  // Mulai shell konsumen yang memuat peta, laporan, formulir, dan pintasan SOS.
  // Layar masih berupa kerangka dan tidak mengirim data ke layanan.
  runApp(const CommencysApp());
}

class CommencysApp extends StatelessWidget {
  // Simpan tujuan awal yang dapat diteruskan oleh deep link atau pintasan widget.
  // Rute hanya memilih tab; rute tersebut tidak mengirim SOS secara otomatis.
  final String initialRoute;

  const CommencysApp({super.key, this.initialRoute = '/'});

  // Daftarkan tema, pemetaan rute aplikasi, dan shell navigasi konsumen.
  // Rute yang tidak dikenal kembali ke tab peta melalui shell bawaan.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Commencys',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: initialRoute,
      // Satu tabel rute menjadi pemetaan tunggal untuk pintasan internal aplikasi.
      // Integrasi intent widget ke `initialRoute` masih perlu disiapkan di MainActivity.
      routes: {
        '/': (context) => const AppShell(),
        '/sos': (context) => const AppShell(initialTab: 3),
        '/report': (context) => const AppShell(initialTab: 2),
        '/map': (context) => const AppShell(initialTab: 0),
        '/alerts': (context) => const AppShell(initialTab: 1),
      },
    );
  }
}
