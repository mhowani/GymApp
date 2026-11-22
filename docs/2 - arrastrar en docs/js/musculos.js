/* Músculos: tocar el dibujo o la lista y ver sus ejercicios */
(async function () {
  'use strict';
  const { $, html, esc, MUSCULOS, NOMBRE_MUSCULO, LUGARES } = GA;
  const lista = await GA.ejercicios();
  let elegido = new URLSearchParams(location.search).get('m') || 'pecho';
  let lugar = '';

  const chips = $('#chips-musculos');
  GA.ZONAS.forEach(([z, nombre]) => {
    chips.appendChild(html(`<div class="texto-2 pequeno" style="width:100%;margin-top:6px;font-weight:700">${esc(nombre)}</div>`));
    MUSCULOS.filter(m => m.zona === z).forEach(m => {
      const b = html(`<button class="chip" type="button">${esc(m.nombre)}</button>`);
      b.dataset.m = m.id;
      b.addEventListener('click', () => elegir(m.id));
      chips.appendChild(b);
    });
  });
  const seg = $('#seg-lugar');
  [['', 'Todos']].concat(Object.entries(LUGARES).map(([k, l]) => [k, l.nombre])).forEach(([k, n]) => {
    const b = html(`<button type="button">${esc(n)}</button>`);
    b.dataset.l = k;
    b.addEventListener('click', () => { lugar = k; pintar(); });
    seg.appendChild(b);
  });

  function elegir(m) {
    elegido = m;
    history.replaceState(null, '', '?m=' + m);
    pintar();
    if (window.innerWidth < 800) $('#titulo-musculo').scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  function pintar() {
    const caja = $('#mapa');
    caja.innerHTML = '';
    caja.appendChild(GA.mapa({ principales: [elegido], alTocar: elegir }));
    GA.$$('#chips-musculos .chip').forEach(b => b.setAttribute('aria-pressed', b.dataset.m === elegido));
    GA.$$('button', seg).forEach(b => b.setAttribute('aria-pressed', b.dataset.l === lugar));
    $('#titulo-musculo').textContent = NOMBRE_MUSCULO[elegido];
    const deLugar = lista.filter(e => !lugar || e.lugar === lugar);
    const prin = deLugar.filter(e => e.principales.includes(elegido));
    const sec = deLugar.filter(e => !e.principales.includes(elegido) && e.secundarios.includes(elegido));
    $('#n-musculo').textContent = `${prin.length} como principal · ${sec.length} como secundario`;
    const cp = $('#lista-principal'); cp.innerHTML = '';
    prin.forEach(e => cp.appendChild(GA.filaEjercicio(e, LUGARES[e.lugar].nombre + ' · ' + e.series)));
    const cs = $('#lista-secundario'); cs.innerHTML = '';
    sec.forEach(e => cs.appendChild(GA.filaEjercicio(e, LUGARES[e.lugar].nombre + ' · ' + e.series)));
    $('#bloque-sec').classList.toggle('oculto', !sec.length);
    $('#sin-ej').classList.toggle('oculto', prin.length + sec.length > 0);
  }
  pintar();
})();
