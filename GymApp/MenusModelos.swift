import Foundation

// MARK: - Datos de menus.json (los mismos que usará la web)

struct DatosMenus: Decodable {
    let version: Int
    let aviso: String
    let calculo: ParametrosCalculo
    let objetivos: [ObjetivoNutricion]
    let actividad: [NivelActividad]
    let comidas: [TipoComida]
    let ingredientes: [Ingrediente]
    let platos: [Plato]
}

struct ParametrosCalculo: Decodable {
    let formula: String
    /// Se suma al factor de actividad por cada día de entrenamiento a la semana
    let factorPorDiaEntreno: Double
    /// Diferencia de calorías entre días de entreno y de descanso (0,10 = 10 %)
    let variacionDiaEntreno: Double
    let minimoKcalMujer: Double
    let minimoKcalHombre: Double
    /// Límites para agrandar o achicar las raciones de un plato
    let escalaMinima: Double
    let escalaMaxima: Double
}

struct ObjetivoNutricion: Decodable, Identifiable, Hashable {
    let id: String
    let nombre: String
    let icono: String
    let descripcion: String
    let ajusteCalorias: Double
    let proteinaPorKg: Double
    let grasaPorcentaje: Double
    /// "proteina", "hidratos" o "equilibrado": qué platos se eligen primero
    let preferencia: String
    let consejos: [String]
}

struct NivelActividad: Decodable, Identifiable, Hashable {
    let id: String
    let nombre: String
    let descripcion: String
    let factor: Double
}

struct TipoComida: Decodable, Identifiable, Hashable {
    let id: String
    let nombre: String
    let icono: String
    let porcentaje: Double
}

struct Ingrediente: Decodable, Identifiable, Hashable {
    let id: String
    let nombre: String
    let seccion: String
    /// "g" o "ml"
    let unidad: String
    // Valores por 100 g o 100 ml
    let kcal: Double
    let proteinas: Double
    let hidratos: Double
    let grasas: Double
    let vegetariano: Bool
    let gluten: Bool
    let lactosa: Bool
    /// Peso de una unidad (un huevo, una manzana…), si tiene sentido contarlo
    let pesoUnidad: Double?
    let nombreUnidad: String?
    /// Ingrediente que lo sustituye cuando se pide sin gluten o sin lactosa
    let sinGluten: String?
    let sinLactosa: String?
}

struct CantidadIngrediente: Decodable, Hashable {
    let id: String
    let cantidad: Double
}

struct Plato: Decodable, Identifiable, Hashable {
    let id: String
    let nombre: String
    let comidas: [String]
    let minutos: Int
    let preparacion: String
    let ingredientes: [CantidadIngrediente]
}

enum CatalogoMenus {
    static let datos: DatosMenus? = {
        guard let url = Bundle.main.url(forResource: "menus", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try JSONDecoder().decode(DatosMenus.self, from: data)
        } catch {
            print("Error leyendo menus.json: \(error)")
            return nil
        }
    }()

    static let ingredientes: [String: Ingrediente] = {
        var d: [String: Ingrediente] = [:]
        for i in datos?.ingredientes ?? [] { d[i.id] = i }
        return d
    }()

    /// Orden de las secciones de la lista de la compra (el del JSON)
    static let secciones: [String] = {
        var lista: [String] = []
        for i in datos?.ingredientes ?? [] where !lista.contains(i.seccion) {
            lista.append(i.seccion)
        }
        return lista
    }()
}

// MARK: - Filtros de dieta (se pueden combinar)

struct FiltrosDieta: Hashable {
    var vegetariano = false
    var sinGluten = false
    var sinLactosa = false
}

// MARK: - Calorías y nutrientes

struct Macros: Hashable {
    var kcal: Double = 0
    var proteinas: Double = 0
    var hidratos: Double = 0
    var grasas: Double = 0

    static func + (a: Macros, b: Macros) -> Macros {
        Macros(kcal: a.kcal + b.kcal, proteinas: a.proteinas + b.proteinas,
               hidratos: a.hidratos + b.hidratos, grasas: a.grasas + b.grasas)
    }
}

/// Un ingrediente con su cantidad (ya cambiado por la versión sin gluten o sin lactosa si hace falta)
struct LineaIngrediente: Identifiable, Hashable {
    let ingrediente: Ingrediente
    let cantidad: Double
    var id: String { ingrediente.id }

    var macros: Macros {
        let f = cantidad / 100
        return Macros(kcal: ingrediente.kcal * f, proteinas: ingrediente.proteinas * f,
                      hidratos: ingrediente.hidratos * f, grasas: ingrediente.grasas * f)
    }

    func escalada(_ factor: Double) -> LineaIngrediente {
        LineaIngrediente(ingrediente: ingrediente, cantidad: cantidad * factor)
    }
}

extension Array where Element == LineaIngrediente {
    var macros: Macros { reduce(Macros()) { $0 + $1.macros } }
}

// MARK: - Datos de la persona

enum Sexo: String, CaseIterable, Identifiable {
    case hombre, mujer
    var id: String { rawValue }
    var nombre: String { self == .hombre ? "Hombre" : "Mujer" }
}

struct PerfilNutricion {
    var sexo: Sexo
    var edad: Int
    var peso: Double
    var altura: Double
    var actividad: NivelActividad
    var diasEntreno: Int
    var objetivo: ObjetivoNutricion
}

struct Necesidades {
    /// Metabolismo basal (lo que gasta el cuerpo en reposo)
    let basal: Double
    /// Calorías para mantener el peso
    let mantenimiento: Double
    /// Calorías medias al día según el objetivo
    let kcal: Double
    let kcalEntreno: Double
    let kcalDescanso: Double
    let proteinas: Double
    let grasas: Double
    let hidratos: Double
    /// true si se han subido las calorías al mínimo recomendado
    let ajustadoAlMinimo: Bool
}

enum CalculadoraNutricion {
    static func calcular(_ p: PerfilNutricion, _ c: ParametrosCalculo) -> Necesidades {
        let peso = min(max(p.peso, 35), 250)
        let altura = min(max(p.altura, 120), 230)
        let edad = Double(min(max(p.edad, 18), 100))
        let dias = min(max(p.diasEntreno, 0), 7)

        // Fórmula de Mifflin-St Jeor
        let basal = 10 * peso + 6.25 * altura - 5 * edad + (p.sexo == .hombre ? 5 : -161)
        let factor = p.actividad.factor + Double(dias) * c.factorPorDiaEntreno
        let mantenimiento = basal * factor

        let minimo = max(p.sexo == .hombre ? c.minimoKcalHombre : c.minimoKcalMujer, basal)
        var kcal = mantenimiento * (1 + p.objetivo.ajusteCalorias)
        var ajustado = false
        if kcal < minimo {
            kcal = minimo
            ajustado = true
        }
        kcal = (kcal / 10).rounded() * 10

        // Días de entreno con algo más de comida y de descanso con algo menos (la media semanal no cambia)
        var entreno = kcal, descanso = kcal
        if dias > 0 && dias < 7 {
            let v = c.variacionDiaEntreno
            entreno = kcal * (1 + v * Double(7 - dias) / 7)
            descanso = max(kcal * (1 - v * Double(dias) / 7), minimo)
        }

        let proteinas = min(peso * p.objetivo.proteinaPorKg, kcal * 0.35 / 4).rounded()
        let grasas = (kcal * p.objetivo.grasaPorcentaje / 9).rounded()
        let hidratos = max(0, (kcal - proteinas * 4 - grasas * 9) / 4).rounded()

        return Necesidades(basal: basal.rounded(), mantenimiento: mantenimiento.rounded(), kcal: kcal,
                           kcalEntreno: (entreno / 10).rounded() * 10, kcalDescanso: (descanso / 10).rounded() * 10,
                           proteinas: proteinas, grasas: grasas, hidratos: hidratos, ajustadoAlMinimo: ajustado)
    }
}

// MARK: - Menú de la semana

struct ComidaMenu: Identifiable, Hashable {
    let tipo: TipoComida
    let plato: Plato
    /// Ingredientes ya ajustados a la ración
    let lineas: [LineaIngrediente]
    let escala: Double
    let macros: Macros
    var id: String { tipo.id }
}

struct DiaMenu: Identifiable, Hashable {
    let indice: Int
    let nombre: String
    let entreno: Bool
    let objetivoKcal: Double
    let comidas: [ComidaMenu]
    var id: Int { indice }
    var macros: Macros { comidas.reduce(Macros()) { $0 + $1.macros } }
}

/// Generador de números aleatorios con semilla: misma semilla = mismo menú
struct AleatorioConSemilla: RandomNumberGenerator {
    private var estado: UInt64
    init(semilla: UInt64) { estado = semilla &+ 0x9E37_79B9_7F4A_7C15 }

    mutating func next() -> UInt64 {
        estado &+= 0x9E37_79B9_7F4A_7C15
        var z = estado
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

enum GeneradorMenus {
    typealias Candidato = (plato: Plato, lineas: [LineaIngrediente])

    static let nombresDias = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
    static let inicialesDias = ["L", "M", "X", "J", "V", "S", "D"]

    /// Días de entreno de la semana (0 = lunes), repartidos con descanso entre medias
    static func diasDeEntreno(_ n: Int) -> Set<Int> {
        switch n {
        case ...0: return []
        case 1: return [0]
        case 2: return [0, 3]
        case 3: return [0, 2, 4]
        case 4: return [0, 1, 3, 4]
        case 5: return [0, 1, 2, 3, 4]
        case 6: return [0, 1, 2, 3, 4, 5]
        default: return Set(0..<7)
        }
    }

    /// Ingredientes del plato con las sustituciones de los filtros. nil si el plato no es apto.
    static func lineas(de plato: Plato, filtros: FiltrosDieta) -> [LineaIngrediente]? {
        var resultado: [LineaIngrediente] = []
        for c in plato.ingredientes {
            guard var ing = CatalogoMenus.ingredientes[c.id] else { return nil }
            if filtros.sinGluten && ing.gluten {
                guard let alt = ing.sinGluten, let nuevo = CatalogoMenus.ingredientes[alt] else { return nil }
                ing = nuevo
            }
            if filtros.sinLactosa && ing.lactosa {
                guard let alt = ing.sinLactosa, let nuevo = CatalogoMenus.ingredientes[alt] else { return nil }
                ing = nuevo
            }
            if filtros.vegetariano && !ing.vegetariano { return nil }
            resultado.append(LineaIngrediente(ingrediente: ing, cantidad: c.cantidad))
        }
        return resultado
    }

    /// Número fijo a partir de un texto (el hashValue de Swift cambia en cada arranque)
    private static func numero(_ texto: String) -> UInt64 {
        var h: UInt64 = 1_469_598_103_934_665_603
        for b in texto.utf8 {
            h = (h ^ UInt64(b)) &* 1_099_511_628_211
        }
        return h
    }

    /// Platos posibles para una comida, en el orden en que se van a usar durante la semana
    static func orden(tipo: TipoComida, filtros: FiltrosDieta, objetivo: ObjetivoNutricion,
                      semilla: Int) -> [Candidato] {
        guard let datos = CatalogoMenus.datos else { return [] }
        var candidatos: [Candidato] = []
        for p in datos.platos where p.comidas.contains(tipo.id) {
            if let l = lineas(de: p, filtros: filtros) { candidatos.append((p, l)) }
        }
        var rng = AleatorioConSemilla(semilla: UInt64(truncatingIfNeeded: semilla) ^ numero(tipo.id + objetivo.id))
        candidatos.shuffle(using: &rng)

        func puntos(_ l: [LineaIngrediente]) -> Double {
            let m = l.macros
            guard m.kcal > 0 else { return 0 }
            switch objetivo.preferencia {
            case "proteina": return m.proteinas * 4 / m.kcal
            case "hidratos": return m.hidratos * 4 / m.kcal
            default: return 0
            }
        }
        guard objetivo.preferencia == "proteina" || objetivo.preferencia == "hidratos",
              candidatos.count > 7 else { return candidatos }

        // La mitad que mejor encaja con el objetivo va primero, sin perder variedad
        let ordenados = candidatos.sorted { puntos($0.lineas) > puntos($1.lineas) }
        let corte = max(7, ordenados.count / 2)
        let preferidos = Set(ordenados.prefix(corte).map { $0.plato.id })
        return candidatos.filter { preferidos.contains($0.plato.id) }
            + candidatos.filter { !preferidos.contains($0.plato.id) }
    }

    /// Menú de los 7 días.
    /// `cambios`: cuántas veces se ha pulsado «Cambiar» en cada comida (clave "día-comida").
    static func semana(necesidades: Necesidades, diasEntreno: Int, objetivo: ObjetivoNutricion,
                       filtros: FiltrosDieta, semilla: Int, cambios: [String: Int]) -> [DiaMenu] {
        guard let datos = CatalogoMenus.datos else { return [] }
        let entreno = diasDeEntreno(diasEntreno)
        let c = datos.calculo
        let ordenes: [String: [Candidato]] = Dictionary(uniqueKeysWithValues: datos.comidas.map {
            ($0.id, orden(tipo: $0, filtros: filtros, objetivo: objetivo, semilla: semilla))
        })

        return (0..<7).map { dia in
            let esEntreno = entreno.contains(dia)
            let objetivoDia = esEntreno ? necesidades.kcalEntreno : necesidades.kcalDescanso
            var usados: Set<String> = []
            var comidas: [ComidaMenu] = []

            for tipo in datos.comidas {
                let lista = ordenes[tipo.id] ?? []
                guard !lista.isEmpty else { continue }
                let desplazamiento = cambios["\(dia)-\(tipo.id)"] ?? 0
                // Las dos tentempiés usan los mismos platos: la merienda empieza más adelante
                let salto = tipo.id == "merienda" ? 3 : 0
                var k = 0
                var elegido = lista[(dia + desplazamiento + salto) % lista.count]
                while usados.contains(elegido.plato.id) && k < lista.count {
                    k += 1
                    elegido = lista[(dia + desplazamiento + salto + k) % lista.count]
                }
                usados.insert(elegido.plato.id)

                let base = elegido.lineas.macros.kcal
                let deseado = objetivoDia * tipo.porcentaje
                var escala = base > 0 ? deseado / base : 1
                escala = min(max((escala * 10).rounded() / 10, c.escalaMinima), c.escalaMaxima)
                let lineas = elegido.lineas.map { $0.escalada(escala) }
                comidas.append(ComidaMenu(tipo: tipo, plato: elegido.plato, lineas: lineas,
                                          escala: escala, macros: lineas.macros))
            }
            return DiaMenu(indice: dia, nombre: nombresDias[dia], entreno: esEntreno,
                           objetivoKcal: objetivoDia, comidas: comidas)
        }
    }
}

// MARK: - Lista de la compra

struct ArticuloCompra: Identifiable, Hashable {
    let ingrediente: Ingrediente
    let cantidad: Double
    var id: String { ingrediente.id }
}

struct SeccionCompra: Identifiable {
    let nombre: String
    let articulos: [ArticuloCompra]
    var id: String { nombre }
}

enum ListaCompra {
    static func crear(semana: [DiaMenu], personas: Int) -> [SeccionCompra] {
        var total: [String: (Ingrediente, Double)] = [:]
        for dia in semana {
            for comida in dia.comidas {
                for l in comida.lineas {
                    let previo = total[l.ingrediente.id]?.1 ?? 0
                    total[l.ingrediente.id] = (l.ingrediente, previo + l.cantidad * Double(max(personas, 1)))
                }
            }
        }
        let articulos = total.values.map { ArticuloCompra(ingrediente: $0.0, cantidad: $0.1) }
        return CatalogoMenus.secciones.compactMap { s in
            let deSeccion = articulos.filter { $0.ingrediente.seccion == s }
                .sorted { $0.ingrediente.nombre.localizedCompare($1.ingrediente.nombre) == .orderedAscending }
            return deSeccion.isEmpty ? nil : SeccionCompra(nombre: s, articulos: deSeccion)
        }
    }

    static func texto(_ secciones: [SeccionCompra], marcados: Set<String>) -> String {
        var t = "Lista de la compra · \(Config.nombreApp)\n"
        for s in secciones {
            t += "\n\(s.nombre.uppercased())\n"
            for a in s.articulos {
                let marca = marcados.contains(a.id) ? "✓" : "•"
                t += "\(marca) \(a.ingrediente.nombre): \(Formato.compra(a.cantidad, a.ingrediente))\n"
            }
        }
        return t
    }
}

// MARK: - Textos de cantidades

enum Formato {
    static func numero(_ valor: Double, decimales: Int = 0) -> String {
        valor.formatted(.number.precision(.fractionLength(0...decimales)).locale(Locale(identifier: "es_ES")))
    }

    static func kcal(_ valor: Double) -> String { numero(valor) + " kcal" }
    static func gramos(_ valor: Double) -> String { numero(valor) + " g" }

    /// Cantidad para un plato: "90 g (≈ 1,5 ud)"
    static func plato(_ cantidad: Double, _ ing: Ingrediente) -> String {
        let redondeo: Double = cantidad < 20 ? 1 : 5
        let valor = max((cantidad / redondeo).rounded() * redondeo, 1)
        let base = numero(valor) + " " + ing.unidad
        guard let pu = ing.pesoUnidad, pu > 0, let nu = ing.nombreUnidad else { return base }
        let unidades = max((cantidad / pu * 2).rounded() / 2, 0.5)
        if nu == "diente" {
            let n = max(Int(unidades.rounded()), 1)
            return n == 1 ? "1 diente" : "\(n) dientes"
        }
        return base + " (≈ " + numero(unidades, decimales: 1) + " " + nu + ")"
    }

    /// Cantidad para comprar: redondea hacia arriba
    static func compra(_ cantidad: Double, _ ing: Ingrediente) -> String {
        if let pu = ing.pesoUnidad, pu > 0, let nu = ing.nombreUnidad {
            let n = max(Int((cantidad / pu).rounded(.up)), 1)
            if nu == "diente" { return n == 1 ? "1 diente" : "\(n) dientes" }
            return "\(n) \(nu) (≈ \(peso(Double(n) * pu, ing.unidad)))"
        }
        return peso(cantidad, ing.unidad)
    }

    private static func peso(_ cantidad: Double, _ unidad: String) -> String {
        if cantidad >= 1000 {
            let grande = unidad == "ml" ? "l" : "kg"
            return numero((cantidad / 100).rounded(.up) / 10, decimales: 1) + " " + grande
        }
        let redondeo: Double = cantidad < 100 ? 5 : 10
        return numero(max((cantidad / redondeo).rounded(.up) * redondeo, redondeo)) + " " + unidad
    }
}
