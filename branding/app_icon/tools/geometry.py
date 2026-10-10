"""Geometry of the Sakina app icon, in a 1024 x 1024 art space.

The icon is flat vector art: an open Quran on a crossed stand (a rehal). It is made of
  * a stand: two crossed bars, drawn behind the book;
  * a cover: one shape with a dip at the spine;
  * two pages (ivory) inset in the cover, each with five lines of text strokes and a small
    eight-pointed gold star at its head (the star is the rub el hizb).
There is no lettering: the "text" is only soft strokes, not words or verses.
"""
import math

EMERALD = '#0B3F33'   # midnight emerald: the cover and stand
DEEP = '#0F2E26'      # deep emerald (reserved for a dark-mode variant)
IVORY = '#FAF6EC'     # warm ivory: the pages
GOLD = '#D6B568'      # muted gold: the background and the stars
INK = '#0D1311'       # near-black: the themed (monochrome) layer
WHITE = '#FFFFFF'     # the notification silhouette

# Where the artwork sits. The art is wider than tall, so each use scales it about a point chosen to
# centre it: ART_CY is its vertical middle; ADAPTIVE_CY is the centre of the smallest circle that
# contains it, which is what the Android circle mask needs.
ART_CY = 620.0
FULL_BLEED_SCALE = 1.12   # iOS, Play and legacy Android: a full square, the art fills about 72% of its width
ADAPTIVE_CY = 557.0
ADAPTIVE_SCALE = 0.77     # Android adaptive layer: the art stays inside the central 61% circle
NOTIFICATION_SCALE = 1.4
SAFE_RADIUS = 1024 * 0.61 / 2

STAND = 'M350 640 L674 900 M674 640 L350 900'
STAND_STROKE = 34
COVER = 'M512 358 Q360 312 186 334 L186 662 Q360 640 512 692 Q664 640 838 662 L838 334 Q664 312 512 358 Z'
PAGE_LEFT = 'M500 376 Q356 332 208 352 L208 636 Q356 616 500 660 Z'
PAGE_RIGHT = 'M524 376 Q668 332 816 352 L816 636 Q668 616 524 660 Z'
LINE_STROKE = 9
LINE_OPACITY = 0.55


def star_path(cx, cy, radius):
    """An eight-pointed star (two squares, one turned 45 degrees) as one 16-vertex outline."""
    inner = radius / math.sqrt(2) / math.cos(math.radians(22.5))
    pts = []
    for k in range(8):
        tip = math.radians(-90 + 45 * k)
        pts.append((cx + radius * math.cos(tip), cy + radius * math.sin(tip)))
        gap = math.radians(-90 + 45 * k + 22.5)
        pts.append((cx + inner * math.cos(gap), cy + inner * math.sin(gap)))
    return 'M' + ' L'.join('%.1f %.1f' % p for p in pts) + ' Z'


def text_lines():
    """Ten soft text strokes, five on each page, bowed like the pages."""
    lines = []
    for i in range(5):
        y = 446 + 38 * i
        lines.append('M256 %d Q354 %d 452 %d' % (y, y - 8, y + 14))
        lines.append('M%d %d Q%d %d %d %d' % (1024 - 256, y, 1024 - 354, y - 8, 1024 - 452, y + 14))
    return lines


STAR_LEFT = star_path(354, 398, 24)
STAR_RIGHT = star_path(670, 398, 24)
