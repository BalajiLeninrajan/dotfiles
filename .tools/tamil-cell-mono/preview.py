"""Render Tamil text the way iamb + Ghostty lay it out: iamb reserves columns per
grapheme, Ghostty anchors each cluster at its cell and places the cluster's glyphs
by HarfBuzz advances from there."""
import os, sys, regex, uharfbuzz as hb, freetype
from PIL import Image, ImageDraw

ZERO = {0x0B82, 0x0BC0, 0x0BCD}   # ா ௗ count as 1 with the iamb fork
PX = 28                      # font size in px; one cell = 0.6 em
CELL = PX * 0.6
LINES = ["இனிய பிறந்தநாள் நல்வாழ்த்துக்கள் பாட்டி!", "அம்மா சாப்பிட்டியா?", "நான் வீட்டுக்கு வருகிறேன்", "கொஞ்சம் பொறு, ஒரு நிமிஷம்",
         "ணா ஔ கை கெ கோ கௌ கி கு கீ க்ஷ"]

def width(ch):
    cp = ord(ch)
    return 0 if cp in ZERO else 1

def layout(text):
    cols, col = [], 0         # column for each codepoint (its grapheme's start)
    for g in regex.findall(r'\X', text):
        for _ in g: cols.append(col)
        col += sum(width(c) for c in g)
    return cols, col

def render(path, draw, y, text):
    blob = hb.Blob.from_file_path(path); face = hb.Face(blob); font = hb.Font(face)
    font.scale = (1000, 1000)
    buf = hb.Buffer(); buf.add_str(text); buf.guess_segment_properties()
    hb.shape(font, buf, {})
    ft = freetype.Face(path); ft.set_pixel_sizes(0, PX)
    cols, total = layout(text)
    # map utf-32 codepoint index (hb cluster) -> column
    run_x, cell_start_x, cur = 0, 0, None
    for info, pos in zip(buf.glyph_infos, buf.glyph_positions):
        c = cols[info.cluster]
        if c != cur:
            cur, cell_start_x = c, run_x
        x = c * CELL + (run_x - cell_start_x + pos.x_offset) * PX / 1000
        ft.load_glyph(info.codepoint, freetype.FT_LOAD_RENDER)
        bm = ft.glyph.bitmap
        if bm.width:
            img = Image.frombytes('L', (bm.width, bm.rows), bytes(bm.buffer))
            ox = int(x + 10 + ft.glyph.bitmap_left); oy = int(y + PX - ft.glyph.bitmap_top - pos.y_offset * PX / 1000)
            draw._image.paste((205, 214, 244), (ox, oy), img)
        run_x += pos.x_advance
    return total

orig, new, out = sys.argv[1:4]
W = int(CELL * 34) + 20
H = (len(LINES) * 2) * (PX * 2) + 60
im = Image.new('RGB', (W, H), (30, 30, 46)); d = ImageDraw.Draw(im)
y = 10
for label, path in ((os.path.basename(orig), orig), (os.path.basename(new), new)):
    d.text((10, y), label, fill=(166, 173, 200)); y += 18
    for line in LINES:
        cols = layout(line)[1]
        for i in range(cols + 1):
            x = 10 + i * CELL; d.line([(x, y + 2), (x, y + PX * 1.6)], fill=(69, 71, 90))
        render(path, d, y, line); y += int(PX * 1.9)
    y += 12
im.save(out)
