package com.commencys.app

// Kontrak REST yang hanya dimiliki widget tugas relawan Android.
// Provider memuat penawaran; receiver mengirim keputusan; keduanya memakai batas yang sama.
// Implementasi jaringan dan penyedia sesi belum dipilih, sehingga antarmuka ini belum aktif.
interface VolunteerTaskGateway {
    // GET /api/volunteer/tasks dengan kredensial sesi; server menentukan relawan dari kredensial.
    // Kembalikan body JSON mentah agar scaffold tidak menambah kelas model data.
    // Callback harus selesai secara asinkron dan tidak boleh menahan thread utama Android.
    fun fetchTasks(
        authorizationHeader: String,
        onResult: (Result<String>) -> Unit,
    )

    // POST /api/incidents/{incidentId}/accept setelah relawan memilih tombol terima.
    // Jangan kirim nama atau ID relawan dari Intent; server memeriksa penerima penawaran.
    fun acceptAssignment(
        incidentId: String,
        authorizationHeader: String,
        onResult: (Result<String>) -> Unit,
    )

    // POST /api/incidents/{incidentId}/reject setelah relawan memilih tombol tolak.
    // Respons hanya menyatakan hasil keputusan; penolakan tidak menyelesaikan laporan.
    fun rejectAssignment(
        incidentId: String,
        authorizationHeader: String,
        onResult: (Result<String>) -> Unit,
    )
}
