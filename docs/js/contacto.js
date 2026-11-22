/* Formulario de contacto con Web3Forms (https://web3forms.com) */
(function () {
  'use strict';
  const f = document.getElementById('formulario');
  const res = document.getElementById('resultado');
  const boton = f.querySelector('button[type="submit"]');
  f.addEventListener('submit', async ev => {
    ev.preventDefault();
    if (!f.reportValidity()) return;
    boton.disabled = true;
    const texto = boton.textContent;
    boton.textContent = 'Enviando…';
    res.className = 'resultado oculto';
    try {
      const datos = Object.fromEntries(new FormData(f));
      const r = await fetch('https://api.web3forms.com/submit', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
        body: JSON.stringify(datos)
      });
      const j = await r.json();
      if (r.ok && j.success) {
        res.textContent = '¡Gracias! Tu mensaje se ha enviado. Te responderemos lo antes posible.';
        res.className = 'resultado ok';
        f.reset();
      } else {
        throw new Error(j.message || 'Error al enviar');
      }
    } catch (e) {
      res.textContent = 'No se ha podido enviar el mensaje (' + e.message + '). Inténtalo de nuevo dentro de un rato.';
      res.className = 'resultado error';
    } finally {
      boton.disabled = false;
      boton.textContent = texto;
    }
  });
})();
