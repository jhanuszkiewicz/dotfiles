# dokleja brakujace znaki (np. polskie) z Inconsolata Medium do Tamzena
# - tak jak fallback "font-family = Tamzen / Inconsolata Medium" w ghostty
import sys
from fontTools.ttLib import TTFont
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.recordingPen import DecomposingRecordingPen
from fontTools.pens.boundsPen import BoundsPen

tamzen_path, out_path = sys.argv[1], sys.argv[2]
src_paths = sys.argv[3:]

tam = TTFont(tamzen_path)
tcmap = tam.getBestCmap()
tgs = tam.getGlyphSet()

def bounds(gs, name):
    p = BoundsPen(gs)
    gs[name].draw(p)
    return p.bounds

adv = tam['hmtx'][tcmap[ord('x')]][0]
tx = bounds(tgs, tcmap[ord('x')])[3]          # wysokosc x w tamzenie

# skala liczona z pierwszego pliku (latin ma 'x', latin-ext juz nie)
pierwszy = TTFont(src_paths[0])
pgs = pierwszy.getGlyphSet()
pcmap = pierwszy.getBestCmap()
sx = bounds(pgs, pcmap[ord('x')])[3]
skala = tx / sx                                # dopasowanie po wysokosci x
sadv = pierwszy['hmtx'][pcmap[ord('x')]][0] * skala
przes = (adv - sadv) / 2                       # wysrodkowanie w komorce

added = 0
for sp in src_paths:
    src = TTFont(sp)
    sgs = src.getGlyphSet()
    scmap = src.getBestCmap()

    for cp, gname in sorted(scmap.items()):
        if cp < 0x20 or cp > 0xFFFF or cp in tcmap:
            continue
        rec = DecomposingRecordingPen(sgs)
        sgs[gname].draw(rec)
        pen = TTGlyphPen(None)
        rec.replay(TransformPen(pen, (skala, 0, 0, skala, przes, 0)))
        g = pen.glyph()
        nowa = 'inc_%04X' % cp
        tam['glyf'][nowa] = g
        g.recalcBounds(tam['glyf'])
        lsb = g.xMin if hasattr(g, 'xMin') and g.numberOfContours else 0
        tam['hmtx'][nowa] = (adv, lsb)
        for t in tam['cmap'].tables:
            if t.isUnicode():
                t.cmap[cp] = nowa
        tcmap[cp] = nowa
        added += 1

order = list(tam['glyf'].glyphOrder)
tam.setGlyphOrder(order)
tam['maxp'].numGlyphs = len(order)
if tam['post'].formatType == 2.0:
    tam['post'].extraNames = []
    tam['post'].mapping = {}
tam.save(out_path)
print(out_path, 'dodano', added, 'znakow')
