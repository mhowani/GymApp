import SwiftUI

// MARK: - Generador del plan semanal (versión base; se ampliará en el hilo 2)

struct DiaPlan: Identifiable {
    let id = UUID()
    let diaSemana: String
    let titulo: String
    let musculos: [Musculo]
    let ejercicios: [Ejercicio]
}

enum Planificador {
    private typealias Sesion = (titulo: String, musculos: [Musculo], variante: Int)

    private static let empuje: [Musculo] = [.pecho, .hombros, .triceps]
    private static let tiron: [Musculo] = [.espalda, .trapecio, .biceps, .antebrazos]
    private static let pierna: [Musculo] = [.cuadriceps, .isquiotibiales, .gluteos, .gemelos, .abdominales]

    private static func sesiones(dias: Int) -> [Sesion] {
        switch dias {
        case 2:
            return [("Cuerpo completo A", [.pecho, .espalda, .cuadriceps, .hombros, .biceps, .abdominales], 0),
                    ("Cuerpo completo B", [.gluteos, .isquiotibiales, .pecho, .espalda, .triceps, .gemelos], 1)]
        case 3:
            return [("Empuje", empuje, 0),
                    ("Tirón", tiron, 0),
                    ("Pierna y core", pierna, 0)]
        case 4:
            return [("Torso A", [.pecho, .espalda, .hombros, .biceps, .triceps], 0),
                    ("Pierna A", [.cuadriceps, .isquiotibiales, .gluteos, .gemelos, .abdominales], 0),
                    ("Torso B", [.espalda, .pecho, .trapecio, .triceps, .biceps], 1),
                    ("Pierna B", [.gluteos, .isquiotibiales, .cuadriceps, .aductores, .abductores, .oblicuos], 1)]
        case 5:
            return [("Empuje", empuje, 0),
                    ("Tirón", tiron, 0),
                    ("Pierna", pierna, 0),
                    ("Torso", [.pecho, .espalda, .hombros, .lumbares], 1),
                    ("Brazos y core", [.biceps, .triceps, .antebrazos, .abdominales, .oblicuos], 1)]
        default:
            return [("Empuje A", empuje, 0),
                    ("Tirón A", tiron, 0),
                    ("Pierna A", pierna, 0),
                    ("Empuje B", empuje + [.abdominales], 1),
                    ("Tirón B", tiron + [.lumbares], 1),
                    ("Pierna B", [.gluteos, .isquiotibiales, .cuadriceps, .aductores, .abductores, .oblicuos], 1)]
        }
    }

    static func diasSemana(_ dias: Int) -> [String] {
        switch dias {
        case 2: return ["Lunes", "Jueves"]
        case 3: return ["Lunes", "Miércoles", "Viernes"]
        case 4: return ["Lunes", "Martes", "Jueves", "Viernes"]
        case 5: return ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes"]
        default: return ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"]
        }
    }

    static func plan(dias: Int, lugar: Lugar) -> [DiaPlan] {
        let nombres = diasSemana(dias)
        return sesiones(dias: dias).enumerated().map { par -> DiaPlan in
            let i = par.offset
            let s = par.element
            var elegidos: [Ejercicio] = []
            for m in s.musculos {
                let disponibles = Catalogo.ejercicios.filter { $0.lugar == lugar && !elegidos.contains($0) }
                // Primero ejercicios donde el músculo es el principal
                var candidatos = disponibles.filter { $0.principales.first == m }
                if candidatos.isEmpty { candidatos = disponibles.filter { $0.principales.contains(m) } }
                if candidatos.isEmpty { continue }
                elegidos.append(candidatos[s.variante % candidatos.count])
            }
            return DiaPlan(diaSemana: nombres[i], titulo: s.titulo, musculos: s.musculos, ejercicios: elegidos)
        }
    }
}

// MARK: - Pantalla del plan

struct PlanView: View {
    @AppStorage("plan.dias") private var dias: Int = 3
    @AppStorage("plan.lugar") private var lugarGuardado: String = Lugar.pesas.rawValue

    private var lugar: Lugar { Lugar(rawValue: lugarGuardado) ?? .pesas }
    private var plan: [DiaPlan] { Planificador.plan(dias: dias, lugar: lugar) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("¿Cuántos días entrenas a la semana?", systemImage: "calendar")
                            .font(.headline)
                        Picker("Días", selection: $dias) {
                            ForEach(2...6, id: \.self) { d in
                                Text("\(d)").tag(d)
                            }
                        }
                        .pickerStyle(.segmented)

                        Label("¿Dónde entrenas?", systemImage: "mappin.and.ellipse")
                            .font(.headline)
                            .padding(.top, 6)
                        Picker("Lugar", selection: $lugarGuardado) {
                            ForEach(Lugar.allCases) { l in
                                Text(l.nombre).tag(l.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    .tarjeta()

                    ForEach(plan) { dia in
                        TarjetaDia(dia: dia)
                    }

                    Label("Descansa al menos un día entre sesiones que trabajen los mismos músculos. Calienta 5-10 minutos antes de empezar.",
                          systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: 800)
                .frame(maxWidth: .infinity)
            }
            .background(Tema.fondo.ignoresSafeArea())
            .navigationTitle("Mi plan")
            .navigationDestination(for: Ejercicio.self) { e in
                DetalleEjercicioView(ejercicio: e)
            }
        }
    }
}

struct TarjetaDia: View {
    let dia: DiaPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(String(dia.diaSemana.prefix(3)).uppercased())
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Tema.degradado))
                VStack(alignment: .leading, spacing: 2) {
                    Text(dia.titulo)
                        .font(.title3.bold())
                    Text("\(dia.diaSemana) · \(dia.ejercicios.count) ejercicios")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            MapaMuscularView(principales: Set(dia.musculos))
                .frame(maxHeight: 180)
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Tema.suave))

            ForEach(dia.ejercicios) { e in
                NavigationLink(value: e) {
                    FilaEjercicio(ejercicio: e, detalle: e.series)
                }
                .buttonStyle(EstiloPulsado())
            }
        }
        .padding()
        .tarjeta(radio: 22)
    }
}
