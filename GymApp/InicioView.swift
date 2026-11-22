import SwiftUI

/// Pantalla de inicio: logo, buscador, lugares, ejercicio del día y favoritos
struct InicioView: View {
    @EnvironmentObject private var estado: EstadoApp
    @EnvironmentObject private var favoritos: Favoritos
    @State private var busqueda = ""
    @State private var verInfo = false

    private var resultados: [Ejercicio] {
        Catalogo.ejercicios.filter { $0.coincide(con: busqueda) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    portada
                    buscador
                    if busqueda.isEmpty {
                        lugares
                        if let e = Catalogo.ejercicioDelDia { ejercicioDelDia(e) }
                        accesos
                        seccionFavoritos
                    }
                }
                .padding()
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
            .background(Tema.fondo.ignoresSafeArea())
            .navigationTitle("Inicio")
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
            .navigationDestination(for: Ejercicio.self) { e in
                DetalleEjercicioView(ejercicio: e)
            }
            .sheet(isPresented: $verInfo) {
                InfoView()
                    .environmentObject(favoritos)
            }
        }
    }

    // MARK: Portada con el logo

    private var saludo: String {
        let hora = Calendar.current.component(.hour, from: Date())
        switch hora {
        case 6..<14: return "¡Buenos días!"
        case 14..<21: return "¡Buenas tardes!"
        default: return "¡Buenas noches!"
        }
    }

    private var portada: some View {
        HStack(spacing: 16) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .padding(8)
                .frame(width: 96, height: 96)
                .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(.white))
                .shadow(color: .black.opacity(0.25), radius: 10, y: 5)

            VStack(alignment: .leading, spacing: 4) {
                Text(saludo)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                Text(Config.nombreApp)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(Catalogo.ejercicios.count) ejercicios con pesas, máquinas y en casa")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                Tema.degradado
                Circle()
                    .fill(Tema.coral.opacity(0.45))
                    .frame(width: 170, height: 170)
                    .blur(radius: 6)
                    .offset(x: 60, y: -70)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                Circle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 120, height: 120)
                    .offset(x: -20, y: 60)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Tema.azul.opacity(0.35), radius: 14, y: 8)
        .padding(.top, 4)
    }

    // MARK: Buscador

    private var buscador: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Tema.acento)
                TextField("Busca un ejercicio o un músculo", text: $busqueda)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .submitLabel(.search)
                    #endif
                    .onSubmit {
                        guard !busqueda.isEmpty else { return }
                        estado.abrirEjercicios(busqueda: busqueda)
                    }
                if !busqueda.isEmpty {
                    Button {
                        busqueda = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Borrar búsqueda")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .tarjeta(radio: 16)

            if !busqueda.isEmpty {
                if resultados.isEmpty {
                    Text("No hay ejercicios con «\(busqueda)».")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                } else {
                    ForEach(resultados.prefix(6)) { e in
                        NavigationLink(value: e) {
                            FilaEjercicio(ejercicio: e)
                        }
                        .buttonStyle(EstiloPulsado())
                    }
                    if resultados.count > 6 {
                        Button {
                            estado.abrirEjercicios(busqueda: busqueda)
                        } label: {
                            Label("Ver los \(resultados.count) resultados", systemImage: "arrow.right.circle.fill")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Tema.azul)
                    }
                }
            }
        }
    }

    // MARK: Lugares

    private var lugares: some View {
        VStack(alignment: .leading, spacing: 12) {
            TituloSeccion(titulo: "¿Dónde entrenas hoy?")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                ForEach(Lugar.allCases) { l in
                    Button {
                        estado.abrirEjercicios(lugar: l)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Image(systemName: l.icono)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 42, height: 42)
                                .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.22)))
                            Spacer(minLength: 8)
                            Text(l.nombre)
                                .font(.headline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Text("\(Catalogo.cantidad(en: l)) ejercicios")
                                .font(.caption.weight(.medium))
                                .opacity(0.85)
                        }
                        .foregroundStyle(.white)
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(l.degradado))
                        .shadow(color: l.color.opacity(0.35), radius: 8, y: 4)
                    }
                    .buttonStyle(EstiloPulsado())
                }
            }
        }
    }

    // MARK: Ejercicio del día

    private func ejercicioDelDia(_ e: Ejercicio) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TituloSeccion(titulo: "Ejercicio del día", icono: "sparkles")
            ZStack(alignment: .topTrailing) {
                NavigationLink(value: e) {
                    HStack(spacing: 14) {
                        MapaMuscularView(principales: Set(e.principales), secundarios: Set(e.secundarios))
                            .padding(8)
                            .frame(width: 140)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Tema.suave))
                        VStack(alignment: .leading, spacing: 8) {
                            EtiquetaLugar(lugar: e.lugar)
                            Text(e.nombre)
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(e.principales.map(\.nombre).joined(separator: " · "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 8) {
                                IndicadorNivel(nivel: e.nivel)
                                Text(e.series)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Tema.acento)
                            }
                        }
                        .padding(.trailing, 28)
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .tarjeta(radio: 20)
                }
                .buttonStyle(EstiloPulsado())
                BotonFavorito(ejercicio: e).padding(8)
            }
        }
    }

    // MARK: Accesos rápidos

    private var accesos: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            acceso(titulo: "Toca un músculo", subtitulo: "Mapa del cuerpo",
                   icono: "figure.strengthtraining.traditional", degradado: Tema.degradado) {
                estado.pestana = .musculos
            }
            acceso(titulo: "Mi plan", subtitulo: "Semana de entreno",
                   icono: "calendar", degradado: Tema.degradadoCoral) {
                estado.pestana = .plan
            }
            acceso(titulo: "Correr", subtitulo: "5 km a maratón",
                   icono: "figure.run", degradado: Tema.degradado) {
                estado.pestana = .correr
            }
            acceso(titulo: "Menús", subtitulo: "Según tu objetivo",
                   icono: "fork.knife", degradado: Tema.degradadoCoral) {
                estado.pestana = .menus
            }
            acceso(titulo: "Información", subtitulo: "Apariencia y web",
                   icono: "info.circle", degradado: Tema.degradado) {
                verInfo = true
            }
        }
    }

    private func acceso(titulo: String, subtitulo: String, icono: String,
                        degradado: LinearGradient, accion: @escaping () -> Void) -> some View {
        Button(action: accion) {
            HStack(spacing: 10) {
                Image(systemName: icono)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(degradado))
                VStack(alignment: .leading, spacing: 1) {
                    Text(titulo)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(subtitulo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .tarjeta(radio: 18)
        }
        .buttonStyle(EstiloPulsado())
    }

    // MARK: Favoritos

    private var seccionFavoritos: some View {
        VStack(alignment: .leading, spacing: 12) {
            TituloSeccion(titulo: "Mis favoritos", icono: "heart.fill",
                          boton: favoritos.ids.isEmpty ? nil : "Ver todos") {
                estado.abrirEjercicios(favoritos: true)
            }

            if favoritos.ids.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "heart")
                        .font(.title2)
                        .foregroundStyle(Tema.coral)
                    Text("Pulsa el corazón de un ejercicio para tenerlo siempre a mano aquí.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .tarjeta()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(favoritos.ejercicios) { e in
                            CeldaEjercicio(ejercicio: e)
                                .frame(width: 170)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .scrollClipDisabled()
            }
        }
    }
}

#Preview {
    InicioView()
        .environmentObject(EstadoApp())
        .environmentObject(Favoritos())
}
