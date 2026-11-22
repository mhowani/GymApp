import SwiftUI

/// Toca un músculo del dibujo (o elígelo en la lista) para ver sus ejercicios
struct MusculosView: View {
    @State private var seleccionado: Musculo? = .pecho
    @State private var lugar: Lugar? = nil
    @State private var verZoom = false

    private var ejercicios: [Ejercicio] {
        guard let m = seleccionado else { return [] }
        return Catalogo.ejercicios
            .filter { $0.trabaja(m) && (lugar == nil || $0.lugar == lugar) }
            .sorted { a, b in
                // Primero donde es músculo principal
                let pa = a.principales.contains(m), pb = b.principales.contains(m)
                return pa != pb ? pa : a.nombre < b.nombre
            }
    }

    private var resaltados: Set<Musculo> {
        seleccionado.map { Set([$0]) } ?? []
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    dibujo
                    listaMusculos
                    if let m = seleccionado { seccionEjercicios(m) }
                }
                .padding()
                .frame(maxWidth: 800)
                .frame(maxWidth: .infinity)
            }
            .background(Tema.fondo.ignoresSafeArea())
            .navigationTitle("Músculos")
            .navigationDestination(for: Ejercicio.self) { e in
                DetalleEjercicioView(ejercicio: e)
            }
            .sheet(isPresented: $verZoom) {
                HojaZoomMapa(titulo: "Toca un músculo",
                             principales: resaltados,
                             alTocar: { m in seleccionado = m },
                             textoPie: seleccionado.map { "\($0.nombre) · \(ejercicios.count) ejercicios" })
            }
        }
    }

    // MARK: Dibujo

    private var dibujo: some View {
        VStack(spacing: 10) {
            HStack {
                Label("Toca un músculo del dibujo", systemImage: "hand.tap.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    verZoom = true
                } label: {
                    Label("Ampliar", systemImage: "plus.magnifyingglass")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(Tema.acento)
            }

            MapaMuscularView(principales: resaltados, alTocar: { m in seleccionado = m })
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Tema.suave))

            if let m = seleccionado {
                Text(m.nombre)
                    .font(.title3.bold())
                    .foregroundStyle(MapaMuscularView.colorPrincipal)
                    .contentTransition(.opacity)
                    .animation(.easeInOut, value: m)
            }
        }
        .padding(12)
        .tarjeta()
    }

    // MARK: Lista de músculos por zonas

    private var listaMusculos: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Musculo.Zona.allCases) { zona in
                VStack(alignment: .leading, spacing: 8) {
                    Text(zona.nombre.uppercased())
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    FilaFlexible {
                        ForEach(Musculo.allCases.filter { $0.zona == zona }) { m in
                            Chip(texto: m.nombre, seleccionado: seleccionado == m,
                                 color: MapaMuscularView.colorPrincipal) {
                                seleccionado = m
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Ejercicios del músculo elegido

    private func seccionEjercicios(_ m: Musculo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TituloSeccion(titulo: "Ejercicios para \(m.nombre.lowercased())")
                .padding(.top, 6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Chip(texto: "Todos", seleccionado: lugar == nil) { lugar = nil }
                    ForEach(Lugar.allCases) { l in
                        Chip(texto: l.nombre, icono: l.icono, seleccionado: lugar == l, color: l.color) {
                            lugar = (lugar == l) ? nil : l
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            if ejercicios.isEmpty {
                Text("No hay ejercicios para este filtro.")
                    .foregroundStyle(.secondary)
            }

            ForEach(ejercicios) { e in
                NavigationLink(value: e) {
                    FilaEjercicio(ejercicio: e,
                                  detalle: e.principales.contains(m) ? "Principal · \(e.series)" : "Secundario · \(e.series)")
                }
                .buttonStyle(EstiloPulsado())
            }
        }
    }
}
