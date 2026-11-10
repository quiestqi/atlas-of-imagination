// The Atlas of Imagination — Exp 01 · Imagination Score with fixed axes (v1, one artwork)
//   x = position in the original picture (0 left … 1 right)
//   y = time: -1 past · 0 now · +1 future · +2 beyond time
//   z = distance from the visible world: plan A = chain steps · plan C = steps + embedding distance
// Data: data/axes_58702.json (made by scripts/03_axes.py, zC by scripts/04_clip_distance.py)
// Keys: Z switch plan A / C   T 中文/English   S save PNG   drag = rotate

import java.util.*;

JSONObject D;
JSONArray CA, RA, OA;
HashMap<String, JSONObject> NODE = new HashMap<String, JSONObject>();
boolean zh = true, planC = false, exporting = false;
final float SX = 860, SY = 175;           // pixels per unit on each axis
float CX, CY;
PFont font;

void setup() {
  size(1400, 1000);
  pixelDensity(displayDensity());
  smooth(8);
  String[] cands = {"Microsoft YaHei", "PingFang SC", "Noto Sans CJK SC", "SimHei", "SansSerif"};
  List<String> avail = Arrays.asList(PFont.list());
  String fname = "SansSerif";
  for (String c : cands) if (avail.contains(c)) { fname = c; break; }
  font = createFont(fname, 24, true); textFont(font);
  D = loadJSONObject("axes_58702.json");
  CA = D.getJSONArray("carriers"); RA = D.getJSONArray("referents"); OA = D.getJSONArray("ops");
  for (int i = 0; i < CA.size(); i++) NODE.put(CA.getJSONObject(i).getString("id"), CA.getJSONObject(i));
  for (int i = 0; i < RA.size(); i++) NODE.put(RA.getJSONObject(i).getString("id"), RA.getJSONObject(i));
  if (args != null) for (String a : args) { if (a.equals("--export-A")) { exporting = true; planC = false; } if (a.equals("--export-C")) { exporting = true; planC = true; } }
  noLoop();
}

boolean isRef(String id) { return id.startsWith("R"); }
boolean zcReady() { for (int i = 0; i < RA.size(); i++) if (RA.getJSONObject(i).isNull("zC")) return false; return true; }
float zOf(JSONObject n) { if (!isRef(n.getString("id"))) return 0; return (planC && zcReady()) ? n.getFloat("zC") : n.getFloat("zA"); }
float yOf(JSONObject n) { return isRef(n.getString("id")) ? n.getFloat("time") : 0; }
String nm(JSONObject n) { return zh ? n.getString("zh") : n.getString("en"); }

// world: x 0..1, y time, z steps  →  screen (oblique: x horizontal, y vertical, z receding up-right)
float ZANG = 0.46, ZLEN = 120;                      // angle and length of one z step on screen
PVector pr(float x, float y, float z) {
  return new PVector(CX + (x - 0.5) * SX + z * ZLEN * cos(ZANG), CY - y * SY - z * ZLEN * sin(ZANG));
}
PVector at(JSONObject n) { return pr(n.getFloat("x"), yOf(n), zOf(n)); }

void ln(PVector a, PVector b) { line(a.x, a.y, b.x, b.y); }
void dashed(PVector a, PVector b, float on, float off) {
  float L = PVector.dist(a, b); if (L < 1) return;
  for (float s = 0; s < L; s += on + off) { PVector p = PVector.lerp(a, b, s / L), q = PVector.lerp(a, b, min(s + on, L) / L); ln(p, q); }
}
void dotted(PVector a, PVector b, float gap) {
  float L = PVector.dist(a, b); noStroke();
  for (float s = 0; s <= L; s += gap) { PVector p = PVector.lerp(a, b, s / L); ellipse(p.x, p.y, 1.6, 1.6); }
}

void spindle(PVector a, PVector b, float t, int mode) {   // 0 text = filled, 1 image = hollow
  PVector c = PVector.lerp(a, b, t), d = PVector.sub(b, a); float L = min(70, d.mag() * 0.45); d.normalize();
  PVector n = new PVector(-d.y, d.x); float w = 7.5;
  PVector tip = PVector.add(c, PVector.mult(d, L * 0.55)), tail = PVector.sub(c, PVector.mult(d, L * 0.45));
  PVector m = PVector.sub(c, PVector.mult(d, L * 0.1)), s1 = PVector.add(m, PVector.mult(n, w)), s2 = PVector.sub(m, PVector.mult(n, w));
  if (mode == 0) { fill(0); noStroke(); } else { noFill(); stroke(0); strokeWeight(0.9); }
  beginShape(); vertex(tail.x, tail.y); quadraticVertex(s1.x, s1.y, tip.x, tip.y); quadraticVertex(s2.x, s2.y, tail.x, tail.y); endShape(CLOSE);
}

String opName(String t) {
  String[] en = {"externalize", "personify", "embody", "inscribe", "substitute", "synecdoche", "depth_time", "anachronism", "layer", "radiate", "repeat", "juxtapose", "witness", "impossible_viewpoint", "activate"};
  String[] z = {"外化", "拟人化", "赋形", "铭写", "象征替代", "提喻", "纵深=时间", "时代错置", "分层", "中心辐射", "重复", "并置", "见证", "不可能视点", "仪式激活"};
  for (int i = 0; i < en.length; i++) if (en[i].equals(t)) return zh ? z[i] : t.replace("_", " ");
  return t;
}

void draw() {
  background(255);
  float zmax = 2.6;
  CX = width * 0.5; CY = height * 0.5;
  // centre the box on screen
  PVector lo = pr(0, -1, 0), hi = pr(1, 2, zmax), m1 = pr(0, 2, zmax), m2 = pr(1, -1, 0);
  float minx = min(min(lo.x, hi.x), min(m1.x, m2.x)), maxx = max(max(lo.x, hi.x), max(m1.x, m2.x));
  float miny = min(min(lo.y, hi.y), min(m1.y, m2.y)), maxy = max(max(lo.y, hi.y), max(m1.y, m2.y));
  CX += width * 0.5 - (minx + maxx) / 2; CY += height * 0.47 - (miny + maxy) / 2;

  drawAxes(zmax);

  // operations
  for (int i = 0; i < OA.size(); i++) {
    JSONObject o = OA.getJSONObject(i); String ev = o.getString("evidence");
    JSONObject f = NODE.get(o.getString("from")), t = NODE.get(o.getString("to"));
    PVector a = at(f), b = at(t);
    PVector d = PVector.sub(b, a); d.normalize(); b = PVector.sub(b, PVector.mult(d, 11)); a = PVector.add(a, PVector.mult(d, 6));
    if (ev.equals("inference")) { fill(150); dotted(a, b, 5); }
    else { stroke(0); strokeWeight(0.8); ln(a, b); spindle(a, b, 0.55, ev.equals("text") ? 0 : 1); }
    PVector lp = PVector.lerp(a, b, 0.3); fill(ev.equals("inference") ? 150 : 50); textSize(10.5); textAlign(LEFT, CENTER);
    text(opName(o.getString("type")) + (ev.equals("inference") ? " ?" : ""), lp.x + 8, lp.y);
  }
  // nesting: child inside parent
  for (int i = 0; i < RA.size(); i++) {
    JSONObject r = RA.getJSONObject(i); if (!r.hasKey("parent")) continue;
    stroke(0, 150); strokeWeight(0.8); dashed(at(r), at(NODE.get(r.getString("parent"))), 3, 4);
    PVector m = PVector.lerp(at(r), at(NODE.get(r.getString("parent"))), 0.5); fill(90); textSize(10); text(zh ? "在梦中 ∈" : "inside ∈", m.x + 6, m.y);
  }
  // referents with coordinate drop lines
  for (int i = 0; i < RA.size(); i++) {
    JSONObject r = RA.getJSONObject(i); boolean inf = r.getBoolean("inferred", false);
    float x = r.getFloat("x"), y = yOf(r), z = zOf(r);
    fill(inf ? 190 : 140); dotted(pr(x, y, z), pr(x, 0, z), 4);           // down/up to "now"
    stroke(inf ? 210 : 175); strokeWeight(0.6); dashed(pr(x, 0, z), pr(x, 0, 0), 2, 4);   // back to the picture plane
    marker(r);
  }
  // carriers on the picture line (y = now, z = 0); labels stacked when carriers sit close together
  Integer[] idx = new Integer[CA.size()]; for (int i = 0; i < idx.length; i++) idx[i] = i;
  Arrays.sort(idx, new Comparator<Integer>() { public int compare(Integer a, Integer b) { return Float.compare(CA.getJSONObject(a).getFloat("x"), CA.getJSONObject(b).getFloat("x")); } });
  float lastX = -999; int row = 0;
  for (int i : idx) {
    JSONObject c = CA.getJSONObject(i); PVector p = at(c);
    row = (p.x - lastX < 110) ? row + 1 : 0; lastX = p.x;
    float ly = p.y + 22 + row * 17;
    stroke(170); strokeWeight(0.5); line(p.x, p.y + 6, p.x, ly - 2);
    fill(0); noStroke(); ellipse(p.x, p.y, 10, 10);
    fill(30); textSize(11); textAlign(LEFT, TOP); text(nm(c), p.x + 4, ly - 6);
  }
  drawTitle();
  if (exporting) { saveFrame("export/axes-" + (planC ? "C" : "A") + "-" + D.getInt("aic_id") + ".png"); exit(); }
}

void marker(JSONObject r) {
  PVector p = at(r); boolean inf = r.getBoolean("inferred", false); int ink = inf ? 150 : 0; float s = 10;
  String k = r.getString("kind");
  fill(255); stroke(ink); strokeWeight(1.1); ellipse(p.x, p.y, s * 2, s * 2); fill(ink); noStroke();
  if (k.equals("being")) arc(p.x, p.y, s * 2, s * 2, HALF_PI, PI + HALF_PI, PIE);
  else if (k.equals("experience")) ellipse(p.x, p.y, s, s);
  else if (k.equals("event")) arc(p.x, p.y, s * 2, s * 2, -HALF_PI, 0, PIE);
  else if (k.equals("concept")) { arc(p.x, p.y, s * 2, s * 2, -HALF_PI, 0, PIE); arc(p.x, p.y, s * 2, s * 2, HALF_PI, PI, PIE); }
  else { noFill(); stroke(ink); ellipse(p.x, p.y, s * 2.8, s * 2.8); }
  if (r.getBoolean("embodied", false)) { noFill(); stroke(ink); strokeWeight(0.8); for (int j = 0; j < 3; j++) ellipse(p.x, p.y, s * 2 + 7 + j * 5, s * 2 + 7 + j * 5); }
  fill(ink); textAlign(LEFT, CENTER); textSize(13); text(nm(r), p.x + 18, p.y - 8);
  fill(inf ? 170 : 110); textSize(9.5);
  String zs = (planC && zcReady()) ? nf(zOf(r), 1, 2) : str(int(zOf(r)));
  text("(" + nf(r.getFloat("x"), 1, 2) + ", " + int(yOf(r)) + ", " + zs + ")", p.x + 18, p.y + 8);
}

void drawAxes(float zmax) {
  String[] tl = zh ? new String[]{"过去", "此刻", "未来", "超时间"} : new String[]{"past", "now", "future", "beyond time"};
  // time levels: a thin frame per level (x × z)
  for (int y = -1; y <= 2; y++) {
    stroke(y == 0 ? 150 : 215); strokeWeight(y == 0 ? 0.9 : 0.6);
    PVector a = pr(0, y, 0), b = pr(1, y, 0), c = pr(1, y, zmax), d = pr(0, y, zmax);
    ln(a, b); ln(b, c); ln(c, d); ln(d, a);
    fill(y == 0 ? 0 : 120); textSize(11); textAlign(RIGHT, CENTER); text(tl[y + 1] + "  " + (y > 0 ? "+" : "") + y, a.x - 10, a.y);
  }
  // grid on the "now" plane: one line per step of z, one per 0.25 of x
  stroke(228); strokeWeight(0.5);
  for (float x = 0.25; x < 1; x += 0.25) ln(pr(x, 0, 0), pr(x, 0, zmax));
  for (int z = 1; z <= 2; z++) ln(pr(0, 0, z), pr(1, 0, z));
  // vertical edges
  stroke(200); strokeWeight(0.6);
  ln(pr(0, -1, 0), pr(0, 2, 0)); ln(pr(1, -1, 0), pr(1, 2, 0)); ln(pr(0, -1, zmax), pr(0, 2, zmax)); ln(pr(1, -1, zmax), pr(1, 2, zmax));
  // picture plane (z = 0) emphasised
  stroke(0); strokeWeight(1.3); ln(pr(0, 0, 0), pr(1, 0, 0));
  // x ticks along the picture line
  fill(110); textSize(10); textAlign(CENTER, TOP);
  for (int i = 0; i <= 4; i++) { float x = i / 4.0; PVector p = pr(x, -1, 0); stroke(120); strokeWeight(0.7); ln(p, new PVector(p.x, p.y + 5)); text(nf(x, 1, 2), p.x, p.y + 8); }
  PVector xl = pr(0.5, -1, 0); fill(0); textSize(11.5); text(zh ? "x  画面位置：左 → 右" : "x  position in picture: left → right", xl.x, xl.y + 26);
  // z ticks along the right floor edge
  textAlign(LEFT, CENTER);
  for (int z = 0; z <= 2; z++) { PVector p = pr(1, -1, z); stroke(120); ln(p, new PVector(p.x + 6, p.y)); fill(110); textSize(10); text(z == 0 ? (zh ? "0 可见" : "0 visible") : z + (zh ? " 步" : " step"), p.x + 10, p.y); }
  PVector zl = pr(1, -1, zmax); fill(0); textSize(11.5);
  text(zh ? "z  离可见世界的距离" + (planC ? "（方案 C：步数 + 向量）" : "（方案 A：链的步数）") : "z  distance from the visible" + (planC ? " (C: steps + embedding)" : " (A: chain steps)"), zl.x + 10, zl.y + 4);
  PVector yl = pr(0, 2, 0); fill(0); textAlign(RIGHT, CENTER); text(zh ? "y  时间" : "y  time", yl.x - 10, yl.y - 26);
}

void drawTitle() {
  textAlign(LEFT, BASELINE); fill(0); textSize(15); text(D.getString("title"), 40, 50);
  fill(110); textSize(10.5); text("AIC " + D.getInt("aic_id") + "  /  " + D.getString("artist") + "  /  " + D.getString("date"), 40, 68);
  textAlign(RIGHT, BASELINE); fill(140); textSize(10);
  text(zh ? "黑梭 = 操作（文本证据）   空心梭 = 仅图像   点线 = 推断，不计分   ◐ 存在者  ◉ 经验  ◔ 事件  ◑ 概念   ● 可见载体   三圈 = 在图中有形体   (x, y, z) = 坐标"
          : "spindle = operation (text)   hollow = image   dotted = inference   (x, y, z) = coordinates", width - 40, height - 30);
  if (planC && !zcReady()) { fill(0); textAlign(LEFT, BASELINE); textSize(12); text(zh ? "方案 C 尚未运行（需要 CLIP），当前显示方案 A" : "plan C not run yet — showing plan A", 40, 92); }
}

void mouseDragged() { ZANG = constrain(ZANG - (mouseY - pmouseY) * 0.004, 0.1, 1.4); ZLEN = constrain(ZLEN + (mouseX - pmouseX) * 0.5, 40, 260); redraw(); }
void keyPressed() {
  if (key == 'z' || key == 'Z') planC = !planC;
  else if (key == 't' || key == 'T') zh = !zh;
  else if (key == 's' || key == 'S') saveFrame("export/axes-" + (planC ? "C" : "A") + "-" + D.getInt("aic_id") + "-####.png");
  redraw();
}
