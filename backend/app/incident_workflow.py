# Batas orkestrasi alur laporan, penugasan, tinjauan, dan audit.
# Semua masukan tetap berupa mapping biasa; tidak ada kelas model domain pada scaffold.

from __future__ import annotations

from typing import Any, Mapping


async def record_report(
    payload: Mapping[str, Any],
    *,
    is_sos: bool = False,
) -> dict[str, Any]:
    # Validasi isi dan lokasi, lalu simpan laporan sumber sebelum membuat tanda terima.
    # Analisis Laya/DBSCAN dan pemberitahuan berjalan sesudah commit sebagai pekerjaan terpisah.
    # Kegagalan proses pendukung tidak boleh mengubah laporan sumber yang telah tersimpan.
    raise NotImplementedError("Report intake workflow is not implemented")


async def record_assignment_decision(
    incident_id: str,
    actor: Mapping[str, Any],
    *,
    accepted: bool,
) -> dict[str, Any]:
    # Catat keputusan eksplisit relawan terautentikasi dalam transaksi dan jejak audit.
    # Penolakan membiarkan laporan terbuka agar admin dapat menentukan tindak lanjut.
    # Operasi harus idempoten atau menolak pengulangan yang tidak sesuai status.
    raise NotImplementedError("Volunteer assignment decision is not implemented")


async def approve_assignment_offer(
    incident_id: str,
    actor: Mapping[str, Any],
    *,
    note: str | None = None,
) -> dict[str, Any]:
    # Catat keputusan admin untuk menawarkan tugas kepada relawan yang memenuhi kebijakan.
    # Pemilihan penerima dan pengiriman dilakukan melalui layanan terpisah.
    # Persetujuan admin tidak mengubah status menjadi diterima oleh relawan.
    raise NotImplementedError("Admin assignment offer is not implemented")


async def record_admin_review(
    incident_id: str,
    actor: Mapping[str, Any],
    changes: Mapping[str, Any],
    *,
    reason: str,
) -> dict[str, Any]:
    # Catat koreksi admin tanpa menimpa teks dan lokasi asli yang dikirim pelapor.
    # Nilai sebelum/sesudah, alasan, identitas, dan waktu harus dapat diaudit.
    raise NotImplementedError("Admin review workflow is not implemented")


async def record_resolution(
    incident_id: str,
    actor: Mapping[str, Any],
    *,
    note: str | None = None,
) -> dict[str, Any]:
    # Catat penyelesaian hanya setelah penugasan diterima dan pelaku berwenang bertindak.
    # Makna penyelesaian dan apakah pelaksanaannya dilakukan relawan atau admin perlu disahkan.
    # Status tidak boleh disimpulkan dari pengiriman, pembacaan, atau ETA.
    raise NotImplementedError("Incident resolution workflow is not implemented")


async def separate_related_reports(
    incident_id: str,
    related_incident_id: str,
    actor: Mapping[str, Any],
    *,
    reason: str,
) -> dict[str, Any]:
    # Lepaskan satu tautan kandidat yang dikoreksi admin tanpa menghapus laporan asal.
    # Perubahan hubungan dan alasannya harus tetap tersedia pada riwayat audit.
    raise NotImplementedError("Related-report correction is not implemented")
