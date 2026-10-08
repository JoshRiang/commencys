# Generate the three UML image assets embedded in Chapter 3.
# PNG is the lossless document source; JPG is supplied for office tools that prefer it.
from pathlib import Path
from math import atan2, cos, sin, pi
from PIL import Image, ImageDraw, ImageFont


OUT = Path(__file__).resolve().parent
FONT = r"C:\Windows\Fonts\arial.ttf"
FONT_BOLD = r"C:\Windows\Fonts\arialbd.ttf"

INK = "#1D2D3F"
MUTED = "#566B80"
LINE = "#718297"
BLUE = "#315F87"
TEAL = "#28776F"
PURPLE = "#70579B"
AMBER = "#A36B21"
RED = "#A54D4A"
BG = "#FFFFFF"
PALE_BLUE = "#F0F5F9"
PALE_TEAL = "#EFF6F4"
PALE_PURPLE = "#F4F1F8"
PALE_AMBER = "#FAF5EB"
PALE_RED = "#FBF0EF"


def font(size, bold=False):
    return ImageFont.truetype(FONT_BOLD if bold else FONT, size)


def wrapped(draw, text, fnt, max_width):
    result = []
    for paragraph in text.split("\n"):
        words = paragraph.split()
        if not words:
            result.append("")
            continue
        line = words[0]
        for word in words[1:]:
            candidate = f"{line} {word}"
            if draw.textbbox((0, 0), candidate, font=fnt)[2] <= max_width:
                line = candidate
            else:
                result.append(line)
                line = word
        result.append(line)
    return result


def centered(draw, box, text, size=29, color=INK, bold=False, gap=7, pad=24):
    x1, y1, x2, y2 = box
    fnt = font(size, bold)
    lines = wrapped(draw, text, fnt, x2 - x1 - 2 * pad)
    heights = [draw.textbbox((0, 0), line or "Ag", font=fnt)[3] for line in lines]
    total = sum(heights) + gap * max(0, len(lines) - 1)
    y = y1 + (y2 - y1 - total) / 2
    for line, height in zip(lines, heights):
        width = draw.textbbox((0, 0), line, font=fnt)[2]
        draw.text((x1 + (x2 - x1 - width) / 2, y), line, font=fnt, fill=color)
        y += height + gap


def dash_line(draw, points, fill=LINE, width=4, dash=18, gap=12):
    for (x1, y1), (x2, y2) in zip(points[:-1], points[1:]):
        dx, dy = x2 - x1, y2 - y1
        length = max(1.0, (dx * dx + dy * dy) ** 0.5)
        ux, uy = dx / length, dy / length
        pos = 0.0
        while pos < length:
            end = min(pos + dash, length)
            draw.line((x1 + ux * pos, y1 + uy * pos,
                       x1 + ux * end, y1 + uy * end), fill=fill, width=width)
            pos += dash + gap


def connector(draw, points, color=LINE, width=5, dashed=False, arrow=True):
    if dashed:
        dash_line(draw, points, color, width)
    else:
        draw.line(points, fill=color, width=width, joint="curve")
    if arrow and len(points) > 1:
        x1, y1 = points[-2]
        x2, y2 = points[-1]
        angle = atan2(y2 - y1, x2 - x1)
        head = 22
        left = (x2 - head * cos(angle - pi / 6), y2 - head * sin(angle - pi / 6))
        right = (x2 - head * cos(angle + pi / 6), y2 - head * sin(angle + pi / 6))
        draw.polygon([(x2, y2), left, right], fill=color)


def edge_label(draw, point, text, color=INK, size=23):
    fnt = font(size, True)
    box = draw.textbbox((0, 0), text, font=fnt)
    x, y = point
    width, height = box[2] + 22, box[3] + 16
    draw.rounded_rectangle((x - width / 2, y - height / 2,
                            x + width / 2, y + height / 2),
                           radius=8, fill=BG, outline="#D9E1E8", width=1)
    draw.text((x - box[2] / 2, y - box[3] / 2 - 1), text, font=fnt, fill=color)


def rect_node(draw, box, text, fill=PALE_BLUE, outline=BLUE, size=28,
              dashed=False, radius=22, bold=False, width=4):
    if dashed:
        x1, y1, x2, y2 = box
        draw.rounded_rectangle(box, radius=radius, fill=fill)
        dash_line(draw, [(x1 + radius, y1), (x2 - radius, y1), (x2, y1 + radius),
                         (x2, y2 - radius), (x2 - radius, y2), (x1 + radius, y2),
                         (x1, y2 - radius), (x1, y1 + radius), (x1 + radius, y1)],
                  outline, width)
    else:
        draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)
    centered(draw, box, text, size=size, bold=bold)


def oval_node(draw, box, text, fill=PALE_BLUE, outline=BLUE, size=27):
    draw.ellipse(box, fill=fill, outline=outline, width=4)
    centered(draw, box, text, size=size, bold=True, pad=42)


def diamond_node(draw, center, width, height, text, fill=PALE_AMBER,
                 outline=AMBER, size=26):
    cx, cy = center
    points = [(cx, cy - height / 2), (cx + width / 2, cy),
              (cx, cy + height / 2), (cx - width / 2, cy)]
    draw.polygon(points, fill=fill, outline=outline)
    draw.line(points + [points[0]], fill=outline, width=4)
    centered(draw, (cx - width / 2 + 45, cy - height / 2 + 22,
                    cx + width / 2 - 45, cy + height / 2 - 22),
             text, size=size, bold=True, pad=4)


def actor(draw, cx, top, label, color=INK):
    radius = 25
    head_y = top + radius
    draw.ellipse((cx - radius, head_y - radius, cx + radius, head_y + radius),
                 outline=color, width=5)
    body_top = head_y + radius + 6
    body_bottom = body_top + 66
    draw.line((cx, body_top, cx, body_bottom), fill=color, width=5)
    draw.line((cx - 43, body_top + 20, cx + 43, body_top + 20), fill=color, width=5)
    draw.line((cx, body_bottom, cx - 37, body_bottom + 54), fill=color, width=5)
    draw.line((cx, body_bottom, cx + 37, body_bottom + 54), fill=color, width=5)
    label_box = (cx - 145, body_bottom + 60, cx + 145, body_bottom + 145)
    centered(draw, label_box, label, size=25, bold=True, pad=6)


def export(image, stem):
    image.save(OUT / f"{stem}.png", format="PNG", optimize=True, dpi=(300, 300))
    image.save(OUT / f"{stem}.jpg", format="JPEG", quality=95, subsampling=0,
               optimize=True, dpi=(300, 300))


def render_use_case():
    w, h = 3200, 1900
    im = Image.new("RGB", (w, h), BG)
    d = ImageDraw.Draw(im)
    boundary = (390, 70, 2810, 1830)
    d.rounded_rectangle(boundary, radius=20, fill="#FFFFFF", outline=BLUE, width=5)

    # Associations are drawn before the use cases so the lines remain behind them.
    connector(d, [(223, 365), (370, 365), (370, 285), (650, 285)], color=LINE, arrow=False)
    connector(d, [(223, 365), (350, 365), (350, 150), (1740, 150), (1740, 285)],
              color=LINE, arrow=False)
    connector(d, [(3017, 1205), (2860, 1205), (2860, 730), (2430, 730)],
              color=LINE, arrow=False)
    connector(d, [(223, 745), (350, 745), (760, 730)], color=LINE, arrow=False)
    connector(d, [(223, 745), (350, 745), (350, 930), (1190, 930)],
              color=LINE, arrow=False)
    connector(d, [(3017, 1205), (2860, 1205), (2860, 1020), (1460, 1020), (1440, 1160)],
              color=LINE, arrow=False)
    connector(d, [(3017, 1205), (2750, 1205), (2430, 1160)], color=LINE, arrow=False)
    connector(d, [(3017, 1205), (2860, 1205), (2860, 1540), (1460, 1540), (1440, 1400)],
              color=LINE, arrow=False)
    connector(d, [(3017, 1205), (2750, 1205), (2430, 1400)], color=LINE, arrow=False)
    connector(d, [(3017, 1205), (2900, 1205), (2900, 1660), (2430, 1660)],
              color=LINE, arrow=False)
    connector(d, [(3017, 1205), (2860, 1205), (2860, 1790), (1440, 1790), (1440, 1660)],
              color=LINE, arrow=False)

    ellipses = [
        ((650, 205, 1330, 365), "Mengirim laporan insiden"),
        ((1740, 205, 2420, 365), "Mengirim SOS"),
        ((1190, 425, 1870, 585), "Menentukan lokasi kejadian"),
        ((760, 650, 1440, 810), "Melihat dan menerima atau menolak tugas dari widget"),
        ((1750, 650, 2430, 810), "Menyetujui penawaran tugas"),
        ((1190, 850, 1870, 1010), "Melihat rute dan perkiraan waktu"),
        ((760, 1080, 1440, 1240), "Meninjau laporan dan saran triase"),
        ((1750, 1080, 2430, 1240), "Mengoreksi kategori atau urgensi"),
        ((760, 1320, 1440, 1480), "Meninjau atau memisahkan kaitan laporan"),
        ((1750, 1320, 2430, 1480), "Memperbarui status penanganan"),
        ((760, 1580, 1440, 1740), "Mengelola akses dan kebijakan"),
        ((1750, 1580, 2430, 1740), "Meninjau riwayat perubahan"),
    ]
    for box, label in ellipses:
        oval_node(d, box, label, fill=PALE_BLUE if box[1] < 1020 else PALE_TEAL)

    connector(d, [(1000, 365), (1250, 425)], color=PURPLE, width=4, dashed=True)
    edge_label(d, (1085, 395), "«include»", color=PURPLE, size=21)
    connector(d, [(2080, 365), (1810, 425)], color=PURPLE, width=4, dashed=True)
    edge_label(d, (1970, 395), "«include»", color=PURPLE, size=21)

    actor(d, 180, 270, "Warga / pelapor")
    actor(d, 180, 650, "Relawan")
    actor(d, 3060, 1110, "Admin")
    return im


def render_interaction_overview():
    w, h = 3600, 2220
    im = Image.new("RGB", (w, h), BG)
    d = ImageDraw.Draw(im)

    # SOS intake line.
    rect_node(d, (50, 180, 150, 250), "Mulai",
              fill=BG, outline=BLUE, size=20, radius=35)
    rect_node(d, (200, 155, 540, 275), "«interactionUse»\nPilih lokasi kejadian",
              fill=PALE_BLUE, outline=BLUE, size=25)
    rect_node(d, (640, 155, 970, 275), "«interactionUse»\nKirim laporan atau SOS",
              fill=PALE_BLUE, outline=BLUE, size=25)
    diamond_node(d, (1150, 215), 270, 150, "Data dan lokasi\nvalid?", size=25)
    rect_node(d, (1035, 390, 1435, 520), "Pesan gagal;\ntanda terima tidak dibuat",
              fill=PALE_RED, outline=RED, size=23)
    rect_node(d, (1330, 155, 1710, 275), "«interactionUse»\nSimpan laporan sumber",
              fill=PALE_TEAL, outline=TEAL, size=25)
    rect_node(d, (1800, 155, 2190, 275), "Kirim tanda terima\nsetelah penyimpanan",
              fill=PALE_TEAL, outline=TEAL, size=25)
    rect_node(d, (1555, 415, 1675, 495), "Selesai", fill=BG, outline=RED,
              size=20, radius=35)
    connector(d, [(150, 215), (200, 215)], color=BLUE)
    connector(d, [(540, 215), (640, 215)], color=BLUE)
    connector(d, [(970, 215), (1015, 215)], color=BLUE)
    connector(d, [(1285, 215), (1330, 215)], color=TEAL)
    edge_label(d, (1305, 180), "Ya", color=TEAL)
    connector(d, [(1150, 290), (1150, 455), (1035, 455)], color=RED)
    edge_label(d, (1115, 375), "Tidak", color=RED)
    connector(d, [(1435, 455), (1555, 455)], color=RED)
    connector(d, [(1710, 215), (1800, 215)], color=TEAL)

    # Asynchronous and independent advisory analysis.
    panel = (180, 600, 2820, 1010)
    d.rounded_rectangle(panel, radius=26, fill="#FAFBFC", outline="#CCD6E0", width=3)
    d.text((220, 620), "Analisis pendukung setelah laporan tersimpan",
           font=font(27, True), fill=MUTED)
    rect_node(d, (380, 710, 1190, 865), "«interactionUse» Laya Multilingual\nSaran kategori dan urgensi",
              fill=PALE_PURPLE, outline=PURPLE, size=27, dashed=True)
    rect_node(d, (1780, 710, 2590, 865), "«interactionUse» DBSCAN\nKandidat laporan terkait",
              fill=PALE_PURPLE, outline=PURPLE, size=27, dashed=True)
    rect_node(d, (980, 900, 1990, 980), "Keluaran disimpan terpisah; laporan sumber tetap utuh",
              fill=BG, outline=TEAL, size=23, radius=16)
    connector(d, [(1995, 275), (1995, 545), (785, 545), (785, 710)],
              color=PURPLE, width=4, dashed=True)
    connector(d, [(1995, 275), (1995, 710)], color=PURPLE, width=4, dashed=True)
    connector(d, [(785, 865), (785, 940), (980, 940)], color=PURPLE, width=4, dashed=True)
    connector(d, [(2185, 865), (2185, 940), (1990, 940)], color=PURPLE, width=4, dashed=True)
    connector(d, [(1485, 980), (1485, 1215)], color=TEAL)

    # Human review and decision to send a targeted notification.
    diamond_node(d, (1480, 1300), 370, 170, "Perlu tinjauan\nmanusia?", size=24)
    connector(d, [(1480, 1175), (1480, 1215)], color=LINE)
    rect_node(d, (340, 1385, 1050, 1535), "«interactionUse» Admin\nmeninjau dan mengoreksi",
              fill=PALE_AMBER, outline=AMBER, size=25)
    rect_node(d, (1900, 1385, 2610, 1535), "Saran tetap bersifat\npendukung",
              fill=PALE_TEAL, outline=TEAL, size=25)
    connector(d, [(1295, 1300), (1050, 1300), (1050, 1460)], color=AMBER)
    edge_label(d, (1160, 1270), "Ya", color=AMBER)
    connector(d, [(1665, 1300), (1900, 1300), (1900, 1460)], color=TEAL)
    edge_label(d, (1795, 1270), "Tidak", color=TEAL)

    diamond_node(d, (1480, 1640), 390, 170, "Admin menyetujui\npenawaran tugas?", size=23)
    connector(d, [(700, 1535), (700, 1580), (1285, 1640)], color=AMBER)
    connector(d, [(2255, 1535), (2255, 1580), (1675, 1640)], color=TEAL)
    rect_node(d, (300, 1825, 950, 1970), "Tetap dalam antrean;\nbelum ada penugasan",
              fill=PALE_AMBER, outline=AMBER, size=24)
    connector(d, [(1285, 1640), (1110, 1640), (950, 1825)], color=LINE)
    edge_label(d, (1080, 1650), "Belum", color=LINE)

    rect_node(d, (1780, 1825, 2310, 1970), "«interactionUse» Kirim\npenawaran ke widget relawan",
              fill=PALE_BLUE, outline=BLUE, size=24)
    diamond_node(d, (2520, 1895), 340, 165, "Relawan menerima\npenawaran?", size=23)
    connector(d, [(1675, 1640), (1715, 1640), (1715, 1895), (1780, 1895)], color=BLUE)
    edge_label(d, (1687, 1740), "Ya", color=BLUE)
    connector(d, [(2310, 1895), (2350, 1895)], color=BLUE)
    rect_node(d, (2700, 1825, 2990, 1970), "Tugas diterima\noleh relawan",
              fill=PALE_TEAL, outline=TEAL, size=23)
    connector(d, [(2690, 1895), (2700, 1895)], color=TEAL)
    edge_label(d, (2695, 1860), "Ya", color=TEAL, size=20)
    rect_node(d, (3110, 1825, 3530, 1970),
              "«interactionUse»\nTampilkan rute dan ETA sebagai perkiraan",
              fill=PALE_PURPLE, outline=PURPLE, size=22)
    connector(d, [(2990, 1895), (3110, 1895)], color=PURPLE)
    rect_node(d, (2290, 2010, 2860, 2165), "Ditolak atau belum dijawab;\nadmin melihat status",
              fill=PALE_AMBER, outline=AMBER, size=23)
    connector(d, [(2520, 1977), (2520, 2010)], color=AMBER)
    edge_label(d, (2585, 1995), "Tidak", color=AMBER, size=20)
    # Keep the first and last interactions inside a safe page margin so image
    # previews and document crops do not cut labels at the canvas edges.
    padded = Image.new("RGB", (w + 200, h), BG)
    padded.paste(im, (100, 0))
    return padded


def component_box(draw, box, title, fill, outline, dashed=False, size=26):
    rect_node(draw, box, title, fill=fill, outline=outline, size=size,
              dashed=dashed, radius=17, bold=False, width=4)
    x1, y1, _, _ = box
    # Small UML component glyph, kept inside the node boundary.
    draw.rectangle((x1 + 14, y1 + 15, x1 + 48, y1 + 43),
                   fill=BG, outline=outline, width=2)


def render_component():
    w, h = 3300, 1740
    im = Image.new("RGB", (w, h), BG)
    d = ImageDraw.Draw(im)
    groups = [
        ((70, 120, 620, 1600), "PERMUKAAN PENGGUNA", PALE_BLUE, BLUE),
        ((700, 120, 1500, 1600), "LAYANAN APLIKASI", PALE_TEAL, TEAL),
        ((1580, 120, 2250, 950), "ANALISIS PENDUKUNG", PALE_PURPLE, PURPLE),
        ((2350, 120, 3210, 950), "PENYIMPANAN", PALE_AMBER, AMBER),
        ((1580, 1050, 2250, 1600), "LAYANAN EKSTERNAL", "#F4F2F8", PURPLE),
    ]
    for box, title, fill, outline in groups:
        d.rounded_rectangle(box, radius=24, fill=fill, outline=outline, width=3)
        d.text((box[0] + 26, box[1] + 20), title, font=font(23, True), fill=outline)

    # Component dependencies, drawn before the component nodes.
    connector(d, [(355, 390), (355, 455)], color=BLUE, width=4)
    connector(d, [(570, 540), (700, 540), (700, 465), (820, 465)],
              color=BLUE, width=4, dashed=True)
    connector(d, [(570, 845), (740, 845), (740, 550), (820, 550)],
              color=BLUE, width=4, dashed=True)
    connector(d, [(570, 1125), (770, 1125), (770, 560), (820, 560)],
              color=BLUE, width=4, dashed=True)
    connector(d, [(1120, 590), (1120, 690)], color=TEAL, width=4)
    connector(d, [(1120, 835), (1120, 885)], color=TEAL, width=4)
    connector(d, [(1120, 1010), (1120, 1080)], color=TEAL, width=4)
    connector(d, [(1420, 465), (1525, 465), (1525, 310), (1660, 310)],
              color=PURPLE, width=4, dashed=True)
    connector(d, [(1420, 770), (1525, 770), (1525, 590), (1660, 590)],
              color=PURPLE, width=4, dashed=True)
    connector(d, [(1420, 780), (2300, 780), (2300, 430), (2450, 430)],
              color=AMBER, width=4, dashed=True)
    connector(d, [(1420, 945), (2320, 945), (2320, 760), (2450, 760)],
              color=AMBER, width=4, dashed=True)
    connector(d, [(2170, 310), (2310, 310), (2310, 375), (2450, 375)],
              color=PURPLE, width=4, dashed=True)
    connector(d, [(2170, 590), (2320, 590), (2320, 480), (2450, 480)],
              color=PURPLE, width=4, dashed=True)
    connector(d, [(1420, 820), (1500, 820), (1500, 1290), (1660, 1290)],
              color=PURPLE, width=4, dashed=True)
    connector(d, [(820, 1140), (650, 1140), (650, 1125), (570, 1125)],
              color=BLUE, width=4, dashed=True)

    component_box(d, (140, 240, 570, 390),
                  "«component» Widget pelapor Android\nPintu masuk laporan dan SOS",
                  BG, BLUE, dashed=True, size=25)
    component_box(d, (140, 455, 570, 625),
                  "«component» Alur pelaporan Flutter\nFormulir dan pengiriman",
                  BG, BLUE, dashed=True, size=24)
    component_box(d, (140, 755, 570, 930),
                  "«component» Widget tugas relawan Android\nMelihat penawaran; terima atau tolak",
                  BG, BLUE, dashed=True, size=23)
    component_box(d, (140, 1035, 570, 1215),
                  "«component» Dashboard admin\nPeninjauan dan koordinasi",
                  BG, BLUE, dashed=True, size=24)
    component_box(d, (820, 340, 1420, 590),
                  "«component» API FastAPI\nREST dan WebSocket",
                  BG, TEAL, size=26)
    component_box(d, (820, 690, 1420, 835),
                  "«component» Pengelolaan laporan dan status",
                  BG, TEAL, size=25)
    component_box(d, (820, 885, 1420, 1010),
                  "«component» Kebijakan akses dan peran",
                  BG, TEAL, dashed=True, size=24)
    component_box(d, (820, 1080, 1420, 1205),
                  "«component» Pemberitahuan terarah",
                  BG, TEAL, dashed=True, size=24)

    component_box(d, (1660, 225, 2170, 395),
                  "«component» Laya Multilingual\nKandidat saran triase",
                  BG, PURPLE, dashed=True, size=25)
    component_box(d, (1660, 505, 2170, 675),
                  "«component» DBSCAN\nKandidat laporan terkait",
                  BG, PURPLE, dashed=True, size=25)
    component_box(d, (2450, 335, 3110, 525),
                  "«component» PostgreSQL / PostGIS\nLaporan sumber dan data lokasi",
                  BG, AMBER, dashed=True, size=25)
    component_box(d, (2450, 675, 3110, 835),
                  "«component» Riwayat perubahan persisten",
                  BG, AMBER, dashed=True, size=24)
    component_box(d, (1660, 1190, 2170, 1390),
                  "«component» OSRM\nRute dan ETA setelah relawan menerima tugas",
                  BG, PURPLE, dashed=True, size=24)

    edge_label(d, (680, 600), "REST", color=BLUE, size=20)
    edge_label(d, (680, 845), "REST", color=BLUE, size=20)
    edge_label(d, (690, 1125), "REST / WebSocket", color=BLUE, size=20)
    edge_label(d, (1110, 650), "API calls", color=TEAL, size=20)
    return im


if __name__ == "__main__":
    export(render_use_case(), "GAMBAR_3_1_USE_CASE")
    export(render_interaction_overview(), "GAMBAR_3_2_INTERACTION_OVERVIEW")
    export(render_component(), "GAMBAR_3_3_COMPONENT")
