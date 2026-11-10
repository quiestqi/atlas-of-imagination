"""Exp 01 · The Dream of Paris drawn with grammar v2 (one artwork).

Grammar v2 (web/grammar_sheet_v2.svg):
  C  = machine edge trace (Canny) of the carrier's own crop, hanging below the picture line; anchor dot on the line
  R  = broken circle; cut pattern = kind; gap faces the first carrier/referent that reaches it; radius ∝ text in-degree
  O  = dot-terminated line (from C) or tangent belt (between R) + one transformation; thick = text evidence
Placement (oblique projection of the three fixed axes):
  x = position in the original picture → horizontal
  y = time (−1 / 0 / +1 / +2)           → vertical
  z = steps from the visible            → receding up-right
Carriers sit on the picture line (y = 0, z = 0). Where traces would overlap they are nudged sideways;
a hairline leader keeps the true x visible.

Usage:  .venv/Scripts/python -I -X utf8 scripts/09_paris_score_v2.py   →   web/paris_score_v2.svg
"""
import math, os, sys, importlib
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
tr = importlib.import_module("08_carrier_trace")
D = tr.D
ROOT = tr.ROOT

INK, GREY, MUTE = "#111", "#c9c9c9", "#8a8a8a"
TH, HL = 1.8, 0.7
WD, HT = 1600, 1060
X0, WX = 150, 1150              # x axis
BASE, SY = 700, 165             # screen y of time 0, pixels per time unit
ZDX, ZDY = 118, -64             # one z step on screen

def f(v): return f"{v:.2f}".rstrip("0").rstrip(".")
def S(x, y, z): return (X0 + x * WX + z * ZDX, BASE - y * SY + z * ZDY)
def P(c, r, a): return (c[0] + r * math.cos(a), c[1] + r * math.sin(a))
def ang(a, b): return math.atan2(b[1] - a[1], b[0] - a[0])
def toward(a, b, d): t = ang(a, b); return (a[0] + d * math.cos(t), a[1] + d * math.sin(t))
def dot(p, r=4.0, col=INK): return f'<circle cx="{f(p[0])}" cy="{f(p[1])}" r="{f(r)}" fill="{col}" stroke="none"/>'
def line(a, b, w=TH, col=INK, extra=""): return f'<line x1="{f(a[0])}" y1="{f(a[1])}" x2="{f(b[0])}" y2="{f(b[1])}" stroke="{col}" stroke-width="{w}" {extra}/>'
def arc(c, r, a0, a1, w=TH):
    p0, p1 = P(c, r, a0), P(c, r, a1); large = 1 if (a1 - a0) % (2 * math.pi) > math.pi else 0
    return f'<path d="M{f(p0[0])},{f(p0[1])} A{f(r)},{f(r)} 0 {large} 1 {f(p1[0])},{f(p1[1])}" stroke="{INK}" stroke-width="{w}" fill="none"/>'
def text(p, s, size=12, col=INK, anchor="start", weight=400):
    return f'<text x="{f(p[0])}" y="{f(p[1])}" font-size="{size}" fill="{col}" text-anchor="{anchor}" font-weight="{weight}">{s}</text>'

# ── R glyphs (same cut patterns as the sheet) ──
GAP = 0.55
def R_glyph(kind, c, r, g, w=TH):
    if kind == "being": return arc(c, r, g + GAP, g + 2 * math.pi - GAP, w)
    if kind == "experience": return arc(c, r, g + GAP, g + math.pi - 0.18, w) + arc(c, r * 0.82, g + math.pi + 0.18, g + 2 * math.pi - GAP, w)
    if kind == "event": return arc(c, r, g + math.pi / 2, g + 3 * math.pi / 2, w)
    if kind == "concept": return "".join(arc(c, r, g + k * math.pi / 2 + 0.32, g + (k + 1) * math.pi / 2 - 0.32, w) for k in range(4))
    return arc(c, r, 0, 2 * math.pi - 0.01, w)

def belt(c1, r1, c2, r2, crossed=False, w=TH):
    d = math.dist(c1, c2); t = ang(c1, c2); s = ""
    b = math.acos(max(-1, min(1, ((r1 + r2) if crossed else (r1 - r2)) / d)))
    for sg in (1, -1):
        s += line(P(c1, r1, t + sg * b), P(c2, r2, t + sg * b + (math.pi if crossed else 0)), w)
    return s

# ── data ──
C = {c["id"]: c for c in D["C"] if not c.get("excluded")}
R = {r["id"]: r for r in D["R"] if not r.get("excluded")}
LIVE = [o for o in D["O"] if o["evidence"] == "text"]
W_IMG = 843

def rpos(r): return S(r["x"], r["time"], r["z"])
def rrad(r): return 13 + 6 * r["in_text_ops"]

# carrier anchors: one per body (box), at that body's own x on the picture line
ANCH = {}
for cid, c in C.items():
    ANCH[cid] = [S(((b[0] + b[2]) / 2) / W_IMG, 0, 0) for b in c["boxes"]]

# ── traces (Canny), one per box; C5 reuses C1's trace ──
def trace_svg(box, cx, top, h):
    mask, _ = tr.canny(tr.crop(box)); H, Wm = mask.shape; k = h / H; x0 = cx - Wm * k / 2
    ys, xs = np.nonzero(mask); px = 1.1
    return "".join(f'<rect x="{f(x0 + x * k)}" y="{f(top + y * k)}" width="{f(px)}" height="{f(px)}" fill="{INK}"/>' for y, x in zip(ys, xs)), Wm * k

def layout_traces():
    items = []   # (cid, box, true_x, height)
    seen = set()
    for cid, c in C.items():
        for i, b in enumerate(c["boxes"]):
            key = tuple(b)
            if key in seen: continue
            seen.add(key)
            h = max(40, min(150, (b[3] - b[1]) * 0.2))
            items.append([cid, b, S(((b[0] + b[2]) / 2) / W_IMG, 0, 0)[0], h, None])
    items.sort(key=lambda t: t[2])
    # widths, then nudge apart
    for it in items:
        mask, _ = tr.canny(tr.crop(it[1])); H, Wm = mask.shape; it[4] = Wm * it[3] / H
    xs = [it[2] for it in items]
    for _ in range(200):
        moved = False
        for i in range(1, len(items)):
            need = (items[i - 1][4] + items[i][4]) / 2 + 22
            if xs[i] - xs[i - 1] < need:
                push = (need - (xs[i] - xs[i - 1])) / 2; xs[i] += push; xs[i - 1] -= push; moved = True
        if not moved: break
    return [(it[0], it[1], it[2], it[3], xs[i]) for i, it in enumerate(items)]

# ── operation phrases with arbitrary endpoints ──
def ph_dline(a, b, w=TH): return line(a, b, w) + dot(a, 4) + dot(b, 2.4)
def ph_externalize(a, b):
    t = ang(a, b); s = ""
    for r in (14, 24, 34):
        s += arc(a, r, t - 0.62, t + 0.62) + dot(P(a, r, t - 0.62), 2.2) + dot(P(a, r, t + 0.62), 2.2)
    return s + ph_dline(a, b)
def ph_inscribe(a, b, n):
    t = ang(a, b); nv = (-math.sin(t), math.cos(t)); s = ph_dline(a, b)
    for k in range(n):
        p = toward(a, b, 42 + k * 14); s += line((p[0] - nv[0] * 10, p[1] - nv[1] * 10), (p[0] + nv[0] * 10, p[1] + nv[1] * 10))
    return s
def ph_embody(anchors, b): return "".join(line(p, b) + dot(p, 4) for p in anchors) + dot(b, 2.4)
def ph_substitute(a, b):
    t = ang(a, b); n = (-math.sin(t) * 4.5, math.cos(t) * 4.5)
    return "".join(line((a[0] + s * n[0], a[1] + s * n[1]), (b[0] + s * n[0], b[1] + s * n[1])) + dot((a[0] + s * n[0], a[1] + s * n[1]), 3) for s in (1, -1)) + dot(b, 2.4)
def ph_anachronism(a, b):
    t = ang(a, b); L = math.dist(a, b); m = toward(a, b, L * 0.42); r = 13
    c1, c2 = toward(m, a, r), toward(m, b, r)
    return (line(a, toward(m, a, 2 * r)) + dot(a, 4) + arc(c1, r, t + math.pi, t + 2 * math.pi) + arc(c2, r, t, t + math.pi)
            + line(toward(m, b, 2 * r), b) + dot(b, 2.4))
def ph_depth(a, b):
    s = dot(a, 4); L = math.dist(a, b); x, gap = 0.0, 8.0
    while True:
        x += gap; gap *= 1.16
        if x >= L - 4: break
        s += dot(toward(a, b, x), 2.3)
    return s + dot(b, 2.4)
def ph_contrast(a, b):
    m = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2); t = ang(a, b); r = 16
    return (line(a, toward(m, a, r * 1.4), HL) + line(toward(m, b, r * 1.4), b, HL) +
            arc(toward(m, a, r * 1.4), r, t - math.pi / 2, t + math.pi / 2) + arc(toward(m, b, r * 1.4), r, t + math.pi / 2, t + 3 * math.pi / 2))

def main():
    out = []
    # guides: time levels at z = 0 and their receding edges (hairline grid)
    for y in (-1, 0, 1, 2):
        a, b = S(0, y, 0), S(1, y, 0)
        out.append(line(a, b, HL if y else 1.1, INK if y == 0 else GREY))
        out.append(line(b, S(1, y, 3.3), HL, GREY)); out.append(line(a, S(0, y, 3.3), HL, GREY))
        out.append(text((a[0] - 14, a[1] + 4), {-1: "过去 −1", 0: "此刻 0", 1: "未来 +1", 2: "超时间 +2"}[y], 11, MUTE, "end"))
    for z in (1, 2, 3):
        out.append(line(S(0, -1, z), S(1, -1, z), HL, "#ececec"))
        p = S(1, -1, z); out.append(text((p[0] + 8, p[1] + 4), f"{z} 步", 11, MUTE))
    out.append(line(S(0, -1, 0), S(0, 2, 0), HL, GREY)); out.append(line(S(1, -1, 0), S(1, 2, 0), HL, GREY))
    p = S(1, -1, 0); out.append(text((p[0] + 8, p[1] + 4), "0 可见", 11, MUTE))
    for i in range(5):
        p = S(i / 4, -1, 0); out.append(line(p, (p[0], p[1] + 5), HL, MUTE)); out.append(text((p[0], p[1] + 18), f"{i / 4:.2f}", 10, MUTE, "middle"))
    p = S(0.5, -1, 0); out.append(text((p[0], p[1] + 38), "x　画面位置　左 → 右", 12, INK, "middle"))
    p = S(0, 2, 0); out.append(text((p[0] - 14, p[1] - 26), "y　时间", 12, INK, "end"))
    p = S(1, -1, 3.3); out.append(text((p[0] + 8, p[1] - 10), "z　离可见世界的步数", 12, INK))

    # carriers: traces hang below the picture line; leader from true x
    tr_svg = []
    for cid, box, true_x, h, x in layout_traces():
        g, w = trace_svg(box, x, BASE + 16, h)
        tr_svg.append(f'<g opacity="0.95">{g}</g>')
        tr_svg.append(line((true_x, BASE), (x, BASE + 12), HL, MUTE))
        tr_svg.append(text((x, BASE + 16 + h + 16), C[cid]["zh"], 11, "#333", "middle"))
    out += tr_svg

    # coordinate projections for R (hairlines)
    for r in R.values():
        c = rpos(r); g0 = S(r["x"], 0, r["z"]); g1 = S(r["x"], 0, 0)
        out.append(line(c, g0, HL, GREY, 'stroke-dasharray="2 4"')); out.append(line(g0, g1, HL, GREY, 'stroke-dasharray="2 4"'))

    # operations
    for o in LIVE:
        t, fr, to = o["type"], o["from"], o["to"]
        if t == "contrast":
            out.append(ph_contrast(ANCH[fr][0], ANCH[to][1])); continue
        if fr in R and to in R:
            c1, r1, c2, r2 = rpos(R[fr]), rrad(R[fr]), rpos(R[to]), rrad(R[to])
            if t == "trigger": out.append(belt(c1, r1, c2, r2, crossed=True))
            elif t == "contain":
                out.append(belt(c1, r1 * 0.55, c2, r2 * 0.55, w=HL + 0.5))
            else: out.append(belt(c1, r1, c2, r2))
            continue
        b0 = rpos(R[to]); a = ANCH[fr][0]; b = toward(b0, a, rrad(R[to]))
        if t == "externalize": out.append(ph_externalize(a, b))
        elif t == "inscribe": out.append(ph_inscribe(a, b, C[fr].get("words", 1)))
        elif t == "embody": out.append(ph_embody(ANCH[fr], toward(b0, (sum(p[0] for p in ANCH[fr]) / len(ANCH[fr]), BASE), rrad(R[to]))))
        elif t == "substitute": out.append(ph_substitute(a, b))
        elif t == "anachronism": out.append(ph_anachronism(a, b))
        elif t == "depth_time": out.append(ph_depth(a, b))
        else: out.append(ph_dline(a, b))

    # referents: gap faces the first thing that reaches them; containers hold scaled copies of what they contain
    for r in R.values():
        c, rad = rpos(r), rrad(r)
        src = next((o["from"] for o in LIVE if o["to"] == r["id"]), None)
        sp = ANCH[src][0] if src in C else (rpos(R[src]) if src in R else (c[0] - 1, c[1] + 1))
        out.append(R_glyph(r["kind"], c, rad, ang(c, sp)))
        kids = [R[o["to"]] for o in LIVE if o["type"] == "contain" and o["from"] == r["id"]]
        for i, k in enumerate(kids):
            kc = (c[0] + (i - (len(kids) - 1) / 2) * rad * 0.62, c[1]); out.append(R_glyph(k["kind"], kc, rad * 0.26, 0, 1.4))
        left = r["id"] in ("R3", "R2")
        lx = c[0] - rad - 10 if left else c[0] + rad + 10; an = "end" if left else "start"
        out.append(text((lx, c[1] - 4), r["zh"], 13, INK, an))
        out.append(text((lx, c[1] + 12), f'{r["id"]} · ({r["x"]:.2f}, {r["time"]:+d}, {r["z"]})', 10, MUTE, an))

    A = D["artwork"]
    head = [text((60, 60), f'{A["title"]}　·　Imagination Score（语法 v2）', 20),
            text((60, 84), f'AIC {A["aic_id"]} · {A["date"]} · C = 机器边缘描线（Canny） · R = 断圆 · O = 点收尾的线 / 切线皮带 · 粗线 = 文本证据', 12, MUTE),
            text((60, HT - 34), "签名（文本证据）：" + " · ".join(f"{k} {v}" for k, v in D["signature"].items()) + f" · 共 {len(LIVE)}　｜　推断 X1（心 = 爱）不画　｜　C1、C5 都框在骑士身上，两个框大部分重叠", 11, MUTE)]
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {WD} {HT}" width="{WD}" height="{HT}" '
           f'font-family="Microsoft YaHei, PingFang SC, Noto Sans CJK SC, sans-serif" fill="none" stroke-linecap="butt">'
           f'<rect width="{WD}" height="{HT}" fill="#fff"/>' + "".join(head + out) + '</svg>')
    p = os.path.join(ROOT, "web", "paris_score_v2.svg"); open(p, "w", encoding="utf-8").write(svg); print(p)

if __name__ == "__main__":
    main()
