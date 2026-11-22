import SwiftUI

struct EjerciciosView: View {
    @EnvironmentObject private var estado: EstadoApp
    @EnvironmentObject private var favoritos: Favoritos
    @State private var nivel: String? = nil

    private let niveles = ["Principiante", "Intermedio", "Avanzado"]

    private var filtrados: [Ejercicio] {
        Catalogo.ejercicios.filter { e in
            (estado.lugar == nil || e.lugar == estado.lugar) &&
            (estado.musculo == nil || e.trabaja(estado.musculo!)) &&
            (nivel == nil || e.nivel == nivel) &&
            (!estado.soloFavoritos || favoritos.contiene(e)) &&
            e.coincide(con: estado.busqueda)
        }
    }

    private var hayFiltrosExtra: Bool { estado.musculo != nil || nivel != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    chipsLugar

                    if hayFiltrosExtra { filtrosActivos }

                    Text(filtrados.count == 1 ? "1 ejercicio" : "\(filtrados.count) ejercicios")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if filtrados.isEmpty {
                        vacio.padding(.top, 30)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 155, maximum: 260), spacing: 12)],
                                  spacing: 12) {
                            ForEach(filtrados) { e in
                                CeldaEjercicio(ejercicio: e)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Tema.fondo.ignoresSafeArea())
            .navigationTitle("Ejercicios")
            .searchable(text: $estado.busqueda, prompt: "Ejercicio, músculo o lugar")
            .navigationDestination(for: Ejercicio.self) { e in
                DetalleEjercicioView(ejercicio: e)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) { menuFiltros }
            }
        }
    }

    // MARK: Filtros

    private var chipsLugar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Chip(texto: "Todos", icono: "square.grid.2x2.fill",
                     seleccionado: estado.lugar == nil && !estado.soloFavoritos) {
                    estado.lugar = nil
                    estado.soloFavoritos = false
                }
                Chip(texto: "Favoritos", icono: "heart.fill",
                     seleccionado: estado.soloFavoritos, color: Tema.coral) {
                    estado.soloFavoritos.toggle()
                }
                ForEach(Lugar.allCases) { l in
                    Chip(texto: l.nombre, icono: l.icono, seleccionado: estado.lugar == l, color: l.color) {
                        estado.lugar = (estado.lugar == l) ? nil : l
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var filtrosActivos: some View {
        FilaFlexible {
            if let m = estado.musculo {
                botonQuitar("Músculo: \(m.nombre)", color: MapaMuscularView.colorPrincipal) {
                    estado.musculo = nil
                }
            }
            if let n = nivel {
                botonQuitar("Nivel: \(n)", color: Tema.acento) { nivel = nil }
            }
        }
    }

    private func botonQuitar(_ texto: String, color: Color, accion: @escaping () -> Void) -> some View {
        Button(action: accion) {
            HStack(spacing: 6) {
                Text(texto)
                Image(systemName: "xmark.circle.fill")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(color.opacity(0.14)))
        }
        .buttonStyle(.plain)
    }

    private var menuFiltros: some View {
        Menu {
            Picker("Músculo", selection: $estado.musculo) {
                Text("Todos los músculos").tag(Musculo?.none)
                ForEach(Musculo.allCases) { m in
                    Text(m.nombre).tag(Musculo?.some(m))
                }
            }
            .pickerStyle(.menu)

            Picker("Nivel", selection: $nivel) {
                Text("Todos los niveles").tag(String?.none)
                ForEach(niveles, id: \.self) { n in
                    Text(n).tag(String?.some(n))
                }
            }
            .pickerStyle(.menu)

            if hayFiltrosExtra || estado.lugar != nil || estado.soloFavoritos || !estado.busqueda.isEmpty {
                Divider()
                Button("Quitar todos los filtros", role: .destructive) {
                    estado.abrirEjercicios()
                    nivel = nil
                }
            }
        } label: {
            Label("Filtrar", systemImage: hayFiltrosExtra
                  ? "line.3.horizontal.decrease.circle.fill"
                  : "line.3.horizontal.decrease.circle")
        }
    }

    @ViewBuilder
    private var vacio: some View {
        if estado.soloFavoritos && favoritos.ids.isEmpty {
            ContentUnavailableView("Aún no tienes favoritos", systemImage: "heart",
                                   description: Text("Pulsa el corazón de un ejercicio para guardarlo aquí."))
        } else if !estado.busqueda.isEmpty {
            ContentUnavailableView.search(text: estado.busqueda)
        } else {
            ContentUnavailableView("Sin resultados", systemImage: "line.3.horizontal.decrease.circle",
                                   description: Text("Prueba a quitar algún filtro."))
        }
    }
}

// MARK: - Ficha de un ejercicio

struct DetalleEjercicioView: View {
    let ejercicio: Ejercicio
    @State private var verZoom = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(ejercicio.nombre)
                    .font(.title.bold())
                    .fixedSize(horizontal: false, vertical: true)

                FilaFlexible {
                    EtiquetaLugar(lugar: ejercicio.lugar)
                    Etiqueta(texto: ejercicio.nivel, icono: "chart.bar.fill", color: Tema.coral)
                    Etiqueta(texto: ejercicio.series, icono: "repeat", color: Tema.acento)
                }

                dibujo
                musculos
                pasos
                consejo

                let parecidos = Catalogo.parecidos(a: ejercicio)
                if !parecidos.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        TituloSeccion(titulo: "Ejercicios parecidos", icono: "arrow.triangle.swap")
                        ForEach(parecidos) { e in
                            NavigationLink(value: e) {
                                FilaEjercicio(ejercicio: e, detalle: "\(e.lugar.nombre) · \(e.series)")
                            }
                            .buttonStyle(EstiloPulsado())
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(Tema.fondo.ignoresSafeArea())
        .navigationTitle(ejercicio.nombre)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                BotonFavorito(ejercicio: ejercicio, conFondo: false)
            }
        }
        .sheet(isPresented: $verZoom) {
            HojaZoomMapa(titulo: ejercicio.nombre,
                         principales: Set(ejercicio.principales),
                         secundarios: Set(ejercicio.secundarios))
        }
    }

    private var dibujo: some View {
        VStack(spacing: 10) {
            MapaMuscularView(principales: Set(ejercicio.principales),
                             secundarios: Set(ejercicio.secundarios))
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Tema.suave))
                .contentShape(Rectangle())
                .onTapGesture { verZoom = true }
            HStack {
                LeyendaMapa()
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
        }
        .padding(12)
        .tarjeta()
    }

    private var musculos: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Músculos principales").font(.headline)
            FilaFlexible {
                ForEach(ejercicio.principales) { m in
                    Etiqueta(texto: m.nombre, color: MapaMuscularView.colorPrincipal)
                }
            }
            if !ejercicio.secundarios.isEmpty {
                Text("Músculos secundarios").font(.headline).padding(.top, 4)
                FilaFlexible {
                    ForEach(ejercicio.secundarios) { m in
                        Etiqueta(texto: m.nombre, color: MapaMuscularView.colorSecundario)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .tarjeta()
    }

    private var pasos: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Cómo se hace").font(.headline)
            ForEach(Array(ejercicio.pasos.enumerated()), id: \.offset) { i, paso in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(i + 1)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Tema.degradado))
                    Text(paso)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 3)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .tarjeta()
    }

    private var consejo: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.title3)
                .foregroundStyle(Tema.coral)
            VStack(alignment: .leading, spacing: 4) {
                Text("Consejo").font(.subheadline.bold()).foregroundStyle(Tema.coral)
                Text(ejercicio.consejo)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Tema.coral.opacity(0.12)))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Tema.coral.opacity(0.25)))
    }
}
