"""Convert data/scores.json (Processing sketch data) into point clouds for TouchDesigner.

Same layout rules as atlas_score.pde (see processing/atlas_score/README.md), but every glyph is sampled
into points. Output: td/points/score_<n>_<aic_id>.csv with TouchDesigner DAT-to-SOP style headers,
plus td/points/index.csv and a quick preview PNG per artwork (pure stdlib, no numpy).

Usage:  python -I td/build_points.py
"""
import csv, json, math, random, struct, zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SCORES = ROOT.parent / "processing" / "atlas_score" / "data" / "scores.json"
OUT = ROOT / "points"
OUT.mkdir(exist_ok=True)
random.seed(7)

# evidence → brightness (B/W). Only text evidence is full white.
EV_ALPHA = {"text": 1.0, "image": 0.38, "inference": 0.12}


# ───────── vector helpers (y is UP, like TouchDesigner) ─────────
def add(a, b): return (a[0] + b[0], a[1] + b[1], a[2] + b[2])
def sub(a, b): return (a[0] - b[0], a[1] - b[1], a[2] - b[2])
def mul(a, s): return (a[0] * s, a[1] * s, a[2] * s)
def lerp(a, b, t): return add(a, mul(sub(b, a), t))
def length(a): return math.sqrt(a[0] ** 2 + a[1] ** 2 + a[2] ** 2)
def norm(a):
    l = length(a) or 1.0
    return mul(a, 1 / l)
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
def basis(d):
    d = norm(d)
    up = (0, 1, 0) if abs(d[1]) < 0.9 else (1, 0, 0)
    u = norm(cross(d, up)); v = norm(cross(d, u))
    return u, v


# ───────── layout (port of atlas_score.pde rules 1–8) ─────────
def radius_for(r, has_children):
    k = r["kind"]
    if k == "experience": return 1.6 if has_children else 0.6
    if k == "world": return 1.7 if has_children else 1.1
    if k == "concept": return 0.45
    return 0.4


def layout(a):
    R, C, O = a["referents"], a["carriers"], a["ops"]
    node = {x["id"]: x for x in R + C}
    refs = {x["id"] for x in R}
    P, RAD, frame = {}, {}, False
    has = lambda t, key, i: any(o["type"] == t and o[key] == i for o in O)
    nc = len(C)
    for i, c in enumerate(C):                                     # rules 1–2
        x = (i - (nc - 1) / 2) * min(2.2, 8.0 / max(nc - 1, 1)); z = -2.8 if has("depth_time", "from", c["id"]) else 1.8
        disk = c.get("shape") == "disk"
        P[c["id"]] = (x, 0.02 if disk else 0.25, 0 if disk else z)
        RAD[c["id"]] = 2.6 if disk else 0.3
    for o in O:                                                   # rule 3
        if o["type"] == "layer":
            t = P[o["to"]]; P[o["from"]] = (t[0], t[1] + 0.9, t[2])
    lv = {i: 1 for i in refs}                                     # rule 4
    for _ in range(6):
        for o in O:
            if o["from"] in refs and o["to"] in refs: lv[o["to"]] = max(lv[o["to"]], lv[o["from"]] + 1)
    kids, by_level = {}, {}
    for r in R:
        if "parent" in r: kids.setdefault(r["parent"], []).append(r["id"])
        else: by_level.setdefault(lv[r["id"]], []).append(r["id"])
    for L in sorted(by_level):
        ids = by_level[L]; n = len(ids)
        for j, i in enumerate(ids):
            r = node[i]; x = (j - (n - 1) / 2) * 3.4; y = 2.6 + (L - 1) * 2.1; z = 0.0
            if r["absence"] == "not_yet": z = -2.4                 # rule 5
            if has("witness", "to", i): x, y, z, frame = 0, 1.9, 4.4, True   # rule 6
            if r.get("viewer"): y += 1.4; x += 3.2                 # rule 7
            if r.get("inferred"): x += 1.6; z += 1.4
            P[i] = (x, y, z); RAD[i] = radius_for(r, i in kids)
    for p, ids in kids.items():                                   # rule 8
        n = len(ids); pc = P[p]
        for j, i in enumerate(ids):
            r = node[i]; oz = -0.7 if r["absence"] == "not_yet" else 0.35
            P[i] = (pc[0] + (j - (n - 1) / 2) * 1.0, pc[1] - 0.2, pc[2] + oz); RAD[i] = radius_for(r, False)
    return node, refs, P, RAD, frame


# ───────── point sampling ─────────
class Cloud:
    def __init__(self): self.pts = []
    def add(self, p, a, size, group):
        self.pts.append((p[0], p[1], p[2], a, size, group))
    def line(self, a, b, alpha, group, density=28, dash=False, size=0.018):
        n = max(2, int(length(sub(b, a)) * density))
        for i in range(n + 1):
            t = i / n
            if dash and int(t * length(sub(b, a)) / 0.12) % 2: continue
            self.add(lerp(a, b, t), alpha, size, group)
    def ring(self, c, d, r, alpha, group, n=40, size=0.018):
        u, v = basis(d)
        for i in range(n):
            t = 2 * math.pi * i / n
            self.add(add(c, add(mul(u, math.cos(t) * r), mul(v, math.sin(t) * r))), alpha, size, group)
    def sphere_wire(self, c, r, alpha, group, lat=7, lon=10):
        for i in range(1, lat):
            phi = math.pi * i / lat; y = math.cos(phi) * r; rr = math.sin(phi) * r
            self.ring(add(c, (0, y, 0)), (0, 1, 0), rr, alpha, group, n=max(12, int(48 * rr)))
        for j in range(lon):
            th = 2 * math.pi * j / lon
            for k in range(41):
                phi = math.pi * k / 40
                self.add(add(c, (math.sin(phi) * math.cos(th) * r, math.cos(phi) * r, math.sin(phi) * math.sin(th) * r)), alpha, 0.016, group)
    def sphere_solid(self, c, r, alpha, group, n=700):
        for _ in range(n):
            z = random.uniform(-1, 1); t = random.uniform(0, 2 * math.pi); s = math.sqrt(1 - z * z)
            self.add(add(c, (s * math.cos(t) * r, z * r, s * math.sin(t) * r)), alpha, 0.02, group)
    def cube_solid(self, c, s, alpha, group, n=260):
        h = s / 2
        for _ in range(n):
            p = [random.uniform(-h, h) for _ in range(3)]; ax = random.randrange(3); p[ax] = h if random.random() < 0.5 else -h
            self.add(add(c, tuple(p)), alpha, 0.022, group)
    def octa(self, c, r, alpha, group):
        v = [(r, 0, 0), (-r, 0, 0), (0, r, 0), (0, -r, 0), (0, 0, r), (0, 0, -r)]
        for i, j in [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5), (2, 4), (4, 3), (3, 5), (5, 2)]:
            self.line(add(c, v[i]), add(c, v[j]), alpha, group)
    def cone(self, c, r, alpha, group):
        apex = add(c, (0, 0, -r * 1.3)); base = add(c, (0, 0, r * 0.6))
        self.ring(base, (0, 0, 1), r * 0.8, alpha, group)
        for i in range(12):
            t = 2 * math.pi * i / 12
            self.line(add(base, (math.cos(t) * r * 0.8, math.sin(t) * r * 0.8, 0)), apex, alpha, group, density=20)


def subs(node, refs, P, i):
    c = P[i]; k = node[i].get("count", 1) if i not in refs else 1
    if k <= 1: return [c]
    return [(c[0] + (t - (k - 1) / 2) * 0.55, c[1] - 0.08, c[2] - abs(t - (k - 1) / 2) * 0.18) for t in range(k)]


def surf(P, RAD, frm, i):
    c = P[i]; d = norm(sub(frm, c)); return add(c, mul(d, RAD[i]))


def build(a):
    node, refs, P, RAD, frame = layout(a)
    cl = Cloud()
    # ground grid (very faint) + vertical axis
    for i in range(-5, 6):
        cl.line((i, 0, -5), (i, 0, 5), 0.06, "ground", density=6); cl.line((-5, 0, i), (5, 0, i), 0.06, "ground", density=6)
    cl.line((-5, 0, -5), (-5, 6, -5), 0.2, "axis", dash=True)
    if frame:
        f = [(-4.2, 0, 2.3), (4.2, 0, 2.3), (4.2, 4.4, 2.3), (-4.2, 4.4, 2.3)]
        for k in range(4): cl.line(f[k], f[(k + 1) % 4], 0.35, "frame", dash=True)
    for c in a["carriers"]:
        i = c["id"]
        if c.get("shape") == "disk":
            cl.ring(P[i], (0, 1, 0), RAD[i], 1.0, "carrier", n=220, size=0.022)
            for k in range(72):
                t = 2 * math.pi * k / 72; r = RAD[i]; l = 0.12 if k % 6 == 0 else 0.06
                cl.line(add(P[i], (math.cos(t) * r, 0, math.sin(t) * r)), add(P[i], (math.cos(t) * (r - l), 0, math.sin(t) * (r - l))), 1.0, "carrier", density=60)
            continue
        ss = subs(node, refs, P, i)
        for q in ss: cl.cube_solid(q, 0.28 if len(ss) > 1 else 0.45, 1.0, "carrier", n=140 if len(ss) > 1 else 260)
    for r in a["referents"]:
        i = r["id"]; c = P[i]; rad = RAD[i]; al = 0.12 if r.get("inferred") else 1.0; k = r["kind"]
        if r.get("embodied"): cl.sphere_solid(c, rad, 0.75 * al, "referent")
        elif k == "concept": cl.octa(c, rad, al, "referent")
        elif k == "event": cl.cone(c, rad, al, "referent")
        elif k == "world": cl.sphere_wire(c, rad, 0.45 * al, "referent", lat=6, lon=8)
        else: cl.sphere_wire(c, rad, (0.5 if k == "experience" else 1.0) * al, "referent")
    for o in a["ops"]:
        t, f, to, ev = o["type"], o["from"], o["to"], o["evidence"]
        al = EV_ALPHA[ev]; dash = ev != "text"; g = "op_" + t
        a0 = P[f]
        if t in ("externalize", "personify"):
            ss = subs(node, refs, P, f); nl = 4 if len(ss) > 1 else 10
            for s in ss:
                b = surf(P, RAD, s, to); d = sub(b, s); u, v = basis(d)
                for kk in range(nl):
                    th = 2 * math.pi * kk / nl
                    cl.line(s, add(b, add(mul(u, math.cos(th) * 0.45), mul(v, math.sin(th) * 0.45))), al * (0.6 if len(ss) > 1 else 1), g, density=18, dash=dash)
                cl.ring(b, d, 0.45, al, g)
        elif t == "inscribe":
            b = surf(P, RAD, a0, to); cl.line(a0, b, al, g, dash=dash); u, _ = basis(sub(b, a0))
            for kk in range(1, 9):
                p = lerp(a0, b, kk / 9); cl.line(add(p, mul(u, -0.14)), add(p, mul(u, 0.14)), al, g, density=60)
        elif t == "substitute":
            a2 = surf(P, RAD, P[to], f) if f in refs else a0; b = surf(P, RAD, a2, to); d = sub(b, a2)
            cl.line(a2, b, al, g, dash=dash); cl.ring(lerp(a2, b, 0.48), d, 0.16, al, g, n=24); cl.ring(lerp(a2, b, 0.54), d, 0.16, al, g, n=24)
            u, v = basis(d); base = sub(b, mul(norm(d), 0.28))
            for kk in range(4):
                th = math.pi / 2 * kk; cl.line(add(base, add(mul(u, math.cos(th) * 0.13), mul(v, math.sin(th) * 0.13))), b, al, g, density=60)
        elif t == "synecdoche":
            b = surf(P, RAD, a0, to); d = sub(b, a0); cl.line(a0, b, al, g, dash=dash)
            for kk in range(1, 6): cl.ring(lerp(a0, b, kk / 6), d, 0.04 + kk * 0.07, al, g)
        elif t == "depth_time":
            b = surf(P, RAD, a0, to); d = sub(b, a0); cl.line(a0, b, al, g, dash=True)
            for kk in range(1, 6): cl.ring(lerp(a0, b, (kk / 6) ** 1.6), d, 0.15, al, g, n=28)
        elif t == "anachronism":
            b = surf(P, RAD, a0, to); d = sub(b, a0); u, v = basis(d); cl.line(a0, b, al * 0.6, g, dash=dash)
            for kk in range(400):
                s = kk / 400; th = s * 2 * math.pi * 6
                cl.add(add(lerp(a0, b, s), add(mul(u, math.cos(th) * 0.2), mul(v, math.sin(th) * 0.2))), al, 0.018, g)
        elif t == "juxtapose":
            b = P[to]; c = add(lerp(a0, b, 0.5), (0, 1.6, 0.6))
            for kk in range(0, 80, 2):
                s = kk / 80; cl.add(add(add(mul(a0, (1 - s) ** 2), mul(c, 2 * s * (1 - s))), mul(b, s * s)), al, 0.024, g)
        elif t == "witness":
            for s in subs(node, refs, P, f): cl.line(add(s, (0, 0.15, 0)), surf(P, RAD, s, to), al, g, dash=True)
        elif t == "impossible_viewpoint":
            c = P[to]; r = RAD[to]; eye = add(c, (3.4, 2.4, 3.0)); dr = RAD[f]
            cl.sphere_solid(eye, 0.12, al, g, n=120); cl.ring(eye, sub(c, eye), 0.3, al, g)
            for kk in range(10):
                th = 2 * math.pi * kk / 10; p = (c[0] + math.cos(th) * r, c[1], c[2] + math.sin(th) * r)
                cl.line(eye, p, al, g, density=14)
                cl.line(p, (P[f][0] + math.cos(th) * dr, P[f][1], P[f][2] + math.sin(th) * dr), al * 0.5, g, dash=True, density=14)
        elif t == "activate":
            b = surf(P, RAD, a0, to); d = sub(b, a0); cl.line(a0, b, al, g, dash=True)
            for kk in range(4): cl.ring(lerp(a0, b, (kk + 0.5) / 4), d, 0.2, al, g, n=30)
        elif t == "layer":
            b = P[to]; cl.line(a0, b, al, g, density=40); m = lerp(a0, b, 0.5)
            corners = [add(m, (-0.6, 0, -0.4)), add(m, (0.6, 0, -0.4)), add(m, (0.6, 0, 0.4)), add(m, (-0.6, 0, 0.4))]
            for kk in range(4): cl.line(corners[kk], corners[(kk + 1) % 4], al, g)
        elif t == "radiate":
            c = P[f]; r = RAD[f]
            for kk in range(12):
                th = 2 * math.pi * kk / 12; cl.line(add(c, (0, 0.01, 0)), add(c, (math.cos(th) * r, 0.01, math.sin(th) * r)), al, g, dash=dash, density=16)
        elif t == "repeat":
            ss = subs(node, refs, P, f); cl.line(ss[0], ss[-1], al, g, dash=dash); m = ss[len(ss) // 2]; cl.line(m, surf(P, RAD, m, to), al, g, dash=dash)
        elif t == "embody":
            host = node[to].get("parent", to); c = P[host]; r = RAD[host]
            for kk in range(6):
                th = 2 * math.pi * kk / 6 + 0.3; el = 0.5 - (kk % 3) * 0.4
                p = (c[0] + math.cos(th) * math.cos(el) * r, c[1] + math.sin(el) * r, c[2] + math.sin(th) * math.cos(el) * r)
                cl.sphere_solid(p, 0.13, al, g, n=60)
                cl.line((P[f][0] + math.cos(th) * r * 0.9, P[f][1], P[f][2] + math.sin(th) * r * 0.9), p, al, g, dash=True, density=14)
        else:
            b = surf(P, RAD, a0, to); cl.line(a0, b, al, g, dash=dash)
    return cl.pts


# ───────── tiny PNG preview (orthographic-ish projection, stdlib only) ─────────
def preview(pts, path, W=900, H=640):
    img = bytearray(W * H)  # black background, white points
    ry, rx = 0.65, 0.42
    for x, y, z, a, s, g in pts:
        X = x * math.cos(ry) + z * math.sin(ry); Z = -x * math.sin(ry) + z * math.cos(ry)
        Y = y * math.cos(rx) - Z * math.sin(rx); Z2 = y * math.sin(rx) + Z * math.cos(rx)
        k = 14 / (14 - Z2); px = int(W / 2 + X * 62 * k); py = int(H * 0.78 - Y * 62 * k)
        if 0 <= px < W and 0 <= py < H:
            i = py * W + px; img[i] = min(255, img[i] + int(255 * a))
    raw = b"".join(b"\x00" + bytes(img[r * W:(r + 1) * W]) for r in range(H))
    def chunk(t, d): return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 0, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    path.write_bytes(png)


def main():
    works = json.loads(SCORES.read_text(encoding="utf-8"))["artworks"]
    index = []
    for n, a in enumerate(works, 1):
        pts = build(a)
        name = f"score_{n}_{a['aic_id']}.csv"
        with open(OUT / name, "w", encoding="utf-8", newline="") as f:
            w = csv.writer(f, delimiter="\t")
            w.writerow(["P(0)", "P(1)", "P(2)", "Cd(0)", "Cd(1)", "Cd(2)", "Cd(3)", "pscale", "group"])
            for x, y, z, al, s, g in pts:
                w.writerow([f"{x:.4f}", f"{y:.4f}", f"{z:.4f}", f"{al:.3f}", f"{al:.3f}", f"{al:.3f}", f"{al:.3f}", f"{s:.4f}", g])
        preview(pts, OUT / f"preview_{n}_{a['aic_id']}.png")
        index.append([n, a["aic_id"], a["title"], name, len(pts)])
        print(f"{n} {a['aic_id']:>6} {len(pts):>6} points  {a['title']}")
    with open(OUT / "index.csv", "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, delimiter="\t"); w.writerow(["n", "aic_id", "title", "file", "points"]); w.writerows(index)


if __name__ == "__main__":
    main()
