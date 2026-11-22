# Genera correr.json para GymApp (app y web)
#
# Uso:  python3 Herramientas/generar_correr.py GymApp/correr.json
#
# Todo lo que sale en la pestaña Correr está aquí: distancias, niveles, ritmos,
# sesiones de calidad, plantillas de la semana, calentamiento, estiramientos y
# ejercicios de fuerza (con los id de ejercicios.json).
# La app (CorrerModelos.swift) y la web leen este archivo y siguen las mismas
# reglas, que están explicadas en "reglas" al final del JSON.
import json, os, sys

# ---------------------------------------------------------------------------
# Distancias rápidas (chips) y barra deslizante
DISTANCIAS = [
    {"id": "5k", "nombre": "5 km", "km": 5, "icono": "figure.run"},
    {"id": "10k", "nombre": "10 km", "km": 10, "icono": "figure.run"},
    {"id": "media", "nombre": "Media maratón", "km": 21.1, "icono": "medal"},
    {"id": "maraton", "nombre": "Maratón", "km": 42.2, "icono": "trophy"},
]
DESLIZADOR = {"min": 3, "max": 42.2, "paso": 0.5, "imanKm": 0.35}
SEMANAS = {"min": 4, "max": 30}

# ---------------------------------------------------------------------------
# Niveles. Las tablas son pares [km de la carrera, valor]; entre dos puntos se
# interpola en línea recta (así funciona la barra deslizante con cualquier km).
NIVELES = [
    {
        "id": "cero", "nombre": "Empezar desde cero", "icono": "figure.walk",
        "descripcion": "No corres ahora o corres menos de 20 minutos seguidos. Empieza alternando correr y caminar.",
        "diasMin": 2, "diasMax": 4, "diasPorDefecto": 3,
        "ritmoSuavePorDefecto": 450,          # 7:30 /km si no hay tiempo de referencia
        "kmPico": [[3, 11], [5, 14], [10, 22], [21.1, 32], [42.2, 48]],
        "tiradaMaxima": [[3, 4], [5, 6], [10, 10], [21.1, 18], [42.2, 30]],
        "semanasMinimas": [[3, 6], [5, 8], [10, 10], [21.1, 16], [42.2, 24]],
        "semanasRecomendadas": [[3, 8], [5, 10], [10, 12], [21.1, 18], [42.2, 26]],
        "fraccionInicio": 0.45, "kmMinimoRodaje": 2,
        "calentamientoKm": 1, "enfriamientoKm": 1,
        "segundaCalidadDesdeDias": 99, "correrCaminar": True,
    },
    {
        "id": "intermedio", "nombre": "Intermedio", "icono": "figure.run",
        "descripcion": "Ya corres 2–4 días por semana y aguantas 30–45 minutos seguidos.",
        "diasMin": 3, "diasMax": 6, "diasPorDefecto": 4,
        "ritmoSuavePorDefecto": 375,          # 6:15 /km
        "kmPico": [[3, 22], [5, 26], [10, 35], [21.1, 45], [42.2, 65]],
        "tiradaMaxima": [[3, 7], [5, 8], [10, 13], [21.1, 20], [42.2, 32]],
        "semanasMinimas": [[3, 4], [5, 6], [10, 8], [21.1, 10], [42.2, 16]],
        "semanasRecomendadas": [[3, 6], [5, 8], [10, 10], [21.1, 12], [42.2, 18]],
        "fraccionInicio": 0.6, "kmMinimoRodaje": 4,
        "calentamientoKm": 2, "enfriamientoKm": 1.5,
        "segundaCalidadDesdeDias": 5, "correrCaminar": False,
    },
    {
        "id": "avanzado", "nombre": "Avanzado", "icono": "bolt.fill",
        "descripcion": "Corres 4 días o más por semana, haces series y ya has corrido carreras.",
        "diasMin": 3, "diasMax": 6, "diasPorDefecto": 5,
        "ritmoSuavePorDefecto": 315,          # 5:15 /km
        "kmPico": [[3, 32], [5, 38], [10, 50], [21.1, 62], [42.2, 85]],
        "tiradaMaxima": [[3, 10], [5, 11], [10, 16], [21.1, 24], [42.2, 34]],
        "semanasMinimas": [[3, 4], [5, 4], [10, 6], [21.1, 8], [42.2, 12]],
        "semanasRecomendadas": [[3, 6], [5, 8], [10, 8], [21.1, 12], [42.2, 16]],
        "fraccionInicio": 0.65, "kmMinimoRodaje": 5,
        "calentamientoKm": 2.5, "enfriamientoKm": 2,
        "segundaCalidadDesdeDias": 4, "correrCaminar": False,
    },
]

# Con menos días se corren menos km a la semana
FACTOR_DIAS = {"2": 0.65, "3": 0.8, "4": 0.92, "5": 1.0, "6": 1.1}
# Parte máxima de los km de la semana que se puede llevar la tirada larga
PORCENTAJE_TIRADA = {"2": 0.6, "3": 0.48, "4": 0.45, "5": 0.4, "6": 0.36}

PROGRESION = {
    "subidaMaximaSemanal": 0.10,   # nunca más de un 10 % de km sobre la semana anterior
    "descargaCada": 4,             # cada 4.ª semana se baja…
    "factorDescarga": 0.8,         # …al 80 %
    "tiradaMaximaMinutos": 180,    # la tirada larga no pasa de 3 horas
    "redondeoKm": 0.5,
    "factorLargaCorrerCaminar": 1.25,
    "ritmoCorrerCaminar": 1.15,    # caminar+correr va un 15 % más lento que el rodaje suave
    "ritmoCalidad": 0.9,           # para estimar la duración de las sesiones de calidad
}

# Afinado (bajar km antes de la carrera). Se elige el último tramo cuyo desdeKm
# sea menor o igual que la distancia. "factores" va de la primera semana de
# afinado a la semana de la carrera (se multiplican por los km de la semana más alta).
AFINADO = [
    {"desdeKm": 0, "semanas": 1, "factores": [0.5]},
    {"desdeKm": 15, "semanas": 2, "factores": [0.75, 0.45]},
    {"desdeKm": 30, "semanas": 3, "factores": [0.8, 0.6, 0.35]},
]
REPARTO_FASES = {"base": 0.4, "desarrollo": 0.35}

FASES = [
    {"id": "base", "nombre": "Base", "color": "celeste",
     "descripcion": "Coger fondo con rodajes suaves, cuestas y algún cambio de ritmo. Sin prisa."},
    {"id": "desarrollo", "nombre": "Desarrollo", "color": "azul",
     "descripcion": "Suben los km y entran las series para ganar velocidad y resistencia."},
    {"id": "especifica", "nombre": "Específica", "color": "azulOscuro",
     "descripcion": "Entrenos al ritmo de la carrera y las tiradas largas más largas del plan."},
    {"id": "afinado", "nombre": "Afinado", "color": "coralClaro",
     "descripcion": "Bajan los km pero se mantiene algo de ritmo para llegar fresco."},
    {"id": "carrera", "nombre": "Semana de carrera", "color": "coral",
     "descripcion": "Poco volumen, mucho descanso y a disfrutar el domingo."},
]

# ---------------------------------------------------------------------------
# Zonas de ritmo. Se calcula el tiempo que harías en "referenciaKm" con la
# fórmula de Riegel (T2 = T1 × (D2/D1)^1,06) y su ritmo por km se multiplica por
# factorMin–factorMax (menor = más rápido). referenciaKm 0 = la distancia objetivo.
ZONAS = [
    {"id": "suave", "nombre": "Rodaje suave", "referenciaKm": 42.195, "factorMin": 1.12, "factorMax": 1.25,
     "sensacion": "Puedes charlar con frases completas · esfuerzo 3–4 de 10", "color": "celeste"},
    {"id": "larga", "nombre": "Tirada larga", "referenciaKm": 42.195, "factorMin": 1.10, "factorMax": 1.20,
     "sensacion": "Cómoda y constante, como si pudieras seguir mucho más · 4–5 de 10", "color": "azul"},
    {"id": "maraton", "nombre": "Ritmo maratón", "referenciaKm": 42.195, "factorMin": 0.99, "factorMax": 1.01,
     "sensacion": "Cómodo pero concentrado · 6 de 10", "color": "azulOscuro"},
    {"id": "umbral", "nombre": "Umbral (tempo)", "referenciaKm": 15, "factorMin": 0.99, "factorMax": 1.03,
     "sensacion": "Exigente pero controlado, solo frases cortas · 7 de 10", "color": "coralClaro"},
    {"id": "series", "nombre": "Series", "referenciaKm": 5, "factorMin": 0.98, "factorMax": 1.01,
     "sensacion": "Fuerte, solo un par de palabras · 8 de 10", "color": "coral"},
    {"id": "rapidas", "nombre": "Rápidas y cuestas", "referenciaKm": 3, "factorMin": 0.96, "factorMax": 1.0,
     "sensacion": "Muy rápido pero suelto, sin apretar los dientes · 9 de 10", "color": "rojo"},
    {"id": "carrera", "nombre": "Ritmo de carrera", "referenciaKm": 0, "factorMin": 0.99, "factorMax": 1.01,
     "sensacion": "El ritmo que quieres llevar el día de la carrera", "color": "morado"},
]

# Tipos de sesión (icono = símbolo SF Symbols de Apple; la web puede usar emojis)
TIPOS = [
    {"id": "suave", "nombre": "Rodaje suave", "icono": "figure.run", "emoji": "🏃", "color": "celeste",
     "descripcion": "Correr tranquilo. Es la base del plan: la mayoría de los km deben ir así."},
    {"id": "calidad", "nombre": "Series y ritmo", "icono": "bolt.fill", "emoji": "⚡", "color": "coral",
     "descripcion": "La sesión más exigente de la semana. Calienta bien antes y termina trotando."},
    {"id": "larga", "nombre": "Tirada larga", "icono": "road.lanes", "emoji": "🛣️", "color": "azul",
     "descripcion": "La salida más larga de la semana, siempre a ritmo cómodo."},
    {"id": "correrCaminar", "nombre": "Correr y caminar", "icono": "figure.walk", "emoji": "🚶", "color": "celeste",
     "descripcion": "Alterna correr suave y caminar. Si te cuesta, repite la semana antes de avanzar."},
    {"id": "carrera", "nombre": "Carrera", "icono": "flag.checkered", "emoji": "🏁", "color": "morado",
     "descripcion": "¡El día de la carrera!"},
    {"id": "fuerza", "nombre": "Fuerza", "icono": "dumbbell.fill", "emoji": "🏋️", "color": "azulOscuro",
     "descripcion": "Ejercicios de GymApp para correr mejor y lesionarte menos."},
    {"id": "descanso", "nombre": "Descanso", "icono": "bed.double.fill", "emoji": "😴", "color": "gris",
     "descripcion": "Descansar también es entrenar. Puedes caminar o estirar suave."},
]

# ---------------------------------------------------------------------------
# Sesiones de calidad.
# hueco: "calidad1" (series, la principal), "calidad2" (tempo, la segunda) o "ambos"
# km = parte principal; si conCalentamiento es true se suman los km de
# calentamiento y enfriamiento del nivel.
SES = []
def S(id, nombre, hueco, fases, dmin, dmax, zona, niveles, cal=True):
    for k, v in niveles.items():
        assert k in ("cero", "intermedio", "avanzado"), k
        assert len(v) == 2, (id, k)
    SES.append({"id": id, "nombre": nombre, "hueco": hueco, "fases": fases,
                "distanciaMin": dmin, "distanciaMax": dmax, "zona": zona, "conCalentamiento": cal,
                "niveles": {k: {"texto": t, "km": km} for k, (t, km) in niveles.items()}})

TODO = 99
# --- Base
S("rectas", "Rodaje con rectas", "calidad1", ["base"], 0, TODO, "rapidas", {
    "cero": ("Rodaje suave y al final 4 rectas de 15 s acelerando poco a poco; vuelve andando", 3),
    "intermedio": ("Rodaje suave y al final 6 rectas de 20 s acelerando poco a poco; vuelve andando", 6),
    "avanzado": ("Rodaje suave y al final 8 rectas de 20 s acelerando poco a poco; vuelve trotando", 8),
}, cal=False)
S("cuestas-cortas", "Cuestas cortas", "calidad1", ["base"], 0, TODO, "rapidas", {
    "cero": ("6 × 20 s cuesta arriba con fuerza; baja andando", 1.5),
    "intermedio": ("8 × 30 s cuesta arriba con fuerza; baja trotando muy suave", 2.5),
    "avanzado": ("10 × 45 s cuesta arriba con fuerza; baja trotando muy suave", 3.5),
})
S("fartlek", "Fartlek", "ambos", ["base"], 0, TODO, "umbral", {
    "cero": ("6 × (1 min alegre + 2 min muy suave)", 3),
    "intermedio": ("8 × (1 min alegre + 1 min 30 s suave)", 5),
    "avanzado": ("10 × (1 min alegre + 1 min suave)", 6),
})
S("progresivo-corto", "Rodaje progresivo", "calidad2", ["base"], 0, TODO, "umbral", {
    "intermedio": ("Empieza suave y ve subiendo poco a poco; el último km a ritmo umbral", 6),
    "avanzado": ("Empieza suave y ve subiendo poco a poco; los 2 últimos km a ritmo umbral", 9),
}, cal=False)
# --- Desarrollo y específica, distancias cortas (hasta 15 km)
S("series-400", "Series de 400 m", "calidad1", ["desarrollo", "especifica"], 0, 15, "rapidas", {
    "cero": ("6 × 200 m rápidos; recupera 2 min caminando", 1.5),
    "intermedio": ("10 × 400 m; recupera 90 s trotando", 4),
    "avanzado": ("12 × 400 m; recupera 75 s trotando", 5),
})
S("series-1000", "Series de 1000 m", "calidad1", ["desarrollo", "especifica"], 0, 25, "series", {
    "cero": ("4 × 500 m; recupera 2 min caminando", 2),
    "intermedio": ("5 × 1000 m; recupera 2 min trotando", 5),
    "avanzado": ("6 × 1000 m; recupera 90 s trotando", 6),
})
S("piramide", "Pirámide", "calidad1", ["desarrollo"], 0, 15, "series", {
    "cero": ("200 – 400 – 600 – 400 – 200 m; recupera 2 min caminando entre cada una", 1.8),
    "intermedio": ("400 – 800 – 1200 – 800 – 400 m; recupera 2 min trotando", 3.6),
    "avanzado": ("400 – 800 – 1200 – 1600 – 1200 – 800 – 400 m; recupera 90 s trotando", 6.4),
})
S("ritmo-carrera-corto", "Series a ritmo de carrera", "calidad1", ["especifica"], 0, 15, "carrera", {
    "cero": ("4 × 1 km a ritmo de carrera; recupera 2 min caminando", 4),
    "intermedio": ("4 × 1,5 km a ritmo de carrera; recupera 2 min trotando", 6),
    "avanzado": ("5 × 1,5 km a ritmo de carrera; recupera 90 s trotando", 7.5),
})
# --- Desarrollo y específica, distancias largas (más de 15 km)
S("series-largas", "Series largas a umbral", "calidad1", ["desarrollo"], 15, TODO, "umbral", {
    "cero": ("4 × 1 km a ritmo umbral; recupera 2 min trotando o caminando", 4),
    "intermedio": ("4 × 2 km a ritmo umbral; recupera 2 min trotando", 8),
    "avanzado": ("5 × 2 km a ritmo umbral; recupera 90 s trotando", 10),
})
S("cuestas-largas", "Cuestas largas", "calidad1", ["desarrollo"], 15, TODO, "series", {
    "cero": ("6 × 1 min cuesta arriba; baja andando", 2),
    "intermedio": ("8 × 90 s cuesta arriba; baja trotando", 3.5),
    "avanzado": ("10 × 2 min cuesta arriba; baja trotando", 5.5),
})
S("ritmo-carrera-largo", "Bloques a ritmo de carrera", "calidad1", ["especifica"], 15, TODO, "carrera", {
    "cero": ("2 × 3 km a ritmo de carrera; recupera 3 min trotando o caminando", 6),
    "intermedio": ("3 × 4 km a ritmo de carrera; recupera 3 min trotando", 12),
    "avanzado": ("3 × 5 km a ritmo de carrera; recupera 2 min trotando", 15),
})
S("progresivo-largo", "Progresivo hasta ritmo de carrera", "calidad1", ["especifica"], 15, TODO, "carrera", {
    "cero": ("Empieza suave y termina los 2 últimos km a ritmo de carrera", 6),
    "intermedio": ("Empieza suave y ve subiendo; los 4 últimos km a ritmo de carrera", 10),
    "avanzado": ("Empieza suave y ve subiendo; los 5 últimos km a ritmo de carrera", 13),
}, cal=False)
# --- Segunda sesión de calidad (tempo)
S("tempo-continuo", "Tempo continuo", "calidad2", ["desarrollo", "especifica"], 0, TODO, "umbral", {
    "intermedio": ("20–25 min seguidos a ritmo umbral", 4.5),
    "avanzado": ("30 min seguidos a ritmo umbral", 6.5),
})
S("tempo-fraccionado", "Tempo fraccionado", "calidad2", ["desarrollo", "especifica"], 0, TODO, "umbral", {
    "intermedio": ("3 × 8 min a ritmo umbral; recupera 2 min trotando", 5),
    "avanzado": ("3 × 10 min a ritmo umbral; recupera 2 min trotando", 7),
})
S("ritmo-maraton", "Rodaje a ritmo maratón", "calidad2", ["especifica"], 30, TODO, "maraton", {
    "intermedio": ("8 km seguidos a ritmo maratón", 8),
    "avanzado": ("12 km seguidos a ritmo maratón", 12),
})
# --- Afinado y semana de carrera
S("afinado-ritmo", "Series cortas a ritmo de carrera", "calidad1", ["afinado"], 0, TODO, "carrera", {
    "cero": ("4 × 400 m a ritmo de carrera; recupera 2 min caminando", 1.6),
    "intermedio": ("6 × 800 m a ritmo de carrera; recupera 2 min trotando", 4.8),
    "avanzado": ("6 × 1 km a ritmo de carrera; recupera 90 s trotando", 6),
})
S("tempo-corto", "Tempo corto", "calidad2", ["afinado"], 0, TODO, "umbral", {
    "intermedio": ("15 min a ritmo umbral", 3),
    "avanzado": ("20 min a ritmo umbral", 4.5),
})
S("activacion", "Activación", "calidad1", ["carrera"], 0, TODO, "carrera", {
    "cero": ("2 km suaves + 4 × 1 min a ritmo de carrera", 2.5),
    "intermedio": ("3 km suaves + 5 × 1 min a ritmo de carrera", 4),
    "avanzado": ("4 km suaves + 6 × 1 min a ritmo de carrera", 5),
}, cal=False)

# Correr y caminar (solo nivel «Empezar desde cero»). Minutos.
CORRER_CAMINAR = [
    {"correr": 1, "caminar": 2, "veces": 8},
    {"correr": 1.5, "caminar": 2, "veces": 7},
    {"correr": 2, "caminar": 2, "veces": 6},
    {"correr": 3, "caminar": 2, "veces": 5},
    {"correr": 4, "caminar": 1.5, "veces": 5},
    {"correr": 6, "caminar": 1.5, "veces": 4},
    {"correr": 8, "caminar": 1, "veces": 3},
    {"correr": 12, "caminar": 1, "veces": 2},
    {"correr": 20, "caminar": 0, "veces": 1},
    {"correr": 30, "caminar": 0, "veces": 1},
]

# Plantillas de la semana según los días que corres (lunes → domingo).
# Huecos: suave, calidad1, calidad2, larga, fuerzaA (pierna y core),
# fuerzaB (tren superior y core), descanso. Un "?" al final = opcional.
# Solo hay un día de pierna (fuerzaA) y nunca va el día antes de series o tirada larga.
PLANTILLAS = {
    "2": [["descanso"], ["calidad1"], ["fuerzaA"], ["descanso"], ["fuerzaB"], ["descanso"], ["larga"]],
    "3": [["descanso"], ["calidad1"], ["fuerzaA"], ["suave"], ["descanso"], ["fuerzaB"], ["larga"]],
    "4": [["descanso"], ["calidad1", "fuerzaA"], ["suave"], ["fuerzaB"], ["calidad2"], ["descanso"], ["larga"]],
    "5": [["descanso"], ["calidad1", "fuerzaA"], ["suave"], ["calidad2"], ["fuerzaB"], ["suave"], ["larga"]],
    "6": [["suave"], ["calidad1", "fuerzaA"], ["suave"], ["calidad2"], ["fuerzaB?"], ["suave"], ["larga"]],
}

# ---------------------------------------------------------------------------
CALENTAMIENTO = [
    {"nombre": "Caminar rápido o trotar muy suave", "detalle": "5–10 min, hasta notar el cuerpo caliente"},
    {"nombre": "Movilidad", "detalle": "Círculos de tobillos, rodillas y cadera; 10 de cada uno"},
    {"nombre": "Ejercicios de técnica", "detalle": "Skipping, talones al glúteo y zancada exagerada: 2 × 20 m de cada"},
    {"nombre": "Rectas progresivas", "detalle": "Antes de series o carrera: 3–4 × 80 m acelerando poco a poco"},
]
ESTIRAMIENTOS_ANTES = [
    {"nombre": "Balanceo de pierna adelante y atrás", "detalle": "10 por pierna, apoyado en una pared"},
    {"nombre": "Balanceo de pierna lateral", "detalle": "10 por pierna"},
    {"nombre": "Zancada con giro de tronco", "detalle": "5 por lado"},
    {"nombre": "Rodillas al pecho caminando", "detalle": "10 pasos"},
    {"nombre": "Elevaciones de talones", "detalle": "15 repeticiones"},
]
ESTIRAMIENTOS_DESPUES = [
    {"nombre": "Gemelo y sóleo en la pared", "detalle": "30 s cada pierna, con la rodilla estirada y luego doblada"},
    {"nombre": "Cuádriceps de pie", "detalle": "30 s cada pierna, talón al glúteo"},
    {"nombre": "Isquiotibiales", "detalle": "30 s cada pierna, con el talón apoyado en un escalón"},
    {"nombre": "Glúteo (figura 4)", "detalle": "30 s cada lado, tumbado boca arriba"},
    {"nombre": "Flexor de cadera", "detalle": "30 s cada lado, en posición de zancada con la rodilla en el suelo"},
    {"nombre": "Aductores (mariposa)", "detalle": "30 s sentado, plantas de los pies juntas"},
]
CONSEJOS = [
    "La mayoría de los km (alrededor del 80 %) deben ir a ritmo suave. Correr siempre rápido es la forma más fácil de lesionarse.",
    "Si te duele algo que no es cansancio normal (dolor punzante, que cambia tu forma de correr o que va a más), para y descansa.",
    "Si pierdes una sesión no la recuperes al día siguiente: sigue el plan como si nada.",
    "Si una semana se te hace muy dura, repítela antes de pasar a la siguiente.",
    "Prueba en las tiradas largas las zapatillas, la ropa, el desayuno y los geles que llevarás el día de la carrera.",
    "En carreras de más de 1 hora 15 min bebe un poco cada 20–30 min y, en la media y la maratón, toma hidratos (geles, dátiles…) a partir de los 45 min.",
    "Sal el día de la carrera algo más lento de lo previsto los primeros km: es mejor terminar fuerte que pinchar al final.",
]

# Fuerza para corredores: cada ejercicio con su versión en pesas, máquinas y en casa
FUERZA = {
    "descripcion": "Dos sesiones cortas (30–40 min) a la semana mejoran la economía de carrera y protegen rodillas, tobillos y cadera. Usa pesos que te dejen 2–3 repeticiones en reserva: no se trata de acabar destrozado.",
    "reglas": [
        "Solo un día de pierna a la semana (Fuerza A). La Fuerza B es de tren superior y core.",
        "La pierna va el mismo día que las series (después de correr o por la tarde) o tras un rodaje suave; nunca el día antes de series o de la tirada larga.",
        "Deja al menos 48 horas entre la Fuerza A y la tirada larga.",
        "Si además sigues «Mi plan» del gimnasio, quita de ese plan los días de pierna: con la Fuerza A de aquí es suficiente.",
        "En las semanas de afinado haz la mitad de series. En la semana de la carrera, nada de fuerza.",
    ],
    "sesiones": [
        {"id": "fuerzaA", "nombre": "Fuerza A · Pierna y core", "icono": "figure.strengthtraining.functional",
         "descripcion": "Piernas fuertes y estables para aguantar los km.",
         "ejercicios": [
             {"pesas": "sentadilla-goblet", "maquinas": "prensa-piernas", "casa": "sentadilla", "series": "3 × 8–10"},
             {"pesas": "subida-banco-mancuernas", "maquinas": "zancada-inversa", "casa": "sentadilla-bulgara", "series": "3 × 8 por pierna",
              "nota": "A una pierna: corrige descompensaciones"},
             {"pesas": "peso-muerto-rumano", "maquinas": "curl-femoral", "casa": "puente-una-pierna", "series": "3 × 8–10"},
             {"pesas": "elevacion-gemelos-mancuernas", "maquinas": "gemelos-sentado", "casa": "gemelos-una-pierna", "series": "3 × 12–15",
              "nota": "Baja despacio: protege el tendón de Aquiles"},
             {"pesas": "almeja", "maquinas": "maquina-abductores", "casa": "almeja", "series": "2 × 15 por lado",
              "nota": "Glúteo medio: rodillas estables"},
             {"pesas": "plancha", "maquinas": "plancha", "casa": "plancha", "series": "3 × 30–45 s"},
         ]},
        {"id": "fuerzaB", "nombre": "Fuerza B · Tren superior y core", "icono": "figure.core.training",
         "descripcion": "Brazos y espalda para una buena postura al final de la carrera. Sin pierna.",
         "ejercicios": [
             {"pesas": "remo-mancuerna", "maquinas": "remo-polea-baja", "casa": "remo-toalla", "series": "3 × 10"},
             {"pesas": "press-banca-mancuernas", "maquinas": "press-pecho-maquina", "casa": "flexiones", "series": "3 × 8–12"},
             {"pesas": "pajaros-mancuernas", "maquinas": "face-pull", "casa": "ytw-suelo", "series": "3 × 12",
              "nota": "Hombros atrás: mejor postura al correr"},
             {"pesas": "plancha-lateral", "maquinas": "lenador-polea", "casa": "plancha-lateral", "series": "3 × 30 s por lado"},
             {"pesas": "bird-dog", "maquinas": "bird-dog", "casa": "bird-dog", "series": "2 × 10 por lado"},
             {"pesas": "bicho-muerto", "maquinas": "bicho-muerto", "casa": "bicho-muerto", "series": "2 × 10 por lado"},
         ]},
    ],
}

AVISO = ("Planes y ritmos orientativos. Si empiezas desde cero, tienes más de 40 años con poca actividad, "
         "o alguna enfermedad o lesión, consulta antes con tu médico. Para o baja el ritmo si notas dolor, "
         "mareo o falta de aire anormal.")

REGLAS = [
    "Fases: semanas de afinado según la tabla 'afinado' (como máximo semanas ÷ 4, entero hacia abajo, y mínimo 1; la última es la semana de carrera). Del resto (M): base = máx(1, redondear(M × 0,4)), desarrollo = redondear(M × 0,35), específica = lo que queda.",
    "Redondear = hacia el entero más cercano y los ,5 hacia arriba (Math.round en JavaScript).",
    "Km de la semana más alta = kmPico(distancia) × factorDias. Empieza en ese valor × fraccionInicio y sube en línea recta hasta la última semana antes del afinado, sin pasar de +10 % sobre la semana anterior.",
    "Cada 4.ª semana (si no es la última antes del afinado) es de descarga: × 0,8. Las semanas de afinado son km más altos alcanzados × factores.",
    "Tirada larga = mín(tiradaMaxima(distancia) × km semana ÷ km de la semana más alta, km semana × porcentajeTirada, 180 min al ritmo de tirada larga), como mínimo kmMinimoRodaje. En la semana de carrera la tirada larga se cambia por la carrera.",
    "Sesiones de calidad: se buscan en sesionesCalidad las que encajan con hueco, fase, distancia y nivel, y se toma la número (semana dentro de la fase) % cantidad. calidad2 solo si días ≥ segundaCalidadDesdeDias; si no, o si no hay ninguna, pasa a rodaje suave. En la semana de carrera calidad2 es rodaje suave.",
    "Rodajes suaves = (km semana − tirada larga − sesiones de calidad) ÷ número de rodajes, como mínimo kmMinimoRodaje. En la semana de carrera el sábado se limita a 4 km.",
    "Correr y caminar (nivel cero): las primeras R semanas, R = mín(pasos, M). El paso de la semana s (empezando en 0) es redondear(s × (pasos − 1) ÷ (R − 1)). Todas las salidas son de correr y caminar; la del domingo con veces × 1,25 (hacia arriba).",
    "Km redondeados a 0,5. Fuerza A y B desaparecen en la semana de carrera.",
]

DATOS = {
    "version": 1,
    "aviso": AVISO,
    "riegel": 1.06,
    "deslizador": DESLIZADOR,
    "semanas": SEMANAS,
    "distancias": DISTANCIAS,
    "niveles": NIVELES,
    "factorDias": FACTOR_DIAS,
    "porcentajeTirada": PORCENTAJE_TIRADA,
    "progresion": PROGRESION,
    "afinado": AFINADO,
    "repartoFases": REPARTO_FASES,
    "fases": FASES,
    "zonas": ZONAS,
    "tipos": TIPOS,
    "sesionesCalidad": SES,
    "correrCaminar": CORRER_CAMINAR,
    "plantillas": PLANTILLAS,
    "calentamiento": CALENTAMIENTO,
    "estiramientosAntes": ESTIRAMIENTOS_ANTES,
    "estiramientosDespues": ESTIRAMIENTOS_DESPUES,
    "consejos": CONSEJOS,
    "fuerza": FUERZA,
    "reglas": REGLAS,
}


def comprobar(ruta_ejercicios):
    """Comprueba que los ejercicios de fuerza existen en ejercicios.json."""
    if not os.path.exists(ruta_ejercicios):
        print("Aviso: no encuentro", ruta_ejercicios, "(no compruebo los id)")
        return
    ids = {e["id"] for e in json.load(open(ruta_ejercicios, encoding="utf-8"))}
    faltan = []
    for s in FUERZA["sesiones"]:
        for e in s["ejercicios"]:
            for lugar in ("pesas", "maquinas", "casa"):
                if e[lugar] not in ids:
                    faltan.append(e[lugar])
    if faltan:
        sys.exit("No existen en ejercicios.json: " + ", ".join(sorted(set(faltan))))
    zonas = {z["id"] for z in ZONAS}
    for s in SES:
        assert s["zona"] in zonas, s["id"]
    for d, semana in PLANTILLAS.items():
        assert len(semana) == 7, d
        corre = sum(1 for dia in semana for h in dia if h.rstrip("?") in ("suave", "calidad1", "calidad2", "larga"))
        assert corre == int(d), (d, corre)
        assert sum(1 for dia in semana for h in dia if h.rstrip("?") == "fuerzaA") <= 1, d


if __name__ == "__main__":
    salida = sys.argv[1] if len(sys.argv) > 1 else "GymApp/correr.json"
    comprobar(os.path.join(os.path.dirname(salida) or ".", "ejercicios.json"))
    with open(salida, "w", encoding="utf-8") as f:
        json.dump(DATOS, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print("Guardado", salida, "·", len(SES), "sesiones de calidad")
