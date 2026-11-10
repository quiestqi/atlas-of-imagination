// The Atlas of Imagination — Experiment 01 · Imagination Score (black & white) v0.1
// Reads data/scores.json; every position is computed by layout rules (see README.md), nothing is hand-placed.
//
// Keys:  ← → or 1–5 switch artwork   L labels   T 中文/English   G image evidence   I inference
//        B invert (black/white)   SPACE auto-rotate   R reset view   S save PNG (export/)
// Mouse: drag = rotate, wheel = zoom

import java.util.*;

JSONArray works;
int cur = 0;
float rx = -0.42, ry = 0.65, zoom = 0.72;
boolean showLabels = true, showImage = true, showInfer = false, invert = false, zh = true, spin = true;
PFont font;
final float U = 80;               // 1 layout unit in pixels

HashMap<String, PVector> P = new HashMap<String, PVector>();     // node centres
HashMap<String, Float> RAD = new HashMap<String, Float>();       // node radii
HashMap<String, JSONObject> NODE = new HashMap<String, JSONObject>();
HashSet<String> REF = new HashSet<String>();
ArrayList<Lb> labels = new ArrayList<Lb>();
boolean frameNeeded = false;

boolean DASH = false;             // current line style
int A = 255;                      // current alpha

class Lb { String t; float x, y; int a; boolean small; Lb(String t, float x, float y, int a, boolean s) { this.t=t; this.x=x; this.y=y; this.a=a; this.small=s; } }

void setup() {
  size(1280, 820, P3D);
  pixelDensity(displayDensity());
  smooth(8);
  String[] candidates = {"Microsoft YaHei", "PingFang SC", "Noto Sans CJK SC", "SimHei", "SansSerif"};
  List<String> avail = Arrays.asList(PFont.list());
  String fname = "SansSerif";
  for (String c : candidates) if (avail.contains(c)) { fname = c; break; }
  font = createFont(fname, 28, true);
  textFont(font);
  works = loadJSONObject("scores.json").getJSONArray("artworks");
  if (args != null && Arrays.asList(args).contains("--export-all")) { exportAll = true; spin = false; cur = 0; }
  layout();
}

// batch export: run with the argument --export-all to save one PNG per artwork, then quit
boolean exportAll = false;
int exportTick = 0;
void exportStep() {
  if (!exportAll) return;
  if (++exportTick < 4) return;
  saveFrame("export/score-" + (cur + 1) + "-" + works.getJSONObject(cur).getInt("aic_id") + ".png");
  exportTick = 0;
  if (++cur >= works.size()) exit(); else layout();
}

int FG() { return invert ? 255 : 0; }
int BG() { return invert ? 0 : 255; }

// ───────────────────────── layout rules ─────────────────────────
boolean isRef(String id) { return REF.contains(id); }

boolean opExists(JSONArray O, String type, String key, String id) {
  for (int i = 0; i < O.size(); i++) { JSONObject o = O.getJSONObject(i); if (o.getString("type").equals(type) && o.getString(key).equals(id)) return true; }
  return false;
}

float radiusFor(JSONObject r, boolean hasChildren) {
  String k = r.getString("kind");
  if (k.equals("experience")) return hasChildren ? 1.6 : 0.6;
  if (k.equals("world")) return hasChildren ? 1.7 : 1.1;
  if (k.equals("concept")) return 0.45;
  if (k.equals("event")) return 0.4;
  return 0.4;
}

void layout() {
  P.clear(); RAD.clear(); NODE.clear(); REF.clear(); frameNeeded = false;
  JSONObject a = works.getJSONObject(cur);
  JSONArray R = a.getJSONArray("referents"), C = a.getJSONArray("carriers"), O = a.getJSONArray("ops");
  for (int i = 0; i < R.size(); i++) { JSONObject r = R.getJSONObject(i); NODE.put(r.getString("id"), r); REF.add(r.getString("id")); }
  for (int i = 0; i < C.size(); i++) { JSONObject c = C.getJSONObject(i); NODE.put(c.getString("id"), c); }

  // Rule 1 — carriers sit on the ground (visible world), spread along x.
  // Rule 2 — a carrier used for depth_time is pushed back in z (the future lies behind).
  int nc = C.size();
  for (int i = 0; i < nc; i++) {
    JSONObject c = C.getJSONObject(i); String id = c.getString("id");
    float x = (i - (nc - 1) / 2.0) * min(2.2, 8.0 / max(nc - 1, 1)), z = 1.8;
    if (opExists(O, "depth_time", "from", id)) z = -2.8;
    boolean disk = c.getString("shape", "cube").equals("disk");
    P.put(id, new PVector(x * U, disk ? -0.02 * U : -0.25 * U, (disk ? 0 : z) * U));
    RAD.put(id, disk ? 2.6 * U : 0.3 * U);
  }
  // Rule 3 — layer(from, to): 'from' is stacked directly above 'to'.
  for (int i = 0; i < O.size(); i++) {
    JSONObject o = O.getJSONObject(i);
    if (o.getString("type").equals("layer")) { PVector t = P.get(o.getString("to")); P.put(o.getString("from"), new PVector(t.x, t.y - 0.9 * U, t.z)); }
  }

  // Rule 4 — height = chain depth: a referent reached from another referent sits one level higher.
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
      if (r.getString("absence").equals("not_yet")) z = -2.4;               // Rule 5 — future = depth
      if (opExists(O, "witness", "to", id)) { z = 4.4; y = -1.9; x = 0; frameNeeded = true; }  // Rule 6 — witnessed-only referent lies outside the picture frame
      if (r.getBoolean("viewer", false)) { y -= 1.4; x += 3.2; }            // Rule 7 — referent addressed to the viewer sits highest, outside the scene
      if (r.getBoolean("inferred", false)) { x += 1.6; z += 1.4; }
      P.put(id, new PVector(x * U, y * U, z * U));
      RAD.put(id, radiusFor(r, kids.containsKey(id)) * U);
    }
  }
  // Rule 8 — contained referents (parent) are placed inside their container; future ones toward the back.
  for (String p : kids.keySet()) {
    ArrayList<String> ids = kids.get(p); int n = ids.size(); PVector pc = P.get(p);
    for (int j = 0; j < n; j++) {
      JSONObject r = NODE.get(ids.get(j));
      float ox = (j - (n - 1) / 2.0) * 1.0, oz = r.getString("absence").equals("not_yet") ? -0.7 : 0.35;
      P.put(ids.get(j), new PVector(pc.x + ox * U, pc.y + 0.2 * U, pc.z + oz * U));
      RAD.put(ids.get(j), radiusFor(r, false) * U);
    }
  }
}

// ───────────────────────── geometry helpers ─────────────────────────
PVector[] basis(PVector d) {
  PVector up = abs(d.y) < 0.9 ? new PVector(0, 1, 0) : new PVector(1, 0, 0);
  PVector u = d.cross(up); u.normalize();
  PVector v = d.cross(u); v.normalize();
  return new PVector[]{u, v};
}
PVector lerpV(PVector a, PVector b, float t) { return PVector.lerp(a, b, t); }
PVector surf(PVector from, String id) {
  PVector c = P.get(id); PVector d = PVector.sub(from, c); d.normalize(); d.mult(RAD.get(id)); return PVector.add(c, d);
}
void ln(PVector a, PVector b) { if (DASH) dashed(a, b, 0.12 * U, 0.09 * U); else line(a.x, a.y, a.z, b.x, b.y, b.z); }
void dashed(PVector a, PVector b, float d, float g) {
  float L = PVector.dist(a, b); if (L < 1) return; PVector dir = PVector.sub(b, a); dir.normalize();
  for (float s = 0; s < L; s += d + g) { float e = min(s + d, L); line(a.x + dir.x * s, a.y + dir.y * s, a.z + dir.z * s, a.x + dir.x * e, a.y + dir.y * e, a.z + dir.z * e); }
}
void ring(PVector c, PVector dir, float r) {
  PVector[] b = basis(dir); noFill(); beginShape();
  for (int i = 0; i < 28; i++) { float t = TWO_PI * i / 28; vertex(c.x + (b[0].x * cos(t) + b[1].x * sin(t)) * r, c.y + (b[0].y * cos(t) + b[1].y * sin(t)) * r, c.z + (b[0].z * cos(t) + b[1].z * sin(t)) * r); }
  endShape(CLOSE);
}
void arrowHead(PVector a, PVector b) {
  PVector d = PVector.sub(b, a); d.normalize(); PVector[] bs = basis(d); float s = 0.13 * U;
  PVector base = PVector.sub(b, PVector.mult(d, 0.28 * U));
  for (int i = 0; i < 4; i++) { float t = HALF_PI * i; PVector p = PVector.add(base, PVector.add(PVector.mult(bs[0], cos(t) * s), PVector.mult(bs[1], sin(t) * s))); line(p.x, p.y, p.z, b.x, b.y, b.z); }
}
void label(String t, PVector p, int a, boolean small) { if (showLabels) labels.add(new Lb(t, screenX(p.x, p.y, p.z), screenY(p.x, p.y, p.z), a, small)); }
String nm(JSONObject o) { return zh ? o.getString("zh") : o.getString("en"); }

// sub-positions for carriers with count>1 (e.g. five women)
ArrayList<PVector> subs(String id) {
  ArrayList<PVector> out = new ArrayList<PVector>(); PVector c = P.get(id); JSONObject n = NODE.get(id);
  int k = (n != null && !isRef(id)) ? n.getInt("count", 1) : 1;
  if (k <= 1) { out.add(c.copy()); return out; }
  for (int i = 0; i < k; i++) { float t = (i - (k - 1) / 2.0); out.add(new PVector(c.x + t * 0.55 * U, c.y + 0.08 * U, c.z - abs(t) * 0.18 * U)); }
  return out;
}

// ───────────────────────── draw ─────────────────────────
void draw() {
  background(BG());
  labels.clear();
  pushMatrix();
  translate(width / 2, height * 0.6, 0);
  scale(zoom);
  rotateX(rx); rotateY(ry);
  if (spin && !mousePressed) ry += 0.0025;
  noLights();
  strokeWeight(1);
  drawGround();
  JSONObject a = works.getJSONObject(cur);
  drawCarriers(a.getJSONArray("carriers"));
  drawReferents(a.getJSONArray("referents"));
  JSONArray O = a.getJSONArray("ops");
  for (int i = 0; i < O.size(); i++) drawOp(O.getJSONObject(i));
  popMatrix();
  drawHUD(a);
  exportStep();
}

void drawGround() {
  stroke(FG(), 22); strokeWeight(1);
  for (int i = -5; i <= 5; i++) { line(i * U, 0, -5 * U, i * U, 0, 5 * U); line(-5 * U, 0, i * U, 5 * U, 0, i * U); }
  stroke(FG(), 70); dashed(new PVector(-5 * U, 0, -5 * U), new PVector(-5 * U, -6 * U, -5 * U), 0.2 * U, 0.15 * U);
  label(zh ? "不可见 ↑" : "invisible ↑", new PVector(-5 * U, -6.2 * U, -5 * U), 120, true);
  label(zh ? "可见（地面）" : "visible (ground)", new PVector(-5 * U, 0.3 * U, -5 * U), 120, true);
  if (frameNeeded) {
    stroke(FG(), 90); float z = 2.3 * U;
    PVector[] f = {new PVector(-4.2 * U, 0, z), new PVector(4.2 * U, 0, z), new PVector(4.2 * U, -4.4 * U, z), new PVector(-4.2 * U, -4.4 * U, z)};
    for (int i = 0; i < 4; i++) dashed(f[i], f[(i + 1) % 4], 0.22 * U, 0.14 * U);
    label(zh ? "画框" : "picture frame", new PVector(3.8 * U, -4.65 * U, z), 140, true);
  }
}

void drawCarriers(JSONArray C) {
  for (int i = 0; i < C.size(); i++) {
    JSONObject c = C.getJSONObject(i); String id = c.getString("id"); PVector p = P.get(id);
    if (c.getString("shape", "cube").equals("disk")) {
      pushMatrix(); translate(p.x, p.y, p.z); rotateX(HALF_PI); stroke(FG()); strokeWeight(1.3); noFill(); ellipse(0, 0, RAD.get(id) * 2, RAD.get(id) * 2);
      for (int k = 0; k < 72; k++) { float t = TWO_PI * k / 72, r = RAD.get(id); line(cos(t) * r, sin(t) * r, cos(t) * (r - (k % 6 == 0 ? 10 : 5)), sin(t) * (r - (k % 6 == 0 ? 10 : 5))); }
      popMatrix(); strokeWeight(1);
      label(nm(c), new PVector(p.x, p.y + 0.5 * U, p.z + RAD.get(id) + 0.3 * U), 200, false);
      continue;
    }
    ArrayList<PVector> ss = subs(id); float s = ss.size() > 1 ? 0.28 * U : 0.45 * U;
    for (PVector q : ss) { pushMatrix(); translate(q.x, q.y, q.z); fill(FG()); noStroke(); box(s); popMatrix(); }   // visible = solid
    label(nm(c), new PVector(p.x, p.y + 0.6 * U, p.z), 200, false);
  }
}

String absenceName(String a) {
  if (zh) { if (a.equals("inner")) return "内在"; if (a.equals("invisible")) return "不可见"; if (a.equals("unreachable")) return "不可达"; if (a.equals("nonexistent")) return "不存在"; if (a.equals("not_yet")) return "未至"; if (a.equals("supernatural")) return "神/超自然"; }
  return a.replace("_", " ");
}

void drawReferents(JSONArray R) {
  for (int i = 0; i < R.size(); i++) {
    JSONObject r = R.getJSONObject(i); String id = r.getString("id"); PVector p = P.get(id); float rad = RAD.get(id);
    boolean inf = r.getBoolean("inferred", false); if (inf && !showInfer) continue;
    int a = inf ? 45 : 255;
    boolean body = r.getBoolean("embodied", false);
    String k = r.getString("kind");
    pushMatrix(); translate(p.x, p.y, p.z);
    stroke(FG(), k.equals("experience") || k.equals("world") ? (int)(a * 0.45) : a); strokeWeight(1);
    if (body) fill(invert ? 90 : 170, a); else noFill();                           // embodied in the image = grey body; absent = wireframe only
    if (k.equals("concept")) { rotateY(frameCount * 0.01); octa(rad); }
    else if (k.equals("event")) { cone(rad); }
    else if (k.equals("world")) { rotateY(frameCount * 0.003); sphereDetail(10); sphere(rad); }
    else if (k.equals("experience")) { sphereDetail(18); sphere(rad); }
    else { sphereDetail(9); sphere(rad); }
    popMatrix();
    String tag = id + " " + nm(r) + " / " + absenceName(r.getString("absence"));
    label(tag, new PVector(p.x, p.y - rad - 0.3 * U, p.z), a, false);
  }
}
void octa(float r) {
  PVector[] v = {new PVector(r, 0, 0), new PVector(-r, 0, 0), new PVector(0, r, 0), new PVector(0, -r, 0), new PVector(0, 0, r), new PVector(0, 0, -r)};
  int[][] f = {{0, 2, 4}, {0, 4, 3}, {0, 3, 5}, {0, 5, 2}, {1, 2, 5}, {1, 5, 3}, {1, 3, 4}, {1, 4, 2}};
  beginShape(TRIANGLES); for (int[] t : f) for (int j : t) vertex(v[j].x, v[j].y, v[j].z); endShape();
}
void cone(float r) {   // points backwards (−z): an event "on its way"
  PVector apex = new PVector(0, 0, -r * 1.3);
  for (int i = 0; i < 16; i++) { float t = TWO_PI * i / 16; line(cos(t) * r * 0.8, sin(t) * r * 0.8, r * 0.6, apex.x, apex.y, apex.z); }
  ring(new PVector(0, 0, r * 0.6), new PVector(0, 0, 1), r * 0.8);
}

// ───────────────────────── operations (one glyph per operation) ─────────────────────────
String opName(String t) {
  String[][] m = {{"externalize", "外化", "externalize"}, {"inscribe", "铭写", "inscribe"}, {"substitute", "象征替代", "substitute"}, {"synecdoche", "提喻", "synecdoche"},
    {"depth_time", "纵深=时间", "depth = time"}, {"anachronism", "时代错置", "anachronism"}, {"juxtapose", "并置", "juxtapose"}, {"witness", "见证", "witness"},
    {"impossible_viewpoint", "不可能视点", "impossible viewpoint"}, {"activate", "仪式激活", "ritual activation"}, {"layer", "分层", "layering"},
    {"radiate", "中心辐射", "radiate"}, {"repeat", "重复", "repeat"}, {"personify", "拟人化", "personify"}, {"embody", "赋形", "embody"}};
  for (String[] e : m) if (e[0].equals(t)) return zh ? e[1] : e[2];
  return t;
}
String category(String t) {
  if (t.equals("externalize")) return "frame";
  if (t.equals("inscribe") || t.equals("substitute") || t.equals("synecdoche")) return "refer";
  if (t.equals("depth_time") || t.equals("anachronism")) return "time";
  if (t.equals("layer") || t.equals("radiate") || t.equals("repeat")) return "arrange";
  if (t.equals("personify") || t.equals("embody")) return "embody";
  return "unnamed";
}

void drawOp(JSONObject o) {
  String ev = o.getString("evidence"), t = o.getString("type"), f = o.getString("from"), to = o.getString("to");
  if (ev.equals("image") && !showImage) return;
  if (ev.equals("inference") && !showInfer) return;
  A = ev.equals("text") ? 255 : (ev.equals("image") ? 115 : 45);
  DASH = !ev.equals("text");                                   // evidence rule: only text evidence is drawn solid
  stroke(FG(), A); strokeWeight(ev.equals("text") ? 1.4 : 1); noFill();
  PVector a = isRef(f) ? P.get(f) : P.get(f).copy();
  PVector mid = null;

  if (t.equals("externalize") || t.equals("personify")) {            // funnel opening from the carrier
    for (PVector s : subs(f)) {
      PVector b = surf(s, to); PVector d = PVector.sub(b, s); float r = 0.45 * U;
      PVector[] bs = basis(d);
      int nl = subs(f).size() > 1 ? 4 : 10; if (subs(f).size() > 1) stroke(FG(), A / 2); for (int i = 0; i < nl; i++) { float th = TWO_PI * i / nl; PVector e = PVector.add(b, PVector.add(PVector.mult(bs[0], cos(th) * r), PVector.mult(bs[1], sin(th) * r))); ln(s, e); }
      ring(b, d, r); mid = lerpV(s, b, 0.5);
    }
  } else if (t.equals("inscribe")) {                                  // line with text-like ticks: a "lyric line"
    PVector b = surf(a, to); ln(a, b); PVector d = PVector.sub(b, a); PVector[] bs = basis(d);
    for (int i = 1; i < 9; i++) { PVector p = lerpV(a, b, i / 9.0); PVector q = PVector.mult(bs[0], 0.14 * U); line(p.x - q.x, p.y - q.y, p.z - q.z, p.x + q.x, p.y + q.y, p.z + q.z); }
    mid = lerpV(a, b, 0.5);
  } else if (t.equals("substitute")) {                                // A = B : double ring + arrow
    PVector a2 = isRef(f) ? surf(P.get(to), f) : a; PVector b = surf(a2, to);
    ln(a2, b); PVector d = PVector.sub(b, a2); ring(lerpV(a2, b, 0.48), d, 0.16 * U); ring(lerpV(a2, b, 0.54), d, 0.16 * U); arrowHead(a2, b);
    mid = lerpV(a2, b, 0.5);
  } else if (t.equals("synecdoche")) {                                // part → whole: rings growing
    PVector b = surf(a, to); ln(a, b); PVector d = PVector.sub(b, a);
    for (int i = 1; i <= 5; i++) ring(lerpV(a, b, i / 6.0), d, (0.04 + i * 0.07) * U);
    mid = lerpV(a, b, 0.5);
  } else if (t.equals("depth_time")) {                                // rings spaced wider toward the future
    PVector b = surf(a, to); boolean dd = DASH; DASH = true; ln(a, b); DASH = dd; PVector d = PVector.sub(b, a);
    for (int i = 1; i <= 5; i++) ring(lerpV(a, b, pow(i / 6.0, 1.6)), d, 0.15 * U);
    mid = lerpV(a, b, 0.5);
  } else if (t.equals("anachronism")) {                               // two times twisted together: helix
    PVector b = surf(a, to); PVector d = PVector.sub(b, a); PVector[] bs = basis(d); ln(a, b);
    beginShape(); for (int i = 0; i <= 160; i++) { float u = i / 160.0, th = u * TWO_PI * 6; PVector p = PVector.add(lerpV(a, b, u), PVector.add(PVector.mult(bs[0], cos(th) * 0.2 * U), PVector.mult(bs[1], sin(th) * 0.2 * U))); vertex(p.x, p.y, p.z); } endShape();
    mid = lerpV(a, b, 0.5);
  } else if (t.equals("juxtapose")) {                                 // rhyme between two carriers: dotted arch
    PVector b = P.get(to); PVector c = PVector.add(lerpV(a, b, 0.5), new PVector(0, -1.6 * U, 0.6 * U));
    PVector prev = a; for (int i = 1; i <= 40; i++) { float u = i / 40.0; PVector p = PVector.add(PVector.add(PVector.mult(a, (1 - u) * (1 - u)), PVector.mult(c, 2 * u * (1 - u))), PVector.mult(b, u * u)); if (i % 2 == 0) line(prev.x, prev.y, prev.z, p.x, p.y, p.z); prev = p; }
    mid = PVector.add(lerpV(a, b, 0.5), new PVector(0, -0.9 * U, 0.3 * U));
  } else if (t.equals("witness")) {                                   // converging gazes toward an undepicted referent
    for (PVector s : subs(f)) { PVector b = surf(s, to); dashed(PVector.add(s, new PVector(0, -0.15 * U, 0)), b, 0.1 * U, 0.08 * U); mid = lerpV(s, b, 0.55); }
  } else if (t.equals("impossible_viewpoint")) {                      // a viewer outside the sphere; projection onto the plane
    PVector c = P.get(to); float r = RAD.get(to); PVector eye = PVector.add(c, new PVector(3.4 * U, -2.4 * U, 3.0 * U));
    pushMatrix(); translate(eye.x, eye.y, eye.z); fill(FG(), A); noStroke(); sphereDetail(8); sphere(0.12 * U); popMatrix(); stroke(FG(), A); noFill();
    ring(eye, PVector.sub(c, eye), 0.3 * U);
    float dr = RAD.get(f);
    for (int i = 0; i < 10; i++) { float th = TWO_PI * i / 10; PVector p = new PVector(c.x + cos(th) * r, c.y, c.z + sin(th) * r); ln(eye, p); stroke(FG(), A / 2); dashed(p, new PVector(P.get(f).x + cos(th) * dr, P.get(f).y, P.get(f).z + sin(th) * dr), 0.1 * U, 0.1 * U); stroke(FG(), A); }
    label(zh ? "观者（不可能的位置）" : "viewer (impossible position)", PVector.add(eye, new PVector(0, -0.4 * U, 0)), A, true);
    mid = lerpV(eye, c, 0.4);
  } else if (t.equals("activate")) {                                  // carrier acts on the referent: rings travelling upward
    PVector b = surf(a, to); boolean dd = DASH; DASH = true; ln(a, b); DASH = dd; PVector d = PVector.sub(b, a);
    for (int k = 0; k < 4; k++) { float u = (frameCount * 0.004f + k / 4.0f) % 1; ring(lerpV(a, b, u), d, 0.2 * U); }
    mid = lerpV(a, b, 0.5);
  } else if (t.equals("layer")) {                                     // stacked: upper over lower, separated by a plate
    PVector b = P.get(to); line(a.x, a.y, a.z, b.x, b.y, b.z);
    PVector m = lerpV(a, b, 0.5); pushMatrix(); translate(m.x, m.y, m.z); rotateX(HALF_PI); rectMode(CENTER); rect(0, 0, 1.2 * U, 0.8 * U); popMatrix();
    mid = PVector.add(m, new PVector(-0.9 * U, 0, 0));
  } else if (t.equals("radiate")) {                                   // radial divisions on the disk
    PVector c = P.get(f); float r = RAD.get(f);
    for (int i = 0; i < 12; i++) { float th = TWO_PI * i / 12; ln(new PVector(c.x, c.y - 1, c.z), new PVector(c.x + cos(th) * r, c.y - 1, c.z + sin(th) * r)); }
    mid = new PVector(c.x - r * 0.7, c.y - 0.2 * U, c.z - r * 0.7);
  } else if (t.equals("repeat")) {                                    // equally spaced repetition
    ArrayList<PVector> ss = subs(f); ln(ss.get(0), ss.get(ss.size() - 1)); PVector b = surf(ss.get(ss.size() / 2), to); ln(ss.get(ss.size() / 2), b);
    mid = lerpV(ss.get(ss.size() / 2), b, 0.5);
  } else if (t.equals("embody")) {                                    // stars become bodies on the sky
    String host = NODE.get(to).hasKey("parent") ? NODE.get(to).getString("parent") : to; PVector c = P.get(host); float r = RAD.get(host);
    for (int i = 0; i < 6; i++) { float th = TWO_PI * i / 6 + 0.3, el = 0.5 - (i % 3) * 0.4; PVector p = new PVector(c.x + cos(th) * cos(el) * r, c.y - sin(el) * r, c.z + sin(th) * cos(el) * r);
      pushMatrix(); translate(p.x, p.y, p.z); fill(invert ? 90 : 170, A); stroke(FG(), A); sphereDetail(6); sphere(0.13 * U); popMatrix(); noFill();
      ln(new PVector(P.get(f).x + cos(th) * r * 0.9, P.get(f).y, P.get(f).z + sin(th) * r * 0.9), p); }
    mid = new PVector(c.x - r - 0.4 * U, c.y, c.z);
  } else {                                                            // unknown operation: plain line, flagged by its name
    PVector b = surf(a, to); ln(a, b); mid = lerpV(a, b, 0.5);
  }
  DASH = false;
  if (mid != null) label(opName(t) + (ev.equals("text") ? "" : (zh ? (ev.equals("image") ? "（仅图像）" : "（推断）") : (ev.equals("image") ? " (image only)" : " (inferred)"))), mid, A, true);
}

// ───────────────────────── HUD ─────────────────────────
void drawHUD(JSONObject a) {
  hint(DISABLE_DEPTH_TEST); camera(); noLights();
  textAlign(CENTER, CENTER);
  for (Lb l : labels) { fill(FG(), l.a); textSize(l.small ? 12 : 14); text(l.t, l.x, l.y); }
  textAlign(LEFT, TOP); fill(FG());
  textSize(22); text(a.getString("title").replace("–", "-"), 32, 28);
  textSize(13); fill(FG(), 170);
  text(a.getString("artist") + "  |  " + a.getString("date").replace("–", "-") + "  |  AIC " + a.getInt("aic_id") + (a.getBoolean("public_domain") ? "  |  public domain" : (zh ? "  |  非 public domain" : "  |  NOT public domain")), 32, 60);
  // signature: count operations per category (text evidence only)
  String[] cats = {"frame", "refer", "time", "arrange", "embody", "unnamed"};
  String[] cz = {"框定", "指代", "时间", "布局", "赋形", "未命名"};
  int[] cnt = new int[cats.length];
  JSONArray O = a.getJSONArray("ops");
  for (int i = 0; i < O.size(); i++) { JSONObject o = O.getJSONObject(i); if (!o.getString("evidence").equals("text")) continue; String c = category(o.getString("type")); for (int k = 0; k < cats.length; k++) if (cats[k].equals(c)) cnt[k]++; }
  String sig = zh ? "签名（仅文本证据）  " : "signature (text evidence)  ";
  for (int k = 0; k < cats.length; k++) sig += (zh ? cz[k] : cats[k]) + " " + cnt[k] + "   ";
  text(sig, 32, 82);
  // legend
  int y = height - 118; noStroke(); fill(BG(), 225); rect(20, y - 10, 640, 96); textSize(12); fill(FG(), 150);
  String[] lg = zh ? new String[]{"实心方块 = 可见载体    灰色实体 = 在图中有形体的对象    线框 = 不在场对象",
    "实线 = 文本证据    淡虚线 = 仅图像证据 [G]    极淡 = 推断 [I]",
    "高度 = 链的深度    纵深 = 时间（越后越是未来）    画框外 = 只能被见证的对象",
    "← → / 1–5 切换作品   L 标签   T 中/英   B 反色   SPACE 旋转   R 复位   S 存 PNG"}
    : new String[]{"solid cube = visible carrier    grey body = referent embodied in the image    wireframe = absent referent",
    "solid line = text evidence    faint dashed = image only [G]    very faint = inference [I]",
    "height = chain depth    depth = time (further back = future)    beyond the frame = witnessed only",
    "← → / 1–5 switch   L labels   T zh/en   B invert   SPACE rotate   R reset   S save PNG"};
  for (int i = 0; i < lg.length; i++) text(lg[i], 32, y + i * 20);
  textAlign(RIGHT, TOP); text((cur + 1) + " / " + works.size(), width - 32, 28);
  hint(ENABLE_DEPTH_TEST);
}

// ───────────────────────── input ─────────────────────────
void keyPressed() {
  if (keyCode == RIGHT) { cur = (cur + 1) % works.size(); layout(); }
  else if (keyCode == LEFT) { cur = (cur - 1 + works.size()) % works.size(); layout(); }
  else if (key >= '1' && key <= '9' && key - '1' < works.size()) { cur = key - '1'; layout(); }
  else if (key == 'l' || key == 'L') showLabels = !showLabels;
  else if (key == 't' || key == 'T') zh = !zh;
  else if (key == 'g' || key == 'G') showImage = !showImage;
  else if (key == 'i' || key == 'I') showInfer = !showInfer;
  else if (key == 'b' || key == 'B') invert = !invert;
  else if (key == ' ') spin = !spin;
  else if (key == 'r' || key == 'R') { rx = -0.42; ry = 0.65; zoom = 0.72; }
  else if (key == 's' || key == 'S') saveFrame("export/score-" + works.getJSONObject(cur).getInt("aic_id") + "-####.png");
}
void mouseDragged() { ry += (mouseX - pmouseX) * 0.01; rx -= (mouseY - pmouseY) * 0.01; rx = constrain(rx, -1.4, 0.2); }
void mouseWheel(MouseEvent e) { zoom = constrain(zoom * (1 - e.getCount() * 0.06), 0.4, 3); }
