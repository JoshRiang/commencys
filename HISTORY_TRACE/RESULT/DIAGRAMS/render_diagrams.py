from pathlib import Path
# Render the proposal and current-state diagrams used by the chapters and docs site.
# The archived sources live one folder deeper than the repository's active code.
from math import atan2, cos, sin, pi
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / 'HISTORY_TRACE' / 'RESULT' / 'DIAGRAMS'
DOCS = ROOT / 'docs'
OUT.mkdir(parents=True, exist_ok=True)

REGULAR = r'C:\Windows\Fonts\arial.ttf'
BOLD = r'C:\Windows\Fonts\arialbd.ttf'

INK = '#15263A'
MUTED = '#52667D'
BLUE = '#2A6496'
TEAL = '#24786F'
PURPLE = '#7256A6'
AMBER = '#A66A12'
RED = '#A94343'
BG = '#F7F9FC'
WHITE = '#FFFFFF'
LINE = '#64778C'
PALE_BLUE = '#EAF2F9'
PALE_TEAL = '#E9F4F1'
PALE_PURPLE = '#F0ECF8'
PALE_AMBER = '#FBF2E4'
PALE_RED = '#F9ECEB'


def font(size, bold=False):
    return ImageFont.truetype(BOLD if bold else REGULAR, size)


def canvas(width, height, title, subtitle):
    im = Image.new('RGB', (width, height), BG)
    d = ImageDraw.Draw(im)
    d.text((64, 38), title, font=font(46, True), fill=INK)
    d.text((66, 100), subtitle, font=font(25), fill=MUTED)
    d.line((64, 150, width - 64, 150), fill='#D6DEE8', width=2)
    return im, d


def wrap_lines(draw, text, fnt, max_width):
    lines = []
    for para in str(text).split('\n'):
        words = para.split()
        if not words:
            lines.append('')
            continue
        line = words[0]
        for word in words[1:]:
            candidate = line + ' ' + word
            if draw.textbbox((0, 0), candidate, font=fnt)[2] <= max_width:
                line = candidate
            else:
                lines.append(line)
                line = word
        lines.append(line)
    return lines


def centered_text(draw, box, text, fnt, color=INK, gap=7):
    x1, y1, x2, y2 = box
    lines = wrap_lines(draw, text, fnt, x2 - x1 - 34)
    heights = [draw.textbbox((0, 0), line or 'Ag', font=fnt)[3] for line in lines]
    total = sum(heights) + gap * (len(lines) - 1)
    y = y1 + (y2 - y1 - total) / 2
    for line, h in zip(lines, heights):
        w = draw.textbbox((0, 0), line, font=fnt)[2]
        draw.text((x1 + (x2 - x1 - w) / 2, y), line, font=fnt, fill=color)
        y += h + gap


def node(draw, rect, title, detail='', color=BLUE, fill=PALE_BLUE, radius=24, size=31, detail_size=23, outline=None):
    outline = outline or color
    draw.rounded_rectangle(rect, radius=radius, fill=fill, outline=outline, width=3)
    x1, y1, x2, y2 = rect
    content = title if not detail else title + '\n' + detail
    fnt = font(size, bool(detail))
    if detail:
        lines1 = wrap_lines(draw, title, font(size, True), x2 - x1 - 34)
        lines2 = wrap_lines(draw, detail, font(detail_size), x2 - x1 - 34)
        gap = 8
        h1 = sum(draw.textbbox((0,0), l, font=font(size,True))[3] for l in lines1)
        h2 = sum(draw.textbbox((0,0), l, font=font(detail_size))[3] for l in lines2)
        total = h1 + h2 + gap
        y = y1 + (y2-y1-total)/2
        for line in lines1:
            b = draw.textbbox((0,0),line,font=font(size,True)); w=b[2]; h=b[3]
            draw.text((x1+(x2-x1-w)/2,y),line,font=font(size,True),fill=INK); y += h + 3
        y += gap - 3
        for line in lines2:
            b = draw.textbbox((0,0),line,font=font(detail_size)); w=b[2]; h=b[3]
            draw.text((x1+(x2-x1-w)/2,y),line,font=font(detail_size),fill=MUTED); y += h + 2
    else:
        centered_text(draw, rect, title, font(size, True), INK)


def arrow(draw, p1, p2, label=None, color=LINE, width=4, dashed=False, label_offset=-20, head=17):
    x1,y1 = p1; x2,y2 = p2
    if dashed:
        dx=x2-x1; dy=y2-y1; length=max(1,(dx*dx+dy*dy)**0.5)
        ux=dx/length; uy=dy/length
        pos=0
        while pos < length-head:
            end=min(pos+18,length-head)
            draw.line((x1+ux*pos,y1+uy*pos,x1+ux*end,y1+uy*end),fill=color,width=width)
            pos += 30
    else:
        draw.line((x1,y1,x2,y2),fill=color,width=width)
    ang=atan2(y2-y1,x2-x1)
    left=(x2-head*cos(ang-pi/6), y2-head*sin(ang-pi/6))
    right=(x2-head*cos(ang+pi/6), y2-head*sin(ang+pi/6))
    draw.polygon([(x2,y2),left,right],fill=color)
    if label:
        mx=(x1+x2)/2; my=(y1+y2)/2 + label_offset
        f=font(21, True); b=draw.textbbox((0,0),label,font=f)
        w=b[2]+16; h=b[3]+8
        draw.rounded_rectangle((mx-w/2,my-h/2,mx+w/2,my+h/2),radius=7,fill=BG)
        draw.text((mx-b[2]/2,my-b[3]/2-2),label,font=f,fill=color)


def poly_arrow(draw, points, color=LINE, width=4, label=None):
    for a,b in zip(points[:-2], points[1:-1]):
        draw.line((a,b),fill=color,width=width)
    arrow(draw,points[-2],points[-1],label=label,color=color,width=width)


def decision(draw, center, w, h, text, color=AMBER, fill=PALE_AMBER, size=28):
    x,y=center
    pts=[(x,y-h/2),(x+w/2,y),(x,y+h/2),(x-w/2,y)]
    draw.polygon(pts,fill=fill,outline=color)
    draw.line(pts+[pts[0]],fill=color,width=3)
    centered_text(draw,(x-w/2+35,y-h/2+15,x+w/2-35,y+h/2-15),text,font(size,True),INK)


def actor(draw, cx, top, label, scale=1.0):
    r=int(25*scale); head_y=top+r
    draw.ellipse((cx-r,head_y-r,cx+r,head_y+r),outline=INK,width=4)
    body_top=head_y+r+5; body_bottom=body_top+int(65*scale)
    draw.line((cx,body_top,cx,body_bottom),fill=INK,width=4)
    draw.line((cx-int(42*scale),body_top+int(20*scale),cx+int(42*scale),body_top+int(20*scale)),fill=INK,width=4)
    draw.line((cx,body_bottom,cx-int(38*scale),body_bottom+int(55*scale)),fill=INK,width=4)
    draw.line((cx,body_bottom,cx+int(38*scale),body_bottom+int(55*scale)),fill=INK,width=4)
    f=font(int(25*scale),True)
    lines=wrap_lines(draw,label,f,250)
    y=top+int(18*scale)
    for line in lines:
        draw.text((cx+int(55*scale),y),line,font=f,fill=INK)
        y += draw.textbbox((0,0),line,font=f)[3] + 3


def save(im, path):
    crop_bottom = {
        'chapter1_logical_architecture.png': 1470,
        'chapter2_delivery_roadmap.png': 1080,
        'architecture-target.png': 1470,
        'architecture.png': 1120,
        'use_case_target.png': 1625,
        'use_case_as_is.png': 1625,
        'interaction_overview_review.png': 1300,
        'interaction_overview_sos.png': 2965,
        'components_target.png': 1245,
        'components_as_is.png': 1245,
        'lightweight-scrum-flow.png': 870,
    }
    bottom = crop_bottom.get(Path(path).name)
    if bottom is not None:
        im = im.crop((0, 150, im.width, bottom))
        ImageDraw.Draw(im).rectangle((0, 0, im.width, 3), fill=BG)
    im.save(path, format='PNG', optimize=True)


def chapter1_logical_architecture():
    w,h=2800,1680
    im,d=canvas(w,h,'Arsitektur logis Commencys','Laporan disimpan sebelum analisis. Model memberi saran; admin menetapkan tindak lanjut.')
    bands=[(70,205,2730,520,'PENERIMAAN LAPORAN',PALE_BLUE,BLUE),(70,545,2730,970,'ANALISIS PENDUKUNG',PALE_TEAL,TEAL),(70,995,2730,1440,'KOORDINASI DAN RUTE',PALE_PURPLE,PURPLE)]
    for x1,y1,x2,y2,label,fill,col in bands:
        d.rounded_rectangle((x1,y1,x2,y2),radius=24,fill=fill,outline=col,width=3)
        d.text((x1+26,y1+17),label,font=font(24,True),fill=col)

    # Synchronous intake path
    node(d,(110,300,370,445),'Warga pelapor','Menyampaikan laporan',BLUE,WHITE,size=26,detail_size=19)
    node(d,(430,300,730,445),'Widget pelapor Android','Pintu masuk laporan dan SOS',BLUE,WHITE,size=25,detail_size=18)
    node(d,(790,300,1090,445),'Formulir Flutter','Teks, lokasi, akurasi',BLUE,WHITE,size=25,detail_size=19)
    node(d,(1150,300,1480,445),'API insiden','Validasi dan otorisasi',TEAL,WHITE,size=26,detail_size=19)
    node(d,(1540,300,1870,445),'PostgreSQL / PostGIS','Laporan sumber, lokasi, status',AMBER,WHITE,size=25,detail_size=19)
    d.rounded_rectangle((1900,300,2685,445),radius=22,fill=WHITE,outline=BLUE,width=3)
    centered_text(d,(1920,315,2665,430),'API memberi tanda terima setelah laporan tersimpan. Target waktu penerimaan perlu diuji pada lingkungan yang disepakati.',font(23),INK)
    arrow(d,(370,373),(430,373),color=BLUE)
    arrow(d,(730,373),(790,373),color=BLUE)
    arrow(d,(1090,373),(1150,373),color=BLUE)
    arrow(d,(1480,373),(1540,373),color=TEAL)

    # Asynchronous analysis path; the committed record is preserved.
    node(d,(1410,680,1760,825),'Pekerja asinkron','Dimulai setelah penyimpanan',TEAL,WHITE,size=25,detail_size=19)
    poly_arrow(d,[(1705,445),(1705,560),(1585,560),(1585,680)],color=TEAL,width=4,label='setelah commit')
    node(d,(1810,610,2120,750),'Laya Multilingual','Saran jenis dan urgensi',PURPLE,WHITE,size=23,detail_size=19)
    node(d,(1810,805,2120,945),'PostGIS + DBSCAN','Kandidat laporan terkait',PURPLE,WHITE,size=24,detail_size=19)
    poly_arrow(d,[(1760,730),(1785,730),(1785,680),(1810,680)],color=PURPLE,width=4)
    poly_arrow(d,[(1760,775),(1785,775),(1785,875),(1810,875)],color=PURPLE,width=4)
    node(d,(2180,685,2675,855),'Dashboard admin','Admin meninjau dan memutuskan',AMBER,WHITE,size=24,detail_size=19)
    arrow(d,(2120,680),(2180,725),color=PURPLE,width=4)
    arrow(d,(2120,875),(2180,815),color=PURPLE,width=4)
    d.text((111,915),'Hasil analisis disimpan terpisah. Laporan sumber tidak ditimpa atau dihapus.',font=font(21,True),fill=MUTED)

    # Human decision, authorized status updates, and routing after acceptance.
    node(d,(2180,1070,2675,1205),'Keputusan status','Admin berwenang',AMBER,WHITE,size=23,detail_size=19)
    arrow(d,(2425,855),(2425,1070),color=AMBER,width=4,label='hasil tinjauan',label_offset=-10)
    node(d,(1800,1070,2120,1205),'Status dan tugas','Pemberitahuan yang terarah',TEAL,WHITE,size=23,detail_size=19)
    node(d,(1410,1070,1730,1205),'WebSocket','Pembaruan status',TEAL,WHITE,size=24,detail_size=19)
    node(d,(960,1070,1340,1205),'Penerima pemberitahuan','Pelapor dan relawan',BLUE,WHITE,size=24,detail_size=19)
    arrow(d,(2180,1138),(2120,1138),color=AMBER,width=4)
    arrow(d,(1800,1138),(1730,1138),color=TEAL,width=4)
    arrow(d,(1410,1138),(1340,1138),color=TEAL,width=4)

    node(d,(960,1270,1340,1405),'Widget tugas relawan','Lihat, terima, atau tolak',BLUE,WHITE,size=23,detail_size=19)
    node(d,(1410,1270,1730,1405),'OSRM','Menghitung rute',PURPLE,WHITE,size=24,detail_size=19)
    node(d,(1800,1270,2120,1405),'Rute dan ETA','Perkiraan perjalanan',PURPLE,WHITE,size=24,detail_size=19)
    arrow(d,(1150,1205),(1150,1270),color=BLUE,width=4,label='setelah notifikasi',label_offset=-12)
    arrow(d,(1340,1338),(1410,1338),color=PURPLE,width=4,label='permintaan rute',label_offset=-25)
    arrow(d,(1730,1338),(1800,1338),color=PURPLE,width=4)
    d.rounded_rectangle((2180,1270,2675,1405),radius=22,fill=WHITE,outline=AMBER,width=3)
    centered_text(d,(2200,1284,2655,1390),'Rute diminta setelah relawan menerima tugas. ETA tetap merupakan perkiraan.',font(22),INK)

    d.rounded_rectangle((70,1475,2730,1615),radius=20,fill=WHITE,outline='#D6DEE8',width=2)
    centered_text(d,(95,1490,2705,1600),'Tanda terima sistem, pemberitahuan, dan penerimaan tugas adalah status berbeda. Jalur analisis tidak menahan penyimpanan SOS. Diagram ini menunjukkan rancangan logis, bukan UML atau bukti implementasi.',font(23),MUTED)
    # Figure title and notes belong in the chapter text, outside the image.
    save(im,OUT/'chapter1_logical_architecture.png')
    save(im,DOCS/'architecture-target.png')

def current_architecture():
    # Show the current scaffold boundary; dashed links are inactive intentions, not live traffic.
    w,h=1800,900
    im=Image.new('RGB',(w,h),BG)
    d=ImageDraw.Draw(im)
    groups=[
        (45,55,500,790,'PERMUKAAN',PALE_BLUE,BLUE),
        (645,55,500,790,'FASTAPI',PALE_TEAL,TEAL),
        (1245,55,510,790,'SERVICE IMPORT',PALE_PURPLE,PURPLE),
    ]
    for x,y,gw,gh,label,fill,col in groups:
        d.rounded_rectangle((x,y,x+gw,y+gh),radius=22,fill=fill,outline=col,width=3)
        d.text((x+20,y+18),label,font=font(23,True),fill=col)

    node(d,(75,105,515,235),'Widget pelapor','Tata letak statis; aksi dinonaktifkan',BLUE,WHITE,size=24,detail_size=18)
    node(d,(75,270,515,400),'Shell Flutter','Alur laporan; lokasi dan API belum aktif',BLUE,WHITE,size=24,detail_size=18)
    node(d,(75,435,515,575),'Widget relawan','Feed dan aksi tugas dinonaktifkan',BLUE,WHITE,size=24,detail_size=18)
    node(d,(75,610,515,750),'Dashboard admin','Antrean statis; data dan tindakan belum aktif',BLUE,WHITE,size=23,detail_size=18)

    node(d,(675,145,1115,275),'Health API','Scaffold; readiness false',TEAL,WHITE,size=25,detail_size=19)
    node(d,(675,325,1115,455),'Route API','Operasional berhenti pada HTTP 501',TEAL,WHITE,size=25,detail_size=19)
    node(d,(675,505,1115,635),'Payload','Objek JSON; tanpa skema aplikasi',TEAL,WHITE,size=25,detail_size=19)
    node(d,(675,685,1115,785),'Dashboard asset','Disajikan dari FastAPI',TEAL,WHITE,size=23,detail_size=18)

    node(d,(1275,135,1725,255),'StateStore','Antarmuka saja; basis data tidak dibuka',PURPLE,WHITE,size=23,detail_size=18)
    node(d,(1275,300,1725,420),'ai_pipeline.py','Tidak dipanggil oleh route API',PURPLE,WHITE,size=23,detail_size=18)
    node(d,(1275,500,1725,620),'Laya','Diimpor; router dan bobot tidak dimuat',PURPLE,WHITE,size=23,detail_size=18)
    node(d,(1275,680,1725,800),'DBSCAN','Diimpor; data tidak dikelompokkan',PURPLE,WHITE,size=23,detail_size=18)

    # Keep short connector labels inside the narrow gaps between component groups.
    arrow(d,(515,335),(675,390),'API kelak',color=BLUE,dashed=True,label_offset=-22)
    arrow(d,(515,505),(675,390),'tugas kelak',color=BLUE,dashed=True,label_offset=-22)
    arrow(d,(515,680),(675,570),'API kelak',color=BLUE,dashed=True,label_offset=-22)
    # The asset-serving flow leaves the asset node from its left edge so it does not
    # pass across the node's own label on the way to the admin dashboard.
    arrow(d,(675,735),(515,680),'aset web',color=TEAL,dashed=True,label_offset=24)
    arrow(d,(1115,390),(1275,195),'nonaktif',color=PURPLE,dashed=True,label_offset=-22)
    arrow(d,(1500,420),(1500,500),'import',color=PURPLE,dashed=True,label_offset=-18)
    arrow(d,(1500,620),(1500,680),'import',color=PURPLE,dashed=True,label_offset=-18)
    im.save(DOCS/'architecture.png',format='PNG',optimize=True)


def draw_use_case(path, target=True):
    if target:
        w,h=2700,1740
        im,d=canvas(w,h,'Commencys: diagram use case sasaran','Aktor dan tujuan sistem yang diusulkan. Diagram ini tidak menyatakan bahwa autentikasi atau seluruh fungsi sudah berjalan.')
        boundary=(70,360,2630,1620)
        d.rounded_rectangle(boundary,radius=28,fill=WHITE,outline=BLUE,width=4)
        d.text((100,285),'Batas sistem',font=font(24,True),fill=BLUE)
        cols=[450,1350,2250]
        labels=['Warga pelapor','Relawan','Admin (operator dashboard)']
        cases=[
            ['Kirim laporan','Kirim SOS','Pilih lokasi'],
            ['Lihat penawaran pada widget','Terima atau tolak dari widget','Lihat rute setelah menerima'],
            ['Tinjau laporan dan saran','Koreksi triase','Pisahkan tautan laporan','Koordinasikan status tugas','Kelola akses dan kebijakan','Tinjau riwayat perubahan']]
        widths=[620,620,620]
        for cx,label,items in zip(cols,labels,cases):
            actor(d,cx,155,label,0.85)
            col_width=widths[cols.index(cx)]
            trunk_x=cx-col_width/2-35
            d.line((cx,258,cx,420),fill=LINE,width=3)
            d.line((trunk_x,420,cx,420),fill=LINE,width=3)
            d.line((trunk_x,420,trunk_x,1435),fill=LINE,width=3)
            for i,item in enumerate(items):
                cy=475+i*175
                rect=(cx-col_width/2,cy-52,cx+col_width/2,cy+52)
                d.line((trunk_x,cy,cx-col_width/2,cy),fill=LINE,width=3)
                d.ellipse(rect,fill='#F5F8FC',outline=BLUE,width=3)
                centered_text(d,rect,item,font(25,True),INK)
        d.text((95,1645),'Titik acuan menerima laporan tidak sama dengan penerimaan tugas oleh relawan.',font=font(23),fill=MUTED)
        save(im,path)
    else:
        w,h=2050,1740
        im,d=canvas(w,h,'Commencys: diagram use case saat ini','Kemampuan yang tampak pada source code. Operator antarmuka bukan peran terautentikasi.')
        boundary=(70,360,1980,1620)
        d.rounded_rectangle(boundary,radius=28,fill=WHITE,outline=BLUE,width=4)
        d.text((100,285),'Batas sistem',font=font(24,True),fill=BLUE)
        cols=[600,1500]
        labels=['Pengguna aplikasi','Operator konsol']
        cases=[
            ['Kirim laporan insiden','Kirim SOS','Pilih GPS atau titik peta','Lihat peta dan daftar','Terima event langsung'],
            ['Lihat antrean tinjauan','Koreksi metadata triase','Hapus tautan cluster','Terima atau tolak tugas','Selesaikan tiket diterima','Baca riwayat audit proses','Terima event langsung']]
        for cx,label,items in zip(cols,labels,cases):
            actor(d,cx,155,label,0.9)
            trunk_x=cx-300
            d.line((cx,258,cx,420),fill=LINE,width=3)
            d.line((trunk_x,420,cx,420),fill=LINE,width=3)
            d.line((trunk_x,420,trunk_x,1435),fill=LINE,width=3)
            for i,item in enumerate(items):
                cy=475+i*165
                rect=(cx-280,cy-50,cx+280,cy+50)
                d.line((trunk_x,cy,cx-280,cy),fill=LINE,width=3)
                d.ellipse(rect,fill='#F5F8FC',outline=BLUE,width=3)
                centered_text(d,rect,item,font(25,True),INK)
        d.text((95,1645),'API tidak memverifikasi identitas atau peran. Nama yang dikirim bukan bukti identitas responden.',font=font(22),fill=MUTED)
        save(im,path)


def review_overview(path):
    w,h=2500,1500
    im,d=canvas(w,h,'Interaction Overview: tinjauan dan koordinasi','Setelah tiket dibuka, operator dapat memilih satu atau beberapa tindakan yang tersedia pada prototipe.')
    node(d,(850,190,1650,315),'Muat daftar, pilih tiket, lalu pilih tindakan','API tidak memeriksa peran operator',BLUE,PALE_BLUE,size=29,detail_size=23)
    lanes=[
        (70,'KOREKSI TRIASE','Koreksi diperlukan?','Perbarui metadata','Pertahankan nilai','Jika berubah, catat sebelum dan sesudah lalu kirim pembaruan',TEAL,PALE_TEAL),
        (870,'PEMISAHAN TAUTAN','Tautan cluster keliru?','Hapus satu cluster_id','Pertahankan tautan','Jika diubah, catat pemisahan dan kirim pembaruan',PURPLE,PALE_PURPLE),
        (1670,'TANGGAPAN TUGAS','Terima tugas?','Terima; catat nama yang belum diverifikasi','Tolak; catat penolakan dan biarkan tiket terbuka','Terima mengubah status menjadi accepted. Setelah itu, koordinator dapat menandai tiket selesai.',RED,PALE_RED)]
    centers=[]
    for x,heading,question,yes_text,no_text,result_text,col,fill in lanes:
        d.rounded_rectangle((x,390,x+760,1280),radius=24,fill=WHITE,outline=col,width=3)
        d.text((x+24,410),heading,font=font(24,True),fill=col)
        cx=x+380
        centers.append(cx)
        decision(d,(cx,595),440,165,question,color=AMBER,fill=PALE_AMBER,size=25)
        left=(x+30,740,x+355,900)
        right=(x+405,740,x+730,900)
        node(d,left,yes_text,color=col,fill=fill,size=23)
        node(d,right,no_text,color=AMBER,fill=PALE_AMBER,size=23)
        result=(x+35,1035,x+725,1195)
        node(d,result,result_text,color=col,fill=fill,size=23)
        arrow(d,(cx-205,595),(x+355,820),'Ya',color=col,label_offset=-22)
        arrow(d,(cx+205,595),(x+405,820),'Tidak',color=AMBER,label_offset=-22)
        arrow(d,(x+192,900),(cx-85,1035),color=col)
        arrow(d,(x+568,900),(cx+85,1035),color=AMBER)
    d.line((1250,315,1250,350),fill=LINE,width=3)
    d.line((centers[0],350,centers[-1],350),fill=LINE,width=3)
    for cx in centers:
        arrow(d,(cx,350),(cx,512),color=LINE)
    d.text((100,1340),'Identitas dan peran belum diverifikasi. Resolusi hanya tersedia setelah tiket diterima.',font=font(23),fill=MUTED)
    save(im,path)


def activity_diagram(path, review=False):
    if not review:
        w,h=2200,3030
        im,d=canvas(w,h,'Interaction Overview: alur SOS saat ini','Pembuatan tiket disimpan sebelum tanda terima; retry identik memakai tiket yang sama.')
        cx=1100
        node(d,(820,190,1380,285),'Mulai',color=TEAL,fill=PALE_TEAL,size=28)
        node(d,(780,345,1420,470),'Pilih GPS atau titik peta','Lokasi perlu tersedia',BLUE,PALE_BLUE,size=28,detail_size=22)
        node(d,(780,535,1420,660),'Kirim permintaan SOS','FastAPI menerima koordinat',BLUE,PALE_BLUE,size=28,detail_size=22)
        node(d,(780,725,1420,850),'Validasi permintaan','Termasuk pemeriksaan kunci retry',TEAL,PALE_TEAL,size=29,detail_size=22)
        decision(d,(1100,1000),430,180,'Valid?')
        node(d,(170,910,610,1085),'Kembalikan kesalahan','Tidak ada tanda terima',RED,PALE_RED,size=25,detail_size=21)
        node(d,(170,1160,610,1260),'Selesai',color=TEAL,fill=PALE_TEAL,size=26)
        node(d,(780,1125,1420,1255),'Simpan tiket sebagai acknowledged','Urgensi P1; kunci retry terkait disimpan di memori',TEAL,PALE_TEAL,size=27,detail_size=22)
        node(d,(780,1310,1420,1435),'Catat pembuatan tiket','Riwayat dalam memori',AMBER,PALE_AMBER,size=26,detail_size=22)
        node(d,(780,1490,1420,1615),'Kembalikan HTTP 201','Tanda terima awal',TEAL,PALE_TEAL,size=28,detail_size=22)
        node(d,(780,1670,1420,1795),'Jalankan publish event',color=PURPLE,fill=PALE_PURPLE,size=28)
        decision(d,(1100,1940),520,190,'Ada pengiriman WebSocket yang berhasil?')
        node(d,(170,2050,760,2200),'Pertahankan acknowledged','Tidak ada penerima aktif',AMBER,PALE_AMBER,size=25,detail_size=21)
        node(d,(1440,2050,2030,2200),'Ubah menjadi broadcast','Pengiriman frame berhasil',TEAL,PALE_TEAL,size=25,detail_size=21)
        node(d,(780,2260,1420,2390),'Jalankan aturan dan pencocokan','Di luar jalur tanda terima',PURPLE,PALE_PURPLE,size=27,detail_size=22)
        decision(d,(1100,2555),430,180,'Perlu tinjauan manusia?')
        node(d,(170,2675,760,2815),'Tandai needs_review',color=AMBER,fill=PALE_AMBER,size=24)
        node(d,(1440,2675,2030,2815),'Simpan metadata anjuran',color=PURPLE,fill=PALE_PURPLE,size=24)
        node(d,(820,2850,1380,2950),'Selesai',color=TEAL,fill=PALE_TEAL,size=27)
        arrow(d,(1100,285),(1100,345)); arrow(d,(1100,470),(1100,535)); arrow(d,(1100,660),(1100,725)); arrow(d,(1100,850),(1100,910))
        arrow(d,(885,1000),(610,1000),'Tidak',color=RED,label_offset=-24); arrow(d,(1100,1090),(1100,1125),'Ya',color=TEAL,label_offset=-24)
        arrow(d,(390,1085),(390,1160),color=RED)
        arrow(d,(1100,1255),(1100,1310)); arrow(d,(1100,1435),(1100,1490)); arrow(d,(1100,1615),(1100,1670)); arrow(d,(1100,1795),(1100,1845))
        arrow(d,(840,1940),(760,2125),'Tidak',color=AMBER,label_offset=-28); arrow(d,(1360,1940),(1440,2125),'Ya',color=TEAL,label_offset=-28)
        arrow(d,(760,2125),(780,2325),color=AMBER); arrow(d,(1440,2125),(1420,2325),color=TEAL)
        arrow(d,(1100,2390),(1100,2465)); arrow(d,(885,2555),(760,2745),'Ya',color=AMBER,label_offset=-25); arrow(d,(1315,2555),(1440,2745),'Tidak',color=PURPLE,label_offset=-25)
        arrow(d,(760,2745),(950,2850),color=AMBER); arrow(d,(1440,2745),(1250,2850),color=PURPLE)
        d.text((645,2990),'Status broadcast tidak membuktikan pesan dibaca atau tugas diterima.',font=font(21),fill=MUTED)
        save(im,path)
    else:
        w,h=2200,2800
        im,d=canvas(w,h,'Interaction Overview: tinjauan dan koordinasi','Alur saat ini. Identitas operator dan responder tidak diverifikasi.')
        cx=1100
        node(d,(820,190,1380,285),'Mulai',color=TEAL,fill=PALE_TEAL,size=28)
        node(d,(780,350,1420,475),'Muat daftar atau antrean tinjauan','REST tanpa pemeriksaan peran',BLUE,PALE_BLUE,size=27,detail_size=22)
        decision(d,(1100,640),470,180,'Tiket perlu ditinjau?')
        node(d,(160,770,740,915),'Lihat tiket dan lokasi','Koordinat dibuka oleh API',BLUE,PALE_BLUE,size=25,detail_size=21)
        node(d,(780,770,1420,900),'Lewati tinjauan triase',color=AMBER,fill=PALE_AMBER,size=25)
        decision(d,(450,1085),400,170,'Perlu koreksi?')
        node(d,(160,1200,740,1360),'Koreksi metadata','Isi laporan awal tetap',TEAL,PALE_TEAL,size=26,detail_size=22)
        node(d,(780,1200,1420,1360),'Catat sebelum dan sesudah','Audit dalam memori',AMBER,PALE_AMBER,size=25,detail_size=21)
        decision(d,(1100,1505),450,170,'Tautan laporan keliru?')
        node(d,(160,1620,740,1780),'Hapus satu cluster_id','Laporan tidak dihapus',TEAL,PALE_TEAL,size=25,detail_size=21)
        node(d,(780,1620,1420,1780),'Catat pemisahan tautan','Audit dalam memori',AMBER,PALE_AMBER,size=25,detail_size=21)
        decision(d,(1100,1925),450,170,'Terima tugas?')
        node(d,(1450,2040,2040,2195),'Set status accepted','Nama tidak diverifikasi',RED,PALE_RED,size=25,detail_size=21)
        node(d,(780,2040,1420,2195),'Catat penolakan','Tiket tetap terbuka',color=AMBER,fill=PALE_AMBER,size=25,detail_size=21)
        node(d,(1450,2280,2040,2440),'Kirim event penerimaan','Status accepted',PURPLE,PALE_PURPLE,size=25,detail_size=21)
        node(d,(780,2280,1420,2440),'Kirim event penolakan','Status tidak berubah',color=TEAL,fill=PALE_TEAL,size=25,detail_size=21)
        node(d,(820,2600,1380,2700),'Selesai',color=TEAL,fill=PALE_TEAL,size=28)
        arrow(d,(1100,285),(1100,350)); arrow(d,(1100,475),(1100,550));
        arrow(d,(865,640),(740,840),'Ya',color=TEAL,label_offset=-25); arrow(d,(1335,640),(1420,835),'Tidak',color=AMBER,label_offset=-25)
        arrow(d,(450,915),(450,1000)); arrow(d,(650,1085),(780,1280),'Ya',color=TEAL,label_offset=-25); arrow(d,(450,1170),(450,1200),'Tidak',color=AMBER,label_offset=-25)
        arrow(d,(740,1280),(780,1280)); arrow(d,(1100,1360),(1100,1415));
        arrow(d,(875,1505),(740,1700),'Ya',color=TEAL,label_offset=-25); arrow(d,(1100,1590),(1100,1620),'Tidak',color=AMBER,label_offset=-25)
        arrow(d,(740,1700),(780,1700)); arrow(d,(1100,1780),(1100,1840));
        arrow(d,(1325,1925),(1450,2115),'Ya',color=RED,label_offset=-25); arrow(d,(1100,2010),(1100,2040),'Tidak',color=AMBER,label_offset=-25)
        arrow(d,(1750,2195),(1750,2360)); arrow(d,(1100,2195),(1100,2280));
        arrow(d,(1750,2440),(1380,2650),color=PURPLE); arrow(d,(1100,2440),(1100,2600),color=TEAL)
        d.text((150,2715),'Setelah diterima, koordinator dapat menandai tiket selesai. Identitas dan peran belum diverifikasi.',font=font(22),fill=MUTED)
        save(im,path)


def components_diagram(path, target=True):
    if target:
        w,h=2500,1480
        im,d=canvas(w,h,'Commencys: diagram komponen sasaran','Komponen target dari proposal. FastAPI telah ada; komponen bertanda rencana belum aktif.')
        groups=[(70,230,500,1000,'KLIEN',PALE_BLUE,BLUE),(610,230,640,1000,'LAYANAN',PALE_TEAL,TEAL),(1280,230,520,1000,'PEMROSESAN',PALE_PURPLE,PURPLE),(1830,230,600,1000,'PERSISTENSI DAN OPERASI',PALE_AMBER,AMBER)]
        for x,y,gw,gh,label,fill,col in groups:
            d.rounded_rectangle((x,y,x+gw,y+gh),radius=26,fill=fill,outline=col,width=3)
            d.text((x+22,y+18),label,font=font(24,True),fill=col)
        node(d,(110,315,530,455),'Widget pelapor','Membuka alur laporan dan SOS',BLUE,WHITE,size=26,detail_size=21)
        node(d,(110,525,530,665),'Alur laporan Flutter','Formulir pelapor',BLUE,WHITE,size=26,detail_size=21)
        node(d,(110,735,530,875),'Widget relawan','Lihat penawaran; terima atau tolak',BLUE,WHITE,size=25,detail_size=20)
        node(d,(110,985,530,1125),'Dashboard admin/operator','Tinjauan dan koordinasi',BLUE,WHITE,size=24,detail_size=20)
        node(d,(660,340,1200,500),'FastAPI API','Komponen yang sudah ada',TEAL,WHITE,size=29,detail_size=22)
        node(d,(660,570,1200,720),'Autentikasi dan kebijakan peran','Rencana',TEAL,WHITE,size=25,detail_size=22)
        node(d,(660,790,1200,940),'Penerbit WebSocket terarah','Rencana',TEAL,WHITE,size=25,detail_size=22)
        node(d,(660,1010,1200,1160),'Penyimpanan tiket dan audit','Rencana',TEAL,WHITE,size=25,detail_size=22)
        node(d,(1330,330,1750,490),'Laya Multilingual','Usulan model teks',PURPLE,WHITE,size=25)
        node(d,(1330,575,1750,735),'DBSCAN','Rencana',PURPLE,WHITE,size=28)
        node(d,(1330,820,1750,980),'OSRM','Rencana',PURPLE,WHITE,size=28)
        node(d,(1880,350,2380,520),'PostgreSQL + PostGIS','Rencana',AMBER,WHITE,size=27,detail_size=22)
        node(d,(1880,650,2380,820),'Audit tahan lama','Rencana',AMBER,WHITE,size=27,detail_size=22)
        node(d,(1880,960,2380,1130),'Docker dan operasi','Target penerapan',AMBER,WHITE,size=27,detail_size=22)
        arrow(d,(320,455),(320,525),'buka alur',color=BLUE,label_offset=0)
        arrow(d,(530,595),(660,415),'REST',color=BLUE)
        arrow(d,(530,805),(660,455),'REST',color=BLUE)
        arrow(d,(530,1055),(660,485),'REST / WebSocket',color=BLUE)
        d.line((1220,415,1220,1085),fill=TEAL,width=4)
        arrow(d,(1200,415),(1220,415),color=TEAL)
        arrow(d,(1220,650),(1200,650),'otorisasi',color=TEAL)
        arrow(d,(1220,865),(1200,865),'penerima',color=TEAL)
        arrow(d,(1220,1085),(1200,1085),'data',color=TEAL)
        d.line((1255,415,1255,900),fill=PURPLE,width=4)
        arrow(d,(1200,430),(1255,430),'proses',color=PURPLE)
        arrow(d,(1255,410),(1330,410),color=PURPLE)
        arrow(d,(1255,650),(1330,650),color=PURPLE)
        arrow(d,(1255,900),(1330,900),color=PURPLE)
        d.line((1200,1085,1240,1085),fill=AMBER,width=4)
        d.line((1240,1085,1240,280),fill=AMBER,width=4)
        d.line((1240,280,1855,280),fill=AMBER,width=4)
        d.line((1855,280,1855,435),fill=AMBER,width=4)
        arrow(d,(1855,435),(1880,435),'data',color=AMBER)
        arrow(d,(2130,520),(2130,650),'audit',color=AMBER)
        d.rounded_rectangle((70,1270,2430,1395),radius=20,fill=WHITE,outline='#D6DEE8',width=2)
        centered_text(d,(100,1280,2400,1380),'Semua konektor bertanda target memerlukan kontrak, pengujian, pengelola, dan keputusan arsitektur sebelum dapat dianggap sebagai integrasi.',font(23),MUTED)
        save(im,path)
    else:
        w,h=2500,1480
        im,d=canvas(w,h,'Commencys: diagram komponen saat ini','Komponen dan batas yang terlihat pada working tree. Tidak ada basis data atau layanan model eksternal aktif.')
        groups=[(70,230,500,1000,'KLIEN',PALE_BLUE,BLUE),(610,230,650,1000,'FASTAPI',PALE_TEAL,TEAL),(1300,230,560,1000,'KOMPONEN PROSES',PALE_PURPLE,PURPLE),(1900,230,530,1000,'DATA DAN EKSTERNAL',PALE_AMBER,AMBER)]
        for x,y,gw,gh,label,fill,col in groups:
            d.rounded_rectangle((x,y,x+gw,y+gh),radius=26,fill=fill,outline=col,width=3)
            d.text((x+22,y+18),label,font=font(24,True),fill=col)
        node(d,(110,350,530,520),'Aplikasi Flutter','Dart screens and widgets',BLUE,WHITE,size=28,detail_size=22)
        node(d,(110,590,530,760),'Flutter services','HTTP client and reconnecting socket',BLUE,WHITE,size=26,detail_size=21)
        node(d,(110,900,530,1070),'Konsol peramban','HTML, CSS, JavaScript',BLUE,WHITE,size=27,detail_size=22)
        node(d,(660,340,1210,490),'FastAPI application','REST, WebSocket, static mount',TEAL,WHITE,size=27,detail_size=22)
        node(d,(660,590,1210,740),'Model Pydantic','Validasi dan serialisasi',TEAL,WHITE,size=27,detail_size=22)
        node(d,(660,870,1210,1020),'API tindakan tiket','Terima, tolak, resolusi; tanpa autentikasi peran',TEAL,WHITE,size=25,detail_size=21)
        node(d,(1350,330,1810,480),'Tugas asinkron','Publish dan enrichment',PURPLE,WHITE,size=26,detail_size=22)
        node(d,(1350,570,1810,720),'heuristic-v2','Aturan kata kunci',PURPLE,WHITE,size=27,detail_size=22)
        node(d,(1350,810,1810,960),'spatiotemporal-v1','Pencocokan jarak dan waktu',PURPLE,WHITE,size=26,detail_size=22)
        node(d,(1350,1050,1810,1200),'Kumpulan WebSocket','Lokal pada proses',PURPLE,WHITE,size=26,detail_size=22)
        node(d,(1950,330,2380,500),'Dict dan lock','Tiket dalam memori',AMBER,WHITE,size=26,detail_size=22)
        node(d,(1950,590,2380,760),'Daftar audit','Entri dalam memori',AMBER,WHITE,size=26,detail_size=22)
        node(d,(1950,900,2380,1070),'Ubin OpenStreetMap','Layanan eksternal',AMBER,WHITE,size=25,detail_size=22)
        arrow(d,(530,435),(660,410),'HTTP')
        arrow(d,(530,675),(660,425),'REST / WS')
        arrow(d,(530,985),(660,440),'origin yang sama')
        arrow(d,(1210,410),(1350,405),'tugas latar')
        d.line((1210,620,1275,620),fill=PURPLE,width=4)
        d.line((1275,620,1275,1125),fill=PURPLE,width=4)
        arrow(d,(1275,1125),(1350,1125),'event',color=PURPLE)
        arrow(d,(1580,480),(1580,570),'triase')
        arrow(d,(1580,720),(1580,810),'kandidat')
        d.line((1875,415,1875,885),fill=AMBER,width=4)
        d.line((1190,340,1190,285),fill=AMBER,width=4)
        d.line((1190,285,1875,285),fill=AMBER,width=4)
        d.line((1875,285,1875,415),fill=AMBER,width=4)
        arrow(d,(1810,415),(1875,415),color=AMBER)
        arrow(d,(1810,645),(1875,645),color=AMBER)
        arrow(d,(1810,885),(1875,885),color=AMBER)
        arrow(d,(1875,430),(1950,415),'tiket',color=AMBER)
        arrow(d,(1875,675),(1950,675),'audit',color=AMBER)
        d.line((1210,945,1275,945),fill=AMBER,width=4)
        d.line((1275,945,1275,285),fill=AMBER,width=4)
        d.line((1275,285,1875,285),fill=AMBER,width=4)
        d.line((1875,285,1875,885),fill=AMBER,width=4)
        d.line((530,985,545,985),fill=BLUE,width=4)
        d.line((545,985,545,1238),fill=BLUE,width=4)
        d.line((545,1238,2165,1238),fill=BLUE,width=4)
        arrow(d,(2165,1238),(2165,1070),color=BLUE)
        d.rounded_rectangle((70,1270,2430,1395),radius=20,fill=WHITE,outline='#D6DEE8',width=2)
        centered_text(d,(100,1280,2400,1380),'Semua tiket, audit, kunci proses, dan koneksi WebSocket berada dalam satu proses backend.',font(24),MUTED)
        save(im,path)


def components_current_diagram(path):
    w,h=2500,1480
    im,d=canvas(w,h,'Commencys: diagram komponen saat ini','Widget konsumen dan dashboard operator menggunakan alur yang berbeda.')
    groups=[
        (70,230,500,1000,'PERMUKAAN',PALE_BLUE,BLUE),
        (610,230,650,1000,'FASTAPI',PALE_TEAL,TEAL),
        (1300,230,560,1000,'KOMPONEN PROSES',PALE_PURPLE,PURPLE),
        (1900,230,530,1000,'PERSISTENSI',PALE_AMBER,AMBER),
    ]
    for x,y,gw,gh,label,fill,col in groups:
        d.rounded_rectangle((x,y,x+gw,y+gh),radius=26,fill=fill,outline=col,width=3)
        d.text((x+22,y+18),label,font=font(24,True),fill=col)
    node(d,(110,315,530,455),'Widget Android','Membuka alur SOS',BLUE,WHITE,size=27,detail_size=21)
    node(d,(110,520,530,660),'Aplikasi konsumen Flutter','SOS, laporan, peta, dan notifikasi',BLUE,WHITE,size=26,detail_size=21)
    node(d,(110,725,530,865),'Layanan Flutter','Klien REST dan WebSocket',BLUE,WHITE,size=26,detail_size=21)
    node(d,(110,1000,530,1140),'Dashboard operator','Antrean, tinjauan, dan tindakan',BLUE,WHITE,size=26,detail_size=21)
    node(d,(660,365,1210,525),'Aplikasi FastAPI','REST, WebSocket, aset web, dan aksi tiket',TEAL,WHITE,size=27,detail_size=21)
    node(d,(660,635,1210,785),'Model Pydantic','Validasi dan serialisasi',TEAL,WHITE,size=27,detail_size=21)
    node(d,(1350,340,1810,485),'heuristic-v2','Klasifikasi berbasis kata kunci',PURPLE,WHITE,size=27,detail_size=21)
    node(d,(1350,590,1810,735),'spatiotemporal-v1','Pencocokan jarak dan waktu',PURPLE,WHITE,size=26,detail_size=21)
    node(d,(1950,470,2380,690),'SQLite lokal','Tiket, audit, dan kunci retry SOS',AMBER,WHITE,size=27,detail_size=21)
    arrow(d,(320,455),(320,520),'buka SOS',color=BLUE,label_offset=0)
    arrow(d,(320,660),(320,725),'REST / WS',color=BLUE,label_offset=0)
    arrow(d,(530,795),(660,405),'HTTP / WS')
    arrow(d,(530,1070),(660,485),'same-origin REST / WS')
    arrow(d,(935,525),(935,635),'validasi',color=TEAL,label_offset=0)
    arrow(d,(1210,445),(1350,410),'triase latar',color=PURPLE)
    arrow(d,(1580,485),(1580,590),'hasil triase',color=PURPLE,label_offset=0)
    d.line((1210,500,1240,500),fill=AMBER,width=4)
    d.line((1240,500,1240,300),fill=AMBER,width=4)
    d.line((1240,300,2165,300),fill=AMBER,width=4)
    arrow(d,(2165,300),(2165,470),'SQLite',color=AMBER,label_offset=0)
    d.rounded_rectangle((70,1270,2430,1395),radius=20,fill=WHITE,outline='#D6DEE8',width=2)
    centered_text(d,(100,1280,2400,1380),'SQLite menyimpan state lintas restart satu proses. Autentikasi, peran, pengiriman terarah, dan layanan model belum aktif.',font(23),MUTED)
    save(im,path)


def chapter2_delivery_roadmap():
    w,h=2800,1380
    im,d=canvas(w,h,'Rencana kerja dan gerbang keputusan Commencys','Urutan usulan tanpa tanggal kalender; setiap tahap berakhir pada bukti yang dapat ditinjau.')
    d.rounded_rectangle((80,190,2720,285),radius=20,fill=PALE_BLUE,outline=BLUE,width=2)
    centered_text(d,(100,200,2700,275),'Widget pelapor dan relawan, dashboard admin, lingkup, kapasitas, dan kriteria disepakati sebelum jadwal menjadi komitmen.',font(24,True),INK)

    xs=[90,620,1150,1680,2210]
    wcard=470; y1=345; y2=785
    cards=[
        ('Sepakati dasar','Tujuan, pengguna, widget pelapor dan relawan, dashboard admin, dan kapasitas.\nBukti keluar: fungsi antarmuka dan kriteria penerimaan disetujui.',BLUE,PALE_BLUE),
        ('Utamakan alur SOS','Lokasi dan akurasi, titik manual, penyimpanan, tanda terima, serta pesan kegagalan.\nBukti keluar: alur diuji pada perangkat dan jaringan yang ditetapkan.',TEAL,PALE_TEAL),
        ('Buktikan koordinasi','Pisahkan tanda terima, penawaran, pemberitahuan, dan keputusan terima/tolak relawan dari widget.\nBukti keluar: status dapat ditelusuri saat klien luring dan pulih.',PURPLE,PALE_PURPLE),
        ('Evaluasi dukungan AI','Laya Multilingual dan DBSCAN sebagai saran. Tinjau data, versi, koreksi, dan hasil per kategori.\nBukti keluar: keputusan penggunaan berbasis evaluasi dan tinjauan manusia.',AMBER,PALE_AMBER),
        ('Tinjau kesiapan','Periksa privasi, akses, penyimpanan, pemulihan, pengukuran, dan dukungan.\nBukti keluar: keputusan uji terbatas dan risiko sisa tercatat.',TEAL,PALE_TEAL),
    ]
    for x,(title,detail,col,fill) in zip(xs,cards):
        node(d,(x,y1,x+wcard,y2),title,detail,col,WHITE,radius=24,size=26,detail_size=19)
    for i in range(4):
        arrow(d,(xs[i]+wcard,y1+220),(xs[i+1],y1+220),color=LINE,width=4)

    d.text((90,835),'Pengendalian sepanjang pekerjaan',font=font(25,True),fill=INK)
    controls=[
        ('Risiko','Pemicu, tanggapan, pemilik, bukti, risiko sisa',PURPLE,PALE_PURPLE),
        ('Mutu dan verifikasi','Kriteria, lingkungan, metrik, dan hasil uji',BLUE,PALE_BLUE),
        ('Kapasitas dan peran','Penanggung jawab, pengganti, dependensi',TEAL,PALE_TEAL),
        ('Keputusan dan perubahan','Alasan, dampak, persetujuan, versi acuan',AMBER,PALE_AMBER),
    ]
    cx=[90,750,1410,2070]
    for x,(title,detail,col,fill) in zip(cx,controls):
        node(d,(x,885,x+620,1055),title,detail,col,fill,radius=18,size=22,detail_size=17)

    d.rounded_rectangle((90,1100,2710,1305),radius=20,fill=WHITE,outline='#D6DEE8',width=2)
    centered_text(d,(115,1115,2685,1290),'Kisaran usaha pada Trello masih perkiraan awal. Target tanda terima di bawah lima detik harus diuji. Tanggal dan kapasitas tim perlu disahkan sebelum menjadi jadwal.',font(22),MUTED)
    # Figure title and notes belong in the chapter text, outside the image.
    save(im,OUT/'chapter2_delivery_roadmap.png')

def process_flow():
    w,h=2300,1050
    im,d=canvas(w,h,'Alur kerja pengembangan iteratif','Scrum ringan sebagaimana dinyatakan sebagai pendekatan proyek; kegiatan aktual perlu dicatat oleh tim.')
    xs=[250,700,1150,1600,2050]
    labels=[('Pilih backlog','Prioritas dan hasil yang disepakati'),('Rancang','Kebutuhan dan batas perubahan'),('Bangun','Perubahan kecil yang dapat diperiksa'),('Verifikasi','Uji sesuai kriteria penerimaan'),('Tinjau','Umpan balik dan tindak lanjut')]
    for x,(title,detail) in zip(xs,labels):
        node(d,(x-175,430,x+175,650),title,detail,color=BLUE,fill=WHITE,size=29,detail_size=22)
    for a,b,label in zip(xs[:-1],xs[1:],['item terpilih','rancangan','perubahan','hasil uji']):
        arrow(d,(a+175,540),(b-175,540),label,color=TEAL,label_offset=-26)
    d.line((2050,650,2050,810),fill=TEAL,width=4)
    d.line((2050,810,250,810),fill=TEAL,width=4)
    arrow(d,(250,810),(250,650),label='perbarui backlog',color=TEAL,label_offset=-30)
    d.rounded_rectangle((365,190,1960,330),radius=22,fill=PALE_PURPLE,outline=PURPLE,width=3)
    centered_text(d,(390,205,1935,315),'Pengujian, tinjauan privasi, dan pemeriksaan kesiapan mengikuti perubahan yang relevan pada setiap siklus.',font(27,True),INK)
    arrow(d,(1150,330),(1150,430),color=PURPLE)
    d.text((500,905),'Diagram ini menjelaskan proses yang direncanakan. Repositori belum membuktikan bahwa semua kegiatan telah dilakukan.',font=font(23),fill=MUTED)
    save(im,DOCS/'lightweight-scrum-flow.png')


def main():
    chapter1_logical_architecture()
    current_architecture()
    draw_use_case(OUT/'use_case_target.png',True)
    draw_use_case(OUT/'use_case_as_is.png',False)
    activity_diagram(OUT/'interaction_overview_sos.png',False)
    review_overview(OUT/'interaction_overview_review.png')
    components_current_diagram(OUT/'components_as_is.png')
    components_diagram(OUT/'components_target.png',True)
    process_flow()
    chapter2_delivery_roadmap()
    print('Rendered the architecture, UML, and process PNG diagrams.')

if __name__=='__main__':
    main()
