# Scaffold kontrak API Commencys untuk pelaporan, koordinasi, triase, dan tinjauan.
# Rute menggambarkan batas sistem pada dokumen proyek, bukan alur yang sudah aktif.
# Layanan operasional tetap kosong sampai kebijakan dan dependensinya disepakati.

from __future__ import annotations

from pathlib import Path
from typing import Any

from fastapi import FastAPI, Header, HTTPException, WebSocket
from fastapi.staticfiles import StaticFiles

from .storage import SQLiteStateStore, StateStore

# Sasaran awal dari dokumen proyek, bukan hasil ukur atau jaminan waktu tanggap.
SOS_BUDGET_S = 5.0

app = FastAPI(title="Commencys", version="0.1.0-skeleton")
_state_store: StateStore | None = None


def configure_state_store(path: Path) -> None:
    # Pertahankan titik konfigurasi SQLite untuk kontrak adapter dan acceptance seam yang ada.
    # Pemanggilan hanya menyimpan path; belum membuka berkas, membuat tabel, atau menyimpan laporan.
    global _state_store
    _state_store = SQLiteStateStore(path)


def _not_implemented(capability: str) -> None:
    # Hentikan permintaan pada batas fitur yang belum memiliki layanan operasional.
    # HTTP 501 mencegah klien menganggap laporan, perubahan status, atau pesan berhasil.
    raise HTTPException(
        status_code=501,
        detail=f"{capability} is not implemented in the phase-one scaffold.",
    )


@app.get("/health")
async def health() -> dict[str, Any]:
    # Periksa bahwa proses API dapat menjawab; nilai ini bukan pemeriksaan kesiapan.
    # `ready` tetap false karena penyimpanan dan alur produk belum tersedia.
    return {
        "status": "scaffold",
        "service": "commencys",
        "ready": False,
    }


@app.get("/api/incidents")
async def list_incidents(
    authorization: str | None = Header(default=None, alias="Authorization"),
) -> list[dict[str, Any]]:
    # Batas baca daftar yang boleh dilihat aplikasi konsumen; tinjauan admin punya rute khusus.
    # Identitas kelak berasal dari kredensial header, bukan dari filter atau body bebas.
    # Implementasi kelak menerapkan kebijakan akses dan bentuk respons API yang sama.
    # Belum ada kueri, penyaringan, atau data contoh pada scaffold ini.
    _not_implemented("Incident listing")


@app.get("/api/incidents/{ticket_id}")
async def get_incident(
    ticket_id: str,
    authorization: str | None = Header(default=None, alias="Authorization"),
) -> dict[str, Any]:
    # Batas baca satu laporan berdasarkan pengenal yang diberikan klien.
    # Server harus memeriksa kredensial dan cakupan sebelum membuka rincian atau koordinat.
    # Implementasi kelak memeriksa akses dan membedakan laporan tidak ditemukan.
    # Saat ini pengenal belum dicari pada repositori mana pun.
    _not_implemented("Incident lookup")


@app.get("/api/volunteer/tasks")
async def volunteer_tasks(
    authorization: str | None = Header(default=None, alias="Authorization"),
) -> list[dict[str, Any]]:
    # Batas daftar penawaran tugas untuk relawan yang sedang terautentikasi.
    # Implementasi kelak hanya mengembalikan tugas dalam cakupan akses relawan tersebut.
    # Header hanya mendeklarasikan titik integrasi; kredensial belum diverifikasi.
    # Belum ada penyaringan atau penyimpanan tugas yang aktif.
    _not_implemented("Volunteer task feed")


@app.post("/api/incidents", status_code=201)
async def create_incident(body: dict[str, Any]) -> dict[str, Any]:
    # Pertahankan batas payload JSON tanpa kelas atau skema model data aplikasi.
    # Alur sasaran menyimpan teks dan lokasi asli sebelum memberi tanda terima.
    # Triase hanya menjadi saran terpisah dan tidak boleh menahan tanda terima.
    # Penyimpanan, audit, dan pemanggilan analisis belum diimplementasikan.
    _not_implemented("Incident intake")


@app.post("/api/sos", status_code=201)
async def send_sos(
    body: dict[str, Any],
    idempotency_key: str | None = Header(default=None, alias="Idempotency-Key"),
) -> dict[str, Any]:
    # Pertahankan payload JSON dan header percobaan ulang pada batas API.
    # Tidak ada skema model data atau pemeriksaan bidang khusus yang dijalankan.
    # Alur sasaran menyimpan permintaan secara idempoten sebelum mengirim tanda terima.
    # Tanda terima tidak berarti pemberitahuan terkirim atau bantuan telah menerima tugas.
    # Analisis lanjutan tidak boleh menjadi prasyarat penyimpanan SOS.
    _not_implemented("SOS intake")


@app.post("/api/incidents/{ticket_id}/offer")
async def offer_assignment(
    ticket_id: str,
    body: dict[str, Any],
    authorization: str | None = Header(default=None, alias="Authorization"),
) -> dict[str, Any]:
    # Batas admin untuk menyetujui penawaran tugas setelah meninjau laporan.
    # Implementasi kelak memeriksa peran admin dan meminta layanan memilih relawan yang berhak.
    # Pembuatan penawaran tidak berarti notifikasi terkirim atau relawan menerima tugas.
    _not_implemented("Assignment offer")


@app.post("/api/incidents/{ticket_id}/accept")
async def accept_assignment(
    ticket_id: str,
    authorization: str | None = Header(default=None, alias="Authorization"),
) -> dict[str, Any]:
    # Catat penerimaan tugas yang dilakukan secara eksplisit oleh relawan.
    # Implementasi kelak memeriksa status laporan, identitas, kewenangan, dan audit.
    # Identitas relawan berasal dari header terverifikasi, bukan nama pada body.
    # Pengiriman pemberitahuan saja tidak dapat menjalankan transisi ini.
    _not_implemented("Assignment acceptance")


@app.post("/api/incidents/{ticket_id}/reject")
async def reject_assignment(
    ticket_id: str,
    authorization: str | None = Header(default=None, alias="Authorization"),
) -> dict[str, Any]:
    # Catat penolakan eksplisit tanpa menandai laporan sebagai selesai.
    # Implementasi kelak menyimpan alasan atau aktor sesuai kebijakan yang disetujui.
    # Keputusan berasal dari relawan terautentikasi melalui widget tugas.
    # Laporan tetap dapat ditinjau untuk penugasan lain.
    _not_implemented("Assignment rejection")


@app.post("/api/incidents/{ticket_id}/resolve")
async def resolve_incident(
    ticket_id: str,
    body: dict[str, Any],
    authorization: str | None = Header(default=None, alias="Authorization"),
) -> dict[str, Any]:
    # Catat penyelesaian setelah penugasan diterima dan aktor berwenang bertindak.
    # Implementasi kelak menyimpan catatan serta waktu penyelesaian ke riwayat audit.
    # Status selesai tidak boleh disimpulkan dari pengiriman atau pembacaan notifikasi.
    _not_implemented("Incident resolution")


@app.get("/api/review-queue")
async def review_queue(
    authorization: str | None = Header(default=None, alias="Authorization"),
) -> list[dict[str, Any]]:
    # Baca laporan yang menunggu pemeriksaan manusia pada dashboard admin saja.
    # Implementasi kelak harus membatasi akses menurut peran dan kebijakan lokasi.
    # Antrean belum dibentuk dan keluaran AI belum tersedia.
    _not_implemented("Admin review queue")


@app.post("/api/incidents/{ticket_id}/correct")
async def correct(
    ticket_id: str,
    body: dict[str, Any],
    authorization: str | None = Header(default=None, alias="Authorization"),
) -> dict[str, Any]:
    # Ubah saran kategori atau urgensi tanpa menimpa keterangan asli pelapor.
    # Payload tetap berupa JSON mentah; validasi bidang belum diimplementasikan.
    # Implementasi kelak mencatat nilai sebelum/sesudah dan aktor pada audit.
    _not_implemented("Triage correction")


@app.post("/api/incidents/{ticket_id}/split")
async def split_cluster(
    ticket_id: str,
    authorization: str | None = Header(default=None, alias="Authorization"),
) -> dict[str, Any]:
    # Lepaskan hubungan laporan yang dinilai keliru tanpa menghapus laporan sumber.
    # Implementasi kelak menyimpan perubahan yang dapat ditinjau dan dipulihkan.
    # Kelompok DBSCAN masih rancangan dan belum dibuat oleh aplikasi.
    _not_implemented("Related-report split")


@app.get("/api/audit")
async def audit(
    incident_id: str | None = None,
    authorization: str | None = Header(default=None, alias="Authorization"),
) -> list[dict[str, Any]]:
    # Baca riwayat perubahan admin, dengan filter pengenal laporan bila diberikan.
    # Implementasi kelak menerapkan otorisasi dan mengembalikan peristiwa yang persisten.
    # Scaffold belum merekam aktor maupun perubahan apa pun.
    _not_implemented("Audit history")


@app.get("/api/eta")
async def eta(
    incident_id: str,
    from_lat: float,
    from_lng: float,
    authorization: str | None = Header(default=None, alias="Authorization"),
) -> dict[str, Any]:
    # Sediakan batas permintaan rute dari koordinat asal ke lokasi laporan.
    # Dokumen sasaran menempatkan estimasi setelah penugasan diterima; ETA bukan janji.
    # Validasi relawan/penugasan, integrasi penyedia rute, dan penanganan kegagalan belum ada.
    _not_implemented("Route and ETA")


@app.websocket("/ws/alerts")
async def alerts(websocket: WebSocket) -> None:
    # Pertahankan alamat kanal pembaruan langsung yang direncanakan.
    # Implementasi kelak harus mengatur autentikasi, penerima, format pesan, dan pemulihan.
    # Menutup koneksi sekarang mencegah klien menyangka pemberitahuan telah terkirim.
    await websocket.close(code=1011, reason="Alert delivery is not implemented")


# The same-origin dashboard keeps its static layout during backend scaffolding.
_web_directory = Path(__file__).resolve().parents[2] / "web"
app.mount("/", StaticFiles(directory=_web_directory, html=True), name="web")
