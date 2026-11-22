/* Catálogo: filtros por lugar, zona, nivel, favoritos y buscador */
(async function () {
  'use strict';
  const { $, $$, html, esc, normalizar, LUGARES, MUSCULOS, NOMBRE_MUSCULO } = GA;
  const lista = await GA.ejercicios();
  const params = new URLSearchParams(location.search);
  const estado = {
    lugar: params.get('lugar') || '',
    musculo: params.get('musculo') || '',
    nivel: '',
    favoritos: false,
    q: params.get('q') || ''
  };

  const chipsLugar = $('#f-lugar');
  [['', 'Todos', 'var(--acento)', '']].concat(Object.entries(LUGARES).map(([id, l]) => [id, l.nombre, l.color, l.emoji]))
    .forEach(([id, nombre, color, emoji]) => {
      const b = html(`<button class="chip" type="button" style="--c:${color}">${emoji ? emoji + ' ' : ''}${esc(nombre)}</button>`);
      b.dataset.v = id;
      b.addEventListener('click', () => { estado.lugar = id; pintar(); });
      chipsLugar.appendChild(b);
    });
  const selM = $('#f-musculo');
  GA.ZONAS.forEach(([z, nombreZona]) => {
    const g = document.createElement('optgroup'); g.label = nombreZona;
    MUSCULOS.filter(m => m.zona === z).forEach(m => g.appendChild(new Option(m.nombre, m.id)));
    selM.appendChild(g);
  });
  selM.addEventListener('change', () => { estado.musculo = selM.value; pintar(); });
  $('#f-nivel').addEventListener('change', ev => { estado.nivel = ev.target.value; pintar(); });
  const bFav = $('#f-fav');
  bFav.addEventListener('click', () => { estado.favoritos = !estado.favoritos; pintar(); });
  const q = $('#q');
  q.value = estado.q;
  q.addEventListener('input', () => { estado.q = q.value; pintar(); });
  $('#limpiar').addEventListener('click', () => {
    Object.assign(estado, { lugar: '', musculo: '', nivel: '', favoritos: false, q: '' });
    q.value = ''; pintar();
  });
  document.addEventListener('favoritos', () => { if (estado.favoritos) pintar(); });

  const textoBusqueda = e => normalizar([e.nombre, LUGARES[e.lugar].nombre, e.nivel]
    .concat(e.principales.map(m => NOMBRE_MUSCULO[m]), e.secundarios.map(m => NOMBRE_MUSCULO[m])).join(' '));

  function pintar() {
    $$('button', chipsLugar).forEach(b => b.setAttribute('aria-pressed', b.dataset.v === estado.lugar));
    selM.value = estado.musculo;
    $('#f-nivel').value = estado.nivel;
    bFav.setAttribute('aria-pressed', estado.favoritos);
    const palabras = normalizar(estado.q).split(/\s+/).filter(Boolean);
    const favs = GA.favoritos.lista();
    const res = lista.filter(e =>
      (!estado.lugar || e.lugar === estado.lugar) &&
      (!estado.musculo || e.principales.includes(estado.musculo) || e.secundarios.includes(estado.musculo)) &&
      (!estado.nivel || normalizar(e.nivel) === estado.nivel) &&
      (!estado.favoritos || favs.includes(e.id)) &&
      palabras.every(p => textoBusqueda(e).includes(p)));
    // Primero los que trabajan el músculo como principal
    if (estado.musculo) res.sort((a, b) => (b.principales.includes(estado.musculo) - a.principales.includes(estado.musculo)));
    $('#cuenta').textContent = res.length === 1 ? '1 ejercicio' : res.length + ' ejercicios';
    const caja = $('#resultados');
    caja.innerHTML = '';
    res.forEach(e => caja.appendChild(GA.tarjetaEjercicio(e)));
    $('#vacio').classList.toggle('oculto', res.length > 0);
    const p = new URLSearchParams();
    if (estado.lugar) p.set('lugar', estado.lugar);
    if (estado.musculo) p.set('musculo', estado.musculo);
    if (estado.q) p.set('q', estado.q);
    history.replaceState(null, '', location.pathname + (p.toString() ? '?' + p : '') + location.hash);
  }
  pintar();

  // Enlace directo a un ejercicio: ejercicios.html#press-banca-barra
  const id = decodeURIComponent(location.hash.slice(1));
  const e = id && lista.find(x => x.id === id);
  if (e) GA.abrirFicha(e);
})();
