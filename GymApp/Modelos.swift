import SwiftUI

// MARK: - Músculos (coinciden con las imágenes m_xxx del catálogo de recursos)

enum Musculo: String, Codable, CaseIterable, Identifiable, Hashable {
    case pecho, hombros, trapecio, biceps, triceps, antebrazos
    case abdominales, oblicuos, espalda, lumbares
    case gluteos, cuadriceps, isquiotibiales, aductores, abductores, gemelos

    var id: String { rawValue }

    var nombre: String {
        switch self {
        case .pecho: return "Pecho"
        case .hombros: return "Hombros"
        case .trapecio: return "Trapecio"
        case .biceps: return "Bíceps"
        case .triceps: return "Tríceps"
        case .antebrazos: return "Antebrazos"
        case .abdominales: return "Abdominales"
        case .oblicuos: return "Oblicuos"
        case .espalda: return "Espalda (dorsales)"
        case .lumbares: return "Lumbares"
        case .gluteos: return "Glúteos"
        case .cuadriceps: return "Cuádriceps"
        case .isquiotibiales: return "Isquiotibiales"
        case .aductores: return "Aductores"
        case .abductores: return "Abductores"
        case .gemelos: return "Gemelos"
        }
    }

    /// Nombre de la imagen (máscara) en Assets.xcassets
    var imagen: String { "m_" + rawValue }

    /// Zona del cuerpo, para agrupar los músculos
    enum Zona: String, CaseIterable, Identifiable {
        case superior, core, inferior

        var id: String { rawValue }

        var nombre: String {
            switch self {
            case .superior: return "Tren superior"
            case .core: return "Core"
            case .inferior: return "Tren inferior"
            }
        }
    }

    var zona: Zona {
        switch self {
        case .pecho, .hombros, .trapecio, .biceps, .triceps, .antebrazos, .espalda:
            return .superior
        case .abdominales, .oblicuos, .lumbares:
            return .core
        default:
            return .inferior
        }
    }
}

// MARK: - Lugar de entrenamiento

enum Lugar: String, Codable, CaseIterable, Identifiable, Hashable {
    case pesas, maquinas, casa

    var id: String { rawValue }

    var nombre: String {
        switch self {
        case .pesas: return "Pesas"
        case .maquinas: return "Máquinas"
        case .casa: return "En casa"
        }
    }

    var descripcion: String {
        switch self {
        case .pesas: return "Barras y mancuernas"
        case .maquinas: return "Poleas y máquinas"
        case .casa: return "Sin material"
        }
    }

    var icono: String {
        switch self {
        case .pesas: return "dumbbell.fill"
        case .maquinas: return "gearshape.2.fill"
        case .casa: return "sofa.fill"
        }
    }

    /// Colores del logo: azul, celeste y coral
    var color: Color {
        switch self {
        case .pesas: return Tema.azul
        case .maquinas: return Tema.celeste
        case .casa: return Tema.coral
        }
    }

    var degradado: LinearGradient {
        let colores: [Color]
        switch self {
        case .pesas: colores = [Tema.azulOscuro, Tema.azul]
        case .maquinas: colores = [Tema.azul, Tema.celeste]
        case .casa: colores = [Tema.coral, Tema.coralClaro]
        }
        return LinearGradient(colors: colores, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Ejercicio

struct Ejercicio: Codable, Identifiable, Hashable {
    let id: String
    let nombre: String
    let lugar: Lugar
    let principales: [Musculo]
    let secundarios: [Musculo]
    let nivel: String
    let series: String
    let pasos: [String]
    let consejo: String

    func trabaja(_ m: Musculo) -> Bool {
        principales.contains(m) || secundarios.contains(m)
    }

    /// 1 = principiante, 2 = intermedio, 3 = avanzado
    var nivelNumero: Int {
        switch nivel.lowercased() {
        case "avanzado": return 3
        case "intermedio": return 2
        default: return 1
        }
    }

    /// Texto donde busca el buscador (nombre, lugar, nivel y músculos)
    private var textoBusqueda: String {
        ([nombre, lugar.nombre, nivel] + principales.map(\.nombre) + secundarios.map(\.nombre))
            .joined(separator: " ")
    }

    /// Busca sin distinguir mayúsculas ni tildes; todas las palabras deben aparecer
    func coincide(con texto: String) -> Bool {
        let palabras = texto.split(separator: " ").map(String.init)
        guard !palabras.isEmpty else { return true }
        let base = textoBusqueda
        return palabras.allSatisfy {
            base.range(of: $0, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }
}

// MARK: - Catálogo (se lee de ejercicios.json)

enum Catalogo {
    static let ejercicios: [Ejercicio] = {
        guard let url = Bundle.main.url(forResource: "ejercicios", withExtension: "json"),
              let datos = try? Data(contentsOf: url),
              let lista = try? JSONDecoder().decode([Ejercicio].self, from: datos) else {
            return []
        }
        return lista
    }()

    static func cantidad(en lugar: Lugar) -> Int {
        ejercicios.filter { $0.lugar == lugar }.count
    }

    /// Cambia cada día
    static var ejercicioDelDia: Ejercicio? {
        guard !ejercicios.isEmpty else { return nil }
        let dia = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return ejercicios[dia % ejercicios.count]
    }

    /// Ejercicios que trabajan el mismo músculo principal (primero los del mismo lugar)
    static func parecidos(a e: Ejercicio, maximo: Int = 4) -> [Ejercicio] {
        guard let m = e.principales.first else { return [] }
        let lista = ejercicios
            .filter { $0.id != e.id && $0.principales.contains(m) }
            .sorted { a, b in
                (a.lugar == e.lugar ? 0 : 1, a.nombre) < (b.lugar == e.lugar ? 0 : 1, b.nombre)
            }
        return Array(lista.prefix(maximo))
    }
}

// MARK: - Rejilla para saber qué músculo se ha tocado en el dibujo

struct MapaToque: Decodable {
    let ancho: Int
    let alto: Int
    let musculos: [String]
    let filas: [String]

    static let compartido: MapaToque? = {
        guard let url = Bundle.main.url(forResource: "mapa_toque", withExtension: "json"),
              let datos = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(MapaToque.self, from: datos)
    }()

    /// x e y van de 0 a 1 (proporción dentro del dibujo)
    func musculo(x: CGFloat, y: CGFloat) -> Musculo? {
        let col = Int(x * CGFloat(ancho))
        let fila = Int(y * CGFloat(alto))
        // Busca en un pequeño radio para que sea fácil acertar con el dedo
        for radio in 0...3 {
            for dy in -radio...radio {
                for dx in -radio...radio {
                    if let m = celda(col + dx, fila + dy) { return m }
                }
            }
        }
        return nil
    }

    private func celda(_ c: Int, _ f: Int) -> Musculo? {
        guard f >= 0, f < filas.count else { return nil }
        let texto = Array(filas[f])
        guard c >= 0, c < texto.count else { return nil }
        guard let valor = texto[c].asciiValue, texto[c] != "." else { return nil }
        let indice = Int(valor) - 97
        guard indice >= 0, indice < musculos.count else { return nil }
        return Musculo(rawValue: musculos[indice])
    }
}
