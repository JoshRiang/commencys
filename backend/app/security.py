# Batas autentikasi dan otorisasi untuk aktor Commencys.
# Tidak ada token, sesi, akun, atau kebijakan akses yang diverifikasi pada scaffold.

from __future__ import annotations

from typing import Any, Mapping

# Gunakan nama peran yang sama pada API, widget, dan dashboard.
# `admin` adalah aktor yang menggunakan dashboard operator; operator bukan peran lain.
REPORTER_ROLE = "reporter"
VOLUNTEER_ROLE = "volunteer"
ADMIN_ROLE = "admin"


def require_authenticated_actor(authorization: str | None) -> Mapping[str, Any]:
    # Uraikan kredensial yang kelak diterbitkan penyedia identitas yang disetujui.
    # Hasil harus memuat identitas terverifikasi; nama bebas dari payload klien tidak cukup.
    # Belum ada format token, kunci, sesi, atau penyedia identitas yang dipilih.
    raise NotImplementedError("Actor authentication is not implemented")


def require_role(actor: Mapping[str, Any], required_role: str) -> None:
    # Tolak permintaan jika identitas terverifikasi tidak memiliki peran yang diperlukan.
    # Admin/operator mengakses tinjauan; relawan bertindak atas penugasan miliknya.
    # Kebijakan sumber peran, cakupan wilayah, dan respons penolakan belum ditetapkan.
    raise NotImplementedError("Role authorization is not implemented")


def require_incident_access(
    actor: Mapping[str, Any],
    incident: Mapping[str, Any],
    *,
    action: str,
) -> None:
    # Terapkan akses minimum terhadap laporan dan koordinat sesuai tujuan tindakan.
    # Penerimaan atau penolakan hanya boleh dilakukan relawan yang dituju.
    # Aturan untuk laporan anonim, admin, dan akses darurat perlu disepakati dahulu.
    raise NotImplementedError("Incident-level authorization is not implemented")
