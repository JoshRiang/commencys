# Render the historical chapter Markdown to PDF with the matching image and caption layout.
# Diagram pages use landscape orientation; text pages use portrait A4.
from __future__ import annotations

import re
from html import escape
from pathlib import Path
from urllib.parse import quote

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    Image,
    KeepTogether,
    LongTable,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
    TableStyle,
    NextPageTemplate,
)


# Source Markdown and final PDFs stay together under the history bundle.
ROOT = Path(__file__).resolve().parents[1]
RESULT = ROOT / "HISTORY_TRACE" / "RESULT"
OUTPUT = ROOT / "HISTORY_TRACE" / "PDF"
CONTENT_WIDTH = A4[0] - 1.75 * inch
LANDSCAPE_PAGE = landscape(A4)
LANDSCAPE_CONTENT_WIDTH = LANDSCAPE_PAGE[0] - 1.4 * inch
INLINE_PATTERN = re.compile(r"(\*\*.+?\*\*|\*.+?\*|`[^`]+`|\[[^\]]+\]\([^)]+\))")
IMAGE_PATTERN = re.compile(r"!\[([^\]]*)\]\(([^)]+)\)")


def register_fonts():
    # Embed the standard Windows Times New Roman faces used by the chapter DOCX files.
    font_directory = Path(r"C:\Windows\Fonts")
    pdfmetrics.registerFont(TTFont("TimesNewRoman", str(font_directory / "times.ttf")))
    pdfmetrics.registerFont(TTFont("TimesNewRoman-Bold", str(font_directory / "timesbd.ttf")))
    pdfmetrics.registerFont(TTFont("TimesNewRoman-Italic", str(font_directory / "timesi.ttf")))
    pdfmetrics.registerFont(TTFont("TimesNewRoman-BoldItalic", str(font_directory / "timesbi.ttf")))
    pdfmetrics.registerFontFamily(
        "TimesNewRoman",
        normal="TimesNewRoman",
        bold="TimesNewRoman-Bold",
        italic="TimesNewRoman-Italic",
        boldItalic="TimesNewRoman-BoldItalic",
    )


def inline_markup(text):
    # Translate the small Markdown subset used in chapters to safe ReportLab markup.
    parts = []
    cursor = 0
    for match in INLINE_PATTERN.finditer(text):
        if match.start() > cursor:
            parts.append(escape(text[cursor:match.start()]))
        token = match.group(0)
        if token.startswith("**"):
            parts.append(f"<b>{escape(token[2:-2])}</b>")
        elif token.startswith("*"):
            parts.append(f"<i>{escape(token[1:-1])}</i>")
        elif token.startswith("`"):
            parts.append(f'<font name="Courier" size="9">{escape(token[1:-1])}</font>')
        else:
            label, url = re.fullmatch(r"\[([^\]]+)\]\(([^)]+)\)", token).groups()
            parts.append(f'<link href="{escape(url, quote=True)}" color="#1F5D8F"><u>{escape(label)}</u></link>')
        cursor = match.end()
    if cursor < len(text):
        parts.append(escape(text[cursor:]))
    return "".join(parts)


def paragraph_style(name, **values):
    return ParagraphStyle(name, **values)


def make_styles():
    base = getSampleStyleSheet()
    return {
        "title": paragraph_style(
            "ChapterTitle", parent=base["Title"], fontName="TimesNewRoman-Bold", fontSize=18,
            leading=23, alignment=TA_CENTER, textColor=colors.black, spaceAfter=16,
            keepWithNext=True,
        ),
        "h1": paragraph_style(
            "ChapterHeading1", fontName="TimesNewRoman-Bold", fontSize=15, leading=19,
            alignment=TA_LEFT, textColor=colors.black, spaceBefore=15, spaceAfter=7,
            keepWithNext=True,
        ),
        "h2": paragraph_style(
            "ChapterHeading2", fontName="TimesNewRoman-Bold", fontSize=12.5, leading=16,
            alignment=TA_LEFT, textColor=colors.black, spaceBefore=10, spaceAfter=5,
            keepWithNext=True,
        ),
        "body": paragraph_style(
            "ChapterBody", fontName="TimesNewRoman", fontSize=12, leading=18,
            alignment=TA_JUSTIFY, firstLineIndent=0.28 * inch, spaceAfter=7,
            allowWidows=0, allowOrphans=0,
        ),
        "list": paragraph_style(
            "ChapterList", fontName="TimesNewRoman", fontSize=11.5, leading=15.5,
            alignment=TA_LEFT, leftIndent=22, firstLineIndent=-15, spaceAfter=4,
            allowWidows=0, allowOrphans=0,
        ),
        "caption": paragraph_style(
            "FigureCaption", fontName="TimesNewRoman-Italic", fontSize=10.5, leading=13,
            alignment=TA_CENTER, spaceBefore=2, spaceAfter=11,
            allowWidows=0, allowOrphans=0,
        ),
        "table": paragraph_style(
            "ChapterTable", fontName="TimesNewRoman", fontSize=9.2, leading=11.2,
            alignment=TA_LEFT, spaceAfter=1, allowWidows=0, allowOrphans=0,
        ),
        "table_head": paragraph_style(
            "ChapterTableHead", fontName="TimesNewRoman-Bold", fontSize=9.2, leading=11.2,
            alignment=TA_LEFT, spaceAfter=1,
        ),
        "code": paragraph_style(
            "ChapterCode", fontName="Courier", fontSize=9, leading=11,
            alignment=TA_LEFT, leftIndent=0.2 * inch, spaceAfter=3,
        ),
    }


def table_row(line):
    return [cell.strip() for cell in line.strip().strip("|").split("|")]


def make_table(rows, styles):
    column_count = len(rows[0])
    weights = []
    for column in range(column_count):
        longest = min(max(len(row[column]) for row in rows), 60)
        weights.append(max(longest, 8))
    total = sum(weights)
    column_widths = [CONTENT_WIDTH * weight / total for weight in weights]
    floor = CONTENT_WIDTH * (0.13 if column_count > 2 else 0.19)
    column_widths = [max(value, floor) for value in column_widths]
    scale = CONTENT_WIDTH / sum(column_widths)
    column_widths = [value * scale for value in column_widths]
    data = []
    for row_index, row in enumerate(rows):
        style = styles["table_head"] if row_index == 0 else styles["table"]
        data.append([Paragraph(inline_markup(cell), style) for cell in row])
    table = LongTable(data, colWidths=column_widths, repeatRows=1, hAlign="CENTER")
    table.setStyle(TableStyle([
        ("GRID", (0, 0), (-1, -1), 0.45, colors.HexColor("#D9E0E7")),
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#EAF1F7")),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
    ]))
    return table


def image_flowable(path, max_width=CONTENT_WIDTH, max_height=6.5 * inch):
    image = Image(str(path))
    image.hAlign = "CENTER"
    image._restrictSize(max_width, max_height)
    return image


def build_pdf(markdown_path):
    source = markdown_path.read_text(encoding="utf-8-sig").splitlines()
    title = next((line[2:].strip() for line in source if line.startswith("# ")), markdown_path.stem)
    target = OUTPUT / f"Commencys_{markdown_path.stem}.pdf"
    document = BaseDocTemplate(
        str(target), pagesize=A4, rightMargin=0.875 * inch, leftMargin=0.875 * inch,
        topMargin=0.78 * inch, bottomMargin=0.78 * inch,
        title=title, author="Commencys project team", subject="Naskah proyek Commencys",
    )
    portrait_frame = Frame(
        0.875 * inch, 0.78 * inch, CONTENT_WIDTH, A4[1] - 1.56 * inch,
        id="portrait", leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0,
    )
    landscape_frame = Frame(
        0.7 * inch, 0.65 * inch, LANDSCAPE_CONTENT_WIDTH, LANDSCAPE_PAGE[1] - 1.3 * inch,
        id="landscape", leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0,
    )
    document.addPageTemplates([
        PageTemplate(id="portrait", pagesize=A4, frames=[portrait_frame]),
        PageTemplate(id="landscape", pagesize=LANDSCAPE_PAGE, frames=[landscape_frame]),
    ])
    styles = make_styles()
    story = []
    index = 0
    in_fence = False
    while index < len(source):
        line = source[index].strip()
        if not line:
            index += 1
            continue
        if line.startswith("~~~") or line.startswith("```"):
            in_fence = not in_fence
            index += 1
            continue
        if in_fence:
            story.append(Paragraph(escape(line), styles["code"]))
            index += 1
            continue
        image_match = IMAGE_PATTERN.fullmatch(line)
        if image_match:
            _, image_reference = image_match.groups()
            image_path = (markdown_path.parent / image_reference).resolve()
            if not image_path.is_file():
                raise FileNotFoundError(f"Image not found for {markdown_path.name}: {image_path}")
            is_diagram = "DIAGRAMS" in image_reference or "UML_PICTURE" in image_reference
            if is_diagram:
                story.extend([NextPageTemplate("landscape"), PageBreak()])
            figure = [image_flowable(
                image_path,
                LANDSCAPE_CONTENT_WIDTH if is_diagram else CONTENT_WIDTH,
                6.0 * inch if is_diagram else 6.5 * inch,
            )]
            caption_index = index + 1
            while caption_index < len(source) and not source[caption_index].strip():
                caption_index += 1
            if caption_index < len(source):
                next_line = source[caption_index].strip()
                if next_line.startswith("*") and next_line.endswith("*"):
                    figure.append(Paragraph(inline_markup(next_line), styles["caption"]))
                    index = caption_index
            story.append(KeepTogether(figure))
            if is_diagram:
                story.extend([NextPageTemplate("portrait"), PageBreak()])
            index += 1
            continue
        if line.startswith("|"):
            rows = []
            while index < len(source) and source[index].strip().startswith("|"):
                candidate = source[index].strip()
                if not re.fullmatch(r"\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?", candidate):
                    rows.append(table_row(candidate))
                index += 1
            if rows:
                story.extend([make_table(rows, styles), Spacer(1, 8)])
            continue
        if line.startswith("# "):
            story.append(Paragraph(inline_markup(line[2:].strip()), styles["title"]))
            index += 1
            continue
        if line.startswith("## "):
            story.append(Paragraph(inline_markup(line[3:].strip()), styles["h1"]))
            index += 1
            continue
        if line.startswith("### "):
            story.append(Paragraph(inline_markup(line[4:].strip()), styles["h2"]))
            index += 1
            continue
        ordered = re.match(r"^(\d+)\.\s+(.*)$", line)
        bullet = re.match(r"^[-*]\s+(.*)$", line)
        if ordered or bullet:
            marker = f"{ordered.group(1)}." if ordered else "-"
            content = ordered.group(2) if ordered else bullet.group(1)
            story.append(Paragraph(inline_markup(f"{marker} {content}"), styles["list"]))
            index += 1
            continue
        if line.startswith("*") and line.endswith("*"):
            story.append(Paragraph(inline_markup(line), styles["caption"]))
            index += 1
            continue
        story.append(Paragraph(inline_markup(line), styles["body"]))
        index += 1
    document.build(story)
    return target


if __name__ == "__main__":
    register_fonts()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for chapter in (1, 2, 3):
        target = build_pdf(RESULT / f"CHAPTER_{chapter}.md")
        print(target)
