# CHECKPOINT 4: Dokumen DOCX, PDF, dan pemeriksaan akhir

**Catatan status, 8 Oktober 2026:** ini adalah catatan pemeriksaan ekspor sebelumnya. Berkas Bab 1 sampai 3 kemudian diperbarui dan diekspor ulang; jumlah halaman dan hasil yang tercatat di bawah tidak menggambarkan ekspor saat ini. Gunakan [CHECKPOINT_5](CHECKPOINT_5.md) sebagai status terbaru.

## Artefak bab

Bab 1, Bab 2, dan Bab 3 disimpan sebagai dokumen terpisah. Naskah sumber tetap berada di `RESULT/CHAPTER_1.md`, `RESULT/CHAPTER_2.md`, dan `RESULT/CHAPTER_3.md`.

- `RESULT/CHAPTER_1.docx` dan `PDF/Commencys_CHAPTER_1.pdf`
- `RESULT/CHAPTER_2.docx` dan `PDF/Commencys_CHAPTER_2.pdf`
- `RESULT/CHAPTER_3.docx` dan `PDF/Commencys_CHAPTER_3.pdf`

DOCX memakai Times New Roman 12 pt untuk isi, spasi 1,5, hierarki judul, tabel berulang dengan judul kolom, penekanan tebal dan miring dari Markdown, serta halaman A4. Halaman yang memuat diagram atau tangkapan layar menggunakan orientasi lanskap. Gambar Bab 1, gambar alur kerja Bab 2, lima tangkapan Trello, dan tiga diagram UML disematkan ke dokumen masing-masing.

## Hasil pemeriksaan

- Tiga arsip DOCX dapat dibuka sebagai ZIP Office Open XML. Gaya isi tercatat memakai Times New Roman 12 pt dan spasi 1,5. Jumlah gambar tertanam adalah satu pada Bab 1, enam pada Bab 2, dan tiga pada Bab 3.
- Teks bab, DOCX, dan PDF tidak mengandung karakter pengganti Unicode. Tautan internal pada Markdown yang diperiksa mengarah ke berkas yang tersedia.
- Semua 30 halaman PDF dirender menjadi gambar untuk pemeriksaan visual. Gambar diagram dan tangkapan Trello terlihat, halaman kosong yang sempat muncul pada PDF Bab 2 telah dihapus, dan susunan akhir tidak menunjukkan teks terpotong.
- PDF akhir terdiri atas 8 halaman untuk Bab 1, 15 halaman untuk Bab 2, dan 7 halaman untuk Bab 3. Halaman gambar menggunakan orientasi lanskap.
- PDF Bab 1 mempertahankan cakupan dan panjang naskah yang mendekati bahan Chapter1.pdf. Perbedaan jumlah halaman berasal dari ukuran A4 dan tata letak dokumen baru.

## Sanitasi dokumentasi repositori

Tidak ditemukan berkas bernama `GITREPO.md`. Pemeriksaan akhir karena itu mencakup `README.md` dan berkas Markdown di `/docs`, tanpa menganggap naskah bab sebagai deskripsi repositori.

Di `docs/01-analysis.md`, kriteria penerimaan relawan kini membedakan pemberitahuan, kesediaan menerima atau menolak tugas, dan status dispatch. Dokumen itu juga tidak lagi menyatakan bahwa pengiriman notifikasi berarti relawan telah menerima tugas. Di `docs/01-analysis.md` dan `docs/evaluation-monitoring.md`, target keberhasilan WebSocket sebesar 99 persen dihapus karena kebijakan penerima dan cara pengukurannya belum ditentukan. Uraian repositori tetap membedakan implementasi yang tersedia dari rancangan Laya, DBSCAN, PostGIS, OSRM, dan fitur lain yang masih berupa usulan.

Perubahan kode dan perubahan working tree lain tidak disentuh dalam tahap ini. Pengujian perangkat lunak tidak dijalankan.

## Batas konversi dan validasi

Mesin kerja ini tidak menyediakan Microsoft Word atau LibreOffice (`soffice.exe`), sehingga renderer DOCX standar tidak dapat dijalankan. PDF dibuat dengan tata letak yang mengikuti sumber Markdown yang sama, bukan melalui konversi langsung dari DOCX. Karena itu, PDF telah ditinjau secara visual, sedangkan tampilan akhir DOCX di Word atau LibreOffice belum dapat dipastikan identik. Struktur DOCX, gaya, teks, gambar tertanam, dan karakter Unicode telah diperiksa secara terprogram.
