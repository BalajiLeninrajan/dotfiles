"""Build "Tamil Cell Mono": Noto Sans Tamil refit so every cluster fills exactly
the terminal cells Ghostty gives it, which the iamb fork at
github.com/BalajiLeninrajan/iamb matches (ா and ௗ count as one column there).

Ghostty anchors each grapheme cluster at its cell and places the cluster's
glyphs by their advances, so advances only have to add up per cluster:
  consonant + ி        2 cells   consonant.i (1200 - I_W) + ி (I_W)
  consonant + ொ/ோ/ௌ   2 cells   ெ/ே (600) + consonant.aa (600) + ா/ௗ.zero (0, drawn leftward)
  everything else                CELL x cells, ink stretched or squeezed to fill
"""
import sys
from fontTools.ttLib import TTFont
from fontTools.ttLib.tables import otTables as ot
from fontTools.pens.recordingPen import DecomposingRecordingPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.pens.boundsPen import BoundsPen
from fontTools.otlLib.builder import buildCoverage

SRC, OUT = sys.argv[1], sys.argv[2]
CELL = 600          # JetBrains Mono advance at UPM 1000
SB = 10             # side bearing kept at each edge of a glyph's box
VS = 1.15           # vertical scale: Tamil body from x-height up toward cap height
MAX_STRETCH = 1.6   # widest a narrow glyph gets stretched
AA_W = 240          # share of the consonant's cell ா / ௗ take inside ொ, ோ, ௌ
I_W = 300           # share of its cell ி keeps; the consonant takes the rest
ATT_S, ATT_DX = 0.8, 40   # ு, ூ when they don't form a ligature (rare)

# Zero-column Tamil code points, the same in Ghostty and the iamb fork.
ZERO = {0x0B82, 0x0BC0, 0x0BCD}

f = TTFont(SRC)
gs = f.getGlyphSet()
cmap = f.getBestCmap()
hmtx = f['hmtx'].metrics
gdef = f['GDEF'].table.GlyphClassDef.classDefs
gsub = f['GSUB'].table

# 1. cells per glyph: cmap, then closure over single and ligature substitutions
cells = {g: (0 if cp in ZERO else 1) for cp, g in cmap.items() if 0x0B80 <= cp <= 0x0BFF}
singles_from = {}
changed = True
while changed:
    changed = False
    for lk in gsub.LookupList.Lookup:
        for st in lk.SubTable:
            if lk.LookupType == 1:
                for a, b in st.mapping.items():
                    singles_from.setdefault(a, set()).add(b)
                    if a in cells and cells.get(b, -1) < cells[a]:
                        cells[b] = cells[a]; changed = True
            elif lk.LookupType == 4:
                for first, ligs in st.ligatures.items():
                    for lig in ligs:
                        comps = [first] + list(lig.Component)
                        if all(c in cells for c in comps):
                            n = sum(cells[c] for c in comps)
                            if cells.get(lig.LigGlyph, -1) < n:
                                cells[lig.LigGlyph] = n; changed = True

aa_glyphs = {cmap[0x0BBE], cmap[0x0BD7]}
ee_glyphs = {cmap[0x0BC6], cmap[0x0BC7]}
prebase = ee_glyphs | {cmap[0x0BC8]}
i_glyphs = {cmap[0x0BBF]} | singles_from.get(cmap[0x0BBF], set())

def bounds(g):
    p = BoundsPen(gs); gs[g].draw(p); return p.bounds

def outline(g, sx, dx):
    rec = DecomposingRecordingPen(gs); gs[g].draw(rec)
    pen = TTGlyphPen(None); rec.replay(TransformPen(pen, (sx, 0, 0, VS, dx, 0)))
    return pen.glyph()

def fill(g, x0, x1):
    """Map g's ink onto [x0, x1]: squeeze, or stretch up to MAX_STRETCH and centre."""
    lo, _, hi, _ = bounds(g)
    s = min((x1 - x0) / (hi - lo), MAX_STRETCH)
    return s, x0 + ((x1 - x0) - (hi - lo) * s) / 2 - lo * s

new_glyf, new_hmtx, xform = {}, {}, {}
order = list(f.getGlyphOrder())

def put(g, sx, dx, adv, name=None):
    name = name or g
    new_glyf[name] = outline(g, sx, dx)
    new_hmtx[name] = adv
    xform[name] = (sx, dx)

for g, n in cells.items():
    adv = hmtx[g][0]
    b = bounds(g)
    if g in aa_glyphs:                    # own cell; a .zero copy serves ொ, ோ, ௌ
        s, dx = fill(g, -AA_W + SB, -SB)
        put(g, s, dx, 0, g + '.zero')
        order.append(g + '.zero'); gdef[g + '.zero'] = 3
        s, dx = fill(g, SB, CELL - SB)
        put(g, s, dx, CELL)
    elif g in i_glyphs:                   # stem fills I_W, hook reaches back over the consonant
        put(g, 1.0, I_W - SB - b[2], I_W)
    elif n == 0:
        if adv == 0:
            put(g, 1.0, 0, 0)             # true mark: only scale it vertically
        else:
            put(g, 1.0, -adv, 0)          # anusvara: a mark over the previous cell
    elif b[0] < 0 and gdef.get(g) == 3:
        put(g, ATT_S, ATT_DX, CELL * n)   # ு / ூ hooking onto a consonant
    else:
        s, dx = fill(g, SB, CELL * n - SB)
        put(g, s, dx, CELL * n)

# 2. contextual variants of the consonant (or ligature) before ா and ி
bases = sorted(g for g, n in cells.items()
               if n >= 1 and g not in aa_glyphs | prebase | i_glyphs
               and gdef.get(g) != 3 and hmtx[g][0] > 0)
to_aa, to_i = {}, {}
for g in bases:
    A = CELL * cells[g]
    s, dx = fill(g, SB, A - AA_W)
    put(g, s, dx, A, g + '.aa')   # ா has no advance, so the base keeps the full cell
    s, dx = fill(g, SB, A + CELL - I_W - SB)
    put(g, s, dx, A + CELL - I_W, g + '.i')
    to_aa[g], to_i[g] = g + '.aa', g + '.i'
    order += [g + '.aa', g + '.i']
    gdef[g + '.aa'] = gdef[g + '.i'] = 1

f.setGlyphOrder(order)
f['glyf'].glyphOrder = order
for g, gl in new_glyf.items():
    f['glyf'][g] = gl
for g, A in new_hmtx.items():
    gl = f['glyf'][g]; gl.recalcBounds(f['glyf'])
    hmtx[g] = (A, getattr(gl, 'xMin', 0))
f['post'].formatType = 2.0
f['post'].extraNames = []
f['post'].mapping = {}

# 3. GSUB: [ெ ே] base' [ா ௗ] -> base.aa ; [ெ ே] base [ா ௗ]' -> .zero ; base' ி -> base.i
glyph_map = f.getReverseGlyphMap(rebuild=True)
lookups = gsub.LookupList.Lookup

def single_lookup(mapping):
    st = ot.SingleSubst(); st.mapping = mapping; st.Format = 2
    lk = ot.Lookup(); lk.LookupType = 1; lk.LookupFlag = 0
    lk.SubTable = [st]; lk.SubTableCount = 1
    lookups.append(lk)
    return len(lookups) - 1

def chain(lookahead, target, inputs=None, backtrack=()):
    st = ot.ChainContextSubst(); st.Format = 3
    st.BacktrackGlyphCount = len(backtrack)
    st.BacktrackCoverage = [buildCoverage(sorted(s), glyph_map) for s in backtrack]
    st.InputGlyphCount = 1; st.InputCoverage = [buildCoverage(sorted(inputs or bases), glyph_map)]
    st.LookAheadGlyphCount = len(lookahead)
    st.LookAheadCoverage = [buildCoverage(sorted(s), glyph_map) for s in lookahead]
    rec = ot.SubstLookupRecord(); rec.SequenceIndex = 0; rec.LookupListIndex = target
    st.SubstCount = 1; st.SubstLookupRecord = [rec]
    return st

idx_aa, idx_i = single_lookup(to_aa), single_lookup(to_i)
idx_zero = single_lookup({g: g + '.zero' for g in aa_glyphs})
lk = ot.Lookup(); lk.LookupType = 6; lk.LookupFlag = 0
# HarfBuzz has already moved ெ / ே in front of the consonant when psts runs,
# so ொ arrives as ெ base ா. Backtrack coverage lists the nearest glyph first.
lk.SubTable = [chain([aa_glyphs], idx_aa, backtrack=[ee_glyphs]),
               chain([], idx_zero, inputs=aa_glyphs,
                     backtrack=[set(bases) | set(to_aa.values()), ee_glyphs]),
               chain([i_glyphs], idx_i)]
lk.SubTableCount = len(lk.SubTable)
lookups.append(lk)
idx_chain = len(lookups) - 1
gsub.LookupList.LookupCount = len(lookups)
for fr in gsub.FeatureList.FeatureRecord:
    if fr.FeatureTag == 'psts':
        fr.Feature.LookupListIndex.append(idx_chain)
        fr.Feature.LookupCount = len(fr.Feature.LookupListIndex)

# 4. GPOS: move anchors with their glyphs, drop kerning that breaks the grid
gpos = f['GPOS'].table
def move(a, g):
    if a is None: return
    s, dx = xform.get(g, (1.0, 0))
    a.XCoordinate = round(a.XCoordinate * s + dx)
    a.YCoordinate = round(a.YCoordinate * VS)
def zero(v):
    if v is None: return
    for attr in ('XAdvance', 'XPlacement'):
        if hasattr(v, attr): setattr(v, attr, 0)
    if hasattr(v, 'YPlacement'): v.YPlacement = round(v.YPlacement * VS)
for lk in gpos.LookupList.Lookup:
    for st in lk.SubTable:
        if lk.LookupType == 4:
            for g, rec in zip(st.BaseCoverage.glyphs, st.BaseArray.BaseRecord):
                for a in rec.BaseAnchor: move(a, g)
            for g, rec in zip(st.MarkCoverage.glyphs, st.MarkArray.MarkRecord):
                move(rec.MarkAnchor, g)
        elif lk.LookupType == 2:
            if st.Format == 1:
                for ps in st.PairSet:
                    for r in ps.PairValueRecord: zero(getattr(r, 'Value1', None)); zero(getattr(r, 'Value2', None))
            else:
                for c1 in st.Class1Record:
                    for c2 in c1.Class2Record: zero(getattr(c2, 'Value1', None)); zero(getattr(c2, 'Value2', None))
        elif lk.LookupType == 1:
            if st.Format == 1: zero(st.Value)
            else:
                for v in st.Value: zero(v)

# 5. names
fam, ps = 'Tamil Cell Mono', 'TamilCellMono-Regular'
name = f['name']
for nid in (16, 17, 21, 22, 25):
    name.removeNames(nameID=nid)
for nid, val in ((1, fam), (2, 'Regular'), (3, f'{ps};grid refit of Noto Sans Tamil'), (4, f'{fam} Regular'), (6, ps)):
    name.setName(val, nid, 3, 1, 0x409); name.setName(val, nid, 1, 0, 0)
for t in ('STAT', 'MVAR', 'HVAR', 'fvar', 'gvar', 'avar', 'DSIG'):
    if t in f: del f[t]
f.save(OUT)
print(f'{len(cells)} Tamil glyphs refit, {len(bases)} bases with .aa/.i variants, saved {OUT}')
