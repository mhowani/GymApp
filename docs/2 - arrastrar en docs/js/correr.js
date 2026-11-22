/* Correr: misma lógica que CorrerModelos.swift (reglas al final de correr.json) */
(async function () {
  'use strict';
  const { $, $$, html, esc, numero, almacen, LUGARES } = GA;
  const [datos, ejercicios] = await Promise.all([GA.cargar('correr'), GA.ejercicios()]);
  const COLOR = {
    celeste: 'var(--celeste)', azul: 'var(--azul)', azulOscuro: 'var(--azul-oscuro)', coral: 'var(--coral)',
    coralClaro: 'var(--coral-claro)', rojo: 'var(--rojo)', morado: '#8E5CD9', gris: '#9AA3AF'
  };
  const color = c => COLOR[c] || 'var(--acento)';
  const NOMBRES = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  // ---------- Formatos ----------
  const fKm = v => numero(v, 1) + ' km';
  const minSeg = s => { if (!isFinite(s) || s <= 0) return '–'; const t = Math.round(s); return Math.floor(t / 60) + ':' + String(t % 60).padStart(2, '0'); };
  const fRitmo = s => minSeg(s) + ' /km';
  const fTiempo = s => {
    if (!isFinite(s) || s <= 0) return '–';
    const t = Math.round(s), h = Math.floor(t / 3600), m = Math.floor((t % 3600) / 60), x = t % 60;
    return h > 0 ? `${h}:${String(m).padStart(2, '0')}:${String(x).padStart(2, '0')}` : `${m}:${String(x).padStart(2, '0')}`;
  };
  const fDuracion = m => (m <= 0 ? '' : m < 60 ? m + ' min' : (m % 60 ? `${Math.floor(m / 60)} h ${m % 60} min` : `${Math.floor(m / 60)} h`));
  const fFecha = (d, op = { weekday: 'long', day: 'numeric', month: 'long' }) => d.toLocaleDateString('es-ES', op);

  // ---------- Utilidades del generador ----------
  const redondear = x => Math.floor(x + 0.5);
  const redondearKm = (x, paso) => (paso > 0 ? redondear(x / paso) * paso : x);
  function interpolar(tabla, x) {
    const p = tabla.filter(t => t.length >= 2).slice().sort((a, b) => a[0] - b[0]);
    if (!p.length) return 0;
    if (x <= p[0][0]) return p[0][1];
    if (x >= p[p.length - 1][0]) return p[p.length - 1][1];
    for (let i = 1; i < p.length; i++) if (x <= p[i][0]) {
      const a = p[i - 1], b = p[i], t = (x - a[0]) / (b[0] - a[0]);
      return a[1] + (b[1] - a[1]) * t;
    }
    return p[p.length - 1][1];
  }
  const semanasMinimas = (n, km) => Math.ceil(interpolar(n.semanasMinimas, km));
  const semanasRecomendadas = (n, km) => Math.ceil(interpolar(n.semanasRecomendadas, km));
  const sumarDias = (d, n) => { const r = new Date(d); r.setDate(r.getDate() + n); return r; };
  const lunes = d => { const r = new Date(d.getFullYear(), d.getMonth(), d.getDate()); return sumarDias(r, -((r.getDay() + 6) % 7)); };
  const inicioPorDefecto = () => { const hoy = new Date(); const i = (hoy.getDay() + 6) % 7; const l = lunes(hoy); return i <= 2 ? l : sumarDias(l, 7); };
  const zona = id => datos.zonas.find(z => z.id === id);
  const nombreDistancia = km => { const d = datos.distancias.find(x => Math.abs(x.km - km) < 0.05); return d ? d.nombre : fKm(km); };
  function ajustarDistancia(km) {
    for (const d of datos.distancias) if (Math.abs(d.km - km) <= datos.deslizador.imanKm) return d.km;
    const paso = datos.deslizador.paso > 0 ? datos.deslizador.paso : 0.5;
    return Math.min(Math.max(Math.round(km / paso) * paso, datos.deslizador.min), datos.deslizador.max);
  }

  // ---------- Calculadora de ritmo (Riegel) ----------
  const prediccion = (ref, km) => (ref.km > 0 && km > 0 ? ref.segundos * Math.pow(km / ref.km, datos.riegel) : 0);
  const ritmo = (seg, km) => (km > 0 ? seg / km : 0);
  function rango(z, ref, objetivoKm) {
    const km = z.referenciaKm > 0 ? z.referenciaKm : objetivoKm;
    const base = ritmo(prediccion(ref, km), km);
    return { rapido: base * z.factorMin, lento: base * z.factorMax };
  }
  const ritmoMedio = (z, ref, km) => { const r = rango(z, ref, km); return (r.rapido + r.lento) / 2; };

  // ---------- Generador de planes ----------
  function generar(op) {
    const nivel = op.nivel, pr = datos.progresion, km = op.distanciaKm, n = Math.max(op.semanas, 1);
    const dias = Math.min(Math.max(op.dias, nivel.diasMin), nivel.diasMax);
    const clave = String(dias);
    let ritmoSuave = nivel.ritmoSuavePorDefecto, ritmoLarga = nivel.ritmoSuavePorDefecto;
    if (op.referencia) {
      if (zona('suave')) ritmoSuave = ritmoMedio(zona('suave'), op.referencia, km);
      if (zona('larga')) ritmoLarga = ritmoMedio(zona('larga'), op.referencia, km);
    }
    const minutos = (k, r) => redondear(k * r / 60);

    // 1. Fases
    const tramo = datos.afinado.filter(t => km >= t.desdeKm).pop() || { desdeKm: 0, semanas: 1, factores: [0.5] };
    const semanasAfinado = Math.min(tramo.semanas, Math.max(1, Math.floor(n / 4)), n);
    const m = n - semanasAfinado;
    const base = m > 0 ? Math.max(1, redondear(m * datos.repartoFases.base)) : 0;
    let desarrollo = redondear(m * datos.repartoFases.desarrollo);
    if (m - base - desarrollo < 0) desarrollo = Math.max(0, m - base);
    const faseDe = w => {
      if (w === n - 1) return ['carrera', n - 1];
      if (w >= m) return ['afinado', m];
      if (w < base) return ['base', 0];
      if (w < base + desarrollo) return ['desarrollo', base];
      return ['especifica', base + desarrollo];
    };

    // 2. Km de cada semana
    const kmPico = interpolar(nivel.kmPico, km) * (datos.factorDias[clave] || 1);
    const kmInicio = kmPico * nivel.fraccionInicio;
    const volumen = new Array(n).fill(0), descarga = new Array(n).fill(false);
    let alcanzado = kmInicio;
    for (let w = 0; w < m; w++) {
      const objetivo = m > 1 ? kmInicio + (kmPico - kmInicio) * w / (m - 1) : kmInicio;
      const sem = w === 0 ? kmInicio : Math.min(objetivo, alcanzado * (1 + pr.subidaMaximaSemanal));
      alcanzado = sem;
      const esDescarga = pr.descargaCada > 0 && (w + 1) % pr.descargaCada === 0 && w < m - 1;
      descarga[w] = esDescarga;
      volumen[w] = esDescarga ? sem * pr.factorDescarga : sem;
    }
    const factores = tramo.factores.slice(-semanasAfinado);
    for (let k = 0; k < semanasAfinado; k++) volumen[m + k] = alcanzado * (k < factores.length ? factores[k] : 0.5);

    // 3. Tirada larga máxima
    const tiradaTabla = interpolar(nivel.tiradaMaxima, km);
    const tiradaPorTiempo = ritmoLarga > 0 ? pr.tiradaMaximaMinutos * 60 / ritmoLarga : tiradaTabla;
    const porcentaje = datos.porcentajeTirada[clave] || 0.4;

    // 4. Correr y caminar
    const pasos = datos.correrCaminar;
    const semanasCC = nivel.correrCaminar ? Math.min(pasos.length, m) : 0;
    const plantilla = datos.plantillas[clave] || [];
    const semanas = [];

    for (let w = 0; w < n; w++) {
      const [faseId, faseInicio] = faseDe(w);
      const fase = datos.fases.find(f => f.id === faseId) || { id: 'base', nombre: 'Base', color: 'celeste', descripcion: '' };
      const final = w === n - 1;
      const inicioSemana = sumarDias(op.inicio, 7 * w);
      const numeroEnFase = w - faseInicio;
      let paso = null;
      if (w < semanasCC && pasos.length) {
        const i = semanasCC === 1 ? pasos.length - 1 : redondear(w * (pasos.length - 1) / (semanasCC - 1));
        paso = pasos[Math.min(Math.max(i, 0), pasos.length - 1)];
      }

      // Primera pasada
      const huecos = [];
      let kmCalidad = 0, kmLarga = 0, rodajes = 0;
      plantilla.slice(0, 7).forEach(dia => {
        const lista = [];
        for (const texto of dia) {
          const opcional = texto.endsWith('?');
          const c = opcional ? texto.slice(0, -1) : texto;
          if (c === 'fuerzaA' || c === 'fuerzaB') lista.push(final ? [{ t: 'descanso' }, false] : [{ t: 'fuerza', clave: c }, opcional]);
          else if (c === 'larga') {
            if (final) lista.push([{ t: 'carrera' }, false]);
            else if (paso) lista.push([{ t: 'cc', larga: true }, opcional]);
            else {
              const porVolumen = tiradaTabla * volumen[w] / Math.max(kmPico, 1);
              const porSemana = volumen[w] * porcentaje;
              const tirada = Math.min(Math.min(porVolumen, porSemana), tiradaPorTiempo);
              const valor = redondearKm(Math.max(tirada, nivel.kmMinimoRodaje), pr.redondeoKm);
              kmLarga += valor;
              lista.push([{ t: 'larga', km: valor }, opcional]);
            }
          } else if (c === 'calidad1' || c === 'calidad2' || c === 'suave') {
            if (paso) { lista.push([{ t: 'cc', larga: false }, opcional]); continue; }
            let elegida = null;
            const puede2 = c === 'calidad2' && !final && dias >= nivel.segundaCalidadDesdeDias;
            if (c === 'calidad1' || puede2) {
              const cand = datos.sesionesCalidad.filter(s => (s.hueco === c || s.hueco === 'ambos') && s.fases.includes(faseId)
                && km >= s.distanciaMin && km <= s.distanciaMax && s.niveles[nivel.id]);
              if (cand.length) elegida = cand[numeroEnFase % cand.length];
            }
            if (elegida) {
              const v = elegida.niveles[nivel.id];
              const extra = elegida.conCalentamiento ? nivel.calentamientoKm + nivel.enfriamientoKm : 0;
              const total = redondearKm(v.km + extra, pr.redondeoKm);
              kmCalidad += total;
              lista.push([{ t: 'calidad', s: elegida, km: total }, opcional]);
            } else { rodajes++; lista.push([{ t: 'suave' }, opcional]); }
          } else lista.push([{ t: 'descanso' }, false]);
        }
        huecos.push(lista);
      });
      const resto = volumen[w] - kmLarga - kmCalidad;
      const kmRodaje = rodajes > 0 ? redondearKm(Math.max(nivel.kmMinimoRodaje, resto / rodajes), pr.redondeoKm) : 0;

      // Segunda pasada
      const diasPlan = [];
      for (let i = 0; i < 7; i++) {
        const fecha = sumarDias(inicioSemana, i);
        const lista = i < huecos.length ? huecos[i] : [[{ t: 'descanso' }, false]];
        const sesiones = [];
        lista.forEach(([h, opcional], ordenS) => {
          const id = `${w + 1}-${i}-${ordenS}`;
          const S = (o) => sesiones.push(Object.assign({ id, km: 0, minutos: 0, zona: null, opcional: false, fuerza: null, nota: null }, o));
          switch (h.t) {
            case 'descanso':
              S({ tipo: 'descanso', titulo: 'Descanso', detalle: 'Puedes caminar o estirar suave.', nota: final && i < 6 ? 'Semana de carrera: descansa bien y duerme mucho.' : null });
              break;
            case 'fuerza': {
              const s = datos.fuerza.sesiones.find(x => x.id === h.clave);
              let nota = null;
              if (faseId === 'afinado') nota = 'Semana de afinado: haz la mitad de series.';
              else if (opcional) nota = 'Opcional: hazla solo si te encuentras fresco.';
              S({ tipo: 'fuerza', titulo: s ? s.nombre : 'Fuerza', detalle: s ? s.descripcion : '', minutos: 35, opcional, fuerza: h.clave, nota });
              break;
            }
            case 'suave': {
              let kms = kmRodaje, titulo = 'Rodaje suave', detalle = `${fKm(kms)} a ritmo cómodo; deberías poder hablar.`;
              if (final && i === 5) { kms = Math.min(kmRodaje, 4); titulo = 'Trote de activación'; detalle = `${fKm(kms)} muy suaves para soltar las piernas antes de la carrera.`; }
              else if (i === 0) { titulo = 'Rodaje de recuperación'; detalle = `${fKm(kms)} muy suaves después de la tirada larga.`; }
              S({ tipo: 'suave', titulo, detalle, km: kms, minutos: minutos(kms, ritmoSuave), zona: 'suave', opcional });
              break;
            }
            case 'calidad': {
              const v = h.s.niveles[nivel.id];
              let detalle = v ? v.texto : h.s.nombre;
              if (h.s.conCalentamiento) detalle = `Calienta ${fKm(nivel.calentamientoKm)} suaves · ${detalle} · Termina con ${fKm(nivel.enfriamientoKm)} suaves.`;
              S({ tipo: 'calidad', titulo: h.s.nombre, detalle, km: h.km, minutos: minutos(h.km, ritmoSuave * pr.ritmoCalidad), zona: h.s.zona, opcional });
              break;
            }
            case 'larga': {
              let detalle = `${fKm(h.km)} a ritmo cómodo y constante. Bebe agua si pasa de 1 hora.`;
              if (faseId === 'especifica' && km > 15 && !nivel.correrCaminar && numeroEnFase % 2 === 1) {
                const fr = Math.min(redondear(km * 0.25), 8);
                detalle = `${fKm(h.km)} a ritmo cómodo; los últimos ${fKm(fr)} a ritmo de carrera.`;
              }
              S({ tipo: 'larga', titulo: 'Tirada larga', detalle, km: h.km, minutos: minutos(h.km, ritmoLarga), zona: 'larga', opcional });
              break;
            }
            case 'carrera':
              S({ tipo: 'carrera', titulo: '¡Carrera! ' + nombreDistancia(km), detalle: 'Calienta 10 min, sal algo más lento los primeros km y acelera solo si vas bien. ¡A disfrutar!', km, zona: 'carrera' });
              break;
            case 'cc': {
              if (!paso) break;
              let veces = paso.veces, correr = paso.correr;
              if (h.larga) {
                if (paso.caminar > 0) veces = Math.ceil(paso.veces * pr.factorLargaCorrerCaminar);
                else correr = Math.ceil(paso.correr * pr.factorLargaCorrerCaminar / 5) * 5;
              }
              const total = veces * (correr + paso.caminar);
              const detalle = paso.caminar > 0
                ? `${veces} × (${numero(correr, 1)} min corriendo suave + ${numero(paso.caminar, 1)} min caminando). Empieza y termina con 5 min caminando.`
                : `${numero(correr)} min corriendo suave sin parar. Empieza y termina con 5 min caminando.`;
              const r = ritmoSuave * pr.ritmoCorrerCaminar;
              const kms = r > 0 ? redondearKm(total * 60 / r, pr.redondeoKm) : 0;
              S({ tipo: 'correrCaminar', titulo: h.larga ? 'Salida larga: correr y caminar' : 'Correr y caminar', detalle, km: kms, minutos: redondear(total), zona: 'suave', opcional });
              break;
            }
          }
        });
        diasPlan.push({ id: i, fecha, sesiones });
      }
      const kmSem = diasPlan.reduce((a, d) => a + d.sesiones.reduce((b, s) => b + s.km, 0), 0);
      const minSem = diasPlan.reduce((a, d) => a + d.sesiones.filter(s => s.tipo !== 'fuerza' && s.tipo !== 'descanso').reduce((b, s) => b + s.minutos, 0), 0);
      semanas.push({ id: w + 1, fase, inicio: inicioSemana, dias: diasPlan, descarga: descarga[w], correrCaminar: !!paso, km: kmSem, minutos: minSem });
    }

    let kmMax = 0, tirada = 0, total = 0;
    for (const s of semanas) {
      total += s.km; kmMax = Math.max(kmMax, s.km);
      for (const d of s.dias) for (const x of d.sesiones) if (x.tipo === 'larga' || x.tipo === 'correrCaminar') tirada = Math.max(tirada, x.km);
    }
    const minimas = semanasMinimas(nivel, km), recomendadas = semanasRecomendadas(nivel, km);
    const avisos = [];
    if (n < minimas) avisos.push(`Con ${n} semanas el plan es muy justo: para ${nombreDistancia(km)} en nivel «${nivel.nombre}» lo prudente son al menos ${minimas} semanas (mejor ${recomendadas}).`);
    if (nivel.correrCaminar && km > 21.2) avisos.push('Desde cero lo prudente es preparar antes un 10 km o una media maratón y dejar la maratón para la temporada siguiente.');
    if (m > 0 && alcanzado < kmPico * 0.9) avisos.push(`Con tan pocas semanas no da tiempo a llegar a los km ideales (unos ${fKm(kmPico)} a la semana): el plan sube como máximo un ${numero(pr.subidaMaximaSemanal * 100)} % por semana.`);
    if (nivel.correrCaminar && semanasCC === m && m < pasos.length) avisos.push('Con estas semanas no se completan todos los pasos de correr y caminar: si el día de la carrera necesitas caminar un poco, hazlo sin problema.');
    return { semanas, kmMax, tirada, total, minimas, recomendadas, avisos, fechaCarrera: sumarDias(op.inicio, 7 * n - 1), dias };
  }

  // ---------- Estado ----------
  const E = {
    distancia: almacen.leer('correr.distancia', 10),
    nivel: almacen.leer('correr.nivel', 'intermedio'),
    dias: almacen.leer('correr.dias', 4),
    semanas: almacen.leer('correr.semanas', 10),
    inicio: almacen.leer('correr.inicio', ''),
    refKm: almacen.leer('correr.refKm', 5),
    refSegundos: almacen.leer('correr.refSegundos', 0),
    hechos: almacen.leer('correr.hechos', []),
    lugarFuerza: almacen.leer('correr.lugarFuerza', almacen.leer('plan.lugar', 'pesas')),
    semana: null,
    parte: 'calentamiento'
  };
  const guardar = (...k) => k.forEach(x => almacen.guardar('correr.' + x, E[x]));
  const nivelActual = () => datos.niveles.find(n => n.id === E.nivel) || datos.niveles[0];
  const fechaInicio = () => {
    if (E.inicio) { const [y, m, d] = E.inicio.split('-').map(Number); if (y) return lunes(new Date(y, m - 1, d)); }
    return inicioPorDefecto();
  };
  const isoLocal = d => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

  // ---------- Controles ----------
  $('#aviso').textContent = datos.aviso;
  const caDist = $('#distancias');
  datos.distancias.forEach(d => {
    const b = html(`<button class="chip" type="button">${esc(d.nombre)}</button>`); b.dataset.km = d.km;
    b.addEventListener('click', () => { E.distancia = d.km; guardar('distancia'); pintar(); });
    caDist.appendChild(b);
  });
  const barra = $('#barra-distancia');
  Object.assign(barra, { min: datos.deslizador.min, max: datos.deslizador.max, step: 0.1 });
  barra.addEventListener('input', () => { E.distancia = ajustarDistancia(+barra.value); guardar('distancia'); pintar(true); });
  barra.addEventListener('change', () => { barra.value = E.distancia; });
  const caNiv = $('#niveles');
  datos.niveles.forEach(n => {
    const b = html(`<button class="nivel-op" type="button"><b>${esc(n.nombre)}</b><small>${esc(n.descripcion)}</small></button>`); b.dataset.v = n.id;
    b.addEventListener('click', () => { E.nivel = n.id; E.dias = n.diasPorDefecto; guardar('nivel', 'dias'); pintar(); });
    caNiv.appendChild(b);
  });
  $('#dias-menos').addEventListener('click', () => { const n = nivelActual(); E.dias = Math.max(n.diasMin, Math.min(E.dias, n.diasMax) - 1); guardar('dias'); pintar(); });
  $('#dias-mas').addEventListener('click', () => { const n = nivelActual(); E.dias = Math.min(n.diasMax, Math.max(E.dias, n.diasMin) + 1); guardar('dias'); pintar(); });
  $('#sem-menos').addEventListener('click', () => { E.semanas = Math.max(datos.semanas.min, E.semanas - 1); guardar('semanas'); pintar(); });
  $('#sem-mas').addEventListener('click', () => { E.semanas = Math.min(datos.semanas.max, E.semanas + 1); guardar('semanas'); pintar(); });
  $('#sem-recomendadas').addEventListener('click', () => { E.semanas = semanasRecomendadas(nivelActual(), E.distancia); guardar('semanas'); pintar(); });
  const inpInicio = $('#inicio');
  inpInicio.addEventListener('change', () => { E.inicio = inpInicio.value; guardar('inicio'); pintar(); });
  $('#inicio-hoy').addEventListener('click', () => { E.inicio = ''; guardar('inicio'); pintar(); });

  // Calculadora
  const selRef = $('#ref-km');
  datos.distancias.forEach(d => selRef.appendChild(new Option(d.nombre, d.km)));
  [3, 15, 30].forEach(k => selRef.appendChild(new Option(k + ' km', k)));
  selRef.value = String(E.refKm);
  if (E.refSegundos > 0) {
    $('#ref-h').value = Math.floor(E.refSegundos / 3600);
    $('#ref-m').value = Math.floor((E.refSegundos % 3600) / 60);
    $('#ref-s').value = Math.round(E.refSegundos % 60);
  }
  $('#form-ritmo').addEventListener('submit', ev => {
    ev.preventDefault();
    const seg = (+$('#ref-h').value || 0) * 3600 + (+$('#ref-m').value || 0) * 60 + (+$('#ref-s').value || 0);
    E.refKm = +selRef.value; E.refSegundos = seg; guardar('refKm', 'refSegundos'); pintar();
  });
  $('#borrar-ritmo').addEventListener('click', () => {
    E.refSegundos = 0; guardar('refSegundos'); ['#ref-h', '#ref-m', '#ref-s'].forEach(s => { $(s).value = ''; }); pintar();
  });

  const segPartes = $('#partes');
  [['calentamiento', 'Calentamiento'], ['estiramientosAntes', 'Antes de correr'], ['estiramientosDespues', 'Después de correr']].forEach(([v, n]) => {
    const b = html(`<button type="button">${n}</button>`); b.dataset.v = v;
    b.addEventListener('click', () => { E.parte = v; pintarPartes(); });
    segPartes.appendChild(b);
  });
  function pintarPartes() {
    $$('button', segPartes).forEach(b => b.setAttribute('aria-pressed', b.dataset.v === E.parte));
    $('#lista-partes').innerHTML = datos[E.parte].map(p => `<li><div><b>${esc(p.nombre)}</b><br><small class="texto-2">${esc(p.detalle)}</small></div></li>`).join('');
  }
  pintarPartes();
  $('#consejos').innerHTML = datos.consejos.map(c => `<li>${esc(c)}</li>`).join('');

  const segLugar = $('#lugar-fuerza');
  Object.entries(LUGARES).forEach(([k, l]) => {
    const b = html(`<button type="button">${l.emoji} ${esc(l.nombre)}</button>`); b.dataset.v = k;
    b.addEventListener('click', () => { E.lugarFuerza = k; guardar('lugarFuerza'); pintarFuerza(); });
    segLugar.appendChild(b);
  });
  function pintarFuerza() {
    $$('button', segLugar).forEach(b => b.setAttribute('aria-pressed', b.dataset.v === E.lugarFuerza));
    $('#fuerza-desc').textContent = datos.fuerza.descripcion;
    $('#fuerza-reglas').innerHTML = datos.fuerza.reglas.map(r => `<li>${esc(r)}</li>`).join('');
    const caja = $('#fuerza'); caja.innerHTML = '';
    datos.fuerza.sesiones.forEach(s => {
      const t = html(`<section class="tarjeta caja"><h3>${esc(s.nombre)}</h3><p class="texto-2 pequeno">${esc(s.descripcion)}</p><div class="lista"></div></section>`);
      s.ejercicios.forEach(x => {
        const e = ejercicios.find(y => y.id === x[E.lugarFuerza]);
        if (e) $('.lista', t).appendChild(GA.filaEjercicio(e, x.series + (x.nota ? ' · ' + x.nota : '')));
      });
      caja.appendChild(t);
    });
  }
  pintarFuerza();

  // ---------- Pintar ----------
  function pintarRitmos(km) {
    const caja = $('#ritmos');
    const ref = E.refSegundos > 0 ? { km: E.refKm, segundos: E.refSegundos } : null;
    if (!ref) {
      caja.innerHTML = `<p class="texto-2">Añade un tiempo reciente (por ejemplo, lo que tardas en 5 km) y verás a qué ritmo hacer cada entreno. Mientras tanto, guíate por las sensaciones:</p>
        <table class="zonas"><tbody>${datos.zonas.map(z => `<tr><td><span class="punto" style="--c:${color(z.color)}"></span><b>${esc(z.nombre)}</b></td><td class="texto-2">${esc(z.sensacion)}</td></tr>`).join('')}</tbody></table>`;
      return;
    }
    const est = prediccion(ref, km);
    caja.innerHTML = `<p>Con <b>${fKm(ref.km)}</b> en <b>${fTiempo(ref.segundos)}</b> · ${fRitmo(ritmo(ref.segundos, ref.km))} · ${numero(ref.km / (ref.segundos / 3600), 1)} km/h</p>
      <div class="cifras" style="margin-bottom:12px">${datos.distancias.map(d => `<div class="cifra"><small>${esc(d.nombre)}</small><b>${fTiempo(prediccion(ref, d.km))}</b><small>${fRitmo(ritmo(prediccion(ref, d.km), d.km))}</small></div>`).join('')}</div>
      <p class="pequeno"><b>Tiempo estimado en ${esc(nombreDistancia(km))}: ${fTiempo(est)}</b> (${fRitmo(ritmo(est, km))})</p>
      <table class="zonas"><tbody>${datos.zonas.map(z => { const r = rango(z, ref, km); return `<tr><td><span class="punto" style="--c:${color(z.color)}"></span><b>${esc(z.nombre)}</b><br><small class="texto-2">${esc(z.sensacion)}</small></td><td>${minSeg(r.rapido)}–${fRitmo(r.lento)}</td></tr>`; }).join('')}</tbody></table>
      <p class="texto-2 pequeno">Estimación con la fórmula de Riegel: es fiable si entrenas para esa distancia. Con calor, cuestas o viento, ve más lento.</p>`;
  }

  function pintarSemana(plan) {
    const total = plan.semanas.length;
    const s = plan.semanas[Math.min(E.semana, total) - 1];
    const caja = $('#semana');
    const tipo = id => datos.tipos.find(t => t.id === id) || { emoji: '•', color: 'gris' };
    caja.innerHTML = `<div class="fila" style="margin-bottom:6px">
        <button class="boton secundario pequeno" id="ant" type="button" ${s.id === 1 ? 'disabled' : ''}>‹</button>
        <div style="flex:1"><h3 style="margin:0">Semana ${s.id} de ${total} · <span style="color:${color(s.fase.color)}">${esc(s.fase.nombre)}</span>${s.descarga ? ' · descarga' : ''}</h3>
        <small class="texto-2">${fFecha(s.inicio, { day: 'numeric', month: 'short' })} – ${fFecha(sumarDias(s.inicio, 6), { day: 'numeric', month: 'short' })} · ${fKm(s.km)} · ${fDuracion(s.minutos)}</small></div>
        <button class="boton secundario pequeno" id="sig" type="button" ${s.id === total ? 'disabled' : ''}>›</button></div>
      <p class="texto-2 pequeno">${esc(s.fase.descripcion)}</p>`;
    if (s.correrCaminar) caja.appendChild(html('<div class="aviso coral">Si una semana de correr y caminar se te hace dura, repítela antes de pasar a la siguiente.</div>'));
    s.dias.forEach(d => {
      const bloque = html(`<div class="dia-correr"><h4>${NOMBRES[d.id]} · ${fFecha(d.fecha, { day: 'numeric', month: 'short' })}</h4></div>`);
      d.sesiones.forEach(x => {
        const tp = tipo(x.tipo), hecha = E.hechos.includes(x.id);
        const extra = [x.km ? fKm(x.km) : '', x.minutos && x.tipo !== 'fuerza' ? '≈ ' + fDuracion(x.minutos) : '', x.opcional ? 'opcional' : ''].filter(Boolean).join(' · ');
        const el = html(`<div class="sesion ${hecha ? 'hecha' : ''}"><span class="e" style="color:${color(tp.color)}">${tp.emoji}</span>
          <div><b>${esc(x.titulo)}</b><small>${esc(x.detalle)}</small>${extra ? `<br><small><b>${esc(extra)}</b></small>` : ''}${x.nota ? `<br><small>👉 ${esc(x.nota)}</small>` : ''}</div></div>`);
        if (x.tipo !== 'descanso') {
          const c = html(`<input type="checkbox" class="marca-hecho" aria-label="Hecho: ${esc(x.titulo)}" ${hecha ? 'checked' : ''}>`);
          c.addEventListener('change', () => {
            E.hechos = c.checked ? E.hechos.concat(x.id) : E.hechos.filter(h => h !== x.id); guardar('hechos');
            el.classList.toggle('hecha', c.checked);
          });
          el.appendChild(c);
        }
        if (x.fuerza) {
          const b = html('<button class="boton secundario pequeno" type="button" style="margin-top:6px">Ver ejercicios</button>');
          b.addEventListener('click', () => $('#fuerza-titulo').scrollIntoView({ behavior: 'smooth' }));
          el.children[1].appendChild(html('<br>')); el.children[1].appendChild(b);
        }
        bloque.appendChild(el);
      });
      caja.appendChild(bloque);
    });
    $('#ant').onclick = () => { E.semana = s.id - 1; pintarSemana(plan); pintarBarras(plan); };
    $('#sig').onclick = () => { E.semana = s.id + 1; pintarSemana(plan); pintarBarras(plan); };
  }

  function pintarBarras(plan) {
    const max = Math.max(...plan.semanas.map(s => s.km), 1);
    const caja = $('#barras'), nums = $('#barras-num');
    caja.innerHTML = ''; nums.innerHTML = '';
    plan.semanas.forEach(s => {
      const b = html(`<button type="button" style="--c:${color(s.fase.color)};height:${Math.max(4, s.km / max * 100)}%" title="Semana ${s.id}: ${fKm(s.km)} · ${esc(s.fase.nombre)}"></button>`);
      b.setAttribute('aria-pressed', s.id === E.semana);
      b.setAttribute('aria-label', `Semana ${s.id}, ${fKm(s.km)}, ${s.fase.nombre}`);
      b.addEventListener('click', () => { E.semana = s.id; pintarSemana(plan); pintarBarras(plan); });
      caja.appendChild(b);
      nums.appendChild(html(`<span>S${s.id}</span>`));
    });
    $('#leyenda-fases').innerHTML = datos.fases.map(f => `<span style="--c:${color(f.color)}">${esc(f.nombre)}</span>`).join('');
  }

  function pintar(soloBarra) {
    const nivel = nivelActual();
    E.distancia = ajustarDistancia(E.distancia);
    if (!soloBarra) barra.value = E.distancia;
    $('#distancia-texto').textContent = nombreDistancia(E.distancia) === fKm(E.distancia) ? fKm(E.distancia) : `${nombreDistancia(E.distancia)} · ${fKm(E.distancia)}`;
    $$('.chip', caDist).forEach(b => b.setAttribute('aria-pressed', Math.abs(+b.dataset.km - E.distancia) < 0.05));
    $$('.nivel-op', caNiv).forEach(b => b.setAttribute('aria-pressed', b.dataset.v === nivel.id));
    const dias = Math.min(Math.max(E.dias, nivel.diasMin), nivel.diasMax);
    $('#dias-n').textContent = dias;
    $('#dias-rango').textContent = `(${nivel.diasMin} a ${nivel.diasMax})`;
    E.semanas = Math.min(Math.max(E.semanas, datos.semanas.min), datos.semanas.max);
    $('#sem-n').textContent = E.semanas;
    const inicio = fechaInicio();
    inpInicio.value = isoLocal(inicio);
    const ref = E.refSegundos > 0 ? { km: E.refKm, segundos: E.refSegundos } : null;
    const plan = generar({ distanciaKm: E.distancia, nivel, dias, semanas: E.semanas, inicio, referencia: ref });
    $('#recomendacion').textContent = `Para ${nombreDistancia(E.distancia)} en este nivel se recomiendan ${plan.recomendadas} semanas (mínimo ${plan.minimas}).`;
    $('#fechas').innerHTML = `Empieza el <b>${fFecha(inicio)}</b> · Carrera el <b>${fFecha(plan.fechaCarrera, { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })}</b>`;
    $('#resumen').innerHTML = `
      <div class="cifra"><small>Semana más alta</small><b>${fKm(plan.kmMax)}</b></div>
      <div class="cifra"><small>Tirada más larga</small><b>${fKm(plan.tirada)}</b></div>
      <div class="cifra"><small>Km en total</small><b>${numero(plan.total)}</b></div>
      <div class="cifra"><small>Días por semana</small><b>${plan.dias}</b></div>`;
    $('#avisos').innerHTML = plan.avisos.map(a => `<div class="aviso coral">${esc(a)}</div>`).join('');
    if (!E.semana || E.semana > plan.semanas.length) {
      const hoy = new Date();
      const w = Math.floor((lunes(hoy) - inicio) / (7 * 86400000));
      E.semana = w >= 0 && w < plan.semanas.length ? w + 1 : 1;
    }
    pintarBarras(plan);
    pintarSemana(plan);
    pintarRitmos(E.distancia);
  }
  pintar();
})();
