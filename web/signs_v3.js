// Imagination Score · sign vocabulary v3 (after Anestis Logothetis' graphic notation)
// Thin ink connecting lines carry small dense signs: stem-and-bar heads, black blobs, open rings, coils,
// zigzags, spirals, hatched wedges, diamonds, flags. Fields are hairline circles holding a texture.
//
// Mapping (each variation has one data source):
//   R  = a small 3D constellation (after Logothetis' "globes"): a STRUCTURE of hairlines + SIGNS strung along it
//          structure = KIND   being = solid black square (signs ringed around it, (n+1)·e of them) · experience = one closed circle
//                             event = star (rays out of a cluster) · concept = sphere of great circles through two poles
//          number of orbits / rays / arcs / turns = number of text operations reaching R (+1)
//          sign strung on it = ABSENCE   inner = ⊙ · supernatural = ○ hollow circle · not_yet = forward flag
//                             invisible = ● solid dot · unreachable = ‖ · nonexistent = ×
//          signs per curve = number of distinct evidence spans (E) behind those operations
//   O  = hairline + the base sign of one of four families (显现 · 指代 · 时间 · 组合) + one modifier
//   E  = text → signs filled black · image → signs drawn open · inference → not drawn
// Injected into pages by scripts/11_build_v3.py (no module import, so the pages also work from file://).

function makeSigns({ THREE, Line2, LineMaterial, LineGeometry, RES }) {
  const INK = 0x111111;
  const mats = [];
  const Z = new THREE.Vector3(0, 0, 1), Yv = new THREE.Vector3(0, 1, 0), Xv = new THREE.Vector3(1, 0, 0);

  // ── ink primitives ──
  function thick(pts, g, w = 2.4) {
    const geo = new LineGeometry(); geo.setPositions(pts.flatMap(p => [p.x, p.y, p.z]));
    const m = new LineMaterial({ color: INK, linewidth: w, transparent: true }); m.resolution.copy(RES); mats.push(m);
    const l = new Line2(geo, m); l.computeLineDistances(); g.add(l); return l;
  }
  function hair(pts, g, color = INK, opacity = 1) {
    const l = new THREE.Line(new THREE.BufferGeometry().setFromPoints(pts), new THREE.LineBasicMaterial({ color, transparent: true, opacity }));
    g.add(l); return l;
  }
  // a local 2D frame in 3D: P(x, y) = o + u·x + v·y
  function frame(o, u, v) { return { o, u: u.clone().normalize(), v: v.clone().normalize(), P(x, y) { return this.o.clone().addScaledVector(this.u, x).addScaledVector(this.v, y); } }; }
  function fill(fr, pts2, g, filled = true, w = 1.2) {
    if (!filled) { thick([...pts2, pts2[0]].map(([x, y]) => fr.P(x, y)), g, w); return; }
    const tri = THREE.ShapeUtils.triangulateShape(pts2.map(([x, y]) => new THREE.Vector2(x, y)), []);
    const pos = []; for (const t of tri) for (const i of t) { const p = fr.P(pts2[i][0], pts2[i][1]); pos.push(p.x, p.y, p.z); }
    const geo = new THREE.BufferGeometry(); geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
    const m = new THREE.Mesh(geo, new THREE.MeshBasicMaterial({ color: INK, side: THREE.DoubleSide, transparent: true })); g.add(m); return m;
  }
  const circ2 = (x, y, r, n = 20, a0 = 0, a1 = Math.PI * 2) => Array.from({ length: n + 1 }, (_, i) => { const a = a0 + (a1 - a0) * i / n; return [x + Math.cos(a) * r, y + Math.sin(a) * r]; });
  const P2 = (fr, pts2) => pts2.map(([x, y]) => fr.P(x, y));

  // ── signs (frame-local units) ──
  const S = {
    blob(fr, x, y, r, g, filled = true) { const c = circ2(x, y, r, 18); c.pop(); return fill(fr, c, g, filled, 1.2); },
    ring(fr, x, y, r, g, w = 1.3) { thick(P2(fr, circ2(x, y, r, 28)), g, w); },
    burst(fr, x, y, r, g) { for (let k = 0; k < 10; k++) { const a = k * Math.PI / 5, rr = r * (k % 2 ? 0.55 : 1); thick([fr.P(x, y), fr.P(x + Math.cos(a) * rr, y + Math.sin(a) * rr)], g, 1.4); } S.blob(fr, x, y, r * 0.22, g); },
    diamond(fr, x, y, r, g, filled = true) { return fill(fr, [[x - r, y], [x, y + r * 0.7], [x + r, y], [x, y - r * 0.7]], g, filled); },
    flag(fr, x, y, dir, s, g, filled = true, h = 0.55) { return fill(fr, [[x, y - s * h], [x + dir * s, y], [x, y + s * h]], g, filled); },
    stemBars(fr, x, y, n, s, g, filled = true) {          // Logothetis' stem-and-bar head
      thick([fr.P(x, y), fr.P(x, y + s * 2.4)], g, 1.4);
      for (let k = 0; k < n; k++) { const yy = y + s * (0.5 + k * 0.42); thick([fr.P(x, yy), fr.P(x + s * 1.1, yy)], g, 1.4); }
      S.flag(fr, x, y + s * 2.4, 1, s * 0.8, g, filled);
    },
    wedge(fr, x0, x1, w0, w1, mode, g) {                  // mode: 'filled' | 'hatched' | 'open'
      const pts = [[x0, -w0], [x1, -w1], [x1, w1], [x0, w0]];
      if (mode === 'filled') return fill(fr, pts, g, true);
      thick([...pts, pts[0]].map(([x, y]) => fr.P(x, y)), g, 1.1);
      if (mode === 'hatched') { const n = Math.max(6, Math.round(Math.abs(x1 - x0) / ((w0 + w1) * 0.35 + 1e-3))); for (let k = 1; k < n; k++) { const t = k / n, x = x0 + (x1 - x0) * t, w = w0 + (w1 - w0) * t; thick([fr.P(x, -w), fr.P(x + (w1 + w0) * 0.12, w)], g, 0.9); } }
    },
    coil(fr, x0, x1, loops, r, g, w = 1.5) {              // spring of loops (prolate cycloid)
      const L = x1 - x0, n = loops * 24, pts = [];
      for (let i = 0; i <= n; i++) { const t = i / n, th = t * loops * Math.PI * 2; pts.push(fr.P(x0 + t * L - r * Math.sin(th) * 1.25, -r * Math.cos(th) + r)); }
      thick(pts, g, w);
    },
    zigzag(fr, x0, x1, amp, n, g, w = 1.6) { const pts = []; for (let i = 0; i <= n; i++) pts.push(fr.P(x0 + (x1 - x0) * i / n, i === 0 || i === n ? 0 : (i % 2 ? amp : -amp))); thick(pts, g, w); },
    spiral(fr, x, y, r, turns, g, w = 1.6) { const n = Math.round(turns * 40), pts = []; for (let i = 0; i <= n; i++) { const t = i / n, a = t * turns * Math.PI * 2; pts.push(fr.P(x + Math.cos(a) * r * t, y + Math.sin(a) * r * t)); } thick(pts, g, w); },
  };

  // ── R: a 3D constellation = STRUCTURE (kind) + SIGNS strung along it (absence) ──
  // info = { n: text operations reaching R, e: distinct evidence spans behind them }
  function absenceSign(ab, fr, s, g) {                     // one small sign at the frame origin
    if (ab === 'inner') { S.ring(fr, 0, 0, s * 0.75, g, 1.2); S.blob(fr, 0, 0, s * 0.28, g); }   // ⊙ held inside
    else if (ab === 'supernatural') S.ring(fr, 0, 0, s * 0.6, g, 1.4);                          // ○
    else if (ab === 'not_yet') S.flag(fr, -s * 0.5, 0, 1, s * 1.2, g);
    else if (ab === 'invisible') S.blob(fr, 0, 0, s * 0.5, g);                                   // ●
    else if (ab === 'unreachable') { thick([fr.P(-s * 0.35, -s), fr.P(-s * 0.35, s)], g, 1.4); thick([fr.P(s * 0.35, -s), fr.P(s * 0.35, s)], g, 1.4); }
    else if (ab === 'nonexistent') { thick([fr.P(-s, -s), fr.P(s, s)], g, 1.4); thick([fr.P(-s, s), fr.P(s, -s)], g, 1.4); }
  }
  // curves of the structure, in local coordinates (unit radius), as arrays of Vector3
  function structure(kind, n) {
    const curves = [], V3 = (x, y, z) => new THREE.Vector3(x, y, z);
    if (kind === 'being') {                                // atom: n+1 tilted orbits
      const m = n + 1;
      for (let k = 0; k < m; k++) { const rot = new THREE.Euler(0.55, 0, k * Math.PI / m); const pts = [];
        for (let i = 0; i <= 72; i++) { const a = i / 72 * Math.PI * 2; pts.push(V3(Math.cos(a), Math.sin(a) * 0.36, 0).applyEuler(rot)); } curves.push(pts); }
    } else if (kind === 'experience') {                    // one closed circle, facing the viewer
      const pts = []; for (let i = 0; i <= 96; i++) { const a = i / 96 * Math.PI * 2; pts.push(V3(Math.cos(a), Math.sin(a), 0)); } curves.push(pts);
    } else if (kind === 'event') {                         // star: 4(n+1) rays from a cluster (Fibonacci directions)
      const m = 4 * (n + 1); for (let k = 0; k < m; k++) { const y = 1 - 2 * (k + 0.5) / m, r = Math.sqrt(1 - y * y), a = k * 2.39996; const L = k % 2 ? 0.62 : 1;
        curves.push([V3(0, 0, 0).addScaledVector(V3(Math.cos(a) * r, y, Math.sin(a) * r), 0.18), V3(Math.cos(a) * r * L, y * L, Math.sin(a) * r * L)]); }
    } else if (kind === 'concept') {                       // meridians: n+3 full great circles through two poles → a whole sphere
      const m = n + 3; for (let k = 0; k < m; k++) { const a = k * Math.PI / m, pts = [];
        for (let i = 0; i <= 96; i++) { const t = i / 96 * Math.PI * 2; pts.push(V3(Math.sin(t) * Math.cos(a), Math.cos(t), Math.sin(t) * Math.sin(a))); } curves.push(pts); }
    } else {                                               // world: tilted parallels
      const m = n + 2; for (let k = 0; k < m; k++) { const y = -0.8 + 1.6 * k / (m - 1), r = Math.sqrt(1 - y * y), pts = [], rot = new THREE.Euler(0, 0, 0.5);
        for (let i = 0; i <= 64; i++) { const a = i / 64 * Math.PI * 2; pts.push(V3(Math.cos(a) * r, y, Math.sin(a) * r).applyEuler(rot)); } curves.push(pts); }
    }
    return curves;
  }
  function rGlyph(r, c, rad, g, info = {}) {
    if (r.kind === 'world') r = { ...r, kind: 'concept' };   // four kinds: "world" merged into "concept" (2026-11-11)
    const n = Math.max(1, info.n || 1), e = Math.max(1, info.e || 1);
    rad *= r.kind === 'event' ? 1.6 : 1.4;                // display scale: every R drawn larger; stars (half their rays short) a bit more
    if (r.kind === 'being') {                              // being = one solid black square (a body), signs around it
      const fr0 = frame(c, Xv, Yv), h = rad * 0.55; fill(fr0, [[-h, -h], [h, -h], [h, h], [-h, h]], g, true);
      const m = (n + 1) * e, s0 = rad * 0.085 + 0.008, R0 = h * 1.55;
      for (let k = 0; k < m; k++) { const a = Math.PI / 4 + k * Math.PI * 2 / m; absenceSign(r.absence, frame(c.clone().addScaledVector(Xv, Math.cos(a) * R0).addScaledVector(Yv, Math.sin(a) * R0), Xv, Yv), s0, g); }
      return;
    }
    const curves = structure(r.kind, n).map(cv => cv.map(p => c.clone().addScaledVector(p, rad)));
    curves.forEach(cv => hair(cv, g));
    if (r.kind === 'event') for (let k = 0; k < 5; k++) S.blob(frame(c, Xv, Yv), Math.cos(k * 1.3) * rad * 0.1, Math.sin(k * 1.7) * rad * 0.1, rad * 0.045, g);
    if (r.kind === 'concept') { for (const yy of [1, -1]) S.ring(frame(c.clone().addScaledVector(Yv, rad * yy), Xv, Yv), 0, 0, rad * 0.06, g); }
    const s = rad * 0.085 + 0.008;
    curves.forEach(cv => {                                 // e signs per curve; on rays the sign sits at the tip
      const idx = r.kind === 'event' ? [cv.length - 1] : Array.from({ length: e }, (_, k) => Math.round((k + 0.5) / e * (cv.length - 1)));
      idx.forEach(i => absenceSign(r.absence, frame(cv[i], Xv, Yv), s, g));
    });
  }

  // ── O: phrases. a, b = endpoints (3D); unit = sign size in world units ──
  function opFrame(a, b) {
    const d = b.clone().sub(a); const L = d.length(); d.normalize();
    let side = new THREE.Vector3().crossVectors(Z, d); if (side.length() < 1e-3) side = Yv.clone(); side.normalize();
    return [frame(a, d, side), L];
  }
  // ── O: four families, one base sign each; one modifier carries the in-family difference ──
  //   显现 manifest  externalize · embody                       blob(s) + n half-circle arcs drawn long line · dot · long line   n = number of figures
  //   指代 refer     substitute · inscribe                       dashed line of bars (long at both ends, short in the middle)   bars grouped by n = inscribed words
  //   时间 time      depth_time · foreshadow · trigger · anachr.  line of tall, spaced triangle arrows   ▷ toward the future · ◁ toward the past
  //   组合 compose   contain · contrast                           point-cloud ring band          wraps R-in-R, or two carriers set against each other
  const FAMILY = { externalize: 'manifest', embody: 'manifest', substitute: 'refer', inscribe: 'refer',
                   depth_time: 'time', foreshadow: 'time', trigger: 'time', anachronism: 'time', contain: 'compose', contrast: 'compose', juxtapose: 'compose', witness: 'manifest', synecdoche: 'refer',
                   impossible_viewpoint: 'manifest', activate: 'manifest', radiate: 'compose', layer: 'compose' };
  function phrase(type, a, b, g, ev, unit, extra = {}) {
    const filled = ev !== 'image';
    const [fr, L] = opFrame(a, b), u = unit, fam = FAMILY[type];
    if (fam === 'manifest') { semiDashDot(fr, L, u, g, filled); S.blob(fr, 0, 0, u * 1.1, g, filled); return; }
    if (fam === 'refer') {                                 // a dashed line made of bars; bars come in groups of n (n = inscribed words), diamond at the middle
      S.blob(fr, 0, 0, u * 0.55, g, filled);
      const n = Math.max(1, extra.words || 1), step = u * 0.55, gap = u * 1.5;
      let x = u * 1.4;
      while (x < L - u * 0.6) {
        for (let k = 0; k < n && x < L - u * 0.6; k++, x += step)
          { const t = Math.abs(x / L - 0.5) * 2, h = u * (0.35 + 0.95 * t * t); thick([fr.P(x, -h), fr.P(x, h)], g, 2.2); }
        x += gap - step;
      }
      return;
    }
    if (fam === 'time') {                                  // the line itself is a row of triangle arrows; ▷ future, ◁ past
      const dir = type === 'anachronism' ? -1 : 1, s = u * 1.0, step = u * 3.4;
      if (!extra.fromR) S.blob(fr, 0, 0, u * 0.55, g, filled);
      for (let x = u * 1.4; x < L - s; x += step) S.flag(fr, dir > 0 ? x : x + s, 0, dir, s, g, filled, 1.05);
      return;
    }
    if (fam === 'compose') {                               // point-cloud ring band wrapping both ends (R in R, or C against C)
      const m = L / 2, ra = L / 2 + (extra.rParent || u * 3), rb = (extra.rParent || u * 3) * 1.1, w = (extra.rParent || u * 3) * 0.16;
      const N = extra.points || 1400, pos = new Float32Array(N * 3), third = new THREE.Vector3().crossVectors(fr.u, fr.v).normalize();
      let seed = 7; const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
      for (let i = 0; i < N; i++) {
        const th = rnd() * Math.PI * 2, rr = 1 + (rnd() + rnd() - 1) * w / rb, h = (rnd() + rnd() - 1) * w;
        const p = fr.P(m + Math.cos(th) * ra * rr, Math.sin(th) * rb * rr).addScaledVector(third, h);
        pos[i * 3] = p.x; pos[i * 3 + 1] = p.y; pos[i * 3 + 2] = p.z;
      }
      const geo = new THREE.BufferGeometry(); geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
      g.add(new THREE.Points(geo, new THREE.PointsMaterial({ color: INK, transparent: true, size: extra.ortho ? 1.4 : 0.016, sizeAttenuation: !extra.ortho })));
      return;
    }
    hair([fr.P(0, 0), fr.P(L, 0)], g);
  }
  // a half-circle from x = 0 to x = L (bulging to +v), drawn as long line · dot · long line …
  function semiDashDot(fr, L, u, g, filled) {
    const r = L / 2, N = 160, pts = []; for (let i = 0; i <= N; i++) { const a = Math.PI - Math.PI * i / N; pts.push([r + Math.cos(a) * r, Math.sin(a) * r]); }
    const seg = u * 5, gap = u * 1.6; let acc = 0, on = true, run = [pts[0]], next = seg;
    for (let i = 1; i < pts.length; i++) {
      acc += Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]);
      if (on) run.push(pts[i]);
      if (acc >= next) {
        if (on) { thick(run.map(([x, y]) => fr.P(x, y)), g, 1.3); next = acc + gap; on = false; }
        else { const m = pts[i - Math.max(1, Math.round(N * gap / (Math.PI * r) / 2))] || pts[i]; S.blob(fr, m[0], m[1], u * 0.32, g, filled); run = [pts[i]]; next = acc + seg; on = true; }
      }
    }
    if (on && run.length > 1) thick(run.map(([x, y]) => fr.P(x, y)), g, 1.3);
  }
  function embody(anchors, tip, g, ev, unit) { for (const p of anchors) { const [fr, L] = opFrame(p, tip); semiDashDot(fr, L, unit, g, ev !== 'image'); S.blob(fr, 0, 0, unit * 1.1, g, ev !== 'image'); } }

  return { thick, hair, frame, fill, S, rGlyph, absenceSign, phrase, embody, FAMILY, mats };
}
