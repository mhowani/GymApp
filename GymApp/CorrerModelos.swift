import Foundation

// MARK: - Datos de correr.json (los mismos que usará la web)

struct DatosCorrer: Decodable {
    let version: Int
    let aviso: String
    /// Exponente de la fórmula de Riegel (T2 = T1 × (D2 / D1) ^ riegel)
    let riegel: Double
    let deslizador: RangoDeslizador
    let semanas: RangoSemanas
    let distancias: [DistanciaCarrera]
    let niveles: [NivelCorredor]
    let factorDias: [String: Double]
    let porcentajeTirada: [String: Double]
    let progresion: ParametrosProgresion
    let afinado: [TramoAfinado]
    let repartoFases: RepartoFases
    let fases: [FaseCorrer]
    let zonas: [ZonaRitmo]
    let tipos: [TipoSesionCorrer]
    let sesionesCalidad: [SesionCalidad]
    let correrCaminar: [PasoCorrerCaminar]
    let plantillas: [String: [[String]]]
    let calentamiento: [PasoConsejo]
    let estiramientosAntes: [PasoConsejo]
    let estiramientosDespues: [PasoConsejo]
    let consejos: [String]
    let fuerza: FuerzaCorredor
}

struct RangoDeslizador: Decodable {
    let min: Double
    let max: Double
    let paso: Double
    /// Si la barra queda a menos de estos km de una distancia rápida, se pega a ella
    let imanKm: Double
}

struct RangoSemanas: Decodable {
    let min: Int
    let max: Int
}

struct DistanciaCarrera: Decodable, Identifiable, Hashable {
    let id: String
    let nombre: String
    let km: Double
    let icono: String
}

struct NivelCorredor: Decodable, Identifiable, Hashable {
    let id: String
    let nombre: String
    let icono: String
    let descripcion: String
    let diasMin: Int
    let diasMax: Int
    let diasPorDefecto: Int
    /// Segundos por km del rodaje suave si no hay tiempo de referencia
    let ritmoSuavePorDefecto: Double
    // Tablas [km de la carrera, valor]
    let kmPico: [[Double]]
    let tiradaMaxima: [[Double]]
    let semanasMinimas: [[Double]]
    let semanasRecomendadas: [[Double]]
    let fraccionInicio: Double
    let kmMinimoRodaje: Double
    let calentamientoKm: Double
    let enfriamientoKm: Double
    let segundaCalidadDesdeDias: Int
    let correrCaminar: Bool
}

struct ParametrosProgresion: Decodable {
    let subidaMaximaSemanal: Double
    let descargaCada: Int
    let factorDescarga: Double
    let tiradaMaximaMinutos: Double
    let redondeoKm: Double
    let factorLargaCorrerCaminar: Double
    let ritmoCorrerCaminar: Double
    let ritmoCalidad: Double
}

struct TramoAfinado: Decodable {
    let desdeKm: Double
    let semanas: Int
    let factores: [Double]
}

struct RepartoFases: Decodable {
    let base: Double
    let desarrollo: Double
}

struct FaseCorrer: Decodable, Identifiable, Hashable {
    let id: String
    let nombre: String
    let color: String
    let descripcion: String
}

struct ZonaRitmo: Decodable, Identifiable, Hashable {
    let id: String
    let nombre: String
    /// 0 = la distancia objetivo
    let referenciaKm: Double
    let factorMin: Double
    let factorMax: Double
    let sensacion: String
    let color: String
}

struct TipoSesionCorrer: Decodable, Identifiable, Hashable {
    let id: String
    let nombre: String
    let icono: String
    let emoji: String
    let color: String
    let descripcion: String
}

struct VarianteCalidad: Decodable, Hashable {
    let texto: String
    let km: Double
}

struct SesionCalidad: Decodable, Identifiable, Hashable {
    let id: String
    let nombre: String
    /// "calidad1", "calidad2" o "ambos"
    let hueco: String
    let fases: [String]
    let distanciaMin: Double
    let distanciaMax: Double
    let zona: String
    let conCalentamiento: Bool
    let niveles: [String: VarianteCalidad]
}

struct PasoCorrerCaminar: Decodable, Hashable {
    /// Minutos corriendo
    let correr: Double
    /// Minutos caminando (0 = correr seguido)
    let caminar: Double
    let veces: Int
}

struct PasoConsejo: Decodable, Hashable, Identifiable {
    let nombre: String
    let detalle: String
    var id: String { nombre }
}

struct FuerzaCorredor: Decodable {
    let descripcion: String
    let reglas: [String]
    let sesiones: [SesionFuerza]
}

struct SesionFuerza: Decodable, Identifiable, Hashable {
    let id: String
    let nombre: String
    let icono: String
    let descripcion: String
    let ejercicios: [EjercicioFuerza]
}

struct EjercicioFuerza: Decodable, Hashable {
    let pesas: String
    let maquinas: String
    let casa: String
    let series: String
    let nota: String?

    func id(para lugar: Lugar) -> String {
        switch lugar {
        case .pesas: return pesas
        case .maquinas: return maquinas
        case .casa: return casa
        }
    }

    /// Ejercicio de ejercicios.json para el lugar elegido
    func ejercicio(para lugar: Lugar) -> Ejercicio? {
        let buscado = id(para: lugar)
        return Catalogo.ejercicios.first { $0.id == buscado }
    }
}

enum CatalogoCorrer {
    static let datos: DatosCorrer? = {
        guard let url = Bundle.main.url(forResource: "correr", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try JSONDecoder().decode(DatosCorrer.self, from: data)
        } catch {
            print("Error leyendo correr.json: \(error)")
            return nil
        }
    }()
}

extension DatosCorrer {
    func fase(_ id: String) -> FaseCorrer? { fases.first { $0.id == id } }
    func zona(_ id: String) -> ZonaRitmo? { zonas.first { $0.id == id } }
    func tipo(_ id: String) -> TipoSesionCorrer? { tipos.first { $0.id == id } }
    func sesionFuerza(_ id: String) -> SesionFuerza? { fuerza.sesiones.first { $0.id == id } }

    /// Nombre de la distancia ("Media maratón") o "12,5 km"
    func nombreDistancia(_ km: Double) -> String {
        if let d = distancias.first(where: { abs($0.km - km) < 0.05 }) { return d.nombre }
        return Formato.km(km)
    }

    /// Pega la barra a 5, 10, 21,1 o 42,2 km si está cerca; si no, redondea a 0,5 km
    func ajustarDistancia(_ km: Double) -> Double {
        for d in distancias where abs(d.km - km) <= deslizador.imanKm {
            return d.km
        }
        let paso = deslizador.paso > 0 ? deslizador.paso : 0.5
        let valor = (km / paso).rounded() * paso
        return Swift.min(Swift.max(valor, deslizador.min), deslizador.max)
    }
}

// MARK: - Calculadora de ritmo (fórmula de Riegel)

/// Un tiempo reciente: por ejemplo 10 km en 52:30
struct TiempoReferencia: Hashable {
    let km: Double
    let segundos: Double
}

enum CalculadoraRitmo {
    /// Tiempo estimado en otra distancia
    static func prediccion(_ ref: TiempoReferencia, km: Double, exponente: Double) -> Double {
        guard ref.km > 0, km > 0 else { return 0 }
        return ref.segundos * pow(km / ref.km, exponente)
    }

    /// Segundos por kilómetro
    static func ritmo(segundos: Double, km: Double) -> Double {
        km > 0 ? segundos / km : 0
    }

    /// Velocidad en km/h
    static func velocidad(segundos: Double, km: Double) -> Double {
        segundos > 0 ? km / (segundos / 3600) : 0
    }

    /// Ritmos (rápido, lento) de una zona, en segundos por km
    static func rango(_ zona: ZonaRitmo, ref: TiempoReferencia, objetivoKm: Double,
                      exponente: Double) -> (rapido: Double, lento: Double) {
        let km = zona.referenciaKm > 0 ? zona.referenciaKm : objetivoKm
        let ritmoBase = ritmo(segundos: prediccion(ref, km: km, exponente: exponente), km: km)
        return (ritmoBase * zona.factorMin, ritmoBase * zona.factorMax)
    }

    static func ritmoMedio(_ zona: ZonaRitmo, ref: TiempoReferencia, objetivoKm: Double,
                           exponente: Double) -> Double {
        let r = rango(zona, ref: ref, objetivoKm: objetivoKm, exponente: exponente)
        return (r.rapido + r.lento) / 2
    }
}

// MARK: - El plan que se muestra

struct SesionPlan: Identifiable, Hashable {
    /// "semana-día-orden", sirve para marcarla como hecha
    let id: String
    /// suave, calidad, larga, correrCaminar, carrera, fuerza, descanso
    let tipo: String
    let titulo: String
    let detalle: String
    let km: Double
    let minutos: Int
    let zona: String?
    let opcional: Bool
    /// fuerzaA o fuerzaB
    let fuerza: String?
    let nota: String?

    var esCarrera: Bool { tipo != "fuerza" && tipo != "descanso" }
    var sePuedeMarcar: Bool { tipo != "descanso" }
}

struct DiaPlanCorrer: Identifiable, Hashable {
    /// 0 = lunes … 6 = domingo
    let id: Int
    let fecha: Date
    let sesiones: [SesionPlan]

    static let nombres = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
    static let cortos = ["L", "M", "X", "J", "V", "S", "D"]
    var nombre: String { DiaPlanCorrer.nombres[id] }
}

struct SemanaPlanCorrer: Identifiable, Hashable {
    /// 1, 2, 3…
    let id: Int
    let fase: FaseCorrer
    let inicio: Date
    let dias: [DiaPlanCorrer]
    let descarga: Bool
    let correrCaminar: Bool

    var km: Double {
        var suma: Double = 0
        for dia in dias {
            for sesion in dia.sesiones { suma += sesion.km }
        }
        return suma
    }

    var minutos: Int {
        var suma = 0
        for dia in dias {
            for sesion in dia.sesiones where sesion.esCarrera { suma += sesion.minutos }
        }
        return suma
    }
    var fin: Date { Calendar.current.date(byAdding: .day, value: 6, to: inicio) ?? inicio }
}

struct PlanCorrer {
    let semanas: [SemanaPlanCorrer]
    let kmSemanaMaxima: Double
    let tiradaMasLarga: Double
    let kmTotales: Double
    let semanasMinimas: Int
    let semanasRecomendadas: Int
    let avisos: [String]
    let fechaCarrera: Date
}

struct OpcionesPlan {
    var distanciaKm: Double
    var nivel: NivelCorredor
    var dias: Int
    var semanas: Int
    /// Lunes de la primera semana
    var inicio: Date
    var referencia: TiempoReferencia?
}

// MARK: - Generador de planes

/// Lo que toca en un hueco de la plantilla de la semana
private enum HuecoPlan {
    case suave
    case calidad(SesionCalidad, Double)
    case larga(Double)
    case carrera
    case cc(larga: Bool)
    case fuerza(String)
    case descanso
}
// Sigue las reglas que hay al final de correr.json (la web hace lo mismo).

enum GeneradorCorrer {
    /// Redondeo "normal": al más cercano y los ,5 hacia arriba (como Math.round en JavaScript)
    static func redondear(_ x: Double) -> Int { Int((x + 0.5).rounded(.down)) }

    static func redondearKm(_ x: Double, _ paso: Double) -> Double {
        guard paso > 0 else { return x }
        return Double(redondear(x / paso)) * paso
    }

    /// Interpola en una tabla [[km, valor], …]
    static func interpolar(_ tabla: [[Double]], _ x: Double) -> Double {
        let puntos = tabla.filter { $0.count >= 2 }.sorted { $0[0] < $1[0] }
        guard let primero = puntos.first, let ultimo = puntos.last else { return 0 }
        if x <= primero[0] { return primero[1] }
        if x >= ultimo[0] { return ultimo[1] }
        for i in 1..<puntos.count where x <= puntos[i][0] {
            let a = puntos[i - 1], b = puntos[i]
            let t = (x - a[0]) / (b[0] - a[0])
            return a[1] + (b[1] - a[1]) * t
        }
        return ultimo[1]
    }

    static func semanasMinimas(_ nivel: NivelCorredor, km: Double) -> Int {
        Int(interpolar(nivel.semanasMinimas, km).rounded(.up))
    }

    static func semanasRecomendadas(_ nivel: NivelCorredor, km: Double) -> Int {
        Int(interpolar(nivel.semanasRecomendadas, km).rounded(.up))
    }

    /// Lunes de la semana de una fecha
    static func lunes(de fecha: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        cal.minimumDaysInFirstWeek = 4
        let partes = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: fecha)
        return cal.date(from: partes) ?? cal.startOfDay(for: fecha)
    }

    /// Lunes de esta semana si hoy es de lunes a miércoles; si no, el lunes que viene
    static func inicioPorDefecto(hoy: Date = Date()) -> Date {
        let indice = (Calendar(identifier: .gregorian).component(.weekday, from: hoy) + 5) % 7
        let esteLunes = lunes(de: hoy)
        if indice <= 2 { return esteLunes }
        return Calendar.current.date(byAdding: .day, value: 7, to: esteLunes) ?? esteLunes
    }

    static func plan(_ op: OpcionesPlan, _ datos: DatosCorrer) -> PlanCorrer {
        let nivel = op.nivel
        let pr = datos.progresion
        let km = op.distanciaKm
        let n = max(op.semanas, 1)
        let dias = min(max(op.dias, nivel.diasMin), nivel.diasMax)
        let claveDias = String(dias)
        let cal = Calendar.current

        // Ritmos para estimar la duración
        let zonaSuave = datos.zona("suave")
        let zonaLarga = datos.zona("larga")
        var ritmoSuave = nivel.ritmoSuavePorDefecto
        var ritmoLarga = nivel.ritmoSuavePorDefecto
        if let ref = op.referencia {
            if let z = zonaSuave { ritmoSuave = CalculadoraRitmo.ritmoMedio(z, ref: ref, objetivoKm: km, exponente: datos.riegel) }
            if let z = zonaLarga { ritmoLarga = CalculadoraRitmo.ritmoMedio(z, ref: ref, objetivoKm: km, exponente: datos.riegel) }
        }
        func minutos(_ kms: Double, _ ritmo: Double) -> Int { redondear(kms * ritmo / 60) }

        // 1. Fases
        let tramo = datos.afinado.last { km >= $0.desdeKm } ?? TramoAfinado(desdeKm: 0, semanas: 1, factores: [0.5])
        let semanasAfinado = min(tramo.semanas, max(1, n / 4), n)
        let m = n - semanasAfinado
        let base = m > 0 ? max(1, redondear(Double(m) * datos.repartoFases.base)) : 0
        var desarrollo = redondear(Double(m) * datos.repartoFases.desarrollo)
        if m - base - desarrollo < 0 { desarrollo = max(0, m - base) }

        func faseDe(_ w: Int) -> (id: String, inicio: Int) {
            if w == n - 1 { return ("carrera", n - 1) }
            if w >= m { return ("afinado", m) }
            if w < base { return ("base", 0) }
            if w < base + desarrollo { return ("desarrollo", base) }
            return ("especifica", base + desarrollo)
        }

        // 2. Km de cada semana
        let kmPico = interpolar(nivel.kmPico, km) * (datos.factorDias[claveDias] ?? 1)
        let kmInicio = kmPico * nivel.fraccionInicio
        var volumen = [Double](repeating: 0, count: n)
        var descarga = [Bool](repeating: false, count: n)
        var alcanzado = kmInicio
        for w in 0..<m {
            let objetivo = m > 1 ? kmInicio + (kmPico - kmInicio) * Double(w) / Double(m - 1) : kmInicio
            let semana = w == 0 ? kmInicio : min(objetivo, alcanzado * (1 + pr.subidaMaximaSemanal))
            alcanzado = semana
            let esDescarga = pr.descargaCada > 0 && (w + 1) % pr.descargaCada == 0 && w < m - 1
            descarga[w] = esDescarga
            volumen[w] = esDescarga ? semana * pr.factorDescarga : semana
        }
        let factores = Array(tramo.factores.suffix(semanasAfinado))
        for k in 0..<semanasAfinado {
            let factor = k < factores.count ? factores[k] : 0.5
            volumen[m + k] = alcanzado * factor
        }

        // 3. Tirada larga máxima
        let tiradaTabla = interpolar(nivel.tiradaMaxima, km)
        let tiradaPorTiempo = ritmoLarga > 0 ? pr.tiradaMaximaMinutos * 60 / ritmoLarga : tiradaTabla
        let porcentaje = datos.porcentajeTirada[claveDias] ?? 0.4

        // 4. Correr y caminar (solo «Empezar desde cero»)
        let pasos = datos.correrCaminar
        let semanasCC = nivel.correrCaminar ? min(pasos.count, m) : 0

        let plantilla = datos.plantillas[claveDias] ?? []
        let faseVacia = FaseCorrer(id: "base", nombre: "Base", color: "celeste", descripcion: "")
        var semanas: [SemanaPlanCorrer] = []

        for w in 0..<n {
            let (faseId, faseInicio) = faseDe(w)
            let fase = datos.fase(faseId) ?? faseVacia
            let final = w == n - 1
            let inicioSemana = cal.date(byAdding: .day, value: 7 * w, to: op.inicio) ?? op.inicio
            let numeroEnFase = w - faseInicio

            // Paso de correr y caminar de esta semana
            var paso: PasoCorrerCaminar? = nil
            if w < semanasCC, !pasos.isEmpty {
                let indice = semanasCC == 1 ? pasos.count - 1
                    : redondear(Double(w) * Double(pasos.count - 1) / Double(semanasCC - 1))
                paso = pasos[min(max(indice, 0), pasos.count - 1)]
            }

            // Primera pasada: qué toca cada día
            var huecos: [[(HuecoPlan, Bool)]] = []
            var kmCalidad: Double = 0
            var kmLarga: Double = 0
            var rodajes = 0

            for (i, dia) in plantilla.enumerated() where i < 7 {
                var lista: [(HuecoPlan, Bool)] = []
                for texto in dia {
                    let opcional = texto.hasSuffix("?")
                    let clave = opcional ? String(texto.dropLast()) : texto
                    switch clave {
                    case "fuerzaA", "fuerzaB":
                        lista.append(final ? (HuecoPlan.descanso, false) : (HuecoPlan.fuerza(clave), opcional))
                    case "larga":
                        if final {
                            lista.append((HuecoPlan.carrera, false))
                        } else if paso != nil {
                            lista.append((.cc(larga: true), opcional))
                        } else {
                            let porVolumen: Double = tiradaTabla * volumen[w] / max(kmPico, 1)
                            let porSemana: Double = volumen[w] * porcentaje
                            let tirada: Double = min(min(porVolumen, porSemana), tiradaPorTiempo)
                            let valor = redondearKm(max(tirada, nivel.kmMinimoRodaje), pr.redondeoKm)
                            kmLarga += valor
                            lista.append((.larga(valor), opcional))
                        }
                    case "calidad1", "calidad2", "suave":
                        if paso != nil {
                            lista.append((.cc(larga: false), opcional))
                            continue
                        }
                        var elegida: SesionCalidad? = nil
                        let puedeCalidad2 = clave == "calidad2" && !final && dias >= nivel.segundaCalidadDesdeDias
                        if clave == "calidad1" || puedeCalidad2 {
                            let candidatas = datos.sesionesCalidad.filter {
                                ($0.hueco == clave || $0.hueco == "ambos")
                                    && $0.fases.contains(faseId)
                                    && km >= $0.distanciaMin && km <= $0.distanciaMax
                                    && $0.niveles[nivel.id] != nil
                            }
                            if !candidatas.isEmpty {
                                elegida = candidatas[numeroEnFase % candidatas.count]
                            }
                        }
                        if let s = elegida, let v = s.niveles[nivel.id] {
                            let extra = s.conCalentamiento ? nivel.calentamientoKm + nivel.enfriamientoKm : 0
                            let total = redondearKm(v.km + extra, pr.redondeoKm)
                            kmCalidad += total
                            lista.append((.calidad(s, total), opcional))
                        } else {
                            rodajes += 1
                            lista.append((.suave, opcional))
                        }
                    default:
                        lista.append((.descanso, false))
                    }
                }
                huecos.append(lista)
            }

            let resto = volumen[w] - kmLarga - kmCalidad
            let kmRodaje = rodajes > 0
                ? redondearKm(max(nivel.kmMinimoRodaje, resto / Double(rodajes)), pr.redondeoKm) : 0

            // Segunda pasada: textos, km y minutos
            var diasPlan: [DiaPlanCorrer] = []
            for i in 0..<7 {
                let fecha = cal.date(byAdding: .day, value: i, to: inicioSemana) ?? inicioSemana
                let lista = i < huecos.count ? huecos[i] : [(HuecoPlan.descanso, false)]
                var sesiones: [SesionPlan] = []
                for (orden, (hueco, opcional)) in lista.enumerated() {
                    let id = "\(w + 1)-\(i)-\(orden)"
                    switch hueco {
                    case .descanso:
                        let nota = final && i < 6 ? "Semana de carrera: descansa bien y duerme mucho." : nil
                        sesiones.append(SesionPlan(id: id, tipo: "descanso", titulo: "Descanso",
                                                   detalle: "Puedes caminar o estirar suave.",
                                                   km: 0, minutos: 0, zona: nil, opcional: false,
                                                   fuerza: nil, nota: nota))
                    case .fuerza(let clave):
                        let s = datos.sesionFuerza(clave)
                        var nota: String? = nil
                        if faseId == "afinado" { nota = "Semana de afinado: haz la mitad de series." }
                        else if opcional { nota = "Opcional: hazla solo si te encuentras fresco." }
                        sesiones.append(SesionPlan(id: id, tipo: "fuerza", titulo: s?.nombre ?? "Fuerza",
                                                   detalle: s?.descripcion ?? "",
                                                   km: 0, minutos: 35, zona: nil, opcional: opcional,
                                                   fuerza: clave, nota: nota))
                    case .suave:
                        var kms = kmRodaje
                        var titulo = "Rodaje suave"
                        var detalle = "\(Formato.km(kms)) a ritmo cómodo; deberías poder hablar."
                        if final && i == 5 {
                            kms = min(kmRodaje, 4)
                            titulo = "Trote de activación"
                            detalle = "\(Formato.km(kms)) muy suaves para soltar las piernas antes de la carrera."
                        } else if i == 0 {
                            titulo = "Rodaje de recuperación"
                            detalle = "\(Formato.km(kms)) muy suaves después de la tirada larga."
                        }
                        sesiones.append(SesionPlan(id: id, tipo: "suave", titulo: titulo, detalle: detalle,
                                                   km: kms, minutos: minutos(kms, ritmoSuave), zona: "suave",
                                                   opcional: opcional, fuerza: nil, nota: nil))
                    case .calidad(let s, let total):
                        let v = s.niveles[nivel.id]
                        var detalle = v?.texto ?? s.nombre
                        if s.conCalentamiento {
                            let calentar: String = Formato.km(nivel.calentamientoKm)
                            let enfriar: String = Formato.km(nivel.enfriamientoKm)
                            detalle = "Calienta \(calentar) suaves · \(detalle) · Termina con \(enfriar) suaves."
                        }
                        sesiones.append(SesionPlan(id: id, tipo: "calidad", titulo: s.nombre, detalle: detalle,
                                                   km: total, minutos: minutos(total, ritmoSuave * pr.ritmoCalidad),
                                                   zona: s.zona, opcional: opcional, fuerza: nil, nota: nil))
                    case .larga(let kms):
                        var detalle = "\(Formato.km(kms)) a ritmo cómodo y constante. Bebe agua si pasa de 1 hora."
                        if faseId == "especifica" && km > 15 && !nivel.correrCaminar && numeroEnFase % 2 == 1 {
                            let finalRapido = min(Double(redondear(km * 0.25)), 8)
                            detalle = "\(Formato.km(kms)) a ritmo cómodo; los últimos \(Formato.km(finalRapido)) a ritmo de carrera."
                        }
                        sesiones.append(SesionPlan(id: id, tipo: "larga", titulo: "Tirada larga", detalle: detalle,
                                                   km: kms, minutos: minutos(kms, ritmoLarga), zona: "larga",
                                                   opcional: opcional, fuerza: nil, nota: nil))
                    case .carrera:
                        sesiones.append(SesionPlan(id: id, tipo: "carrera",
                                                   titulo: "¡Carrera! " + datos.nombreDistancia(km),
                                                   detalle: "Calienta 10 min, sal algo más lento los primeros km y acelera solo si vas bien. ¡A disfrutar!",
                                                   km: km, minutos: 0, zona: "carrera", opcional: false,
                                                   fuerza: nil, nota: nil))
                    case .cc(let larga):
                        guard let p = paso else { continue }
                        var veces = p.veces
                        var correr = p.correr
                        if larga {
                            if p.caminar > 0 {
                                veces = Int((Double(p.veces) * pr.factorLargaCorrerCaminar).rounded(.up))
                            } else {
                                correr = (p.correr * pr.factorLargaCorrerCaminar / 5).rounded(.up) * 5
                            }
                        }
                        let total = Double(veces) * (correr + p.caminar)
                        let detalle: String
                        if p.caminar > 0 {
                            detalle = "\(veces) × (\(Formato.numero(correr, decimales: 1)) min corriendo suave + \(Formato.numero(p.caminar, decimales: 1)) min caminando). Empieza y termina con 5 min caminando."
                        } else {
                            detalle = "\(Formato.numero(correr)) min corriendo suave sin parar. Empieza y termina con 5 min caminando."
                        }
                        let ritmo = ritmoSuave * pr.ritmoCorrerCaminar
                        let kms = ritmo > 0 ? redondearKm(total * 60 / ritmo, pr.redondeoKm) : 0
                        sesiones.append(SesionPlan(id: id, tipo: "correrCaminar",
                                                   titulo: larga ? "Salida larga: correr y caminar" : "Correr y caminar",
                                                   detalle: detalle, km: kms, minutos: redondear(total), zona: "suave",
                                                   opcional: opcional, fuerza: nil, nota: nil))
                    }
                }
                diasPlan.append(DiaPlanCorrer(id: i, fecha: fecha, sesiones: sesiones))
            }

            semanas.append(SemanaPlanCorrer(id: w + 1, fase: fase, inicio: inicioSemana, dias: diasPlan,
                                            descarga: descarga[w], correrCaminar: paso != nil))
        }

        // Resumen y avisos
        var kmMaximo: Double = 0
        var tirada: Double = 0
        var total: Double = 0
        for semana in semanas {
            let kmSemana: Double = semana.km
            total += kmSemana
            kmMaximo = max(kmMaximo, kmSemana)
            for dia in semana.dias {
                for sesion in dia.sesiones where sesion.tipo == "larga" || sesion.tipo == "correrCaminar" {
                    tirada = max(tirada, sesion.km)
                }
            }
        }
        let minimas = semanasMinimas(nivel, km: km)
        let recomendadas = semanasRecomendadas(nivel, km: km)

        var avisos: [String] = []
        if n < minimas {
            avisos.append("Con \(n) semanas el plan es muy justo: para \(datos.nombreDistancia(km)) en nivel «\(nivel.nombre)» lo prudente son al menos \(minimas) semanas (mejor \(recomendadas)).")
        }
        if nivel.correrCaminar && km > 21.2 {
            avisos.append("Desde cero lo prudente es preparar antes un 10 km o una media maratón y dejar la maratón para la temporada siguiente.")
        }
        if m > 0 && alcanzado < kmPico * 0.9 {
            avisos.append("Con tan pocas semanas no da tiempo a llegar a los km ideales (unos \(Formato.km(kmPico)) a la semana): el plan sube como máximo un \(Formato.numero(pr.subidaMaximaSemanal * 100)) % por semana.")
        }
        if nivel.correrCaminar && semanasCC == m && m < pasos.count {
            avisos.append("Con estas semanas no se completan todos los pasos de correr y caminar: si el día de la carrera necesitas caminar un poco, hazlo sin problema.")
        }

        let carrera = cal.date(byAdding: .day, value: 7 * n - 1, to: op.inicio) ?? op.inicio
        return PlanCorrer(semanas: semanas, kmSemanaMaxima: kmMaximo, tiradaMasLarga: tirada,
                          kmTotales: total, semanasMinimas: minimas, semanasRecomendadas: recomendadas,
                          avisos: avisos, fechaCarrera: carrera)
    }
}

// MARK: - Textos de ritmos y tiempos

extension Formato {
    static func km(_ valor: Double) -> String { numero(valor, decimales: 1) + " km" }

    /// 332 → "5:32"
    static func minutosSegundos(_ segundos: Double) -> String {
        guard segundos.isFinite, segundos > 0 else { return "–" }
        let total = Int(segundos.rounded())
        return "\(total / 60):" + String(format: "%02d", total % 60)
    }

    /// Ritmo por km: "5:32 /km"
    static func ritmo(_ segundosPorKm: Double) -> String {
        minutosSegundos(segundosPorKm) + " /km"
    }

    /// Tiempo de carrera: "52:30" o "1:52:30"
    static func tiempo(_ segundos: Double) -> String {
        guard segundos.isFinite, segundos > 0 else { return "–" }
        let total = Int(segundos.rounded())
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        if h > 0 { return "\(h):" + String(format: "%02d:%02d", m, s) }
        return "\(m):" + String(format: "%02d", s)
    }

    /// Duración aproximada: "45 min" o "1 h 20 min"
    static func duracion(_ minutos: Int) -> String {
        guard minutos > 0 else { return "" }
        if minutos < 60 { return "\(minutos) min" }
        let h = minutos / 60, m = minutos % 60
        return m == 0 ? "\(h) h" : "\(h) h \(m) min"
    }
}
