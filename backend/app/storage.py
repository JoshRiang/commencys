# Kontrak penyimpanan untuk laporan, riwayat audit, dan identitas percobaan ulang SOS.
# Adapter produksi, skema, migrasi, retensi, dan pemulihan belum dipilih atau dibuat.
# Memuat modul ini tidak membuka koneksi atau mengubah data lokal.

from __future__ import annotations

from pathlib import Path
from typing import Any, Protocol


class StateStorageError(RuntimeError):
    # Nama galat bersama bagi adapter SQLite/PostgreSQL ketika operasi penyimpanan dibuat.
    # Dipertahankan untuk kontrak dan acceptance seam; scaffold saat ini belum melemparkannya.
    pass


class StateStore(Protocol):
    # Satu kontrak untuk adapter lokal maupun target PostgreSQL agar API tidak terikat vendor.
    # Semua adapter memakai operasi yang sama untuk laporan, audit, dan kunci SOS.

    def load(
        self,
    ) -> tuple[
        dict[str, dict[str, Any]],
        list[dict[str, Any]],
        dict[str, tuple[str, str, float]],
    ]:
        # Kembalikan laporan menurut ID, riwayat audit berurutan, dan kunci SOS yang masih berlaku.
        # Pembaca kelak menetapkan masa berlaku kunci dan cara menangani data yang rusak.
        ...

    def commit_change(
        self,
        ticket_id: str,
        ticket: dict[str, Any],
        audit_entry: dict[str, Any],
        *,
        idempotency_key: str | None = None,
        idempotency_value: tuple[str, str, float] | None = None,
    ) -> None:
        # Simpan perubahan laporan beserta peristiwa audit sebagai satu transaksi.
        # Jika kunci idempotensi disertakan, simpan hasilnya agar pengulangan tidak menggandakan SOS.
        ...

    def ping(self) -> None:
        # Periksa keterjangkauan adapter tanpa membuat atau mengubah laporan.
        # Hasil pemeriksaan tidak dengan sendirinya berarti sistem siap menerima trafik.
        ...


class SQLiteStateStore(StateStore):
    # Adapter lokal dipertahankan sebagai seam kompatibilitas dan acceptance test.
    # Ia bukan target penyimpanan produksi dan belum membuka database atau menyimpan state.

    def __init__(self, path: Path) -> None:
        # Simpan lokasi konfigurasi untuk digunakan adapter pada fase berikutnya.
        # Jangan membuat direktori, berkas, tabel, atau koneksi pada fase scaffold.
        self.path = path

    def load(
        self,
    ) -> tuple[
        dict[str, dict[str, Any]],
        list[dict[str, Any]],
        dict[str, tuple[str, str, float]],
    ]:
        # Adapter nyata harus membaca laporan, audit, dan kunci yang belum kedaluwarsa.
        # Bentuk tuple mengikuti kontrak StateStore agar pemanggil tidak mengetahui vendor.
        raise NotImplementedError("SQLite persistence is not implemented")

    def commit_change(
        self,
        ticket_id: str,
        ticket: dict[str, Any],
        audit_entry: dict[str, Any],
        *,
        idempotency_key: str | None = None,
        idempotency_value: tuple[str, str, float] | None = None,
    ) -> None:
        # Adapter nyata harus menyimpan laporan, audit, dan kunci percobaan ulang secara atomik.
        # Kegagalan salah satu bagian harus membatalkan seluruh perubahan.
        raise NotImplementedError("SQLite persistence is not implemented")

    def ping(self) -> None:
        # Adapter nyata memeriksa koneksi tanpa mengubah keadaan tersimpan.
        # Status proses API tetap perlu dibedakan dari kesiapan penyimpanan.
        raise NotImplementedError("SQLite persistence is not implemented")
