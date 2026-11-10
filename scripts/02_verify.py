"""Step 2: re-verify each shortlisted ID against the single-record endpoint + IIIF image server.
Usage: python -I scripts/02_verify.py <id> <id> ...   -> data/verified.jsonl"""
import json, re, sys, time, urllib.request
from pathlib import Path
OUT = Path(__file__).resolve().parent.parent / "data"
UA = {"AIC-User-Agent": "atlas-of-imagination-research (academic)", "User-Agent": "atlas-research-client"}
FIELDS = ("id,title,artist_display,artist_title,date_display,place_of_origin,medium_display,"
          "artwork_type_title,department_title,description,short_description,image_id,"
          "is_public_domain,copyright_notice,credit_line,api_link")

def fetch(url, raw=False):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=30) as r:
        return (r.status, r.read()) if raw else json.load(r)

def plain(s): return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", s or "")).strip()

rows = []
for aid in sys.argv[1:]:
    rec = {"id": int(aid)}
    try:
        resp = fetch(f"https://api.artic.edu/api/v1/artworks/{aid}?fields={FIELDS}")
        a, iiif = resp["data"], resp["config"]["iiif_url"]
        rec.update(a); rec["api_record_valid"] = True
    except Exception as e:
        rec["api_record_valid"] = False; rec["error"] = str(e); rows.append(rec); continue
    desc = (a.get("description") or "").strip()
    rec["description_nonempty"] = bool(desc)
    rec["description_char_count_raw"] = len(desc)
    rec["description_char_count_plain"] = len(plain(desc))
    rec["artwork_url"] = f"https://www.artic.edu/artworks/{aid}"
    rec["image_accessible"] = False
    if a.get("image_id"):
        base = f"{iiif}/{a['image_id']}"
        rec["iiif_info_url"] = f"{base}/info.json"
        pass
        try:
            info = fetch(rec["iiif_info_url"])
            rec["iiif_max_width"], rec["iiif_max_height"] = info.get("width"), info.get("height")
            w = min(843, info.get("width") or 843)   # never request upscaling (fails on small originals)
            rec["iiif_image_url_843"] = f"{base}/full/{w},/0/default.jpg"
            st, _ = fetch(rec["iiif_image_url_843"], raw=True)
            rec["image_accessible"] = st == 200
        except Exception as e:
            rec["image_error"] = str(e)
    rows.append(rec); time.sleep(0.3)
    print(aid, "api", rec["api_record_valid"], "desc", rec["description_nonempty"],
          rec["description_char_count_plain"], "img", rec["image_accessible"],
          rec.get("iiif_max_width"), "PD", a.get("is_public_domain"))
with open(OUT / "verified.jsonl", "w", encoding="utf-8") as f:
    for r in rows: f.write(json.dumps(r, ensure_ascii=False) + "\n")
