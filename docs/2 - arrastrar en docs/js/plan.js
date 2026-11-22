/* Plan semanal: misma lógica que Planificador (PlanView.swift) */
(async function () {
  'use strict';
  const { $, html, esc, LUGARES, NOMBRE_MUSCULO } = GA;
  const lista = await GA.ejercicios();
  let dias = GA.almacen.leer('plan.dias', 3);
  let lugar = GA.almacen.leer('plan.lugar', 'pesas');

  const empuje = ['pecho', 'hombros', 'triceps'];
  const tiron = ['espalda', 'trapecio', 'biceps', 'antebrazos'];
  const pierna = ['cuadriceps', 'isquiotibiales', 'gluteos', 'gemelos', 'abdominales'];

  function sesiones(n) {
    switch (n) {
      case 2: return [['Cuerpo completo A', ['pecho', 'espalda', 'cuadriceps', 'hombros', 'biceps', 'abdominales'], 0],
        ['Cuerpo completo B', ['gluteos', 'isquiotibiales', 'pecho', 'espalda', 'triceps', 'gemelos'], 1]];
      case 3: return [['Empuje', empuje, 0], ['Tirón', tiron, 0], ['Pierna y core', pierna, 0]];
      case 4: return [['Torso A', ['pecho', 'espalda', 'hombros', 'biceps', 'triceps'], 0],
        ['Pierna A', ['cuadriceps', 'isquiotibiales', 'gluteos', 'gemelos', 'abdominales'], 0],
        ['Torso B', ['espalda', 'pecho', 'trapecio', 'triceps', 'biceps'], 1],
        ['Pierna B', ['gluteos', 'isquiotibiales', 'cuadriceps', 'aductores', 'abductores', 'oblicuos'], 1]];
      case 5: return [['Empuje', empuje, 0], ['Tirón', tiron, 0], ['Pierna', pierna, 0],
        ['Torso', ['pecho', 'espalda', 'hombros', 'lumbares'], 1],
        ['Brazos y core', ['biceps', 'triceps', 'antebrazos', 'abdominales', 'oblicuos'], 1]];
      default: return [['Empuje A', empuje, 0], ['Tirón A', tiron, 0], ['Pierna A', pierna, 0],
        ['Empuje B', empuje.concat(['abdominales']), 1], ['Tirón B', tiron.concat(['lumbares']), 1],
        ['Pierna B', ['gluteos', 'isquiotibiales', 'cuadriceps', 'aductores', 'abductores', 'oblicuos'], 1]];
    }
  }
  const diasSemana = n => ({
    2: ['Lunes', 'Jueves'], 3: ['Lunes', 'Miércoles', 'Viernes'], 4: ['Lunes', 'Martes', 'Jueves', 'Viernes'],
    5: ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes']
  }[n] || ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado']);

  function plan(n, l) {
    const nombres = diasSemana(n);
    return sesiones(n).map(([titulo, musculos, variante], i) => {
      const elegidos = [];
      for (const m of musculos) {
        const disponibles = lista.filter(e => e.lugar === l && !elegidos.includes(e));
        let candidatos = disponibles.filter(e => e.principales[0] === m);
        if (!candidatos.length) candidatos = disponibles.filter(e => e.principales.includes(m));
        if (!candidatos.length) continue;
        elegidos.push(candidatos[variante % candidatos.length]);
      }
      return { dia: nombres[i], titulo, musculos, ejercicios: elegidos };
    });
  }

  const segDias = $('#seg-dias'), segLugar = $('#seg-lugar');
  [2, 3, 4, 5, 6].forEach(n => {
    const b = html(`<button type="button">${n}</button>`); b.dataset.v = n;
    b.addEventListener('click', () => { dias = n; GA.almacen.guardar('plan.dias', n); pintar(); });
    segDias.appendChild(b);
  });
  Object.entries(LUGARES).forEach(([k, l]) => {
    const b = html(`<button type="button">${l.emoji} ${esc(l.nombre)}</button>`); b.dataset.v = k;
    b.addEventListener('click', () => { lugar = k; GA.almacen.guardar('plan.lugar', k); pintar(); });
    segLugar.appendChild(b);
  });

  function pintar() {
    GA.$$('button', segDias).forEach(b => b.setAttribute('aria-pressed', +b.dataset.v === dias));
    GA.$$('button', segLugar).forEach(b => b.setAttribute('aria-pressed', b.dataset.v === lugar));
    const caja = $('#dias');
    caja.innerHTML = '';
    const semana = new Set();
    for (const d of plan(dias, lugar)) {
      d.musculos.forEach(m => semana.add(m));
      const t = html(`<section class="tarjeta caja">
        <div class="dia-cab"><span class="d">${esc(d.dia.slice(0, 3).toUpperCase())}</span>
          <div><h3>${esc(d.titulo)}</h3><small class="texto-2">${esc(d.dia)} · ${d.ejercicios.length} ejercicios</small></div></div>
        <div class="mapa-dia"></div><div class="lista"></div></section>`);
      $('.mapa-dia', t).appendChild(GA.mapa({ principales: d.musculos }));
      d.ejercicios.forEach(e => $('.lista', t).appendChild(GA.filaEjercicio(e, e.series)));
      caja.appendChild(t);
    }
    const res = $('#semana-mapa'); res.innerHTML = '';
    res.appendChild(GA.mapa({ principales: [...semana] }));
    $('#semana-texto').textContent = [...semana].map(m => NOMBRE_MUSCULO[m]).join(', ');
  }
  pintar();
})();
