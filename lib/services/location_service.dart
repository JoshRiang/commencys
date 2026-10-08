// Adapter lokasi perangkat untuk laporan yang memakai GPS atau titik manual.
// Izin, pembacaan posisi, dan nilai akurasi belum dihubungkan ke aplikasi.
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Periksa layanan lokasi serta minta izin yang diperlukan sebelum membaca GPS.
  // Hasil false berarti UI harus menawarkan pemilihan manual atau menjelaskan batasnya.
  Future<bool> ensurePermission() async {
    throw UnimplementedError('Pemeriksaan izin lokasi belum diimplementasikan');
  }

  // Ambil posisi beserta akurasi horizontal yang sudah disediakan oleh Position.
  // Null berarti posisi tidak didapat; pemanggil harus menawarkan titik manual.
  Future<Position?> currentPosition() async {
    throw UnimplementedError('Pengambilan lokasi belum diimplementasikan');
  }
}
