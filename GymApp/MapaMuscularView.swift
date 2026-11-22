import SwiftUI

/// Dibujo del cuerpo (frente y espalda) con los músculos coloreados.
/// Rojo = músculo principal · Naranja = músculo secundario
struct MapaMuscularView: View {
    var principales: Set<Musculo> = []
    var secundarios: Set<Musculo> = []
    var mostrarLineas: Bool = true
    var alTocar: ((Musculo) -> Void)? = nil

    static let colorPrincipal = Color(red: 0.90, green: 0.22, blue: 0.24)
    static let colorSecundario = Color(red: 0.98, green: 0.62, blue: 0.20)

    private let proporcion: CGFloat = 1400.0 / 1096.0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                capa("m_cuerpo", Tema.cuerpo)
                ForEach(Musculo.allCases) { m in
                    if principales.contains(m) {
                        capa(m.imagen, Self.colorPrincipal)
                    } else if secundarios.contains(m) {
                        capa(m.imagen, Self.colorSecundario.opacity(0.85))
                    }
                }
                if mostrarLineas {
                    capa("m_lineas", Color.primary.opacity(0.85))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .overlay {
                // Solo se puede tocar si se ha indicado qué hacer al tocar
                if let alTocar {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { punto in
                            guard geo.size.width > 0, geo.size.height > 0 else { return }
                            if let m = MapaToque.compartido?.musculo(x: punto.x / geo.size.width,
                                                                       y: punto.y / geo.size.height) {
                                alTocar(m)
                            }
                        }
                }
            }
        }
        .aspectRatio(proporcion, contentMode: .fit)
        .animation(.easeInOut(duration: 0.25), value: principales)
        .animation(.easeInOut(duration: 0.25), value: secundarios)
    }

    private func capa(_ nombre: String, _ color: Color) -> some View {
        Image(nombre)
            .renderingMode(.template)
            .resizable()
            .interpolation(.high)
            .foregroundStyle(color)
    }
}

/// Leyenda de colores
struct LeyendaMapa: View {
    var body: some View {
        HStack(spacing: 16) {
            punto(MapaMuscularView.colorPrincipal, "Principal")
            punto(MapaMuscularView.colorSecundario, "Secundario")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func punto(_ color: Color, _ texto: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(texto)
        }
    }
}

#Preview {
    MapaMuscularView(principales: [.pecho, .cuadriceps], secundarios: [.triceps, .hombros])
        .padding()
        .background(Tema.suave)
}
