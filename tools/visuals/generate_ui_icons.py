"""Generate the original Steal A Curse UI icon set.

Usage (repository root):
    python tools/visuals/generate_ui_icons.py            # all icons + preview sheet
    python tools/visuals/generate_ui_icons.py soul vip   # selected icons

Output: assets/ui/icons/<name>.png (256 px, transparent) and
assets/ui/icons/_preview.png (dark-background review at 24/48/96 px).
Uploaded asset IDs are recorded in src/shared/VisualAssets.luau.
"""
from __future__ import annotations

import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(__file__))
from iconkit import (S, Icon, cubic, dilate, ellipse_mask, erode, intersect, path, poly_mask,  # noqa: E402
                     radial, rrect_mask, solid, subtract, transform, union, vgradient, vgradient3)

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "ui", "icons")

CYAN_TOP, CYAN_BOTTOM = (196, 255, 246), (24, 170, 186)
CYAN_GLOW = (64, 232, 222)
GOLD_TOP, GOLD_BOTTOM = (255, 226, 132), (214, 120, 36)
VIOLET_TOP, VIOLET_BOTTOM = (186, 140, 255), (88, 46, 168)
MAGENTA = (238, 92, 196)


# ---------------------------------------------------------------- shapes
def soul_mask(scale=1.0, offset=(0, 0)):
    pts = path((512, 902), [
        ((360, 902), (250, 800), (252, 640)),
        ((254, 520), (284, 380), (300, 250)),     # left lick rises to a point
        ((350, 330), (390, 390), (430, 404)),     # dips back toward the body
        ((420, 290), (500, 160), (618, 80)),      # main tip, leaning right
        ((600, 200), (650, 270), (700, 330)),     # inner curl
        ((730, 300), (760, 270), (786, 236)),     # small right lick
        ((800, 340), (782, 470), (774, 560)),
        ((780, 790), (660, 902), (512, 902)),
    ])
    m = poly_mask(pts)
    if scale != 1.0 or offset != (0, 0):
        m = transform(m, scale=scale, center=(512, 620), offset=offset)
    return m


def draw_soul(icon: Icon, scale=1.0, offset=(0, 0), eyes=True, glow=True, outline=34):
    m = soul_mask(scale, offset)
    if glow:
        icon.glow(m, CYAN_GLOW, radius=52, opacity=0.5)
    # Pale violet tips -> spectral cyan body -> deep teal base.
    y0 = int(620 + (80 - 620) * scale + offset[1])
    ym = int(620 + (520 - 620) * scale + offset[1])
    y1 = int(620 + (900 - 620) * scale + offset[1])
    fill = vgradient3((222, 196, 255), CYAN_TOP, CYAN_BOTTOM, max(0, y0), ym, min(S - 1, y1))
    icon.body(m, None, None, outline=outline, shade=0.38, highlight=0.0, fill=fill)
    # Inner hot core: a smaller lighter flame so the soul has depth, not a flat blob.
    core = transform(soul_mask(), scale=0.56 * scale, center=(512, 620),
                     offset=(10 * scale + offset[0], 70 * scale + offset[1]))
    core = core.filter(ImageFilter.GaussianBlur(22 * scale))
    icon.over(solid((236, 255, 252), intersect(core, m), 0.85))
    if eyes:
        ex, ey = offset
        for x, tilt in ((448, 22), (590, -22)):
            cx, cy = 512 + (x - 512) * scale + ex, 650 + (0) * scale + ey
            rx, ry = 34 * scale, 56 * scale
            # A slanted brow cut lowers the inner top of each eye: a small,
            # knowing "cursed" look instead of a cute ghost stare.
            eye = ellipse_mask((cx - rx, cy - ry, cx + rx, cy + ry))
            inner = 1 if x < 512 else -1
            brow = poly_mask([(cx - rx * 1.5 * inner, cy - ry * 1.6), (cx + rx * 1.5 * inner, cy - ry * 1.6),
                              (cx + rx * 1.5 * inner, cy - ry * 0.05), (cx - rx * 1.5 * inner, cy - ry * 0.75)])
            eye = subtract(eye, brow)
            icon.flat(eye, (20, 30, 52))
            gl = ellipse_mask((cx - rx * 0.45, cy - ry * 0.05, cx + rx * 0.05, cy + ry * 0.45))
            icon.flat(gl, (235, 255, 255), 0.9)
    return m


def gear_mask(cx=512, cy=512, r_outer=300, r_inner=235, teeth=8, hole=105):
    pts = []
    for i in range(teeth * 2):
        a0 = (i / (teeth * 2)) * math.tau
        a1 = ((i + 1) / (teeth * 2)) * math.tau
        r = r_outer if i % 2 == 0 else r_inner
        inset = 0.16 if i % 2 == 0 else 0.0
        for a in (a0 + inset * (a1 - a0), a1 - inset * (a1 - a0)):
            pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    m = poly_mask(pts)
    m = union(m, ellipse_mask((cx - r_inner - 6, cy - r_inner - 6, cx + r_inner + 6, cy + r_inner + 6)))
    # Round the tooth corners slightly.
    m = erode(dilate(m, 22), 22)
    return subtract(m, ellipse_mask((cx - hole, cy - hole, cx + hole, cy + hole)))


def star_points(cx, cy, r_out, r_in, n=5, rot=-90):
    pts = []
    for i in range(n * 2):
        a = math.radians(rot + i * 180 / n)
        r = r_out if i % 2 == 0 else r_in
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    return pts


def heart_leaf(cx, cy, size, angle):
    """Rounded heart-shaped clover leaf pointing away from (cx, cy)."""
    m = union(
        ellipse_mask((512 - size * 0.95, 512 - size * 1.55, 512 + size * 0.05, 512 - size * 0.45)),
        ellipse_mask((512 - size * 0.05, 512 - size * 1.55, 512 + size * 0.95, 512 - size * 0.45)),
        poly_mask([(512 - size * 0.9, 512 - size * 0.85), (512 + size * 0.9, 512 - size * 0.85), (512, 512 - size * 0.02)]),
    )
    return transform(m, angle=angle, center=(512, 512), offset=(cx - 512, cy - 512))


# ---------------------------------------------------------------- icons
def icon_soul():
    icon = Icon()
    draw_soul(icon)
    return icon


def icon_double():
    icon = Icon()
    draw_soul(icon, scale=0.82, offset=(-150, -40))
    icon.glow(soul_mask(0.62, (170, 80)), CYAN_GLOW, radius=30, opacity=0.25)
    draw_soul(icon, scale=0.62, offset=(170, 80), glow=False, outline=30)
    return icon


def icon_shop():
    icon = Icon()
    sack = path((420, 400), [
        ((300, 470), (190, 620), (196, 742)),
        ((204, 870), (340, 912), (512, 912)),
        ((684, 912), (820, 870), (828, 742)),
        ((834, 620), (724, 470), (604, 400)),
    ])
    body = poly_mask(sack)
    ruffle = poly_mask(path((404, 372), [
        ((360, 300), (330, 230), (356, 178)),
        ((410, 222), (450, 238), (480, 214)),
        ((500, 170), (530, 168), (552, 214)),
        ((590, 238), (626, 220), (672, 176)),
        ((694, 236), (664, 304), (620, 372)),
    ]))
    tie = rrect_mask((384, 352, 640, 424), 34)
    sil = union(body, ruffle, tie)
    icon.glow(sil, (255, 170, 80), radius=46, opacity=0.38)
    icon.body(ruffle, (219, 160, 255), (120, 72, 196), outline=34, shade=0.3, highlight=0.25)
    icon.body(body, (178, 120, 246), (74, 38, 140), outline=34, shade=0.4, highlight=0.28)
    icon.body(tie, GOLD_TOP, GOLD_BOTTOM, outline=28, shade=0.25, highlight=0.35)
    # Soul emblem stitched on the sack.
    draw_soul(icon, scale=0.4, offset=(0, 40), eyes=False, glow=False, outline=22)
    return icon


def icon_curses():
    icon = Icon()
    pages = rrect_mask((262, 236, 816, 876), 46)
    cover = rrect_mask((214, 174, 772, 838), 52)
    spine = rrect_mask((214, 174, 330, 838), 44)
    icon.glow(union(cover, pages), (168, 112, 255), radius=46, opacity=0.4)
    icon.body(pages, (250, 236, 214), (198, 172, 150), outline=34, shade=0.35, highlight=0.0)
    icon.body(cover, VIOLET_TOP, VIOLET_BOTTOM, outline=34, shade=0.38, highlight=0.3)
    icon.flat(spine, (54, 26, 104), 0.75)
    for (x0, y0, x1, y1) in ((620, 174, 772, 326), (620, 686, 772, 838)):
        corner = intersect(cover, poly_mask([(x0, y0), (x1, y0), (x1, y1)] if y0 == 174 else [(x1, y0), (x1, y1), (x0, y1)]))
        icon.body(corner, GOLD_TOP, GOLD_BOTTOM, outline=0, shade=0.2, highlight=0.3)
    # Watching eye sigil.
    eye = poly_mask(path((330, 506), [((420, 380), (620, 380), (710, 506)), ((620, 632), (420, 632), (330, 506))]))
    icon.body(eye, (255, 250, 236), (214, 196, 232), outline=26, shade=0.2, highlight=0)
    iris = ellipse_mask((448, 444, 576, 572))
    icon.body(iris, (130, 255, 236), (16, 150, 170), outline=0, shade=0.2, highlight=0)
    icon.flat(ellipse_mask((490, 470, 534, 546)), (16, 11, 30))
    icon.flat(ellipse_mask((470, 462, 496, 488)), (255, 255, 255), 0.95)
    return icon


def icon_gamepass():
    icon = Icon()
    ticket = rrect_mask((168, 300, 856, 724), 64)
    for cy in (512,):
        for cx in (168, 856):
            ticket = subtract(ticket, ellipse_mask((cx - 70, cy - 70, cx + 70, cy + 70)))
    ticket = transform(ticket, angle=12)
    icon.glow(ticket, MAGENTA, radius=46, opacity=0.42)
    icon.body(ticket, (255, 132, 214), (148, 48, 172), outline=34, shade=0.38, highlight=0.3)
    perforation = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(perforation)
    for y in range(338, 700, 52):
        d.ellipse((660 - 11, y - 11, 660 + 11, y + 11), fill=255)
    icon.flat(transform(perforation, angle=12), (70, 16, 92), 0.7)
    star = transform(poly_mask(star_points(430, 512, 150, 64)), angle=12)
    icon.body(star, GOLD_TOP, GOLD_BOTTOM, outline=26, shade=0.25, highlight=0.4)
    return icon


def icon_settings():
    icon = Icon()
    g = gear_mask()
    icon.glow(g, (180, 170, 240), radius=40, opacity=0.3)
    icon.body(g, (236, 232, 255), (132, 126, 178), outline=34, shade=0.42, highlight=0.35)
    inner = subtract(ellipse_mask((512 - 168, 512 - 168, 512 + 168, 512 + 168)), ellipse_mask((512 - 105, 512 - 105, 512 + 105, 512 + 105)))
    icon.flat(inner, (96, 84, 150), 0.45)
    return icon


def icon_vip():
    icon = Icon()
    crown = poly_mask([(232, 700), (196, 330), (368, 520), (512, 236), (656, 520), (828, 330), (792, 700)])
    band = rrect_mask((222, 646, 802, 812), 40)
    tips = union(*[ellipse_mask((x - 52, y - 52, x + 52, y + 52)) for x, y in ((196, 316), (512, 214), (828, 316))])
    sil = union(crown, band, tips)
    icon.glow(sil, (255, 196, 90), radius=50, opacity=0.45)
    icon.body(union(crown, tips), GOLD_TOP, GOLD_BOTTOM, outline=34, shade=0.38, highlight=0.35)
    icon.body(band, (255, 214, 120), (190, 100, 30), outline=30, shade=0.3, highlight=0.3)
    gem = poly_mask([(512, 666), (566, 728), (512, 792), (458, 728)])
    icon.body(gem, (255, 160, 230), (190, 40, 150), outline=20, shade=0.2, highlight=0.4)
    for x in (340, 684):
        g2 = ellipse_mask((x - 34, 694, x + 34, 762))
        icon.body(g2, (180, 255, 246), (20, 160, 180), outline=18, shade=0.2, highlight=0.4)
    return icon


def icon_luck():
    icon = Icon()
    cx, cy = 512, 470
    leaves = [heart_leaf(cx, cy, 190, a) for a in (45, 135, 225, 315)]
    stem = poly_mask(cubic((520, 520), (560, 680), (640, 780), (720, 880), 24) +
                     list(reversed(cubic((480, 540), (520, 700), (600, 810), (676, 904), 24))))
    sil = union(*leaves, stem)
    icon.glow(sil, (110, 240, 130), radius=46, opacity=0.4)
    icon.body(stem, (120, 210, 110), (40, 120, 60), outline=30, shade=0.3, highlight=0)
    for leaf in leaves:
        icon.body(leaf, (170, 255, 150), (36, 160, 80), outline=32, shade=0.36, highlight=0.3)
    # Leaf veins.
    vein = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(vein)
    for a in (45, 135, 225, 315):
        r = math.radians(a - 90)
        d.line((cx, cy, cx + math.cos(r) * 230, cy + math.sin(r) * 230), fill=255, width=16)
    icon.flat(intersect(vein, union(*leaves)), (24, 110, 60), 0.55)
    icon.flat(ellipse_mask((cx - 30, cy - 30, cx + 30, cy + 30)), (230, 255, 200), 0.9)
    return icon


def icon_slot():
    icon = Icon()
    # A round stone display pedestal seen slightly from above, with a free-slot plus.
    base = union(ellipse_mask((214, 790, 810, 920)), rrect_mask((214, 760, 810, 856), 10))
    base_top = ellipse_mask((214, 722, 810, 852))
    column = union(rrect_mask((330, 610, 694, 800), 8), ellipse_mask((330, 740, 694, 836)))
    top = union(ellipse_mask((246, 560, 778, 690)), rrect_mask((246, 590, 778, 650), 8), ellipse_mask((246, 520, 778, 650)))
    top_face = ellipse_mask((256, 516, 768, 640))
    icon.body(base, (150, 132, 196), (60, 48, 100), outline=34, shade=0.4, highlight=0)
    icon.body(base_top, (176, 160, 222), (118, 100, 170), outline=0, shade=0.2, highlight=0)
    icon.body(column, (140, 122, 190), (66, 54, 110), outline=34, shade=0.45, highlight=0.15)
    icon.body(top, (150, 132, 200), (80, 66, 128), outline=34, shade=0.35, highlight=0)
    icon.body(top_face, (214, 200, 250), (150, 132, 204), outline=0, shade=0.15, highlight=0.3)
    icon.over(solid(CYAN_GLOW, ellipse_mask((350, 540, 674, 616)).filter(ImageFilter.GaussianBlur(22)), 0.55))
    plus = union(rrect_mask((456, 120, 568, 470), 34), rrect_mask((338, 240, 686, 352), 34))
    icon.glow(plus, CYAN_GLOW, radius=44, opacity=0.6)
    icon.body(plus, (210, 255, 248), (30, 196, 190), outline=30, shade=0.3, highlight=0.35)
    return icon


def icon_speed():
    icon = Icon()
    bolt = poly_mask([(612, 96), (286, 572), (488, 572), (398, 928), (752, 418), (548, 418), (676, 96)])
    bolt = erode(dilate(bolt, 18), 18)
    icon.glow(bolt, CYAN_GLOW, radius=50, opacity=0.5)
    for i, y in enumerate((332, 472, 612)):
        streak = rrect_mask((120 + i * 40, y - 22, 330 + i * 30, y + 22), 22)
        icon.body(streak, (190, 250, 255), (60, 190, 220), outline=22, shade=0, highlight=0)
    icon.body(bolt, (230, 255, 252), (40, 190, 210), outline=34, shade=0.4, highlight=0.35)
    return icon


def icon_trail():
    icon = Icon()
    tail = poly_mask(cubic((640, 190), (470, 260), (300, 520), (140, 884), 30) +
                     list(reversed(cubic((800, 410), (560, 470), (330, 660), (140, 884), 30))))
    head = ellipse_mask((560, 170, 860, 470))
    icon.glow(union(tail, head), MAGENTA, radius=50, opacity=0.45)
    fade = vgradient((255, 150, 230), (120, 40, 170), 260, 870)
    icon.body(tail, None, None, outline=30, shade=0.3, highlight=0.0, fill=fade)
    icon.body(head, (255, 240, 252), (236, 96, 200), outline=34, shade=0.38, highlight=0.3)
    for (x, y, r) in ((360, 300, 26), (250, 520, 18), (470, 760, 20)):
        sp = poly_mask(star_points(x, y, r * 2.4, r * 0.7, n=4, rot=0))
        icon.flat(sp, (255, 226, 250), 0.95)
    return icon


def icon_potion():
    icon = Icon()
    neck = rrect_mask((430, 200, 594, 420), 26)
    flask = union(ellipse_mask((226, 360, 798, 912)), neck)
    cork = rrect_mask((404, 128, 620, 232), 30)
    icon.glow(flask, (120, 250, 140), radius=50, opacity=0.4)
    icon.body(flask, (226, 236, 255), (150, 156, 196), outline=34, shade=0.3, highlight=0.0)
    wave = poly_mask(cubic((200, 580), (380, 520), (640, 640), (830, 560), 32) + [(830, 1000), (200, 1000)])
    liquid = intersect(erode(flask, 40), wave)
    icon.body(liquid, (170, 255, 140), (30, 170, 80), outline=0, shade=0.35, highlight=0)
    for (x, y, r) in ((430, 700, 34), (560, 640, 22), (600, 780, 28)):
        icon.flat(ellipse_mask((x - r, y - r, x + r, y + r)), (230, 255, 220), 0.8)
    shine = transform(rrect_mask((300, 470, 360, 720), 30), angle=-18, center=(330, 595))
    icon.flat(intersect(shine, flask), (255, 255, 255), 0.55)
    icon.body(cork, (214, 150, 96), (120, 70, 40), outline=30, shade=0.3, highlight=0.3)
    return icon


def icon_jar():
    icon = Icon()
    jar = rrect_mask((246, 270, 778, 900), 130)
    lid = rrect_mask((288, 160, 736, 290), 44)
    icon.glow(jar, CYAN_GLOW, radius=50, opacity=0.4)
    icon.body(jar, (96, 82, 148), (42, 34, 82), outline=34, shade=0.35, highlight=0)
    draw_soul(icon, scale=0.62, offset=(0, 30), glow=False, outline=0)
    glass = erode(jar, 24)
    icon.over(solid((210, 230, 255), glass, 0.12))
    shine = rrect_mask((300, 340, 360, 760), 30)
    icon.flat(intersect(shine, glass), (255, 255, 255), 0.45)
    icon.body(lid, GOLD_TOP, GOLD_BOTTOM, outline=30, shade=0.3, highlight=0.35)
    return icon


def icon_red_moon():
    icon = Icon()
    disc = ellipse_mask((196, 196, 828, 828))
    icon.glow(disc, (255, 40, 70), radius=60, opacity=0.6, grow=30)
    icon.body(disc, None, None, outline=34, shade=0.0, highlight=0.0,
              fill=radial((255, 120, 110), (150, 10, 36), (430, 400), 520))
    for (x, y, r) in ((600, 360, 70), (420, 560, 54), (630, 620, 40), (360, 340, 30), (520, 720, 34)):
        crater = ellipse_mask((x - r, y - r, x + r, y + r))
        icon.flat(crater, (110, 6, 26), 0.55)
        icon.flat(transform(crater, scale=0.7, center=(x, y), offset=(-r * 0.18, -r * 0.18)), (255, 150, 140), 0.18)
    # Eclipse shade on the lower right gives it a crescent of shadow.
    shade = subtract(disc, transform(disc, offset=(-90, -70)))
    icon.over(solid((40, 0, 14), shade.filter(ImageFilter.GaussianBlur(30)), 0.75))
    return icon


def icon_sanctuary():
    icon = Icon()
    gem = poly_mask([(512, 110), (760, 420), (512, 730), (264, 420)])
    inner = poly_mask([(512, 250), (640, 420), (512, 590), (384, 420)])
    stem = poly_mask([(470, 700), (554, 700), (520, 930), (504, 930)])
    icon.glow(gem, (190, 120, 255), radius=60, opacity=0.6, grow=30)
    icon.body(stem, (236, 210, 255), (120, 80, 200), outline=24, shade=0.2, highlight=0)
    icon.body(gem, (214, 170, 255), (98, 50, 190), outline=34, shade=0.38, highlight=0.35)
    icon.body(inner, (240, 255, 252), (110, 236, 226), outline=0, shade=0.2, highlight=0.3)
    return icon


def icon_tool_pack():
    icon = Icon()
    lid = rrect_mask((206, 260, 818, 470), 70)
    box = rrect_mask((206, 430, 818, 860), 36)
    sil = union(lid, box)
    icon.glow(sil, (255, 170, 80), radius=46, opacity=0.35)
    icon.body(box, (176, 112, 70), (96, 54, 34), outline=34, shade=0.4, highlight=0.15)
    icon.body(lid, (204, 136, 84), (128, 76, 44), outline=34, shade=0.3, highlight=0.3)
    for x in (300, 724):
        band = rrect_mask((x - 30, 270, x + 30, 850), 14)
        icon.body(band, GOLD_TOP, GOLD_BOTTOM, outline=0, shade=0.25, highlight=0.3)
    lock = rrect_mask((448, 420, 576, 560), 26)
    icon.body(lock, (210, 255, 248), (30, 196, 190), outline=26, shade=0.25, highlight=0.4)
    icon.flat(ellipse_mask((496, 466, 528, 498)), (16, 11, 30))
    return icon


IRON_TOP, IRON_BOTTOM = (176, 184, 196), (78, 84, 98)
WOOD_TOP, WOOD_BOTTOM = (176, 116, 74), (92, 54, 32)
BONE_TOP, BONE_BOTTOM = (250, 240, 214), (186, 168, 136)


def icon_tool_shovel():
    icon = Icon()
    shaft = transform(rrect_mask((470, 120, 554, 660), 30), angle=-35, scale=1.18, center=(512, 512))
    grip = transform(union(rrect_mask((410, 84, 614, 156), 32), rrect_mask((470, 92, 554, 200), 24)), angle=-35, scale=1.18, center=(512, 512))
    blade = poly_mask(path((392, 620), [((380, 700), (390, 800), (512, 900)), ((634, 800), (644, 700), (632, 620))]) + [(600, 600), (424, 600)])
    blade = transform(blade, angle=-35, center=(512, 512))
    socket = transform(rrect_mask((468, 560, 556, 640), 16), angle=-35, center=(512, 512))
    icon.glow(union(shaft, blade), (180, 200, 255), radius=40, opacity=0.25)
    icon.body(shaft, WOOD_TOP, WOOD_BOTTOM, outline=30, shade=0.3, highlight=0.25)
    icon.body(grip, BONE_TOP, BONE_BOTTOM, outline=28, shade=0.25, highlight=0.3)
    icon.body(blade, IRON_TOP, IRON_BOTTOM, outline=34, shade=0.4, highlight=0.4)
    icon.body(socket, (120, 126, 140), (60, 64, 76), outline=0, shade=0.2, highlight=0.2)
    return icon


def icon_tool_boots():
    icon = Icon()
    boot = poly_mask(path((330, 200), [((330, 200), (520, 200), (520, 200)), ((520, 450), (520, 560), (560, 620)),
                                       ((700, 640), (820, 680), (830, 790)), ((830, 860), (780, 880), (700, 880)), ((300, 880),)]))
    boot = erode(dilate(boot, 30), 30)
    sole = rrect_mask((290, 840, 846, 912), 30)
    icon.glow(boot, (255, 150, 80), radius=50, opacity=0.4)
    icon.body(boot, (120, 108, 104), (52, 46, 48), outline=34, shade=0.4, highlight=0.25)
    icon.body(sole, (90, 86, 82), (40, 38, 38), outline=28, shade=0.2, highlight=0)
    seal = rrect_mask((360, 300, 470, 420), 18)
    icon.body(seal, BONE_TOP, BONE_BOTTOM, outline=20, shade=0.2, highlight=0.3)
    for x, y, r in ((180, 760, 40), (150, 640, 28), (210, 540, 22)):
        icon.flat(ellipse_mask((x - r, y - r, x + r, y + r)), (255, 160, 90), 0.85)
    return icon


def icon_tool_urn():
    icon = Icon()
    body = union(ellipse_mask((260, 330, 764, 880)), rrect_mask((392, 230, 632, 380), 30))
    lid = rrect_mask((360, 170, 664, 260), 36)
    icon.glow(body, (255, 140, 80), radius=46, opacity=0.35)
    for side in (-1, 1):
        handle = transform(rrect_mask((640, 380, 720, 600), 34), angle=0, center=(512, 512)) if side > 0 else rrect_mask((304, 380, 384, 600), 34)
        icon.body(subtract(handle, erode(handle, 40)), (230, 180, 110), (150, 100, 50), outline=22, shade=0.2, highlight=0.2)
    icon.body(body, (196, 112, 76), (110, 52, 34), outline=34, shade=0.4, highlight=0.3)
    icon.body(lid, GOLD_TOP, GOLD_BOTTOM, outline=28, shade=0.25, highlight=0.35)
    mark = union(rrect_mask((486, 480, 538, 720), 14), rrect_mask((420, 550, 604, 600), 14))
    icon.flat(mark, (250, 236, 210), 0.9)
    return icon


def icon_tool_censer():
    icon = Icon()
    bowl = intersect(ellipse_mask((270, 380, 754, 860)), rrect_mask((200, 560, 830, 900), 0))
    cap = intersect(ellipse_mask((300, 420, 724, 760)), rrect_mask((200, 380, 830, 600), 0))
    chainL = rrect_mask((330, 140, 352, 560), 10)
    chainR = rrect_mask((672, 140, 694, 560), 10)
    icon.body(union(chainL, chainR), IRON_TOP, IRON_BOTTOM, outline=18, shade=0, highlight=0)
    icon.glow(union(bowl, cap), (200, 210, 230), radius=50, opacity=0.4)
    icon.body(bowl, GOLD_TOP, GOLD_BOTTOM, outline=34, shade=0.4, highlight=0.3)
    icon.body(cap, (240, 200, 120), (170, 110, 40), outline=30, shade=0.3, highlight=0.35)
    for x, y, r in ((440, 300, 70), (560, 230, 90), (470, 140, 60)):
        puff = ellipse_mask((x - r, y - r, x + r, y + r))
        icon.over(solid((220, 226, 236), puff.filter(ImageFilter.GaussianBlur(10)), 0.85))
    return icon


def icon_tool_lantern():
    icon = Icon()
    glass = rrect_mask((360, 330, 664, 760), 40)
    roof = poly_mask([(320, 340), (512, 170), (704, 340)])
    base = rrect_mask((330, 740, 694, 840), 26)
    ring = subtract(ellipse_mask((440, 80, 584, 224)), ellipse_mask((476, 116, 548, 188)))
    icon.glow(glass, (120, 240, 210), radius=60, opacity=0.6, grow=30)
    icon.body(ring, IRON_TOP, IRON_BOTTOM, outline=20, shade=0.2, highlight=0.2)
    icon.body(glass, (200, 255, 236), (60, 190, 160), outline=0, shade=0.2, highlight=0.3)
    flame = poly_mask(path((512, 660), [((440, 640), (450, 520), (512, 440)), ((574, 520), (584, 640), (512, 660))]))
    icon.flat(flame, (255, 255, 240), 0.95)
    for x in (360, 500, 640):
        icon.body(rrect_mask((x, 330, x + 24, 760), 10), IRON_TOP, IRON_BOTTOM, outline=18, shade=0, highlight=0)
    icon.body(roof, (110, 116, 130), (50, 54, 66), outline=30, shade=0.3, highlight=0.3)
    icon.body(base, (110, 116, 130), (50, 54, 66), outline=28, shade=0.3, highlight=0.2)
    return icon


def icon_tool_salt():
    icon = Icon()
    bag = poly_mask(path((400, 330), [((300, 420), (240, 640), (280, 800)), ((320, 900), (704, 900), (744, 800)),
                                      ((784, 640), (724, 420), (624, 330))]))
    neck = rrect_mask((390, 260, 634, 350), 30)
    icon.glow(bag, (240, 230, 200), radius=46, opacity=0.35)
    icon.body(bag, (236, 222, 186), (170, 150, 112), outline=34, shade=0.4, highlight=0.3)
    icon.body(neck, (150, 110, 70), (90, 60, 36), outline=26, shade=0.2, highlight=0.2)
    cross = union(rrect_mask((486, 470, 538, 760), 14), rrect_mask((420, 540, 604, 592), 14))
    icon.flat(cross, (120, 92, 60), 0.8)
    for x, y, r in ((300, 220, 16), (380, 170, 12), (250, 290, 10), (740, 230, 14)):
        icon.flat(ellipse_mask((x - r, y - r, x + r, y + r)), (255, 255, 240), 0.95)
    return icon


def icon_tool_trap():
    icon = Icon()
    base = ellipse_mask((200, 640, 824, 860))
    teeth = []
    for i in range(7):
        x = 250 + i * 87
        teeth.append(poly_mask([(x - 40, 760), (x, 380 + (i % 2) * 90), (x + 40, 760)]))
    jaws = union(*teeth)
    icon.glow(union(base, jaws), (140, 200, 90), radius=40, opacity=0.3)
    icon.body(base, WOOD_TOP, WOOD_BOTTOM, outline=34, shade=0.4, highlight=0.25)
    icon.body(jaws, BONE_TOP, BONE_BOTTOM, outline=26, shade=0.35, highlight=0.3)
    plate = ellipse_mask((420, 700, 604, 790))
    icon.body(plate, GOLD_TOP, GOLD_BOTTOM, outline=18, shade=0.2, highlight=0.3)
    return icon


def icon_tool_talisman():
    icon = Icon()
    paper = transform(rrect_mask((370, 200, 654, 860), 18), angle=-8, center=(512, 530))
    icon.glow(paper, (120, 240, 220), radius=50, opacity=0.45)
    icon.body(paper, (250, 238, 200), (210, 186, 140), outline=32, shade=0.3, highlight=0.3)
    ink = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(ink)
    d.line((512, 300, 512, 760), fill=255, width=34)
    d.line((420, 420, 604, 420), fill=255, width=28)
    d.line((440, 600, 590, 680), fill=255, width=24)
    d.ellipse((462, 470, 562, 570), outline=255, width=22)
    icon.flat(intersect(transform(ink, angle=-8, center=(512, 530)), paper), (180, 30, 50), 0.9)
    tear = transform(poly_mask([(560, 840), (654, 760), (654, 860)]), angle=-8, center=(512, 530))
    icon.flat(tear, (16, 11, 30), 1)
    return icon


def icon_tool_chain():
    icon = Icon()
    links = []
    for i in range(4):
        cx, cy = 330 + i * 120, 250 + i * 150
        outer = ellipse_mask((cx - 110, cy - 70, cx + 110, cy + 70))
        inner = ellipse_mask((cx - 60, cy - 26, cx + 60, cy + 26))
        link = transform(subtract(outer, inner), angle=-35 + (i % 2) * 70, center=(cx, cy))
        links.append(link)
    hook = subtract(ellipse_mask((640, 700, 860, 920)), ellipse_mask((690, 750, 810, 870)))
    hook = subtract(hook, rrect_mask((640, 700, 750, 810), 0))
    all_ = union(*links, hook)
    icon.glow(all_, (190, 170, 255), radius=40, opacity=0.3)
    for link in links:
        icon.body(link, IRON_TOP, IRON_BOTTOM, outline=26, shade=0.35, highlight=0.4)
    icon.body(hook, GOLD_TOP, GOLD_BOTTOM, outline=26, shade=0.3, highlight=0.35)
    return icon


def icon_tool_mirror():
    icon = Icon()
    frame = ellipse_mask((260, 140, 764, 820))
    glass = ellipse_mask((320, 200, 704, 760))
    stand = rrect_mask((460, 780, 564, 900), 18)
    icon.glow(frame, (140, 220, 240), radius=46, opacity=0.4)
    icon.body(stand, GOLD_TOP, GOLD_BOTTOM, outline=26, shade=0.3, highlight=0.2)
    icon.body(frame, GOLD_TOP, GOLD_BOTTOM, outline=34, shade=0.35, highlight=0.35)
    icon.body(glass, (190, 236, 248), (70, 130, 170), outline=0, shade=0.25, highlight=0)
    # Two ghostly silhouettes: you and your double.
    for x, alpha in ((450, 0.85), (580, 0.45)):
        head = ellipse_mask((x - 46, 340, x + 46, 432))
        body = rrect_mask((x - 64, 430, x + 64, 640), 50)
        icon.flat(union(head, body), (240, 255, 255), alpha)
    shine = transform(rrect_mask((360, 260, 400, 520), 20), angle=20, center=(380, 390))
    icon.flat(intersect(shine, glass), (255, 255, 255), 0.5)
    return icon


ICONS = {
    "soul": icon_soul,
    "double_souls": icon_double,
    "shop": icon_shop,
    "curses": icon_curses,
    "gamepass": icon_gamepass,
    "settings": icon_settings,
    "vip": icon_vip,
    "luck": icon_luck,
    "slot": icon_slot,
    "speed": icon_speed,
    "trail": icon_trail,
    "potion": icon_potion,
    "soul_jar": icon_jar,
    "red_moon": icon_red_moon,
    "sanctuary": icon_sanctuary,
    "tool_pack": icon_tool_pack,
    "tool_shovel": icon_tool_shovel,
    "tool_ash_boots": icon_tool_boots,
    "tool_impact_urn": icon_tool_urn,
    "tool_mist_censer": icon_tool_censer,
    "tool_exorcist_lantern": icon_tool_lantern,
    "tool_consecrated_salt": icon_tool_salt,
    "tool_root_trap": icon_tool_trap,
    "tool_break_talisman": icon_tool_talisman,
    "tool_jailer_chain": icon_tool_chain,
    "tool_double_mirror": icon_tool_mirror,
}


def preview(names):
    tiles = []
    for name in names:
        img = Image.open(os.path.join(OUT, name + ".png"))
        tiles.append((name, img))
    cell = 220
    sheet = Image.new("RGBA", (cell * min(5, len(tiles)), cell * math.ceil(len(tiles) / 5)), (18, 20, 36, 255))
    d = ImageDraw.Draw(sheet)
    for i, (name, img) in enumerate(tiles):
        x, y = (i % 5) * cell, (i // 5) * cell
        d.rounded_rectangle((x + 8, y + 8, x + cell - 8, y + cell - 8), radius=16, fill=(28, 30, 52, 255))
        sheet.alpha_composite(img.resize((120, 120), Image.LANCZOS), (x + 14, y + 14))
        sheet.alpha_composite(img.resize((48, 48), Image.LANCZOS), (x + 150, y + 20))
        sheet.alpha_composite(img.resize((24, 24), Image.LANCZOS), (x + 162, y + 90))
        d.text((x + 16, y + cell - 40), name, fill=(220, 220, 240, 255))
    sheet.save(os.path.join(OUT, "_preview.png"))


def main(argv):
    os.makedirs(OUT, exist_ok=True)
    names = argv or list(ICONS)
    for name in names:
        ICONS[name]().save(os.path.join(OUT, name + ".png"))
        print("wrote", name)
    preview(list(ICONS) if not argv else names)


if __name__ == "__main__":
    main(sys.argv[1:])
