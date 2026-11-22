/* Figura animada de cada ejercicio.
   Traducción directa de FiguraEjercicioView.swift (DibujoFigura): mismos datos ("animacion" de ejercicios.json),
   mismas medidas, colores y orden de dibujo. */
(function () {
  'use strict';
  const ANCHO = 120, ALTO = 110;
  const L = { torso: 30, brazo: 15, antebrazo: 14, muslo: 22, pierna: 21, pie: 7, cuello: 10 };
  const rgb = (r, g, b, a = 1) => `rgba(${Math.round(r * 255)},${Math.round(g * 255)},${Math.round(b * 255)},${a})`;
  const C = {
    cuerpo: '#ffffff', cerca: '#ffffff', lejos: rgb(0.93, 0.93, 0.95),
    trabaja: rgb(0.90, 0.22, 0.24), trabajaLejos: rgb(0.94, 0.55, 0.55),
    secundario: rgb(0.98, 0.62, 0.20), secundarioLejos: rgb(0.99, 0.78, 0.59),
    contorno: rgb(0.10, 0.10, 0.12), contornoLejos: rgb(0.47, 0.49, 0.53),
    equipo: rgb(0.18, 0.20, 0.24), mueble: rgb(0.69, 0.73, 0.78),
    suelo: 'rgba(142,142,147,0.25)', esterilla: rgb(0.75, 0.85, 0.93), cable: 'rgba(142,142,147,0.7)',
    disco: rgb(0.27, 0.29, 0.33), centroDisco: 'rgb(204,204,204)'
  };
  const TORSO = ['pecho', 'hombros', 'trapecio', 'espalda', 'abdominales', 'oblicuos', 'lumbares'];
  const BRAZO = ['biceps', 'triceps'];
  const MUSLO = ['cuadriceps', 'isquiotibiales', 'aductores', 'abductores', 'gluteos'];
  const def = (v, d) => (v === undefined || v === null ? d : v);

  /** Pose.resuelta(deFrente:) */
  function resuelta(p, deFrente) {
    const r = { x: def(p.x, 60), y: def(p.y, 0) };
    if (deFrente) {
      r.rot = def(p.rot, 0); r.hombros = def(p.hombros, 0); r.sentado = def(p.sentado, 0);
      r.abd_a = def(p.abd_a, def(p.abd, 0)); r.abd_b = def(p.abd_b, def(p.abd, 0));
      r.codo_a = def(p.codo_a, def(p.codo, 0)); r.codo_b = def(p.codo_b, def(p.codo, 0));
      r.abre_a = def(p.abre_a, def(p.abre, 6)); r.abre_b = def(p.abre_b, def(p.abre, 6));
    } else {
      const br = def(p.brazo, -90), an = def(p.antebrazo, -90), mu = def(p.muslo, -90), pi = def(p.pierna, -90), pe = def(p.pie, 0);
      r.torso = def(p.torso, 90); r.cuello = def(p.cuello, 0);
      r.brazo = br; r.antebrazo = an; r.brazo_b = def(p.brazo_b, br); r.antebrazo_b = def(p.antebrazo_b, an);
      r.muslo = mu; r.pierna = pi; r.muslo_b = def(p.muslo_b, mu); r.pierna_b = def(p.pierna_b, pi);
      r.pie = pe; r.pie_b = def(p.pie_b, pe);
    }
    return r;
  }

  const punto = (o, ang, largo) => {
    const a = ang * Math.PI / 180;
    return { x: o.x + largo * Math.cos(a), y: o.y + largo * Math.sin(a) };
  };

  function pose(anim, t, deFrente) {
    const a = resuelta(anim.a, deFrente), b = resuelta(anim.b, deFrente);
    const r = Object.assign({}, a);
    for (const k in a) {
      if (k === 'sentado') continue;
      const vb = def(b[k], a[k]);
      r[k] = a[k] + (vb - a[k]) * t;
    }
    return r;
  }

  function articulacionesLado(p, anim, t) {
    const v = k => def(p[k], 0);
    const anclaje = def(t < 0.5 ? anim.a.anclaje : anim.b.anclaje, 'pie');
    let cadera;
    if (anclaje === 'pie') {
      const tobillo = { x: v('x'), y: v('y') };
      const rodilla = punto(tobillo, v('pierna') + 180, L.pierna);
      cadera = punto(rodilla, v('muslo') + 180, L.muslo);
    } else if (anclaje === 'mano') {
      const mano = { x: v('x'), y: v('y') };
      const codo = punto(mano, v('antebrazo') + 180, L.antebrazo);
      const hombro = punto(codo, v('brazo') + 180, L.brazo);
      cadera = punto(hombro, v('torso') + 180, L.torso);
    } else {
      cadera = { x: v('x'), y: v('y') };
    }
    const j = { cadera };
    const hombro = punto(cadera, v('torso'), L.torso);
    j.hombro = hombro;
    j.cabeza = punto(hombro, v('torso') + v('cuello'), L.cuello);
    for (const lado of ['a', 'b']) {
      const suf = lado === 'a' ? '' : '_b';
      const codo = punto(hombro, v('brazo' + suf), L.brazo);
      j['codo' + lado] = codo;
      j['mano' + lado] = punto(codo, v('antebrazo' + suf), L.antebrazo);
      const rodilla = punto(cadera, v('muslo' + suf), L.muslo);
      j['rodilla' + lado] = rodilla;
      const tobillo = punto(rodilla, v('pierna' + suf), L.pierna);
      j['tobillo' + lado] = tobillo;
      j['punta' + lado] = punto(tobillo, v('pie' + suf), L.pie);
    }
    return j;
  }

  function articulacionesFrente(p) {
    const v = k => def(p[k], 0);
    const cx = v('x'), by = v('y');
    const sentado = v('sentado') > 0.5;
    const lm = sentado ? 9 : L.muslo;
    const caderaY = sentado ? by + L.pierna + lm : by + L.muslo + L.pierna;
    const j = {};
    j.cadera = { x: cx, y: caderaY };
    j.hombro = { x: cx, y: caderaY + 28 + v('hombros') };
    j.cabeza = { x: cx, y: caderaY + 38 };
    for (const [lado, sg] of [['a', 1], ['b', -1]]) {
      const hom = { x: cx + sg * 9, y: caderaY + 28 + v('hombros') };
      j['hom' + lado] = hom;
      const ua = -90 + sg * v('abd_' + lado);
      const codo = punto(hom, ua, L.brazo);
      j['codo' + lado] = codo;
      j['mano' + lado] = punto(codo, ua + sg * v('codo_' + lado), L.antebrazo);
      const cad = { x: cx + sg * 5, y: caderaY };
      j['cad' + lado] = cad;
      const ta = -90 + sg * v('abre_' + lado);
      const rodilla = punto(cad, ta, lm);
      j['rodilla' + lado] = rodilla;
      const tobillo = punto(rodilla, sentado ? -90 : ta, L.pierna);
      j['tobillo' + lado] = tobillo;
      j['punta' + lado] = punto(tobillo, -90 + sg * 70, 4);
    }
    const rot = v('rot');
    if (rot !== 0) {
      const r = rot * Math.PI / 180;
      for (const k in j) {
        const q = j[k], dx = q.x - cx, dy = q.y - by;
        j[k] = { x: cx + dx * Math.cos(r) - dy * Math.sin(r), y: by + dx * Math.sin(r) + dy * Math.cos(r) };
      }
    }
    return j;
  }

  function toca(parte, m) {
    const alguno = lista => lista.some(x => m.has(x));
    switch (parte) {
      case 'torso': return alguno(TORSO);
      case 'brazo': return alguno(BRAZO);
      case 'antebrazo': return m.has('antebrazos');
      case 'muslo': return alguno(MUSLO);
      case 'pierna': return m.has('gemelos');
      default: return false;
    }
  }

  /** Dibuja la figura en un contexto 2D de ancho w y alto h (en píxeles del lienzo). */
  function dibujar(gc, w, h, anim, t, principalesLista, secundariosLista) {
    const principales = new Set(principalesLista || []);
    const secundarios = new Set((secundariosLista || []).filter(m => !principales.has(m)));
    const deFrente = anim.vista === 'frente';
    const color = (parte, cerca = true) => {
      if (toca(parte, principales)) return cerca ? C.trabaja : C.trabajaLejos;
      if (toca(parte, secundarios)) return cerca ? C.secundario : C.secundarioLejos;
      return cerca ? C.cerca : C.lejos;
    };

    const s = Math.min(w / ANCHO, h / ALTO);
    const ox = (w - ANCHO * s) / 2, oy = (h - ALTO * s) / 2;
    const T = q => ({ x: ox + q.x * s, y: oy + (ALTO - 8 - q.y) * s });

    gc.clearRect(0, 0, w, h);
    gc.lineCap = 'round'; gc.lineJoin = 'round';
    const linea = (pts, c, ancho) => {
      if (!pts.length) return;
      gc.beginPath();
      const p0 = T(pts[0]); gc.moveTo(p0.x, p0.y);
      for (const q of pts.slice(1)) { const p = T(q); gc.lineTo(p.x, p.y); }
      gc.strokeStyle = c; gc.lineWidth = ancho * s; gc.stroke();
    };
    const circulo = (q, r, c) => {
      const p = T(q); gc.beginPath(); gc.arc(p.x, p.y, r * s, 0, Math.PI * 2); gc.fillStyle = c; gc.fill();
    };
    const rect = (x, y, ancho, alto, radio, c) => {
      gc.beginPath();
      if (gc.roundRect) gc.roundRect(x, y, ancho, alto, radio); else gc.rect(x, y, ancho, alto);
      gc.fillStyle = c; gc.fill();
    };
    const mancuerna = (q, c) => {
      const p = T(q);
      rect(p.x - 4.5 * s, p.y - 1.8 * s, 9 * s, 3.6 * s, s, c);
      for (const dx of [-4.5, 4.5]) rect(p.x + (dx - 1.2) * s, p.y - 3 * s, 2.4 * s, 6 * s, 0.6 * s, c);
    };
    const pt = (arr, i) => ({ x: arr[i], y: arr[i + 1] });

    const pr = anim.props || {};
    const j = deFrente ? articulacionesFrente(pose(anim, t, true)) : articulacionesLado(pose(anim, t, false), anim, t);
    const J = k => j[k] || { x: 0, y: 0 };
    const seg = (a, b, c, ancho, lejos = false) => {
      linea([J(a), J(b)], lejos ? C.contornoLejos : C.contorno, ancho + 1.5);
      linea([J(a), J(b)], c, ancho);
    };
    const cabeza = () => { circulo(J('cabeza'), 6.9, C.contorno); circulo(J('cabeza'), 6.2, C.cuerpo); };

    // Suelo y accesorios fijos
    linea([{ x: 0, y: 0 }, { x: ANCHO, y: 0 }], C.suelo, 1);
    if (pr.esterilla && pr.esterilla.length >= 2) linea([{ x: pr.esterilla[0], y: 0.6 }, { x: pr.esterilla[1], y: 0.6 }], C.esterilla, 1.6);
    if (pr.banco && pr.banco.length >= 3) {
      const b = pr.banco;
      linea([{ x: b[0], y: b[2] - 2 }, { x: b[1], y: b[2] - 2 }], C.mueble, 4);
      for (const xx of [b[0] + 3, b[1] - 3]) linea([{ x: xx, y: b[2] - 2 }, { x: xx, y: 0 }], C.mueble, 1.6);
    }
    if (pr.escalon && pr.escalon.length >= 3) {
      const e = pr.escalon, a = T({ x: e[0], y: e[2] }), b = T({ x: e[1], y: 0 });
      gc.fillStyle = C.mueble; gc.fillRect(a.x, a.y, b.x - a.x, b.y - a.y);
    }
    if (pr.respaldo && pr.respaldo.length >= 4) {
      const r = pr.respaldo, o = pt(r, 0);
      linea([o, punto(o, r[2], r[3])], C.mueble, 4);
    }
    if (pr.poste && pr.poste.length >= 2) linea([{ x: pr.poste[0], y: 0 }, { x: pr.poste[0], y: pr.poste[1] }], C.mueble, 2.5);
    if (pr.polea && pr.polea.length >= 2) {
      const o = pt(pr.polea, 0);
      for (const m of (deFrente ? ['manoa', 'manob'] : ['manoa'])) linea([o, J(m)], C.cable, 0.6);
      circulo(o, 2.2, C.equipo);
    }

    if (!deFrente) {
      // Lado lejano
      seg('hombro', 'codob', color('brazo', false), 4.5, true);
      seg('codob', 'manob', color('antebrazo', false), 4, true);
      seg('cadera', 'rodillab', color('muslo', false), 6, true);
      seg('rodillab', 'tobillob', color('pierna', false), 5, true);
      seg('tobillob', 'puntab', C.lejos, 3.5, true);
      if (pr.mancuerna === true) { gc.globalAlpha = 0.55; mancuerna(J('manob'), C.equipo); gc.globalAlpha = 1; }
      // Tronco y cabeza
      seg('cadera', 'hombro', color('torso'), 10);
      cabeza();
      // Lado cercano
      seg('cadera', 'rodillaa', color('muslo'), 6.5);
      seg('rodillaa', 'tobilloa', color('pierna'), 5.5);
      seg('tobilloa', 'puntaa', C.cerca, 3.5);
      if (pr.rodillo) circulo(J(pr.rodillo), 3, C.equipo);
      if (pr.barra) { circulo(J(pr.barra), 7, C.disco); circulo(J(pr.barra), 1.6, C.centroDisco); }
      if (pr.mochila === true) { const p = T(J('manoa')); rect(p.x - 4 * s, p.y, 8 * s, 9 * s, 2 * s, C.trabaja); }
      seg('hombro', 'codoa', color('brazo'), 5);
      seg('codoa', 'manoa', color('antebrazo'), 4.5);
      if (pr.mancuerna === true) mancuerna(J('manoa'), C.equipo);
      if (pr.asa === true) { const p = T(J('manoa')); rect(p.x - 1.3 * s, p.y - 3.5 * s, 2.6 * s, 7 * s, s, C.equipo); }
    } else {
      if (pr.barra !== undefined && pr.barra !== null) linea([punto(J('manob'), 180, 6), punto(J('manoa'), 0, 6)], C.equipo, 1.8);
      if (pr.toalla === true) linea([J('manob'), J('manoa')], C.trabaja, 2.5);
      for (const lado of ['a', 'b']) {
        seg('cad' + lado, 'rodilla' + lado, color('muslo'), 6.5);
        seg('rodilla' + lado, 'tobillo' + lado, color('pierna'), 5.5);
        seg('tobillo' + lado, 'punta' + lado, C.cerca, 3.5);
      }
      const ct = color('torso');
      linea([J('cada'), J('cadb')], C.contorno, 8.5);
      linea([J('homa'), J('homb')], C.contorno, 8.5);
      linea([J('cadera'), J('hombro')], C.contorno, 14.5);
      linea([J('cada'), J('cadb')], ct, 7);
      linea([J('homa'), J('homb')], ct, 7);
      linea([J('cadera'), J('hombro')], ct, 13);
      cabeza();
      for (const lado of ['a', 'b']) {
        seg('hom' + lado, 'codo' + lado, color('brazo'), 5);
        seg('codo' + lado, 'mano' + lado, color('antebrazo'), 4.5);
        if (pr.mancuerna === true) mancuerna(J('mano' + lado), C.equipo);
        if (pr.asa === true) circulo(J('mano' + lado), 2, C.equipo);
      }
    }
  }

  const activas = new Set();
  let bucle = null;
  const reducir = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  function fotograma(ahora) {
    for (const f of activas) {
      if (!f.lienzo.isConnected) { activas.delete(f); continue; }
      const fase = ((ahora / 1000) % f.duracion) / f.duracion;
      const t = reducir ? 1 : (1 - Math.cos(fase * 2 * Math.PI)) / 2;
      f.pintar(t);
    }
    bucle = activas.size ? requestAnimationFrame(fotograma) : null;
  }

  /** Crea un <canvas> con la figura del ejercicio. Si no tiene animación devuelve null. */
  function crear(ejercicio, opciones = {}) {
    if (ejercicio.ilustracion) {
      // Dibujo de Everkinetic (CC BY-SA 4.0) animado en GIF
      const img = document.createElement('img');
      img.className = 'figura figura-gif';
      img.src = 'img/ejercicios/' + ejercicio.id + '.gif';
      img.alt = 'Animación de ' + ejercicio.nombre;
      img.width = 420; img.height = 385;
      img.loading = 'lazy';
      return img;
    }
    const anim = ejercicio.animacion;
    if (!anim) return null;
    const lienzo = document.createElement('canvas');
    lienzo.className = 'figura';
    lienzo.setAttribute('role', 'img');
    lienzo.setAttribute('aria-label', 'Animación de ' + ejercicio.nombre);
    const f = {
      lienzo, duracion: opciones.duracion || 2.6,
      pintar(t) {
        const r = lienzo.getBoundingClientRect();
        const dpr = window.devicePixelRatio || 1;
        const w = Math.max(1, Math.round(r.width * dpr)), h = Math.max(1, Math.round(r.height * dpr));
        if (lienzo.width !== w || lienzo.height !== h) { lienzo.width = w; lienzo.height = h; }
        dibujar(lienzo.getContext('2d'), w, h, anim, t, ejercicio.principales, ejercicio.secundarios);
      }
    };
    if (opciones.animada === false) {
      requestAnimationFrame(() => f.pintar(opciones.t === undefined ? 1 : opciones.t));
    } else {
      activas.add(f);
      if (!bucle) bucle = requestAnimationFrame(fotograma);
    }
    return lienzo;
  }

  window.Figura = { crear, dibujar, ANCHO, ALTO };
})();
