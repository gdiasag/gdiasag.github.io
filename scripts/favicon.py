"""
Draws the favicon as SVG using the site's font and a theme's colors.

Usage:
    favicon.py <font.woff2> <_colorschemes.scss> <theme> <text> > favicon.svg
"""

import re
import sys

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

font_file, colorschemes, theme, text = sys.argv[1:]

font = TTFont(font_file)
glyphs = font.getGlyphSet()
cmap = font.getBestCmap()
missing = [ch for ch in text if ord(ch) not in cmap]
if missing:
    sys.exit(f"{font_file} has no glyph for {' '.join(missing)}")

# The text's outlines side by side, y pointing down as in SVG.
path = SVGPathPen(glyphs)
bounds = BoundsPen(glyphs)
x = 0
for ch in text:
    glyph = glyphs[cmap[ord(ch)]]
    for pen in (path, bounds):
        glyph.draw(TransformPen(pen, (1, 0, 0, -1, x, 0)))
    x += glyph.width

# The theme's colors, from what _nvim/theme.lua wrote for it.
block = re.search(
    r'\[data-theme="%s"\] \{(.*?)\n\}' % re.escape(theme),
    open(colorschemes).read(),
    re.S,
)
if not block:
    sys.exit(f"no colors for {theme} in {colorschemes}")
color = lambda group: re.search(
    r"--%s: (#[0-9a-f]{6});" % group, block.group(1)
).group(1)

# Fit into 24 of the tile's 32 units, centered.
x0, y0, x1, y1 = bounds.bounds
scale = 24 / max(x1 - x0, y1 - y0)
dx = (32 - (x1 - x0) * scale) / 2 - x0 * scale
dy = (32 - (y1 - y0) * scale) / 2 - y0 * scale

print(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">'
    f'<rect class="bg" width="32" height="32" rx="7" fill="{color("Normal-bg")}"/>'
    f'<path class="fg" fill="{color("Normal-fg")}" transform="translate({dx:.2f} {dy:.2f}) scale({scale:.5f})"'
    f' d="{path.getCommands()}"/>'
    "</svg>"
)
