"""Exp 01 · trace the visible carriers of The Dream of Paris from their own pixels.

Idea: C (visible) is drawn by the machine from the painting itself; R (absent) has no pixels and stays pure geometry.
For every carrier box in data/paris_translation.json:
    A  edge trace   — Canny-style: blur → Sobel → thin to 1px (non-max suppression) → hysteresis
    B  pixel contour — threshold the blurred crop, draw the staircase boundary between dark and light pixels
Both work on the 843px IIIF image, so small carriers come out coarse (that pixel grain is kept on purpose).

Usage:  .venv/Scripts/python -I -X utf8 scripts/08_carrier_trace.py
Output: export/carrier_trace_58702.png  (sheet: original · edge trace · pixel contour)
        data/carrier_trace_58702.json   (parameters per carrier, for reproducibility)
"""
import json, os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
D = json.load(open(os.path.join(ROOT, "data", "paris_translation.json"), encoding="utf-8"))
IM = Image.open(os.path.join(ROOT, "images", "58702.jpg")).convert("L")
FONT = ImageFont.truetype("C:/Windows/Fonts/msyh.ttc", 18)
FONT_S = ImageFont.truetype("C:/Windows/Fonts/msyh.ttc", 13)
CELL_H, MAX_W, PAD = 300, 330, 26

def crop(box):
    return IM.crop(tuple(box))

def canny(g, sigma=1.2, hi_pct=88, lo_ratio=0.45):
    a = np.asarray(g.filter(ImageFilter.GaussianBlur(sigma)), dtype=np.float32)
    gx = np.zeros_like(a); gy = np.zeros_like(a)
    gx[1:-1, 1:-1] = (a[:-2, 2:] + 2 * a[1:-1, 2:] + a[2:, 2:]) - (a[:-2, :-2] + 2 * a[1:-1, :-2] + a[2:, :-2])
    gy[1:-1, 1:-1] = (a[2:, :-2] + 2 * a[2:, 1:-1] + a[2:, 2:]) - (a[:-2, :-2] + 2 * a[:-2, 1:-1] + a[:-2, 2:])
    mag = np.hypot(gx, gy); ang = (np.rad2deg(np.arctan2(gy, gx)) + 180) % 180
    nms = np.zeros_like(mag)
    for (lo, hi), (dy, dx) in [((0, 22.5), (0, 1)), ((157.5, 180), (0, 1)), ((22.5, 67.5), (1, 1)), ((67.5, 112.5), (1, 0)), ((112.5, 157.5), (1, -1))]:
        m = (ang >= lo) & (ang < hi)
        f = np.roll(np.roll(mag, dy, 0), dx, 1); b = np.roll(np.roll(mag, -dy, 0), -dx, 1)
        keep = m & (mag >= f) & (mag >= b); nms[keep] = mag[keep]
    hi = np.percentile(nms[nms > 0], hi_pct) if (nms > 0).any() else 1; lo = hi * lo_ratio
    strong = nms >= hi; weak = nms >= lo
    for _ in range(60):                                    # hysteresis: grow strong edges along weak ones
        grow = strong.copy()
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                grow |= np.roll(np.roll(strong, dy, 0), dx, 1)
        grow &= weak
        if (grow == strong).all(): break
        strong = grow
    return strong, {"sigma": sigma, "hi_percentile": hi_pct, "lo_ratio": lo_ratio}

def binarize(g, sigma=1.5):
    a = np.asarray(g.filter(ImageFilter.GaussianBlur(sigma)), dtype=np.float32)
    # Otsu threshold
    hist, edges = np.histogram(a, bins=64); p = hist / hist.sum(); mids = (edges[:-1] + edges[1:]) / 2
    best, t = -1, mids[len(mids) // 2]
    for i in range(1, 64):
        w0, w1 = p[:i].sum(), p[i:].sum()
        if w0 == 0 or w1 == 0: continue
        m0, m1 = (p[:i] * mids[:i]).sum() / w0, (p[i:] * mids[i:]).sum() / w1
        v = w0 * w1 * (m0 - m1) ** 2
        if v > best: best, t = v, mids[i]
    return a < t, {"sigma": sigma, "otsu_threshold": round(float(t), 1)}

def render_edges(mask, s):
    h, w = mask.shape; out = Image.new("L", (w * s, h * s), 255); d = ImageDraw.Draw(out)
    ys, xs = np.nonzero(mask)
    for y, x in zip(ys, xs): d.rectangle([x * s, y * s, x * s + s - 1, y * s + s - 1], fill=20)
    return out

def render_contour(mask, s):
    h, w = mask.shape; out = Image.new("L", (w * s, h * s), 255); d = ImageDraw.Draw(out)
    v = mask[:, 1:] != mask[:, :-1]                         # vertical pixel edges
    for y, x in zip(*np.nonzero(v)): d.line([((x + 1) * s, y * s), ((x + 1) * s, (y + 1) * s)], fill=20, width=1)
    hz = mask[1:, :] != mask[:-1, :]                        # horizontal pixel edges
    for y, x in zip(*np.nonzero(hz)): d.line([(x * s, (y + 1) * s), ((x + 1) * s, (y + 1) * s)], fill=20, width=1)
    return out

def fit(img, s_nearest):
    w, h = img.size; k = min(CELL_H / h, MAX_W / w)
    return img.resize((max(1, int(w * k)), max(1, int(h * k))), Image.NEAREST if s_nearest else Image.LANCZOS)

def hcat(imgs, gap=8):
    W = sum(i.width for i in imgs) + gap * (len(imgs) - 1); H = max(i.height for i in imgs)
    out = Image.new("L", (W, H), 255); x = 0
    for i in imgs: out.paste(i, (x, H - i.height)); x += i.width + gap
    return out

def main():
    rows, log = [], {}
    for c in [c for c in D["C"] if not c.get("excluded")]:
        parts_o, parts_e, parts_c, par = [], [], [], []
        for box in c["boxes"]:
            g = crop(box); h = g.height
            s = max(1, round(CELL_H / max(h, 1) / (len(c["boxes"]))))      # integer upscale keeps the pixel grain
            e, pe = canny(g); m, pm = binarize(g)
            parts_o.append(g.resize((g.width * s, g.height * s), Image.NEAREST))
            parts_e.append(render_edges(e, s)); parts_c.append(render_contour(m, s)); par.append({"box": box, "canny": pe, "contour": pm, "upscale": s})
        o, e, k = (fit(hcat(p), True) for p in (parts_o, parts_e, parts_c))
        rows.append((c, o, e, k)); log[c["id"]] = par
    colw = [max(r[i].width for r in rows) for i in (1, 2, 3)]
    W = PAD * 2 + 210 + sum(colw) + PAD * 3; H = 120 + sum(max(r[1].height, r[2].height, r[3].height) + 60 for r in rows)
    sheet = Image.new("L", (W, H), 255); d = ImageDraw.Draw(sheet)
    d.text((PAD, 28), "The Dream of Paris · 可见载体由机器从像素描出", font=FONT, fill=0)
    x0 = PAD + 210
    for i, t in enumerate(["原画裁切（灰度）", "A  边缘描线（Canny）", "B  像素轮廓（阈值 + 阶梯边界）"]):
        d.text((x0 + sum(colw[:i]) + PAD * i, 76), t, font=FONT_S, fill=110)
    y = 104
    for c, o, e, k in rows:
        hgt = max(o.height, e.height, k.height)
        d.line([(PAD, y - 8), (W - PAD, y - 8)], fill=210)
        d.text((PAD, y), f'{c["id"]}  {c["zh"]}', font=FONT_S, fill=0)
        d.text((PAD, y + 20), f'n = {c["n"]} · x = {c["x"]:.2f}', font=FONT_S, fill=130)
        for i, im in enumerate((o, e, k)):
            sheet.paste(im, (x0 + sum(colw[:i]) + PAD * i, y))
        y += hgt + 60
    os.makedirs(os.path.join(ROOT, "export"), exist_ok=True)
    out = os.path.join(ROOT, "export", "carrier_trace_58702.png"); sheet.save(out)
    json.dump(log, open(os.path.join(ROOT, "data", "carrier_trace_58702.json"), "w", encoding="utf-8"), indent=1)
    print(out, sheet.size)

if __name__ == "__main__":
    main()
