// The Atlas of Imagination — Exp 01 · Imagination Score, "orbit notation" v0.3 (one artwork)
//
// Mapping (every mark carries a slot of the rule system):
//   scribbled band in the middle  = the picture surface: dense clusters = visible carriers C
//   above the band                = transcendent absence (supernatural / unreachable / nonexistent / not_yet)
//   below the band                = inward absence (inner / invisible)
//   distance from the band        = chain depth (an R reached through another R sits farther out)
//   small marker ◐                = an absent referent R (fill pattern = kind)
//   dashed orbit                  = everything one R gathers: its marker + all carriers that point to it
//   thin line + black spindle     = an operation O, spindle points C → R
//   spindle filled / hollow       = evidence: text / image only
//   faint grey tangle             = inference only (not counted)
//
// Keys: T 中文/English   L labels   S save PNG   (WORK below picks the artwork)

import java.util.*;

final int WORK = 0;                 // 0 = The Dream of Paris
JSONObject A;
JSONArray RR, CC, OO;
HashMap<String, PVector> POS = new HashMap<String, PVector>();
HashMap<String, JSONObject> NODE = new HashMap<String, JSONObject>();
HashSet<String> REF = new HashSet<String>();
HashMap<String, Float> BLOB = new HashMap<String, Float>();
boolean zh = true, showLabels = true, exporting = false;
float BAND;                         // y of the band centre
PFont font;

void setup() {
  size(1400, 980);
  pixelDensity(displayDensity());
  smooth(8);
  String[] cands = {"Microsoft YaHei", "PingFang SC", "Noto Sans CJK SC", "SimHei", "SansSerif"};
  List<String> avail = Arrays.asList(PFont.list());
  String fname = "SansSerif";
  for (String c : cands) if (avail.contains(c)) { fname = c; break; }
  font = createFont(fname, 24, true);
  textFont(font);
  A = loadJSONObject("scores.json").getJSONArray("artworks").getJSONObject(WORK);
  RR = A.getJSONArray("referents"); CC = A.getJSONArray("carriers"); OO = A.getJSONArray("ops");
  if (args != null && Arrays.asList(args).contains("--export")) exporting = true;
  layout();
  noLoop();
}

boolean isRef(String id) { return REF.contains(id); }
String nm(JSONObject n) { return zh ? n.getString("zh") : n.getString("en"); }
boolean above(JSONObject r) {
  String a = r.getString("absence");
  return a.equals("supernatural") || a.equals("unreachable") || a.equals("nonexistent") || a.equals("not_yet");
}

// carriers that (directly or through another R) point at referent id
HashSet<String> gathered(String id, int depth) {
  HashSet<String> out = new HashSet<String>();
  if (depth > 6) return out;
  for (int i = 0; i < OO.size(); i++) {
    JSONObject o = OO.getJSONObject(i);
    if (!o.getString("to").equals(id)) continue;
    String f = o.getString("from");
    if (isRef(f)) out.addAll(gathered(f, depth + 1)); else out.add(f);
  }
  return out;
}

void layout() {
  POS.clear(); NODE.clear(); REF.clear(); BLOB.clear();
  BAND = height * 0.47;
  for (int i = 0; i < RR.size(); i++) { JSONObject r = RR.getJSONObject(i); NODE.put(r.getString("id"), r); REF.add(r.getString("id")); }
  for (int i = 0; i < CC.size(); i++) { JSONObject c = CC.getJSONObject(i); NODE.put(c.getString("id"), c); }

  // carriers along the band, alternating upper / lower strip; blob size = number of operations it carries
  int nc = CC.size(); float x0 = 190, x1 = width - 190;
  for (int i = 0; i < nc; i++) {
    String id = CC.getJSONObject(i).getString("id");
    float x = nc == 1 ? width / 2 : lerp(x0, x1, i / (float) (nc - 1));
    POS.put(id, new PVector(x, BAND + (i % 2 == 0 ? -26 : 26)));
    int k = 0;
    for (int j = 0; j < OO.size(); j++) { JSONObject o = OO.getJSONObject(j); if (o.getString("from").equals(id) || o.getString("to").equals(id)) k++; }
    BLOB.put(id, 22.0 + 9 * k + 4 * CC.getJSONObject(i).getInt("count", 1));
  }

  // chain level
  HashMap<String, Integer> lv = new HashMap<String, Integer>();
  for (String id : REF) lv.put(id, 1);
  for (int k = 0; k < 6; k++)
    for (int i = 0; i < OO.size(); i++) {
      JSONObject o = OO.getJSONObject(i); String f = o.getString("from"), t = o.getString("to");
      if (isRef(f) && isRef(t)) lv.put(t, max(lv.get(t), lv.get(f) + 1));
    }

  // referents: x = mean of gathered carriers, y = side by absence, distance by chain level
  ArrayList<String> later = new ArrayList<String>();
  for (int i = 0; i < RR.size(); i++) {
    JSONObject r = RR.getJSONObject(i); String id = r.getString("id");
    if (r.hasKey("parent")) { later.add(id); continue; }
    float x = meanX(id, width / 2);
    float d = 175 + (lv.get(id) - 1) * 120;
    if (r.getBoolean("viewer", false)) d += 90;
    float y = above(r) ? BAND - d : BAND + d;
    POS.put(id, new PVector(x, y));
  }
  // contained referents orbit their container, on their own side of the band
  for (String id : later) {
    JSONObject r = NODE.get(id); PVector p = POS.get(r.getString("parent"));
    float x = meanX(id, p.x), y = above(r) ? min(p.y, BAND) - 150 : max(p.y, BAND) + 110;
    POS.put(id, new PVector(x, y));
  }
  // push apart markers that collide
  for (int it = 0; it < 30; it++)
    for (String a : REF) for (String b : REF) {
      if (a.compareTo(b) >= 0) continue;
      PVector pa = POS.get(a), pb = POS.get(b);
      if (PVector.dist(pa, pb) < 110 && abs(pa.y - pb.y) < 60) { float s = pa.x < pb.x ? -1 : 1; pa.x += s * 6; pb.x -= s * 6; }
    }
}
float meanX(String id, float fallback) {
  HashSet<String> g = gathered(id, 0); if (g.size() == 0) return fallback;
  float s = 0; for (String c : g) s += POS.get(c).x; return s / g.size();
}

// ───────────────────────── marks ─────────────────────────
void scribbleBlob(float cx, float cy, float r, int seed, float dens) {
  randomSeed(seed); noiseSeed(seed);
  noFill();
  // contour, drawn twice like a pen going round
  for (int pass = 0; pass < 2; pass++) {
    stroke(0, 200); strokeWeight(0.8);
    beginShape();
    for (float a = 0; a <= TWO_PI + 0.3; a += 0.07) {
      float rr = r * (0.7 + 0.5 * noise(cos(a) * 1.3 + 5, sin(a) * 1.3 + 5 + pass * 0.15));
      rr += sin(a * 23) * 1.6;
      curveVertex(cx + cos(a) * rr * 1.25, cy + sin(a) * rr * 0.62);
    }
    endShape();
  }
  // inner texture: curls and hatches
  int n = int(r * r * 0.11 * dens);
  for (int i = 0; i < n; i++) {
    float a = random(TWO_PI), d = sqrt(random(1)) * r * 0.95;
    float x = cx + cos(a) * d * 1.2, y = cy + sin(a) * d * 0.58;
    float t = random(1);
    stroke(0, random(120, 230)); strokeWeight(random(0.4, 0.9));
    if (t < 0.45) {                                  // curl
      float s = random(1.2, 3.8); beginShape();
      for (float u = 0; u < TWO_PI * random(1, 1.8); u += 0.5) curveVertex(x + cos(u) * s * (1 + u * 0.06), y + sin(u) * s * 0.8);
      endShape();
    } else if (t < 0.85) {                           // hatch
      float an = random(-0.9, 0.9) + (d > r * 0.7 ? a : 0), l = random(2, 7);
      line(x, y, x + cos(an) * l, y + sin(an) * l);
    } else {                                         // seed dot
      noStroke(); fill(0, 200); ellipse(x, y, random(1, 2.6), random(1, 2.6)); noFill();
    }
  }
  // hairs on the rim
  for (int i = 0; i < r * 1.6; i++) {
    float a = random(TWO_PI), rr = r * (0.75 + 0.5 * noise(cos(a) * 1.3 + 5, sin(a) * 1.3 + 5));
    float x = cx + cos(a) * rr * 1.25, y = cy + sin(a) * rr * 0.62;
    stroke(0, 170); strokeWeight(0.5);
    line(x, y, x + cos(a + random(-0.6, 0.6)) * random(2, 7), y + sin(a + random(-0.6, 0.6)) * random(2, 6));
  }
}

void drawBand() {
  // sparse connective texture: the rest of the picture surface
  randomSeed(11);
  for (int row = -1; row <= 1; row += 2)
    for (float x = 70; x < width - 70; x += random(14, 34)) {
      float y = BAND + row * 26 + random(-14, 14), s = random(3, 11);
      stroke(0, random(60, 140)); strokeWeight(random(0.4, 0.8)); noFill();
      beginShape();
      for (float u = 0; u < TWO_PI * random(0.7, 1.6); u += 0.45) curveVertex(x + cos(u) * s * 1.4, y + sin(u) * s * 0.7);
      endShape();
    }
  for (int i = 0; i < CC.size(); i++) {
    String id = CC.getJSONObject(i).getString("id"); PVector p = POS.get(id); int k = CC.getJSONObject(i).getInt("count", 1);
    if (k == 1) scribbleBlob(p.x, p.y, BLOB.get(id), 100 + i * 7, 1);
    else for (int j = 0; j < k; j++) scribbleBlob(p.x + (j - (k - 1) / 2.0) * BLOB.get(id) * 0.9, p.y + (j % 2) * 10, BLOB.get(id) * 0.55, 100 + i * 7 + j, 1);
  }
}

void dashed(ArrayList<PVector> pts, float on, float off, float w, int g, int a) {
  float acc = 0; stroke(g, a); strokeWeight(w);
  for (int i = 1; i < pts.size(); i++) {
    PVector p = pts.get(i - 1), q = pts.get(i); float L = PVector.dist(p, q);
    if (acc % (on + off) < on) line(p.x, p.y, q.x, q.y);
    acc += L;
  }
}

// one R's orbit: an ellipse fitted around its marker and every carrier it gathers
void orbit(String id, int seed, boolean faint) {
  ArrayList<PVector> pts = new ArrayList<PVector>();
  pts.add(POS.get(id));
  for (String c : gathered(id, 0)) pts.add(POS.get(c));
  for (int i = 0; i < RR.size(); i++) { JSONObject r = RR.getJSONObject(i); if (r.getString("parent", "").equals(id)) pts.add(POS.get(r.getString("id"))); }
  PVector m = new PVector(); for (PVector p : pts) m.add(p); m.div(pts.size());
  float sxx = 0, syy = 0, sxy = 0;
  for (PVector p : pts) { float dx = p.x - m.x, dy = p.y - m.y; sxx += dx * dx; syy += dy * dy; sxy += dx * dy; }
  float ang = 0.5 * atan2(2 * sxy, sxx - syy);
  float ra = 0, rb = 0;
  for (PVector p : pts) { float dx = p.x - m.x, dy = p.y - m.y; ra = max(ra, abs(dx * cos(ang) + dy * sin(ang))); rb = max(rb, abs(-dx * sin(ang) + dy * cos(ang))); }
  ra = ra * 1.18 + 55; rb = max(rb * 1.25 + 40, 60);
  randomSeed(seed);
  for (int pass = 0; pass < 2; pass++) {
    float a2 = ang + random(-0.06, 0.06), k = 1 + pass * random(0.03, 0.08), ph = random(TWO_PI);
    ArrayList<PVector> e = new ArrayList<PVector>();
    for (float t = 0; t <= TWO_PI * 1.04; t += 0.012) {
      float wob = 1 + 0.05 * sin(t * 3 + ph);
      float x = cos(t) * ra * k * wob, y = sin(t) * rb * k * wob;
      e.add(new PVector(m.x + x * cos(a2) - y * sin(a2), m.y + x * sin(a2) + y * cos(a2)));
    }
    if (faint) dashed(e, 3, 5, 0.6, 150, 150);
    else dashed(e, pass == 0 ? 14 : 4, pass == 0 ? 6 : 6, pass == 0 ? 0.9 : 0.6, 0, pass == 0 ? 220 : 150);
  }
}

void spindle(PVector a, PVector b, float t, boolean filled) {
  PVector c = PVector.lerp(a, b, t), d = PVector.sub(b, a); d.normalize();
  PVector n = new PVector(-d.y, d.x);
  float L = 84, w = 9.5;
  PVector tip = PVector.add(c, PVector.mult(d, L * 0.55)), tail = PVector.sub(c, PVector.mult(d, L * 0.45));
  PVector s1 = PVector.add(PVector.sub(c, PVector.mult(d, L * 0.12)), PVector.mult(n, w));
  PVector s2 = PVector.sub(PVector.sub(c, PVector.mult(d, L * 0.12)), PVector.mult(n, w));
  if (filled) { fill(0); noStroke(); } else { noFill(); stroke(0); strokeWeight(0.9); }
  beginShape();
  vertex(tail.x, tail.y);
  quadraticVertex(s1.x, s1.y, tip.x, tip.y);
  quadraticVertex(s2.x, s2.y, tail.x, tail.y);
  endShape(CLOSE);
  // small inner triangle pointing toward R
  PVector k = PVector.sub(c, PVector.mult(d, L * 0.2));
  PVector f = PVector.add(k, PVector.mult(d, 7)), l = PVector.add(PVector.sub(k, PVector.mult(d, 3)), PVector.mult(n, 2.6)), r = PVector.sub(PVector.sub(k, PVector.mult(d, 3)), PVector.mult(n, 2.6));
  if (filled) { fill(255); noStroke(); } else { fill(0); noStroke(); }
  triangle(f.x, f.y, l.x, l.y, r.x, r.y);
}

void bracket(PVector a, PVector b, float dist) {     // ⌐ : where the evidence attaches
  PVector d = PVector.sub(b, a); d.normalize(); PVector n = new PVector(-d.y, d.x);
  PVector p = PVector.add(a, PVector.mult(d, dist));
  stroke(0); strokeWeight(1.6);
  PVector q = PVector.add(p, PVector.mult(n, 8));
  line(p.x, p.y, q.x, q.y);
  PVector r = PVector.add(q, PVector.mult(d, 6));
  line(q.x, q.y, r.x, r.y);
}

PVector blobEdge(String id, PVector toward) {
  PVector c = POS.get(id); if (isRef(id)) return markerEdge(c, toward);
  float r = BLOB.get(id); PVector d = PVector.sub(toward, c); d.normalize();
  return new PVector(c.x + d.x * r * 1.0, c.y + d.y * r * 0.5);
}
PVector markerEdge(PVector c, PVector toward) { PVector d = PVector.sub(toward, c); d.normalize(); return PVector.add(c, PVector.mult(d, 10)); }

String opName(String t) {
  String[] en = {"externalize", "personify", "embody", "inscribe", "substitute", "synecdoche", "depth_time", "anachronism", "layer", "radiate", "repeat", "juxtapose", "witness", "impossible_viewpoint", "activate"};
  String[] z = {"外化", "拟人化", "赋形", "铭写", "象征替代", "提喻", "纵深=时间", "时代错置", "分层", "中心辐射", "重复", "并置", "见证", "不可能视点", "仪式激活"};
  for (int i = 0; i < en.length; i++) if (en[i].equals(t)) return zh ? z[i] : t.replace("_", " ");
  return t;
}

void drawOp(JSONObject o, int i) {
  String f = o.getString("from"), t = o.getString("to"), e = o.getString("evidence");
  PVector A0 = POS.get(f), B0 = POS.get(t);
  PVector a = blobEdge(f, B0), b = isRef(t) ? markerEdge(B0, A0) : blobEdge(t, A0);
  if (e.equals("inference")) {                         // grey tangle: suspected, not counted
    randomSeed(500 + i);
    for (int k = 0; k < 9; k++) {
      stroke(110, 70); strokeWeight(0.5); noFill();
      PVector m1 = PVector.lerp(a, b, 0.33), m2 = PVector.lerp(a, b, 0.66);
      bezier(a.x, a.y, m1.x + random(-90, 90), m1.y + random(-70, 70), m2.x + random(-90, 90), m2.y + random(-70, 70), b.x, b.y);
    }
    if (showLabels) { PVector c = PVector.lerp(a, b, 0.5); fill(130); textSize(10); text(opName(o.getString("type")) + " ?", c.x + 10, c.y); }
    return;
  }
  stroke(0); strokeWeight(0.75); line(a.x, a.y, b.x, b.y);
  spindle(a, b, 0.58, e.equals("text"));
  bracket(a, b, 26);
  if (showLabels) {
    PVector d = PVector.sub(b, a); d.normalize(); PVector p = PVector.add(a, PVector.mult(d, 44));
    fill(40); textSize(10.5); textAlign(LEFT, CENTER); text(opName(o.getString("type")), p.x + 9, p.y);
  }
}

void marker(JSONObject r) {
  PVector p = POS.get(r.getString("id")); boolean inf = r.getBoolean("inferred", false);
  int ink = inf ? 140 : 0; float s = 9;
  String k = r.getString("kind");
  fill(255); stroke(ink); strokeWeight(1.1); ellipse(p.x, p.y, s * 2, s * 2);
  fill(ink); noStroke();
  if (k.equals("being")) arc(p.x, p.y, s * 2, s * 2, HALF_PI, PI + HALF_PI, PIE);                 // ◐
  else if (k.equals("experience")) { ellipse(p.x, p.y, s * 0.9, s * 0.9); }                         // ◉
  else if (k.equals("event")) arc(p.x, p.y, s * 2, s * 2, -HALF_PI, 0, PIE);                        // ◔
  else if (k.equals("concept")) { arc(p.x, p.y, s * 2, s * 2, -HALF_PI, 0, PIE); arc(p.x, p.y, s * 2, s * 2, HALF_PI, PI, PIE); }  // ◑ crossed
  else { noFill(); stroke(ink); strokeWeight(1); ellipse(p.x, p.y, s * 2.8, s * 2.8); fill(ink); noStroke(); ellipse(p.x, p.y, 4, 4); } // world
  if (r.getBoolean("embodied", false)) { noFill(); stroke(ink); strokeWeight(0.8); for (int j = 0; j < 3; j++) ellipse(p.x, p.y, s * 2 + 7 + j * 5, s * 2 + 7 + j * 5); }
  if (r.getBoolean("viewer", false)) { stroke(ink); strokeWeight(0.8); line(p.x + 12, p.y - 12, p.x + 40, p.y - 40); noFill(); arc(p.x + 46, p.y - 46, 14, 8, 0, TWO_PI); }
  if (showLabels) {
    fill(ink); textAlign(LEFT, CENTER); textSize(12.5); text(nm(r), p.x + 16, p.y + (above(r) ? -14 : 14));
    fill(ink == 0 ? 120 : 170); textSize(9.5);
    text(r.getString("id") + " · " + absZh(r.getString("absence")), p.x + 16, p.y + (above(r) ? -30 : 30));
  }
}
String absZh(String a) {
  if (!zh) return a.replace("_", " ");
  if (a.equals("inner")) return "内在"; if (a.equals("invisible")) return "不可见"; if (a.equals("unreachable")) return "不可达";
  if (a.equals("nonexistent")) return "不存在"; if (a.equals("not_yet")) return "未至"; return "超自然";
}

void draw() {
  background(255);
  // orbits first (behind)
  for (int i = 0; i < RR.size(); i++) { JSONObject r = RR.getJSONObject(i); orbit(r.getString("id"), 300 + i, r.getBoolean("inferred", false)); }
  drawBand();
  for (int i = 0; i < OO.size(); i++) drawOp(OO.getJSONObject(i), i);
  for (int i = 0; i < RR.size(); i++) marker(RR.getJSONObject(i));
  if (showLabels) for (int i = 0; i < CC.size(); i++) {
    JSONObject c = CC.getJSONObject(i); PVector p = POS.get(c.getString("id"));
    fill(255, 210); noStroke(); textSize(11); float w = textWidth(nm(c));
    float y = p.y + (i % 2 == 0 ? -BLOB.get(c.getString("id")) * 0.62 - 12 : BLOB.get(c.getString("id")) * 0.62 + 16);
    rect(p.x - w / 2 - 3, y - 9, w + 6, 17); fill(0); textAlign(CENTER, CENTER); text(nm(c), p.x, y);
  }
  // side cues
  fill(150); textSize(10); textAlign(LEFT, CENTER);
  text(zh ? "↑ 超越性缺席：超自然 / 不可达 / 不存在 / 未至" : "↑ transcendent absence", 40, BAND - 95);
  text(zh ? "— 画面（可见载体）" : "— picture surface (visible carriers)", 40, BAND);
  text(zh ? "↓ 内向缺席：内在 / 不可见" : "↓ inward absence", 40, BAND + 95);
  // title
  textAlign(LEFT, BASELINE); fill(0); textSize(15); text(A.getString("title"), 40, 50);
  fill(110); textSize(10.5); text("AIC " + A.getInt("aic_id") + "  /  " + A.getString("artist") + "  /  " + A.getString("date"), 40, 68);
  // key
  float ky = height - 42; fill(110); textSize(10);
  text(zh ? "黑梭 = 操作（文本证据）   空心梭 = 仅图像   灰缠线 = 推断，不计分   虚线轨道 = 一个 R 召集的全部载体   离带越远 = 链越深   ◐ 存在者  ◉ 经验  ◔ 事件  ◑ 概念"
          : "black spindle = operation (text)   hollow = image only   grey tangle = inference   dashed orbit = all carriers one R gathers   farther = deeper chain", 40, ky);
  if (exporting) { saveFrame("export/orbit-" + A.getInt("aic_id") + ".png"); exit(); }
}

void keyPressed() {
  if (key == 't' || key == 'T') zh = !zh;
  else if (key == 'l' || key == 'L') showLabels = !showLabels;
  else if (key == 's' || key == 'S') saveFrame("export/orbit-" + A.getInt("aic_id") + "-####.png");
  redraw();
}
