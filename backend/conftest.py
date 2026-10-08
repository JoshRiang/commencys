# Tambahkan direktori backend agar kontrak dan spesifikasi tes dapat mengimpor paket app.
# Berkas ini tidak membuat basis data atau fixture layanan karena adapter belum aktif.
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
