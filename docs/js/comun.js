/* GymApp web · código común: datos, mapa muscular, tarjetas, ficha del ejercicio, favoritos y tema. */
(function () {
  'use strict';

  const MUSCULOS = [
    ['pecho', 'Pecho', 'superior'], ['hombros', 'Hombros', 'superior'], ['trapecio', 'Trapecio', 'superior'],
    ['biceps', 'Bíceps', 'superior'], ['triceps', 'Tríceps', 'superior'], ['antebrazos', 'Antebrazos', 'superior'],
    ['abdominales', 'Abdominales', 'core'], ['oblicuos', 'Oblicuos', 'core'], ['espalda', 'Espalda (dorsales)', 'superior'],
    ['lumbares', 'Lumbares', 'core'], ['gluteos', 'Glúteos', 'inferior'], ['cuadriceps', 'Cuádriceps', 'inferior'],
    ['isquiotibiales', 'Isquiotibiales', 'inferior'], ['aductores', 'Aductores', 'inferior'],
    ['abductores', 'Abductores', 'inferior'], ['gemelos', 'Gemelos', 'inferior']
  ].map(([id, nombre, zona]) => ({ id, nombre, zona }));
  const NOMBRE_MUSCULO = Object.fromEntries(MUSCULOS.map(m => [m.id, m.nombre]));
  const ZONAS = [['superior', 'Tren superior'], ['core', 'Core'], ['inferior', 'Tren inferior']];

  const LUGARES = {
    pesas: { nombre: 'Pesas', descripcion: 'Barras y mancuernas', emoji: '🏋️', color: 'var(--azul)' },
    maquinas: { nombre: 'Máquinas', descripcion: 'Poleas y máquinas', emoji: '⚙️', color: 'var(--celeste)' },
    casa: { nombre: 'En casa', descripcion: 'Sin material', emoji: '🛋️', color: 'var(--coral)' }
  };

  // ---------- Utilidades ----------
  const esc = s => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const normalizar = s => String(s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();
  const $ = (sel, raiz = document) => raiz.querySelector(sel);
  const $$ = (sel, raiz = document) => Array.from(raiz.querySelectorAll(sel));
  const html = (texto) => { const t = document.createElement('template'); t.innerHTML = texto.trim(); return t.content.firstElementChild; };
  const numero = (v, dec = 0) => Number(v).toLocaleString('es-ES', { minimumFractionDigits: 0, maximumFractionDigits: dec });

  const almacen = {
    leer(clave, porDefecto) {
      try { const v = localStorage.getItem('gymapp.' + clave); return v === null ? porDefecto : JSON.parse(v); }
      catch (e) { return porDefecto; }
    },
    guardar(clave, valor) {
      try { localStorage.setItem('gymapp.' + clave, JSON.stringify(valor)); } catch (e) { /* sin almacenamiento */ }
    }
  };

  // ---------- Datos ----------
  const cache = {};
  function cargar(nombre) {
    if (!cache[nombre]) {
      cache[nombre] = fetch('datos/' + nombre + '.json').then(r => {
        if (!r.ok) throw new Error('No se pudo leer ' + nombre + '.json');
        return r.json();
      });
    }
    return cache[nombre];
  }
  const ejercicios = () => cargar('ejercicios');

  // ---------- Favoritos ----------
  const favoritos = {
    lista() { return almacen.leer('favoritos', []); },
    contiene(id) { return this.lista().includes(id); },
    alternar(id) {
      const l = this.lista();
      const i = l.indexOf(id);
      if (i >= 0) l.splice(i, 1); else l.push(id);
      almacen.guardar('favoritos', l);
      document.dispatchEvent(new CustomEvent('favoritos'));
      return i < 0;
    }
  };

  // ---------- Tema claro / oscuro ----------
  function aplicarTema() {
    const t = almacen.leer('tema', 'auto');
    if (t === 'auto') document.documentElement.removeAttribute('data-tema');
    else document.documentElement.setAttribute('data-tema', t);
    const b = $('.boton-tema');
    if (b) {
      b.textContent = t === 'oscuro' ? '🌙' : t === 'claro' ? '☀️' : '🌓';
      b.title = 'Apariencia: ' + (t === 'oscuro' ? 'oscura' : t === 'claro' ? 'clara' : 'automática');
    }
  }
  aplicarTema();

  // ---------- Mapa muscular ----------
  let toque = null;
  cargar('mapa_toque').then(d => { toque = d; }).catch(() => {});

  function musculoEn(x, y) {
    if (!toque) return null;
    const col = Math.floor(x * toque.ancho), fila = Math.floor(y * toque.alto);
    const celda = (c, f) => {
      if (f < 0 || f >= toque.filas.length) return null;
      const texto = toque.filas[f];
      if (c < 0 || c >= texto.length) return null;
      const ch = texto[c];
      if (ch === '.') return null;
      const i = ch.charCodeAt(0) - 97;
      return i >= 0 && i < toque.musculos.length ? toque.musculos[i] : null;
    };
    for (let radio = 0; radio <= 3; radio++)
      for (let dy = -radio; dy <= radio; dy++)
        for (let dx = -radio; dx <= radio; dx++) {
          const m = celda(col + dx, fila + dy);
          if (m) return m;
        }
    return null;
  }

  /** Dibujo del cuerpo con los músculos coloreados. opciones: principales, secundarios, marcados, alTocar, lineas */
  function mapa(opciones = {}) {
    const principales = new Set(opciones.principales || []);
    const secundarios = new Set(opciones.secundarios || []);
    const marcados = new Set(opciones.marcados || []);
    const d = document.createElement('div');
    d.className = 'mapa';
    const capa = (nombre, clase) => {
      const c = document.createElement('div');
      c.className = 'capa ' + clase;
      const u = `url("img/m_${nombre}.png")`;
      c.style.webkitMaskImage = u; c.style.maskImage = u;
      d.appendChild(c);
    };
    capa('cuerpo', 'cuerpo');
    for (const m of MUSCULOS) {
      if (marcados.has(m.id)) capa(m.id, 'marcado');
      else if (principales.has(m.id)) capa(m.id, 'principal');
      else if (secundarios.has(m.id)) capa(m.id, 'secundario');
    }
    if (opciones.lineas !== false) capa('lineas', 'lineas');
    const nombres = [...principales].map(m => NOMBRE_MUSCULO[m]).join(', ');
    d.setAttribute('role', opciones.alTocar ? 'button' : 'img');
    d.setAttribute('aria-label', opciones.alTocar ? 'Dibujo del cuerpo: toca un músculo' : (nombres ? 'Músculos: ' + nombres : 'Dibujo del cuerpo'));
    if (opciones.alTocar) {
      d.classList.add('tocable');
      d.addEventListener('click', ev => {
        const r = d.getBoundingClientRect();
        const m = musculoEn((ev.clientX - r.left) / r.width, (ev.clientY - r.top) / r.height);
        if (m) opciones.alTocar(m);
      });
    }
    return d;
  }

  const leyenda = () => html('<div class="leyenda"><span style="--c:var(--rojo)">Principal</span><span style="--c:var(--naranja)">Secundario</span></div>');

  // ---------- Piezas de interfaz ----------
  const nivelNumero = n => ({ avanzado: 3, intermedio: 2 }[normalizar(n)] || 1);
  const indicadorNivel = n => {
    const k = nivelNumero(n);
    return `<span class="nivel" title="Nivel ${esc(n)}" aria-label="Nivel ${esc(n)}">${[1, 2, 3].map(i => `<i class="${i <= k ? 'on' : ''}"></i>`).join('')}</span>`;
  };
  const etiquetaLugar = l => `<span class="lugar ${l}">${LUGARES[l].emoji} ${LUGARES[l].nombre}</span>`;
  const nombresMusculos = lista => lista.map(m => NOMBRE_MUSCULO[m] || m);

  function botonFavorito(e) {
    const b = html('<button class="fav" type="button"></button>');
    const pintar = () => {
      const on = favoritos.contiene(e.id);
      b.setAttribute('aria-pressed', on);
      b.textContent = on ? '♥' : '♡';
      b.setAttribute('aria-label', on ? 'Quitar de favoritos' : 'Añadir a favoritos');
    };
    pintar();
    b.addEventListener('click', ev => { ev.stopPropagation(); favoritos.alternar(e.id); });
    document.addEventListener('favoritos', pintar);
    return b;
  }

  function tarjetaEjercicio(e) {
    const t = html(`<article class="ejercicio tarjeta" tabindex="0" role="link" aria-label="${esc(e.nombre)}">
      <div class="dibujo">${etiquetaLugar(e.lugar)}</div>
      <div class="info">
        <div class="nombre">${esc(e.nombre)}</div>
        <div class="musc">${esc(nombresMusculos(e.principales).join(' · '))}</div>
        <div class="pie-t">${indicadorNivel(e.nivel)}<span class="series">${esc(e.series)}</span></div>
      </div></article>`);
    $('.dibujo', t).appendChild(mapa({ principales: e.principales, secundarios: e.secundarios }));
    t.appendChild(botonFavorito(e));
    const abrir = () => abrirFicha(e);
    t.addEventListener('click', abrir);
    t.addEventListener('keydown', ev => { if (ev.key === 'Enter' || ev.key === ' ') { ev.preventDefault(); abrir(); } });
    return t;
  }

  function filaEjercicio(e, detalle) {
    const b = html(`<button type="button" class="fila-ej"><span class="ico ${e.lugar}">${LUGARES[e.lugar].emoji}</span>
      <span><b>${esc(e.nombre)}</b><small>${esc(detalle || nombresMusculos(e.principales).join(', '))}</small></span></button>`);
    b.addEventListener('click', () => abrirFicha(e));
    return b;
  }

  // ---------- Ficha del ejercicio ----------
  let dialogo = null;
  function parecidos(lista, e, maximo = 4) {
    const m = e.principales[0];
    if (!m) return [];
    return lista.filter(x => x.id !== e.id && x.principales.includes(m))
      .sort((a, b) => ((a.lugar === e.lugar ? 0 : 1) - (b.lugar === e.lugar ? 0 : 1)) || a.nombre.localeCompare(b.nombre, 'es'))
      .slice(0, maximo);
  }

  async function abrirFicha(e) {
    const lista = await ejercicios();
    if (!dialogo) {
      dialogo = html(`<dialog class="ficha" aria-labelledby="ficha-titulo">
        <div class="ficha-cab"><h2 id="ficha-titulo"></h2><button class="cerrar" type="button" aria-label="Cerrar" autofocus>✕</button></div>
        <div class="ficha-cuerpo"></div></dialog>`);
      document.body.appendChild(dialogo);
      $('.cerrar', dialogo).addEventListener('click', () => dialogo.close());
      dialogo.addEventListener('click', ev => { if (ev.target === dialogo) dialogo.close(); });
      dialogo.addEventListener('close', () => {
        $('.ficha-cuerpo', dialogo).innerHTML = '';
        if (location.hash) history.replaceState(null, '', location.pathname + location.search);
      });
    }
    $('#ficha-titulo', dialogo).textContent = e.nombre;
    const cuerpo = $('.ficha-cuerpo', dialogo);
    cuerpo.innerHTML = `
      <div class="fila">${etiquetaLugar(e.lugar)}<span class="etiqueta">${indicadorNivel(e.nivel)} ${esc(e.nivel)}</span>
        <span class="etiqueta" style="--c:var(--coral)">🔁 ${esc(e.series)}</span></div>
      <div class="ficha-dibujos">
        <div class="marco fig"></div>
        <div class="marco map"></div>
      </div>
      <div class="rejilla-2">
        <div><h3>Músculos</h3>
          <p><b style="color:var(--rojo)">Principales:</b> ${esc(nombresMusculos(e.principales).join(', '))}</p>
          ${e.secundarios.length ? `<p><b style="color:var(--naranja)">Secundarios:</b> ${esc(nombresMusculos(e.secundarios).join(', '))}</p>` : ''}
        </div>
        <div class="consejo"><b>💡 Consejo</b><br>${esc(e.consejo)}</div>
      </div>
      <div><h3>Cómo se hace</h3><ol class="pasos">${e.pasos.map(p => `<li>${esc(p)}</li>`).join('')}</ol></div>
      <div class="par"></div>`;
    const fig = Figura.crear(e);
    if (fig) $('.fig', cuerpo).appendChild(fig); else $('.fig', cuerpo).remove();
    $('.map', cuerpo).appendChild(mapa({ principales: e.principales, secundarios: e.secundarios }));
    $('.map', cuerpo).appendChild(leyenda());
    const par = parecidos(lista, e);
    if (par.length) {
      const caja = $('.par', cuerpo);
      caja.innerHTML = '<h3>Ejercicios parecidos</h3>';
      const l = html('<div class="lista"></div>');
      par.forEach(x => l.appendChild(filaEjercicio(x, LUGARES[x.lugar].nombre + ' · ' + x.series)));
      caja.appendChild(l);
    }
    const favCab = botonFavorito(e);
    favCab.style.position = 'static';
    const cab = $('.ficha-cab', dialogo);
    const viejo = $('.fav', cab); if (viejo) viejo.remove();
    cab.insertBefore(favCab, $('.cerrar', cab));
    if (!dialogo.open) dialogo.showModal();
    dialogo.scrollTop = 0;
    if (location.pathname.endsWith('ejercicios.html')) history.replaceState(null, '', '#' + e.id);
  }

  // ---------- Ejercicio del día (igual que la app: cambia cada día) ----------
  function ejercicioDelDia(lista) {
    if (!lista.length) return null;
    // Días desde el 1-1-0001 (como Calendar.ordinality(of: .day, in: .era))
    const hoy = new Date();
    const utc = Date.UTC(hoy.getFullYear(), hoy.getMonth(), hoy.getDate());
    const dia = Math.floor(utc / 86400000) + 719163;
    return lista[dia % lista.length];
  }

  // ---------- Cabecera ----------
  document.addEventListener('DOMContentLoaded', () => {
    aplicarTema();
    const bt = $('.boton-tema');
    if (bt) bt.addEventListener('click', () => {
      const orden = ['auto', 'claro', 'oscuro'];
      const t = almacen.leer('tema', 'auto');
      almacen.guardar('tema', orden[(orden.indexOf(t) + 1) % 3]);
      aplicarTema();
    });
    const bm = $('.boton-menu'), menu = $('.menu');
    if (bm && menu) bm.addEventListener('click', () => {
      const ab = menu.classList.toggle('abierto');
      bm.setAttribute('aria-expanded', ab);
    });
    const anio = $('#anio'); if (anio) anio.textContent = new Date().getFullYear();
  });

  // ---------- App instalable (Android, Windows…) y uso sin conexión ----------
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => navigator.serviceWorker.register('sw.js').catch(() => {}));
  }
  let avisoInstalar = null;
  window.addEventListener('beforeinstallprompt', ev => {
    ev.preventDefault();
    avisoInstalar = ev;
    const tema = $('.boton-tema');
    if (!tema || $('.boton-instalar')) return;
    const b = html('<button class="boton-instalar" type="button" title="Instalar GymApp en este dispositivo">⬇︎ Instalar app</button>');
    b.addEventListener('click', async () => {
      if (!avisoInstalar) return;
      avisoInstalar.prompt();
      await avisoInstalar.userChoice.catch(() => {});
      avisoInstalar = null;
      b.remove();
    });
    tema.before(b);
  });
  window.addEventListener('appinstalled', () => { avisoInstalar = null; const b = $('.boton-instalar'); if (b) b.remove(); });

  window.GA = {
    MUSCULOS, NOMBRE_MUSCULO, ZONAS, LUGARES, esc, normalizar, $, $$, html, numero, almacen, cargar, ejercicios,
    favoritos, mapa, leyenda, musculoEn, indicadorNivel, etiquetaLugar, nombresMusculos, tarjetaEjercicio,
    filaEjercicio, abrirFicha, ejercicioDelDia, parecidos, nivelNumero
  };
})();
