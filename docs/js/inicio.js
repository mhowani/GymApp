/* Página de inicio: buscador, lugares, ejercicio del día y favoritos */
(async function () {
  'use strict';
  const { $, html, esc, LUGARES } = GA;
  const lista = await GA.ejercicios();
  for (const l of Object.keys(LUGARES)) {
    const n = $('#n-' + l);
    if (n) n.textContent = lista.filter(e => e.lugar === l).length + ' ejercicios';
  }
  $('#total').textContent = lista.length;

  const e = GA.ejercicioDelDia(lista);
  if (e) {
    const caja = $('#del-dia');
    const t = html(`<div class="tarjeta caja del-dia">
      <div class="marco fig"></div>
      <div><span class="etiqueta" style="--c:var(--coral)">⭐ Ejercicio del día</span>
        <h3 style="margin-top:10px;font-size:1.4rem">${esc(e.nombre)}</h3>
        <p class="texto-2">${esc(GA.nombresMusculos(e.principales).join(' · '))} · ${esc(e.series)}</p>
        <p>${esc(e.consejo)}</p>
        <button class="boton" type="button">Ver cómo se hace</button></div></div>`);
    const fig = Figura.crear(e);
    if (fig) $('.fig', t).appendChild(fig); else $('.fig', t).appendChild(GA.mapa({ principales: e.principales, secundarios: e.secundarios }));
    $('button', t).addEventListener('click', () => GA.abrirFicha(e));
    caja.appendChild(t);
  }

  function pintarFavoritos() {
    const ids = GA.favoritos.lista();
    const favs = ids.map(id => lista.find(x => x.id === id)).filter(Boolean);
    const caja = $('#favoritos');
    caja.innerHTML = '';
    $('#sin-favoritos').classList.toggle('oculto', favs.length > 0);
    favs.forEach(f => caja.appendChild(GA.tarjetaEjercicio(f)));
  }
  pintarFavoritos();
  document.addEventListener('favoritos', pintarFavoritos);

  $('#busqueda').addEventListener('submit', ev => {
    ev.preventDefault();
    const q = $('#q').value.trim();
    location.href = 'ejercicios.html' + (q ? '?q=' + encodeURIComponent(q) : '');
  });
})();
