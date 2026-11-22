import SwiftUI
import Charts

// MARK: - Registro de peso y altura (se guarda en el dispositivo)

struct MedidaCorporal: Codable, Identifiable, Hashable {
    var id = UUID()
    var fecha: Date
    /// kg
    var peso: Double
    /// cm
    var altura: Double

    /// Índice de masa corporal
    var imc: Double {
        let m = altura / 100
        return m > 0 ? peso / (m * m) : 0
    }
}

final class RegistroCorporal: ObservableObject {
    /// Ordenadas de la más antigua a la más reciente
    @Published private(set) var medidas: [MedidaCorporal] = []
    private let clave = "registro.medidas"

    init() {
        if let data = UserDefaults.standard.data(forKey: clave),
           let lista = try? JSONDecoder().decode([MedidaCorporal].self, from: data) {
            medidas = lista.sorted { $0.fecha < $1.fecha }
        }
    }

    var ultima: MedidaCorporal? { medidas.last }

    /// Añade una medida. Si ya hay una ese mismo día, la sustituye.
    func anadir(fecha: Date, peso: Double, altura: Double) {
        let cal = Calendar.current
        medidas.removeAll { cal.isDate($0.fecha, inSameDayAs: fecha) }
        medidas.append(MedidaCorporal(fecha: fecha, peso: peso, altura: altura))
        medidas.sort { $0.fecha < $1.fecha }
        guardar()
    }

    func borrar(_ m: MedidaCorporal) {
        medidas.removeAll { $0.id == m.id }
        guardar()
    }

    private func guardar() {
        if let data = try? JSONEncoder().encode(medidas) {
            UserDefaults.standard.set(data, forKey: clave)
        }
    }
}

// MARK: - Pantalla del registro

struct RegistroView: View {
    @ObservedObject var registro: RegistroCorporal
    /// Peso y altura que usa el cálculo de calorías
    @Binding var peso: Double
    @Binding var altura: Double

    @State private var fecha = Date()
    @State private var pesoNuevo: Double = 0
    @State private var alturaNueva: Double = 0
    @State private var guardado = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            nuevaMedida
            if let ultima = registro.ultima {
                resumen(ultima)
            }
            if registro.medidas.count >= 2 {
                grafica
            }
            historial
        }
        .onAppear {
            if pesoNuevo == 0 { pesoNuevo = registro.ultima?.peso ?? peso }
            if alturaNueva == 0 { alturaNueva = registro.ultima?.altura ?? altura }
        }
    }

    // MARK: Nueva medida

    private var nuevaMedida: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Nueva medida", systemImage: "plus.circle.fill")
                .font(.headline)
                .foregroundStyle(Tema.acento)

            DatePicker("Fecha", selection: $fecha, in: ...Date(), displayedComponents: .date)

            campo("Peso", valor: $pesoNuevo, rango: 35...250, paso: 0.1, unidad: "kg", decimales: 1)
            campo("Altura", valor: $alturaNueva, rango: 120...230, paso: 1, unidad: "cm", decimales: 0)

            Button {
                guardar()
            } label: {
                Label(guardado ? "¡Guardado!" : "Guardar medida",
                      systemImage: guardado ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(guardado ? Color.green : Tema.azul)

            Text("Si es la medida más reciente, las calorías del menú se recalculan con ella. Para comparar bien, pésate siempre a la misma hora, mejor por la mañana en ayunas.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .tarjeta()
    }

    private func campo(_ titulo: String, valor: Binding<Double>, rango: ClosedRange<Double>,
                       paso: Double, unidad: String, decimales: Int) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            TextField(titulo, value: valor, format: .number.precision(.fractionLength(0...decimales)))
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .textFieldStyle(.roundedBorder)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
            Text(unidad)
                .foregroundStyle(.secondary)
                .frame(width: 26, alignment: .leading)
            Stepper(titulo, value: valor, in: rango, step: paso)
                .labelsHidden()
        }
    }

    private func guardar() {
        let p = min(max(pesoNuevo, 35), 250)
        let a = min(max(alturaNueva, 120), 230)
        registro.anadir(fecha: fecha, peso: p, altura: a)
        if let ultima = registro.ultima {
            peso = ultima.peso
            altura = ultima.altura
        }
        withAnimation { guardado = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { guardado = false }
        }
    }

    // MARK: Resumen

    private func resumen(_ ultima: MedidaCorporal) -> some View {
        let primera = registro.medidas.first ?? ultima
        let cambio = ultima.peso - primera.peso
        let signo = cambio > 0.05 ? "+" : ""
        return HStack(spacing: 10) {
            dato(Formato.numero(ultima.peso, decimales: 1) + " kg", "Último peso", "scalemass.fill", Tema.acento)
            dato(signo + Formato.numero(cambio, decimales: 1) + " kg", "Desde el inicio", "arrow.up.arrow.down", Tema.coral)
            dato(Formato.numero(ultima.imc, decimales: 1), "IMC", "figure.stand", Tema.azul)
        }
    }

    private func dato(_ valor: String, _ texto: String, _ icono: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icono)
                .foregroundStyle(color)
            Text(valor)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(texto)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .tarjeta(radio: 16)
    }

    // MARK: Gráfica

    private var grafica: some View {
        let pesos = registro.medidas.map(\.peso)
        let minimo = (pesos.min() ?? 0) - 2
        let maximo = (pesos.max() ?? 100) + 2
        return VStack(alignment: .leading, spacing: 10) {
            Label("Evolución del peso", systemImage: "chart.xyaxis.line")
                .font(.headline)
            Chart(registro.medidas) { m in
                LineMark(x: .value("Fecha", m.fecha, unit: .day),
                         y: .value("Peso", m.peso))
                    .foregroundStyle(Tema.azul)
                    .interpolationMethod(.catmullRom)
                PointMark(x: .value("Fecha", m.fecha, unit: .day),
                          y: .value("Peso", m.peso))
                    .foregroundStyle(Tema.coral)
            }
            .chartYScale(domain: minimo...maximo)
            .chartYAxisLabel("kg")
            .frame(height: 200)
            Text("El IMC es solo una referencia general (18,5-24,9 se considera saludable en adultos) y no distingue músculo de grasa.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .tarjeta()
    }

    // MARK: Historial

    private var historial: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label("Historial", systemImage: "list.bullet.rectangle")
                .font(.headline)
                .padding(.bottom, 8)
            if registro.medidas.isEmpty {
                Text("Todavía no hay medidas. Guarda la primera arriba.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                let lista = Array(registro.medidas.reversed())
                ForEach(Array(lista.enumerated()), id: \.element.id) { i, m in
                    fila(m, anterior: i + 1 < lista.count ? lista[i + 1] : nil)
                    if i < lista.count - 1 { Divider() }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .tarjeta()
    }

    private func fila(_ m: MedidaCorporal, anterior: MedidaCorporal?) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(m.fecha.formatted(.dateTime.day().month(.abbreviated).year().locale(Locale(identifier: "es_ES"))))
                    .font(.subheadline.weight(.semibold))
                Text("\(Formato.numero(m.altura)) cm · IMC \(Formato.numero(m.imc, decimales: 1))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Formato.numero(m.peso, decimales: 1) + " kg")
                    .font(.subheadline.weight(.bold))
                if let anterior {
                    let d = m.peso - anterior.peso
                    Text((d > 0.05 ? "+" : "") + Formato.numero(d, decimales: 1) + " kg")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Button(role: .destructive) {
                withAnimation { registro.borrar(m) }
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(Color.red.opacity(0.8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Borrar medida")
        }
        .padding(.vertical, 8)
    }
}
