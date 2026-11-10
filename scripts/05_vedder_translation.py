"""Exp 01 · third artwork with the same rules: A Glimpse into Hell, or Fear (Elihu Vedder, AIC 97884).

Same checks as the other translations: E spans verbatim, text-evidence operations only.
witness → 显现 and synecdoche → 指代 (placed into the four families by meaning).
Usage:   python -I -X utf8 scripts/05_vedder_translation.py   →   data/vedder_translation.json
"""
import json, os, re, html

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AIC, W = 97884, 843          # images/97884.jpg is 843 × 636

E = {
    "E1": "five females confront the gate of Hell",
    "E2": "Beholding such a sight, they express apprehension and fear, accentuated by the swirling forms of their draperies and hair",
    "E3": "Vedder focused on the figures’ psychological tension, rather than the spectacle of the environs itself",
    "E4": "depicting only a sliver of fiery flames at bottom left",
}

# boxes = image observation on images/97884.jpg (843 × 636, hand-measured)
C = [
    {"id": "C1", "zh": "五位女性", "en": "five women", "boxes": [[20, 130, 260, 520], [230, 60, 520, 560], [400, 20, 620, 200], [470, 190, 730, 560], [690, 280, 830, 510]], "ev": ["E1", "E2"]},
    {"id": "C2", "zh": "翻卷的衣褶与头发", "en": "swirling draperies and hair", "boxes": [[20, 420, 780, 620]], "ev": ["E2"]},
    {"id": "C3", "zh": "左下角一角火焰", "en": "sliver of flames, bottom left", "boxes": [[20, 500, 200, 620]], "ev": ["E4"]},
]

R = [
    {"id": "R1", "zh": "地狱", "en": "Hell", "kind": "concept", "absence": "unreachable",       # "world" merged into "concept" (2026-11-11)
     "time": 2, "time_ev": [None, "default: concept → beyond time"]},
    {"id": "R2", "zh": "恐惧", "en": "apprehension and fear", "kind": "experience", "absence": "inner",
     "time": 0, "time_ev": ["E2", "“they express” — in the depicted moment"]},
]

O = [
    {"id": "O1", "type": "witness", "from": "C1", "to": "R1", "evidence": "text", "E": ["E1", "E2", "E3"],
     "reading": "the women 'confront' and 'behold' Hell; the painting shows their reaction, not the place (E3)"},
    {"id": "O2", "type": "synecdoche", "from": "C3", "to": "R1", "evidence": "text", "E": ["E4"]},
    {"id": "O3", "type": "externalize", "from": "C1", "to": "R2", "evidence": "text", "E": ["E2"]},
    {"id": "O4", "type": "externalize", "from": "C2", "to": "R2", "evidence": "text", "E": ["E2"],
     "reading": "'accentuated by the swirling forms of their draperies and hair'"},
    {"id": "O5", "type": "trigger", "from": "R1", "to": "R2", "evidence": "text", "E": ["E2"],
     "reading": "'Beholding such a sight, they express … fear' — the sight of Hell causes the fear"},
]

CATEGORY = {"externalize": "显现", "embody": "显现", "substitute": "指代", "inscribe": "指代",
            "depth_time": "时间", "foreshadow": "时间", "trigger": "时间", "anachronism": "时间",
            "contain": "组合", "contrast": "组合", "juxtapose": "组合",
            "witness": "显现", "synecdoche": "指代"}   # witness / synecdoche placed by meaning (2026-11-11)

def main():
    rec = next(json.loads(l) for l in open(os.path.join(ROOT, "data", "verified_batch3.jsonl"), encoding="utf-8") if json.loads(l)["id"] == AIC)
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
    json.dump(out, open(os.path.join(ROOT, "data", "vedder_translation.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("E spans verified:", len(E))
    for c in C: print(f'{c["id"]}  x={c["x"]:.2f}  n={c["n"]}  {c["zh"]}')
    for r in R: print(f'{r["id"]}  x={r["x"]}  y={r["time"]:+d}  z={r["z"]}  ops_in={r["in_text_ops"]}  {r["zh"]}' + ("  [excluded]" if r.get("excluded") else ""))
    print("signature:", sig)

if __name__ == "__main__":
    main()
