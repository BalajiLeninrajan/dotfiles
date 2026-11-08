# Tamil Cell Mono

Noto Sans Tamil refit to the terminal grid, so Tamil in iamb fits its cells
in Ghostty. Each grapheme cluster fills exactly the columns Ghostty gives it.
That needs iamb from github.com/BalajiLeninrajan/iamb (the nightly RPM): stock iamb counts ா
and ௗ as zero columns, Ghostty counts them as one, and the mismatch erases
whole clusters (டி, து) further along the line.

Contextual rules keep two-part vowels inside their two columns: in ொ, ோ and
ௌ the consonant narrows and ா / ௗ draw over its right edge with no advance,
and before ி the consonant widens to 1.5 cells.

Rebuild from the Fedora variable font:

```sh
uv run --no-project --with fonttools python -I - <<'PY'
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer
f = instancer.instantiateVariableFont(TTFont('/usr/share/fonts/google-noto-vf/NotoSansTamil[wght].ttf'), {'wght': 400})
f.save('noto-tamil-400.ttf')
PY
uv run --no-project --with fonttools python -I build_font.py noto-tamil-400.ttf \
  ../../dot_local/share/fonts/TamilCellMono/TamilCellMono-Regular.ttf
```

`preview.py ORIGINAL NEW OUT.png` renders both fonts on the grid the way iamb
and Ghostty lay them out (needs uharfbuzz, freetype-py, pillow, regex).
