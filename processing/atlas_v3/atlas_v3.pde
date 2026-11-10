// The Atlas of Imagination — Exp 01 · The Dream of Paris · 3D Imagination Score (Processing P3D)
// Same rules for every artwork (signs v3, four operation families). data/<work>_v3.json is written by
// scripts/10_paris_score_3d.py; W switches between the works listed in WORKS.
//
// Mouse: drag = rotate · wheel = zoom
// Keys:  G axes · L picture line · F traces flat/hanging · T labels · N / B next / previous operation (with evidence)
//        W next artwork · SPACE spin · R reset view · S save PNG · P save vector PDF (export/)
// Run with --export [--work=charity] to save one PNG and quit.

import processing.pdf.*;
import java.util.*;

JSONObject D;
final String[] WORKS = {"paris", "charity", "vedder", "durer"};   // public-domain works only
int wi = 0;
PFont font;
final float U = 100, SX = 10, SY = 2.4, SZ = 2.6, UNIT = 0.055, ZM = 3.4;
float rx = -0.38, ry = -0.55, zoom = 0.3;
boolean showAxes = true, showLine = true, flat = true, showLabels = true, spin = false, recordPDF = false, exporting = false;
int sel = -1, A = 255, exportTick = 0;
final int INK = 17;

HashMap<String, JSONObject> Cm = new HashMap<String, JSONObject>(), Rm = new HashMap<String, JSONObject>();
ArrayList<JSONObject> LIVE = new ArrayList<JSONObject>();
HashMap<String, ArrayList<PVector>> ANCH = new HashMap<String, ArrayList<PVector>>();
ArrayList<Trace> traces = new ArrayList<Trace>();
ArrayList<Lab> labs = new ArrayList<Lab>();
HashMap<String, String> OPZ = new HashMap<String, String>();
final PVector X = new PVector(1, 0, 0), Y = new PVector(0, 1, 0), Z = new PVector(0, 0, 1);

class Trace { String cid; float[] xy, xz; PVector anchor; float xs, far; boolean first; }
class Lab { String t; float x, y; float size; int col; Lab(String t, float x, float y, float size, int col) { this.t = t; this.x = x; this.y = y; this.size = size; this.col = col; } }
class Fr {
  PVector o, u, v;
  Fr(PVector o, PVector u, PVector v) { this.o = o.copy(); this.u = u.copy().normalize(); this.v = v.copy().normalize(); }
  PVector P(float x, float y) { return PVector.add(o, PVector.add(PVector.mult(u, x), PVector.mult(v, y))); }
}

void setup() {
  size(1500, 950, P3D);
  pixelDensity(displayDensity());
  smooth(8);
  String[] cands = {"Microsoft YaHei", "PingFang SC", "Noto Sans CJK SC", "SimHei", "SansSerif"};
  List<String> avail = Arrays.asList(PFont.list());
  String fname = "SansSerif";
  for (String c : cands) if (avail.contains(c)) { fname = c; break; }
  font = createFont(fname, 24, true);
  textFont(font);
  String[] k = {"externalize", "embody", "substitute", "inscribe", "depth_time", "foreshadow", "trigger", "anachronism", "contain", "contrast", "juxtapose", "witness", "synecdoche"};
  String[] z = {"外化", "赋形", "象征替代", "铭写", "纵深=时间", "预示", "引发", "时代错置", "包含", "对照", "并置", "见证", "提喻"};
  for (int i = 0; i < k.length; i++) OPZ.put(k[i], z[i]);
  if (args != null) for (String a : args) { if (a.equals("--export")) exporting = true; if (a.startsWith("--work=")) wi = max(0, Arrays.asList(WORKS).indexOf(a.substring(7))); }
  load();
}

// ───────── data ─────────
PVector W(float x, float y, float z) { return new PVector((x - 0.5) * SX, y * SY, -z * SZ); }
PVector rPos(JSONObject r) { return W(r.getFloat("x"), r.getInt("time"), r.getInt("z")); }
float rRad(JSONObject r) { return 0.3 + 0.06 * r.getInt("in_text_ops"); }

void load() {
  Cm.clear(); Rm.clear(); LIVE.clear(); ANCH.clear(); traces.clear(); sel = -1;
  D = loadJSONObject(WORKS[wi] + "_v3.json");
  JSONArray C = D.getJSONArray("C"), R = D.getJSONArray("R"), O = D.getJSONArray("O");
  for (int i = 0; i < C.size(); i++) { JSONObject c = C.getJSONObject(i); if (!c.hasKey("excluded")) Cm.put(c.getString("id"), c); }
  for (int i = 0; i < R.size(); i++) { JSONObject r = R.getJSONObject(i); if (!r.hasKey("excluded")) Rm.put(r.getString("id"), r); }
  for (int i = 0; i < O.size(); i++) { JSONObject o = O.getJSONObject(i); if (!o.getString("evidence").equals("inference")) LIVE.add(o);   // image evidence drawn too (not yet hollow here) }
  // traces: nudged apart along x, laid flat (xz) or hanging (xy)
  JSONArray T = D.getJSONArray("traces");
  int nT = T.size(); float[] X0 = new float[nT], HW = new float[nT], WW = new float[nT]; Integer[] idx = new Integer[nT];
  for (int i = 0; i < nT; i++) {
    JSONObject t = T.getJSONObject(i); JSONArray b = t.getJSONArray("box");
    HW[i] = constrain((b.getInt(3) - b.getInt(1)) * 0.0036, 0.75, 2.4); WW[i] = HW[i] * t.getInt("w") / t.getInt("h"); X0[i] = (t.getFloat("x") - 0.5) * SX; idx[i] = i;
  }
  final float[] X0f = X0;
  Arrays.sort(idx, new Comparator<Integer>() { public int compare(Integer a, Integer b) { return Float.compare(X0f[a], X0f[b]); } });
  float[] xs = new float[nT]; for (int i = 0; i < nT; i++) xs[i] = X0[idx[i]];
  for (int it = 0; it < 300; it++) { boolean moved = false;
    for (int i = 1; i < nT; i++) { float need = (WW[idx[i - 1]] + WW[idx[i]]) / 2 + 0.22; if (xs[i] - xs[i - 1] < need) { float p = (need - (xs[i] - xs[i - 1])) / 2; xs[i] += p; xs[i - 1] -= p; moved = true; } }
    if (!moved) break; }
  for (int q = 0; q < nT; q++) {
    int i = idx[q]; JSONObject t = T.getJSONObject(i); JSONArray pts = t.getJSONArray("pts");
    Trace tr = new Trace(); tr.cid = t.getString("cid"); tr.first = t.getInt("i") == 0; tr.xs = xs[q];
    float k = HW[i] / t.getInt("h"), top = 0.32, x0 = xs[q] - WW[i] / 2; int n = pts.size() / 2;
    tr.xy = new float[n * 3]; tr.xz = new float[n * 3];
    for (int j = 0; j < n; j++) {
      float px = x0 + pts.getInt(2 * j) * k, d = top + pts.getInt(2 * j + 1) * k;
      tr.xy[j * 3] = px; tr.xy[j * 3 + 1] = -d; tr.xy[j * 3 + 2] = 0;
      tr.xz[j * 3] = px; tr.xz[j * 3 + 1] = -0.004; tr.xz[j * 3 + 2] = d;
    }
    tr.anchor = W(t.getFloat("x"), 0, 0); tr.far = top + HW[i] + 0.16;
    if (!ANCH.containsKey(tr.cid)) ANCH.put(tr.cid, new ArrayList<PVector>());
    ANCH.get(tr.cid).add(tr.anchor);
    traces.add(tr);
  }
  // anchors in box order (contrast uses the 2nd figure of C7)
  for (String cid : ANCH.keySet()) Collections.sort(ANCH.get(cid), new Comparator<PVector>() { public int compare(PVector a, PVector b) { return 0; } });
}

// ───────── ink ─────────
void vtx(PVector p) { vertex(p.x * U, -p.y * U, p.z * U); }
void ln(PVector a, PVector b, float w, int col) { stroke(col, A); strokeWeight(w); line(a.x * U, -a.y * U, a.z * U, b.x * U, -b.y * U, b.z * U); }
void ln(PVector a, PVector b, float w) { ln(a, b, w, INK); }
void poly(ArrayList<PVector> pts, float w) { noFill(); stroke(INK, A); strokeWeight(w); beginShape(); for (PVector p : pts) vtx(p); endShape(); }
void dashed(PVector a, PVector b, float dash, float gap, float w, int col) {
  float L = PVector.dist(a, b); if (L < 1e-4) return;
  for (float s = 0; s < L; s += dash + gap) ln(PVector.lerp(a, b, s / L), PVector.lerp(a, b, min(s + dash, L) / L), w, col);
}
void fillPoly(Fr fr, float[][] pts) { noStroke(); fill(INK, A); beginShape(); for (float[] p : pts) vtx(fr.P(p[0], p[1])); endShape(CLOSE); }
void blob(Fr fr, float x, float y, float r) { float[][] p = new float[18][2]; for (int i = 0; i < 18; i++) { float a = TWO_PI * i / 18; p[i][0] = x + cos(a) * r; p[i][1] = y + sin(a) * r; } fillPoly(fr, p); }
void ring(Fr fr, float x, float y, float r, float w) { noFill(); stroke(INK, A); strokeWeight(w); beginShape(); for (int i = 0; i <= 28; i++) { float a = TWO_PI * i / 28; vtx(fr.P(x + cos(a) * r, y + sin(a) * r)); } endShape(); }
void flag(Fr fr, float x, float y, float dir, float s, float h) { fillPoly(fr, new float[][]{{x, y - s * h}, {x + dir * s, y}, {x, y + s * h}}); }
void seg(Fr fr, float x0, float y0, float x1, float y1, float w) { ln(fr.P(x0, y0), fr.P(x1, y1), w); }
void label(String t, PVector p, float size, int col) { if (showLabels) labs.add(new Lab(t, screenX(p.x * U, -p.y * U, p.z * U), screenY(p.x * U, -p.y * U, p.z * U), size, col)); }

// ───────── R: structure = kind, strung signs = absence ─────────
void absenceSign(String ab, Fr fr, float s) {
  if (ab.equals("inner")) { ring(fr, 0, 0, s * 0.75, 1.2); blob(fr, 0, 0, s * 0.28); }
  else if (ab.equals("supernatural")) ring(fr, 0, 0, s * 0.6, 1.4);
  else if (ab.equals("not_yet")) flag(fr, -s * 0.5, 0, 1, s * 1.2, 0.55);
  else if (ab.equals("invisible")) blob(fr, 0, 0, s * 0.5);
  else if (ab.equals("unreachable")) { seg(fr, -s * 0.35, -s, -s * 0.35, s, 1.4); seg(fr, s * 0.35, -s, s * 0.35, s, 1.4); }
  else if (ab.equals("nonexistent")) { seg(fr, -s, -s, s, s, 1.4); seg(fr, -s, s, s, -s, 1.4); }
}
ArrayList<ArrayList<PVector>> structure(String kind, int n) {
  ArrayList<ArrayList<PVector>> cs = new ArrayList<ArrayList<PVector>>();
  if (kind.equals("experience")) { ArrayList<PVector> c = new ArrayList<PVector>(); for (int i = 0; i <= 96; i++) { float a = TWO_PI * i / 96; c.add(new PVector(cos(a), sin(a), 0)); } cs.add(c); }
  else if (kind.equals("event")) { int m = 4 * (n + 1);
    for (int k = 0; k < m; k++) { float y = 1 - 2 * (k + 0.5) / m, r = sqrt(1 - y * y), a = k * 2.39996, L = k % 2 == 1 ? 0.62 : 1;
      PVector d = new PVector(cos(a) * r, y, sin(a) * r); ArrayList<PVector> c = new ArrayList<PVector>(); c.add(PVector.mult(d, 0.18)); c.add(PVector.mult(d, L)); cs.add(c); } }
  else if (kind.equals("concept")) { int m = n + 3;
    for (int k = 0; k < m; k++) { float a = k * PI / m; ArrayList<PVector> c = new ArrayList<PVector>();
      for (int i = 0; i <= 96; i++) { float t = TWO_PI * i / 96; c.add(new PVector(sin(t) * cos(a), cos(t), sin(t) * sin(a))); } cs.add(c); } }
  return cs;
}
void rGlyph(JSONObject r, PVector c, float rad, int n, int e) {
  String kind = r.getString("kind"), ab = r.getString("absence");
  if (kind.equals("world")) kind = "concept";               // four kinds: "world" was merged into "concept"
  rad *= kind.equals("event") ? 1.6 : 1.4;
  if (kind.equals("being")) {                              // solid black square, signs ringed around it
    Fr f0 = new Fr(c, X, Y); float h = rad * 0.55; fillPoly(f0, new float[][]{{-h, -h}, {h, -h}, {h, h}, {-h, h}});
    int m = (n + 1) * e; float s0 = rad * 0.085 + 0.008, R0 = h * 1.55;
    for (int k = 0; k < m; k++) { float a = QUARTER_PI + k * TWO_PI / m; absenceSign(ab, new Fr(PVector.add(c, new PVector(cos(a) * R0, sin(a) * R0, 0)), X, Y), s0); }
    return;
  }
  ArrayList<ArrayList<PVector>> cs = structure(kind, n);
  for (ArrayList<PVector> cv : cs) { for (int i = 0; i < cv.size(); i++) cv.set(i, PVector.add(c, PVector.mult(cv.get(i), rad))); poly(cv, 1); }
  if (kind.equals("event")) for (int k = 0; k < 5; k++) blob(new Fr(c, X, Y), cos(k * 1.3) * rad * 0.1, sin(k * 1.7) * rad * 0.1, rad * 0.045);
  if (kind.equals("concept")) for (int yy = -1; yy <= 1; yy += 2) ring(new Fr(PVector.add(c, PVector.mult(Y, rad * yy)), X, Y), 0, 0, rad * 0.06, 1.2);
  float s = rad * 0.085 + 0.008;
  for (ArrayList<PVector> cv : cs) {
    if (kind.equals("event")) absenceSign(ab, new Fr(cv.get(cv.size() - 1), X, Y), s);
    else for (int k = 0; k < e; k++) absenceSign(ab, new Fr(cv.get(round((k + 0.5) / e * (cv.size() - 1))), X, Y), s);
  }
}

// ───────── O: four families ─────────
String family(String t) {
  if (t.equals("externalize") || t.equals("embody") || t.equals("witness") || t.equals("impossible_viewpoint") || t.equals("activate")) return "manifest";
  if (t.equals("substitute") || t.equals("inscribe") || t.equals("synecdoche")) return "refer";
  if (t.equals("contain") || t.equals("contrast") || t.equals("juxtapose") || t.equals("radiate") || t.equals("layer")) return "compose";
  return "time";
}
Fr opFrame(PVector a, PVector b) { PVector d = PVector.sub(b, a).normalize(); PVector side = Z.cross(d); if (side.mag() < 1e-3) side = Y.copy(); return new Fr(a, d, side); }
void semiDashDot(Fr fr, float L, float u) {                // half-circle, long line · dot · long line …
  float r = L / 2; int N = 160; ArrayList<float[]> pts = new ArrayList<float[]>();
  for (int i = 0; i <= N; i++) { float a = PI - PI * i / N; pts.add(new float[]{r + cos(a) * r, sin(a) * r}); }
  float seg = u * 5, gap = u * 1.6, acc = 0, next = seg; boolean on = true; ArrayList<PVector> run = new ArrayList<PVector>(); run.add(fr.P(pts.get(0)[0], pts.get(0)[1]));
  for (int i = 1; i < pts.size(); i++) {
    acc += dist(pts.get(i)[0], pts.get(i)[1], pts.get(i - 1)[0], pts.get(i - 1)[1]);
    if (on) run.add(fr.P(pts.get(i)[0], pts.get(i)[1]));
    if (acc >= next) {
      if (on) { poly(run, 1.3); next = acc + gap; on = false; }
      else { int j = max(0, i - max(1, round(N * gap / (PI * r) / 2))); blob(fr, pts.get(j)[0], pts.get(j)[1], u * 0.32); run = new ArrayList<PVector>(); run.add(fr.P(pts.get(i)[0], pts.get(i)[1])); next = acc + seg; on = true; }
    }
  }
  if (on && run.size() > 1) poly(run, 1.3);
}
void band(Fr fr, float L, float rP, int N) {               // point-cloud ring band
  float m = L / 2, ra = L / 2 + rP, rb = rP * 1.1, w = rP * 0.16; PVector third = fr.u.cross(fr.v).normalize();
  long seed = 7; stroke(INK, A); strokeWeight(1.6); beginShape(POINTS);
  for (int i = 0; i < N; i++) {
    seed = (seed * 16807) % 2147483647; float r1 = seed / 2147483647.0;
    seed = (seed * 16807) % 2147483647; float r2 = seed / 2147483647.0;
    seed = (seed * 16807) % 2147483647; float r3 = seed / 2147483647.0;
    seed = (seed * 16807) % 2147483647; float r4 = seed / 2147483647.0;
    seed = (seed * 16807) % 2147483647; float r5 = seed / 2147483647.0;
    float th = r1 * TWO_PI, rr = 1 + (r2 + r3 - 1) * w / rb, h = (r4 + r5 - 1) * w;
    vtx(PVector.add(fr.P(m + cos(th) * ra * rr, sin(th) * rb * rr), PVector.mult(third, h)));
  }
  endShape();
}
void phrase(String type, PVector a, PVector b, boolean fromR, int words, float rP, int pts) {
  Fr fr = opFrame(a, b); float L = PVector.dist(a, b), u = UNIT; String fam = family(type);
  if (fam.equals("manifest")) { semiDashDot(fr, L, u); blob(fr, 0, 0, u * 1.1); return; }
  if (fam.equals("refer")) {
    blob(fr, 0, 0, u * 0.55); int n = max(1, words); float step = u * 0.55, gap = u * 1.5, x = u * 1.4;
    while (x < L - u * 0.6) { for (int k = 0; k < n && x < L - u * 0.6; k++, x += step) { float t = abs(x / L - 0.5) * 2, h = u * (0.35 + 0.95 * t * t); seg(fr, x, -h, x, h, 2.2); } x += gap - step; }
    return;
  }
  if (fam.equals("time")) {
    float dir = type.equals("anachronism") ? -1 : 1, s = u * 1.0, step = u * 3.4;
    if (!fromR) blob(fr, 0, 0, u * 0.55);
    for (float x = u * 1.4; x < L - s; x += step) flag(fr, dir > 0 ? x : x + s, 0, dir, s, 1.05);
    return;
  }
  band(fr, L, rP, pts);
}
PVector towards(PVector a, PVector b, float d) { return PVector.add(a, PVector.mult(PVector.sub(b, a).normalize(), d)); }
PVector rim(String rid, PVector from) { return towards(rPos(Rm.get(rid)), from, rRad(Rm.get(rid))); }

// ───────── selection alpha ─────────
JSONObject selOp() { return sel >= 0 ? LIVE.get(sel) : null; }
int alphaFor(String id) { JSONObject o = selOp(); if (o == null) return 255; return (id.equals(o.getString("from")) || id.equals(o.getString("to"))) ? 255 : 28; }

// ───────── draw ─────────
void draw() {
  if (recordPDF) beginRaw(PDF, "export/" + WORKS[wi] + "_v3-" + nf(frameCount, 5) + ".pdf");
  background(255);
  perspective(PI / 6.5, float(width) / height, 10, 100000);
  labs.clear();
  pushMatrix();
  translate(width / 2, height / 2 + 40, 0);
  scale(zoom);
  rotateX(rx); rotateY(ry);
  translate(-60, 120, 320);
  if (spin) ry += 0.0025;

  if (showAxes) drawAxes();
  A = 255;
  if (showLine) ln(W(0, 0, 0), W(1, 0, 0), 2.4);
  // carriers
  for (Trace t : traces) {
    A = alphaFor(t.cid);
    stroke(INK, A); strokeWeight(1.3); beginShape(POINTS);
    float[] p = flat ? t.xz : t.xy; for (int j = 0; j < p.length; j += 3) vertex(p[j] * U, -p[j + 1] * U, p[j + 2] * U);
    endShape();
    PVector end = flat ? new PVector(t.xs, 0, 0.26) : new PVector(t.xs, -0.26, 0);
    ln(t.anchor, end, 0.8, 150); blob(new Fr(t.anchor, X, Y), 0, 0, 0.045);
    if (t.first) label(Cm.get(t.cid).getString("zh"), flat ? new PVector(t.xs, 0, t.far) : new PVector(t.xs, -t.far, 0), 11, 60);
  }
  // referents
  for (JSONObject r : Rm.values()) {
    A = alphaFor(r.getString("id"));
    PVector c = rPos(r); float rad = rRad(r);
    int n = 0; HashSet<String> es = new HashSet<String>();
    for (JSONObject o : LIVE) if (o.getString("to").equals(r.getString("id"))) { n++; JSONArray E = o.getJSONArray("E"); for (int i = 0; i < E.size(); i++) es.add(E.getString(i)); }
    rGlyph(r, c, rad, max(1, n), max(1, es.size()));
    if (showAxes) { int a0 = A; A = min(A, 160); dashed(PVector.sub(c, PVector.mult(Y, rad)), W(r.getFloat("x"), 0, r.getInt("z")), 0.05, 0.08, 0.8, 120); dashed(W(r.getFloat("x"), 0, r.getInt("z")), W(r.getFloat("x"), 0, 0), 0.05, 0.08, 0.8, 150); A = a0; }
    label(r.getString("zh") + "  " + r.getString("id"), PVector.add(c, new PVector(rad * 1.5, 0, 0)), 13, INK);
  }
  // operations
  for (int i = 0; i < LIVE.size(); i++) {
    JSONObject o = LIVE.get(i); String t = o.getString("type"), f = o.getString("from"), to = o.getString("to");
    A = (sel < 0 || sel == i) ? 255 : 22;
    if (Cm.containsKey(f) && Cm.containsKey(to)) { ArrayList<PVector> at = ANCH.get(to); phrase(t, ANCH.get(f).get(0), at.size() > 1 ? at.get(1) : at.get(0), false, 0, 0.22, 1100); continue; }
    if (Rm.containsKey(f) && Rm.containsKey(to)) {
      PVector c1 = rPos(Rm.get(f)), c2 = rPos(Rm.get(to));
      if (t.equals("contain")) phrase(t, c1, c2, true, 0, rRad(Rm.get(f)), 1400);
      else phrase(t, towards(c1, c2, rRad(Rm.get(f))), towards(c2, c1, rRad(Rm.get(to))), true, 0, 0, 0);
      continue;
    }
    if (family(t).equals("manifest") && ANCH.get(f).size() > 1) {   // one half-circle per body (n = figures)
      PVector mid = new PVector(); for (PVector p : ANCH.get(f)) mid.add(p); mid.div(ANCH.get(f).size());
      PVector tip = rim(to, mid);
      for (PVector p : ANCH.get(f)) { Fr fr = opFrame(p, tip); semiDashDot(fr, PVector.dist(p, tip), UNIT); blob(fr, 0, 0, UNIT * 1.1); }
      continue;
    }
    PVector a = ANCH.get(f).get(0);
    phrase(t, a, rim(to, a), false, Cm.get(f).getInt("words", 0), 0, 0);
  }
  popMatrix();
  if (recordPDF) { endRaw(); recordPDF = false; println("PDF saved"); }
  drawHUD();
  if (exporting && ++exportTick == 3) { saveFrame("export/" + WORKS[wi] + "_v3.png"); exit(); }
}

void drawAxes() {
  A = 255; int g = 190;
  String[] tl = {"过去 −1", "此刻 0", "未来 +1", "超时间 +2"};
  for (int y = -1; y <= 2; y++) {
    PVector[] c = {W(0, y, 0), W(1, y, 0), W(1, y, ZM), W(0, y, ZM)};
    for (int i = 0; i < 4; i++) if (!(y == 0 && i == 0)) dashed(c[i], c[(i + 1) % 4], 0.07, 0.07, 0.8, g);
    label(tl[y + 1], W(-0.04, y, 0), 10.5, 150);
  }
  float[][] corners = {{0, 0}, {1, 0}, {0, ZM}, {1, ZM}};
  for (float[] q : corners) dashed(W(q[0], -1, q[1]), W(q[0], 2, q[1]), 0.07, 0.07, 0.8, 205);
  for (int z = 1; z <= 3; z++) { dashed(W(0, 0, z), W(1, 0, z), 0.07, 0.07, 0.7, 225); label(z + " 步", W(1.03, -1, z), 10.5, 150); }
  for (float x = 0.25; x < 1; x += 0.25) dashed(W(x, 0, 0), W(x, 0, ZM), 0.07, 0.07, 0.7, 225);
  for (int i = 0; i <= 4; i++) label(nf(i / 4.0, 1, 2), W(i / 4.0, -1.12, 0), 10, 150);
  label("0 可见", W(1.03, -1, 0), 10.5, 150);
  label("x  画面位置  左 → 右", W(0.5, -1.32, 0), 12, INK);
  label("y  时间", W(-0.04, 2.3, 0), 12, INK);
  label("z  离可见世界的步数", W(1.05, -1, ZM + 0.15), 12, INK);
}

void drawHUD() {
  hint(DISABLE_DEPTH_TEST);
  camera(); perspective();
  for (Lab l : labs) { fill(l.col); textSize(l.size); textAlign(LEFT, CENTER); text(l.t, l.x + 4, l.y); }
  JSONObject a = D.getJSONObject("artwork");
  fill(INK); textAlign(LEFT, BASELINE); textSize(16); text(a.getString("title") + " · Imagination Score 3D", 28, 40);
  fill(140); textSize(11);
  text("拖动 = 旋转 · 滚轮 = 缩放 · W 换作品 · G 坐标轴 · L 画面线 · F 描线平放/竖挂 · T 标签 · N / B 逐个看操作 · SPACE 自转 · R 复位 · S 存 PNG · P 存矢量 PDF", 28, 60);
  JSONObject o = selOp();
  if (o != null) {
    String fam = D.getJSONObject("category").getString(o.getString("type"));
    String s = o.getString("id") + "  " + fam + "（" + OPZ.get(o.getString("type")) + "）  " + name(o.getString("from")) + " → " + name(o.getString("to"));
    fill(INK); textSize(13); text(s, 28, height - 48);
    JSONArray E = o.getJSONArray("E"); String ev = "";
    for (int i = 0; i < E.size(); i++) ev += E.getString(i) + "：“" + D.getJSONObject("E").getString(E.getString(i)) + "”   ";
    fill(90); textSize(11); text(ev, 28, height - 26);
  }
  hint(ENABLE_DEPTH_TEST);
}
String name(String id) { return Cm.containsKey(id) ? Cm.get(id).getString("zh") : Rm.get(id).getString("zh"); }

// ───────── interaction ─────────
void mouseDragged() { ry += (mouseX - pmouseX) * 0.006; rx = constrain(rx - (mouseY - pmouseY) * 0.006, -1.5, 0.6); }
void mouseWheel(MouseEvent e) { zoom = constrain(zoom * (e.getCount() > 0 ? 0.92 : 1.08), 0.15, 5); }
void keyPressed() {
  if (key == 'g' || key == 'G') showAxes = !showAxes;
  else if (key == 'l' || key == 'L') showLine = !showLine;
  else if (key == 'f' || key == 'F') flat = !flat;
  else if (key == 't' || key == 'T') showLabels = !showLabels;
  else if (key == 'n' || key == 'N') sel = sel + 1 >= LIVE.size() ? -1 : sel + 1;
  else if (key == 'b' || key == 'B') sel = sel - 1 < -1 ? LIVE.size() - 1 : sel - 1;
  else if (key == ' ') spin = !spin;
  else if (key == 'r' || key == 'R') { rx = -0.38; ry = -0.55; zoom = 0.3; }
  else if (key == 's' || key == 'S') saveFrame("export/" + WORKS[wi] + "_v3-####.png");
  else if (key == 'w' || key == 'W') { wi = (wi + 1) % WORKS.length; load(); }
  else if (key == 'p' || key == 'P') recordPDF = true;
}
