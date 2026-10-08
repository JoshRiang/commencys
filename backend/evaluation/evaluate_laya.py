# Kerangka evaluasi terpisah untuk kandidat Laya Multilingual pada teks Indonesia.
# Evaluasi ini belum membaca data, memuat checkpoint, atau menghitung metrik.

from __future__ import annotations

from pathlib import Path
from typing import Any, Mapping, Sequence


def load_reviewed_examples(dataset_path: Path) -> Sequence[Mapping[str, Any]]:
    # Baca data berlabel yang telah disetujui dan tidak mencakup identitas yang tak perlu.
    # Pemisahan train/validation/test harus mencegah kebocoran laporan yang sama.
    # Format dataset dan aturan akses belum ditetapkan; fungsi tidak membaca berkas saat ini.
    raise NotImplementedError("Reviewed Indonesian evaluation data is not configured")


def evaluate_checkpoint(
    examples: Sequence[Mapping[str, Any]],
    checkpoint: str = "convaiinnovations/laya-multilingual",
) -> dict[str, Any]:
    # Bandingkan keluaran dengan label tinjauan dan baseline yang disepakati.
    # Laporkan hasil per kategori, laporan kritis yang terlewat, kalibrasi, dan batas sampel.
    # Jangan menganggap cakupan multibahasa sebagai bukti mutu Bahasa Indonesia.
    raise NotImplementedError("Laya checkpoint evaluation is not implemented")


def write_evaluation_summary(
    results: Mapping[str, Any],
    output_path: Path,
) -> None:
    # Simpan versi checkpoint, data, parameter, hasil, dan peninjau tanpa menyalin data sensitif.
    # Lokasi keluaran dan format laporan perlu mengikuti kebijakan data proyek.
    raise NotImplementedError("Evaluation reporting is not implemented")
