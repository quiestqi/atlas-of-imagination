"""Exp 01 · full translation of one artwork: The Dream of Paris (AIC 58702).

Artwork → R/C/O/E analysis → structural graph → symbolic grammar → 3D imagination score

Every evidence span E is a verbatim substring of the AIC description (checked below; the script stops if not).
Only operations with text evidence enter the structure and the score; inference is listed and excluded.

Axes (decided 2026-11-11):
  x = position in the original picture (carrier: bbox centre / image width; R: mean x of every carrier that reaches it,
      directly or through other R)
  y = time: -1 past · 0 depicted moment · +1 future · +2 beyond time (text first, else default by kind)
  z = steps from the visible world: carriers 0; R = longest chain of evidenced operations from a carrier

Usage:   python -I -X utf8 scripts/05_paris_translation.py
Output:  data/paris_translation.json  ·  web/paris_translation.html (from web/paris_template.html)
"""
import json, os, re, base64, html

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W = 843  # width of images/58702.jpg

def plain_description():
    rec = json.loads(open(os.path.join(ROOT, "data", "verified_58702.jsonl"), encoding="utf-8").readline())
    return rec, html.unescape(re.sub(r"<[^>]+>", "", rec["description"])).strip()

# ───────── E · evidence spans (verbatim) ─────────
E = {
    "E1": "Faced with choosing the fairest goddess among Minerva, Juno, and Venus",
    "E2": "Venus, shown here holding a heart and the golden apple given as a prize in the contest",
    "E3": "with her son Cupid frolicking at her feet",
    "E4": "Paris wears the garb of a contemporary knight rather than classical dress, a choice that emphasizes the enduring relevance of his moral crossroads",
    "E5": "as well as, through contrast, the nudity of the goddesses",
    "E6": "His sleeping pose",
    "E7": "the painting’s inscription, PARIS / TRA(U)M (“dream of Paris,” on the slip of paper attached to the tree)",
    "E8": "indicate that he is in the midst of a dream vision",
    "E9": "a poetic device carried over from medieval allegory and used to foreshadow future events in a narrative",
    "E10": "the departure of Paris and Helen by boat in the middle distance",
    "E11": "the catalyst for the Trojan War",
}

# ───────── C · visible carriers (boxes = image observation on images/58702.jpg) ─────────
C = [
    {"id": "C1", "zh": "沉睡的姿势", "en": "sleeping pose", "boxes": [[300, 640, 530, 1300]], "ev": ["E6"]},
    {"id": "C2", "zh": "铭文纸条 PARIS / TRA(U)M", "en": "inscribed slip", "boxes": [[398, 395, 465, 450]], "ev": ["E7"], "words": 2},
    {"id": "C3", "zh": "中景的船", "en": "boat in the middle distance", "boxes": [[290, 618, 378, 655]], "ev": ["E10"], "depth_plane": 1},
    {"id": "C4", "zh": "金苹果", "en": "golden apple", "boxes": [[645, 965, 690, 1010]], "ev": ["E2"]},
    {"id": "C5", "zh": "当代骑士装束", "en": "contemporary knight's garb", "boxes": [[335, 700, 520, 1300]], "ev": ["E4"]},
    {"id": "C7", "zh": "三个裸体女像", "en": "three nude figures", "boxes": [[0, 690, 200, 1300], [170, 650, 340, 1270], [655, 655, 843, 1300]], "ev": ["E1", "E5"]},
    {"id": "C8", "zh": "脚边的丘比特", "en": "Cupid at her feet", "boxes": [[555, 985, 700, 1280]], "ev": ["E3"]},
    {"id": "C6", "zh": "维纳斯手中的心", "en": "heart held by Venus", "boxes": [[655, 828, 702, 872]], "ev": ["E2"], "excluded": "only takes part in an inferred operation"},
]

# ───────── R · absent referents ─────────
R = [
    {"id": "R1", "zh": "巴黎斯的梦境", "en": "Paris's dream vision", "kind": "experience", "absence": "inner",
     "time": 0, "time_ev": ["E8", "“in the midst of” — happening in the depicted moment"]},
    {"id": "R2", "zh": "三女神", "en": "Minerva, Juno, Venus", "kind": "being", "absence": "supernatural",
     "time": 0, "time_ev": ["E1", "the contest is the depicted scene"]},
    {"id": "R6", "zh": "丘比特", "en": "Cupid", "kind": "being", "absence": "supernatural",
     "time": 0, "time_ev": ["E3", "“frolicking” — present"]},
    {"id": "R3", "zh": "巴黎斯与海伦乘船离去", "en": "departure of Paris and Helen", "kind": "event", "absence": "not_yet",
     "time": 1, "time_ev": ["E9", "“foreshadow future events”"]},
    {"id": "R5", "zh": "特洛伊战争", "en": "the Trojan War", "kind": "event", "absence": "not_yet",
     "time": 1, "time_ev": ["E11", "caused by a future event, so also future"]},
    {"id": "R4", "zh": "道德抉择", "en": "moral crossroads", "kind": "concept", "absence": "invisible",
     "time": 2, "time_ev": ["E4", "“enduring relevance”"]},
    {"id": "R7", "zh": "爱", "en": "love", "kind": "concept", "absence": "invisible", "time": 2,
     "time_ev": [None, "default: concept"], "excluded": "reached only by an inference"},
]

# ───────── O · structural operations ─────────
O = [
    {"id": "O1", "type": "externalize", "from": "C1", "to": "R1", "evidence": "text", "E": ["E6", "E8"]},
    {"id": "O2", "type": "inscribe", "from": "C2", "to": "R1", "evidence": "text", "E": ["E7", "E8"]},
    {"id": "O3", "type": "embody", "from": "C7", "to": "R2", "evidence": "text", "E": ["E1", "E5"]},
    {"id": "O4", "type": "embody", "from": "C8", "to": "R6", "evidence": "text", "E": ["E3"]},
    {"id": "O5", "type": "contain", "from": "R1", "to": "R2", "evidence": "text", "E": ["E7", "E8"],
     "reading": "the inscription titles the painted scene as Paris's dream; the description does not separately say the goddesses are inside the vision"},
    {"id": "O6", "type": "contain", "from": "R1", "to": "R6", "evidence": "text", "E": ["E7", "E8"], "reading": "same as O5"},
    {"id": "O7", "type": "foreshadow", "from": "R1", "to": "R3", "evidence": "text", "E": ["E9", "E10"]},
    {"id": "O8", "type": "depth_time", "from": "C3", "to": "R3", "evidence": "text", "E": ["E10"]},
    {"id": "O9", "type": "trigger", "from": "R3", "to": "R5", "evidence": "text", "E": ["E11"]},
    {"id": "O10", "type": "substitute", "from": "C4", "to": "R4", "evidence": "text", "E": ["E2", "E1"]},
    {"id": "O11", "type": "anachronism", "from": "C5", "to": "R4", "evidence": "text", "E": ["E4"]},
    {"id": "O12", "type": "contrast", "from": "C5", "to": "C7", "evidence": "text", "E": ["E5"]},
    {"id": "X1", "type": "substitute", "from": "C6", "to": "R7", "evidence": "inference", "E": ["E2"],
     "excluded": "the text only says Venus holds a heart; heart = love is iconographic convention"},
]

CATEGORY = {"externalize": "显现", "embody": "显现", "substitute": "指代", "inscribe": "指代",
            "depth_time": "时间", "foreshadow": "时间", "trigger": "时间", "anachronism": "时间",
            "contain": "组合", "contrast": "组合"}   # four families (approved 2026-11-11)

def main():
    rec, desc = plain_description()
    for k, s in E.items():
        if s not in desc: raise SystemExit(f"{k} is not a verbatim span of the description: {s!r}")
    live = [o for o in O if o["evidence"] == "text"]
    Rid = {r["id"]: r for r in R}; Cid = {c["id"]: c for c in C}

    for c in C:
        bs = c["boxes"]; c["n"] = len(bs)
        c["x"] = round(sum((b[0] + b[2]) / 2 for b in bs) / len(bs) / W, 3)

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
        g = sorted(gathered(r["id"]))
        r["reached_by"] = g
        r["x"] = round(sum(Cid[c]["x"] for c in g) / len(g), 3) if g else None
        r["z"] = steps[r["id"]] or None
        r["in_text_ops"] = sum(1 for o in live if o["to"] == r["id"])

    graph = {"nodes": [{"id": c["id"], "layer": 0} for c in C if not c.get("excluded")] +
                      [{"id": r["id"], "layer": r["z"]} for r in R if not r.get("excluded")],
             "edges": [{"id": o["id"], "from": o["from"], "to": o["to"], "type": o["type"]} for o in live]}
    sig = {}
    for o in live: sig[CATEGORY[o["type"]]] = sig.get(CATEGORY[o["type"]], 0) + 1

    out = {"artwork": {"aic_id": rec["id"], "title": rec["title"], "artist": rec["artist_display"], "date": rec["date_display"],
                       "medium": rec["medium_display"], "public_domain": rec["is_public_domain"], "url": rec["artwork_url"],
                       "image_id": rec["image_id"], "description": desc},
           "E": E, "C": C, "R": R, "O": O, "category": CATEGORY, "graph": graph, "signature": sig,
           "axes": {"x": "position in picture 0-1", "y": "time -1/0/+1/+2", "z": "steps from the visible"}}
    json.dump(out, open(os.path.join(ROOT, "data", "paris_translation.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)

    tpl = open(os.path.join(ROOT, "web", "paris_template.html"), encoding="utf-8").read()
    page = tpl.replace("__DATA__", json.dumps(out, ensure_ascii=False).replace("</", "<\\/")).replace("__IMGSRC__", "../images/58702.jpg")
    open(os.path.join(ROOT, "web", "paris_translation.html"), "w", encoding="utf-8").write(page)

    print("E spans verified:", len(E))
    for r in R: print(f'{r["id"]:3} x={r["x"]}  y={r["time"]:+d}  z={r["z"]}  ops_in={r["in_text_ops"]}  {r["zh"]}' + ("  [excluded]" if r.get("excluded") else ""))
    print("signature:", sig)

if __name__ == "__main__":
    main()
