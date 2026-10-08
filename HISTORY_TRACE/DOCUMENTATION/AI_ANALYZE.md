# Analisis Referensi AI Commencys

**Pembaruan model:** diperiksa kembali terhadap kartu model resmi pada 8 Oktober 2026. Usulan model dalam proyek adalah *Laya Multilingual*; model belum dimuat atau dievaluasi dalam kode Commencys.

## Tujuan dan batas pembacaan

Catatan ini merangkum [AI_Powered_Reference.pdf](../DOCUMENTATION_AND_AI_BUILDING_BLOCKS/AI_Powered_Reference.pdf), termasuk sketsa arsitektur pada halaman 8 dan file `AI_Powered_Architecture_BuildingBlock.jpeg`. Diagram JPEG telah ditinjau untuk memahami batas dan arus komponen. **JPEG tidak disalin atau ditanamkan di sini** karena sudah diserahkan sebagai artefak tersendiri. Analisis berikut membedakan kebutuhan, usulan, dan bukti; pernyataan dalam bahan diskusi tidak dengan sendirinya membuktikan bahwa fitur telah dibangun atau diuji.

Bahan bertanggal 25 September 2026 memetakan sembilan station AI ke proyek Commencys. Pemetaan tersebut berguna sebagai daftar pertimbangan, tetapi tidak berarti semua station harus masuk ke prototipe. Jalur pelaporan darurat perlu tetap sederhana, dapat dilacak, dan tidak bergantung pada model generatif.

## Ringkasan sembilan station

| Station dalam bahan | Hubungan dengan Commencys | Keputusan dan syarat yang perlu dibawa ke perencanaan |
|---|---|---|
| Data dan pipeline ETL | **Fondasi inti.** Laporan memuat teks, waktu, lokasi, sumber koordinat, dan bukti opsional. | Simpan laporan sumber secara utuh. Validasi skema sebelum menyimpan. Hasil model, perubahan koordinator, dan hubungan antar-laporan dicatat sebagai metadata terpisah agar laporan asal tidak tertimpa. Tetapkan tujuan penggunaan, akses, retensi, dan penghapusan data. |
| Embedding dan vector store | Tidak diperlukan untuk alur SOS inti. | Tunda dari lingkup prototipe. Pertimbangkan hanya untuk pencarian semantik atas SOP atau riwayat insiden pada tahap lanjutan. Pencarian semantik tidak menggantikan pencocokan lokasi dan waktu. |
| API LLM dan rekayasa prompt | Bukan komponen inti. | Jika kelak dipakai untuk ringkasan bagi koordinator, hasilnya bersifat saran dan harus dapat ditelusuri ke laporan sumber. LLM tidak boleh menunda penerimaan SOS, memberi diagnosis medis, atau mengambil keputusan respons. |
| Penyesuaian model dan model khusus | IndoBERT diusulkan dalam bahan awal untuk menyarankan jenis insiden dan tingkat urgensi. Usulan kelompok yang lebih baru mengarah ke Laya Multilingual. | Definisikan taksonomi dan arti operasional setiap label sebelum anotasi. Dataset perlu ditinjau manusia, mewakili bahasa informal, dan dipisahkan dengan mencegah kejadian yang sama masuk ke data latih dan data uji. Skor rendah atau konflik masuk ke tinjauan manusia. |
| RAG | Pilihan pengembangan lanjutan untuk mencari SOP dan panduan. | Jika disetujui, gunakan dokumen resmi yang memiliki pemilik dan versi. Setiap hasil menyebut sumber yang dipakai. RAG tetap berada di luar jalur penerimaan dan penugasan darurat. |
| Pemanggilan fungsi dan agen | Bukan dasar untuk keputusan atau tindakan operasional pada prototipe. | Perubahan tiket, penerimaan tugas, dan status harus melalui alur aplikasi yang deterministik dan berwenang. Asisten masa depan paling jauh dapat membantu pencarian baca-saja atau menyusun draf yang ditinjau manusia. |
| Integrasi aplikasi | Menghubungkan antarmuka warga, relawan, dan koordinator dengan layanan, data, analisis, pembaruan status, serta rute. | Pisahkan jalur transaksi SOS dari analisis asinkron. Simpan tiket sebelum memberi tanda terima. Setelah penyimpanan, analisis klasifikasi dan pencarian kandidat laporan dapat berjalan di luar jalur kritis. DBSCAN adalah algoritma pengelompokan spasial, bukan model bahasa. |
| Evaluasi dan pemantauan | Mengukur keandalan alur, kegunaan keluaran model, pengelompokan, pemberitahuan, dan rute. | Tetapkan definisi metrik, data uji, lingkungan, pemilik, dan ambang sebelum menyatakan hasil. Ukur kesalahan per kelas, terutama laporan gawat yang terlewat; hitung penggabungan keliru dan kejadian berulang yang tidak ditemukan; bandingkan ETA dengan perjalanan yang diamati. |
| AI yang bertanggung jawab dan pengaman | Berlaku pada seluruh alur yang memproses identitas, lokasi, atau saran model. | Batasi lokasi presisi menurut tujuan dan kewenangan. Tampilkan ketidakpastian. Sediakan koreksi manusia dan jejak perubahan yang terlindungi. Jangan menyebut log tidak dapat diubah, model aman, atau sistem patuh hukum tanpa rancangan dan bukti yang mendukung klaim tersebut. |

## Arti untuk rancangan Commencys

### Pembaruan usulan model kelompok

Bahan AI yang ditelaah semula menyebut IndoBERT. Setelah bahan tersebut ditinjau, kelompok mengajukan Laya sebagai pengganti. Alamat `convaiinnovations/laya` menunjuk ke checkpoint bahasa Inggris pada repositori model; checkpoint multibahasa diterbitkan sebagai `convaiinnovations/laya-multilingual` [kartu Laya](https://huggingface.co/convaiinnovations/laya) [kartu Laya Multilingual](https://huggingface.co/convaiinnovations/laya-multilingual). Kartu Laya menyebut dukungan keluarga model untuk lebih dari 100 bahasa, tetapi angka cakupan itu bukan bukti mutu untuk bahasa Indonesia atau laporan Commencys. Pada benchmark keputusan bertipe yang dilaporkan pemilik model, checkpoint dasar Laya dan Laya Multilingual memperoleh akurasi 0,362 dan 0,342; keduanya berada di bawah baseline mayoritas 0,461. Hasil tersebut bukan evaluasi pada data insiden Indonesia. Kartu model juga memperingatkan bahwa probabilitas mentah belum terkalibrasi. Karena itu, Laya Multilingual hanya kandidat yang perlu dibandingkan pada data laporan Indonesia yang ditinjau manusia, dengan pengukuran kesalahan tiap kelas dan kalibrasi yang diuji terpisah. Pilihan ini memperbarui usulan model, bukan menggambarkan implementasi yang sudah ada.

Bahan mengusulkan alur yang terdiri dari aplikasi warga, relawan, dan koordinator; API layanan; penyimpanan PostgreSQL/PostGIS; pemrosesan IndoBERT; pencarian laporan terkait dengan DBSCAN; pembaruan status melalui WebSocket; dan layanan rute OSRM. Susunan ini paling tepat diperlakukan sebagai **rancangan sasaran**. Daftar komponen tidak menjawab sendiri batas transaksi, tanggung jawab data, aturan penerima, atau bukti kesiapan.

Ada tiga jalur yang perlu dipisahkan saat rancangan diterjemahkan ke dokumen proyek:

1. **Penerimaan SOS.** Aplikasi mengirim laporan. Layanan memvalidasi dan menyimpan laporan sumber. Tanda terima diberikan setelah penyimpanan berhasil. Batas lima detik dalam bahan adalah target yang perlu didefinisikan lingkungan ukurnya, bukan hasil pengukuran.
2. **Analisis pendukung.** Dalam bahan awal, IndoBERT memberi saran kategori dan urgensi. Usulan kelompok kini mengarahkan pengujian pada Laya Multilingual; DBSCAN tetap membantu menemukan laporan yang mungkin terkait. Keduanya tidak boleh menghapus isi laporan atau menghalangi pembuatan tiket. Koordinator memeriksa keluaran yang meragukan.
3. **Koordinasi respons.** Status pemberitahuan berbeda dari penerimaan tugas. Relawan harus menyatakan penerimaan tugas sebelum rute dan ETA diperlakukan sebagai panduan perjalanan. Pembaruan status hanya dikirim kepada pengguna yang berwenang.

Jika beberapa laporan dalam satu kejadian memiliki urgensi berbeda, isi dan hasil setiap laporan tetap dipertahankan. Ringkasan kelompok boleh menampilkan urgensi tertinggi yang belum selesai sebagai **indikasi sementara**, jika aturan itu disetujui tim. Ringkasan tersebut tidak menimpa urgensi tiket asal. SOS kritis tidak boleh diturunkan otomatis oleh model; koreksi harus dilakukan oleh koordinator yang berwenang dan dicatat.

## Tinjauan sketsa arsitektur

Sketsa tangan pada halaman 8 dan diagram blok JPEG mengelompokkan arsitektur ke dalam lapisan data dan pengetahuan, model, orkestrasi, aplikasi, serta pengembangan lanjutan. Pengelompokan itu membantu memperlihatkan komponen yang dipertimbangkan. Namun, banyak panah panjang dan bersilangan membuat urutan transaksi, arah pembaruan, serta batas antara proses sinkron dan asinkron sulit diperiksa. Penomoran lapisan juga tidak mengikuti urutan alur pengguna, dan DBSCAN diletakkan berdekatan dengan model bahasa seolah keduanya memiliki jenis pemrosesan yang sama.

Diagram pengganti untuk Bab 1 perlu menampilkan satu jalur penerimaan yang pendek, penyimpanan sebelum tanda terima, jalur analisis asinkron yang terpisah, tinjauan koordinator, serta komunikasi dan rute setelah tugas diterima. Diagram tersebut merupakan **arsitektur logis**, bukan diagram komponen UML dan bukan pernyataan bahwa komponen sasaran sudah berjalan. Fitur embedding, vector store, RAG, dan LLM sebaiknya tidak dimasukkan ke jalur inti.

## Ketentuan untuk Bab 2

- Tetapkan alur SOS sebagai prioritas awal dan tuliskan batas lima detik sebagai kriteria target yang perlu diuji.
- Jaga agar penulisan tiket dan pemberitahuan awal tetap berjalan ketika analisis model terlambat atau gagal.
- Bedakan tanda terima sistem, pemberitahuan, penerimaan tugas, dan penyelesaian.
- Perlakukan hasil Laya Multilingual dan DBSCAN sebagai masukan peninjauan, bukan putusan otomatis yang mengubah laporan sumber. Bandingkan model dengan baseline pada data Indonesia; evaluasi kesalahan laporan kritis serta kalibrasi keluaran secara terpisah sebelum penggunaan.
- Catat versi model, keluaran dan tingkat keyakinan, parameter pengelompokan, keputusan koreksi, identitas peninjau, alasan, serta waktu. Persetujuan label untuk evaluasi atau pelatihan dilakukan melalui proses tinjauan, bukan otomatis.
- Tempatkan embedding, LLM, RAG, dan agen baca-saja sebagai opsi masa depan yang belum disetujui.
- Jadikan privasi lokasi, pemulihan data, layanan eksternal, dan kinerja pada jaringan nyata sebagai risiko dan keluaran verifikasi.

## Sumber yang dianalisis

- [AI_Powered_Reference.pdf](../DOCUMENTATION_AND_AI_BUILDING_BLOCKS/AI_Powered_Reference.pdf), khususnya halaman 1-10.
- [Kartu model resmi Laya](https://huggingface.co/convaiinnovations/laya) dan [Laya Multilingual](https://huggingface.co/convaiinnovations/laya-multilingual), dibuka kembali pada 8 Oktober 2026 untuk memeriksa bahasa checkpoint dan keterbatasan benchmark.
- `AI_Powered_Architecture_BuildingBlock.jpeg`, ditinjau secara visual tetapi sengaja tidak ditanamkan ulang.
- [Reference.png](../DOCUMENTATION_AND_AI_BUILDING_BLOCKS/Reference.png), dipakai hanya untuk memahami gaya dan batas diagram yang diberikan, bukan sebagai sumber klaim sistem.
