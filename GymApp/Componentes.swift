import SwiftUI

enum Config {
    /// Nombre visible de la app
    static let nombreApp = "GymApp"
    /// Dirección de la versión web (GitHub Pages)
    static let webURL = URL(string: "https://mhowani.github.io/GymApp/")!
    /// Página de contacto de la web (formulario Web3Forms)
    static let contactoURL = URL(string: "https://mhowani.github.io/GymApp/contacto.html")!
}

/// Cabecera con el logo
struct CabeceraLogo: View {
    var subtitulo: String = "Entrena con pesas, máquinas o en casa"

    var body: some View {
        HStack(spacing: 12) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .padding(4)
                .frame(width: 52, height: 52)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white))
            VStack(alignment: .leading, spacing: 2) {
                Text(Config.nombreApp)
                    .font(.title2.bold())
                Text(subtitulo)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

/// Título de sección con botón opcional a la derecha
struct TituloSeccion: View {
    let titulo: String
    var icono: String? = nil
    var boton: String? = nil
    var accion: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            if let icono {
                Image(systemName: icono).foregroundStyle(Tema.acento)
            }
            Text(titulo).font(.title3.bold())
            Spacer()
            if let boton, let accion {
                Button(boton, action: accion)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Tema.acento)
                    .buttonStyle(.plain)
            }
        }
    }
}

/// Botón tipo "chip" para filtros
struct Chip: View {
    let texto: String
    var icono: String? = nil
    let seleccionado: Bool
    var color: Color = Tema.acento
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            HStack(spacing: 6) {
                if let icono { Image(systemName: icono) }
                Text(texto).lineLimit(1)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(seleccionado ? Color.white : color)
            .background(
                Capsule().fill(seleccionado ? AnyShapeStyle(color.gradient) : AnyShapeStyle(color.opacity(0.14)))
            )
            .contentShape(Capsule())
        }
        .buttonStyle(EstiloPulsado())
    }
}

/// Etiqueta de color en forma de cápsula
struct Etiqueta: View {
    let texto: String
    var icono: String? = nil
    var color: Color = Tema.acento

    var body: some View {
        HStack(spacing: 5) {
            if let icono { Image(systemName: icono) }
            Text(texto).lineLimit(1)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundStyle(color)
        .background(Capsule().fill(color.opacity(0.14)))
    }
}

/// Etiqueta del lugar (Pesas, Máquinas, En casa) con su color
struct EtiquetaLugar: View {
    let lugar: Lugar

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: lugar.icono)
            Text(lugar.nombre)
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(lugar.degradado))
    }
}

/// Tres barritas que indican el nivel
struct IndicadorNivel: View {
    let nivel: String
    var conTexto: Bool = false

    private var numero: Int {
        switch nivel.lowercased() {
        case "avanzado": return 3
        case "intermedio": return 2
        default: return 1
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(1...3, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(i <= numero ? Tema.coral : Color.secondary.opacity(0.25))
                        .frame(width: 4, height: CGFloat(4 + i * 3))
                }
            }
            if conTexto {
                Text(nivel).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Nivel \(nivel)")
    }
}

/// Corazón para añadir o quitar de favoritos
struct BotonFavorito: View {
    @EnvironmentObject private var favoritos: Favoritos
    let ejercicio: Ejercicio
    var conFondo: Bool = true

    var body: some View {
        let activo = favoritos.contiene(ejercicio)
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                favoritos.alternar(ejercicio)
            }
        } label: {
            Image(systemName: activo ? "heart.fill" : "heart")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(activo ? Tema.coral : Color.secondary)
                .symbolEffect(.bounce, value: activo)
                .frame(width: 32, height: 32)
                .background {
                    if conFondo {
                        Circle().fill(Tema.tarjeta)
                            .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(activo ? "Quitar de favoritos" : "Añadir a favoritos")
    }
}

/// Tarjeta de ejercicio para las cuadrículas
struct TarjetaEjercicio: View {
    let ejercicio: Ejercicio

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MapaMuscularView(principales: Set(ejercicio.principales),
                             secundarios: Set(ejercicio.secundarios))
                .padding(.horizontal, 10)
                .padding(.top, 34)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
                .background(Tema.suave)
                .overlay(alignment: .topLeading) {
                    EtiquetaLugar(lugar: ejercicio.lugar).padding(8)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(ejercicio.nombre)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                Text(ejercicio.principales.map(\.nombre).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    IndicadorNivel(nivel: ejercicio.nivel)
                    Spacer(minLength: 4)
                    Text(ejercicio.series)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Tema.acento)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .tarjeta(radio: 20)
    }
}

/// Tarjeta que abre la ficha del ejercicio, con el corazón de favorito encima
struct CeldaEjercicio: View {
    let ejercicio: Ejercicio

    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(value: ejercicio) {
                TarjetaEjercicio(ejercicio: ejercicio)
            }
            .buttonStyle(EstiloPulsado())
            BotonFavorito(ejercicio: ejercicio)
                .padding(6)
        }
    }
}

/// Fila compacta de ejercicio (para listas)
struct FilaEjercicio: View {
    let ejercicio: Ejercicio
    var detalle: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: ejercicio.lugar.icono)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(ejercicio.lugar.degradado))
            VStack(alignment: .leading, spacing: 2) {
                Text(ejercicio.nombre)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Text(detalle ?? ejercicio.principales.map(\.nombre).joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .tarjeta(radio: 16)
        .contentShape(Rectangle())
    }
}

/// Coloca los elementos en filas y pasa a la siguiente cuando no caben
struct FilaFlexible<Contenido: View>: View {
    var espacio: CGFloat = 8
    @ViewBuilder var contenido: Contenido

    var body: some View {
        let disposicion = DisposicionFlexible(espacio: espacio)
        disposicion {
            contenido
        }
    }
}

struct DisposicionFlexible: Layout {
    var espacio: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let ancho = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, altoFila: CGFloat = 0, maxX: CGFloat = 0
        for s in subviews {
            let t = s.sizeThatFits(.unspecified)
            if x > 0 && x + t.width > ancho {
                x = 0
                y += altoFila + espacio
                altoFila = 0
            }
            x += t.width + espacio
            maxX = max(maxX, x - espacio)
            altoFila = max(altoFila, t.height)
        }
        return CGSize(width: proposal.width ?? maxX, height: y + altoFila)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, altoFila: CGFloat = 0
        for s in subviews {
            let t = s.sizeThatFits(.unspecified)
            if x > bounds.minX && x + t.width > bounds.maxX {
                x = bounds.minX
                y += altoFila + espacio
                altoFila = 0
            }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(t))
            x += t.width + espacio
            altoFila = max(altoFila, t.height)
        }
    }
}
