# CHECKPOINT_2 - Pembaruan Bab 2, Usulan Laya, dan Diagram

**Catatan status, 8 Oktober 2026:** checkpoint ini merekam tahap Bab 2 pada 7 Oktober. Gunakan [CHECKPOINT_5](CHECKPOINT_5.md) untuk status dokumen, codebase, dan verifikasi terbaru.

**Tanggal:** 7 Oktober 2026  
**Tahap:** penyelarasan usulan model, ringkasan Trello, dokumen proyek, dan gambar diagram  
**Nama proyek:** Commencys

## 1. Bahan yang ditelaah

[AI_ANALYZE.md](../DOCUMENTATION/AI_ANALYZE.md) memetakan isi *AI_Powered_Reference.pdf* dan menambahkan pembaruan atas usulan model kelompok. [TRELLO_ANALYZE.md](../DOCUMENTATION/TRELLO_ANALYZE.md) menelaah berkas jawaban dan lima tangkapan layar. Catatan tersebut adalah bahan analisis internal; Bab 2 merujuk bahan proyek asal.

Bahan AI dan jawaban Trello semula menyebut IndoBERT. Kelompok kini mengusulkan Laya Multilingual sebagai kandidat untuk masukan berbahasa Indonesia. Kartu model menyarankan checkpoint multilingual bagi teks non-Inggris, tetapi tidak menyajikan hasil khusus bahasa Indonesia. Kartu tersebut juga mengingatkan bahwa keputusan *zero-shot* masih lemah dan skor perlu dikalibrasi. Bab 2 menyajikan perubahan ini sebagai usulan yang perlu dibandingkan dan diuji, bukan hasil yang sudah terbukti. [Laya](https://huggingface.co/convaiinnovations/laya) dan [Laya Multilingual](https://huggingface.co/convaiinnovations/laya-multilingual).

## 2. Bab 1 dan Bab 2

[CHAPTER_1.md](CHAPTER_1.md) diperbarui untuk memakai nama Commencys dan mencatat perubahan usulan model. Isi tetap berangkat dari dokumen Chapter1.pdf; kondisi repositori tidak digunakan sebagai bukti bagi narasi bab. Asumsi perangkat komputasi model ditulis sebagai hal yang perlu diukur, karena kebutuhan Laya belum diuji.

[CHAPTER_2.md](CHAPTER_2.md) berbahasa Indonesia dan memakai penekanan tebal serta miring seperlunya. Bagian Trello kini hanya merangkum inti pembahasan: utamakan alur SOS dengan fallback, simpan laporan sebelum memberi tanda terima, bedakan pemberitahuan dari penerimaan tugas, bagi tanggung jawab dengan peninjau atau pengganti, dan tetapkan jadwal setelah lingkup serta kapasitas disepakati. Rincian estimasi per tugas dan tanggal pada kartu tidak dimasukkan sebagai janji kerja. Kelima tangkapan layar Trello disertakan dengan keterangan singkat.

Bagian AI Bab 2 menjelaskan perbedaan IndoBERT yang tercantum dalam bahan awal dan Laya Multilingual yang diusulkan kelompok. Laya ditempatkan setelah penyimpanan laporan dan sebagai pemberi saran; hasilnya memerlukan evaluasi lokal, kalibrasi, peninjauan manusia, dan mekanisme kembali ke versi sebelumnya. DBSCAN tetap dijelaskan sebagai proses terpisah untuk mencari kandidat laporan terkait.

## 3. Penyelarasan dokumen proyek dan diagram

Dokumen rencana dan komponen sasaran pada `/docs` serta catatan komponen UML sekarang menyebut Laya Multilingual sebagai usulan. Uraian keadaan berjalan tetap menyatakan bahwa kode memakai aturan kata kunci dan belum menjalankan Laya. Nama Commencys digunakan dalam naskah dan materi yang disusun; nama lama pada URL repositori atau tangkapan layar sumber dipertahankan bila diperlukan untuk menjaga rujukan.

Seluruh diagram PNG yang dihasilkan oleh [render_diagrams.py](DIAGRAMS/render_diagrams.py) dibuat ulang dengan menghilangkan pita judul dan catatan penutup. Perubahan mencakup diagram Bab 1 dan Bab 2, diagram use case, interaction overview, diagram komponen, serta gambar arsitektur dan alur pada `/docs`. Tangkapan layar Trello adalah bahan sumber dan tidak diubah.

## 4. Pemeriksaan dan batas klaim

- Diagram hasil render ditinjau secara visual untuk memastikan isi utama tidak terpotong setelah bingkai dihilangkan.
- Bab 2 tidak menetapkan estimasi hari kerja atau tanggal kalender sebagai komitmen tim.
- Tidak ada klaim bahwa Laya sudah dipasang, dilatih, dikalibrasi, atau diuji pada laporan Commencys.
- Kualitas model harus diukur pada data Indonesia yang ditinjau; keterangan kinerja pada kartu model adalah klaim penerbit model, bukan evaluasi independen Commencys.
- Pengujian aplikasi tidak dijalankan. Tidak ada hasil uji perangkat, lapangan, produksi, keamanan, hukum, atau respons darurat yang diklaim.

## 5. Artefak utama

- [Bab 1](CHAPTER_1.md)
- [Bab 2](CHAPTER_2.md)
- [Analisis referensi AI](../DOCUMENTATION/AI_ANALYZE.md)
- [Analisis Trello](../DOCUMENTATION/TRELLO_ANALYZE.md)
- [Diagram Bab 1](DIAGRAMS/chapter1_logical_architecture.png) dan [sumber Mermaid](DIAGRAMS/chapter1_logical_architecture.mmd)
- [Diagram Bab 2](DIAGRAMS/chapter2_delivery_roadmap.png) dan [sumber Mermaid](DIAGRAMS/chapter2_delivery_roadmap.mmd)
- [Renderer diagram](DIAGRAMS/render_diagrams.py)
- [Checkpoint 0](CHECKPOINT_0.md) dan [Checkpoint 1](CHECKPOINT_1.md)
