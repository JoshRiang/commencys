# Titik integrasi target PostgreSQL/PostGIS untuk kontrak StateStore.
# Modul ini tidak membuka koneksi, menjalankan SQL, atau menyimpan data.

from __future__ import annotations

from typing import Any

from .storage import StateStore


class PostgresStateStore(StateStore):
    # Adapter target mengikuti kontrak penyimpanan yang sama dengan SQLiteStateStore.
    # Kelas ini tidak mengatur alur API atau mendefinisikan kelas model data.

    def __init__(self, database_url: str) -> None:
        # Simpan konfigurasi agar implementasi mendatang dapat menerima URL dari lingkungan.
        # Jangan memvalidasi rahasia, menghubungi server, atau menjalankan migrasi di sini.
        self.database_url = database_url

    def load(
        self,
    ) -> tuple[
        dict[str, dict[str, Any]],
        list[dict[str, Any]],
        dict[str, tuple[str, str, float]],
    ]:
        # Baca laporan sumber, audit, dan kunci idempotensi melalui transaksi konsisten.
        # Kebijakan paginasi, retensi, dan pembatasan koordinat belum dirancang.
        raise NotImplementedError("PostgreSQL persistence is not implemented")

    def commit_change(
        self,
        ticket_id: str,
        ticket: dict[str, Any],
        audit_entry: dict[str, Any],
        *,
        idempotency_key: str | None = None,
        idempotency_value: tuple[str, str, float] | None = None,
    ) -> None:
        # Simpan keadaan laporan dan catatan audit secara atomik.
        # Simpan hasil SOS dengan kunci idempotensi pada transaksi yang sama bila disertakan.
        # SQL, driver, migrasi aktif, dan strategi retry belum diimplementasikan.
        raise NotImplementedError("PostgreSQL persistence is not implemented")

    def ping(self) -> None:
        # Periksa keterjangkauan basis data tanpa membuat atau mengubah keadaan.
        # Pemeriksaan ini kelak dibedakan dari pemeriksaan kesiapan layanan penuh.
        raise NotImplementedError("PostgreSQL persistence is not implemented")
