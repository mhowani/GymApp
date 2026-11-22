/* Menús: misma lógica que MenusModelos.swift (calculadora Mifflin-St Jeor, generador de menús y lista de la compra) */
(async function () {
  'use strict';
  const { $, $$, html, esc, numero, almacen } = GA;
  const datos = await GA.cargar('menus');
  const ING = Object.fromEntries(datos.ingredientes.map(i => [i.id, i]));
  const SECCIONES = [...new Set(datos.ingredientes.map(i => i.seccion))];
  const NOMBRES_DIAS = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  const INICIALES = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  const EMOJI_COMIDA = { desayuno: '🌅', media_manana: '☕', comida: '🍽️', merienda: '🥕', cena: '🌙' };
  const EMOJI_OBJETIVO = ['💪', '🔥', '⚖️', '✂️', '🏋️', '🏃', '🎯'];

  // ---------- Estado (se guarda en el navegador) ----------
  const E = {
    sexo: almacen.leer('menus.sexo', 'hombre'),
    edad: almacen.leer('menus.edad', 30),
    peso: almacen.leer('menus.peso', 75),
    altura: almacen.leer('menus.altura', 175),
    actividad: almacen.leer('menus.actividad', 'ligera'),
    dias: almacen.leer('menus.dias', almacen.leer('plan.dias', 3)),
    objetivo: almacen.leer('menus.objetivo', 'mantener'),
    vegetariano: almacen.leer('menus.vegetariano', false),
    sinGluten: almacen.leer('menus.sinGluten', false),
    sinLactosa: almacen.leer('menus.sinLactosa', false),
    semilla: almacen.leer('menus.semilla', 1),
    cambios: almacen.leer('menus.cambios', {}),
    personas: almacen.leer('menus.personas', 1),
    marcados: almacen.leer('menus.marcados', []),
    registro: almacen.leer('menus.registro', []),
    vista: 'menu',
    dia: (new Date().getDay() + 6) % 7
  };
  if (!datos.objetivos.some(o => o.id === E.objetivo)) E.objetivo = datos.objetivos[0].id;
  const guardar = (...claves) => claves.forEach(k => almacen.guardar('menus.' + k, E[k]));

  // ---------- Cálculo ----------
  const sumar = (a, b) => ({ kcal: a.kcal + b.kcal, proteinas: a.proteinas + b.proteinas, hidratos: a.hidratos + b.hidratos, grasas: a.grasas + b.grasas });
  const CERO = { kcal: 0, proteinas: 0, hidratos: 0, grasas: 0 };
  const macrosLinea = l => { const f = l.cantidad / 100, i = l.ing; return { kcal: i.kcal * f, proteinas: i.proteinas * f, hidratos: i.hidratos * f, grasas: i.grasas * f }; };
  const macrosLineas = ls => ls.reduce((a, l) => sumar(a, macrosLinea(l)), CERO);
  const clamp = (x, a, b) => Math.min(Math.max(x, a), b);

  function necesidades() {
    const c = datos.calculo;
    const obj = datos.objetivos.find(o => o.id === E.objetivo);
    const act = datos.actividad.find(a => a.id === E.actividad) || datos.actividad[0];
    const peso = clamp(+E.peso || 0, 35, 250), altura = clamp(+E.altura || 0, 120, 230), edad = clamp(+E.edad || 0, 18, 100);
    const dias = clamp(+E.dias, 0, 7);
    const basal = 10 * peso + 6.25 * altura - 5 * edad + (E.sexo === 'hombre' ? 5 : -161);
    const factor = act.factor + dias * c.factorPorDiaEntreno;
    const mantenimiento = basal * factor;
    const minimo = Math.max(E.sexo === 'hombre' ? c.minimoKcalHombre : c.minimoKcalMujer, basal);
    let kcal = mantenimiento * (1 + obj.ajusteCalorias), ajustado = false;
    if (kcal < minimo) { kcal = minimo; ajustado = true; }
    kcal = Math.round(kcal / 10) * 10;
    let entreno = kcal, descanso = kcal;
    if (dias > 0 && dias < 7) {
      const v = c.variacionDiaEntreno;
      entreno = kcal * (1 + v * (7 - dias) / 7);
      descanso = Math.max(kcal * (1 - v * dias / 7), minimo);
    }
    const proteinas = Math.round(Math.min(peso * obj.proteinaPorKg, kcal * 0.35 / 4));
    const grasas = Math.round(kcal * obj.grasaPorcentaje / 9);
    const hidratos = Math.round(Math.max(0, (kcal - proteinas * 4 - grasas * 9) / 4));
    return {
      basal: Math.round(basal), mantenimiento: Math.round(mantenimiento), kcal,
      kcalEntreno: Math.round(entreno / 10) * 10, kcalDescanso: Math.round(descanso / 10) * 10,
      proteinas, grasas, hidratos, ajustado
    };
  }

  // ---------- Generador de menús ----------
  const M64 = (1n << 64n) - 1n;
  function aleatorio(semilla) {
    let estado = (semilla + 0x9E3779B97F4A7C15n) & M64;
    return function () {
      estado = (estado + 0x9E3779B97F4A7C15n) & M64;
      let z = estado;
      z = ((z ^ (z >> 30n)) * 0xBF58476D1CE4E5B9n) & M64;
      z = ((z ^ (z >> 27n)) * 0x94D049BB133111EBn) & M64;
      return z ^ (z >> 31n);
    };
  }
  function hashTexto(texto) {
    let h = 1469598103934665603n;
    for (const b of new TextEncoder().encode(texto)) h = ((h ^ BigInt(b)) * 1099511628211n) & M64;
    return h;
  }
  function diasDeEntreno(n) {
    if (n <= 0) return new Set();
    return new Set({ 1: [0], 2: [0, 3], 3: [0, 2, 4], 4: [0, 1, 3, 4], 5: [0, 1, 2, 3, 4], 6: [0, 1, 2, 3, 4, 5] }[n] || [0, 1, 2, 3, 4, 5, 6]);
  }
  function lineasPlato(plato) {
    const r = [];
    for (const c of plato.ingredientes) {
      let ing = ING[c.id];
      if (!ing) return null;
      if (E.sinGluten && ing.gluten) { if (!ing.sinGluten || !ING[ing.sinGluten]) return null; ing = ING[ing.sinGluten]; }
      if (E.sinLactosa && ing.lactosa) { if (!ing.sinLactosa || !ING[ing.sinLactosa]) return null; ing = ING[ing.sinLactosa]; }
      if (E.vegetariano && !ing.vegetariano) return null;
      r.push({ ing, cantidad: c.cantidad });
    }
    return r;
  }
  function orden(tipo, objetivo) {
    const cand = [];
    for (const p of datos.platos) if (p.comidas.includes(tipo.id)) { const l = lineasPlato(p); if (l) cand.push({ plato: p, lineas: l }); }
    const rnd = aleatorio((BigInt(E.semilla) & M64) ^ hashTexto(tipo.id + objetivo.id));
    for (let i = cand.length - 1; i > 0; i--) {
      const j = Number(rnd() % BigInt(i + 1));
      [cand[i], cand[j]] = [cand[j], cand[i]];
    }
    const puntos = ls => {
      const m = macrosLineas(ls);
      if (m.kcal <= 0) return 0;
      return objetivo.preferencia === 'proteina' ? m.proteinas * 4 / m.kcal : objetivo.preferencia === 'hidratos' ? m.hidratos * 4 / m.kcal : 0;
    };
    if (!(objetivo.preferencia === 'proteina' || objetivo.preferencia === 'hidratos') || cand.length <= 7) return cand;
    const ordenados = cand.slice().sort((a, b) => puntos(b.lineas) - puntos(a.lineas));
    const corte = Math.max(7, Math.floor(ordenados.length / 2));
    const pref = new Set(ordenados.slice(0, corte).map(c => c.plato.id));
    return cand.filter(c => pref.has(c.plato.id)).concat(cand.filter(c => !pref.has(c.plato.id)));
  }
  function semana(nec) {
    const c = datos.calculo;
    const objetivo = datos.objetivos.find(o => o.id === E.objetivo);
    const entreno = diasDeEntreno(+E.dias);
    const ordenes = Object.fromEntries(datos.comidas.map(t => [t.id, orden(t, objetivo)]));
    return NOMBRES_DIAS.map((nombre, dia) => {
      const esEntreno = entreno.has(dia);
      const objetivoDia = esEntreno ? nec.kcalEntreno : nec.kcalDescanso;
      const usados = new Set();
      const comidas = [];
      for (const tipo of datos.comidas) {
        const lista = ordenes[tipo.id];
        if (!lista.length) continue;
        const desp = E.cambios[dia + '-' + tipo.id] || 0;
        const salto = tipo.id === 'merienda' ? 3 : 0;
        let k = 0, elegido = lista[(dia + desp + salto) % lista.length];
        while (usados.has(elegido.plato.id) && k < lista.length) { k++; elegido = lista[(dia + desp + salto + k) % lista.length]; }
        usados.add(elegido.plato.id);
        const base = macrosLineas(elegido.lineas).kcal;
        let escala = base > 0 ? objetivoDia * tipo.porcentaje / base : 1;
        escala = clamp(Math.round(escala * 10) / 10, c.escalaMinima, c.escalaMaxima);
        const lineas = elegido.lineas.map(l => ({ ing: l.ing, cantidad: l.cantidad * escala }));
        comidas.push({ tipo, plato: elegido.plato, lineas, escala, macros: macrosLineas(lineas) });
      }
      return { dia, nombre, entreno: esEntreno, objetivoKcal: objetivoDia, comidas, macros: comidas.reduce((a, x) => sumar(a, x.macros), CERO) };
    });
  }

  // ---------- Textos de cantidades (Formato.plato / Formato.compra) ----------
  const ceil = Math.ceil;
  function cantPlato(cantidad, ing) {
    const red = cantidad < 20 ? 1 : 5;
    const valor = Math.max(Math.round(cantidad / red) * red, 1);
    const base = numero(valor) + ' ' + ing.unidad;
    if (!(ing.pesoUnidad > 0) || !ing.nombreUnidad) return base;
    const uds = Math.max(Math.round(cantidad / ing.pesoUnidad * 2) / 2, 0.5);
    if (ing.nombreUnidad === 'diente') { const n = Math.max(Math.round(uds), 1); return n === 1 ? '1 diente' : n + ' dientes'; }
    return base + ' (≈ ' + numero(uds, 1) + ' ' + ing.nombreUnidad + ')';
  }
  function pesoCompra(cantidad, unidad) {
    if (cantidad >= 1000) return numero(ceil(cantidad / 100) / 10, 1) + ' ' + (unidad === 'ml' ? 'l' : 'kg');
    const red = cantidad < 100 ? 5 : 10;
    return numero(Math.max(ceil(cantidad / red) * red, red)) + ' ' + unidad;
  }
  function cantCompra(cantidad, ing) {
    if (ing.pesoUnidad > 0 && ing.nombreUnidad) {
      const n = Math.max(ceil(cantidad / ing.pesoUnidad), 1);
      if (ing.nombreUnidad === 'diente') return n === 1 ? '1 diente' : n + ' dientes';
      return n + ' ' + ing.nombreUnidad + ' (≈ ' + pesoCompra(n * ing.pesoUnidad, ing.unidad) + ')';
    }
    return pesoCompra(cantidad, ing.unidad);
  }
  function listaCompra(sem) {
    const total = {};
    for (const d of sem) for (const c of d.comidas) for (const l of c.lineas) {
      total[l.ing.id] = total[l.ing.id] || { ing: l.ing, cantidad: 0 };
      total[l.ing.id].cantidad += l.cantidad * Math.max(E.personas, 1);
    }
    const arts = Object.values(total);
    return SECCIONES.map(s => ({ nombre: s, articulos: arts.filter(a => a.ing.seccion === s).sort((a, b) => a.ing.nombre.localeCompare(b.ing.nombre, 'es')) }))
      .filter(s => s.articulos.length);
  }

  // ---------- Interfaz ----------
  $('#aviso').textContent = datos.aviso;
  const segSexo = $('#sexo');
  [['hombre', 'Hombre'], ['mujer', 'Mujer']].forEach(([v, n]) => {
    const b = html(`<button type="button">${n}</button>`); b.dataset.v = v;
    b.addEventListener('click', () => { E.sexo = v; guardar('sexo'); pintar(); });
    segSexo.appendChild(b);
  });
  const selAct = $('#actividad');
  datos.actividad.forEach(a => selAct.appendChild(new Option(a.nombre + ' · ' + a.descripcion, a.id)));
  const selDias = $('#dias');
  for (let i = 0; i <= 7; i++) selDias.appendChild(new Option(i === 1 ? '1 día' : i + ' días', i));
  [['edad', 'edad'], ['peso', 'peso'], ['altura', 'altura']].forEach(([id, k]) => {
    const inp = $('#' + id); inp.value = E[k];
    inp.addEventListener('change', () => { const v = parseFloat(String(inp.value).replace(',', '.')); if (v > 0) { E[k] = v; guardar(k); pintar(); } });
  });
  selAct.addEventListener('change', () => { E.actividad = selAct.value; guardar('actividad'); pintar(); });
  selDias.addEventListener('change', () => { E.dias = +selDias.value; guardar('dias'); pintar(); });

  const caObj = $('#objetivos');
  datos.objetivos.forEach((o, i) => {
    const b = html(`<button class="chip" type="button" title="${esc(o.descripcion)}">${EMOJI_OBJETIVO[i % EMOJI_OBJETIVO.length]} ${esc(o.nombre)}</button>`);
    b.dataset.v = o.id;
    b.addEventListener('click', () => { E.objetivo = o.id; E.cambios = {}; guardar('objetivo', 'cambios'); pintar(); });
    caObj.appendChild(b);
  });
  const caFil = $('#filtros');
  [['vegetariano', '🥚 Vegetariano'], ['sinGluten', '🌾 Sin gluten'], ['sinLactosa', '🥛 Sin lactosa']].forEach(([k, n]) => {
    const b = html(`<button class="chip" type="button" style="--c:var(--coral)">${n}</button>`); b.dataset.k = k;
    b.addEventListener('click', () => { E[k] = !E[k]; E.cambios = {}; guardar(k, 'cambios'); pintar(); });
    caFil.appendChild(b);
  });
  const segVista = $('#vistas');
  [['menu', '🍽️ Menú'], ['compra', '🛒 Lista de la compra'], ['registro', '📈 Registro']].forEach(([v, n]) => {
    const b = html(`<button type="button">${n}</button>`); b.dataset.v = v;
    b.addEventListener('click', () => { E.vista = v; pintar(); });
    segVista.appendChild(b);
  });
  $('#otra-semana').addEventListener('click', () => { E.semilla = E.semilla + 1; E.cambios = {}; guardar('semilla', 'cambios'); pintar(); });

  function pintarCifras(nec) {
    const obj = datos.objetivos.find(o => o.id === E.objetivo);
    $('#cifras').innerHTML = `
      <div class="cifra"><small>Calorías al día (media)</small><b>${numero(nec.kcal)} kcal</b></div>
      <div class="cifra"><small>Día de entreno</small><b>${numero(nec.kcalEntreno)}</b></div>
      <div class="cifra"><small>Día de descanso</small><b>${numero(nec.kcalDescanso)}</b></div>
      <div class="cifra"><small>Proteínas</small><b>${numero(nec.proteinas)} g</b></div>
      <div class="cifra"><small>Hidratos</small><b>${numero(nec.hidratos)} g</b></div>
      <div class="cifra"><small>Grasas</small><b>${numero(nec.grasas)} g</b></div>`;
    $('#basal').textContent = `Metabolismo basal: ${numero(nec.basal)} kcal · Mantenimiento: ${numero(nec.mantenimiento)} kcal · Fórmula ${datos.calculo.formula}.`;
    $('#minimo').classList.toggle('oculto', !nec.ajustado);
    $('#objetivo-desc').textContent = obj.descripcion;
    $('#consejos').innerHTML = obj.consejos.map(c => `<li>${esc(c)}</li>`).join('');
  }

  function pintarMenu(sem) {
    const caD = $('#dias-semana'); caD.innerHTML = '';
    sem.forEach(d => {
      const b = html(`<button type="button" class="${d.entreno ? 'entreno' : ''}">${INICIALES[d.dia]}<small>${numero(d.macros.kcal)}</small></button>`);
      b.setAttribute('aria-pressed', d.dia === E.dia);
      b.setAttribute('aria-label', d.nombre + (d.entreno ? ', día de entreno' : ''));
      b.addEventListener('click', () => { E.dia = d.dia; pintar(); });
      caD.appendChild(b);
    });
    const d = sem[E.dia];
    $('#dia-titulo').textContent = d.nombre + (d.entreno ? ' · día de entreno' : ' · descanso');
    $('#dia-resumen').textContent = `${numero(d.macros.kcal)} kcal (objetivo ${numero(d.objetivoKcal)}) · P ${numero(d.macros.proteinas)} g · H ${numero(d.macros.hidratos)} g · G ${numero(d.macros.grasas)} g`;
    const caC = $('#comidas'); caC.innerHTML = '';
    if (!d.comidas.length) caC.appendChild(html('<p class="texto-2">No hay platos que cumplan todos los filtros a la vez.</p>'));
    d.comidas.forEach(c => {
      const t = html(`<article class="tarjeta comida">
        <div class="comida-cab"><span class="e">${EMOJI_COMIDA[c.tipo.id] || '🍴'}</span>
          <div><b>${esc(c.tipo.nombre)}</b><br><small>${numero(c.macros.kcal)} kcal · ${numero(c.macros.proteinas)} g proteína · ${c.plato.minutos} min</small></div>
          <button class="boton secundario pequeno" type="button">🔄 Cambiar</button></div>
        <h3 style="margin:4px 0 0">${esc(c.plato.nombre)}</h3>
        <ul>${c.lineas.map(l => `<li>${esc(l.ing.nombre)}: ${esc(cantPlato(l.cantidad, l.ing))}</li>`).join('')}</ul>
        <p class="pequeno" style="margin:0">${esc(c.plato.preparacion)}</p></article>`);
      $('button', t).addEventListener('click', () => {
        const k = d.dia + '-' + c.tipo.id;
        E.cambios[k] = (E.cambios[k] || 0) + 1; guardar('cambios'); pintar();
      });
      caC.appendChild(t);
    });
  }

  function pintarCompra(sem) {
    $('#personas').textContent = E.personas;
    const secs = listaCompra(sem);
    const caja = $('#compra'); caja.innerHTML = '';
    secs.forEach(s => {
      const sec = html(`<div class="compra-sec"><h3>${esc(s.nombre)}</h3></div>`);
      s.articulos.forEach(a => {
        const marcado = E.marcados.includes(a.ing.id);
        const fila = html(`<label class="compra-item ${marcado ? 'hecho' : ''}"><input type="checkbox" ${marcado ? 'checked' : ''}>
          <span>${esc(a.ing.nombre)}</span><em>${esc(cantCompra(a.cantidad, a.ing))}</em></label>`);
        $('input', fila).addEventListener('change', ev => {
          E.marcados = ev.target.checked ? E.marcados.concat(a.ing.id) : E.marcados.filter(x => x !== a.ing.id);
          guardar('marcados'); fila.classList.toggle('hecho', ev.target.checked);
        });
        sec.appendChild(fila);
      });
      caja.appendChild(sec);
    });
    $('#copiar').onclick = async () => {
      let t = 'Lista de la compra · GymApp\n';
      for (const s of secs) {
        t += '\n' + s.nombre.toUpperCase() + '\n';
        for (const a of s.articulos) t += (E.marcados.includes(a.ing.id) ? '✓ ' : '• ') + a.ing.nombre + ': ' + cantCompra(a.cantidad, a.ing) + '\n';
      }
      try { await navigator.clipboard.writeText(t); $('#copiar').textContent = '✓ Copiada'; }
      catch (e) { $('#copiar').textContent = 'No se pudo copiar'; }
      setTimeout(() => { $('#copiar').textContent = '📋 Copiar lista'; }, 2000);
    };
  }
  $('#menos').addEventListener('click', () => { E.personas = Math.max(1, E.personas - 1); guardar('personas'); pintar(); });
  $('#mas').addEventListener('click', () => { E.personas = Math.min(12, E.personas + 1); guardar('personas'); pintar(); });
  $('#desmarcar').addEventListener('click', () => { E.marcados = []; guardar('marcados'); pintar(); });

  // ---------- Registro de peso y altura ----------
  const hoyISO = () => { const d = new Date(); return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 10); };
  $('#r-fecha').value = hoyISO();
  $('#r-peso').value = E.peso; $('#r-altura').value = E.altura;
  $('#form-registro').addEventListener('submit', ev => {
    ev.preventDefault();
    const fecha = $('#r-fecha').value || hoyISO();
    const peso = parseFloat(String($('#r-peso').value).replace(',', '.'));
    const altura = parseFloat(String($('#r-altura').value).replace(',', '.'));
    if (!(peso > 0) || !(altura > 0)) return;
    E.registro = E.registro.filter(r => r.fecha !== fecha).concat({ fecha, peso, altura }).sort((a, b) => a.fecha.localeCompare(b.fecha));
    const ultima = E.registro[E.registro.length - 1];
    E.peso = ultima.peso; E.altura = ultima.altura;
    $('#peso').value = E.peso; $('#altura').value = E.altura;
    guardar('registro', 'peso', 'altura'); pintar();
  });
  function pintarRegistro() {
    const r = E.registro;
    const tabla = $('#tabla-registro');
    const imc = x => x.peso / Math.pow(x.altura / 100, 2);
    tabla.innerHTML = r.length ? `<table class="zonas"><thead><tr><th>Fecha</th><th>Peso</th><th>Altura</th><th>IMC</th><th></th></tr></thead><tbody>
      ${r.slice().reverse().map(x => `<tr><td>${new Date(x.fecha + 'T12:00').toLocaleDateString('es-ES', { day: 'numeric', month: 'short', year: 'numeric' })}</td>
        <td>${numero(x.peso, 1)} kg</td><td>${numero(x.altura)} cm</td><td>${numero(imc(x), 1)}</td>
        <td><button class="boton secundario pequeno" data-f="${x.fecha}" type="button" aria-label="Borrar">✕</button></td></tr>`).join('')}</tbody></table>`
      : '<p class="texto-2">Aún no hay medidas. Añade la primera arriba.</p>';
    $$('button[data-f]', tabla).forEach(b => b.addEventListener('click', () => {
      E.registro = E.registro.filter(x => x.fecha !== b.dataset.f); guardar('registro'); pintar();
    }));
    const g = $('#grafica');
    if (r.length < 2) { g.innerHTML = ''; return; }
    const W = 600, H = 200, P = 30;
    const pesos = r.map(x => x.peso), min = Math.min(...pesos) - 1, max = Math.max(...pesos) + 1;
    const t0 = new Date(r[0].fecha).getTime(), t1 = new Date(r[r.length - 1].fecha).getTime() || t0 + 1;
    const X = f => P + (new Date(f).getTime() - t0) / Math.max(t1 - t0, 1) * (W - 2 * P);
    const Y = p => H - P - (p - min) / (max - min) * (H - 2 * P);
    const pts = r.map(x => `${X(x.fecha).toFixed(1)},${Y(x.peso).toFixed(1)}`).join(' ');
    g.innerHTML = `<svg viewBox="0 0 ${W} ${H}" role="img" aria-label="Evolución del peso" style="width:100%;height:auto">
      <line x1="${P}" y1="${H - P}" x2="${W - P}" y2="${H - P}" stroke="currentColor" opacity=".15"/>
      <text x="${P}" y="${Y(max) + 4}" font-size="12" fill="currentColor" opacity=".6">${numero(max, 1)} kg</text>
      <text x="${P}" y="${Y(min) - 4}" font-size="12" fill="currentColor" opacity=".6">${numero(min, 1)} kg</text>
      <polyline points="${pts}" fill="none" stroke="var(--coral)" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"/>
      ${r.map(x => `<circle cx="${X(x.fecha).toFixed(1)}" cy="${Y(x.peso).toFixed(1)}" r="4.5" fill="var(--coral)"/>`).join('')}</svg>`;
  }

  function pintar() {
    GA.$$('button', segSexo).forEach(b => b.setAttribute('aria-pressed', b.dataset.v === E.sexo));
    selAct.value = E.actividad; selDias.value = E.dias;
    GA.$$('.chip', caObj).forEach(b => b.setAttribute('aria-pressed', b.dataset.v === E.objetivo));
    GA.$$('.chip', caFil).forEach(b => b.setAttribute('aria-pressed', !!E[b.dataset.k]));
    GA.$$('button', segVista).forEach(b => b.setAttribute('aria-pressed', b.dataset.v === E.vista));
    const nec = necesidades();
    pintarCifras(nec);
    const sem = semana(nec);
    $('#vista-menu').classList.toggle('oculto', E.vista !== 'menu');
    $('#vista-compra').classList.toggle('oculto', E.vista !== 'compra');
    $('#vista-registro').classList.toggle('oculto', E.vista !== 'registro');
    if (E.vista === 'menu') pintarMenu(sem);
    else if (E.vista === 'compra') pintarCompra(sem);
    else pintarRegistro();
  }
  pintar();
})();
