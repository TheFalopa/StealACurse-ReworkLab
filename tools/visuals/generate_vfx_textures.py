"""Generate original particle/beam textures for Curse VFX.

Usage (repository root):
    python tools/visuals/generate_vfx_textures.py [name ...]

Output: assets/vfx/textures/<name>.png and _preview.png.
Most textures are white with an alpha falloff so a ParticleEmitter Color can
tint them; a few (accretion, shard, petal) bake a deliberate colour ramp.
Uploaded asset IDs are recorded in src/shared/VisualAssets.luau.
"""
from __future__ import annotations

import math
import os
import random
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "vfx", "textures")


def smooth(t):
    t = min(1.0, max(0.0, t))
    return t * t * (3 - 2 * t)


def lerp(a, b, t):
    return a + (b - a) * t


def ramp(stops, t):
    """stops: [(t, (r,g,b)), ...] sorted."""
    t = min(1.0, max(0.0, t))
    for (t0, c0), (t1, c1) in zip(stops, stops[1:]):
        if t <= t1:
            k = (t - t0) / max(1e-6, t1 - t0)
            return tuple(int(lerp(c0[i], c1[i], k)) for i in range(3))
    return stops[-1][1]


def field(size, fn):
    img = Image.new("RGBA", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            u = (x + 0.5) / size * 2 - 1
            v = (y + 0.5) / size * 2 - 1
            px[x, y] = fn(u, v)
    return img


def noise(size, scale, seed):
    """Soft value noise built from upscaled random grids (no numpy needed)."""
    random.seed(seed)
    acc = Image.new("L", (size, size), 0)
    weight = 0
    for octave, amp in ((scale, 1.0), (scale * 2, 0.5), (scale * 4, 0.25)):
        g = Image.new("L", (octave, octave))
        g.putdata([random.randint(0, 255) for _ in range(octave * octave)])
        g = g.resize((size, size), Image.BICUBIC).filter(ImageFilter.GaussianBlur(size / octave / 3))
        acc = Image.blend(acc, g, amp / (weight + amp))
        weight += amp
    return acc


def white_alpha(size, alpha_fn):
    return field(size, lambda u, v: (255, 255, 255, int(255 * max(0.0, min(1.0, alpha_fn(u, v))))))


# ---------------------------------------------------------------- textures
def glow_soft():
    return white_alpha(256, lambda u, v: math.exp(-((u * u + v * v) / 0.18)) * smooth(1 - math.hypot(u, v)))


def glow_core():
    # Bright pinpoint with a long soft skirt: reads as a hot focal light.
    def a(u, v):
        r = math.hypot(u, v)
        return (0.75 * math.exp(-(r / 0.09) ** 2) + 0.45 * math.exp(-(r / 0.38) ** 2)) * smooth(1 - r)
    return white_alpha(256, a)


def void_core():
    # Opaque black singularity with a soft edge; tinted black or deep violet.
    def f(u, v):
        r = math.hypot(u, v)
        a = smooth((0.62 - r) / 0.2)
        return (6, 2, 14, int(255 * a))
    return field(256, f)


def horizon_rim():
    # Asymmetric bright lip around the core (gravitational lensing feel):
    # thick and hot on the lower-left, thin on the upper-right. Not a uniform hoop.
    def f(u, v):
        r = math.hypot(u, v)
        ang = math.atan2(v, u)
        bias = 0.55 + 0.45 * math.cos(ang - 2.3)
        width = 0.035 + 0.06 * bias
        band = math.exp(-((r - 0.52) / width) ** 2)
        inner = math.exp(-((r - 0.48) / 0.16) ** 2) * 0.35 * bias
        a = min(1.0, band * (0.35 + 0.65 * bias) + inner) * smooth((0.98 - r) / 0.2)
        c = ramp([(0, (255, 214, 250)), (1, (255, 255, 255))], bias)
        return c + (int(255 * a),)
    return field(256, f)


def accretion():
    # Spiral-armed disc seen face-on. Used with VelocityPerpendicular particles
    # so it lies in a plane and rotates via RotSpeed. Colour baked hot->violet.
    size = 512
    n = noise(size, 6, 11)
    npx = n.load()

    def f(u, v):
        r = math.hypot(u, v)
        if r > 1:
            return (0, 0, 0, 0)
        ang = math.atan2(v, u)
        # Two tight trailing arms with dark lanes between them.
        spiral = 0.5 + 0.5 * math.cos(2 * (ang + 3.4 * math.log(max(r, 0.05))))
        x = int((u * 0.5 + 0.5) * (size - 1))
        y = int((v * 0.5 + 0.5) * (size - 1))
        grain = npx[x, y] / 255
        hole = smooth((r - 0.24) / 0.05)
        outer = smooth((0.96 - r) / 0.5)
        lanes = spiral ** 2.6
        density = (0.06 + 0.94 * lanes) * (0.45 + 0.75 * grain)
        # Hot, thin inner edge where matter meets the horizon.
        side = (0.5 + 0.5 * math.cos(ang - 0.9)) ** 1.5
        lip = math.exp(-((r - 0.29) / 0.04) ** 2) * (0.15 + 0.55 * side) * (0.6 + 0.4 * lanes)
        heat = smooth((0.7 - r) / 0.45)
        a = min(1.0, (density * outer * (0.6 + 0.9 * heat) + lip) * hole)
        c = ramp([(0, (96, 34, 176)), (0.45, (206, 70, 210)), (0.8, (255, 164, 232)), (1, (255, 246, 255))],
                 min(1.0, heat * (0.55 + 0.45 * lanes) + lip))
        return c + (int(255 * a),)
    return field(size, f)


def streak():
    # Vertical tapered streak with a bright head at the top (for VelocityParallel).
    def a(u, v):
        t = (v + 1) / 2  # 0 top -> 1 bottom
        width = lerp(0.16, 0.015, t)
        across = math.exp(-(u / width) ** 2)
        along = smooth(t / 0.12) * (1 - t) ** 1.3
        return across * along * 1.6
    return white_alpha(256, a)


def spark():
    def a(u, v):
        r = math.hypot(u, v)
        cross = math.exp(-abs(u) / 0.03) * math.exp(-abs(v) / 0.55) + math.exp(-abs(v) / 0.03) * math.exp(-abs(u) / 0.55)
        return (0.9 * math.exp(-(r / 0.12) ** 2) + 0.7 * cross + 0.25 * math.exp(-(r / 0.4) ** 2)) * smooth(1 - r)
    return white_alpha(256, a)


def shard():
    # Dark angular stone fragment with a hot violet edge on one side.
    size = 256
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pts = [(128, 22), (196, 92), (176, 196), (110, 236), (62, 150), (78, 70)]
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).polygon(pts, fill=255)
    body = Image.new("RGBA", (size, size), (30, 18, 46, 255))
    img.paste(body, (0, 0), mask)
    facet = Image.new("L", (size, size), 0)
    ImageDraw.Draw(facet).polygon([(128, 22), (196, 92), (130, 120), (78, 70)], fill=255)
    img.paste(Image.new("RGBA", (size, size), (60, 40, 86, 255)), (0, 0), ImageChops.darker(facet, mask))
    edge = mask.filter(ImageFilter.GaussianBlur(3))
    shifted = ImageChops.offset(mask, -10, 8)
    rim = ImageChops.subtract(mask, shifted).filter(ImageFilter.GaussianBlur(2))
    img.paste(Image.new("RGBA", (size, size), (236, 120, 255, 255)), (0, 0), rim)
    a = ImageChops.multiply(img.getchannel("A"), edge.point(lambda v: min(255, v * 2)))
    img.putalpha(a)
    return img


def wisp():
    size = 256
    n = noise(size, 5, 4)
    npx = n.load()

    def a(u, v):
        r = math.hypot(u * 1.1, v)
        x = int((u * 0.5 + 0.5) * (size - 1))
        y = int((v * 0.5 + 0.5) * (size - 1))
        return smooth((0.95 - r) / 0.7) * (0.25 + 0.95 * (npx[x, y] / 255) ** 1.4)
    return white_alpha(size, a)


def mote():
    return white_alpha(128, lambda u, v: (math.exp(-(math.hypot(u, v) / 0.18) ** 2) + 0.35 * math.exp(-(math.hypot(u, v) / 0.5) ** 2)) * smooth(1 - math.hypot(u, v)))


def petal():
    def width(v):
        # Rounded crown (upper ellipse) narrowing to a pinched base at the bottom.
        if v < -0.82 or v > 0.88:
            return 0.0
        if v < 0.05:
            k = (v + 0.82) / 0.87
            return 0.46 * math.sqrt(max(0.0, 1 - (1 - k) ** 2))
        k = (v - 0.05) / 0.83
        return 0.46 * (1 - k) ** 1.4

    def f(u, v):
        w = width(v)
        if w <= 0:
            return (0, 0, 0, 0)
        # Slight notch at the crown makes it read as a rose petal, not a drop.
        notch = 0.06 * math.exp(-(u / 0.09) ** 2) if v < -0.6 else 0
        inner = (w - abs(u)) / w
        a = smooth((w - abs(u)) / 0.035) * smooth((v + 0.82 - notch) / 0.04)
        t = (v + 0.82) / 1.7
        c = ramp([(0, (255, 112, 136)), (0.45, (214, 32, 64)), (1, (92, 4, 22))], t * 0.75 + (1 - inner) * 0.35)
        return c + (int(255 * a),)
    return field(256, f)


def spore():
    def a(u, v):
        r = math.hypot(u, v)
        return (0.85 * math.exp(-(r / 0.22) ** 2) + 0.5 * math.exp(-((r - 0.42) / 0.08) ** 2)) * smooth((0.9 - r) / 0.2)
    return white_alpha(256, a)


def ember():
    def a(u, v):
        return math.exp(-((u / 0.16) ** 2 + (v / 0.42) ** 2)) * 1.2
    return white_alpha(128, a)


def rune_ring():
    # A broken ring of carved glyph ticks for cursed relic/celestial seals.
    size = 512
    img = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(img)
    c = size / 2
    random.seed(7)
    for i in range(18):
        a0 = i / 18 * 360 + 4
        a1 = a0 + 14
        d.arc((c - 220, c - 220, c + 220, c + 220), a0, a1, fill=255, width=10)
        a = math.radians(a0 + 7)
        kind = i % 3
        x, y = c + math.cos(a) * 180, c + math.sin(a) * 180
        if kind == 0:
            d.line((x - 10, y - 10, x + 10, y + 10), fill=255, width=7)
        elif kind == 1:
            d.ellipse((x - 8, y - 8, x + 8, y + 8), outline=255, width=6)
        else:
            d.line((x, y - 14, x, y + 14), fill=255, width=7)
    img = img.filter(ImageFilter.GaussianBlur(1.2))
    glow = img.filter(ImageFilter.GaussianBlur(10))
    a = ImageChops.lighter(img, glow.point(lambda v: int(v * 0.8)))
    out = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    out.putalpha(a)
    return out


def moon_blood():
    # Sky moon for the Red Moon event: crimson disc, darker maria, soft limb.
    size = 512
    n = noise(size, 7, 23)
    npx = n.load()

    def f(u, v):
        r = math.hypot(u, v)
        if r > 0.98:
            return (0, 0, 0, 0)
        x = int((u * 0.5 + 0.5) * (size - 1))
        y = int((v * 0.5 + 0.5) * (size - 1))
        maria = smooth((npx[x, y] / 255 - 0.45) / 0.2)
        limb = 1 - 0.45 * (r ** 3)
        light = 0.75 + 0.25 * (-u * 0.6 - v * 0.4)
        base = ramp([(0, (70, 2, 14)), (0.45, (168, 18, 36)), (1, (236, 84, 76))], (1 - maria * 0.75) * light)
        c = tuple(int(ch * limb) for ch in base)
        return c + (int(255 * smooth((0.98 - r) / 0.03)),)
    return field(size, f)


def portal_frame():
    # One glowing pointed doorway outline; stacked at depth for parallax.
    size = 512
    img = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(img)
    pts = [(150, 470), (150, 190), (256, 60), (362, 190), (362, 470)]
    d.line(pts, fill=255, width=14, joint="curve")
    img = img.filter(ImageFilter.GaussianBlur(2))
    glow = img.filter(ImageFilter.GaussianBlur(16)).point(lambda v: min(255, v * 2))
    a = ImageChops.lighter(img, glow)
    out = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    out.putalpha(a)
    return out


def rays():
    # Soft vertical light rays, brightest at the bottom centre, for halos.
    size = 256
    random.seed(5)
    beams = [(random.uniform(-0.8, 0.8), random.uniform(0.03, 0.09), random.uniform(0.4, 1)) for _ in range(9)]

    def a(u, v):
        t = (v + 1) / 2
        acc = 0
        for cx, w, k in beams:
            spread = cx * (0.35 + 0.65 * (1 - t))
            acc += k * math.exp(-((u - spread) / w) ** 2)
        return min(1.0, acc) * smooth(t / 0.9) * smooth((1 - t) / 0.08) * smooth((1 - abs(u)) / 0.3)
    return white_alpha(size, a)


def specter():
    # A faint hooded figure: rounded head, sloping shoulders, frayed hem.
    size = 256

    def a(u, v):
        t = (v + 0.85) / 1.8  # 0 at the crown of the hood, 1 at the tail
        if t < 0 or t > 1:
            return 0.0
        sway = 0.22 * math.sin(t * 6.0 - 1.2) * smooth((t - 0.35) / 0.65)
        # Rounded hood, broad shoulders, then a long tapering wispy tail.
        if t < 0.14:
            width = 0.2 * math.sqrt(max(0.0, 1 - ((0.14 - t) / 0.14) ** 2))
        elif t < 0.36:
            width = 0.2 + 0.24 * smooth((t - 0.14) / 0.22)
        else:
            width = 0.44 * (1 - (t - 0.36) / 0.64) ** 1.3 + 0.015
        body = smooth((width - abs(u - sway)) / 0.07)
        face = math.exp(-((u / 0.1) ** 2 + ((t - 0.13) / 0.06) ** 2))
        return body * (0.95 - 0.55 * t) * (1 - 0.85 * face)
    return white_alpha(size, a)


def crescent():
    def a(u, v):
        outer = smooth((0.82 - math.hypot(u, v)) / 0.04)
        inner = smooth((0.66 - math.hypot(u - 0.3, v - 0.12)) / 0.04)
        glow = 0.35 * math.exp(-((math.hypot(u, v) - 0.7) / 0.18) ** 2)
        return max(0.0, outer - inner) + glow * (1 - inner)
    return white_alpha(256, a)


def crystal():
    size = 256
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).polygon([(128, 12), (176, 110), (138, 244), (88, 120)], fill=255)
    facet = Image.new("L", (size, size), 0)
    ImageDraw.Draw(facet).polygon([(128, 12), (176, 110), (128, 128)], fill=255)
    img.paste(Image.new("RGBA", (size, size), (186, 214, 255, 255)), (0, 0), mask)
    img.paste(Image.new("RGBA", (size, size), (246, 252, 255, 255)), (0, 0), ImageChops.darker(facet, mask))
    edge = ImageChops.subtract(mask, ImageChops.offset(mask, 6, -4)).filter(ImageFilter.GaussianBlur(1.5))
    img.paste(Image.new("RGBA", (size, size), (255, 255, 255, 255)), (0, 0), edge)
    img.putalpha(mask.filter(ImageFilter.GaussianBlur(1.2)))
    return img


def wheel_wedge():
    # One 45-degree sector, apex at the image centre, pointing up. Rotated per
    # sector in UI; soft inner edge + thin separation gap between sectors.
    size = 512

    def a(u, v):
        r = math.hypot(u, v)
        if r < 0.16 or r > 0.98:
            return 0.0
        ang = math.degrees(math.atan2(u, -v))  # 0 = up, clockwise positive
        half = 22.5 - math.degrees(0.012 / max(r, 0.2))  # constant-width gap
        if abs(ang) > half:
            return 0.0
        edge = smooth((half - abs(ang)) / 1.5) * smooth((0.98 - r) / 0.015) * smooth((r - 0.16) / 0.02)
        shade = 0.82 + 0.18 * smooth((r - 0.2) / 0.7)
        return edge * shade
    return white_alpha(size, a)


TEXTURES = {
    "glow_soft": glow_soft,
    "glow_core": glow_core,
    "void_core": void_core,
    "horizon_rim": horizon_rim,
    "accretion": accretion,
    "streak": streak,
    "spark": spark,
    "shard": shard,
    "wisp": wisp,
    "mote": mote,
    "petal": petal,
    "spore": spore,
    "ember": ember,
    "rune_ring": rune_ring,
    "moon_blood": moon_blood,
    "portal_frame": portal_frame,
    "rays": rays,
    "specter": specter,
    "crescent": crescent,
    "crystal": crystal,
    "wheel_wedge": wheel_wedge,
}


def preview(names):
    cell = 180
    cols = 5
    sheet = Image.new("RGBA", (cell * cols, cell * math.ceil(len(names) / cols)), (16, 14, 28, 255))
    d = ImageDraw.Draw(sheet)
    for i, name in enumerate(names):
        img = Image.open(os.path.join(OUT, name + ".png")).convert("RGBA")
        x, y = (i % cols) * cell, (i // cols) * cell
        tile = img.resize((150, 150), Image.LANCZOS)
        sheet.alpha_composite(tile, (x + 15, y + 6))
        d.text((x + 15, y + cell - 20), name, fill=(220, 220, 240, 255))
    sheet.save(os.path.join(OUT, "_preview.png"))


def main(argv):
    os.makedirs(OUT, exist_ok=True)
    names = argv or list(TEXTURES)
    for name in names:
        TEXTURES[name]().save(os.path.join(OUT, name + ".png"), optimize=True)
        print("wrote", name)
    preview(list(TEXTURES))


if __name__ == "__main__":
    main(sys.argv[1:])
