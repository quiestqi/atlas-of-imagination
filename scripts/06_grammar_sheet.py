"""Exp 01 · grammar ↔ symbol reference sheet (one page, black ink on white).

Each cell: the symbol, its name, the grammar rule, and the data field that drives it.
Usage:  python -I -X utf8 scripts/06_grammar_sheet.py   →   web/grammar_sheet.svg
"""
import math, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INK, MUTE, W_LINE = "#111", "#8a8a8a", 1.1
COLS, CW, CH, GX = 5, 236, 136, 40          # columns, cell width/height, left margin
GH = 92                                     # glyph area height inside a cell

def f(v): return f"{v:.2f}".rstrip("0").rstrip(".")
def line(a, b, extra=""): return f'<line x1="{f(a[0])}" y1="{f(a[1])}" x2="{f(b[0])}" y2="{f(b[1])}" {extra}/>'
def dot(p, r=3.2, fill=INK): return f'<circle cx="{f(p[0])}" cy="{f(p[1])}" r="{r}" fill="{fill}" stroke="none"/>'
def circ(p, r, extra=""): return f'<circle cx="{f(p[0])}" cy="{f(p[1])}" r="{f(r)}" {extra}/>'
def ell(p, rx, ry, extra=""): return f'<ellipse cx="{f(p[0])}" cy="{f(p[1])}" rx="{f(rx)}" ry="{f(ry)}" {extra}/>'
def path(d, extra=""): return f'<path d="{d}" {extra}/>'
def towards(a, b, d):
    dx, dy = b[0] - a[0], b[1] - a[1]; L = math.hypot(dx, dy); return (a[0] + dx / L * d, a[1] + dy / L * d)
def arc_pts(c, r, a0, a1, n=40): return [(c[0] + r * math.cos(a0 + (a1 - a0) * i / n), c[1] + r * math.sin(a0 + (a1 - a0) * i / n)) for i in range(n + 1)]
def poly(pts, extra=""): return path("M" + " L".join(f"{f(x)},{f(y)}" for x, y in pts), extra)
def quad(a, c, b): return f"M{f(a[0])},{f(a[1])} Q{f(c[0])},{f(c[1])} {f(b[0])},{f(b[1])}"

# standard anchors inside a glyph box (0..CW, 0..GH)
CA, RB, RR = (60, 62), (270, 34), 13        # carrier point, referent centre, referent radius
def to_R(a=CA, c=RB, r=RR): return towards(c, a, r)    # point on R's rim facing a

def R(c=RB, r=RR): return circ(c, r)

# ───────── glyphs ─────────
G = {}
G["point"] = dot((170, 46), 3.4)
G["circle"] = circ((170, 46), 20)
G["line"] = line((70, 46), (270, 46))
G["arc"] = path(quad((70, 62), (170, -6), (270, 62)))

G["being"] = circ((170, 46), 20) + dot((170, 46), 1.8)
G["experience"] = ell((170, 46), 34, 11)
G["event"] = poly(arc_pts((170, 58), 22, math.pi, 2 * math.pi))
G["concept"] = circ((170, 46), 20) + ell((170, 46), 7, 20)

G["ev_text"] = line((70, 46), (270, 46))
G["ev_image"] = line((70, 46), (270, 46), 'stroke-dasharray="6 5"')
G["ev_infer"] = f'<text x="170" y="50" text-anchor="middle" font-size="11" fill="{MUTE}">（不画）</text>'

G["t_repeat"] = "".join(dot((110 + i * 30, 46), 3) for i in range(5))
G["t_shift"] = line((80, 38), (260, 38)) + line((80, 54), (260, 54))
G["t_rotate"] = circ((110, 46), 20) + ell((230, 46), 30, 9)
G["t_reverse"] = poly([(70, 58), (190, 58)] + arc_pts((190, 44), 14, math.pi / 2, -math.pi / 2)[::1] + [(140, 30)])
G["t_scale"] = "".join(circ((170, 46), r) for r in (5, 12, 20, 28))

# operation phrases — all built from point / line / arc / circle
def op_externalize():
    s = dot(CA) + line(CA, to_R()) + R()
    for r in (9, 16, 23):                                    # 1:2:3 opening toward R
        ang = math.atan2(RB[1] - CA[1], RB[0] - CA[0])
        s += poly(arc_pts(CA, r, ang - 0.75, ang + 0.75, 24))
    return s
def op_inscribe():
    s = dot(CA) + line(CA, to_R()) + R()
    ang = math.atan2(RB[1] - CA[1], RB[0] - CA[0]); nx, ny = -math.sin(ang), math.cos(ang)
    for d in (30, 40):                                       # n = number of inscribed words
        p = towards(CA, RB, d); s += line((p[0] - nx * 8, p[1] - ny * 8), (p[0] + nx * 8, p[1] + ny * 8))
    return s
def op_embody():
    s = R()
    for i in range(3):                                       # n = number of figures
        p = (50 + i * 20, 70); s += dot(p) + line(p, to_R(p))
    return s
def op_substitute():
    a, b = CA, to_R(); ang = math.atan2(b[1] - a[1], b[0] - a[0]); nx, ny = -math.sin(ang) * 3, math.cos(ang) * 3
    return dot(CA) + line((a[0] + nx, a[1] + ny), (b[0] + nx, b[1] + ny)) + line((a[0] - nx, a[1] - ny), (b[0] - nx, b[1] - ny)) + R()
def op_anachronism():
    c, r = (270, 46), 13; b = (c[0] - r, c[1])
    return dot((60, 46)) + line((60, 46), b) + poly([(150, 46)] + arc_pts((150, 34), 12, math.pi / 2, -math.pi / 2) + [(118, 22)]) + R(c, r)
def op_depth():
    c, r = (270, 30), 13
    return dot((60, 64)) + poly([(60, 64), (150, 64), (150, 30), (c[0] - r, 30)]) + R(c, r)
def op_foreshadow():
    a, c, r = (70, 66), (270, 30), 13
    return circ(a, 10) + path(quad(towards(a, (150, -10), 10), (150, -10), towards(c, (150, -10), r))) + R(c, r)
def op_trigger():
    a, c, r = (70, 50), (270, 50), 13
    return circ(a, 10) + path(quad((80, 46), (170, 2), (257, 46))) + path(quad((80, 54), (170, 18), (257, 54))) + R(c, r)
def op_contain():
    p = (100, 56); c, r = (270, 30), 13
    return ell(p, 42, 13) + circ((88, 56), 4) + circ((112, 56), 4) + path(quad((142, 54), (200, 6), towards(c, (200, 6), r))) + R(c, r)
def op_contrast():
    a, b = (70, 46), (270, 46)
    return dot(a) + dot(b) + path(quad(a, (170, 6), b)) + path(quad(a, (170, 86), b))
for k, fn in [("externalize", op_externalize), ("inscribe", op_inscribe), ("embody", op_embody), ("substitute", op_substitute),
              ("anachronism", op_anachronism), ("depth_time", op_depth), ("foreshadow", op_foreshadow), ("trigger", op_trigger),
              ("contain", op_contain), ("contrast", op_contrast)]:
    G[k] = fn()

# ───────── sheet content: (glyph, name, rule, data) ─────────
SECTIONS = [
    ("1 · 基本图形", "只有四种元素，其余全部由它们组合而成", [
        ("point", "点 ●", "C 可见载体", "有身体、在画面上的东西"),
        ("circle", "圆 ○", "R 缺席的对象", "一圈线围着空处：不在场"),
        ("line", "直线", "从 C 出发的操作", "起点是可见的"),
        ("arc", "弧", "从 R 出发的操作", "缺席引出缺席，没有落脚点"),
    ]),
    ("2 · R 的种类　旋转", "同一个圆换朝向", [
        ("being", "存在者", "立圆 + 圆心点", "kind = being"),
        ("experience", "经验", "平圆（水平，可容纳）", "kind = experience"),
        ("event", "事件", "半圆（尚未完成）", "kind = event"),
        ("concept", "概念", "两个正交的圆（无形体）", "kind = concept"),
    ]),
    ("3 · 证据　线型", "E 决定线怎么画，不决定画什么", [
        ("ev_text", "文本", "实线", "AIC 描述原文，计入签名"),
        ("ev_image", "图像", "虚线 = 短线重复 + 间隔", "机器看图得出"),
        ("ev_infer", "推断", "不画", "只列在表里，不进谱"),
    ]),
    ("4 · 变换　Lucinda Childs", "每种变换都由一个数据字段驱动", [
        ("t_repeat", "重复 ×n", "同一元素出现 n 次", "形体数 · 铭文词数"),
        ("t_shift", "平移", "复制后偏移", "一物两面 · 景深层数"),
        ("t_rotate", "旋转", "换朝向", "R 的种类"),
        ("t_reverse", "反向", "路径折回", "时间方向相反"),
        ("t_scale", "缩放", "放大或缩小", "R 的入度 · 包含关系"),
    ]),
    ("5 · 操作短语", "直线或弧 + 一个变换", [
        ("externalize", "外化", "直线 + 三段弧 1:2:3 放大", "内在向外扩散（固定形）"),
        ("inscribe", "铭写", "直线 + n 条垂直短线", "n = 铭文词数"),
        ("embody", "赋形", "n 条直线汇聚到一个 R", "n = 形体数"),
        ("substitute", "象征替代", "直线 ×2 平移", "符号 / 所指"),
        ("anachronism", "时代错置", "直线 + 一次折回", "时间方向相反"),
        ("depth_time", "纵深 = 时间", "直线 + 台阶", "台阶数 = 景深层"),
        ("foreshadow", "预示", "弧，向上（未来）弯", "R → 尚未发生的 R"),
        ("trigger", "引发", "弧 ×2 错开", "连锁：因 → 果"),
        ("contain", "包含", "平圆内嵌缩小的子 R + 弧", "R 在 R 里"),
        ("contrast", "对照", "两条镜像弧", "两个载体互相衬托"),
    ]),
]

def main():
    out, y = [], 0
    Wd = GX * 2 + COLS * CW
    y = 120
    out.append(f'<text x="{GX}" y="62" font-size="22" fill="{INK}">Imagination Score · 语法与符号对照</text>')
    out.append(f'<text x="{GX}" y="88" font-size="12" fill="{MUTE}">Exp 01 · R 缺席的对象 / C 可见载体 / O 结构操作 / E 证据 · 坐标 x = 画面位置，y = 时间，z = 离可见世界的步数</text>')
    for title, sub, cells in SECTIONS:
        y += 30
        out.append(f'<line x1="{GX}" y1="{y}" x2="{Wd - GX}" y2="{y}" stroke="{INK}" stroke-width="1.2"/>')
        out.append(f'<text x="{GX}" y="{y + 22}" font-size="14" font-weight="600" fill="{INK}">{title}</text>')
        out.append(f'<text x="{GX + 210}" y="{y + 22}" font-size="11.5" fill="{MUTE}">{sub}</text>')
        y += 36
        for i, (g, name, rule, data) in enumerate(cells):
            cx, cy = GX + (i % COLS) * CW, y + (i // COLS) * CH
            out.append(f'<g transform="translate({cx},{cy})">')
            sc = (CW - 12) / 330; gh = GH * sc
            out.append(f'<rect x="6" y="0" width="{CW - 12}" height="{f(gh)}" fill="none" stroke="#e6e6e6"/>')
            out.append(f'<g transform="translate(6,0) scale({f(sc)})" fill="none" stroke="{INK}" stroke-width="{f(W_LINE / sc)}" stroke-linecap="round" stroke-linejoin="round">{G[g]}</g>')
            out.append(f'<text x="8" y="{f(gh + 20)}" font-size="13.5" fill="{INK}">{name}</text>')
            out.append(f'<text x="8" y="{f(gh + 38)}" font-size="11.5" fill="#333">{rule}</text>')
            out.append(f'<text x="8" y="{f(gh + 55)}" font-size="11" fill="{MUTE}">{data}</text>')
            out.append('</g>')
        y += math.ceil(len(cells) / COLS) * CH
    H = y + 40
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {Wd} {H}" width="{Wd}" height="{H}" '
           f'font-family="Microsoft YaHei, PingFang SC, Noto Sans CJK SC, sans-serif">'
           f'<rect width="{Wd}" height="{H}" fill="#fff"/>' + "".join(out) + '</svg>')
    p = os.path.join(ROOT, "web", "grammar_sheet.svg")
    open(p, "w", encoding="utf-8").write(svg)
    print(p, Wd, "x", H)

if __name__ == "__main__":
    main()
