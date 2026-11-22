# GymApp

App de ejercicios para iPhone, iPad y Mac (SwiftUI) con pesas, máquinas y ejercicios en casa sin material.
Cada ejercicio colorea en el dibujo del cuerpo los músculos que trabaja: **rojo** = principal, **naranja** = secundario.

## Abrir y ejecutar
1. Abre `GymApp.xcodeproj` con Xcode 16 o posterior.
2. Pulsa el proyecto **GymApp** (icono azul) → pestaña **Signing & Capabilities** → en **Team** elige tu cuenta de Apple.
3. Arriba, elige el destino (**My Mac**, tu iPhone o un simulador) y pulsa ▶︎.

## Contenido
| Archivo | Para qué sirve |
|---|---|
| `GymAppApp.swift` | Arranque de la app, pestañas (Inicio, Ejercicios, Músculos, Mi plan, Correr, Menús) y modo claro/oscuro |
| `Tema.swift` | Colores del logo (azules y coral), estilo de tarjeta, apariencia, favoritos y estado compartido |
| `Modelos.swift` | Músculos, lugares (pesas, máquinas, casa), carga de ejercicios y buscador |
| `InicioView.swift` | Pantalla de inicio: logo, buscador, lugares, ejercicio del día y favoritos |
| `MapaMuscularView.swift` | Dibujo del cuerpo que se colorea y se puede tocar |
| `MapaZoomView.swift` | Dibujo ampliable (pellizcar, arrastrar, botones + y −) |
| `EjerciciosView.swift` | Catálogo con filtros y buscador, y ficha de cada ejercicio |
| `MusculosView.swift` | Tocar un músculo y ver sus ejercicios |
| `PlanView.swift` | Plan semanal según días y lugar |
| `InfoView.swift` | Logo, apariencia, web y contacto (se abre desde Inicio → Información) |
| `MenusView.swift` | Pestaña Menús: objetivo, filtros, menú de 7 días con 5 comidas, lista de la compra y hoja «Mis datos» |
| `RegistroView.swift` | Registro de peso y altura (cm) con fecha, gráfica, IMC e historial; se guarda en el dispositivo |
| `MenusModelos.swift` | Lectura de menus.json, cálculo de calorías y proteínas, generador de menús y lista de la compra |
| `CorrerView.swift` | Pestaña Correr: distancia (chips y barra de 3 a 42,2 km), nivel, días, semanas, ritmos, plan semana a semana, calentamiento, estiramientos y fuerza |
| `CorrerModelos.swift` | Lectura de correr.json, calculadora de ritmo (Riegel) y generador de planes |
| `Componentes.swift` | Ajustes (`Config`), tarjetas, chips, etiquetas y botón de favorito |
| `ejercicios.json` | Lista de ejercicios (también la usará la web) |
| `menus.json` | Ingredientes, platos, objetivos y parámetros de los menús (también lo usará la web) |
| `correr.json` | Distancias, niveles, zonas de ritmo, sesiones, plantillas de la semana y fuerza para corredores (también lo usará la web) |
| `mapa_toque.json` | Rejilla para saber qué músculo se toca |

Las imágenes `m_*` del catálogo de recursos son las zonas de cada músculo sacadas del dibujo original.

## Colores
| Nombre | Color | Uso |
|---|---|---|
| `Tema.azulOscuro` | #0B386E | Degradados |
| `Tema.azul` | #1F70BD | Pesas, botones |
| `Tema.celeste` | #5CB8E6 | Máquinas, acento en modo oscuro |
| `Tema.coral` | #F27873 | En casa, favoritos, consejos |

## Menús
- **Cálculo**: fórmula de Mifflin-St Jeor × actividad diaria + 0,04 por cada día de entreno, más el ajuste del objetivo (p. ej. −20 % adelgazar, +10 % ganar músculo). Nunca baja de 1300 kcal (mujer) / 1600 kcal (hombre) ni del metabolismo basal. Los días de entreno llevan algo más de comida y los de descanso algo menos; la media semanal no cambia.
- **Menús**: 5 comidas (desayuno 22 %, media mañana 10 %, comida 33 %, merienda 12 %, cena 23 %). Las raciones de cada plato se agrandan o achican para llegar a las calorías. Botón **Cambiar** en cada comida y **Otra semana** arriba.
- **Filtros** combinables: vegetariano (con huevos y lácteos), sin gluten y sin lactosa. Sin gluten y sin lactosa cambian ingredientes por su versión apta (pan, pasta, avena, leche, yogur, quesos); si un plato no se puede adaptar, no aparece.
- **menus.json**: cada ingrediente lleva calorías y nutrientes por 100 g; las calorías de los platos se calculan solas. Para añadir o cambiar platos, edita `Herramientas/generar_menus.py` y ejecútalo con `python3 Herramientas/generar_menus.py GymApp/menus.json`, o edita el JSON a mano.
- **Registro**: tercera vista de Menús. Guarda peso y altura con fecha (una medida por día; si repites el día, se sustituye). La medida más reciente pasa a «Mis datos» y recalcula las calorías.
- Es orientativo y no sustituye a un dietista-nutricionista (el aviso está en la app y en el JSON).

## Correr
- **Objetivo**: 5 km, 10 km, media maratón (21,1 km), maratón (42,2 km) o cualquier distancia con la barra (3–42,2 km, de 0,5 en 0,5; se pega a las distancias rápidas al acercarse).
- **Nivel**: empezar desde cero (2–4 días, empieza alternando correr y caminar), intermedio (3–6 días) y avanzado (3–6 días). **Semanas**: 4–30, con las recomendadas para cada distancia y nivel. El plan empieza un lunes (botón del calendario) y la carrera es el domingo de la última semana.
- **Cómo se calcula**: fases base → desarrollo → específica → afinado → semana de carrera. Los km suben como máximo un 10 % por semana, cada 4.ª semana es de descarga (−20 %) y antes de la carrera se baja según la distancia (1 semana en 5–10 km, 2 en la media, 3 en la maratón). La tirada larga crece con los km y tiene un tope por distancia y de 3 horas. Las reglas exactas están al final de `correr.json` (`reglas`), para que la web haga lo mismo.
- **Ritmos**: calculadora con un tiempo reciente (fórmula de Riegel): ritmo, velocidad, tiempos estimados y zonas (suave, tirada larga, maratón, umbral, series, rápidas y ritmo de carrera). Sin tiempo, cada zona se explica por sensaciones.
- **Fuerza**: Fuerza A (pierna y core, solo 1 día a la semana y nunca el día antes de series o tirada larga) y Fuerza B (tren superior y core), con los ejercicios de `ejercicios.json` en pesas, máquinas o casa. Nada de fuerza en la semana de carrera.
- **Cambiar sesiones o niveles**: edita `Herramientas/generar_correr.py` y ejecútalo con `python3 Herramientas/generar_correr.py GymApp/correr.json` (comprueba que los ejercicios existen).
- En iPhone, con 6 pestañas, **Correr** y **Menús** aparecen dentro de **Más** (también se abren desde Inicio).

## Versión web (carpeta `docs/`)
- Dirección: **https://mhowani.github.io/GymApp/** (GitHub Pages, rama `main`, carpeta `/docs`).
- HTML, CSS y JavaScript sin instalar nada. Páginas: Inicio, Ejercicios (filtros por lugar, músculo, nivel, favoritos y buscador), Músculos (dibujo que se puede tocar), Mi plan, Correr, Menús y Contacto (formulario de Web3Forms).
- **Datos**: usa los mismos JSON que la app, copiados en `docs/datos/` (GitHub Pages solo publica `docs/`). Si cambias `GymApp/ejercicios.json`, `menus.json`, `correr.json` o `mapa_toque.json`, cópialos también allí:
  `cp GymApp/ejercicios.json GymApp/menus.json GymApp/correr.json GymApp/mapa_toque.json docs/datos/`
- **Dibujo de músculos**: las imágenes `m_*.png` de Assets.xcassets están en `docs/img/` (reducidas a 1000 px) y se colorean con máscaras CSS. `mapa_toque.json` dice qué músculo se ha tocado.
- **Figuras animadas**: `docs/js/figura.js` es la traducción a JavaScript de `FiguraEjercicioView.swift` (mismo campo `animacion` de ejercicios.json).
- **Animaciones**: están definidas en `Herramientas/anims.py` y `Herramientas/anims_nuevos.py`. Para volver a escribirlas en el JSON: `python3 Herramientas/poner_animaciones.py GymApp/ejercicios.json` (con una segunda ruta `.png` genera una hoja de prueba; necesita Pillow).
- **Contacto**: el formulario envía a Web3Forms con la clave de acceso que hay en `docs/contacto.html` (no es secreta).
- **Google Search Console**: la etiqueta de verificación va en el `<head>` de `docs/index.html`; `docs/sitemap.xml` y `docs/robots.txt` llevan la dirección de la web.
- Favoritos, plan, menús, registro y planes de correr se guardan solo en el navegador (localStorage).
