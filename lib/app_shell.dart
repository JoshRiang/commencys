// Shell navigasi untuk permukaan konsumen; dashboard human-in-the-loop terpisah di web.
import 'package:flutter/material.dart';

import 'screens/alerts_screen.dart';
import 'screens/map_screen.dart';
import 'screens/report_screen.dart';
import 'screens/sos_screen.dart';
import 'services/api_client.dart';
import 'services/websocket_service.dart';

class AppShell extends StatefulWidget {
  // Terima tab awal; nilai 0-3 memilih peta, laporan, buat laporan, atau SOS.
  // Pintasan SOS hanya membuka layar dan tidak menandakan laporan sudah terkirim.
  final int initialTab;

  const AppShell({super.key, this.initialTab = 0});

  // Buat state yang mengelola tab dan siklus hidup dependensi aplikasi.
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index;
  late final ApiClient _api;
  late final CoordinationSocket _socket;

  // Buat adapter yang akan dibagikan oleh layar tanpa membuka koneksi jaringan.
  // Indeks dibatasi agar nilai rute yang tidak valid tidak merusak navigasi.
  @override
  void initState() {
    super.initState();
    _index = widget.initialTab.clamp(0, 3).toInt();
    _api = ApiClient();
    _socket = CoordinationSocket();
  }

  // Lepaskan stream dan klien HTTP yang dimiliki shell sebelum widget dibuang.
  @override
  void dispose() {
    _socket.dispose();
    _api.dispose();
    super.dispose();
  }

  // Perbarui tab aktif setelah interaksi navigasi atau callback layar selesai.
  // Callback laporan belum dipanggil karena pengiriman belum tersedia.
  void _go(int index) {
    setState(() => _index = index);
  }

  // Susun layar konsumen dalam IndexedStack agar state tab tetap terjaga.
  // NavigationBar adalah navigasi aplikasi, bukan dashboard operator atau situs pemasaran.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          MapScreen(api: _api, socket: _socket),
          AlertsScreen(api: _api, socket: _socket),
          ReportScreen(api: _api, onSubmitted: () => _go(1)),
          SosScreen(api: _api, socket: _socket),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _go,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Peta',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Laporan',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Buat',
          ),
          NavigationDestination(
            icon: Icon(Icons.sos_outlined),
            selectedIcon: Icon(Icons.sos),
            label: 'SOS',
          ),
        ],
      ),
    );
  }
}
