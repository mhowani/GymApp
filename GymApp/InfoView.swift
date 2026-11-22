import SwiftUI

struct InfoView: View {
    @EnvironmentObject private var favoritos: Favoritos
    @AppStorage("apariencia") private var apariencia: Apariencia = .sistema
    @Environment(\.dismiss) private var dismiss
    @State private var verContacto = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // Logo y descripción
                    VStack(spacing: 14) {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .padding(12)
                            .frame(width: 150, height: 150)
                            .background(RoundedRectangle(cornerRadius: 36, style: .continuous).fill(.white))
                            .shadow(color: .black.opacity(0.25), radius: 12, y: 6)

                        Text(Config.nombreApp)
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Ejercicios con pesas, máquinas y en casa sin material. Cada ejercicio muestra en el dibujo los músculos que trabaja: en rojo los principales y en naranja los secundarios.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Tema.degradado))
                    .shadow(color: Tema.azul.opacity(0.3), radius: 14, y: 8)

                    // Datos
                    HStack(spacing: 12) {
                        dato("\(Catalogo.ejercicios.count)", "ejercicios", "dumbbell.fill", Tema.acento)
                        dato("\(Musculo.allCases.count)", "músculos", "figure.arms.open", MapaMuscularView.colorPrincipal)
                        dato("\(favoritos.ids.count)", "favoritos", "heart.fill", Tema.coral)
                    }

                    // Apariencia
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Apariencia", systemImage: "circle.lefthalf.filled")
                            .font(.headline)
                        Picker("Apariencia", selection: $apariencia) {
                            ForEach(Apariencia.allCases) { a in
                                Text(a.nombre).tag(a)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        Text("«Automático» sigue el modo claro u oscuro del dispositivo.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .tarjeta()

                    // Enlaces
                    VStack(spacing: 12) {
                        Link(destination: Config.webURL) {
                            Label("Versión web", systemImage: "globe")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Tema.azul)

                        Button {
                            verContacto = true
                        } label: {
                            Label("Contacto", systemImage: "envelope.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Tema.coral)

                        HStack(spacing: 12) {
                            NavigationLink {
                                ManualView()
                            } label: {
                                Label("Manual", systemImage: "book.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.bordered)
                            .tint(Tema.acento)

                            NavigationLink {
                                PrivacidadView()
                            } label: {
                                Label("Privacidad", systemImage: "lock.shield.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.bordered)
                            .tint(Tema.acento)
                        }
                    }

                    Text("Consulta con un profesional antes de empezar un programa de ejercicio si tienes alguna lesión o problema de salud.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                    Text("Versión \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
            .background(Tema.fondo.ignoresSafeArea())
            .navigationTitle("Información")
            .sheet(isPresented: $verContacto) {
                ContactoView()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .preferredColorScheme(apariencia.esquema)
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 640)
        #endif
    }

    private func dato(_ valor: String, _ texto: String, _ icono: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icono)
                .foregroundStyle(color)
            Text(valor)
                .font(.title2.bold())
            Text(texto)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .tarjeta(radio: 16)
    }
}
