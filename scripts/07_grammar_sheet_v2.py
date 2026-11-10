"""Exp 01 · grammar ↔ symbol reference sheet v2.

Visual language taken from the references (Lucinda Childs score sheets, dot-and-line constellation drawings,
broken-arc posters/type, circles joined by tangent belts):
    dot-terminated lines · broken circles · thick / hairline contrast · tangent belts · glyphs nested in circles

Usage:  python -I -X utf8 scripts/07_grammar_sheet_v2.py   →   web/grammar_sheet_v2.svg
"""
import math, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INK, MUTE = "#111", "#8a8a8a"
TH, HL = 3.2, 0.8                      # thick = text evidence · hairline = image evidence
COLS, CW, CH, GX, GH = 5, 236, 140, 40, 92

def f(v): return f"{v:.2f}".rstrip("0").rstrip(".")
def P(c, r, a): return (c[0] + r * math.cos(a), c[1] + r * math.sin(a))
def dot(p, r=4.2): return f'<circle cx="{f(p[0])}" cy="{f(p[1])}" r="{f(r)}" fill="{INK}" stroke="none"/>'
def line(a, b, w=TH): return f'<line x1="{f(a[0])}" y1="{f(a[1])}" x2="{f(b[0])}" y2="{f(b[1])}" stroke-width="{w}"/>'
def arc(c, r, a0, a1, w=TH):
    """circular arc from angle a0 to a1 (radians, clockwise in screen space when a1 > a0)"""
    p0, p1 = P(c, r, a0), P(c, r, a1); large = 1 if (a1 - a0) % (2 * math.pi) > math.pi else 0
    return f'<path d="M{f(p0[0])},{f(p0[1])} A{f(r)},{f(r)} 0 {large} 1 {f(p1[0])},{f(p1[1])}" stroke-width="{w}"/>'
def dline(a, b, w=TH, ends=(4.2, 2.6)):                  # dot-terminated line
    return line(a, b, w) + (dot(a, ends[0]) if ends[0] else "") + (dot(b, ends[1]) if ends[1] else "")
def ang(a, b): return math.atan2(b[1] - a[1], b[0] - a[0])
def toward(a, b, d): t = ang(a, b); return (a[0] + d * math.cos(t), a[1] + d * math.sin(t))

# ── R: a broken circle; the cut pattern says the kind, the gap faces where the operation comes from ──
GAP = 0.55
def R_being(c, r, g, w=TH):      return arc(c, r, g + GAP, g + 2 * math.pi - GAP, w)                       # ¾ ring, one gap
def R_experience(c, r, g, w=TH): return arc(c, r, g + GAP, g + math.pi - 0.18, w) + arc(c, r * 0.82, g + math.pi + 0.18, g + 2 * math.pi - GAP, w)  # split, two radii
def R_event(c, r, g, w=TH):      return arc(c, r, g + math.pi / 2, g + 3 * math.pi / 2, w)                 # half ring, open toward source
def R_concept(c, r, g, w=TH):    return "".join(arc(c, r, g + k * math.pi / 2 + 0.32, g + (k + 1) * math.pi / 2 - 0.32, w) for k in range(4))  # four quarters
RK = {"being": R_being, "experience": R_experience, "event": R_event, "concept": R_concept}

def belt(c1, r1, c2, r2, crossed=False, w=TH):
    """tangent lines joining two circles (open belt, or crossed belt)"""
    d = math.dist(c1, c2); t = ang(c1, c2); s = ""
    k = (r1 + r2) / d if crossed else (r1 - r2) / d
    b = math.acos(max(-1, min(1, k)))
    for sgn in (1, -1):
        a1 = P(c1, r1, t + sgn * b)
        a2 = P(c2, r2, t + sgn * b + (math.pi if crossed else 0))
        s += line(a1, a2, w)
    return s

CA, RC, RR = (60, 62), (268, 38), 15                      # standard carrier, referent centre, radius
def gap_to(src, c=RC): return ang(c, src)                 # gap faces the source
def rim(src, c=RC, r=RR): return toward(c, src, r)

G = {}
def trace_glyph(cid="C8", cx=165, top=4, h=84):
    """C symbol: machine edge trace (Canny, scripts/08_carrier_trace.py) of the carrier's own crop + anchor dot."""
    import sys, json as _j
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import importlib; tr = importlib.import_module("08_carrier_trace")
    c = next(c for c in tr.D["C"] if c["id"] == cid); mask, _ = tr.canny(tr.crop(c["boxes"][0]))
    import numpy as np
    H, Wm = mask.shape; k = h / H; x0 = cx - Wm * k / 2
    ys, xs = np.nonzero(mask)
    s = "".join(f'<rect x="{f(x0 + x * k)}" y="{f(top + y * k)}" width="{f(k)}" height="{f(k)}" fill="{INK}" stroke="none"/>' for y, x in zip(ys, xs))
    return s + dot((cx, top + h + 2), 3.4)
# 1 · elements
G["dot"] = trace_glyph()
G["broken"] = R_being((165, 46), 22, math.pi * 0.75)
G["dline"] = dline((70, 46), (260, 46))
G["belt"] = R_being((95, 50), 14, math.pi) + R_being((240, 42), 22, 0) + belt((95, 50), 14, (240, 42), 22)
# 2 · kinds (gap faces lower-left, where a carrier would be)
g0 = math.pi * 0.78
G["k_being"] = R_being((165, 46), 22, g0)
G["k_experience"] = R_experience((165, 46), 22, g0)
G["k_event"] = R_event((165, 46), 22, g0)
G["k_concept"] = R_concept((165, 46), 22, g0)
G["k_gap"] = dot((70, 70)) + line((70, 70), rim((70, 70), (230, 36), 22)) + R_being((230, 36), 22, gap_to((70, 70), (230, 36)))
G["k_contain"] = R_experience((165, 46), 34, g0) + R_being((152, 46), 8, 0, 2) + R_being((180, 46), 8, math.pi, 2)
# 3 · evidence
G["e_text"] = dline((70, 46), (260, 46), TH)
G["e_image"] = dline((70, 46), (260, 46), HL, (3, 1.6))
G["e_infer"] = f'<text x="165" y="50" text-anchor="middle" font-size="11" fill="{MUTE}" stroke="none">（不画）</text>'
# 4 · transformations
G["t_repeat"] = "".join(dot((105 + i * 30, 46), 4.2) for i in range(5))
G["t_shift"] = dline((80, 36), (250, 36)) + dline((80, 56), (250, 56))
G["t_rotate"] = "".join(R_being((80 + i * 56, 46), 15, i * math.pi / 2) for i in range(4))
G["t_reverse"] = arc((130, 46), 22, -math.pi / 2, math.pi / 2) + arc((200, 46), 22, math.pi / 2, 3 * math.pi / 2)
G["t_scale"] = "".join(arc((90, 46), r, -0.8, 0.8) for r in (14, 26, 38, 50)) + dot((90, 46), 4.2)

# 5 · operation phrases
def op_externalize():
    s = R_being(RC, RR, gap_to(CA)); t = ang(CA, RC)
    for i, r in enumerate((14, 24, 34)):                                  # arcs 1:2:3, dots at their ends
        s += arc(CA, r, t - 0.62, t + 0.62); s += dot(P(CA, r, t - 0.62), 2.4) + dot(P(CA, r, t + 0.62), 2.4)
    return s + dline(CA, rim(CA))
def op_inscribe():
    s = dline(CA, rim(CA)) + R_being(RC, RR, gap_to(CA)); t = ang(CA, RC); n = (-math.sin(t), math.cos(t))
    for d in (40, 54):                                                    # n bars = inscribed words
        p = toward(CA, RC, d); s += line((p[0] - n[0] * 11, p[1] - n[1] * 11), (p[0] + n[0] * 11, p[1] + n[1] * 11))
    return s
def op_embody():
    tip = rim((70, 72)); s = R_being(RC, RR, gap_to((70, 72)))
    for i in range(3): s += dline((40 + i * 30, 76), tip, TH, (4.2, 0))  # n figures converge
    return s + dot(tip, 2.6)
def op_substitute():
    t = ang(CA, RC); n = (-math.sin(t) * 5, math.cos(t) * 5); b = rim(CA)
    return (dline((CA[0] + n[0], CA[1] + n[1]), (b[0] + n[0], b[1] + n[1]), TH, (3.2, 2.2)) +
            dline((CA[0] - n[0], CA[1] - n[1]), (b[0] - n[0], b[1] - n[1]), TH, (3.2, 2.2)) + R_being(RC, RR, gap_to(CA)))
def op_anachronism():
    a, c = (50, 50), (272, 50)
    return (dline(a, (120, 50), TH, (4.2, 0)) + arc((136, 50), 16, math.pi, 2 * math.pi) + arc((168, 50), 16, 0, math.pi)
            + line((184, 50), (c[0] - RR, 50)) + dot((c[0] - RR, 50), 2.6) + R_being(c, RR, math.pi))
def op_depth():
    a, c = (50, 70), (268, 32); s = dot(a); x = 0.0; gap = 9.0              # beads drift apart: depth = time
    while True:
        x += gap; gap *= 1.22; t = x / math.dist(a, rim(a, c))
        if t >= 1: break
        p = (a[0] + (rim(a, c)[0] - a[0]) * t, a[1] + (rim(a, c)[1] - a[1]) * t); s += dot(p, 2.4)
    return s + R_event(c, RR, gap_to(a, c))
def op_foreshadow():
    c1, c2 = (80, 58), (250, 30)
    return R_experience(c1, 16, math.pi) + R_event(c2, 18, gap_to(c1, c2)) + belt(c1, 16, c2, 18)
def op_trigger():
    c1, c2 = (82, 46), (248, 46)
    return R_event(c1, 16, math.pi) + R_event(c2, 20, 0) + belt(c1, 16, c2, 20, crossed=True)
def op_contain():
    c = (120, 46)
    return (R_experience(c, 34, math.pi * 0.8) + R_being((106, 46), 9, 0, 2) + R_being((134, 46), 9, math.pi, 2)
            + belt(c, 34, (262, 40), 12) + R_being((262, 40), 12, math.pi))
def op_contrast():
    a, b = (60, 46), (270, 46)
    return dot(a) + dot(b) + line(a, (140, 46), HL) + line((190, 46), b, HL) + arc((140, 46), 20, -math.pi / 2, math.pi / 2) + arc((190, 46), 20, math.pi / 2, 3 * math.pi / 2)
for k, fn in [("externalize", op_externalize), ("inscribe", op_inscribe), ("embody", op_embody), ("substitute", op_substitute),
              ("anachronism", op_anachronism), ("depth_time", op_depth), ("foreshadow", op_foreshadow), ("trigger", op_trigger),
              ("contain", op_contain), ("contrast", op_contrast)]:
    G[k] = fn()

SECTIONS = [
    ("1 · 基本元素", "参考：点收尾的线、断开的圆、圆与圆之间的切线", [
        ("dot", "机器描线 + 锚点", "C 可见载体：从原画像素描出", "裁切框 → Canny 边缘（例：丘比特）"),
        ("broken", "断开的圆", "R 缺席的对象", "圆不闭合 = 不在场"),
        ("dline", "点收尾的线", "从 C 出发的操作", "起点是实心点（可见）"),
        ("belt", "切线皮带", "R 与 R 之间的操作", "两头都是断圆，没有可见的落脚点"),
    ]),
    ("2 · R 怎么断　旋转 + 切分", "断法 = 种类；缺口朝向 = 操作从哪来", [
        ("k_being", "存在者", "¾ 圆，一个缺口", "kind = being"),
        ("k_experience", "经验", "两段弧，内外错开", "kind = experience"),
        ("k_event", "事件", "半圆，尚未完成", "kind = event"),
        ("k_concept", "概念", "四段 ¼ 弧，无形体", "kind = concept"),
        ("k_gap", "缺口朝向", "缺口对着到达它的载体", "操作的方向"),
        ("k_contain", "容器", "子 R 缩小后放进圆里", "R 包含 R"),
    ]),
    ("3 · 证据　粗细", "不再用虚线，改用粗细对比", [
        ("e_text", "文本", "粗线", "AIC 描述原文，计入签名"),
        ("e_image", "图像", "发丝线", "机器看图得出"),
        ("e_infer", "推断", "不画", "只列在表里，不进谱"),
    ]),
    ("4 · 变换　Lucinda Childs", "每种变换都由一个数据字段驱动", [
        ("t_repeat", "重复 ×n", "同一元素出现 n 次", "形体数 · 铭文词数"),
        ("t_shift", "平移", "复制后平行偏移", "一物两面"),
        ("t_rotate", "旋转", "缺口转向", "操作来自哪个方向"),
        ("t_reverse", "反向", "镜像的一对弧", "方向相反：时间、对照"),
        ("t_scale", "缩放", "同心弧逐层放大", "扩散 · 入度 · 包含"),
    ]),
    ("5 · 操作短语", "点收尾的线 / 切线皮带 + 一个变换", [
        ("externalize", "外化", "三层同心弧 1:2:3 + 线", "内在向外扩散（固定形）"),
        ("inscribe", "铭写", "线 + n 根横杠", "n = 铭文词数"),
        ("embody", "赋形", "n 条点线汇聚到一个 R", "n = 形体数"),
        ("substitute", "象征替代", "两条平行点线", "符号 / 所指"),
        ("anachronism", "时代错置", "线中插一对反向弧", "时间方向相反"),
        ("depth_time", "纵深 = 时间", "点串，间距越来越大", "越深越远 = 越晚"),
        ("foreshadow", "预示", "开口皮带：经验 → 事件", "R → 尚未发生的 R"),
        ("trigger", "引发", "交叉皮带：事件 → 事件", "因 → 果"),
        ("contain", "包含", "圆里装着子 R + 皮带", "R 在 R 里"),
        ("contrast", "对照", "背靠背的一对弧", "两个载体互相衬托"),
    ]),
]

def main():
    out, Wd = [], GX * 2 + COLS * CW
    out.append(f'<text x="{GX}" y="62" font-size="22" fill="{INK}">Imagination Score · 语法与符号对照 v2</text>')
    out.append(f'<text x="{GX}" y="88" font-size="12" fill="{MUTE}">R 缺席的对象 / C 可见载体 / O 结构操作 / E 证据 · 元素：机器描线（可见）、断圆（缺席）、点收尾的线、切线皮带；粗 = 文本证据，细 = 图像证据</text>')
    y = 120
    for title, sub, cells in SECTIONS:
        y += 30
        out.append(f'<line x1="{GX}" y1="{y}" x2="{Wd - GX}" y2="{y}" stroke="{INK}" stroke-width="1.2"/>')
        out.append(f'<text x="{GX}" y="{y + 22}" font-size="14" font-weight="600" fill="{INK}">{title}</text>')
        out.append(f'<text x="{GX + 230}" y="{y + 22}" font-size="11.5" fill="{MUTE}">{sub}</text>')
        y += 36
        for i, (g, name, rule, data) in enumerate(cells):
            cx, cy = GX + (i % COLS) * CW, y + (i // COLS) * CH
            sc = (CW - 12) / 330; gh = GH * sc
            out.append(f'<g transform="translate({cx},{cy})">')
            out.append(f'<rect x="6" y="0" width="{CW - 12}" height="{f(gh)}" fill="none" stroke="#e8e8e8"/>')
            out.append(f'<g transform="translate(6,0) scale({f(sc)})" fill="none" stroke="{INK}" stroke-linecap="butt">{G[g]}</g>')
            out.append(f'<text x="8" y="{f(gh + 20)}" font-size="13.5" fill="{INK}">{name}</text>')
            out.append(f'<text x="8" y="{f(gh + 38)}" font-size="11.5" fill="#333">{rule}</text>')
            out.append(f'<text x="8" y="{f(gh + 55)}" font-size="11" fill="{MUTE}">{data}</text>')
            out.append('</g>')
        y += math.ceil(len(cells) / COLS) * CH
    H = y + 40
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {Wd} {H}" width="{Wd}" height="{H}" '
           f'font-family="Microsoft YaHei, PingFang SC, Noto Sans CJK SC, sans-serif">'
           f'<rect width="{Wd}" height="{H}" fill="#fff"/>' + "".join(out) + '</svg>')
    p = os.path.join(ROOT, "web", "grammar_sheet_v2.svg"); open(p, "w", encoding="utf-8").write(svg); print(p, Wd, "x", H)

if __name__ == "__main__":
    main()
