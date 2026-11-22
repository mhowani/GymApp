import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Color que cambia solo entre modo claro y modo oscuro

extension Color {
    init(claro: Color, oscuro: Color) {
        #if os(macOS)
        self.init(nsColor: NSColor(name: nil) { apariencia in
            let esOscuro = apariencia.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return esOscuro ? NSColor(oscuro) : NSColor(claro)
        })
        #else
        self.init(uiColor: UIColor { rasgos in
            rasgos.userInterfaceStyle == .dark ? UIColor(oscuro) : UIColor(claro)
        })
        #endif
    }
}

// MARK: - Colores del logo (azules y coral)

enum Tema {
    static let azulOscuro = Color(red: 0.04, green: 0.22, blue: 0.43)   // #0B386E
    static let azul       = Color(red: 0.12, green: 0.44, blue: 0.74)   // #1F70BD
    static let celeste    = Color(red: 0.36, green: 0.72, blue: 0.90)   // #5CB8E6
    static let coral      = Color(red: 0.95, green: 0.47, blue: 0.45)   // #F27873
    static let coralClaro = Color(red: 0.98, green: 0.66, blue: 0.54)   // #FAA88A

    /// Degradado principal, como el del logo
    static let degradado = LinearGradient(colors: [azulOscuro, azul, celeste],
                                          startPoint: .topLeading, endPoint: .bottomTrailing)
    static let degradadoCoral = LinearGradient(colors: [coral, coralClaro],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)

    /// Fondo de las pantallas
    static let fondo = Color(claro: Color(red: 0.95, green: 0.97, blue: 0.99),
                             oscuro: Color(red: 0.04, green: 0.07, blue: 0.12))
    /// Fondo de las tarjetas
    static let tarjeta = Color(claro: .white,
                               oscuro: Color(red: 0.10, green: 0.14, blue: 0.21))
    /// Fondo suave (zona del dibujo dentro de las tarjetas)
    static let suave = Color(claro: Color(red: 0.91, green: 0.95, blue: 0.99),
                             oscuro: Color(red: 0.15, green: 0.20, blue: 0.29))
    /// Azul para textos e iconos: se lee bien en claro y en oscuro
    static let acento = Color(claro: azul, oscuro: celeste)
    /// Borde fino de las tarjetas
    static let borde = Color(claro: Color.black.opacity(0.06), oscuro: Color.white.opacity(0.08))
    /// Relleno del cuerpo en el dibujo de músculos
    static let cuerpo = Color(claro: .white, oscuro: Color(white: 0.26))
}

// MARK: - Estilo de tarjeta (fondo, borde y sombra)

struct EstiloTarjeta: ViewModifier {
    var radio: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: radio, style: .continuous).fill(Tema.tarjeta))
            .overlay(RoundedRectangle(cornerRadius: radio, style: .continuous).strokeBorder(Tema.borde))
            .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func tarjeta(radio: CGFloat = 18) -> some View {
        modifier(EstiloTarjeta(radio: radio))
    }
}

/// Botón que se encoge un poco al pulsarlo
struct EstiloPulsado: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Apariencia (sistema, claro, oscuro)

enum Apariencia: String, CaseIterable, Identifiable {
    case sistema, claro, oscuro

    var id: String { rawValue }

    var nombre: String {
        switch self {
        case .sistema: return "Automático"
        case .claro: return "Claro"
        case .oscuro: return "Oscuro"
        }
    }

    var esquema: ColorScheme? {
        switch self {
        case .sistema: return nil
        case .claro: return .light
        case .oscuro: return .dark
        }
    }
}

// MARK: - Favoritos (se guardan en el dispositivo)

final class Favoritos: ObservableObject {
    @Published private(set) var ids: Set<String>
    private let clave = "favoritos.ids"

    init() {
        ids = Set(UserDefaults.standard.stringArray(forKey: clave) ?? [])
    }

    func contiene(_ e: Ejercicio) -> Bool { ids.contains(e.id) }

    func alternar(_ e: Ejercicio) {
        if ids.contains(e.id) { ids.remove(e.id) } else { ids.insert(e.id) }
        UserDefaults.standard.set(Array(ids), forKey: clave)
    }

    var ejercicios: [Ejercicio] {
        Catalogo.ejercicios.filter { ids.contains($0.id) }
    }
}

// MARK: - Estado compartido entre pestañas

enum Pestana: Hashable {
    case inicio, ejercicios, musculos, plan, correr, menus
}

final class EstadoApp: ObservableObject {
    @Published var pestana: Pestana = .inicio
    @Published var busqueda = ""
    @Published var lugar: Lugar? = nil
    @Published var musculo: Musculo? = nil
    @Published var soloFavoritos = false

    /// Abre la pestaña Ejercicios con los filtros indicados
    func abrirEjercicios(lugar: Lugar? = nil, musculo: Musculo? = nil,
                         favoritos: Bool = false, busqueda: String = "") {
        self.lugar = lugar
        self.musculo = musculo
        self.soloFavoritos = favoritos
        self.busqueda = busqueda
        pestana = .ejercicios
    }
}
