"""Exp 01 · compute the three axes for every annotated artwork (v1 axis definition, 2026-11-11).

x = horizontal position in the original picture (0 = left edge, 1 = right edge)
      carrier: centre of its bounding box(es) — image observation, hand-measured on images/<id>.jpg (IIIF ≤843px)
      referent: mean x of the carriers that reach it (directly or through another R);
                an R reached by nothing uses the mean x of its own figures
y = time relative to the depicted moment: -1 past · 0 now (all carriers) · +1 future · +2 beyond time
      rule: explicit text evidence wins; otherwise default by kind —
            experience → 0 (happening in the depicted moment) · concept / world / being → +2 · event → 0
z = distance from the visible world
      plan A: chain steps — carriers 0; R reached directly from a carrier 1; via another R, or nested
              inside another R (parent), = that R + 1 (the larger route counts)
      plan C: filled in by 04_clip_distance.py

Referent / carrier / op definitions come from processing/atlas_score/data/scores.json (the rule trials);
this file only adds what the axes need: boxes and time.

Usage:  python -I -X utf8 scripts/03_axes.py
Output: data/axes.json (all works). Then run 04_clip_distance.py (it fills zC; rerunning this file clears it).
"""
import json, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# boxes are [x0, y0, x1, y1] px; a carrier with several bodies has several boxes
ANN = {
    58702: {"size": [843, 1323], "figure_literal": "a nude woman",
        "boxes": {"C1": [[300, 640, 530, 1300]], "C2": [[398, 395, 465, 450]], "C3": [[290, 618, 378, 655]],
                  "C4": [[645, 965, 690, 1010]], "C5": [[335, 700, 520, 1300]], "C6": [[655, 828, 702, 872]]},
        "figures": {"R2": [[0, 690, 200, 1300], [170, 650, 340, 1270], [655, 655, 843, 1300]]},
        "time": {"R1": [0, "text", "he is in the midst of a dream vision"],
                 "R2": [0, "text", "appear to him in the midst of a dream vision (inside R1, same moment)"],
                 "R3": [1, "text", "used to foreshadow future events"],
                 "R4": [2, "text", "the enduring relevance of his moral crossroads"],
                 "R5": [2, "default", "concept → beyond time"]}},
    36492: {"size": [843, 881],
        "boxes": {"C3": [[0, 470, 175, 600], [90, 300, 385, 790], [445, 365, 790, 515]],
                  "C1": [[250, 155, 690, 800]], "C2": [[630, 600, 843, 850]]},
        "time": {"R1": [2, "default", "concept (virtue) → beyond time"],
                 "R2": [2, "default", "concept → beyond time"],
                 "R3": [2, "default", "concept → beyond time"],
                 "R4": [2, "default", "supernatural being → beyond time"]}},
    97884: {"size": [843, 636],
        "boxes": {"C2": [[20, 500, 200, 620]],
                  "C1": [[20, 130, 260, 520], [230, 60, 520, 560], [400, 20, 620, 200], [470, 190, 730, 560], [690, 280, 830, 510]]},
        "time": {"R2": [0, "default", "experience → the depicted moment (their fear, now)"],
                 "R1": [2, "default", "world → beyond time"]}},
    106549: {"size": [843, 1062],
        "boxes": {"C1": [[100, 160, 760, 810]]},
        "time": {"R1": [2, "default", "world → beyond time"],
                 "R2": [2, "default", "being → beyond time"]}},
    181742: {"size": [843, 1354],
        "boxes": {"C2": [[225, 375, 630, 960]], "C1": [[115, 110, 705, 400]], "C3": [[480, 180, 690, 330]]},
        "time": {"R2": [-1, "text", "the Neolithic stone ax heads that the god is said to hurl to Earth (debatable: myth vs. artefact age)"],
                 "R3": [2, "default", "concept → beyond time"],
                 "R1": [2, "default", "supernatural being → beyond time"]}},
}

def build(art, ann):
    W = ann["size"][0]
    ops = art["ops"]
    R = {r["id"]: dict(r) for r in art["referents"]}
    C = {c["id"]: dict(c) for c in art["carriers"]}
    for cid, c in C.items():
        bs = ann["boxes"][cid]; c["boxes"] = bs
        c["x"] = round(sum((b[0] + b[2]) / 2 for b in bs) / len(bs) / W, 3)
        c.update(y=0, zA=0, zC=0)

    def gathered(rid, seen=()):
        out = set()
        for o in ops:
            if o["to"] != rid: continue
            f = o["from"]
            if f in R and f not in seen: out |= gathered(f, seen + (rid,))
            elif f in C: out.add(f)
        return out

    for rid, r in R.items():
        g = sorted(gathered(rid)); r["reached_by"] = g
        figs = ann.get("figures", {}).get(rid)
        if figs: r["figures"] = figs
        if g:
            r["x"] = round(sum(C[c]["x"] for c in g) / len(g), 3); r["x_rule"] = "mean x of carriers " + ",".join(g)
        elif figs:
            r["x"] = round(sum((b[0] + b[2]) / 2 for b in figs) / len(figs) / W, 3); r["x_rule"] = "mean x of its own figures"
        else:
            r["x"] = None
        t = ann["time"][rid]; r["time"] = t[0]; r["time_ev"] = t[1:]
    for rid, r in R.items():                              # R reached by nothing and without figures: sit with parent
        if r["x"] is None: r["x"] = R[r["parent"]]["x"]; r["x_rule"] = "x of parent"

    step = {rid: None for rid in R}
    for _ in range(12):
        for o in ops:
            f, t = o["from"], o["to"]
            if t not in R: continue
            s = 1 if f in C else (step[f] + 1 if step.get(f) else None)
            if s and (step[t] is None or s > step[t]): step[t] = s
        for rid, r in R.items():
            p = r.get("parent")
            if p and step.get(p): step[rid] = max(step[rid] or 0, step[p] + 1)
    for rid, r in R.items():
        r["zA"] = step[rid] if step[rid] is not None else 1
        r["zC"] = None

    keep = ("aic_id", "title", "artist", "date", "public_domain")
    return {**{k: art[k] for k in keep}, "image": f"images/{art['aic_id']}.jpg", "size": ann["size"],
            "figure_literal": ann.get("figure_literal", "a figure"),
            "carriers": list(C.values()), "referents": list(R.values()), "ops": ops}

def main():
    scores = json.load(open(os.path.join(ROOT, "processing", "atlas_score", "data", "scores.json"), encoding="utf-8"))
    works = [build(a, ANN[a["aic_id"]]) for a in scores["artworks"] if a["aic_id"] in ANN]
    axes = {"x": "position in picture 0-1", "y": "time: -1 past, 0 now, 1 future, 2 beyond time",
            "zA": "chain steps from the visible", "zC": "steps + embedding distance (04_clip_distance.py)"}
    json.dump({"_axes": axes, "works": works}, open(os.path.join(ROOT, "data", "axes.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    for w in works:
        print(f'\n{w["aic_id"]}  {w["title"]}')
        for c in w["carriers"]: print(f'  {c["id"]}  x={c["x"]:.2f}            {c["zh"]}')
        for r in w["referents"]: print(f'  {r["id"]}  x={r["x"]:.2f}  y={r["time"]:+d}  zA={r["zA"]}  {r["zh"]}   [{r["time_ev"][0]}]')

if __name__ == "__main__":
    main()
