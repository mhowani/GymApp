import SwiftUI
import Charts

// MARK: - Colores de correr.json ("azul", "coral"…)

enum ColoresCorrer {
    static func color(_ nombre: String) -> Color {
        switch nombre {
        case "azulOscuro": return Tema.azulOscuro
        case "azul": return Tema.azul
        case "celeste": return Tema.celeste
        case "coral": return Tema.coral
        case "coralClaro": return Tema.coralClaro
        case "rojo": return .red
        case "morado": return .purple
        case "verde": return .green
        default: return .gray
        }
    }

    /// Igual, pero que se lea bien como texto en modo oscuro
    static func texto(_ nombre: String) -> Color {
        nombre == "azulOscuro" ? Tema.acento : color(nombre)
    }
}

private let espanol = Locale(identifier: "es_ES")

// MARK: - Pestaña Correr

struct CorrerView: View {
    @AppStorage("correr.distancia") private var distancia: Double = 10
    @AppStorage("correr.nivel") private var nivelId: String = "intermedio"
    @AppStorage("correr.dias") private var dias: Int = 4
    @AppStorage("correr.semanas") private var semanas: Int = 10
    /// Lunes de la primera semana (segundos desde 2001; 0 = sin elegir)
    @AppStorage("correr.inicio") private var inicioGuardado: Double = 0
    @AppStorage("correr.refKm") private var refKm: Double = 5
    @AppStorage("correr.refSegundos") private var refSegundos: Double = 0
    @AppStorage("correr.hechos") private var hechosTexto: String = ""
    @AppStorage("plan.dias") private var diasGimnasio: Int = 3

    @State private var semanaElegida: Int? = nil
    @State private var verCalculadora = false

    private var inicio: Date {
        inicioGuardado > 0 ? Date(timeIntervalSinceReferenceDate: inicioGuardado)
                           : GeneradorCorrer.inicioPorDefecto()
    }

    private var referencia: TiempoReferencia? {
        refSegundos > 0 && refKm > 0 ? TiempoReferencia(km: refKm, segundos: refSegundos) : nil
    }

    private var hechos: Set<String> {
        Set(hechosTexto.split(separator: ",").map(String.init))
    }

    var body: some View {
        NavigationStack {
            Group {
                if let datos = CatalogoCorrer.datos, !datos.niveles.isEmpty, !datos.distancias.isEmpty {
                    contenido(datos)
                } else {
                    ContentUnavailableView("No se encuentra correr.json",
                                           systemImage: "exclamationmark.triangle",
                                           description: Text("Comprueba que el archivo correr.json está dentro de la carpeta GymApp del proyecto."))
                }
            }
            .background(Tema.fondo.ignoresSafeArea())
            .navigationTitle("Correr")
            .navigationDestination(for: Ejercicio.self) { e in
                DetalleEjercicioView(ejercicio: e)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            empezar(semanaQueViene: false)
                        } label: {
                            Label("Empezar esta semana", systemImage: "play.fill")
                        }
                        Button {
                            empezar(semanaQueViene: true)
                        } label: {
                            Label("Empezar la semana que viene", systemImage: "calendar.badge.plus")
                        }
                    } label: {
                        Label("Empezar el plan", systemImage: "calendar.badge.clock")
                    }
                    .help("Elegir cuándo empieza el plan (borra las sesiones marcadas como hechas)")
                }
            }
            .sheet(isPresented: $verCalculadora) {
                if let datos = CatalogoCorrer.datos {
                    CalculadoraRitmoView(datos: datos, objetivoKm: distancia,
                                         refKm: $refKm, refSegundos: $refSegundos)
                }
            }
            .onAppear {
                if inicioGuardado == 0 {
                    inicioGuardado = GeneradorCorrer.inicioPorDefecto().timeIntervalSinceReferenceDate
                }
            }
        }
    }

    // MARK: Acciones

    private func empezar(semanaQueViene: Bool) {
        let lunes = GeneradorCorrer.lunes(de: Date())
        let fecha = semanaQueViene ? (Calendar.current.date(byAdding: .day, value: 7, to: lunes) ?? lunes) : lunes
        inicioGuardado = fecha.timeIntervalSinceReferenceDate
        hechosTexto = ""
        semanaElegida = nil
    }

    private func alternarHecho(_ id: String) {
        var lista = hechos
        if lista.contains(id) { lista.remove(id) } else { lista.insert(id) }
        hechosTexto = lista.sorted().joined(separator: ",")
    }

    /// Semana del plan en la que estamos hoy (1 si aún no ha empezado)
    private func semanaActual(_ plan: PlanCorrer) -> Int {
        let cal = Calendar.current
        let dias = cal.dateComponents([.day], from: cal.startOfDay(for: inicio),
                                      to: cal.startOfDay(for: Date())).day ?? 0
        guard dias >= 0 else { return 1 }
        return min(dias / 7 + 1, max(plan.semanas.count, 1))
    }

    private var haEmpezado: Bool {
        Calendar.current.startOfDay(for: Date()) >= Calendar.current.startOfDay(for: inicio)
    }

    // MARK: Contenido

    private func contenido(_ datos: DatosCorrer) -> some View {
        let nivel = datos.niveles.first { $0.id == nivelId } ?? datos.niveles[0]
        let diasValidos = min(max(dias, nivel.diasMin), nivel.diasMax)
        let semanasValidas = min(max(semanas, datos.semanas.min), datos.semanas.max)
        let opciones = OpcionesPlan(distanciaKm: distancia, nivel: nivel, dias: diasValidos,
                                    semanas: semanasValidas, inicio: inicio, referencia: referencia)
        let plan = GeneradorCorrer.plan(opciones, datos)
        let actual = semanaActual(plan)
        let numero = min(max(semanaElegida ?? actual, 1), max(plan.semanas.count, 1))

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AvisoCorrer(texto: Text("Planes y ritmos **orientativos**. Si empiezas desde cero o tienes alguna lesión, consulta antes con tu médico."),
                            icono: "exclamationmark.triangle.fill")

                selectorDistancia(datos)
                selectorNivel(datos, elegido: nivel)
                selectorSemana(datos, nivel: nivel, dias: diasValidos, semanas: semanasValidas, plan: plan)

                RitmosCorrerView(datos: datos, referencia: referencia, objetivoKm: distancia) {
                    verCalculadora = true
                }

                ResumenPlanCorrerView(datos: datos, plan: plan, elegida: numero,
                                      actual: haEmpezado ? actual : 0) { n in
                    semanaElegida = n
                }

                ForEach(plan.avisos, id: \.self) { aviso in
                    AvisoCorrer(texto: Text(verbatim: aviso), icono: "info.circle.fill", color: Tema.azul)
                }

                if let semana = plan.semanas.first(where: { $0.id == numero }) {
                    SemanaCorrerView(datos: datos, semana: semana, total: plan.semanas.count,
                                     esActual: haEmpezado && numero == actual,
                                     referencia: referencia, objetivoKm: distancia,
                                     hechos: hechos, alternar: alternarHecho)
                }

                CalentamientoCorrerView(datos: datos)
                FuerzaCorredorSeccion(datos: datos, diasGimnasio: diasGimnasio)
                consejos(datos)

                Text(datos.aviso)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Distancia (chips y barra deslizante)

    private func selectorDistancia(_ datos: DatosCorrer) -> some View {
        let preset = datos.distancias.first { abs($0.km - distancia) < 0.05 }
        return VStack(alignment: .leading, spacing: 12) {
            TituloSeccion(titulo: "Distancia objetivo", icono: "flag.checkered")
            FilaFlexible {
                ForEach(datos.distancias) { d in
                    Chip(texto: d.nombre, icono: d.icono, seleccionado: preset?.id == d.id) {
                        distancia = d.km
                        semanaElegida = nil
                    }
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(Formato.km(distancia))
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Tema.acento)
                    .contentTransition(.numericText())
                Text(preset?.nombre ?? "Distancia a medida")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            Slider(value: Binding(get: { distancia },
                                  set: { distancia = datos.ajustarDistancia($0) }),
                   in: datos.deslizador.min...datos.deslizador.max) {
                Text("Distancia objetivo")
            } minimumValueLabel: {
                Text(Formato.km(datos.deslizador.min)).font(.caption)
            } maximumValueLabel: {
                Text(Formato.km(datos.deslizador.max)).font(.caption)
            }
            .tint(Tema.coral)
            Text("Mueve la barra si quieres hacer menos kilómetros: los km de cada semana, las tiradas largas y las series se adaptan solos.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .tarjeta()
    }

    // MARK: Nivel

    private func selectorNivel(_ datos: DatosCorrer, elegido: NivelCorredor) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            TituloSeccion(titulo: "Nivel", icono: "chart.bar.fill")
            FilaFlexible {
                ForEach(datos.niveles) { n in
                    Chip(texto: n.nombre, icono: n.icono, seleccionado: n.id == elegido.id, color: Tema.coral) {
                        nivelId = n.id
                        dias = min(max(dias, n.diasMin), n.diasMax)
                        semanaElegida = nil
                    }
                }
            }
            Text(elegido.descripcion)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Días y semanas

    private func selectorSemana(_ datos: DatosCorrer, nivel: NivelCorredor, dias diasValidos: Int,
                                semanas semanasValidas: Int, plan: PlanCorrer) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TituloSeccion(titulo: "Tu calendario", icono: "calendar")

            Stepper(value: Binding(get: { diasValidos }, set: { dias = $0 }),
                    in: nivel.diasMin...nivel.diasMax) {
                HStack {
                    Label("Días para correr", systemImage: "figure.run")
                    Spacer()
                    Text("\(diasValidos)").font(.headline).monospacedDigit()
                }
            }

            Stepper(value: Binding(get: { semanasValidas }, set: { semanas = $0; semanaElegida = nil }),
                    in: datos.semanas.min...datos.semanas.max) {
                HStack {
                    Label("Semanas hasta la carrera", systemImage: "hourglass")
                    Spacer()
                    Text("\(semanasValidas)").font(.headline).monospacedDigit()
                }
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: semanasValidas >= plan.semanasMinimas ? "checkmark.seal.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(semanasValidas >= plan.semanasMinimas ? Color.green : Tema.coral)
                Text("Para \(datos.nombreDistancia(distancia)) en este nivel se recomiendan \(plan.semanasRecomendadas) semanas (mínimo \(plan.semanasMinimas)).")
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if semanasValidas != plan.semanasRecomendadas {
                    Button("Usar \(plan.semanasRecomendadas)") {
                        semanas = plan.semanasRecomendadas
                        semanaElegida = nil
                    }
                    .font(.footnote.weight(.semibold))
                    .buttonStyle(.bordered)
                    .tint(Tema.acento)
                }
            }

            Divider()

            HStack(spacing: 8) {
                Image(systemName: "play.circle.fill").foregroundStyle(Tema.acento)
                Text("Empieza el **\(inicio.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(espanol)))**")
                    .font(.subheadline)
            }
            HStack(spacing: 8) {
                Image(systemName: "flag.checkered").foregroundStyle(Tema.coral)
                Text("Carrera el **\(plan.fechaCarrera.formatted(.dateTime.weekday(.wide).day().month(.wide).year().locale(espanol)))**")
                    .font(.subheadline)
            }
            Text("Para cambiar el día de inicio, pulsa el botón del calendario de arriba.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .tarjeta()
    }

    // MARK: Consejos

    private func consejos(_ datos: DatosCorrer) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            TituloSeccion(titulo: "Consejos", icono: "lightbulb.fill")
            ForEach(datos.consejos, id: \.self) { c in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Tema.coral)
                    Text(c)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(16)
        .tarjeta()
    }
}

// MARK: - Aviso de color

struct AvisoCorrer: View {
    let texto: Text
    var icono: String = "exclamationmark.triangle.fill"
    var color: Color = Tema.coral

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icono)
                .foregroundStyle(color)
            texto
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(color.opacity(0.12)))
    }
}

// MARK: - Fila de una zona de ritmo

struct FilaZonaRitmo: View {
    let zona: ZonaRitmo
    var rango: (rapido: Double, lento: Double)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(ColoresCorrer.color(zona.color))
                .frame(width: 10, height: 10)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 2) {
                Text(zona.nombre)
                    .font(.subheadline.weight(.semibold))
                Text(zona.sensacion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 6)
            if let rango {
                Text("\(Formato.minutosSegundos(rango.rapido))–\(Formato.ritmo(rango.lento))")
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(ColoresCorrer.texto(zona.color))
                    .lineLimit(1)
                    .fixedSize()
            }
        }
    }
}

// MARK: - Tarjeta de ritmos

struct RitmosCorrerView: View {
    let datos: DatosCorrer
    let referencia: TiempoReferencia?
    let objetivoKm: Double
    let abrir: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TituloSeccion(titulo: "Tus ritmos", icono: "speedometer",
                          boton: referencia == nil ? nil : "Cambiar", accion: abrir)
            if let ref = referencia {
                let prediccion = CalculadoraRitmo.prediccion(ref, km: objetivoKm, exponente: datos.riegel)
                Text("Con \(Formato.km(ref.km)) en \(Formato.tiempo(ref.segundos)) · \(Formato.ritmo(CalculadoraRitmo.ritmo(segundos: ref.segundos, km: ref.km)))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                HStack {
                    Label("Tiempo estimado en \(datos.nombreDistancia(objetivoKm))", systemImage: "stopwatch")
                        .font(.subheadline)
                    Spacer()
                    Text(Formato.tiempo(prediccion))
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(Tema.acento)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Tema.suave))
                ForEach(datos.zonas) { z in
                    FilaZonaRitmo(zona: z, rango: CalculadoraRitmo.rango(z, ref: ref, objetivoKm: objetivoKm,
                                                                         exponente: datos.riegel))
                }
                Text("Estimación con la fórmula de Riegel: es fiable si entrenas para esa distancia. Con calor, cuestas o viento, ve más lento.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Añade un tiempo reciente (por ejemplo, lo que tardas en 5 km) y verás a qué ritmo hacer cada entreno. Mientras tanto, guíate por las sensaciones:")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(datos.zonas) { z in
                    FilaZonaRitmo(zona: z)
                }
                Button(action: abrir) {
                    Label("Calcular mis ritmos", systemImage: "stopwatch")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Tema.acento)
            }
        }
        .padding(16)
        .tarjeta()
    }
}

// MARK: - Resumen del plan (datos, gráfico y semanas)

struct ResumenPlanCorrerView: View {
    let datos: DatosCorrer
    let plan: PlanCorrer
    let elegida: Int
    /// 0 si el plan aún no ha empezado
    let actual: Int
    let elegir: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TituloSeccion(titulo: "Tu plan", icono: "chart.bar.xaxis")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                dato("Semanas", "\(plan.semanas.count)", "calendar")
                dato("Semana más alta", Formato.km(plan.kmSemanaMaxima), "chart.line.uptrend.xyaxis")
                dato("Tirada más larga", Formato.km(plan.tiradaMasLarga), "road.lanes")
                dato("Km en total", Formato.numero(plan.kmTotales) + " km", "sum")
            }

            Chart(plan.semanas) { s in
                BarMark(x: .value("Semana", s.id), y: .value("Km", s.km))
                    .foregroundStyle(ColoresCorrer.color(s.fase.color).opacity(s.id == elegida ? 1 : 0.5))
                    .cornerRadius(3)
            }
            .chartXSelection(value: Binding<Int?>(get: { nil }, set: { if let v = $0 { elegir(v) } }))
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 150)
            .accessibilityLabel("Kilómetros de cada semana")

            FilaFlexible(espacio: 12) {
                ForEach(fasesDelPlan) { f in
                    HStack(spacing: 5) {
                        Circle().fill(ColoresCorrer.color(f.color)).frame(width: 9, height: 9)
                        Text(f.nombre).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            selectorSemanas
        }
        .padding(16)
        .tarjeta()
    }

    private var fasesDelPlan: [FaseCorrer] {
        datos.fases.filter { f in plan.semanas.contains { $0.fase.id == f.id } }
    }

    private func dato(_ titulo: String, _ valor: String, _ icono: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(titulo, systemImage: icono)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(valor)
                .font(.title3.bold())
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Tema.suave))
    }

    private var selectorSemanas: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(plan.semanas) { s in
                        let seleccionada = s.id == elegida
                        let color = ColoresCorrer.color(s.fase.color)
                        Button {
                            elegir(s.id)
                        } label: {
                            VStack(spacing: 3) {
                                Text("S\(s.id)")
                                    .font(.subheadline.weight(.bold))
                                Text(Formato.numero(s.km) + " km")
                                    .font(.caption2)
                                    .monospacedDigit()
                                Capsule()
                                    .fill(seleccionada ? Color.white : color)
                                    .frame(width: 18, height: 4)
                            }
                            .foregroundStyle(seleccionada ? Color.white : Color.primary)
                            .frame(width: 58, height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(seleccionada ? AnyShapeStyle(color.gradient) : AnyShapeStyle(Tema.suave))
                            )
                            .overlay(alignment: .topTrailing) {
                                if s.id == actual {
                                    Circle().fill(Tema.coral).frame(width: 8, height: 8).padding(5)
                                }
                            }
                        }
                        .buttonStyle(EstiloPulsado())
                        .id(s.id)
                        .accessibilityLabel("Semana \(s.id), \(Formato.km(s.km)), \(s.fase.nombre)")
                    }
                }
                .padding(.vertical, 2)
            }
            .onAppear { proxy.scrollTo(elegida, anchor: .center) }
            .onChange(of: elegida) { _, nueva in
                withAnimation { proxy.scrollTo(nueva, anchor: .center) }
            }
        }
    }
}

// MARK: - Una semana del plan

struct SemanaCorrerView: View {
    let datos: DatosCorrer
    let semana: SemanaPlanCorrer
    let total: Int
    let esActual: Bool
    let referencia: TiempoReferencia?
    let objetivoKm: Double
    let hechos: Set<String>
    let alternar: (String) -> Void

    private var fechas: String {
        let formato = Date.FormatStyle.dateTime.day().month(.abbreviated).locale(espanol)
        let desde: String = semana.inicio.formatted(formato)
        let hasta: String = semana.fin.formatted(formato)
        return "\(desde) – \(hasta)"
    }

    private var marcables: [SesionPlan] {
        semana.dias.flatMap(\.sesiones).filter(\.sePuedeMarcar)
    }

    private var hechas: Int {
        marcables.filter { hechos.contains($0.id) }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Semana \(semana.id) de \(total)")
                    .font(.title3.bold())
                Spacer()
                Text(Formato.km(semana.km))
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(Tema.acento)
            }
            FilaFlexible(espacio: 6) {
                if esActual {
                    Etiqueta(texto: "Esta semana", icono: "star.fill", color: Tema.coral)
                }
                Etiqueta(texto: semana.fase.nombre, icono: "circle.fill", color: ColoresCorrer.texto(semana.fase.color))
                Etiqueta(texto: fechas, icono: "calendar")
                if semana.descarga {
                    Etiqueta(texto: "Descarga", icono: "arrow.down.circle.fill", color: .green)
                }
                if semana.minutos > 0 {
                    Etiqueta(texto: "≈ \(Formato.duracion(semana.minutos)) corriendo", icono: "clock")
                }
                if !marcables.isEmpty {
                    Etiqueta(texto: "\(hechas)/\(marcables.count) hechas", icono: "checkmark.circle",
                             color: hechas == marcables.count ? .green : .secondary)
                }
            }
            Text(semana.descarga
                 ? "Semana de descarga: menos km para que el cuerpo asimile el trabajo y vuelvas con más fuerza."
                 : semana.fase.descripcion)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if semana.correrCaminar {
                AvisoCorrer(texto: Text("Si una semana de correr y caminar se te hace dura, **repítela** antes de pasar a la siguiente."),
                            icono: "figure.walk", color: Tema.azul)
            }

            VStack(spacing: 10) {
                ForEach(semana.dias) { dia in
                    DiaCorrerView(datos: datos, dia: dia, referencia: referencia,
                                  objetivoKm: objetivoKm, hechos: hechos, alternar: alternar)
                }
            }
        }
    }
}

struct DiaCorrerView: View {
    let datos: DatosCorrer
    let dia: DiaPlanCorrer
    let referencia: TiempoReferencia?
    let objetivoKm: Double
    let hechos: Set<String>
    let alternar: (String) -> Void

    private static let cortos = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"]

    var body: some View {
        let esHoy = Calendar.current.isDateInToday(dia.fecha)
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 2) {
                Text(DiaCorrerView.cortos[dia.id])
                    .font(.subheadline.weight(.bold))
                Text(dia.fecha.formatted(.dateTime.day().locale(espanol)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 46)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(esHoy ? Tema.coral.opacity(0.22) : Tema.suave))
            .accessibilityLabel(dia.nombre + (esHoy ? ", hoy" : ""))

            VStack(spacing: 8) {
                ForEach(dia.sesiones) { s in
                    TarjetaSesionCorrer(datos: datos, sesion: s, referencia: referencia,
                                        objetivoKm: objetivoKm, hecho: hechos.contains(s.id)) {
                        alternar(s.id)
                    }
                }
            }
        }
    }
}

struct TarjetaSesionCorrer: View {
    let datos: DatosCorrer
    let sesion: SesionPlan
    let referencia: TiempoReferencia?
    let objetivoKm: Double
    let hecho: Bool
    let alternar: () -> Void

    private var tipo: TipoSesionCorrer? { datos.tipo(sesion.tipo) }
    private var color: Color { ColoresCorrer.color(tipo?.color ?? "gris") }

    var body: some View {
        if sesion.tipo == "descanso" {
            HStack(spacing: 10) {
                Image(systemName: tipo?.icono ?? "bed.double.fill")
                    .foregroundStyle(.secondary)
                    .frame(width: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text(sesion.titulo).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                    Text(sesion.nota ?? sesion.detalle).font(.caption).foregroundStyle(.tertiary)
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Tema.tarjeta.opacity(0.6)))
        } else {
            HStack(alignment: .top, spacing: 8) {
                if let id = sesion.fuerza, let fuerza = datos.sesionFuerza(id) {
                    NavigationLink {
                        SesionFuerzaView(datos: datos, sesion: fuerza)
                    } label: {
                        contenido(conFlecha: true)
                    }
                    .buttonStyle(.plain)
                } else {
                    contenido(conFlecha: false)
                }
                Button(action: alternar) {
                    Image(systemName: hecho ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(hecho ? Color.green : Color.secondary)
                        .symbolEffect(.bounce, value: hecho)
                        .frame(width: 34, height: 34)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(hecho ? "Marcar como no hecha" : "Marcar como hecha")
            }
            .padding(12)
            .tarjeta(radio: 16)
            .opacity(hecho ? 0.65 : 1)
        }
    }

    private func contenido(conFlecha: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: tipo?.icono ?? "figure.run")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(color.gradient))
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(sesion.titulo)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    if sesion.opcional {
                        Etiqueta(texto: "Opcional", color: .secondary)
                    }
                }
                Text(sesion.detalle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                FilaFlexible(espacio: 6) {
                    if sesion.km > 0 {
                        Etiqueta(texto: textoKm, icono: "point.topleft.down.to.point.bottomright.curvepath",
                                 color: Tema.acento)
                    }
                    if sesion.minutos > 0 {
                        Etiqueta(texto: textoDuracion, icono: "clock", color: Tema.acento)
                    }
                    if let zonaId = sesion.zona, let zona = datos.zona(zonaId) {
                        Etiqueta(texto: textoRitmo(zona), icono: "speedometer", color: ColoresCorrer.texto(zona.color))
                    }
                }
                if let nota = sesion.nota {
                    Label(nota, systemImage: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(Tema.coral)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if conFlecha {
                    HStack(spacing: 4) {
                        Text("Ver ejercicios")
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Tema.acento)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var textoKm: String {
        let km: String = Formato.km(sesion.km)
        return sesion.tipo == "correrCaminar" ? "≈ \(km)" : km
    }

    private var textoDuracion: String {
        let duracion: String = Formato.duracion(sesion.minutos)
        let exacta = sesion.tipo == "fuerza" || sesion.tipo == "correrCaminar"
        return exacta ? duracion : "≈ \(duracion)"
    }

    /// "5:20–5:50 /km" si hay tiempo de referencia; si no, el nombre de la zona
    private func textoRitmo(_ zona: ZonaRitmo) -> String {
        guard let ref = referencia else { return zona.nombre }
        let r = CalculadoraRitmo.rango(zona, ref: ref, objetivoKm: objetivoKm, exponente: datos.riegel)
        if sesion.tipo == "carrera" {
            let t = CalculadoraRitmo.prediccion(ref, km: objetivoKm, exponente: datos.riegel)
            return "≈ \(Formato.tiempo(t)) · \(Formato.ritmo((r.rapido + r.lento) / 2))"
        }
        return "\(Formato.minutosSegundos(r.rapido))–\(Formato.ritmo(r.lento))"
    }
}

// MARK: - Calentamiento y estiramientos

struct CalentamientoCorrerView: View {
    let datos: DatosCorrer

    private enum Parte: String, CaseIterable, Identifiable {
        case calentamiento, antes, despues
        var id: String { rawValue }
        var nombre: String {
            switch self {
            case .calentamiento: return "Calentar"
            case .antes: return "Antes"
            case .despues: return "Después"
            }
        }
    }

    @State private var parte: Parte = .calentamiento

    private var pasos: [PasoConsejo] {
        switch parte {
        case .calentamiento: return datos.calentamiento
        case .antes: return datos.estiramientosAntes
        case .despues: return datos.estiramientosDespues
        }
    }

    private var explicacion: String {
        switch parte {
        case .calentamiento: return "Antes de cada salida, sobre todo antes de series y carreras (10–15 min)."
        case .antes: return "Estiramientos en movimiento (dinámicos) para preparar las piernas. Nada de aguantar posturas en frío."
        case .despues: return "Al terminar, con el cuerpo caliente: estiramientos suaves, sin rebotes ni dolor."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TituloSeccion(titulo: "Calentamiento y estiramientos", icono: "figure.flexibility")
            Picker("Parte", selection: $parte) {
                ForEach(Parte.allCases) { p in
                    Text(p.nombre).tag(p)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            Text(explicacion)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(Array(pasos.enumerated()), id: \.offset) { i, p in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(i + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Tema.acento))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.nombre).font(.subheadline.weight(.semibold))
                        Text(p.detalle).font(.caption).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(16)
        .tarjeta()
    }
}

// MARK: - Fuerza para corredores

struct FuerzaCorredorSeccion: View {
    let datos: DatosCorrer
    let diasGimnasio: Int
    @AppStorage("correr.lugarFuerza") private var lugarFuerza: String = ""
    @AppStorage("plan.lugar") private var lugarPlan: String = Lugar.pesas.rawValue

    private var lugar: Lugar {
        Lugar(rawValue: lugarFuerza) ?? Lugar(rawValue: lugarPlan) ?? .pesas
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TituloSeccion(titulo: "Fuerza para corredores", icono: "dumbbell.fill")
            Text(datos.fuerza.descripcion)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            FilaFlexible {
                ForEach(Lugar.allCases) { l in
                    Chip(texto: l.nombre, icono: l.icono, seleccionado: l == lugar, color: l.color) {
                        lugarFuerza = l.rawValue
                    }
                }
            }
            ForEach(datos.fuerza.sesiones) { s in
                NavigationLink {
                    SesionFuerzaView(datos: datos, sesion: s)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: s.icono)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(lugar.degradado))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.nombre).font(.subheadline.weight(.bold)).foregroundStyle(.primary)
                            Text("\(s.ejercicios.count) ejercicios · \(lugar.nombre)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Tema.suave))
                    .contentShape(Rectangle())
                }
                .buttonStyle(EstiloPulsado())
            }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(datos.fuerza.reglas, id: \.self) { r in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.shield.fill")
                            .foregroundStyle(Tema.coral)
                            .font(.footnote)
                        Text(r)
                            .font(.footnote)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
            }
            if diasGimnasio > 0 {
                AvisoCorrer(texto: Text("En «Mi plan» tienes **\(diasGimnasio) \(diasGimnasio == 1 ? "día" : "días")** de gimnasio. Si lo sigues a la vez que este plan, quita sus días de pierna y no entrenes pierna el día antes de las series o de la tirada larga."),
                            icono: "calendar.badge.exclamationmark", color: Tema.azul)
            }
        }
        .padding(16)
        .tarjeta()
    }
}

/// Lista de ejercicios de una sesión de fuerza (abre la ficha de GymApp)
struct SesionFuerzaView: View {
    let datos: DatosCorrer
    let sesion: SesionFuerza
    @AppStorage("correr.lugarFuerza") private var lugarFuerza: String = ""
    @AppStorage("plan.lugar") private var lugarPlan: String = Lugar.pesas.rawValue

    private var lugar: Lugar {
        Lugar(rawValue: lugarFuerza) ?? Lugar(rawValue: lugarPlan) ?? .pesas
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(sesion.descripcion)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                FilaFlexible {
                    ForEach(Lugar.allCases) { l in
                        Chip(texto: l.nombre, icono: l.icono, seleccionado: l == lugar, color: l.color) {
                            lugarFuerza = l.rawValue
                        }
                    }
                }
                ForEach(Array(sesion.ejercicios.enumerated()), id: \.offset) { _, ef in
                    if let e = ef.ejercicio(para: lugar) {
                        NavigationLink(value: e) {
                            FilaEjercicio(ejercicio: e, detalle: textoSeries(ef))
                        }
                        .buttonStyle(EstiloPulsado())
                    }
                }
                AvisoCorrer(texto: Text("Descansa 60–90 s entre series. Elige un peso con el que te sobren 2–3 repeticiones: el objetivo es correr mejor, no acabar agotado."),
                            icono: "lightbulb.fill", color: Tema.azul)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(datos.fuerza.reglas, id: \.self) { r in
                        Label(r, systemImage: "checkmark.circle")
                            .font(.footnote)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding()
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(Tema.fondo.ignoresSafeArea())
        .navigationTitle(sesion.nombre)
    }

    private func textoSeries(_ ef: EjercicioFuerza) -> String {
        guard let nota = ef.nota else { return ef.series }
        return "\(ef.series) · \(nota)"
    }
}

// MARK: - Calculadora de ritmo

struct CalculadoraRitmoView: View {
    let datos: DatosCorrer
    let objetivoKm: Double
    @Binding var refKm: Double
    @Binding var refSegundos: Double
    @Environment(\.dismiss) private var dismiss

    @State private var km: Double
    @State private var horas: Int
    @State private var minutos: Int
    @State private var segundos: Int

    init(datos: DatosCorrer, objetivoKm: Double, refKm: Binding<Double>, refSegundos: Binding<Double>) {
        self.datos = datos
        self.objetivoKm = objetivoKm
        _refKm = refKm
        _refSegundos = refSegundos
        let total = Int(refSegundos.wrappedValue.rounded())
        _km = State(initialValue: refKm.wrappedValue > 0 ? refKm.wrappedValue : 5)
        if total > 0 {
            _horas = State(initialValue: total / 3600)
            _minutos = State(initialValue: (total % 3600) / 60)
            _segundos = State(initialValue: total % 60)
        } else {
            _horas = State(initialValue: 0)
            _minutos = State(initialValue: 30)
            _segundos = State(initialValue: 0)
        }
    }

    private var totalSegundos: Double {
        Double(max(horas, 0) * 3600 + max(minutos, 0) * 60 + max(segundos, 0))
    }

    private var referencia: TiempoReferencia? {
        totalSegundos > 0 && km > 0 ? TiempoReferencia(km: km, segundos: totalSegundos) : nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Menu {
                        ForEach(datos.distancias) { d in
                            Button(d.nombre) { km = d.km }
                        }
                    } label: {
                        Label("Elegir una distancia", systemImage: "list.bullet")
                    }
                    Stepper(value: $km, in: 1...50, step: 0.5) {
                        HStack {
                            Text("Distancia")
                            Spacer()
                            Text(Formato.km(km)).bold().monospacedDigit()
                        }
                    }
                } header: {
                    Text("¿Qué distancia corriste?")
                } footer: {
                    Text("Usa una carrera o un entreno a tope de las últimas 4–6 semanas.")
                }

                Section("¿Cuánto tardaste? (horas : minutos : segundos)") {
                    HStack(spacing: 6) {
                        campo("h", $horas)
                        Text(":").bold()
                        campo("min", $minutos)
                        Text(":").bold()
                        campo("s", $segundos)
                        Spacer(minLength: 0)
                    }
                }

                if let ref = referencia {
                    Section("Resultado") {
                        fila("Ritmo", Formato.ritmo(CalculadoraRitmo.ritmo(segundos: ref.segundos, km: ref.km)))
                        fila("Velocidad", Formato.numero(CalculadoraRitmo.velocidad(segundos: ref.segundos, km: ref.km),
                                                         decimales: 1) + " km/h")
                    }

                    Section {
                        ForEach(distanciasPrediccion, id: \.self) { d in
                            let t = CalculadoraRitmo.prediccion(ref, km: d, exponente: datos.riegel)
                            HStack {
                                Text(datos.nombreDistancia(d))
                                if abs(d - objetivoKm) < 0.05 {
                                    Image(systemName: "flag.checkered").foregroundStyle(Tema.coral)
                                }
                                Spacer()
                                Text(Formato.tiempo(t)).bold().monospacedDigit()
                                Text(Formato.ritmo(t / d))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                                    .frame(minWidth: 70, alignment: .trailing)
                            }
                        }
                    } header: {
                        Text("Tiempos estimados")
                    } footer: {
                        Text("Fórmula de Riegel. Solo es realista si entrenas para esa distancia.")
                    }

                    Section("Ritmos de entrenamiento") {
                        ForEach(datos.zonas) { z in
                            FilaZonaRitmo(zona: z, rango: CalculadoraRitmo.rango(z, ref: ref, objetivoKm: objetivoKm,
                                                                                 exponente: datos.riegel))
                        }
                    }
                }

                if refSegundos > 0 {
                    Section {
                        Button("Borrar mi tiempo", role: .destructive) {
                            refSegundos = 0
                            dismiss()
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Calculadora de ritmo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        refKm = km
                        refSegundos = totalSegundos
                        dismiss()
                    }
                    .disabled(referencia == nil)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 600)
        #endif
    }

    /// 5, 10, 21,1 y 42,2 km, y la distancia objetivo si es otra
    private var distanciasPrediccion: [Double] {
        var lista = datos.distancias.map(\.km)
        if !lista.contains(where: { abs($0 - objetivoKm) < 0.05 }) {
            lista.append(objetivoKm)
            lista.sort()
        }
        return lista
    }

    private func campo(_ titulo: String, _ valor: Binding<Int>) -> some View {
        TextField(titulo, value: valor, format: .number)
            .multilineTextAlignment(.center)
            .monospacedDigit()
            .frame(width: 60)
            .textFieldStyle(.roundedBorder)
            #if os(iOS)
            .keyboardType(.numberPad)
            #endif
    }

    private func fila(_ titulo: String, _ valor: String) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            Text(valor).bold().monospacedDigit()
        }
    }
}

#Preview {
    CorrerView()
}
