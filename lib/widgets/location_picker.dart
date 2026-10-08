// Pemilih titik manual untuk laporan ketika GPS tidak tersedia atau tidak dipilih.
// Peta interaktif dan pengembalian koordinat belum diimplementasikan.
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';

Future<LatLng?> pickLocationOnMap(
  BuildContext context, {
  LatLng? initialCenter,
}) {
  // Buka bottom sheet; nilai hasil yang direncanakan adalah titik pilihan atau null.
  // Tombol konfirmasi nonaktif sehingga scaffold saat ini tidak menghasilkan titik baru.
  return showModalBottomSheet<LatLng>(
    context: context,
    useSafeArea: true,
    builder: (_) => _LocationPicker(initialCenter: initialCenter),
  );
}

class _LocationPicker extends StatelessWidget {
  // Titik awal hanya menjadi pusat peta saat implementasi tersedia, bukan pilihan pengguna.
  final LatLng? initialCenter;

  const _LocationPicker({this.initialCenter});

  // Tampilkan tempat peta, titik awal, dan kendali konfirmasi yang belum aktif.
  // Implementasi perlu membedakan titik terpilih dari posisi GPS yang sekadar diperkirakan.
  @override
  Widget build(BuildContext context) {
    final coordinate = initialCenter == null
        ? 'Lokasi belum dipilih'
        : 'Titik awal peta: ${initialCenter!.latitude}, ${initialCenter!.longitude}';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pilih lokasi laporan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          Container(
            height: 180,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.infoSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: const Icon(
              Icons.map_outlined,
              size: 40,
              color: AppColors.info,
            ),
          ),
          const SizedBox(height: 10),
          Text(coordinate, style: const TextStyle(color: AppColors.secondary)),
          const SizedBox(height: 14),
          const FilledButton(
            onPressed: null,
            child: Text('Pemilihan lokasi belum tersedia'),
          ),
        ],
      ),
    );
  }
}
