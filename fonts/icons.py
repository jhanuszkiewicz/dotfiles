# puts pixel icons into a tamzen font
#
#   python3 icons.py Tamzen10x20-Bold.ttf [out.ttf]
#
# the icons come from icons-WxH.txt for that font size:
#   icons-10x20.txt  sketchybar
#   icons-8x16.txt   eza in ghostty
# no out = overwrite the input file
# running it again just replaces the icons, so after editing a txt run it again
import sys
import os
import re
from fontTools.ttLib import TTFont
from fontTools.pens.ttGlyphPen import TTGlyphPen

src = sys.argv[1]
out = sys.argv[2] if len(sys.argv) > 2 else src

font = TTFont(src)
cmap = font.getBestCmap()

size = re.search(r"(\d+)x(\d+)", font['name'].getDebugName(1)).group(0)
w = int(size.split("x")[0])
txt = os.path.join(os.path.dirname(os.path.abspath(__file__)), "icons-" + size + ".txt")
if not os.path.exists(txt):
    print("no", txt)
    sys.exit(1)

P = font['hmtx'][cmap[ord('a')]][0] // w        # one pixel in font units
rows_up = font['hhea'].ascent // P              # rows above the baseline
rows_down = -font['hhea'].descent // P          # rows below

# read the txt -> list of (name, [codepoints], rows)
icons = []
center = False
for line in open(txt):
    line = line.strip()
    if line == "" or line == "#" or line.startswith("# "):
        continue
    if line == "@ center":
        center = True
    elif line.startswith("="):
        parts = line.split()
        cps = []
        for p in parts[2:]:
            cps.append(int(p, 16))
        icons.append((parts[1], cps, []))
    else:
        icons[-1][2].append(line)

# codepoints above FFFF (lots of nerd icons) need a format 12 cmap table,
# tamzen only has format 4 ones
big = False
for name, cps, rows in icons:
    for cp in cps:
        if cp > 0xFFFF:
            big = True
has12 = False
for t in font['cmap'].tables:
    if t.format == 12:
        has12 = True
if big and not has12:
    from fontTools.ttLib.tables._c_m_a_p import CmapSubtable
    t12 = CmapSubtable.newSubtable(12)
    t12.platformID = 3
    t12.platEncID = 10
    t12.language = 0
    t12.cmap = dict(cmap)
    font['cmap'].tables.append(t12)

order = font.getGlyphOrder()
for name, cps, rows in icons:
    h = len(rows)
    if center:
        # middle of the whole line (ghostty centers icons too)
        bottom = -rows_down + (rows_up + rows_down - h) // 2
    else:
        # last row on the baseline
        bottom = 0
    if bottom + h > rows_up or bottom < -rows_down:
        print(name, "doesn't fit:", h, "rows")
        sys.exit(1)

    # every row: runs of # -> one rectangle each
    pen = TTGlyphPen(None)
    width = 0
    for i in range(h):
        row = rows[i]
        if len(row) > width:
            width = len(row)
        r = bottom + (h - 1 - i)
        c = 0
        while c < len(row):
            if row[c] == "#":
                c0 = c
                while c < len(row) and row[c] == "#":
                    c += 1
                pen.moveTo((c0 * P, r * P))
                pen.lineTo((c0 * P, (r + 1) * P))
                pen.lineTo((c * P, (r + 1) * P))
                pen.lineTo((c * P, r * P))
                pen.closePath()
            else:
                c += 1

    g = pen.glyph()
    # already in the font (icons.py ran before) -> replace that glyph
    gname = cmap.get(cps[0], "icon_" + name.replace("-", "_"))
    font['glyf'][gname] = g
    g.recalcBounds(font['glyf'])
    font['hmtx'][gname] = (width * P, g.xMin)
    if gname not in order:
        order.append(gname)

    for t in font['cmap'].tables:
        if t.isUnicode():
            for cp in cps:
                if cp <= 0xFFFF or t.format in (12, 13):
                    t.cmap[cp] = gname

font.setGlyphOrder(order)
font['maxp'].numGlyphs = len(order)
# post format 2 keeps its own name list, easier to drop it
if font['post'].formatType == 2.0:
    font['post'].formatType = 3.0
font.save(out)
print(out, "-", len(icons), "icons from", os.path.basename(txt))
