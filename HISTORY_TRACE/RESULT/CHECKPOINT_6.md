# CHECKPOINT 6: Pembekuan Baseline Lokal

**Tanggal pemeriksaan:** 8 Oktober 2026  
**Repositori:** Commencys, working tree lokal  
**Status Git:** belum dikomit dan belum dikirim ke remote

Checkpoint ini mencatat keadaan scaffold, konfigurasi dependensi, dan pemeriksaan lokal sebagai baseline untuk pekerjaan berikutnya. Pembekuan ini tidak menyatakan bahwa seluruh fitur sudah selesai atau bebas bug. Semua perubahan lokal yang sudah ada tetap dipertahankan.

## Cakupan dan batas sistem

Commencys memiliki tiga peran yang berbeda: pelapor, relawan, dan admin. Admin menjalankan fungsi operator melalui dashboard. Relawan menggunakan widget untuk melihat penawaran tugas dan memberi keputusan. Operator bukan peran akun tambahan.

Susunan kode sudah menyediakan lokasi bagi aplikasi Flutter, API FastAPI, penyimpanan PostGIS, autentikasi Keycloak, pemrosesan kandidat laporan dengan Laya dan DBSCAN, notifikasi, serta perutean OSRM. Bagian-bagian tersebut masih berupa kerangka untuk mengarahkan implementasi tim:

- Rute API dan lapisan alur kerja belum menjalankan proses laporan, penawaran, penerimaan, atau penolakan secara end-to-end. Endpoint operasional masih dapat mengembalikan HTTP 501.
- Widget relawan, receiver aksi Android, dan gateway tugas sudah memiliki tempat di struktur aplikasi. Permintaan keputusan belum terhubung sampai ke layanan backend; tampilan scaffold tidak membuktikan bahwa penugasan berhasil.
- Lapisan autentikasi, penyimpanan, notifikasi, dan perutean belum menjadi layanan yang berfungsi. Konfigurasi Keycloak dan paket Flutter terkait tidak menggantikan integrasi OIDC yang belum selesai.
- Berkas migrasi SQL masih berupa komentar. Belum ada DDL aktif, kelas model data, koneksi database operasional, maupun data produk.
- Dependensi Laya tersedia di lingkungan Python, tetapi bobot model belum diunduh, inferensi belum diaktifkan, dan kinerja pada data Indonesia belum dievaluasi. Pustaka DBSCAN juga belum menjalankan pengelompokan pada alur laporan.
- Konfigurasi OSRM dan skrip persiapan data tersedia, tetapi data OSM PBF, hasil preprocessing, rute, dan ETA belum tersedia.

## Lingkungan dan dependensi

- Android SDK dan Android user home berada di `D:\Android\Sdk` dan `D:\Android\UserHome`. Pub, Gradle, pip, Hugging Face, Torch, dan data OSRM diarahkan ke `D:\Commencys-Cache`.
- Lingkungan Python aktif berada di `D:\Commencys-Cache\Python\commencys` dengan Python 3.11.15. Paket terpasang mencakup FastAPI 0.142.4, Psycopg 3.3.6, PyJWT 2.15.1, Laya 0.4.0, Hugging Face Hub 1.33.0, scikit-learn 1.9.1, PyTorch 2.14.1, Transformers 5.19.0, dan pytest 8.4.2.
- Flutter SDK yang terdeteksi sudah ada di `C:\Users\Reinathan\develop\flutter` dan berukuran sekitar 3,04 GB; SDK tersebut tidak dipindahkan saat pembersihan repo. Android SDK dan cache build berada di D:. APK debug yang sebelumnya berhasil dibangun disimpan di `D:\Commencys-Cache\FlutterBuild\build\app\outputs\flutter-apk\app-debug.apk` dan berukuran sekitar 153,6 MB.
- `compose.yaml` mendefinisikan PostGIS 16-3.5, Mailpit 1.31.4, Keycloak 26.8.0, dan OSRM 26.10-debian. Konfigurasi Compose dapat divalidasi, tetapi daemon Docker tidak tersedia saat pemeriksaan ini. Image belum ditarik dan layanan belum dijalankan.

## Pemeriksaan yang tercatat

- `pip check` melaporkan tidak ada dependensi Python yang rusak; impor paket API dan AI berhasil.
- `docker compose config --quiet` berhasil memvalidasi konfigurasi layanan.
- Skrip PowerShell di `tools/` lolos pemeriksaan sintaks dan konfigurasi realm Keycloak dapat dibaca sebagai JSON.
- `git diff --check` tidak menemukan kesalahan whitespace. Git hanya menampilkan peringatan normal tentang konversi akhir baris LF dan CRLF pada berkas kerja Windows.
- Build APK debug dan analisis Flutter pernah berhasil pada pemeriksaan sebelumnya. APK tetap tersedia di D:. Percobaan analisis Flutter ulang pada sesi penutupan ini tidak menghasilkan keluaran sebelum batas waktu perintah, sehingga tidak dipakai sebagai hasil verifikasi baru.
- Pemeriksaan ini tidak menjalankan rangkaian unit atau integrasi test dan tidak menguji aplikasi pada perangkat. Keberhasilan konfigurasi atau build tidak membuktikan bahwa alur produk sudah berfungsi.

## Pembersihan dan keadaan berkas

Cache yang dapat dibuat ulang telah dihapus dari repositori: `.venv` lama, `.dart_tool`, `.pytest_cache` di root dan backend, `android/.gradle`, berkas `.flutter-plugins-dependencies`, serta direktori `__pycache__`. Entri `android/.gradle/` ditambahkan ke `.gitignore` agar cache lokal tersebut tidak masuk ke perubahan Git. Direktori build Flutter proyek sudah berada di D: dan APK-nya dipertahankan.

Ruang kosong C: naik dari sekitar 2,34 GB menjadi 3,58 GB setelah pembersihan. Lingkungan Python aktif, Android SDK, cache dependensi, dan APK di D: tidak dihapus. Berkas sumber, `pubspec.lock`, dokumen PDF, Markdown, gambar, dan berkas data proyek dipertahankan. PDF dan naskah Bab 1 sampai Bab 3 tidak diubah pada tahap penutupan ini; selain `.gitignore`, hanya checkpoint ini yang diperbarui.

## Status pembekuan

Keadaan pada working tree lokal setelah pembersihan menjadi acuan checkpoint ini. Tidak ada commit atau push. Scaffold dan dependensi sudah dipetakan, tetapi aktivasi database, autentikasi, inferensi AI, clustering, notifikasi, routing, alur keputusan relawan, dan pengujian end-to-end tetap menjadi pekerjaan implementasi berikutnya.
