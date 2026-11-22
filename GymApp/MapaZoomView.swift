import SwiftUI

/// Dibujo de músculos que se puede ampliar:
/// pellizca (o usa + y −) para hacer zoom y arrastra para moverte.
struct MapaZoomable: View {
    var principales: Set<Musculo> = []
    var secundarios: Set<Musculo> = []
    var alTocar: ((Musculo) -> Void)? = nil

    @State private var escala: CGFloat = 1
    @State private var escalaBase: CGFloat = 1
    @State private var desplazamiento: CGSize = .zero
    @State private var desplazamientoBase: CGSize = .zero
    @State private var tamano: CGSize = .zero

    private let escalaMaxima: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            MapaMuscularView(principales: principales,
                             secundarios: secundarios,
                             alTocar: alTocar)
                .frame(width: geo.size.width, height: geo.size.height)
                .scaleEffect(escala)
                .offset(desplazamiento)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .contentShape(Rectangle())
                .gesture(gestos(geo.size))
                .onAppear { tamano = geo.size }
                .onChange(of: geo.size) { _, nuevo in tamano = nuevo }
        }
        .overlay(alignment: .bottomTrailing) { controles.padding(10) }
    }

    // MARK: Gestos (pellizcar y arrastrar)

    private func gestos(_ tam: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { valor in
                escala = min(max(escalaBase * valor.magnification, 1), escalaMaxima)
                desplazamiento = limitar(desplazamiento, tam, escala)
            }
            .onEnded { _ in
                escalaBase = escala
                desplazamientoBase = desplazamiento
            }
            .simultaneously(with:
                DragGesture(minimumDistance: 8)
                    .onChanged { valor in
                        guard escala > 1 else { return }
                        let nuevo = CGSize(width: desplazamientoBase.width + valor.translation.width,
                                           height: desplazamientoBase.height + valor.translation.height)
                        desplazamiento = limitar(nuevo, tam, escala)
                    }
                    .onEnded { _ in
                        desplazamientoBase = desplazamiento
                    }
            )
    }

    /// Evita que el dibujo se salga del recuadro
    private func limitar(_ d: CGSize, _ tam: CGSize, _ e: CGFloat) -> CGSize {
        let mx = (e - 1) * tam.width / 2
        let my = (e - 1) * tam.height / 2
        return CGSize(width: min(max(d.width, -mx), mx),
                      height: min(max(d.height, -my), my))
    }

    private func zoom(_ nueva: CGFloat) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            escala = min(max(nueva, 1), escalaMaxima)
            escalaBase = escala
            desplazamiento = escala == 1 ? .zero : limitar(desplazamiento, tamano, escala)
            desplazamientoBase = desplazamiento
        }
    }

    // MARK: Botones + y −

    private var controles: some View {
        HStack(spacing: 0) {
            botonControl("minus.magnifyingglass", "Reducir") { zoom(escala / 1.5) }
                .disabled(escala <= 1)
                .keyboardShortcut("-", modifiers: .command)
            Divider().frame(height: 22)
            botonControl("arrow.counterclockwise", "Tamaño original") { zoom(1) }
                .disabled(escala <= 1)
                .keyboardShortcut("0", modifiers: .command)
            Divider().frame(height: 22)
            botonControl("plus.magnifyingglass", "Ampliar") { zoom(escala * 1.5) }
                .disabled(escala >= escalaMaxima)
                .keyboardShortcut("+", modifiers: .command)
        }
        .background(Capsule().fill(.regularMaterial))
        .overlay(Capsule().strokeBorder(Tema.borde))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
    }

    private func botonControl(_ icono: String, _ nombre: String, _ accion: @escaping () -> Void) -> some View {
        Button(action: accion) {
            Image(systemName: icono)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Tema.acento)
                .frame(width: 44, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(nombre)
    }
}

/// Hoja que ocupa casi toda la pantalla con el dibujo ampliable
struct HojaZoomMapa: View {
    let titulo: String
    var principales: Set<Musculo> = []
    var secundarios: Set<Musculo> = []
    var alTocar: ((Musculo) -> Void)? = nil
    /// Texto opcional bajo el dibujo (por ejemplo, el músculo elegido)
    var textoPie: String? = nil

    @Environment(\.dismiss) private var cerrar

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                MapaZoomable(principales: principales, secundarios: secundarios, alTocar: alTocar)
                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Tema.suave))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                if let textoPie {
                    Text(textoPie)
                        .font(.headline)
                        .foregroundStyle(MapaMuscularView.colorPrincipal)
                } else {
                    LeyendaMapa()
                }

                Label(alTocar == nil
                      ? "Pellizca o usa + y − para ampliar. Arrastra para moverte."
                      : "Pellizca para ampliar y toca un músculo para elegirlo.",
                      systemImage: "hand.draw")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Tema.fondo.ignoresSafeArea())
            .navigationTitle(titulo)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { cerrar() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 700, minHeight: 620)
        #endif
    }
}

#Preview {
    HojaZoomMapa(titulo: "Press de banca", principales: [.pecho], secundarios: [.triceps, .hombros])
}
