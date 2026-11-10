# The Atlas of Imagination — Experiment 01 · Imagination Score

This experiment is computational design research in which the machine acts as a curator of human imagination. Each artwork from the Art Institute of Chicago is translated into a rule-based 3D score:

- **visible carriers** are traced by the machine from the image's own pixels;
- **absent referents** are drawn as pure geometry;
- **operations** connect the two, and every operation is tied to a verbatim quote from the AIC description.

- **Rules:** [RULES.md](RULES.md)
- **3D scores (three.js):** `web/score_paris.html`, `score_charity.html`, `score_vedder.html`, `score_durer.html`. Serve the folder (`python -m http.server 8765`) and open `http://localhost:8765/web/score_paris.html`.
- **Sign sheet:** `web/grammar_v3.html`
- **Print / vector PDF renderer:** `processing/atlas_v3/` (Processing 4, P3D)

All works used are public domain. Images © public domain, via the AIC IIIF API. Data comes from the AIC API.
