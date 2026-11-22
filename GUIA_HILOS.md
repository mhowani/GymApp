# GymApp · Guía de los 3 hilos

El proyecto base está en **~/Developer/GymApp** (Mac). Para cada hilo, abre una conversación nueva en la app de Claude del Mac, pulsa **+ → Añadir carpeta**, elige **~/Developer/GymApp** y pega el texto del hilo.

---

## Hilo 1 · Diseño de la app (Xcode)

> Estoy haciendo la app GymApp en Xcode (SwiftUI, iPhone, iPad y Mac). El proyecto está en ~/Developer/GymApp; lee el README.md y los archivos .swift antes de empezar. No sé programar: devuélveme siempre los archivos completos para copiar y pegar (o modifícalos directamente en la carpeta). La pruebo en un iPhone SE y en el Mac.
> En este hilo quiero mejorar el **diseño**: pantalla de inicio más visual con el logo, colores del logo (azules y coral), tarjetas más bonitas, modo oscuro, favoritos, buscador, ampliar el dibujo de músculos con zoom y añadir más ejercicios a ejercicios.json (pesas, máquinas y en casa sin material).

## Hilo 2 · Plan de trabajo según los días a la semana

> Estoy haciendo la app GymApp en Xcode (SwiftUI, iPhone, iPad y Mac). El proyecto está en ~/Developer/GymApp; lee el README.md y PlanView.swift. No sé programar: devuélveme siempre los archivos completos.
> En este hilo quiero ampliar el **plan de trabajo**: elegir de 1 a 7 días por semana, objetivo (fuerza, ganar músculo, perder grasa, mantenerme), nivel (principiante, intermedio, avanzado) y lugar (pesas, máquinas, casa o mezcla). Que reparta los grupos musculares por días con descanso, marque series, repeticiones y descanso, permita cambiar un ejercicio por otro equivalente, marcar ejercicios hechos, guardar el historial y mostrar en el dibujo los músculos trabajados en la semana.

## Hilo 3 · Versión web + GitHub + Google Search Console + Web3Forms

> Estoy haciendo la app GymApp. El proyecto de Xcode está en ~/Developer/GymApp (lee el README.md). Quiero una **versión web** de la app en la carpeta docs/ (HTML, CSS y JavaScript, sin instalar nada) que use los mismos datos: GymApp/ejercicios.json, las imágenes de músculos m_*.png de Assets.xcassets (para colorear el dibujo) y el logo.
> Debe tener: catálogo de ejercicios con filtros (pesas, máquinas, casa), mapa muscular que se pueda tocar, plan semanal, y una página de **contacto con formulario de Web3Forms**.
> Después, usando el navegador de la app de Claude en mi Mac (tengo la sesión iniciada): crear el repositorio en **GitHub**, subir el proyecto, activar **GitHub Pages** desde docs/, conseguir la clave de acceso de **Web3Forms** y ponerla en el formulario, y dar de alta la web en **Google Search Console** (verificación con etiqueta HTML, sitemap.xml y robots.txt). Al final, actualiza Config.webURL y Config.contactoURL en Componentes.swift con la dirección de la web.

---

### Orden recomendado
1. Abrir el proyecto y comprobar que compila (pega aquí los errores si los hay).
2. Hilo 1 (diseño) → 3. Hilo 2 (plan) → 4. Hilo 3 (web), así la web sale con los ejercicios y el plan ya definitivos.
