import SwiftUI

// MARK: - Pestaña Menús

enum VistaMenus: String, CaseIterable, Identifiable {
    case menu, compra, registro
    var id: String { rawValue }
    var nombre: String {
        switch self {
        case .menu: return "Menú"
        case .compra: return "Compra"
        case .registro: return "Registro"
        }
    }
}

struct MenusView: View {
    // Datos de la persona (se guardan en el dispositivo)
    @AppStorage("menus.sexo") private var sexoGuardado: String = Sexo.hombre.rawValue
    @AppStorage("menus.edad") private var edad: Int = 30
    @AppStorage("menus.peso") private var peso: Double = 75
    @AppStorage("menus.altura") private var altura: Double = 175
    @AppStorage("menus.actividad") private var actividadId: String = "ligera"
    /// -1 = usar los días de «Mi plan»
    @AppStorage("menus.dias") private var diasGuardados: Int = -1
    @AppStorage("plan.dias") private var diasPlan: Int = 3
    @AppStorage("menus.datosRevisados") private var datosRevisados = false

    // Objetivo y filtros
    @AppStorage("menus.objetivo") private var objetivoId: String = "mantener"
    @AppStorage("menus.vegetariano") private var vegetariano = false
    @AppStorage("menus.sinGluten") private var sinGluten = false
    @AppStorage("menus.sinLactosa") private var sinLactosa = false

    // Menú y compra
    @AppStorage("menus.semilla") private var semilla: Int = 1
    @AppStorage("menus.cambios") private var cambiosTexto: String = ""
    @AppStorage("menus.personas") private var personas: Int = 1
    @AppStorage("menus.marcados") private var marcadosTexto: String = ""

    @State private var vista: VistaMenus = .menu
    @State private var diaElegido: Int = MenusView.hoy
    @State private var verDatos = false
    @StateObject private var registro = RegistroCorporal()

    /// Día de hoy (0 = lunes … 6 = domingo)
    static var hoy: Int {
        (Calendar(identifier: .gregorian).component(.weekday, from: Date()) + 5) % 7
    }

    private var dias: Int { diasGuardados >= 0 ? diasGuardados : diasPlan }

    private var filtros: FiltrosDieta {
        FiltrosDieta(vegetariano: vegetariano, sinGluten: sinGluten, sinLactosa: sinLactosa)
    }

    private var cambios: [String: Int] {
        var d: [String: Int] = [:]
        for par in cambiosTexto.split(separator: ",") {
            let partes = par.split(separator: "=")
            if partes.count == 2, let n = Int(partes[1]) { d[String(partes[0])] = n }
        }
        return d
    }

    var body: some View {
        NavigationStack {
            Group {
                if let datos = CatalogoMenus.datos, !datos.objetivos.isEmpty, !datos.actividad.isEmpty {
                    contenido(datos)
                } else {
                    ContentUnavailableView("No se encuentra menus.json",
                                           systemImage: "exclamationmark.triangle",
                                           description: Text("Comprueba que el archivo menus.json está dentro de la carpeta GymApp del proyecto."))
                }
            }
            .background(Tema.fondo.ignoresSafeArea())
            .navigationTitle("Menús")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        otraSemana()
                    } label: {
                        Label("Otra semana", systemImage: "shuffle")
                    }
                    .help("Proponer otros platos para toda la semana")
                }
            }
            .sheet(isPresented: $verDatos, onDismiss: { datosRevisados = true }) {
                DatosNutricionView(sexo: $sexoGuardado, edad: $edad, peso: $peso, altura: $altura,
                                   actividad: $actividadId,
                                   dias: Binding(get: { dias }, set: { diasGuardados = $0 }),
                                   actividades: CatalogoMenus.datos?.actividad ?? [],
                                   aviso: CatalogoMenus.datos?.aviso ?? "")
            }
        }
    }

    // MARK: Contenido

    private func contenido(_ datos: DatosMenus) -> some View {
        let objetivo = datos.objetivos.first { $0.id == objetivoId } ?? datos.objetivos[0]
        let actividad = datos.actividad.first { $0.id == actividadId } ?? datos.actividad[0]
        let sexo = Sexo(rawValue: sexoGuardado) ?? .hombre
        let perfil = PerfilNutricion(sexo: sexo, edad: edad, peso: peso, altura: altura,
                                     actividad: actividad, diasEntreno: dias, objetivo: objetivo)
        let necesidades = CalculadoraNutricion.calcular(perfil, datos.calculo)
        let semana = GeneradorMenus.semana(necesidades: necesidades, diasEntreno: dias, objetivo: objetivo,
                                           filtros: filtros, semilla: semilla, cambios: cambios)
        let textoPerfil = "\(sexo.nombre) · \(edad) años · \(Formato.numero(peso, decimales: 1)) kg · \(Formato.numero(altura)) cm · \(actividad.nombre.lowercased()) · \(dias) \(dias == 1 ? "día" : "días") de entreno"

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                avisoCorto

                ResumenNecesidadesView(necesidades: necesidades, objetivo: objetivo, textoPerfil: textoPerfil,
                                       dias: dias, pedirDatos: !datosRevisados) {
                    verDatos = true
                }

                selectorObjetivo(datos.objetivos, elegido: objetivo)
                selectorFiltros

                Picker("Vista", selection: $vista) {
                    ForEach(VistaMenus.allCases) { v in
                        Text(v.nombre).tag(v)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                if vista == .registro {
                    RegistroView(registro: registro, peso: $peso, altura: $altura)
                } else if semana.isEmpty || semana.allSatisfy({ $0.comidas.isEmpty }) {
                    ContentUnavailableView("No hay platos con estos filtros",
                                           systemImage: "fork.knife",
                                           description: Text("Prueba a quitar algún filtro."))
                } else if vista == .menu {
                    MenuSemanaView(semana: semana, diaElegido: $diaElegido) { dia, comida in
                        cambiar(dia: dia, comida: comida)
                    }
                    consejos(objetivo)
                } else {
                    ListaCompraView(secciones: ListaCompra.crear(semana: semana, personas: personas),
                                    personas: $personas, marcadosTexto: $marcadosTexto)
                }

                avisoCompleto(datos)
            }
            .padding()
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Partes

    private var avisoCorto: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Tema.coral)
            Text("Menús y cifras **orientativos**. No sustituyen el consejo de un dietista-nutricionista.")
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Tema.coral.opacity(0.12)))
    }

    private func selectorObjetivo(_ objetivos: [ObjetivoNutricion], elegido: ObjetivoNutricion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            TituloSeccion(titulo: "Objetivo", icono: "target")
            FilaFlexible {
                ForEach(objetivos) { o in
                    Chip(texto: o.nombre, icono: o.icono, seleccionado: o.id == elegido.id) {
                        objetivoId = o.id
                    }
                }
            }
            Text(elegido.descripcion)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var selectorFiltros: some View {
        VStack(alignment: .leading, spacing: 10) {
            TituloSeccion(titulo: "Tipo de dieta", icono: "line.3.horizontal.decrease.circle")
            FilaFlexible {
                Chip(texto: "Vegetariano", icono: "leaf.fill", seleccionado: vegetariano, color: .green) {
                    vegetariano.toggle()
                }
                Chip(texto: "Sin gluten", icono: "laurel.leading", seleccionado: sinGluten, color: Tema.coral) {
                    sinGluten.toggle()
                }
                Chip(texto: "Sin lactosa", icono: "drop.fill", seleccionado: sinLactosa, color: Tema.azul) {
                    sinLactosa.toggle()
                }
            }
            Text(textoFiltros)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var textoFiltros: String {
        var partes: [String] = []
        if vegetariano { partes.append("sin carne ni pescado (con huevos y lácteos)") }
        if sinGluten { partes.append("pan, pasta y avena sin gluten") }
        if sinLactosa { partes.append("lácteos sin lactosa") }
        if partes.isEmpty { return "Dieta mediterránea variada. Puedes combinar los filtros." }
        return "Menús " + partes.joined(separator: ", ") + ". Revisa siempre las etiquetas de los productos."
    }

    private func consejos(_ objetivo: ObjetivoNutricion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Consejos: \(objetivo.nombre.lowercased())", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(Tema.coral)
            ForEach(objetivo.consejos, id: \.self) { c in
                Label {
                    Text(c).fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Tema.acento)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .tarjeta()
    }

    private func avisoCompleto(_ datos: DatosMenus) -> some View {
        VStack(spacing: 6) {
            Text(datos.aviso)
            Text("Calorías calculadas con la fórmula \(datos.calculo.formula) y raciones ajustadas a tus datos.")
        }
        .font(.footnote)
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }

    // MARK: Acciones

    private func otraSemana() {
        semilla += 1
        cambiosTexto = ""
        marcadosTexto = ""
    }

    private func cambiar(dia: DiaMenu, comida: ComidaMenu) {
        var d = cambios
        d["\(dia.indice)-\(comida.tipo.id)", default: 0] += 1
        cambiosTexto = d.keys.sorted().map { "\($0)=\(d[$0] ?? 0)" }.joined(separator: ",")
    }
}

// MARK: - Tarjeta con las calorías y nutrientes

struct ResumenNecesidadesView: View {
    let necesidades: Necesidades
    let objetivo: ObjetivoNutricion
    let textoPerfil: String
    let dias: Int
    let pedirDatos: Bool
    let editar: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(objetivo.nombre, systemImage: objetivo.icono)
                    .font(.subheadline.weight(.bold))
                Spacer()
                Button(action: editar) {
                    Label("Mis datos", systemImage: "person.crop.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Tema.azulOscuro)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(.white))
                }
                .buttonStyle(EstiloPulsado())
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(Formato.numero(necesidades.kcal))
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                Text("kcal al día (media)")
                    .font(.subheadline.weight(.semibold))
                    .opacity(0.9)
            }

            HStack(spacing: 8) {
                nutriente("Proteína", necesidades.proteinas)
                nutriente("Hidratos", necesidades.hidratos)
                nutriente("Grasas", necesidades.grasas)
            }

            if dias > 0 && dias < 7 {
                Label("Entreno: \(Formato.kcal(necesidades.kcalEntreno)) · Descanso: \(Formato.kcal(necesidades.kcalDescanso))",
                      systemImage: "figure.strengthtraining.traditional")
                    .font(.caption.weight(.semibold))
            }

            Text(textoPerfil)
                .font(.caption)
                .opacity(0.85)
                .fixedSize(horizontal: false, vertical: true)

            if necesidades.ajustadoAlMinimo {
                Label("Hemos subido las calorías al mínimo recomendado. No es aconsejable comer menos sin control profesional.",
                      systemImage: "exclamationmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if pedirDatos {
                Button(action: editar) {
                    Label("Pon tus datos para ajustar las calorías", systemImage: "hand.point.right.fill")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(.white)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Tema.degradadoCoral))
                }
                .buttonStyle(EstiloPulsado())
            }
        }
        .foregroundStyle(.white)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Tema.degradado))
        .shadow(color: Tema.azul.opacity(0.3), radius: 12, y: 6)
    }

    private func nutriente(_ nombre: String, _ gramos: Double) -> some View {
        VStack(spacing: 2) {
            Text(Formato.gramos(gramos))
                .font(.headline)
            Text(nombre)
                .font(.caption2.weight(.semibold))
                .opacity(0.85)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.16)))
    }
}

// MARK: - Menú de la semana

struct MenuSemanaView: View {
    let semana: [DiaMenu]
    @Binding var diaElegido: Int
    let cambiar: (DiaMenu, ComidaMenu) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                ForEach(semana) { d in
                    botonDia(d)
                }
            }
            Label("El punto coral marca los días de entreno.", systemImage: "circle.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
                .labelStyle(PuntoCoral())

            if let dia = semana.first(where: { $0.indice == diaElegido }) ?? semana.first {
                cabecera(dia)
                if dia.macros.kcal < dia.objetivoKcal * 0.9 {
                    Label("Este menú se queda corto para tus calorías: añade pan, fruta, frutos secos, legumbres o un tentempié más.",
                          systemImage: "plus.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Tema.coral)
                        .fixedSize(horizontal: false, vertical: true)
                } else if dia.macros.kcal > dia.objetivoKcal * 1.1 {
                    Label("Este menú pasa un poco de tus calorías: reduce algo el pan, el arroz o la pasta.",
                          systemImage: "minus.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Tema.coral)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ForEach(dia.comidas) { c in
                    TarjetaComidaMenu(comida: c) {
                        cambiar(dia, c)
                    }
                }
            }
        }
    }

    private func botonDia(_ d: DiaMenu) -> some View {
        let elegido = d.indice == diaElegido
        return Button {
            withAnimation(.easeOut(duration: 0.2)) { diaElegido = d.indice }
        } label: {
            VStack(spacing: 4) {
                Text(GeneradorMenus.inicialesDias[d.indice])
                    .font(.subheadline.weight(.bold))
                Circle()
                    .fill(d.entreno ? Tema.coral : Color.clear)
                    .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .foregroundStyle(elegido ? Color.white : Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(elegido ? AnyShapeStyle(Tema.degradado) : AnyShapeStyle(Tema.tarjeta))
            )
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Tema.borde))
            .contentShape(Rectangle())
        }
        .buttonStyle(EstiloPulsado())
        .accessibilityLabel(d.nombre + (d.entreno ? ", día de entreno" : ""))
    }

    private func cabecera(_ dia: DiaMenu) -> some View {
        let m = dia.macros
        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dia.nombre)
                    .font(.title3.bold())
                Text(dia.entreno ? "Día de entreno" : "Día de descanso")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(dia.entreno ? Tema.coral : Color.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Formato.kcal(m.kcal))
                    .font(.headline)
                Text("Proteína \(Formato.gramos(m.proteinas)) · Objetivo \(Formato.kcal(dia.objetivoKcal))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.top, 4)
    }
}

/// Estilo de etiqueta con un punto coral pequeño
private struct PuntoCoral: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            Circle().fill(Tema.coral).frame(width: 6, height: 6)
            configuration.title
        }
    }
}

struct TarjetaComidaMenu: View {
    let comida: ComidaMenu
    let cambiar: () -> Void
    @State private var abierto = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: comida.tipo.icono)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Tema.degradado))
                VStack(alignment: .leading, spacing: 3) {
                    Text(comida.tipo.nombre.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Tema.acento)
                    Text(comida.plato.nombre)
                        .font(.subheadline.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(Formato.kcal(comida.macros.kcal)) · \(Formato.gramos(comida.macros.proteinas)) proteína · \(comida.plato.minutos) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }

            HStack {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { abierto.toggle() }
                } label: {
                    Label(abierto ? "Ocultar" : "Ingredientes y preparación",
                          systemImage: abierto ? "chevron.up" : "list.bullet")
                }
                Spacer()
                Button(action: cambiar) {
                    Label("Cambiar", systemImage: "arrow.triangle.2.circlepath")
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Tema.acento)
            .buttonStyle(.plain)

            if abierto {
                VStack(alignment: .leading, spacing: 6) {
                    if abs(comida.escala - 1) > 0.01 {
                        Text("Ración ajustada ×\(Formato.numero(comida.escala, decimales: 1)) a tus calorías")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(Array(comida.lineas.enumerated()), id: \.offset) { _, l in
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("•").foregroundStyle(Tema.coral)
                            Text(l.ingrediente.nombre)
                            Spacer(minLength: 8)
                            Text(Formato.plato(l.cantidad, l.ingrediente))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                        .font(.footnote)
                    }
                    Text(comida.plato.preparacion)
                        .font(.footnote)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Tema.suave))
                        .padding(.top, 4)
                    Text("Sal, pimienta, especias, vinagre y hierbas al gusto.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .transition(.opacity)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tarjeta()
    }
}

// MARK: - Lista de la compra

struct ListaCompraView: View {
    let secciones: [SeccionCompra]
    @Binding var personas: Int
    @Binding var marcadosTexto: String

    private var marcados: Set<String> {
        Set(marcadosTexto.split(separator: ",").map(String.init))
    }

    private func alternar(_ id: String) {
        var m = marcados
        if m.contains(id) { m.remove(id) } else { m.insert(id) }
        marcadosTexto = m.sorted().joined(separator: ",")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 12) {
                Stepper(value: $personas, in: 1...8) {
                    Label("Para \(personas) \(personas == 1 ? "persona" : "personas")", systemImage: "person.2.fill")
                        .font(.headline)
                }
                Text("Cantidades para los 7 días del menú, redondeadas hacia arriba. Toca un producto para tacharlo.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 10) {
                    ShareLink(item: ListaCompra.texto(secciones, marcados: marcados)) {
                        Label("Compartir", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Tema.azul)
                    Button("Desmarcar todo") { marcadosTexto = "" }
                        .buttonStyle(.bordered)
                        .disabled(marcados.isEmpty)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .tarjeta()

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 14, alignment: .top)],
                      alignment: .leading, spacing: 14) {
                ForEach(secciones) { s in
                    seccion(s)
                }
            }
        }
    }

    private func seccion(_ s: SeccionCompra) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(s.nombre)
                .font(.headline)
                .padding(.bottom, 6)
            ForEach(s.articulos) { a in
                fila(a)
                if a.id != s.articulos.last?.id { Divider() }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .tarjeta()
    }

    private func fila(_ a: ArticuloCompra) -> some View {
        let hecho = marcados.contains(a.id)
        return Button {
            withAnimation(.easeOut(duration: 0.15)) { alternar(a.id) }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: hecho ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(hecho ? Color.green : Color.secondary)
                Text(a.ingrediente.nombre)
                    .strikethrough(hecho)
                    .foregroundStyle(hecho ? Color.secondary : Color.primary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                Text(Formato.compra(a.cantidad, a.ingrediente))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(hecho ? Color.secondary : Tema.acento)
                    .multilineTextAlignment(.trailing)
            }
            .font(.subheadline)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Hoja «Mis datos»

struct DatosNutricionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var sexo: String
    @Binding var edad: Int
    @Binding var peso: Double
    @Binding var altura: Double
    @Binding var actividad: String
    @Binding var dias: Int
    let actividades: [NivelActividad]
    let aviso: String

    var body: some View {
        NavigationStack {
            Form {
                Section("Tú") {
                    Picker("Sexo", selection: $sexo) {
                        ForEach(Sexo.allCases) { s in
                            Text(s.nombre).tag(s.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)

                    filaEntero("Edad", valor: $edad, rango: 18...90, unidad: "años")
                    filaDecimal("Peso", valor: $peso, rango: 35...200, paso: 0.5, unidad: "kg")
                    filaDecimal("Altura", valor: $altura, rango: 120...220, paso: 1, unidad: "cm")
                }

                Section {
                    Picker("Actividad diaria", selection: $actividad) {
                        ForEach(actividades) { a in
                            Text("\(a.nombre) · \(a.descripcion)").tag(a.id)
                        }
                    }
                    Stepper(value: $dias, in: 0...7) {
                        Text("Días de entreno a la semana: **\(dias)**")
                    }
                } header: {
                    Text("Actividad")
                } footer: {
                    Text("En «Actividad diaria» no cuentes el gimnasio: los días de entreno se suman aparte. Al principio se usan los días de «Mi plan».")
                }

                Section {
                    Text(aviso)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Mis datos")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 580)
        #endif
    }

    private func filaEntero(_ titulo: String, valor: Binding<Int>, rango: ClosedRange<Int>, unidad: String) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            TextField(titulo, value: valor, format: .number)
                .multilineTextAlignment(.trailing)
                .frame(width: 70)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
            Text(unidad).foregroundStyle(.secondary)
            Stepper(titulo, value: valor, in: rango)
                .labelsHidden()
        }
    }

    private func filaDecimal(_ titulo: String, valor: Binding<Double>, rango: ClosedRange<Double>,
                             paso: Double, unidad: String) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            TextField(titulo, value: valor, format: .number.precision(.fractionLength(0...1)))
                .multilineTextAlignment(.trailing)
                .frame(width: 70)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
            Text(unidad).foregroundStyle(.secondary)
            Stepper(titulo, value: valor, in: rango, step: paso)
                .labelsHidden()
        }
    }
}

#Preview {
    MenusView()
}
