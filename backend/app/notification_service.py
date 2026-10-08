# Batas pemilihan penerima dan pengiriman penawaran tugas secara terarah.
# Ini terpisah dari WebSocket status; tidak ada kanal delivery yang aktif pada scaffold.

from __future__ import annotations

from typing import Any, Mapping, Sequence


async def select_recipients(
    incident: Mapping[str, Any],
) -> Sequence[Mapping[str, Any]]:
    # Pilih relawan yang memenuhi wilayah, ketersediaan, dan aturan penerima yang disahkan.
    # Jangan mengirim koordinat tepat ke semua pengguna atau menyamakan kirim dengan baca.
    # Cakupan lokasi, privasi, dan pembatasan frekuensi belum ditentukan.
    raise NotImplementedError("Notification recipient selection is not implemented")


async def publish_assignment(
    incident: Mapping[str, Any],
    recipients: Sequence[Mapping[str, Any]],
) -> dict[str, Any]:
    # Kirim penawaran tugas dan catat hasil per penerima pada kanal yang disepakati.
    # Status terkirim, diterima relawan, dan selesai harus tetap merupakan peristiwa berbeda.
    # Fungsi ini tidak boleh menerima atau menyelesaikan tugas atas nama relawan.
    raise NotImplementedError("Assignment notification delivery is not implemented")
