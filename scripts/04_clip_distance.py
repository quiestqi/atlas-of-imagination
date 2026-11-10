"""Exp 01 · plan C for the z axis: chain steps + embedding distance (CLIP ViT-B/32, OpenAI weights).

For every referent R, take the image crops of the carriers that reach it (or, for an R reached by nothing,
the crops of its own figures). For each crop:

    s_lit  = cos(crop, "an image of <literal carrier description>")   how well the crop shows what it literally is
    s_R    = cos(crop, "an image of <R>")                               how visible R is in that crop
    s_null = mean cos(crop, unrelated control texts)                    floor: something that is not there at all

    f = 1 - (s_R - s_null) / (s_lit - s_null), clamped to [0, 1]
        0 = R is as visible in the crop as the carrier itself · 1 = no more visible than something unrelated

f of R = mean over its crops.  zC = zA + 0.9 * f   (stays inside its own step, layers never swap)
A carrier with several bodies (count > 1) contributes one crop per body.

Usage:  .venv/Scripts/python -I -X utf8 scripts/04_clip_distance.py      (run after 03_axes.py)
Reads / writes data/axes.json (adds zC and the raw similarities).
"""
import json, os
import torch, open_clip
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AX = os.path.join(ROOT, "data", "axes.json")
NULL = ["a photograph of a car", "a screenshot of a spreadsheet", "a bowl of soup", "a satellite map of a city"]

def main():
    d = json.load(open(AX, encoding="utf-8"))
    model, _, prep = open_clip.create_model_and_transforms("ViT-B-32", pretrained="openai")
    tok = open_clip.get_tokenizer("ViT-B-32"); model.eval()

    @torch.no_grad()
    def img_emb(pil):
        e = model.encode_image(prep(pil).unsqueeze(0)); return e / e.norm(dim=-1, keepdim=True)
    @torch.no_grad()
    def txt_emb(texts):
        e = model.encode_text(tok(texts)); return e / e.norm(dim=-1, keepdim=True)
    null_e = txt_emb(NULL)

    for w in d["works"]:
        im = Image.open(os.path.join(ROOT, w["image"])).convert("RGB")
        def crop(b, pad=0.15):
            x0, y0, x1, y1 = b; bw, bh = x1 - x0, y1 - y0
            return im.crop((max(0, x0 - bw * pad), max(0, y0 - bh * pad), min(im.width, x1 + bw * pad), min(im.height, y1 + bh * pad)))
        C = {c["id"]: c for c in w["carriers"]}
        print(f'\n{w["aic_id"]}  {w["title"]}')
        for r in w["referents"]:
            if r["reached_by"]:
                crops = [(f'{cid}' + (f'.{k+1}' if len(C[cid]["boxes"]) > 1 else ''), crop(b), C[cid]["en"])
                         for cid in r["reached_by"] for k, b in enumerate(C[cid]["boxes"])]
            else:
                crops = [(f"fig{i+1}", crop(b, 0.05), w["figure_literal"]) for i, b in enumerate(r.get("figures", []))]
            r_e = txt_emb(["an image of " + r["en"]])
            rows = []
            for cid, pil, lit in crops:
                ie = img_emb(pil)
                s_lit = float(ie @ txt_emb(["an image of " + lit]).T)
                s_r = float(ie @ r_e.T)
                s_null = float((ie @ null_e.T).mean())
                f = 1 - (s_r - s_null) / max(s_lit - s_null, 1e-6)
                rows.append({"crop": cid, "s_lit": round(s_lit, 4), "s_R": round(s_r, 4), "s_null": round(s_null, 4),
                             "margin": round(s_lit - s_null, 4), "f": round(min(1, max(0, f)), 3)})
            f = sum(x["f"] for x in rows) / len(rows) if rows else 1.0
            r["clip"] = {"model": "ViT-B-32/openai", "f": round(f, 3), "crops": rows}
            r["zC"] = round(r["zA"] + 0.9 * f, 3)
            weak = [x["crop"] for x in rows if x["margin"] < 0.03]
            print(f'  {r["id"]}  zA={r["zA"]}  f={f:.3f}  zC={r["zC"]:.2f}  {r["zh"]}' + (f'   ⚠ weak crop: {",".join(weak)}' if weak else ''))
    d["_axes"]["zC"] = "zA + 0.9 * f, f = 1 - (s_R - s_null)/(s_lit - s_null), CLIP ViT-B/32 openai, mean over carrier crops"
    json.dump(d, open(AX, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

if __name__ == "__main__":
    main()
