# builds polish letters out of tamzen's own pixels
# (instead of the scaled inconsolata ones that merge.py glues in)
#
#   python3 polish.py Tamzen8x16-Bold.ttf [out.ttf] [-v]
#
# no out = overwrite the input file, -v = print the new letters
# acute: taken from Ó/ó, dot: from i, ogonek and Ł stroke: drawn by hand
import sys
import re
from fontTools.ttLib import TTFont
from fontTools.pens.pointInsidePen import PointInsidePen
from fontTools.pens.ttGlyphPen import TTGlyphPen

args = [a for a in sys.argv[1:] if a != '-v']
src = args[0]
out = args[1] if len(args) > 1 else src
bold = "Bold" in src

font = TTFont(src)
cmap = font.getBestCmap()
gs = font.getGlyphSet()

w = int(re.search(r"(\d+)x(\d+)", font['name'].getDebugName(1)).group(1))
adv = font['hmtx'][cmap[ord('a')]][0]
P = adv // w                      # size of one "pixel" in font units
top = font['hhea'].ascent // P
bottom = font['hhea'].descent // P


def raster(ch):
    g = gs[cmap[ord(ch)]]
    px = set()
    for r in range(bottom, top):
        for c in range(w):
            pen = PointInsidePen(gs, (c * P + P // 2, r * P + P // 2))
            g.draw(pen)
            if pen.getResult():
                px.add((c, r))
    return px


def top_row(px):
    m = -100
    for c, r in px:
        if r > m:
            m = r
    return m


def center(px):
    cols = [c for c, r in px]
    return (min(cols) + max(cols)) / 2


def shift(px, dx, dy=0):
    res = set()
    for c, r in px:
        res.add((c + dx, r + dy))
    return res


# bold tamzen = regular stroke smeared 1px to the right
def smear(px):
    if not bold:
        return px
    return px | shift(px, 1)


# accent = everything in the accented glyph above the top of its base letter
def accent(accented, base):
    t = top_row(raster(base))
    acc = set()
    for c, r in raster(accented):
        if r > t:
            acc.add((c, r))
    return acc


def with_acute(ch, acc, ref):
    base = raster(ch)
    dx = round(center(base) - center(ref))
    return base | shift(acc, dx)


def with_dot(ch, dot_bottom):
    base = raster(ch)
    dx = round(center(base) - center(dot))
    dy = dot_bottom - min(r for c, r in dot)
    return base | shift(dot, dx, dy)


def with_ogonek(ch):
    base = raster(ch)
    R = max(c for c, r in base if r == 0)
    if bold:
        R -= 1
    if bottom <= -6:
        og = {(R, -1), (R - 1, -2), (R - 1, -3), (R, -4), (R + 1, -4)}
    else:
        og = {(R, -1), (R - 1, -2), (R, -3), (R + 1, -3)}
    return base | smear(og)


def with_stroke(ch):
    base = raster(ch)
    # stem = leftmost column that is at least half as tall as the tallest one
    count = {}
    for c, r in base:
        count[c] = count.get(c, 0) + 1
    big = max(count.values())
    s = -1
    for c in sorted(count):
        if s == -1 and count[c] * 2 >= big:
            s = c
    m = (top_row(base) + 1) // 2
    if bold:
        # 2px stem would hide the middle of the slash, so skip over it
        st = {(s - 1, m - 1), (s + 1, m), (s + 2, m + 1)}
    else:
        st = {(s - 1, m - 1), (s + 1, m + 1), (s + 2, m + 2)}
    return base | smear(st)


def to_glyph(px):
    pen = TTGlyphPen(None)
    for r in range(bottom, top):
        c = 0
        while c < w:
            if (c, r) in px:
                c0 = c
                while (c, r) in px:
                    c += 1
                x0, x1 = c0 * P, c * P
                y0, y1 = r * P, (r + 1) * P
                pen.moveTo((x0, y0))
                pen.lineTo((x0, y1))
                pen.lineTo((x1, y1))
                pen.lineTo((x1, y0))
                pen.closePath()
            else:
                c += 1
    return pen.glyph()


up_acc = accent('Ó', 'O')
low_acc = accent('ó', 'o')
up_ref = raster('Ó') - up_acc
low_ref = raster('ó') - low_acc
# dot = the part of i above the x-height
xh = top_row(raster('x'))
dot = set(p for p in raster('i') if p[1] > xh)

new = {}
for ch, base in [('Ś', 'S'), ('Ć', 'C'), ('Ń', 'N'), ('Ź', 'Z')]:
    new[ch] = with_acute(base, up_acc, up_ref)
for ch, base in [('ś', 's'), ('ć', 'c'), ('ń', 'n'), ('ź', 'z')]:
    new[ch] = with_acute(base, low_acc, low_ref)
new['Ż'] = with_dot('Z', min(r for c, r in up_acc))
new['ż'] = with_dot('z', min(r for c, r in dot))
for ch, base in [('Ą', 'A'), ('Ę', 'E'), ('ą', 'a'), ('ę', 'e')]:
    new[ch] = with_ogonek(base)
new['Ł'] = with_stroke('L')
new['ł'] = with_stroke('l')

for ch in new:
    px = set(p for p in new[ch] if 0 <= p[0] < w and bottom <= p[1] < top)
    name = cmap[ord(ch)]
    g = to_glyph(px)
    font['glyf'][name] = g
    g.recalcBounds(font['glyf'])
    font['hmtx'][name] = (adv, g.xMin)

    if '-v' in sys.argv:
        print(ch)
        for r in range(top - 1, bottom - 1, -1):
            print("".join("#" if (c, r) in px else "." for c in range(w)))

font.save(out)
print(out, "-", len(new), "letters rebuilt")
