/* GymApp · service worker: la web funciona sin conexión y se puede instalar como app (Android, Windows…).
   Cada vez que publiques cambios en la web, sube el número de VERSION para que los usuarios reciban lo nuevo. */
const VERSION = 'gymapp-2026-11-22-1';
const BASICOS = VERSION + '-basicos';
const IMAGENES = 'gymapp-imagenes-1';

// Lo imprescindible para usar la app sin conexión (las figuras de los ejercicios se guardan al verlas).
const PRECARGA = [
  "./",
  "404.html",
  "contacto.html",
  "correr.html",
  "ejercicios.html",
  "index.html",
  "manual.html",
  "menus.html",
  "musculos.html",
  "plan.html",
  "privacidad.html",
  "manifest.webmanifest",
  "favicon.png",
  "css/estilo.css",
  "js/comun.js",
  "js/contacto.js",
  "js/correr.js",
  "js/ejercicios.js",
  "js/figura.js",
  "js/inicio.js",
  "js/menus.js",
  "js/musculos.js",
  "js/plan.js",
  "datos/correr.json",
  "datos/ejercicios.json",
  "datos/mapa_toque.json",
  "datos/menus.json",
  "img/logo.png",
  "img/icono-192.png",
  "img/icono-512.png",
  "img/apple-touch-icon.png",
  "img/m_abdominales.png",
  "img/m_abductores.png",
  "img/m_aductores.png",
  "img/m_antebrazos.png",
  "img/m_biceps.png",
  "img/m_cuadriceps.png",
  "img/m_cuerpo.png",
  "img/m_espalda.png",
  "img/m_gemelos.png",
  "img/m_gluteos.png",
  "img/m_hombros.png",
  "img/m_isquiotibiales.png",
  "img/m_lineas.png",
  "img/m_lumbares.png",
  "img/m_oblicuos.png",
  "img/m_pecho.png",
  "img/m_trapecio.png",
  "img/m_triceps.png"
];

self.addEventListener('install', ev => {
  ev.waitUntil(caches.open(BASICOS).then(c => c.addAll(PRECARGA)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', ev => {
  ev.waitUntil(
    caches.keys()
      .then(claves => Promise.all(claves.filter(k => k !== BASICOS && k !== IMAGENES).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

// Páginas, estilos, código y datos: primero internet (para tener siempre lo último) y, si no hay, la copia guardada.
async function primeroRed(peticion) {
  const cache = await caches.open(BASICOS);
  try {
    const r = await fetch(peticion);
    if (r && r.ok) cache.put(peticion, r.clone());
    return r;
  } catch (e) {
    const guardada = await cache.match(peticion, { ignoreSearch: true });
    if (guardada) return guardada;
    if (peticion.mode === 'navigate') return cache.match('index.html');
    throw e;
  }
}

// Imágenes: primero la copia guardada (rápido y sin gastar datos) y, si no está, se descarga y se guarda.
async function primeroCache(peticion) {
  const guardada = await caches.match(peticion, { ignoreSearch: true });
  if (guardada) return guardada;
  const r = await fetch(peticion);
  if (r && r.ok) (await caches.open(IMAGENES)).put(peticion, r.clone());
  return r;
}

self.addEventListener('fetch', ev => {
  const p = ev.request;
  if (p.method !== 'GET') return;
  const url = new URL(p.url);
  if (url.origin !== self.location.origin) return; // el formulario de contacto y otras webs van directos
  if (p.destination === 'image' || /\.(png|gif|jpe?g|webp|svg)$/i.test(url.pathname)) ev.respondWith(primeroCache(p));
  else ev.respondWith(primeroRed(p));
});
