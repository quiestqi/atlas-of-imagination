"""Exp 01 · fourth artwork with the same rules: Celestial Map of the Southern Sky (Dürer, AIC 106549).
Only one sentence of the description is about imagination; the other operations are image evidence (drawn hollow, not counted).
Usage:   python -I -X utf8 scripts/05_durer_translation.py   →   data/durer_translation.json
"""
import json, os, re, html

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AIC, W = 106549, 843          # images/106549.jpg is 843 × 1062

E = {
    "E1": "the dual view depicts the heavens as if the viewer were observing them from space",
}
# the rest of the description is print / globe history: no operation.
# boxes = image observation on images/106549.jpg (843 × 1062, hand-measured)
C = [
    {"id": "C1", "zh": "平面星图（圆盘）", "en": "flat star map (disk)", "boxes": [[100, 160, 760, 810]], "ev": ["E1"]},
    {"id": "C2", "zh": "星座形象（鲸、九头蛇、船、半人马）", "en": "constellation figures", "boxes": [[235, 195, 385, 385], [600, 420, 760, 700], [450, 430, 620, 560], [380, 600, 560, 760]], "ev": []},
    {"id": "C3", "zh": "拉丁文星座名", "en": "Latin constellation labels", "boxes": [[425, 270, 505, 300], [640, 320, 700, 380], [205, 515, 330, 640]], "ev": []},
]
R = [
    {"id": "R1", "zh": "从宇宙外看到的天穹", "en": "the heavens seen from outside", "kind": "concept", "absence": "unreachable",
     "time": 2, "time_ev": [None, "default: concept → beyond time"]},
    {"id": "R2", "zh": "星座生物", "en": "constellation creatures", "kind": "being", "absence": "nonexistent",
     "time": 2, "time_ev": [None, "default: being → beyond time"]},
]
O = [
    {"id": "O1", "type": "impossible_viewpoint", "from": "C1", "to": "R1", "evidence": "text", "E": ["E1"]},
    {"id": "O2", "type": "radiate", "from": "C1", "to": "R1", "evidence": "image", "E": [],
     "reading": "image: the disk is divided by 12 radial lines with a graduated rim"},
    {"id": "O3", "type": "embody", "from": "C2", "to": "R2", "evidence": "image", "E": [],
     "reading": "image: groups of stars are drawn as whale, hydra, ship, centaur (n = 4 figures measured)"},
    {"id": "O4", "type": "inscribe", "from": "C3", "to": "R2", "evidence": "image", "E": [],
     "reading": "image: Latin names written beside the figures"},
    {"id": "O5", "type": "contain", "from": "R1", "to": "R2", "evidence": "image", "E": [],
     "reading": "image: the creatures are drawn inside the disk of the heavens"},
]

CATEGORY = {"externalize": "显现", "embody": "显现", "witness": "显现", "impossible_viewpoint": "显现", "activate": "显现",
            "substitute": "指代", "inscribe": "指代", "synecdoche": "指代",
            "depth_time": "时间", "foreshadow": "时间", "trigger": "时间", "anachronism": "时间",
            "contain": "组合", "contrast": "组合", "juxtapose": "组合", "radiate": "组合", "layer": "组合"}

def main():
    rec = next(json.loads(l) for l in open(os.path.join(ROOT, "data", "verified_batch3.jsonl"), encoding="utf-8") if json.loads(l)["id"] == AIC)
    desc = html.unescape(re.sub(r"<[^>]+>", "", rec["description"])).strip()
    for k, s in E.items():
        if s not in desc: raise SystemExit(f"{k} is not a verbatim span of the description: {s!r}")
    live = [o for o in O if o["evidence"] in ("text", "image")]      # image evidence is drawn hollow
    Rid = {r["id"]: r for r in R}; Cid = {c["id"]: c for c in C}
    for c in C:
        bs = c["boxes"]; c["n"] = len(bs); c["x"] = round(sum((b[0] + b[2]) / 2 for b in bs) / len(bs) / W, 3)

    def gathered(rid, seen=()):
        out = set()
        for o in live:
            if o["to"] != rid: continue
            f = o["from"]
            if f in Rid and f not in seen: out |= gathered(f, seen + (rid,))
            elif f in Cid: out.add(f)
        return out

    steps = {r["id"]: 0 for r in R}
    for _ in range(12):
        for o in live:
            if o["to"] not in Rid: continue
            base = 0 if o["from"] in Cid else steps[o["from"]]
            if o["from"] in Rid and base == 0: continue
            steps[o["to"]] = max(steps[o["to"]], base + 1)
    for r in R:
        g = sorted(gathered(r["id"])); r["reached_by"] = g
        r["x"] = round(sum(Cid[c]["x"] for c in g) / len(g), 3) if g else None
        r["z"] = steps[r["id"]] or None
        r["in_text_ops"] = sum(1 for o in live if o["to"] == r["id"])   # all drawn operations (text + image)
    sig = {}
    for o in live:
        if o["evidence"] == "text": sig[CATEGORY[o["type"]]] = sig.get(CATEGORY[o["type"]], 0) + 1
    out = {"artwork": {"aic_id": rec["id"], "title": rec["title"], "artist": rec["artist_display"], "date": rec["date_display"],
                       "medium": rec["medium_display"], "public_domain": rec["is_public_domain"], "url": rec["artwork_url"],
                       "image_id": rec["image_id"], "description": desc},
           "image": f"images/{AIC}.jpg", "E": E, "C": C, "R": R, "O": O, "category": CATEGORY, "signature": sig}
    json.dump(out, open(os.path.join(ROOT, "data", "durer_translation.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("E spans verified:", len(E))
    for c in C: print(f'{c["id"]}  x={c["x"]:.2f}  n={c["n"]}  {c["zh"]}')
    for r in R: print(f'{r["id"]}  x={r["x"]}  y={r["time"]:+d}  z={r["z"]}  ops_in={r["in_text_ops"]}  {r["zh"]}' + ("  [excluded]" if r.get("excluded") else ""))
    print("signature:", sig)

if __name__ == "__main__":
    main()
