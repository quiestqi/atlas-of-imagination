# The Atlas of Imagination — Experiment 01 rules (v3)

Experiment 01 translates one artwork into a **3D Imagination Score**:

> Artwork → R/C/O/E analysis → structural graph → symbolic grammar → 3D score

*Imagination* is defined operationally: **representation of what is absent, invisible, inaccessible, or not yet existent through perceptible forms.**

Every mark in the score maps back to a data field. Every data field in turn traces back to verbatim text from the Art Institute of Chicago (AIC) API, or to an image observation that is explicitly marked as one.

---

## 1. Corpus and data rules

- The source is the AIC API (`/api/v1/artworks/{id}`) together with the IIIF image `{iiif_url}/{image_id}/full/{min(843,w)},/0/default.jpg`.
- Only **public-domain** works are used. Non-public-domain works are removed from all outputs.
- A work qualifies only if its `description` is non-empty and its `image_id` resolves.
- Nothing is invented. No step is reported as "passed" unless the code for it actually ran.

## 2. Analysis: R / C / O / E

| Slot | Meaning |
|---|---|
| **R** — Absent Referent | What the work imagines: absent, invisible, inaccessible, or not yet existing. |
| **C** — Visible Carrier | What is actually depicted (has pixels in the image). |
| **O** — Structural Operation | How a carrier, or another referent, leads to a referent. |
| **E** — Evidence | Why we claim the operation exists. |

**Evidence levels**

| Level | Source | In the score | In the signature |
|---|---|---|---|
| text | A verbatim span of the AIC `description`. The build script checks every span. | signs **filled** | counted |
| image | A machine or researcher visual observation, marked `[image]`. | signs **hollow** | not counted |
| inference | Iconographic convention not stated in the text. | **not drawn** | not counted |

**Hard rule:** without evidence, an operation does not count.

**R attributes**

- **kind**, one of four: `being` · `experience` · `event` · `concept`. "World" (a place such as Hell or the heavens) was merged into `concept`.
- **absence**: `inner` · `supernatural` · `not_yet` · `invisible` · `unreachable` · `nonexistent`. Absence is classified by the culture's own frame.

**Labels.** C and R are labelled with verbatim words from the AIC description. Items the description never mentions are tagged `[image] …` or `[inference] …`.

## 3. Axes

| Axis | Meaning | Rule |
|---|---|---|
| **x** | Position in the original picture (0 = left, 1 = right) | A carrier's x is the centre of its bounding box divided by the image width (hand-measured). An R's x is the mean x of every carrier that reaches it, directly or through other R. |
| **y** | Time | −1 past · 0 depicted moment (all carriers sit here) · +1 future · +2 beyond time. Text evidence comes first; otherwise the kind sets a default: experience → 0, concept and being → +2, event → 0. |
| **z** | Steps from the visible world | Carriers are at 0. An R's z is the longest chain of evidenced operations from a carrier; nesting counts as one step. |

## 4. Operations: four families

| Family | Operation types | Base sign | Modifier (data-driven) |
|---|---|---|---|
| **manifest** | externalize · embody · witness · impossible viewpoint · activate | A half-circle arc drawn as *long line · dot · long line*, starting from a solid blob | n arcs = number of bodies in the carrier |
| **refer** | substitute · inscribe · synecdoche | A dashed line of bars, long at both ends and short in the middle | bars are grouped by n = number of inscribed words |
| **time** | depth = time · foreshadow · trigger · anachronism | A row of tall, spaced triangle arrows | ▷ points toward the future, ◁ toward the past (anachronism) |
| **compose** | contain · contrast · juxtapose · radiate · layer | A point-cloud ring band | wraps R-in-R, or two carriers set against each other |

A line that starts at a carrier begins at that carrier's anchor on the picture line. A line that starts at an R begins at that R's rim.

## 5. Symbol grammar (3D)

**C — visible carrier.** A machine edge trace (Canny: σ 1.8, top 10 % of edges, low ratio 0.5) of the carrier's own crop.

- The trace lies flat on the *now* plane, in front of the picture line, and can be toggled to hang vertically.
- An anchor dot sits at the carrier's true x on the picture line.

**R — absent referent.** A constellation: a hairline **structure** (by kind) with **signs** strung on it (by absence).

| kind | structure |
|---|---|
| being | Solid black square, with its signs ringed around it |
| experience | One closed circle |
| event | Star of rays from a small cluster; the sign sits at each ray tip |
| concept | Sphere of great circles through two poles |

| absence | sign |
|---|---|
| inner | ⊙ |
| supernatural | ○ |
| not_yet | ▷ |
| invisible | ● |
| unreachable | ‖ |
| nonexistent | × |

The counts are data-driven:

- Rays, meridians and ringed signs scale with *n* (operations reaching R) and *e* (distinct evidence spans).
- Size grows with *n*.
- Display scale is 1.4×, and 1.6× for events.

**Axes** are drawn dashed and can be hidden. The **picture line** (now × visible) can be hidden too.

## 6. Pipeline

```
scripts/01_discover.py, 02_verify.py      corpus discovery and verification (AIC API, IIIF)
scripts/05_*_translation.py               R/C/O/E + axes for one work; checks E spans verbatim
scripts/08_carrier_trace.py               Canny edge tracing of carrier crops
scripts/10_paris_score_3d.py              builds web/score_<work>.html and processing/atlas_v3/data/<work>_v3.json
web/signs_v3.js                           the sign vocabulary (shared by every web page)
web/paris3d_template.html                 the three.js 3D score template
processing/atlas_v3/atlas_v3.pde          Processing P3D renderer (print / vector PDF)
```

**Run**

```
python -m venv .venv && .venv/Scripts/pip install numpy pillow
python scripts/05_paris_translation.py   (and 05_charity / 05_vedder / 05_durer)
.venv/Scripts/python scripts/10_paris_score_3d.py
python -m http.server 8765               then open http://localhost:8765/web/score_paris.html
```

## 7. Works (public domain)

| Work | AIC | Notes |
|---|---|---|
| The Dream of Paris, Monogrammist PG, 1536 | 58702 | Time fully unfolded: now → future → beyond time |
| Allegory of Charity, Francesco de Mura, c. 1743–44 | 36492 | Everything is beyond time; refer dominates |
| A Glimpse into Hell, or Fear, Elihu Vedder, 1888–98 | 97884 | The referent is off-frame: witness and synecdoche |
| Celestial Map of the Southern Sky, Albrecht Dürer, 1515 | 106549 | One text operation; the rest is image evidence (hollow) |

## 8. Known limitations

- Carrier bounding boxes are hand-measured on the 843 px IIIF image.
- The default time rule places most concepts at "beyond time".
- The longest-chain rule for z can place an effect (fear) farther than its cause (Hell).
- Symbol shapes are vocabulary choices. Only their selection and their counts are driven by data.
