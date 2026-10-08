package com.commencys.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context

class CommencysVolunteerWidgetProvider : AppWidgetProvider() {
    // Bentuk provider terpisah untuk mode penawaran tugas relawan di layar utama Android.
    // Provider ini belum memuat tugas, memverifikasi sesi, atau memanggil API Commencys.
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        // Muat penawaran melalui VolunteerTaskGateway setelah sesi relawan tersedia.
        // Buat RemoteViews tanpa contoh; pasang PendingIntent eksplisit menuju action receiver.
        // Berikan hanya ID insiden yang diperlukan; jangan menaruh kredensial pada Intent.
        // Perbarui tampilan dari hasil server dan cegah klik ganda saat keputusan dikirim.
        // Semua langkah tersebut masih berupa catatan; widget tidak memuat atau mengubah data.
    }

    companion object {
        // Aksi lokal hanya mengarahkan pilihan widget; aksi ini belum terhubung ke layanan.
        const val ACTION_ACCEPT = "com.commencys.app.widget.volunteer.ACCEPT"
        const val ACTION_REJECT = "com.commencys.app.widget.volunteer.REJECT"
        const val EXTRA_INCIDENT_ID = "com.commencys.app.widget.volunteer.INCIDENT_ID"
    }
}
