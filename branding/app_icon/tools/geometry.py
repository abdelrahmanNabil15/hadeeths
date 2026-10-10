"""Geometry of the Sakina app icon, in a 1024 x 1024 art space.

The icon is flat vector art made of only two shapes:
  * the eight-pointed star (rub el hizb): two squares, one turned 45 degrees, drawn as one 16-vertex
    outline in gold;
  * an open book: two mirrored pages with a narrow gap at the spine, in ivory.
"""
import math

CX = CY = 512.0

EMERALD = '#0B3F33'   # midnight emerald: the background
DEEP = '#0F2E26'      # deep emerald (reserved for a dark-mode variant)
IVORY = '#FAF6EC'     # warm ivory: the book
GOLD = '#D6B568'      # muted gold: the star
INK = '#0D1311'       # near-black: the themed (monochrome) layer
WHITE = '#FFFFFF'     # the notification silhouette

STAR_RADIUS = 290     # tip radius; with the stroke below, the miter points stay inside the 61% safe circle
STAR_STROKE = 26
BOOK_SCALE = 1.12
FULL_BLEED_SCALE = 1.2  # on a full-bleed square (iOS, Play, legacy Android) the symbol is drawn larger
SAFE_RADIUS = 1024 * 0.61 / 2


def star_points(radius=STAR_RADIUS):
    """Tips at [radius] every 45 degrees; inner corners where the two squares cross."""
    inner = radius / math.sqrt(2) / math.cos(math.radians(22.5))
    pts = []
    for k in range(8):
        tip = math.radians(-90 + 45 * k)
        pts.append((CX + radius * math.cos(tip), CY + radius * math.sin(tip)))
        gap = math.radians(-90 + 45 * k + 22.5)
        pts.append((CX + inner * math.cos(gap), CY + inner * math.sin(gap)))
    return pts


def star_path(radius=STAR_RADIUS):
    return 'M' + ' L'.join('%.1f %.1f' % p for p in star_points(radius)) + ' Z'


def book_paths(scale=BOOK_SCALE, dy=-14.0):
    """The two pages (left, right) as closed paths, mirrored about the vertical axis."""
    half_gap, outer = 9.0, 130.0
    top_spine, top_outer, top_ctrl = 474 + dy, 458 + dy, 440 + dy
    bot_spine, bot_outer, bot_ctrl = 602 + dy, 586 + dy, 568 + dy

    def at(x, y):
        return CX + (x - CX) * scale, CY + (y - CY) * scale

    def page(sign):
        spine = CX + sign * half_gap
        edge = CX + sign * (half_gap + outer)
        mid = CX + sign * (half_gap + outer / 2)
        pts = (at(spine, top_spine) + at(mid, top_ctrl) + at(edge, top_outer) + at(edge, bot_outer)
               + at(mid, bot_ctrl) + at(spine, bot_spine))
        return 'M%.1f %.1f Q%.1f %.1f %.1f %.1f L%.1f %.1f Q%.1f %.1f %.1f %.1f Z' % pts

    return page(-1), page(1)
