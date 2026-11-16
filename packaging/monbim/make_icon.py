#!/usr/bin/env python3
"""Draw MonBIM's app icon (original artwork, MIT OR Apache-2.0) and write every file the builds and packages use.

    python3 packaging/monbim/make_icon.py          # needs Python with Pillow; the outputs are committed
    python3 packaging/monbim/make_icon.py --rust   # also prints the shapes for start.rs's logo()

A building drawn in isometric on MonCad's blue drafting sheet: the left wall Mongolian-flag red, the right wall
blue, the roof gold (Mon3D's cube colours), white edges and windows. The file names stay upstream's (bimcraft-*,
bimcraft.ico/.icns/.svg) so the packaging scripts and build.rs need no changes. This replaces packaging/icons.sh,
which needs ImageMagick: Pillow resizes, and writes the .ico and the .icns, itself.
"""
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "app-icon"
APP_ID = "io.github.ipedrax.bimcraft"
NAVY, GRID, WHITE = (13, 59, 110), (52, 104, 160), (248, 250, 252)
RED, BLUE, GOLD = (218, 41, 28), (25, 118, 210), (255, 196, 46)
GRID_ALPHA = 110
EDGE = 5.5  # white edge width, in the 256 px design space
S = 4096  # supersampled canvas
K = S / 256


def hexc(c):
    return "#%02X%02X%02X" % c


def shapes():
    """The building's faces and windows, fitted into the tile, as (colour, points in 256 px space, edged)."""
    a = b = 70.0  # footprint
    h = 116.0  # height
    floors = 3
    c = math.cos(math.radians(30))

    def q(pts):
        return [(x * c - y * c, -x * 0.5 - y * 0.5 - z) for x, y, z in pts]

    faces = [
        (RED, q([(0, 0, 0), (0, b, 0), (0, b, h), (0, 0, h)]), True),
        (BLUE, q([(0, 0, 0), (a, 0, 0), (a, 0, h), (0, 0, h)]), True),
        (GOLD, q([(0, 0, h), (a, 0, h), (a, b, h), (0, b, h)]), True),
    ]
    fh = h / floors
    for f in range(floors):
        z0, z1 = f * fh + fh * 0.3, f * fh + fh * 0.72
        for i in range(2):
            u0 = 10 + i * 31
            u1 = u0 + 21
            faces.append((WHITE, q([(u0, 0, z0), (u1, 0, z0), (u1, 0, z1), (u0, 0, z1)]), False))
            faces.append((WHITE, q([(0, u0, z0), (0, u1, z0), (0, u1, z1), (0, u0, z1)]), False))
    xs = [x for _, pts, _ in faces for x, _ in pts]
    ys = [y for _, pts, _ in faces for _, y in pts]
    box = (38.0, 36.0, 180.0, 184.0)  # left, top, width, height
    w, hh = max(xs) - min(xs), max(ys) - min(ys)
    s = min(box[2] / w, box[3] / hh)
    ox = box[0] + (box[2] - w * s) / 2 - min(xs) * s
    oy = box[1] + (box[3] - hh * s) / 2 - min(ys) * s
    out = []
    for col, pts, edged in faces:
        pts = [(round(ox + x * s, 1), round(oy + y * s, 1)) for x, y in pts]
        # Clockwise on screen (y down), as egui's convex_polygon wants its points.
        if sum(x0 * y1 - x1 * y0 for (x0, y0), (x1, y1) in zip(pts, pts[1:] + pts[:1])) < 0:
            pts.reverse()
        out.append((col, pts, edged))
    return out


def grid_lines():
    return [8 + 20 * i for i in range(1, 12)]


def render(size: int) -> Image.Image:
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(img).rounded_rectangle([8 * K, 8 * K, 248 * K, 248 * K], 52 * K, fill=NAVY)
    g = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gd = ImageDraw.Draw(g)
    for v in grid_lines():
        gd.line([(v * K, 8 * K), (v * K, 248 * K)], fill=GRID + (GRID_ALPHA,), width=int(1.6 * K))
        gd.line([(8 * K, v * K), (248 * K, v * K)], fill=GRID + (GRID_ALPHA,), width=int(1.6 * K))
    tile = Image.new("L", (S, S), 0)
    ImageDraw.Draw(tile).rounded_rectangle([8 * K, 8 * K, 248 * K, 248 * K], 52 * K, fill=255)
    g.putalpha(Image.composite(g.getchannel("A"), Image.new("L", (S, S), 0), tile))
    img.alpha_composite(g)
    d = ImageDraw.Draw(img)
    for col, pts, edged in shapes():
        p = [(x * K, y * K) for x, y in pts]
        d.polygon(p, fill=col)
        if edged:
            d.line(p + [p[0]], fill=WHITE, width=int(EDGE * K), joint="curve")
            r = EDGE * K / 2
            for x, y in p:
                d.ellipse([x - r, y - r, x + r, y + r], fill=WHITE)
    return img.resize((size, size), Image.LANCZOS)


def svg() -> str:
    lines = [
        '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">',
        '  <clipPath id="tile"><rect x="8" y="8" width="240" height="240" rx="52"/></clipPath>',
        f'  <rect x="8" y="8" width="240" height="240" rx="52" fill="{hexc(NAVY)}"/>',
        f'  <g clip-path="url(#tile)" stroke="{hexc(GRID)}" stroke-opacity="{GRID_ALPHA / 255:.2f}" stroke-width="1.6">'
        + "".join(f'<path d="M{v} 0V256M0 {v}H256"/>' for v in grid_lines())
        + "</g>",
    ]
    for col, pts, edged in shapes():
        p = " ".join(f"{x},{y}" for x, y in pts)
        edge = f' stroke="{hexc(WHITE)}" stroke-width="{EDGE}" stroke-linejoin="round"' if edged else ""
        lines.append(f'  <polygon points="{p}" fill="{hexc(col)}"{edge}/>')
    lines.append("</svg>")
    return "\n".join(lines) + "\n"


def rust() -> str:
    out = []
    for col, pts, edged in shapes():
        name = {RED: "red", BLUE: "blue", GOLD: "gold", WHITE: "white"}[col]
        p = ", ".join(f"({x:.1f}, {y:.1f})" for x, y in pts)
        out.append(f"    poly(&[{p}], {name}, {'true' if edged else 'false'});")
    return "\n".join(out)


if __name__ == "__main__":
    master = render(1024)
    master.save(OUT / "bimcraft-1024.png", optimize=True)
    for s in (256, 64):
        master.resize((s, s), Image.LANCZOS).save(OUT / f"bimcraft-{s}.png", optimize=True)
    (OUT / "bimcraft.svg").write_text(svg())
    for s in (16, 24, 32, 48, 64, 128, 256, 512):
        d = OUT / "hicolor" / f"{s}x{s}" / "apps"
        d.mkdir(parents=True, exist_ok=True)
        render(s).save(d / f"{APP_ID}.png", optimize=True)
    (OUT / "hicolor" / "scalable" / "apps").mkdir(parents=True, exist_ok=True)
    (OUT / "hicolor" / "scalable" / "apps" / f"{APP_ID}.svg").write_text(svg())
    # macOS: Apple's grid, an 824 px body on a 1024 px canvas; the tile fills 960 of the master's 1024.
    body = master.resize((1024 * 824 // 960,) * 2, Image.LANCZOS)
    mac = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    mac.alpha_composite(body, ((1024 - body.width) // 2, (1024 - body.height) // 2))
    mac.save(OUT / "bimcraft-macos-1024.png", optimize=True)
    mac.save(OUT / "bimcraft.icns", format="ICNS")
    # Windows: each size resampled straight from the 4096 px drawing.
    sizes = (16, 24, 32, 48, 64, 128, 256)
    big = render(256)
    big.save(OUT / "bimcraft.ico", format="ICO", sizes=[(s, s) for s in sizes],
             append_images=[render(s) for s in sizes[:-1]])
    print("icons written to", OUT)
    if "--rust" in sys.argv:
        print(rust())
