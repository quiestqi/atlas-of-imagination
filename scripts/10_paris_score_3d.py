"""Exp 01 · The Dream of Paris as a 3D score (three.js) + the sign sheet; signs v3 from web/signs_v3.js.

Packs data/paris_translation.json + Canny edge points of every carrier box into web/paris_score_3d.html
(template: web/paris3d_template.html). Geometry is built in the browser from the same rules as the sheet.

Usage:  .venv/Scripts/python -I -X utf8 scripts/10_paris_score_3d.py
"""
import json, os, sys, importlib
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
tr = importlib.import_module("08_carrier_trace")
ROOT, D = tr.ROOT, tr.D
# sparser, more abstract traces than the trace sheet: heavy blur, high thresholds (2026-11-11, user: 更抽象模糊一点)
CANNY = {"sigma": 1.8, "hi_pct": 90, "lo_ratio": 0.5}

from PIL import Image

def traces_for(Dw, img_path):
    im = Image.open(img_path).convert("L"); out = []
    for c in Dw["C"]:
        if c.get("excluded"): continue
        for i, b in enumerate(c["boxes"]):
            mask, par = tr.canny(im.crop(tuple(b)), **CANNY); H, Wm = mask.shape
            ys, xs = np.nonzero(mask)
            out.append({"cid": c["id"], "i": i, "box": b, "x": round((b[0] + b[2]) / 2 / im.width, 4),
                        "w": int(Wm), "h": int(H), "pts": [int(v) for p in zip(xs, ys) for v in p], "canny": par})
    return out

# works rendered by the Processing sketch (same rules); file names = what the sketch cycles through with W
WORKS = [("paris", "paris_translation.json", "images/58702.jpg"), ("charity", "charity_translation.json", "images/36492.jpg"),
         ("vedder", "vedder_translation.json", "images/97884.jpg"),
         ("durer", "durer_translation.json", "images/106549.jpg")]   # only public-domain works (Sango 181742 removed: not public domain)

# English labels = verbatim words from the AIC API description (checked below). Items the description never
# mentions (image-only evidence) are tagged "[image] …" so they cannot be mistaken for API text.
LABELS = {
    "paris": {"C1": "His sleeping pose", "C2": "PARIS / TRA(U)M", "C3": "boat in the middle distance", "C4": "the golden apple",
              "C5": "the garb of a contemporary knight", "C7": "the nudity of the goddesses", "C8": "her son Cupid", "C6": "a heart",
              "R1": "a dream vision", "R2": "Minerva, Juno, and Venus", "R6": "Cupid", "R3": "the departure of Paris and Helen",
              "R5": "the Trojan War", "R4": "his moral crossroads"},
    "charity": {"C1": "a mother", "C3": "several young children", "C2": "a pelican",
                "R2": "maternal love", "R3": "sacrifice", "R1": "the virtue of charity", "R4": "[inference] Christ"},
    "vedder": {"C1": "five females", "C2": "the swirling forms of their draperies and hair", "C3": "a sliver of fiery flames",
               "R1": "Hell", "R2": "apprehension and fear"},
    "durer": {"C1": "the dual view", "C2": "[image] constellation figures", "C3": "[image] Latin constellation names",
              "R1": "the heavens", "R2": "[image] constellation creatures"},
}
def add_labels(name, Dw):
    desc = Dw["artwork"]["description"]
    for n in Dw["C"] + Dw["R"]:
        lab = LABELS[name].get(n["id"])
        if lab is None: lab = "[no API text] " + n["en"]
        if not lab.startswith("[") and lab not in desc: raise SystemExit(f"{name} {n['id']}: label is not verbatim API text: {lab!r}")
        n["label"] = lab
    return Dw

def main():
    pdir = os.path.join(ROOT, "processing", "atlas_v3", "data"); os.makedirs(pdir, exist_ok=True)
    pages = []
    for name, fn, img in WORKS:
        Dw = json.load(open(os.path.join(ROOT, "data", fn), encoding="utf-8"))
        Dw = add_labels(name, Dw)
        tw = traces_for(Dw, os.path.join(ROOT, img))
        json.dump({**Dw, "traces": tw, "canny": CANNY}, open(os.path.join(pdir, f"{name}_v3.json"), "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
        print(f"processing data: {name}_v3.json", sum(len(t["pts"]) // 2 for t in tw), "edge points")
        pages.append((name, Dw, tw))
    # one web page per work (same template, same sign code), linked by a small nav
    signs_js = open(os.path.join(ROOT, "web", "signs_v3.js"), encoding="utf-8").read()
    tpl_web = open(os.path.join(ROOT, "web", "paris3d_template.html"), encoding="utf-8").read().replace("__SIGNS__", signs_js)
    for name, Dw, tw in pages:
        nav = "　".join(f'<b>{d["artwork"]["title"]}</b>' if n == name else f'<a href="score_{n}.html" style="color:#888">{d["artwork"]["title"]}</a>' for n, d, _ in pages)
        page = tpl_web.replace("__NAV__", nav).replace("__DATA__", json.dumps({**Dw, "traces": tw}, ensure_ascii=False, separators=(",", ":")).replace("</", "<\/"))
        open(os.path.join(ROOT, "web", f"score_{name}.html"), "w", encoding="utf-8").write(page); print("web page:", f"web/score_{name}.html")
    traces = traces_for(D, os.path.join(ROOT, "images", "58702.jpg"))
    data = {**D, "traces": traces}
    tpl = open(os.path.join(ROOT, "web", "paris3d_template.html"), encoding="utf-8").read()
    signs = open(os.path.join(ROOT, "web", "signs_v3.js"), encoding="utf-8").read()
    tpl = tpl.replace("__SIGNS__", signs)
    tpl = tpl.replace("__NAV__", "")
    page = tpl.replace("__DATA__", json.dumps(data, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/"))
    out = os.path.join(ROOT, "web", "paris_score_3d.html"); open(out, "w", encoding="utf-8").write(page)
    print(out, len(page) // 1024, "KB,", sum(len(t["pts"]) // 2 for t in traces), "edge points")
    # grammar sheet v3 — same sign code
    sheet = open(os.path.join(ROOT, "web", "grammar_v3_template.html"), encoding="utf-8").read().replace("__SIGNS__", signs)
    sheet = sheet.replace("__DATA__", json.dumps({"traces": [t for t in traces if t["cid"] == "C8"]}, separators=(",", ":")))
    out2 = os.path.join(ROOT, "web", "grammar_v3.html"); open(out2, "w", encoding="utf-8").write(sheet); print(out2)

if __name__ == "__main__":
    main()
