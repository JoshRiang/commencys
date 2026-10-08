# CHECKPOINT 3

**Catatan status, 8 Oktober 2026:** checkpoint ini merekam pembuatan Bab 3 pada 7 Oktober. Gunakan [CHECKPOINT_5](CHECKPOINT_5.md) untuk status dokumen dan codebase terbaru.

## Cakupan

Bab 3 dan tiga diagram UML sasaran Commencys telah disiapkan. Modelnya diselaraskan dengan Bab 1, Bab 2, Checkpoint 0 sampai 2, serta catatan `FORUML` dan referensi pemodelan yang tersimpan di `MD`. Diagram menggambarkan rancangan yang hendak dibangun, bukan klaim bahwa seluruh fungsi dan integrasi sudah tersedia di kode.

## Artefak yang dibuat

- `RESULT/CHAPTER_3.md` berisi penjelasan dalam Bahasa Indonesia, tiga diagram, hubungan antarbagian model, hal yang masih perlu diputuskan, dan daftar pustaka.
- `RESULT/UML_PICTURE/GAMBAR_3_1_USE_CASE.mmd`, `.png`, dan `.jpg` berisi diagram use case.
- `RESULT/UML_PICTURE/GAMBAR_3_2_INTERACTION_OVERVIEW.mmd`, `.png`, dan `.jpg` berisi ikhtisar interaksi pengiriman laporan atau SOS, analisis pendukung, tinjauan koordinator, dan penerimaan penugasan.
- `RESULT/UML_PICTURE/GAMBAR_3_3_COMPONENT.mmd`, `.png`, dan `.jpg` berisi rancangan komponen klien, aplikasi, analisis, penyimpanan, dan layanan eksternal.
- `RESULT/UML_PICTURE/render_uml_picture.py` membuat berkas PNG dan JPG lokal untuk ketiga diagram.

Gambar di Bab 3 tidak memuat header atau footer. Judul gambar dan keterangannya berada di teks Bab 3 agar dapat dipindahkan ke dokumen.

## Pemeriksaan keselarasan

- Diagram use case menghubungkan warga atau pelapor, relawan, koordinator insiden, dan administrator dengan tujuan yang relevan.
- Diagram ikhtisar interaksi menempatkan validasi sebelum penyimpanan, dan penyimpanan sebelum tanda terima. Analisis Laya Multilingual serta pencarian kandidat DBSCAN berlangsung setelah laporan tersimpan dan tetap bersifat pendukung.
- Pemberitahuan terkirim dibedakan dari pesan yang dibaca, penerimaan penugasan, dan penyelesaian penanganan. Rute dan ETA baru relevan setelah relawan menerima tugas.
- Diagram komponen mempertahankan keputusan teknologi klien yang belum selesai. Laya, DBSCAN, PostgreSQL/PostGIS, riwayat perubahan, kebijakan akses, notifikasi, dan OSRM ditandai sebagai bagian rancangan atau integrasi yang masih perlu dikonfirmasi.
- Ketiga diagram mempertahankan laporan sumber dan tidak menganggap saran model atau kaitan DBSCAN sebagai perubahan otomatis pada laporan.

## Validasi dan batasan

Nama berkas, tautan relatif Bab 3, format PNG/JPG, dan dimensi gambar diperiksa. Gambar dibuka dan ditinjau secara visual setelah ekspor lokal. Sumber Mermaid disimpan berdampingan dengan gambar.

Workspace ini tidak menyediakan Mermaid CLI atau paket Mermaid lokal. Karena itu, gambar PNG/JPG dibuat oleh skrip Pillow lokal dari tata letak yang diselaraskan dengan isi sumber `.mmd`; gambar tersebut bukan hasil eksekusi mesin Mermaid. Sumber `.mmd` ditinjau terhadap dokumentasi Mermaid resmi, tetapi belum divalidasi oleh parser Mermaid. Diagram ikhtisar interaksi menggunakan sintaks flowchart Mermaid untuk merangkum struktur IOD dan bukan berkas model UML native. Batas ini juga dijelaskan pada Bab 3.

## Referensi pemodelan

Daftar pustaka Bab 3 menggunakan sumber buku Braude, spesifikasi UML resmi dari Object Management Group, dan dokumentasi sintaks Mermaid resmi. Catatan analisis internal dan berkas proyek tidak dimasukkan sebagai sumber pustaka.
