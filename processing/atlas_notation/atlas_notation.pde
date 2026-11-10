// The Atlas of Imagination — Exp 01 · Imagination Score, notation style (black ink on white) v0.2
// Same data (data/scores.json) and same 8 layout rules as atlas_score; only the drawing language changes:
// hand-inked notation glyphs, projected into an axonometric wireframe box.
//
// Keys:  ← → or 1–5 switch artwork   L labels   T 中文/English   I inference   R reset view   S save PNG
// Mouse: drag = rotate

import java.util.*;

JSONArray works;
final int WORK = 0;                // 只做一件：0 = The Dream of Paris（改这个数字换作品）
int cur = WORK;
float rx = 0.50, ry = 0.62;
boolean showLabels = true, zh = true, showInfer = true;
PFont font;
final float U = 80;

HashMap<String, PVector> P = new HashMap<String, PVector>();
HashMap<String, Float> RAD = new HashMap<String, Float>();
HashMap<String, JSONObject> NODE = new HashMap<String, JSONObject>();
HashSet<String> REF = new HashSet<String>();
boolean frameNeeded = false;
JSONArray RR, CC, OO;
float[] BB = new float[6];

float S = 1, CX = 0, CY = 0;                      // projection scale / centre
int MODE = 0; float W = 1.2; int INK = 0; int ALPHA = 255; float JIT = 1.1; float SEED = 0; float GS = 1;
int savedMode = 0;

void setup() {
  size(880, 1120);
  pixelDensity(displayDensity());
  smooth(8);
  String[] cands = {"Microsoft YaHei", "PingFang SC", "Noto Sans CJK SC", "SimHei", "SansSerif"};
  List<String> avail = Arrays.asList(PFont.list());
  String fname = "SansSerif";
  for (String c : cands) if (avail.contains(c)) { fname = c; break; }
  font = createFont(fname, 24, true);
  textFont(font);
  works = loadJSONObject("scores.json").getJSONArray("artworks");
  if (args != null && Arrays.asList(args).contains("--export")) exportAll = true;
  layout();
}

boolean exportAll = false;
int exportTick = 0;
void exportStep() {
  if (!exportAll) return;
  if (++exportTick < 3) return;
  saveFrame("export/notation-" + works.getJSONObject(cur).getInt("aic_id") + ".png");
  exit();
}

// ───────────────────────── layout rules (identical to atlas_score) ─────────────────────────
boolean isRef(String id) { return REF.contains(id); }
boolean isDisk(String id) { JSONObject n = NODE.get(id); return n != null && !isRef(id) && n.getString("shape", "").equals("disk"); }

boolean opExists(JSONArray O, String type, String key, String id) {
  for (int i = 0; i < O.size(); i++) { JSONObject o = O.getJSONObject(i); if (o.getString("type").equals(type) && o.getString(key).equals(id)) return true; }
  return false;
}

float radiusFor(JSONObject r, boolean hasChildren) {
  String k = r.getString("kind");
  if (k.equals("experience")) return hasChildren ? 1.6 : 0.6;
  if (k.equals("world")) return hasChildren ? 1.7 : 1.1;
  if (k.equals("concept")) return 0.45;
  return 0.4;
}

void layout() {
  P.clear(); RAD.clear(); NODE.clear(); REF.clear(); frameNeeded = false;
  JSONObject a = works.getJSONObject(cur);
  JSONArray R = a.getJSONArray("referents"), C = a.getJSONArray("carriers"), O = a.getJSONArray("ops");
  RR = R; CC = C; OO = O;
  SEED = cur * 13.7;
  for (int i = 0; i < R.size(); i++) { JSONObject r = R.getJSONObject(i); NODE.put(r.getString("id"), r); REF.add(r.getString("id")); }
  for (int i = 0; i < C.size(); i++) { JSONObject c = C.getJSONObject(i); NODE.put(c.getString("id"), c); }

  // Rule 1 — carriers on the ground, spread along x.  Rule 2 — depth_time carrier pushed back (future = behind).
  int nc = C.size();
  for (int i = 0; i < nc; i++) {
    JSONObject c = C.getJSONObject(i); String id = c.getString("id");
    float x = (i - (nc - 1) / 2.0) * min(2.2, 8.0 / max(nc - 1, 1)), z = 1.8;
    if (opExists(O, "depth_time", "from", id)) z = -2.8;
    boolean disk = c.getString("shape", "cube").equals("disk");
    P.put(id, new PVector(x * U, disk ? -0.02 * U : -0.25 * U, (disk ? 0 : z) * U));
    RAD.put(id, disk ? 2.6 * U : 0.3 * U);
  }
  // Rule 3 — layer(from, to): from stacked above to.
  for (int i = 0; i < O.size(); i++) {
    JSONObject o = O.getJSONObject(i);
    if (o.getString("type").equals("layer")) { PVector t = P.get(o.getString("to")); P.put(o.getString("from"), new PVector(t.x, t.y - 0.9 * U, t.z)); }
  }
  // Rule 4 — height = chain depth.
  HashMap<String, Integer> lv = new HashMap<String, Integer>();
  for (String id : REF) lv.put(id, 1);
  for (int k = 0; k < 6; k++)
    for (int i = 0; i < O.size(); i++) {
      JSONObject o = O.getJSONObject(i); String f = o.getString("from"), t = o.getString("to");
      if (isRef(f) && isRef(t)) lv.put(t, max(lv.get(t), lv.get(f) + 1));
    }
  HashMap<String, ArrayList<String>> kids = new HashMap<String, ArrayList<String>>();
  TreeMap<Integer, ArrayList<String>> byLevel = new TreeMap<Integer, ArrayList<String>>();
  for (int i = 0; i < R.size(); i++) {
    JSONObject r = R.getJSONObject(i); String id = r.getString("id");
    if (r.hasKey("parent")) { String p = r.getString("parent"); if (!kids.containsKey(p)) kids.put(p, new ArrayList<String>()); kids.get(p).add(id); }
    else { int L = lv.get(id); if (!byLevel.containsKey(L)) byLevel.put(L, new ArrayList<String>()); byLevel.get(L).add(id); }
  }
  for (int L : byLevel.keySet()) {
    ArrayList<String> ids = byLevel.get(L); int n = ids.size();
    for (int j = 0; j < n; j++) {
      String id = ids.get(j); JSONObject r = NODE.get(id);
      float x = (j - (n - 1) / 2.0) * 3.4, y = -(2.6 + (L - 1) * 2.1), z = 0;
      if (r.getString("absence").equals("not_yet")) z = -2.4;                                   // Rule 5
      if (opExists(O, "witness", "to", id)) { z = 4.4; y = -1.9; x = 0; frameNeeded = true; }   // Rule 6
      if (r.getBoolean("viewer", false)) { y -= 1.4; x += 3.2; }                                // Rule 7
      if (r.getBoolean("inferred", false)) { x += 1.6; z += 1.4; }
      P.put(id, new PVector(x * U, y * U, z * U));
      RAD.put(id, radiusFor(r, kids.containsKey(id)) * U);
    }
  }
  // Rule 8 — contained referents inside their container.
  for (String p : kids.keySet()) {
    ArrayList<String> ids = kids.get(p); int n = ids.size(); PVector pc = P.get(p);
    for (int j = 0; j < n; j++) {
      JSONObject r = NODE.get(ids.get(j));
      float ox = (j - (n - 1) / 2.0) * 1.0, oz = r.getString("absence").equals("not_yet") ? -0.7 : 0.35;
      P.put(ids.get(j), new PVector(pc.x + ox * U, pc.y + 0.2 * U, pc.z + oz * U));
      RAD.put(ids.get(j), radiusFor(r, false) * U);
    }
  }
  // the observer of an impossible viewpoint sits outside the referent it looks at
  for (int i = 0; i < O.size(); i++) {
    JSONObject o = O.getJSONObject(i);
    if (o.getString("type").equals("impossible_viewpoint")) {
      PVector t = P.get(o.getString("to")); float r = RAD.get(o.getString("to"));
      P.put("EYE", new PVector(t.x + 0.8 * U, t.y - r - 1.3 * U, t.z + 0.5 * U)); RAD.put("EYE", 0.2 * U);
    }
  }
  // bounding box (ground = bottom face)
  float[] b = {99999, -99999, 99999, -99999, 99999, -99999};
  for (String id : P.keySet()) {
    PVector p = P.get(id); float r = RAD.get(id); float vr = isRef(id) ? r : 0.3 * U;
    b[0] = min(b[0], p.x - r); b[1] = max(b[1], p.x + r);
    b[2] = min(b[2], p.y - vr); b[3] = max(b[3], p.y + vr);
    b[4] = min(b[4], p.z - r); b[5] = max(b[5], p.z + r);
  }
  if (frameNeeded) { b[0] = min(b[0], -4.2 * U); b[1] = max(b[1], 4.2 * U); b[2] = min(b[2], -4.4 * U); }
  float pad = 0.5 * U;
  BB[0] = b[0] - pad; BB[1] = b[1] + pad; BB[2] = b[2] - pad; BB[3] = 0; BB[4] = b[4] - pad; BB[5] = b[5] + pad;
}

// ───────────────────────── projection (axonometric) ─────────────────────────
PVector rot(PVector p) {
  float x1 = p.x * cos(ry) + p.z * sin(ry), z1 = -p.x * sin(ry) + p.z * cos(ry);
  float y2 = p.y * cos(rx) + z1 * sin(rx), z2 = -p.y * sin(rx) + z1 * cos(rx);
  return new PVector(x1, y2, z2);
}
PVector pr(PVector p) { PVector r = rot(p); return new PVector(CX + r.x * S, CY + r.y * S); }
PVector pr(float x, float y, float z) { return pr(new PVector(x, y, z)); }

void fit() {
  float mnx = 99999, mxx = -99999, mny = 99999, mxy = -99999;
  for (int i = 0; i < 8; i++) {
    PVector r = rot(new PVector(BB[(i & 1)], BB[2 + ((i >> 1) & 1)], BB[4 + ((i >> 2) & 1)]));
    mnx = min(mnx, r.x); mxx = max(mxx, r.x); mny = min(mny, r.y); mxy = max(mxy, r.y);
  }
  float aw = width - 120, ah = height - 400;
  S = min(aw / (mxx - mnx), ah / (mxy - mny));
  CX = width / 2.0 - (mnx + mxx) / 2 * S;
  CY = 120 + ah / 2.0 - (mny + mxy) / 2 * S;
}

PVector sc(String id) { return pr(P.get(id)); }
float refR(String id) { return max(12, RAD.get(id) * S * 0.85); }
PVector edge(String id, PVector toward) {
  PVector c = sc(id); float r = isRef(id) ? refR(id) : (isDisk(id) ? 0 : 9);
  PVector d = PVector.sub(toward, c); if (d.mag() < 0.01) return c;
  d.normalize(); return PVector.add(c, PVector.mult(d, r));
}

// ───────────────────────── ink: paths, wobble, line modes ─────────────────────────
ArrayList<PVector> seg(PVector a, PVector b, float bend) {
  ArrayList<PVector> out = new ArrayList<PVector>();
  float L = PVector.dist(a, b); int n = max(2, int(L / 3));
  PVector nrm = new PVector(-(b.y - a.y), b.x - a.x); if (nrm.mag() > 0) nrm.normalize();
  PVector m = PVector.add(PVector.lerp(a, b, 0.5), PVector.mult(nrm, bend * L));
  for (int i = 0; i <= n; i++) {
    float t = i / (float) n, u = 1 - t;
    out.add(new PVector(u * u * a.x + 2 * u * t * m.x + t * t * b.x, u * u * a.y + 2 * u * t * m.y + t * t * b.y));
  }
  return out;
}
ArrayList<PVector> arcP(float cx, float cy, float r, float a0, float a1) {
  ArrayList<PVector> out = new ArrayList<PVector>();
  int n = max(10, int(abs(a1 - a0) * r / 3));
  for (int i = 0; i <= n; i++) { float a = lerp(a0, a1, i / (float) n); out.add(new PVector(cx + cos(a) * r, cy + sin(a) * r)); }
  return out;
}
ArrayList<PVector> circP(PVector c, float r) { return arcP(c.x, c.y, r, 0, TWO_PI); }
ArrayList<PVector> ringXZ(PVector c, float R) {
  ArrayList<PVector> out = new ArrayList<PVector>();
  for (int i = 0; i <= 120; i++) { float a = TWO_PI * i / 120; out.add(pr(c.x + cos(a) * R, c.y, c.z + sin(a) * R)); }
  return out;
}

void drawPath(ArrayList<PVector> pts) {
  int n = pts.size(); if (n < 2) return;
  PVector[] q = new PVector[n];
  for (int i = 0; i < n; i++) {
    PVector p = pts.get(i);
    float jx = (noise(p.x * 0.025, p.y * 0.025, SEED) - 0.5) * 2 * JIT;
    float jy = (noise(p.x * 0.025 + 40, p.y * 0.025 + 40, SEED) - 0.5) * 2 * JIT;
    q[i] = new PVector(p.x + jx, p.y + jy);
  }
  if (MODE == 0) {
    noFill(); stroke(INK, ALPHA); strokeWeight(W);
    beginShape(); for (PVector p : q) vertex(p.x, p.y); endShape();
    return;
  }
  float acc = 0, next = 0;
  for (int i = 1; i < n; i++) {
    float L = PVector.dist(q[i - 1], q[i]);
    if (MODE == 1) {
      if ((acc % 11) < 6.5) { stroke(INK, ALPHA); strokeWeight(W); line(q[i - 1].x, q[i - 1].y, q[i].x, q[i].y); }
    } else {
      noStroke(); fill(INK, ALPHA);
      while (next <= acc + L) {
        float t = (next - acc) / max(L, 0.001);
        ellipse(lerp(q[i - 1].x, q[i].x, t), lerp(q[i - 1].y, q[i].y, t), W * 1.7, W * 1.7);
        next += 5;
      }
    }
    acc += L;
  }
}
void markOn() { savedMode = MODE; MODE = 0; }
void markOff() { MODE = savedMode; }
PVector at(ArrayList<PVector> p, float t) { return p.get(constrain(round(t * (p.size() - 1)), 0, p.size() - 1)).copy(); }
PVector tng(ArrayList<PVector> p, float t) {
  int i = constrain(round(t * (p.size() - 1)), 1, p.size() - 1);
  PVector d = PVector.sub(p.get(i), p.get(i - 1)); d.normalize(); return d;
}
void tickAt(PVector c, PVector d, float len) {
  PVector n = new PVector(-d.y, d.x); n.mult(len);
  drawPath(seg(PVector.sub(c, n), PVector.add(c, n), 0));
}
void dot(PVector c, float r) { noStroke(); fill(INK, ALPHA); ellipse(c.x, c.y, r * 2, r * 2); }
void ring(PVector c, float r) { drawPath(circP(c, r)); }
PVector polar(PVector c, float a, float r) { return new PVector(c.x + cos(a) * r, c.y + sin(a) * r); }

void evidence(String e) {
  if (e.equals("text"))       { MODE = 0; W = 1.25; INK = 0;   ALPHA = 255; }
  else if (e.equals("image")) { MODE = 1; W = 0.9;  INK = 40;  ALPHA = 235; }
  else                        { MODE = 2; W = 1.0;  INK = 140; ALPHA = 220; }
}

// ───────────────────────── operation glyphs (screen space) ─────────────────────────
void gSubstitute(PVector a, PVector b) {            // = : one thing stands for another
  ArrayList<PVector> p = seg(a, b, 0.06); drawPath(p);
  markOn(); tickAt(at(p, 0.78), tng(p, 0.78), 5 * GS); tickAt(at(p, 0.85), tng(p, 0.85), 5 * GS); markOff();
  dot(b, 2.4 * GS);
}
void gInscribe(PVector a, PVector b) {              // ≡ : written words
  ArrayList<PVector> p = seg(a, b, 0); drawPath(p); float L = max(PVector.dist(a, b), 1);
  markOn(); for (int k = 0; k < 3; k++) { float t = (8 + k * 4.5) * GS / L; tickAt(at(p, t), tng(p, t), 5.5 * GS); } markOff();
  ring(b, 3 * GS);
}
void gDepth(PVector a, PVector b) {                 // ○○◯ : depth = time, growing toward the future
  ArrayList<PVector> p = seg(a, b, 0.04); drawPath(p);
  markOn(); ring(at(p, 0.35), 2.5 * GS); ring(at(p, 0.56), 4.5 * GS); ring(at(p, 0.78), 7 * GS); markOff();
  dot(a, 2 * GS);
}
void gAnachronism(PVector a, PVector b) {           // ∿ : wrong time braided in
  ArrayList<PVector> p = new ArrayList<PVector>(); float L = PVector.dist(a, b); int n = max(8, int(L / 2));
  PVector d = PVector.sub(b, a); d.normalize(); PVector nr = new PVector(-d.y, d.x);
  for (int i = 0; i <= n; i++) { float t = i / (float) n; PVector q = PVector.lerp(a, b, t); q.add(PVector.mult(nr, sin(t * L / (5 * GS)) * 3.2 * GS * sin(PI * t))); p.add(q); }
  drawPath(p); dot(b, 2.4 * GS);
}
void gSynecdoche(PVector a, PVector b) {            // ))))) : the part opens onto the whole
  ArrayList<PVector> p = seg(a, b, 0); drawPath(p);
  markOn();
  for (int k = 0; k < 5; k++) { float t = 0.3 + k * 0.11; PVector c = at(p, t), d = tng(p, t); float an = atan2(d.y, d.x), r = (2.5 + k * 1.6) * GS; drawPath(arcP(c.x, c.y, r, an - HALF_PI, an + HALF_PI)); }
  markOff();
}
void gFan(PVector a, PVector c, float rr, int n) {  // comb of strokes: carrier opens into an inner/absent space
  float base = atan2(a.y - c.y, a.x - c.x);
  for (int i = 0; i < n; i++) {
    float f = n == 1 ? 0 : map(i, 0, n - 1, -1, 1);
    PVector tgt = polar(c, base + f * 0.95, rr);
    drawPath(seg(a, tgt, f * 0.22)); dot(tgt, 1.3 * GS);
  }
  dot(a, 2.2 * GS);
}
void gWitness(ArrayList<PVector> src, PVector b) {  // converging sightlines toward what is off-frame
  for (PVector s : src) drawPath(seg(s, b, 0));
  markOn(); ring(b, 4 * GS); markOff();
}
void gView(PVector eye, ArrayList<PVector> rim) {   // ● with projection rays: a viewpoint nobody can occupy
  for (PVector r : rim) drawPath(seg(eye, r, 0));
  markOn(); dot(eye, 5 * GS); ring(eye, 10 * GS); markOff();
}
void gRadiate(PVector c, ArrayList<PVector> rim) {  // radial spokes with tally ticks
  for (int i = 0; i < rim.size(); i++) {
    ArrayList<PVector> p = seg(c, rim.get(i), 0); drawPath(p); dot(rim.get(i), 2 * GS);
    markOn(); for (int k = 0; k <= i % 3; k++) { float t = 0.86 - k * 0.035; tickAt(at(p, t), tng(p, t), 3.5 * GS); } markOff();
  }
}
void gForks(PVector c, float rr, int n, float s) {  // ψ : the absent takes on a body
  markOn();
  for (int i = 0; i < n; i++) {
    float an = i * TWO_PI / n - HALF_PI + 0.3;
    PVector base = polar(c, an, rr), tip = polar(c, an, rr + s);
    drawPath(seg(base, tip, 0));
    for (int k = -1; k <= 1; k++) { PVector e = polar(tip, an + k * 0.45, s * 0.7); drawPath(seg(tip, e, 0)); dot(e, 1.3 * GS); }
  }
  markOff();
}
void gJuxtapose(PVector a, PVector b) {             // dotted arch: two carriers set side by side
  ArrayList<PVector> p = seg(a, b, -0.35); drawPath(p);
  markOn(); for (int k = 1; k < 10; k++) dot(at(p, k / 10.0), 1.6 * GS); markOff();
}
void gLayer(PVector a, PVector b) {                 // ladder: stacked registers
  ArrayList<PVector> p = seg(a, b, 0); drawPath(p);
  markOn(); for (int k = 0; k < 4; k++) { float t = 0.2 + k * 0.2; tickAt(at(p, t), tng(p, t), 6 * GS); } markOff();
}
void gRepeat(PVector a, PVector b) {                // ⁙ dot grid: the same unit counted out
  ArrayList<PVector> p = seg(a, b, 0.05); drawPath(p);
  PVector c = at(p, 0.5), d = tng(p, 0.5), nr = new PVector(-d.y * 14 * GS, d.x * 14 * GS); c.add(nr);
  markOn(); for (int i = -1; i <= 1; i++) for (int j = -1; j <= 1; j++) dot(new PVector(c.x + i * 4.5 * GS, c.y + j * 4.5 * GS), 1.4 * GS); markOff();
}
void gActivate(PVector a, PVector b) {              // ●○○ rising: the carrier acts on the referent
  ArrayList<PVector> p = seg(a, b, -0.12); drawPath(p);
  markOn(); for (int k = 0; k < 4; k++) { float t = (k / 4.0 + frameCount * 0.003) % 1; ring(at(p, 0.1 + t * 0.8), (2 + t * 2.5) * GS); } markOff();
  dot(a, 3.5 * GS);
}

// ───────────────────────── draw ─────────────────────────
void draw() {
  background(255);
  fit();
  noiseSeed(7);
  LBL.clear();
  drawStage();
  for (int i = 0; i < CC.size(); i++) drawCarrier(CC.getJSONObject(i));
  for (int i = 0; i < OO.size(); i++) drawOp(OO.getJSONObject(i));
  for (int i = 0; i < RR.size(); i++) drawRef(RR.getJSONObject(i));
  if (showLabels) drawLabels();
  drawTitle();
  drawLegend();
  exportStep();
}

void line3(float x0, float y0, float z0, float x1, float y1, float z1) { drawPath(seg(pr(x0, y0, z0), pr(x1, y1, z1), 0)); }

void drawStage() {
  float x0 = BB[0], x1 = BB[1], y0 = BB[2], y1 = BB[3], z0 = BB[4], z1 = BB[5];
  JIT = 0; MODE = 0; ALPHA = 255;
  // ground grid = visible world
  INK = 232; W = 0.5;
  for (float x = ceil(x0 / U) * U; x <= x1; x += U) line3(x, 0, z0, x, 0, z1);
  for (float z = ceil(z0 / U) * U; z <= z1; z += U) line3(x0, 0, z, x1, 0, z);
  // level plates: one per height of the referent chain
  INK = 212; W = 0.5;
  HashSet<Integer> ys = new HashSet<Integer>();
  for (int i = 0; i < RR.size(); i++) { JSONObject r = RR.getJSONObject(i); if (!r.hasKey("parent")) ys.add(round(P.get(r.getString("id")).y)); }
  for (int yy : ys) {
    line3(x0, yy, z0, x1, yy, z0); line3(x1, yy, z0, x1, yy, z1); line3(x1, yy, z1, x0, yy, z1); line3(x0, yy, z1, x0, yy, z0);
  }
  // box
  INK = 185; W = 0.6;
  float[][] e = {{x0,y0,z0,x1,y0,z0},{x1,y0,z0,x1,y0,z1},{x1,y0,z1,x0,y0,z1},{x0,y0,z1,x0,y0,z0},
                 {x0,y1,z0,x1,y1,z0},{x1,y1,z0,x1,y1,z1},{x1,y1,z1,x0,y1,z1},{x0,y1,z1,x0,y1,z0},
                 {x0,y0,z0,x0,y1,z0},{x1,y0,z0,x1,y1,z0},{x1,y0,z1,x1,y1,z1},{x0,y0,z1,x0,y1,z1}};
  for (float[] s : e) line3(s[0], s[1], s[2], s[3], s[4], s[5]);
  // ruler on the front-left vertical edge: one tick per unit of height
  for (float y = 0; y >= y0; y -= U) { PVector p = pr(x0, y, z1); line(p.x - 4, p.y, p.x, p.y); }
  // corner crosses
  INK = 150;
  for (int i = 0; i < 8; i++) {
    PVector p = pr((i & 1) == 0 ? x0 : x1, ((i >> 1) & 1) == 0 ? y0 : y1, ((i >> 2) & 1) == 0 ? z0 : z1);
    stroke(INK); strokeWeight(0.6); line(p.x - 3, p.y - 3, p.x + 3, p.y + 3); line(p.x - 3, p.y + 3, p.x + 3, p.y - 3);
  }
  // picture frame (only when something is witnessed from outside it)
  if (frameNeeded) {
    INK = 110; W = 0.8; MODE = 1; float z = 3.3 * U;
    line3(-4.2 * U, 0, z, 4.2 * U, 0, z); line3(4.2 * U, 0, z, 4.2 * U, -4.4 * U, z);
    line3(4.2 * U, -4.4 * U, z, -4.2 * U, -4.4 * U, z); line3(-4.2 * U, -4.4 * U, z, -4.2 * U, 0, z);
    PVector p = pr(4.2 * U, -4.4 * U, z); label(zh ? "画框" : "picture frame", p.x + 5, p.y - 4, 120, 10);
  }
  MODE = 0; JIT = 1.1;
}

String nm(JSONObject n) { return zh ? n.getString("zh") : n.getString("en"); }

ArrayList<PVector> subsScreen(String id) {
  PVector c = sc(id); int k = NODE.get(id).getInt("count", 1);
  ArrayList<PVector> out = new ArrayList<PVector>();
  if (k == 1) out.add(c);
  else if (k == 3) { out.add(new PVector(c.x - 7, c.y + 4)); out.add(new PVector(c.x + 7, c.y + 4)); out.add(new PVector(c.x, c.y - 7)); }
  else if (k == 5) { out.add(c); for (int i = 0; i < 4; i++) out.add(polar(c, QUARTER_PI + i * HALF_PI, 10)); }
  else for (int i = 0; i < k; i++) out.add(new PVector(c.x + (i - (k - 1) / 2.0) * 9, c.y));
  return out;
}

void drawCarrier(JSONObject c) {
  String id = c.getString("id"); MODE = 0; INK = 0; ALPHA = 255; W = 1.2; GS = 1;
  if (isDisk(id)) {
    PVector cc = P.get(id); float R = RAD.get(id);
    drawPath(ringXZ(cc, R)); W = 0.7; drawPath(ringXZ(cc, R * 0.94));
    stroke(0); strokeWeight(0.6);
    for (int i = 0; i < 90; i++) {
      float a = TWO_PI * i / 90; float r2 = i % 5 == 0 ? 0.88 : 0.915;
      PVector p1 = pr(cc.x + cos(a) * R * 0.94, cc.y, cc.z + sin(a) * R * 0.94), p2 = pr(cc.x + cos(a) * R * r2, cc.y, cc.z + sin(a) * R * r2);
      line(p1.x, p1.y, p2.x, p2.y);
    }
    dot(sc(id), 2.5);
    PVector f = pr(cc.x, cc.y, cc.z + R); label(nm(c), f.x + 8, f.y + 16, 40, 11);
  } else {
    for (PVector s : subsScreen(id)) dot(s, 4.2);
    PVector p = sc(id); label(nm(c), p.x + 10, p.y + 20, 40, 11);
  }
}

void drawOp(JSONObject o) {
  String t = o.getString("type"), f = o.getString("from"), to = o.getString("to"), e = o.getString("evidence");
  if (e.equals("inference") && !showInfer) return;
  evidence(e); GS = 1; JIT = 1.1;
  PVector A0 = sc(f), B0 = sc(to), a = edge(f, B0), b = edge(to, A0);
  if (t.equals("substitute")) gSubstitute(a, b);
  else if (t.equals("inscribe")) gInscribe(a, b);
  else if (t.equals("depth_time")) gDepth(a, b);
  else if (t.equals("anachronism")) gAnachronism(a, b);
  else if (t.equals("synecdoche")) gSynecdoche(a, b);
  else if (t.equals("externalize")) gFan(a, B0, isRef(to) ? refR(to) : 9, 7);
  else if (t.equals("personify")) gFan(a, B0, isRef(to) ? refR(to) : 9, 4);
  else if (t.equals("witness")) gWitness(subsScreen(f), b);
  else if (t.equals("juxtapose")) gJuxtapose(a, b);
  else if (t.equals("layer")) gLayer(a, b);
  else if (t.equals("repeat")) gRepeat(a, b);
  else if (t.equals("activate")) gActivate(a, b);
  else if (t.equals("impossible_viewpoint") || t.equals("radiate")) {
    PVector cc = P.get(f); float R = RAD.get(f);
    ArrayList<PVector> rim = new ArrayList<PVector>();
    int n = t.equals("radiate") ? 12 : 9; float k = t.equals("radiate") ? 0.94 : 1.0;
    for (int i = 0; i < n; i++) { float an = TWO_PI * i / n + 0.15; rim.add(pr(cc.x + cos(an) * R * k, cc.y, cc.z + sin(an) * R * k)); }
    if (t.equals("radiate")) gRadiate(A0, rim); else gView(sc("EYE"), rim);
  }
  else if (t.equals("embody")) { gSubstitute(a, b); gForks(B0, refR(to), 5, 9); }
  else drawPath(seg(a, b, 0));
}

void absenceMark(String ab, PVector m, float rr, PVector c) {
  markOn();
  if (ab.equals("inner")) { ring(m, 3.2); dot(m, 1.1); }
  else if (ab.equals("supernatural")) { for (int k = 0; k < 6; k++) { PVector e = polar(m, k * PI / 3, 5.5); drawPath(seg(m, e, 0)); dot(e, 1.1); } }
  else if (ab.equals("unreachable")) { drawPath(seg(new PVector(m.x - 4, m.y + 3), new PVector(m.x - 1, m.y - 4), 0)); drawPath(seg(new PVector(m.x + 1, m.y + 3), new PVector(m.x + 4, m.y - 4), 0)); }
  else if (ab.equals("nonexistent")) { drawPath(seg(new PVector(m.x - 3.5, m.y - 3.5), new PVector(m.x + 3.5, m.y + 3.5), 0)); drawPath(seg(new PVector(m.x - 3.5, m.y + 3.5), new PVector(m.x + 3.5, m.y - 3.5), 0)); }
  else if (ab.equals("not_yet")) { for (int k = 0; k < 2; k++) { float x = m.x - 3 + k * 4; drawPath(seg(new PVector(x - 2, m.y - 3.5), new PVector(x + 1.5, m.y), 0)); drawPath(seg(new PVector(x + 1.5, m.y), new PVector(x - 2, m.y + 3.5), 0)); } }
  else ring(m, 2.6);                                                                    // invisible
  markOff();
  if (ab.equals("not_yet") && c != null) { int s = MODE; MODE = 1; ring(c, rr + 6); MODE = s; }
}

void drawRef(JSONObject r) {
  String id = r.getString("id"); boolean inf = r.getBoolean("inferred", false);
  if (inf && !showInfer) return;
  PVector c = sc(id); float rr = refR(id); PVector w = P.get(id); GS = 1;
  // drop line to the ground: how far above the visible world this referent sits
  if (!r.hasKey("parent")) {
    JIT = 0.4; MODE = 2; INK = 175; ALPHA = 255; W = 0.8;
    PVector g = pr(w.x, 0, w.z);
    drawPath(seg(new PVector(c.x, c.y + rr), g, 0));
    stroke(150); strokeWeight(0.7); line(g.x - 4, g.y, g.x + 4, g.y); line(g.x, g.y - 2, g.x, g.y + 2);
  }
  JIT = 1.1;
  if (inf) { MODE = 2; INK = 140; W = 1.0; ALPHA = 220; } else { MODE = 0; INK = 0; W = 1.05; ALPHA = 255; }
  String k = r.getString("kind");
  if (k.equals("experience")) { ring(c, rr); W *= 0.8; drawPath(circP(new PVector(c.x + rr * 0.16, c.y + rr * 0.1), rr * 0.74)); }
  else if (k.equals("world")) { ring(c, rr); W *= 0.8; ring(c, rr * 0.86); for (int i = 0; i < 8; i++) dot(polar(c, i * TWO_PI / 8 + 0.3, rr), 2.2); }
  else if (k.equals("concept")) { ring(c, rr); W *= 0.8; ring(c, rr * 0.62); ring(c, rr * 0.28); }
  else if (k.equals("event")) { drawPath(arcP(c.x, c.y, rr, -0.4, TWO_PI - 1.3)); dot(polar(c, TWO_PI - 1.3, rr), 2.2); }
  else { ring(c, rr); dot(c, 1.8); }                                                     // being
  if (r.getBoolean("embodied", false)) dot(c, 5);
  W = 1.0;
  PVector m = polar(c, -QUARTER_PI, rr + 9);
  absenceMark(r.getString("absence"), m, rr, c);
  if (r.getBoolean("viewer", false)) {                                                   // addressed to the viewer: a small eye
    PVector v = polar(c, PI - 0.5, rr + 12);
    markOn(); drawPath(arcP(v.x, v.y + 4, 6, PI + 0.5, TWO_PI - 0.5)); drawPath(arcP(v.x, v.y - 4, 6, 0.5, PI - 0.5)); dot(v, 1.6); markOff();
  }
  label(nm(r), m.x + 9, m.y + 4, inf ? 140 : 20, 11.5);
}

// ───────────────────────── labels ─────────────────────────
class Lb { String t; float x, y, sz; int g; Lb(String t, float x, float y, int g, float sz) { this.t = t; this.x = x; this.y = y; this.g = g; this.sz = sz; } }
ArrayList<Lb> LBL = new ArrayList<Lb>();
void label(String t, float x, float y, int g, float sz) { LBL.add(new Lb(t, x, y, g, sz)); }
void drawLabels() {
  ArrayList<float[]> used = new ArrayList<float[]>();
  for (Lb l : LBL) {
    textSize(l.sz); float w = textWidth(l.t), h = l.sz + 3, y = l.y;
    for (int it = 0; it < 12; it++) {
      boolean hit = false;
      for (float[] u : used) if (l.x < u[0] + u[2] && l.x + w > u[0] && y - h < u[1] && y > u[1] - u[3]) { hit = true; break; }
      if (!hit) break; y += h;
    }
    used.add(new float[]{l.x, y, w, h});
    noStroke(); fill(255, 215); rect(l.x - 2, y - l.sz, w + 4, l.sz + 4);
    fill(l.g); textAlign(LEFT, BASELINE); text(l.t, l.x, y);
  }
}

// ───────────────────────── title & legend ─────────────────────────
String[] ORDER = {"externalize", "personify", "embody", "inscribe", "substitute", "synecdoche", "depth_time", "anachronism",
                  "layer", "radiate", "repeat", "juxtapose", "witness", "impossible_viewpoint", "activate"};
String[] ORDER_ZH = {"外化", "拟人化", "赋形", "铭写", "象征替代", "提喻", "纵深=时间", "时代错置",
                     "分层", "中心辐射", "重复", "并置", "见证", "不可能视点", "仪式激活"};

void drawTitle() {
  JSONObject a = works.getJSONObject(cur);
  textAlign(LEFT, BASELINE); fill(0); textSize(15);
  text(a.getString("title"), 44, 52);
  fill(90); textSize(11);
  text("AIC " + a.getInt("aic_id") + "  /  " + a.getString("artist") + "  /  " + a.getString("date").replace("–", "-")
       + (a.getBoolean("public_domain") ? "" : "  /  NOT public domain"), 44, 72);
  textAlign(RIGHT, BASELINE); fill(140); textSize(10);
  text("IMAGINATION SCORE  |  Exp 01  |  " + (cur + 1) + " / " + works.size(), width - 44, 52);
  textAlign(LEFT, BASELINE);
}

void icon(String t, float x, float y, String e) {
  evidence(e); GS = 0.6; JIT = 0.5;
  PVector a = new PVector(x, y + 16), b = new PVector(x + 24, y);
  if (t.equals("substitute")) gSubstitute(a, b);
  else if (t.equals("inscribe")) gInscribe(a, b);
  else if (t.equals("depth_time")) gDepth(a, b);
  else if (t.equals("anachronism")) gAnachronism(a, b);
  else if (t.equals("synecdoche")) gSynecdoche(a, b);
  else if (t.equals("externalize")) gFan(a, new PVector(x + 22, y + 3), 7, 5);
  else if (t.equals("personify")) gFan(a, new PVector(x + 22, y + 3), 7, 3);
  else if (t.equals("juxtapose")) gJuxtapose(new PVector(x, y + 16), new PVector(x + 24, y + 16));
  else if (t.equals("layer")) gLayer(new PVector(x + 12, y + 18), new PVector(x + 12, y - 2));
  else if (t.equals("repeat")) gRepeat(a, b);
  else if (t.equals("activate")) gActivate(a, b);
  else if (t.equals("witness")) { ArrayList<PVector> s = new ArrayList<PVector>(); for (int i = 0; i < 3; i++) s.add(new PVector(x + i * 5, y + 17)); gWitness(s, b); }
  else if (t.equals("impossible_viewpoint")) { ArrayList<PVector> s = new ArrayList<PVector>(); for (int i = 0; i < 4; i++) s.add(new PVector(x + i * 6, y + 18)); gView(new PVector(x + 20, y), s); }
  else if (t.equals("radiate")) { ArrayList<PVector> s = new ArrayList<PVector>(); PVector c = new PVector(x + 12, y + 8); for (int i = 0; i < 8; i++) s.add(polar(c, i * TWO_PI / 8, 10)); gRadiate(c, s); }
  else if (t.equals("embody")) { PVector c = new PVector(x + 12, y + 9); MODE = 0; ring(c, 3.5); evidence(e); gForks(c, 3.5, 3, 5); }
  GS = 1; JIT = 1.1;
}

void drawLegend() {
  float top = height - 255, x0 = 44;
  stroke(200); strokeWeight(0.6); line(x0, top - 18, width - 44, top - 18);
  // signature: one glyph per operation found, in the style of its evidence
  textAlign(LEFT, BASELINE); fill(0); textSize(10.5);
  text(zh ? "签名  一个符号 = 一次操作（实线 = 文本证据，计入签名）" : "SIGNATURE  one glyph per operation (solid = text evidence, counted)", x0, top);
  float y = top + 16;
  for (int k = 0; k < ORDER.length; k++) {
    ArrayList<String> evs = new ArrayList<String>(); int nText = 0;
    for (int i = 0; i < OO.size(); i++) {
      JSONObject o = OO.getJSONObject(i);
      if (!o.getString("type").equals(ORDER[k])) continue;
      if (o.getString("evidence").equals("inference") && !showInfer) continue;
      evs.add(o.getString("evidence")); if (o.getString("evidence").equals("text")) nText++;
    }
    if (evs.size() == 0) continue;
    fill(60); textSize(10.5); textAlign(LEFT, BASELINE);
    text((zh ? ORDER_ZH[k] : ORDER[k].replace("_", " ")) + "  " + nText, x0, y + 13);
    for (int i = 0; i < evs.size(); i++) icon(ORDER[k], x0 + 110 + i * 38, y, evs.get(i));
    y += 26;
  }
  // key: evidence, absence, kind
  float kx = width / 2.0 + 30, ky = top;
  fill(0); textSize(10.5); text(zh ? "证据" : "EVIDENCE", kx, ky);
  String[] ev = {"text", "image", "inference"}; String[] evz = {"文本（AIC 描述原文）", "仅图像观察", "推断（不计分）"};
  for (int i = 0; i < 3; i++) {
    evidence(ev[i]); JIT = 0.5; drawPath(seg(new PVector(kx, ky + 16 + i * 16), new PVector(kx + 36, ky + 16 + i * 16), 0));
    fill(70); textSize(10); text(zh ? evz[i] : ev[i], kx + 46, ky + 20 + i * 16);
  }
  ky += 70;
  fill(0); textSize(10.5); text(zh ? "缺席方式" : "ABSENCE", kx, ky);
  String[] ab = {"inner", "invisible", "unreachable", "nonexistent", "not_yet", "supernatural"};
  String[] abz = {"内在", "不可见", "不可达", "不存在", "未至", "超自然"};
  MODE = 0; INK = 0; ALPHA = 255; W = 1.0; JIT = 0.4;
  for (int i = 0; i < 6; i++) {
    float xx = kx + (i % 3) * 120, yy = ky + 18 + (i / 3) * 20;
    absenceMark(ab[i], new PVector(xx + 6, yy - 4), 0, null);
    fill(70); textSize(10); text(zh ? abz[i] : ab[i].replace("_", " "), xx + 18, yy);
  }
  ky += 62;
  fill(0); textSize(10.5); text(zh ? "对象种类" : "KIND", kx, ky);
  String[] kd = {"being", "experience", "event", "concept", "world"}; String[] kdz = {"存在者", "经验", "事件", "概念", "世界"};
  for (int i = 0; i < 5; i++) {
    float xx = kx + i * 72; PVector c = new PVector(xx + 8, ky + 18); float rr = 7;
    MODE = 0; INK = 0; W = 0.9;
    if (kd[i].equals("experience")) { ring(c, rr); drawPath(circP(new PVector(c.x + 1.2, c.y + 0.8), rr * 0.74)); }
    else if (kd[i].equals("world")) { ring(c, rr); ring(c, rr * 0.8); for (int j = 0; j < 6; j++) dot(polar(c, j * TWO_PI / 6, rr), 1.2); }
    else if (kd[i].equals("concept")) { ring(c, rr); ring(c, rr * 0.6); ring(c, rr * 0.25); }
    else if (kd[i].equals("event")) drawPath(arcP(c.x, c.y, rr, -0.4, TWO_PI - 1.3));
    else { ring(c, rr); dot(c, 1.2); }
    fill(70); textSize(10); text(zh ? kdz[i] : kd[i], xx + 19, ky + 22);
  }
  fill(110); textSize(9.5);
  text(zh ? "● 可见载体   ● 大实心 = 在图中有形体   ┊ 点线 = 离地高度   ⊢ 刻度 = 1 层" : "● visible carrier   ● large = embodied in the image   ┊ dotted = height above ground   ⊢ tick = 1 unit",
       kx, ky + 52);
  JIT = 1.1;
}

// ───────────────────────── interaction ─────────────────────────
void mouseDragged() { ry += (mouseX - pmouseX) * 0.008; rx = constrain(rx + (mouseY - pmouseY) * 0.006, 0.05, 1.45); }
void keyPressed() {
  if (keyCode == RIGHT) { cur = (cur + 1) % works.size(); layout(); }
  else if (keyCode == LEFT) { cur = (cur - 1 + works.size()) % works.size(); layout(); }
  else if (key >= '1' && key <= '9' && key - '1' < works.size()) { cur = key - '1'; layout(); }
  else if (key == 'l' || key == 'L') showLabels = !showLabels;
  else if (key == 't' || key == 'T') zh = !zh;
  else if (key == 'i' || key == 'I') showInfer = !showInfer;
  else if (key == 'r' || key == 'R') { rx = 0.50; ry = 0.62; }
  else if (key == 's' || key == 'S') saveFrame("export/notation-" + works.getJSONObject(cur).getInt("aic_id") + "-####.png");
}
