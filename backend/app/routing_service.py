# Batas estimasi rute untuk relawan yang telah menerima penugasan.
# OSRM adalah sasaran pada dokumen, tetapi endpoint dan pemanggilan jaringan belum aktif.

from __future__ import annotations

from typing import Any, Mapping


async def estimate_route(
    origin: Mapping[str, Any],
    destination: Mapping[str, Any],
    *,
    assignment_accepted: bool,
) -> dict[str, Any]:
    # Pastikan pemanggil hanya meminta rute untuk penugasan yang sudah diterima.
    # Validasi koordinat, pemilihan profil, batas waktu, dan fallback perlu ditetapkan.
    # Hasil harus dilabeli perkiraan dan tidak boleh menjadi janji waktu kedatangan.
    raise NotImplementedError("Route and ETA estimation is not implemented")
