"""Builds the Sakina app icon: the SVG sources, every PNG, and the Android and iOS resources.

From the project root:
  python branding/app_icon/tools/build.py spec      # writes the SVGs, XML, Contents.json and build/spec.json
  flutter test branding/app_icon/tools/render_icons_test.dart   # draws each job from the vectors
  python branding/app_icon/tools/build.py png       # writes the PNGs and validates them

The PNGs are drawn from the vector data at each exact size (never scaled from a bitmap).
"""
import json
import math
import os
import struct
import sys
import zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from geometry import (CX, CY, EMERALD, FULL_BLEED_SCALE, GOLD, INK, IVORY, SAFE_RADIUS, STAR_STROKE,  # noqa: E402
                      WHITE, book_paths, star_path)

SRC = 'branding/app_icon'
BUILD = SRC + '/build'
RES = 'android/app/src/main/res'
IOS = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
NOTIFICATION_SCALE = 1.5

DENSITIES = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0}

# iPhone and iPad sizes the project supports (deployment target 13), as in Flutter's template.
IOS_ICONS = [
    ('iphone', 20, 2), ('iphone', 20, 3), ('iphone', 29, 2), ('iphone', 29, 3), ('iphone', 40, 2),
    ('iphone', 40, 3), ('iphone', 60, 2), ('iphone', 60, 3), ('ipad', 20, 1), ('ipad', 20, 2),
    ('ipad', 29, 1), ('ipad', 29, 2), ('ipad', 40, 1), ('ipad', 40, 2), ('ipad', 76, 1), ('ipad', 76, 2),
    ('ipad', 83.5, 2), ('ios-marketing', 1024, 1),
]


def layer(d, fill=None, stroke=None, sw=0, evenodd=False, ident=None):
    out = {'d': d, 'fill': fill, 'stroke': stroke, 'sw': sw, 'id': ident}
    if evenodd:
        out['evenodd'] = True
    return out


def art(star=GOLD, book=IVORY):
    left, right = book_paths()
    return [layer(star_path(), stroke=star, sw=STAR_STROKE, ident='star'),
            layer(left, fill=book, ident='book-left'), layer(right, fill=book, ident='book-right')]


def silhouette():
    """The notification icon: a solid star with the open book cut out of it."""
    left, right = book_paths()
    return [layer(star_path() + ' ' + left + ' ' + right, fill=WHITE, evenodd=True, ident='star-with-book-cutout')]


# ------------------------------------------------------------------ svg


def path_element(ly):
    a = []
    if ly.get('id'):
        a.append('id="%s"' % ly['id'])
    a.append('d="%s"' % ly['d'])
    a.append('fill="%s"' % (ly['fill'] or 'none'))
    if ly['stroke']:
        a.append('stroke="%s" stroke-width="%g" stroke-linejoin="miter" stroke-miterlimit="10"' % (ly['stroke'], ly['sw']))
    if ly.get('evenodd'):
        a.append('fill-rule="evenodd"')
    return '<path %s/>' % ' '.join(a)


def svg(title, layers, scale=1.0, bg=None, bg_only=False):
    out = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">',
           '<title>%s</title>' % title]
    if bg:
        out.append('<g id="background"><rect width="1024" height="1024" fill="%s"/></g>' % bg)
    if layers:
        t = ' transform="translate(512 512) scale(%g) translate(-512 -512)"' % scale if scale != 1.0 else ''
        out.append('<g id="foreground"%s>' % t)
        out.extend(path_element(ly) for ly in layers)
        out.append('</g>')
    out.append('</svg>')
    return '\n'.join(out) + '\n'


def write(path, text):
    os.makedirs(os.path.dirname(path) or '.', exist_ok=True)
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)


# ------------------------------------------------------------------ jobs


def item(layers, size, scale=1.0, bg=None, x=0, y=0, clip=None):
    return {'x': x, 'y': y, 'size': size, 'scale': scale, 'bg': bg, 'clip': clip, 'layers': layers}


def job(name, px, items, mode, out, bg=None, w=None, h=None):
    return {'name': name, 'w': w or px, 'h': h or px, 'bg': bg, 'items': items, 'mode': mode, 'out': out}


def jobs():
    j = [
        job('foreground', 1024, [item(art(), 1024)], 'rgba', SRC + '/app_icon_foreground.png'),
        job('background', 1024, [], 'rgb', SRC + '/app_icon_background.png', bg=EMERALD),
        job('ios', 1024, [item(art(), 1024, FULL_BLEED_SCALE, bg=EMERALD)], 'rgb', SRC + '/app_icon_ios.png'),
        job('play', 512, [item(art(), 512, FULL_BLEED_SCALE, bg=EMERALD)], 'rgba_opaque',
            SRC + '/app_icon_play_store.png'),
        job('monochrome', 1024, [item(art(INK, INK), 1024)], 'rgba', SRC + '/app_icon_monochrome.png'),
        job('notification', 96, [item(silhouette(), 96, NOTIFICATION_SCALE)], 'rgba', SRC + '/notification_icon.png'),
    ]
    for d, f in DENSITIES.items():
        legacy, layer_px, small = round(48 * f), round(108 * f), round(24 * f)
        j += [
            job('legacy-' + d, legacy, [item(art(), legacy, FULL_BLEED_SCALE, bg=EMERALD)], 'rgb',
                '%s/mipmap-%s/ic_launcher.png' % (RES, d)),
            job('adaptive-fg-' + d, layer_px, [item(art(), layer_px)], 'rgba',
                '%s/mipmap-%s/ic_launcher_foreground.png' % (RES, d)),
            job('adaptive-mono-' + d, layer_px, [item(art(INK, INK), layer_px)], 'rgba',
                '%s/mipmap-%s/ic_launcher_monochrome.png' % (RES, d)),
            job('notification-' + d, small, [item(silhouette(), small, NOTIFICATION_SCALE)], 'rgba',
                '%s/drawable-%s/ic_notification.png' % (RES, d)),
        ]
    for idiom, size, scale in IOS_ICONS:
        px = round(size * scale)
        name = ios_name(idiom, size, scale)
        j.append(job('ios-' + name, px, [item(art(), px, FULL_BLEED_SCALE, bg=EMERALD)], 'rgb', '%s/%s' % (IOS, name)))
    # quality-assurance sheets (not shipped): actual sizes under circle and squircle masks, light and dark
    for dark in (False, True):
        plate = INK if dark else IVORY
        sizes, gap, margin = (48, 96, 192), 28, 32
        width = margin * 2 + sum(sizes) + gap * 2
        items = []
        for row, (clip, scale, layers) in enumerate((('rrect', FULL_BLEED_SCALE, art()), ('circle', 1.0, art()))):
            x = margin
            for s in sizes:
                items.append(item(layers, s, scale, bg=EMERALD, x=x, y=margin + row * (192 + margin) + (192 - s) // 2,
                                  clip=clip))
                x += s + gap
        n = 'dark' if dark else 'light'
        j.append(job('qa-' + n, width, items, 'rgb', BUILD + '/qa/icon-%s-actual-size.png' % n, bg=plate,
                     h=margin * 3 + 192 * 2))
    # the notification icon on a dark status bar, at 24 dp (1x, 2x, 4x) and enlarged for inspection
    items, x = [], 16
    for s in (24, 48, 96):
        items.append(item(silhouette(), s, NOTIFICATION_SCALE, x=x, y=16))
        x += s + 20
    j.append(job('qa-notification', 0, items, 'rgb', BUILD + '/qa/notification-on-dark.png', bg=INK, w=x, h=128))
    return j


def ios_name(idiom, size, scale):
    if idiom == 'ios-marketing':
        return 'Icon-App-1024x1024@1x.png'
    s = ('%g' % size)
    return 'Icon-App-%sx%s@%dx.png' % (s, s, scale)


def ios_contents():
    images = []
    for idiom, size, scale in IOS_ICONS:
        s = '%g' % size
        images.append({'size': '%sx%s' % (s, s), 'idiom': idiom, 'filename': ios_name(idiom, size, scale),
                       'scale': '%dx' % scale})
    return json.dumps({'images': images, 'info': {'version': 1, 'author': 'xcode'}}, indent=2) + '\n'


def spec():
    write(SRC + '/app_icon_master.svg', svg('Sakina app icon (master: background and foreground layers)', art(),
                                           scale=FULL_BLEED_SCALE, bg=EMERALD))
    write(SRC + '/app_icon_foreground.svg', svg('Sakina app icon: foreground (transparent)', art()))
    write(SRC + '/app_icon_monochrome.svg', svg('Sakina app icon: monochrome (themed icons)', art(INK, INK)))
    write(SRC + '/notification_icon.svg', svg('Sakina notification icon', silhouette(), scale=NOTIFICATION_SCALE))
    write(RES + '/mipmap-anydpi-v26/ic_launcher.xml',
          '<?xml version="1.0" encoding="utf-8"?>\n'
          '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
          '    <background android:drawable="@color/ic_launcher_background"/>\n'
          '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
          '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>\n'
          '</adaptive-icon>\n')
    write(RES + '/values/ic_launcher_background.xml',
          '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
          '    <color name="ic_launcher_background">%s</color>\n</resources>\n' % EMERALD)
    write(RES + '/raw/keep.xml',
          '<?xml version="1.0" encoding="utf-8"?>\n'
          '<!-- The notification icon is looked up by name at run time, so resource shrinking must keep it. -->\n'
          '<resources xmlns:tools="http://schemas.android.com/tools"\n'
          '    tools:keep="@drawable/ic_notification" />\n')
    write(IOS + '/Contents.json', ios_contents())
    os.makedirs(BUILD, exist_ok=True)
    all_jobs = jobs()
    json.dump({'jobs': all_jobs}, open(BUILD + '/spec.json', 'w'))
    print('spec: %d render jobs' % len(all_jobs))


# ------------------------------------------------------------------ png


def png_bytes(w, h, rows, ctype):
    def chunk(tag, data):
        body = tag + data
        return struct.pack('>I', len(data)) + body + struct.pack('>I', zlib.crc32(body) & 0xFFFFFFFF)

    raw = b''.join(b'\x00' + r for r in rows)
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, ctype, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b''))


def convert(px, w, h, mode):
    rows = []
    for y in range(h):
        row = px[y * w * 4:(y + 1) * w * 4]
        if mode == 'rgba':
            rows.append(bytes(row))
        elif mode == 'rgba_opaque':
            r = bytearray(row)
            r[3::4] = b'\xff' * w
            rows.append(bytes(r))
        else:  # rgb: no alpha channel at all
            out = bytearray(w * 3)
            out[0::3], out[1::3], out[2::3] = row[0::4], row[1::4], row[2::4]
            rows.append(bytes(out))
    return png_bytes(w, h, rows, {'rgba': 6, 'rgba_opaque': 6, 'rgb': 2}[mode])


def png():
    jobs_ = json.load(open(BUILD + '/spec.json'))['jobs']
    for j in jobs_:
        name, w, h = j['name'], j['w'], j['h']
        px = open('%s/raw/%s.rgba' % (BUILD, name), 'rb').read()
        assert len(px) == w * h * 4, name
        os.makedirs(os.path.dirname(j['out']), exist_ok=True)
        open(j['out'], 'wb').write(convert(px, w, h, j['mode']))
    print('wrote %d PNG files' % len(jobs_))


def validate():
    """Reads every shipped PNG back and checks size, colour mode, transparency, colours and the safe area."""
    jobs_ = [j for j in json.load(open(BUILD + '/spec.json'))['jobs'] if not j['name'].startswith('qa-')]
    failures, rows = [], []
    kinds = {0: 'grey', 2: 'RGB (no alpha)', 6: 'RGBA'}
    for j in jobs_:
        data = open(j['out'], 'rb').read()
        assert data[:8] == b'\x89PNG\r\n\x1a\n'
        w, h, _bits, ctype = struct.unpack('>IIBB', data[16:26])
        raw = open('%s/raw/%s.rgba' % (BUILD, j['name']), 'rb').read()
        alpha = raw[3::4]
        want_alpha = j['mode'] in ('rgba', 'rgba_opaque')
        row = {'file': j['out'], 'size': '%dx%d' % (w, h), 'colour': kinds[ctype]}
        if (w, h) != (j['w'], j['h']):
            failures.append('%s: wrong size' % j['out'])
        if want_alpha != (ctype == 6):
            failures.append('%s: wrong colour type' % j['out'])
        name = j['name']
        if name.startswith(('foreground', 'monochrome', 'adaptive-')):
            seen = [i for i, a in enumerate(alpha) if a]
            far = max(math.hypot(i % w + 0.5 - w / 2, i // w + 0.5 - h / 2) for i in seen) / w * 1024
            row['transparent_corner'] = alpha[0] == 0
            row['farthest_visible_px_in_1024_space'] = round(far, 1)
            row['inside_61_percent_safe_circle'] = far <= SAFE_RADIUS + 0.5
            if alpha[0] != 0 or far > SAFE_RADIUS + 0.5:
                failures.append('%s: transparency or safe area' % j['out'])
        if name.startswith('notification'):
            vis = [i for i, a in enumerate(alpha) if a]
            white = all(raw[4 * i] == 255 and raw[4 * i + 1] == 255 and raw[4 * i + 2] == 255 for i in vis)
            row['white_only'] = white
            row['transparent_corner'] = alpha[0] == 0
            if not white or alpha[0] != 0:
                failures.append('%s: not a white silhouette on transparent' % j['out'])
        if name == 'background':
            flat = all(raw[i:i + 3] == b'\x0b\x3f\x33' for i in range(0, len(raw), 4))
            row['solid_0B3F33'] = flat
            if not flat:
                failures.append('background is not a flat 0B3F33')
        if name in ('ios', 'play') or name.startswith(('legacy-', 'ios-')):
            row['fully_opaque'] = min(alpha) == 255
            if min(alpha) != 255:
                failures.append('%s: not opaque' % j['out'])
        rows.append(row)
    for r in rows:
        print(json.dumps(r))
    print('FAILURES: %s' % (failures or 'none'))
    return not failures


def svg_check():
    for name in ('app_icon_master', 'app_icon_foreground', 'app_icon_monochrome', 'notification_icon'):
        text = open('%s/%s.svg' % (SRC, name), encoding='utf-8').read()
        paths = text.count('<path')
        raster = '<image' in text or 'base64' in text or 'data:' in text
        print('%s.svg: %d <path> elements, embedded raster: %s' % (name, paths, raster))
        assert paths >= 1 and not raster


if __name__ == '__main__':
    cmd = sys.argv[1]
    if cmd == 'validate':
        svg_check()
        sys.exit(0 if validate() else 1)
    {'spec': spec, 'png': png}[cmd]()
