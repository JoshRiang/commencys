# FROMCHAPTER1_2: Ketertelusuran Bab 1 ke Repositori

**Baseline kebutuhan, i = 0:** [Bab 1 Commencys](../../RESULT/CHAPTER_1.md), ditinjau bersama Chapter1.pdf dan revisi keputusan proyek sampai 8 Oktober 2026.  
**Baseline kode, j = 0:** scaffold lokal yang belum dikomit pada 8 Oktober 2026.  
**Tujuan:** membedakan kebutuhan bab, rancangan sasaran, dan keadaan yang benar-benar tersedia pada kode.

Chapter1.pdf tetap menjadi sumber historis untuk isi yang diajukan pada saat itu. Keputusan antarmuka yang lebih baru dalam Bab 1 menetapkan widget Android untuk pelapor, widget tugas untuk relawan, dashboard admin/operator, serta Flutter sebagai wadah alur laporan setelah widget pelapor dibuka. Operator adalah fungsi admin pada dashboard, bukan peran tambahan. Usulan IndoBERT pada bahan awal diperbarui menjadi kandidat Laya Multilingual. Pembaruan ini tidak mengubah isi PDF sumber.

## Aturan pembacaan status

- **Ada sebagai scaffold** berarti hanya ada deklarasi, batas, tampilan statis, atau fungsi kosong.
- **Belum diterapkan** berarti perilaku operasional tidak ditemukan pada source yang diperiksa.
- **Target** berarti kebutuhan atau usulan di dokumen, bukan bukti implementasi.
- **Terverifikasi** hanya berlaku untuk pemeriksaan yang disebutkan secara khusus. Pemeriksaan sintaks tidak membuktikan alur pengguna.

## Matriks ketertelusuran

| Kebutuhan dari Bab 1 | Sasaran pada dokumen | Bukti pada baseline kode j = 0 | Status yang benar |
|---|---|---|---|
| Laporan komunitas melengkapi informasi publik tanpa menggantikan layanan darurat resmi. | Batas penggunaan dan tujuan prototipe. | README menyatakan repositori bukan layanan darurat; tidak ada integrasi dispatch resmi. | Batas produk tertulis; layanan operasional belum ada. |
| Warga mengirim laporan berlokasi atau SOS. | Widget konsumen membuka alur laporan; laporan membawa lokasi dan informasi kejadian. | Widget dan layar Flutter berupa kerangka. Widget tidak memulai SOS; Flutter tidak meminta lokasi atau mengirim laporan. | Tampilan dan batas komponen ada; alur pengiriman belum diterapkan. |
| Pelapor menerima tanda terima yang jujur setelah laporan tersimpan. | Laporan harus disimpan sebelum sistem mengonfirmasi penerimaan. | Route operasional FastAPI mengembalikan HTTP 501; belum ada penyimpanan laporan atau tanda terima. | Kebutuhan sasaran; belum diterapkan. |
| Lokasi dapat berasal dari GPS atau pemilihan manual. | Sumber dan akurasi lokasi perlu diketahui; ada jalur cadangan saat GPS gagal. | Layanan lokasi dan pemilih titik adalah batas/kerangka; tidak meminta izin lokasi atau mengirim koordinat. | Belum diterapkan dan belum diuji pada perangkat. |
| Operator meninjau laporan melalui dashboard terpisah. | Dashboard mendukung peninjauan manusia dan koordinasi. | Struktur HTML/CSS dashboard tersedia; pengambilan data dan tindakan JavaScript tidak aktif. | Struktur antarmuka ada; fungsi dashboard belum diterapkan. |
| Backend menyediakan API untuk alur laporan dan koordinasi. | Kontrak laporan, status, tinjauan, dan tindakan harus didefinisikan. | FastAPI memiliki health route dan deklarasi route; route operasional mengembalikan HTTP 501. | Batas endpoint ada; perilaku API belum diterapkan. |
| Laporan dan jejak perubahan disimpan secara tahan lama. | Basis data sasaran perlu menjaga laporan sumber dan riwayat perubahan. | `StateStore` adalah protokol dan adapter SQLite tidak aktif. Tidak ada koneksi database atau skema yang berjalan. | Belum diterapkan; PostgreSQL/PostGIS tetap rancangan sasaran. |
| Triase memberi saran kategori dan urgensi untuk ditinjau manusia. | IndoBERT pada proposal awal; usulan kelompok kemudian memilih Laya Multilingual sebagai kandidat evaluasi. | Paket `laya` dan import tersedia. Tidak ada router, checkpoint, inferensi, dataset, atau evaluasi. | Kandidat dependensi saja; model belum dipakai atau dipilih berdasarkan hasil. |
| Sistem menandai laporan yang mungkin berkaitan. | DBSCAN dapat membantu menemukan kandidat berdasarkan lokasi dan waktu tanpa melebur laporan sumber. | `scikit-learn` dan import `DBSCAN` tersedia. Tidak ada persiapan data, pemanggilan algoritma, atau pembaruan relasi laporan. | Import saja; pencarian kandidat belum diterapkan. |
| Pengguna berwenang menerima pembaruan status. | WebSocket dan pemuatan ulang status mendukung koordinasi. | Route WebSocket menutup koneksi dengan kode kegagalan; klien tidak membuka koneksi aktif. | Batas teknis ada; pengiriman status belum berjalan. |
| Relawan menerima atau menolak tugas dari widget; admin mengoordinasikan tindak lanjut. | Penawaran, pemberitahuan, keputusan relawan, kedatangan, dan penyelesaian adalah status berbeda. | Widget tugas dan API offer/feed/accept/reject berupa scaffold; autentikasi dan perubahan status persisten belum aktif. | Hanya kebutuhan dan model sasaran. |
| Rute dan ETA membantu relawan setelah tugas diterima. | Layanan rute dapat dipertimbangkan setelah status penerimaan tugas jelas. | Tidak ada pemanggilan OSRM atau perhitungan ETA operasional. | Target; belum diterapkan. |
| Data lokasi, identitas, dan saran model dilindungi. | Kebijakan akses, retensi, penghapusan, dan koreksi perlu ditetapkan. | Tidak ada autentikasi, kontrol peran, atau penyimpanan data operasional untuk ditegakkan. | Belum diterapkan; kepatuhan hukum belum dinilai. |
| Sistem memenuhi target waktu dan kualitas yang disepakati. | Sasaran tanda terima di bawah lima detik harus mempunyai metode ukur dan lingkungan uji. | Route laporan belum beroperasi; tidak ada hasil beban, latensi, atau evaluasi model. | Target belum diuji; tidak ada klaim performa yang dapat dibuat. |
| Tim bekerja secara iteratif dan meninjau hasil. | Bab 1 dan Bab 2 menjelaskan metode serta artefak yang direncanakan. | Dokumen perencanaan tersedia, tetapi repositori bukan bukti rapat, persetujuan, kapasitas, atau pelaksanaan iterasi. | Metode terdokumentasi; praktik tim tidak dapat diverifikasi dari kode. |

## Peta source untuk pemeriksaan berikutnya

- `backend/app/main.py`: health response, deklarasi API, HTTP 501, dan penutupan WebSocket.
- `backend/app/ai_pipeline.py`: import Laya dan DBSCAN serta fungsi analisis yang belum diimplementasikan.
- `backend/app/storage.py`: protokol penyimpanan dan adapter placeholder.
- `lib/`, `android/app/src/main/`, dan `web/`: kerangka antarmuka konsumen dan operator.
- [ABOUT_1: keadaan codebase](../ABOUT/ABOUT_1_CODEBASE_CURRENT_STATE.md): inventaris komponen, dependency, dan pemeriksaan lokal.
- [ABOUT_2: audit kebenaran Markdown terhadap kode](../ABOUT/ABOUT_2_MARKDOWN_CODE_TRUTH_AUDIT.md): aturan status dan bukti pemeriksaan.

## Hasil pemeriksaan dan batasnya

Python compilation, import FastAPI dan modul AI, pemeriksaan sintaks JavaScript, parsing delapan berkas Android XML, serta `pip check` lulus pada pemeriksaan lokal 8 Oktober 2026. Import Laya dan DBSCAN juga lulus. Pytest mengumpulkan 39 kasus backend dan melewati semuanya karena penanda penundaan pada tingkat suite; tidak ada assertion perilaku yang dijalankan. Percobaan analisis dan tes Flutter tidak menghasilkan keluaran dan dihentikan, sehingga status Dart dan Flutter belum terverifikasi. Tidak ada klaim bahwa build Android, uji perangkat, beban, model, privasi, atau alur darurat telah lulus.

Dokumen ini memakai Bab 1 sebagai baseline kebutuhan dan memeriksa source apa adanya. Diagram target dan naskah bab tidak diperlakukan sebagai bukti runtime. Hasil perubahan source yang lebih lama dalam catatan [FROMCHAPTER1_1](FROMCHAPTER1_1_FOUNDATION.md) atau [FORUML](../FORUML/) tetap bersifat historis jika membahas implementasi sebelum scaffold saat ini.
