"""Small PIL toolkit for game-ready UI icons.

Icons are authored as vector-like shapes on a 1024 px canvas and rendered with
a consistent style: dark ink outline, vertical gradient fill, soft lower shade,
upper highlight and a restrained outer glow. The final PNG is downsampled to
256 px so it reads cleanly at the 24-64 px sizes used by the HUD.
"""
from __future__ import annotations

import math
from PIL import Image, ImageChops, ImageDraw, ImageFilter

S = 1024
INK = (16, 11, 30)


def canvas(mode: str = "L", value=0) -> Image.Image:
    return Image.new(mode, (S, S), value)


def cubic(p0, p1, p2, p3, steps: int = 48):
    pts = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        x = u ** 3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t ** 3 * p3[0]
        y = u ** 3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t ** 3 * p3[1]
        pts.append((x, y))
    return pts


def path(start, segments):
    """segments: list of (c1, c2, end) cubic segments or (end,) line segments."""
    pts = [start]
    cur = start
    for seg in segments:
        if len(seg) == 1:
            pts.append(seg[0])
            cur = seg[0]
        else:
            pts.extend(cubic(cur, seg[0], seg[1], seg[2])[1:])
            cur = seg[2]
    return pts


def poly_mask(points) -> Image.Image:
    m = canvas()
    ImageDraw.Draw(m).polygon(points, fill=255)
    return m


def ellipse_mask(box) -> Image.Image:
    m = canvas()
    ImageDraw.Draw(m).ellipse(box, fill=255)
    return m


def rrect_mask(box, radius) -> Image.Image:
    m = canvas()
    ImageDraw.Draw(m).rounded_rectangle(box, radius=radius, fill=255)
    return m


def union(*masks) -> Image.Image:
    out = masks[0]
    for m in masks[1:]:
        out = ImageChops.lighter(out, m)
    return out


def subtract(a, b) -> Image.Image:
    return ImageChops.subtract(a, b)


def intersect(a, b) -> Image.Image:
    return ImageChops.darker(a, b)


def transform(mask: Image.Image, angle=0.0, scale=1.0, center=(S / 2, S / 2), offset=(0, 0)) -> Image.Image:
    """Rotate (degrees, counter-clockwise) and scale about center, then offset."""
    a = math.radians(angle)
    cos, sin = math.cos(a), math.sin(a)
    cx, cy = center
    # Inverse affine for Image.transform: output -> input.
    inv = 1 / scale
    ox, oy = offset
    # x_in = inv*( cos*(x-cx-ox) - sin*(y-cy-oy) ) + cx ; y similar with +sin
    a0 = inv * cos
    a1 = -inv * sin
    a2 = cx - a0 * (cx + ox) - a1 * (cy + oy)
    b0 = inv * sin
    b1 = inv * cos
    b2 = cy - b0 * (cx + ox) - b1 * (cy + oy)
    return mask.transform((S, S), Image.AFFINE, (a0, a1, a2, b0, b1, b2), resample=Image.BICUBIC)


def dilate(mask: Image.Image, px: float) -> Image.Image:
    if px <= 0:
        return mask
    blurred = mask.filter(ImageFilter.GaussianBlur(px * 0.5))
    return blurred.point(lambda v: 255 if v > 18 else int(v * 255 / 18))


def erode(mask: Image.Image, px: float) -> Image.Image:
    if px <= 0:
        return mask
    blurred = mask.filter(ImageFilter.GaussianBlur(px * 0.5))
    return blurred.point(lambda v: 255 if v > 237 else max(0, int((v - 219) * 255 / 18)))


def vgradient(top, bottom, y0=0, y1=S) -> Image.Image:
    g = Image.new("RGBA", (1, S))
    for y in range(S):
        t = min(1.0, max(0.0, (y - y0) / max(1, (y1 - y0))))
        g.putpixel((0, y), tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,))
    return g.resize((S, S))


def vgradient3(top, mid, bottom, y0, ym, y1) -> Image.Image:
    upper = vgradient(top, mid, y0, ym)
    lower = vgradient(mid, bottom, ym, y1)
    out = upper.copy()
    out.paste(lower.crop((0, ym, S, S)), (0, ym))
    return out


def radial(color_in, color_out, center, radius) -> Image.Image:
    small = 256
    img = Image.new("RGBA", (small, small))
    cx, cy = center[0] * small / S, center[1] * small / S
    r = radius * small / S
    px = img.load()
    for y in range(small):
        for x in range(small):
            t = min(1.0, math.hypot(x - cx, y - cy) / r)
            t = t * t * (3 - 2 * t)
            px[x, y] = tuple(int(color_in[i] + (color_out[i] - color_in[i]) * t) for i in range(3)) + (255,)
    return img.resize((S, S), Image.BICUBIC)


def solid(color, alpha_mask: Image.Image, opacity: float = 1.0) -> Image.Image:
    layer = Image.new("RGBA", (S, S), tuple(color[:3]) + (0,))
    a = alpha_mask if opacity >= 1 else alpha_mask.point(lambda v: int(v * opacity))
    layer.putalpha(a)
    return layer


def masked(fill: Image.Image, mask: Image.Image) -> Image.Image:
    out = fill.copy()
    out.putalpha(ImageChops.multiply(fill.getchannel("A"), mask))
    return out


class Icon:
    def __init__(self):
        self.img = Image.new("RGBA", (S, S), (0, 0, 0, 0))

    def over(self, layer: Image.Image):
        self.img = Image.alpha_composite(self.img, layer)

    def glow(self, mask, color, radius=46, opacity=0.55, grow=24):
        g = dilate(mask, grow).filter(ImageFilter.GaussianBlur(radius))
        self.over(solid(color, g, opacity))

    def body(self, mask, top, bottom, outline=36, shade=0.32, highlight=0.30,
             ink=INK, gradient_span=None, fill=None, light_dir=(-1, -1)):
        """Draw one styled shape: outline, fill, lower shade and upper rim light."""
        if outline > 0:
            self.over(solid(ink, dilate(mask, outline)))
        y0, y1 = gradient_span or bbox_y(mask)
        base = fill if fill is not None else vgradient(top, bottom, y0, y1)
        self.over(masked(base, mask))
        if shade > 0:
            # Lower/right inner shadow: the mask minus a copy displaced toward the light.
            moved = transform(mask, offset=(-light_dir[0] * 34, -light_dir[1] * 34))
            edge = subtract(mask, moved).filter(ImageFilter.GaussianBlur(14))
            self.over(solid((10, 4, 30), intersect(edge, mask), shade))
        if highlight > 0:
            moved = transform(mask, offset=(light_dir[0] * 26, light_dir[1] * 26))
            rim = subtract(mask, moved).filter(ImageFilter.GaussianBlur(8))
            self.over(solid((255, 255, 255), intersect(rim, erode(mask, 10)), highlight))

    def flat(self, mask, color, opacity=1.0, outline=0, ink=INK):
        if outline > 0:
            self.over(solid(ink, dilate(mask, outline)))
        self.over(solid(color, mask, opacity))

    def save(self, path: str, size: int = 256):
        # Trim padding consistently: keep the full canvas so all icons share
        # the same optical framing, then downsample with high quality.
        self.img.resize((size, size), Image.LANCZOS).save(path, optimize=True)


def bbox_y(mask: Image.Image):
    box = mask.getbbox() or (0, 0, S, S)
    return box[1], box[3]
