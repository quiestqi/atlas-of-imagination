"""Stage A sample: discover AIC candidates across cross-cultural query directions.
Hard filters applied here (data only, not imagination judgement):
  description non-empty, image_id present. Public-domain status recorded, not filtered."""
import json, re, time, sys, urllib.parse, urllib.request
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "data"
OUT.mkdir(exist_ok=True)
UA = {"AIC-User-Agent": "atlas-of-imagination-research (academic)", "User-Agent": "atlas-research-client"}
FIELDS = ("id,title,artist_display,artist_title,date_display,place_of_origin,medium_display,"
          "artwork_type_title,department_title,classification_titles,style_titles,"
          "description,short_description,image_id,is_public_domain")
QUERIES = {
  "south_asian_cosmology": "mandala",
  "himalayan_deity": "Tibetan deity",
  "east_asian_supernatural": "demon Japanese",
  "east_asian_paradise": "Buddhist paradise",
  "african_spirit": "power figure spirit",
  "mesoamerican_cosmos": "deity Mesoamerican",
  "eu_apocalypse": "apocalypse",
  "eu_symbolism": "Symbolist",
  "dream_vision": "vision dream",
  "allegory": "allegory",
  "hybrid_creature": "monster",
  "speculative_architecture": "imaginary architecture",
}

def get(url):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)

def strip_html(s):
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", s or "")).strip()

pool = {}
for tag, q in QUERIES.items():
    url = f"https://api.artic.edu/api/v1/artworks/search?q={urllib.parse.quote(q)}&limit=25&fields={FIELDS}"
    data = get(url)["data"]
    kept = 0
    for a in data:
        desc = (a.get("description") or "").strip()
        if not desc or not a.get("image_id"):
            continue
        rec = pool.setdefault(a["id"], {**a, "discovery_queries": []})
        rec["discovery_queries"].append(tag)
        kept += 1
    print(f"{tag:28s} q={q!r:26s} returned={len(data):3d} kept={kept}")
    time.sleep(0.4)

for r in pool.values():
    r["description_plain_len"] = len(strip_html(r["description"]))
with open(OUT / "candidate_pool.jsonl", "w", encoding="utf-8") as f:
    for r in pool.values():
        f.write(json.dumps(r, ensure_ascii=False) + "\n")
print("unique candidates:", len(pool), "public domain:", sum(r["is_public_domain"] for r in pool.values()))
