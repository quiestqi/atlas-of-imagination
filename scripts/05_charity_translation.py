"""Exp 01 · full translation of a second artwork with the same rules: Allegory of Charity (AIC 36492).

Same pipeline and checks as 05_paris_translation.py:
  every evidence span E must be a verbatim substring of the AIC description (the script stops otherwise);
  only operations with text evidence enter the structure; inferences are listed and excluded.
Only the first sentence of the description speaks about imagination; the rest (commission, career, canvas shape)
is history and produces no operation.

Usage:   python -I -X utf8 scripts/05_charity_translation.py   →   data/charity_translation.json
"""
import json, os, re, html

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AIC, W = 36492, 843          # images/36492.jpg is 843 × 881

E = {
    "E1": "This painting presents an allegory of the virtue of charity through images of maternal love and sacrifice",
    "E2": "a mother nurtures several young children",
    "E3": "a pelican feeds her young by drawing blood from her own breast",
}

# boxes = image observation on images/36492.jpg (hand-measured)
C = [
    {"id": "C1", "zh": "哺育的母亲", "en": "mother nurturing", "boxes": [[250, 155, 690, 800]], "ev": ["E2"]},
    {"id": "C3", "zh": "几个孩子", "en": "several young children", "boxes": [[0, 470, 175, 600], [90, 300, 385, 790], [445, 365, 790, 515]], "ev": ["E2"]},
    {"id": "C2", "zh": "啄胸喂血的鹈鹕", "en": "pelican feeding her young with her blood", "boxes": [[630, 600, 843, 850]], "ev": ["E3"]},
]

R = [
    {"id": "R2", "zh": "母爱", "en": "maternal love", "kind": "concept", "absence": "invisible",
     "time": 2, "time_ev": [None, "default: concept → beyond time"]},
    {"id": "R3", "zh": "牺牲", "en": "sacrifice", "kind": "concept", "absence": "invisible",
     "time": 2, "time_ev": [None, "default: concept → beyond time"]},
    {"id": "R1", "zh": "慈爱（美德）", "en": "the virtue of charity", "kind": "concept", "absence": "invisible",
     "time": 2, "time_ev": [None, "default: concept → beyond time"]},
    {"id": "R4", "zh": "基督", "en": "Christ", "kind": "being", "absence": "supernatural", "time": 2,
     "time_ev": [None, "default"], "excluded": "reached only by an inference"},
]

O = [
    {"id": "O1", "type": "externalize", "from": "C1", "to": "R2", "evidence": "text", "E": ["E2", "E1"]},
    {"id": "O2", "type": "embody", "from": "C3", "to": "R2", "evidence": "text", "E": ["E2", "E1"],
     "reading": "the children are part of the image of maternal love ('nurtures several young children'); n = 3 bodies in the picture"},
    {"id": "O3", "type": "substitute", "from": "C2", "to": "R3", "evidence": "text", "E": ["E3", "E1"]},
    {"id": "O4", "type": "substitute", "from": "R2", "to": "R1", "evidence": "text", "E": ["E1"]},
    {"id": "O5", "type": "substitute", "from": "R3", "to": "R1", "evidence": "text", "E": ["E1"]},
    {"id": "O6", "type": "juxtapose", "from": "C1", "to": "C2", "evidence": "text", "E": ["E1", "E2", "E3"],
     "reading": "two images set side by side for one virtue ('images of maternal love and sacrifice: a mother … and a pelican …')"},
    {"id": "X1", "type": "substitute", "from": "C2", "to": "R4", "evidence": "inference", "E": ["E3"],
     "excluded": "pelican = Christ is iconographic convention; the text does not say it"},
    {"id": "X2", "type": "externalize", "from": "C1", "to": "R1", "evidence": "inference", "E": ["E2"],
     "excluded": "the text calls her 'a mother', not Charity personified"},
]

CATEGORY = {"externalize": "显现", "embody": "显现", "substitute": "指代", "inscribe": "指代",
            "depth_time": "时间", "foreshadow": "时间", "trigger": "时间", "anachronism": "时间",
            "contain": "组合", "contrast": "组合", "juxtapose": "组合"}

def main():
    rec = json.loads(open(os.path.join(ROOT, "data", f"verified_{AIC}.jsonl"), encoding="utf-8").readline())
    desc = html.unescape(re.sub(r"<[^>]+>", "", rec["description"])).strip()
    for k, s in E.items():
        if s not in desc: raise SystemExit(f"{k} is not a verbatim span of the description: {s!r}")
    live = [o for o in O if o["evidence"] == "text"]
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
        r["in_text_ops"] = sum(1 for o in live if o["to"] == r["id"])
    sig = {}
    for o in live: sig[CATEGORY[o["type"]]] = sig.get(CATEGORY[o["type"]], 0) + 1
    out = {"artwork": {"aic_id": rec["id"], "title": rec["title"], "artist": rec["artist_display"], "date": rec["date_display"],
                       "medium": rec["medium_display"], "public_domain": rec["is_public_domain"], "url": rec["artwork_url"],
                       "image_id": rec["image_id"], "description": desc},
           "image": f"images/{AIC}.jpg", "E": E, "C": C, "R": R, "O": O, "category": CATEGORY, "signature": sig}
    json.dump(out, open(os.path.join(ROOT, "data", "charity_translation.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("E spans verified:", len(E))
    for c in C: print(f'{c["id"]}  x={c["x"]:.2f}  n={c["n"]}  {c["zh"]}')
    for r in R: print(f'{r["id"]}  x={r["x"]}  y={r["time"]:+d}  z={r["z"]}  ops_in={r["in_text_ops"]}  {r["zh"]}' + ("  [excluded]" if r.get("excluded") else ""))
    print("signature:", sig)

if __name__ == "__main__":
    main()
