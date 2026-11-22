import SwiftUI

/// Formulario de contacto dentro de la app. Se envía con Web3Forms (el mismo servicio que la web)
/// y llega a tu correo sin que la dirección aparezca en la app.
struct ContactoView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var nombre = ""
    @State private var email = ""
    @State private var tema = "Duda sobre un ejercicio"
    @State private var mensaje = ""
    @State private var acepta = false
    @State private var verPrivacidad = false

    @State private var enviando = false
    @State private var resultado: Resultado? = nil

    private enum Resultado: Equatable {
        case ok
        case error(String)
    }

    private let temas = ["Duda sobre un ejercicio", "Idea o sugerencia", "He encontrado un error",
                         "Privacidad o mis datos", "Otro"]

    private var emailValido: Bool {
        let partes = email.trimmingCharacters(in: .whitespaces).split(separator: "@")
        return partes.count == 2 && partes[1].contains(".") && !partes[0].isEmpty
    }

    private var sePuedeEnviar: Bool {
        !nombre.trimmingCharacters(in: .whitespaces).isEmpty && emailValido &&
        !mensaje.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && acepta && !enviando
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("¿Tienes una duda, una idea o has encontrado un error? Escríbenos y te responderemos lo antes posible.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Tus datos") {
                    TextField("Nombre", text: $nombre)
                        #if os(iOS)
                        .textContentType(.name)
                        #endif
                    TextField("Correo electrónico", text: $email)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        #endif
                    if !email.isEmpty && !emailValido {
                        Text("Revisa el correo: parece incompleto.")
                            .font(.caption)
                            .foregroundStyle(Tema.coral)
                    }
                }

                Section("Mensaje") {
                    Picker("Asunto", selection: $tema) {
                        ForEach(temas, id: \.self) { Text($0).tag($0) }
                    }
                    TextEditor(text: $mensaje)
                        .frame(minHeight: 140)
                }

                Section {
                    Toggle(isOn: $acepta) {
                        Text("He leído y acepto la política de privacidad")
                            .font(.subheadline)
                    }
                    .tint(Tema.acento)
                    Button("Leer la política de privacidad") { verPrivacidad = true }
                        .font(.subheadline)
                } footer: {
                    Text("Usamos tu nombre y tu correo solo para responderte. El mensaje se envía con el servicio Web3Forms.")
                }

                Section {
                    Button {
                        Task { await enviar() }
                    } label: {
                        HStack {
                            Spacer()
                            if enviando {
                                ProgressView()
                            } else {
                                Label("Enviar mensaje", systemImage: "paperplane.fill")
                                    .font(.headline)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!sePuedeEnviar)

                    if let resultado {
                        switch resultado {
                        case .ok:
                            Label("¡Gracias! Tu mensaje se ha enviado. Te responderemos lo antes posible.",
                                  systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        case .error(let texto):
                            Label("No se ha podido enviar (\(texto)). Comprueba la conexión e inténtalo otra vez.",
                                  systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(Tema.coral)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Contacto")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .sheet(isPresented: $verPrivacidad) {
                NavigationStack {
                    PrivacidadView()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Cerrar") { verPrivacidad = false }
                            }
                        }
                }
                #if os(macOS)
                .frame(minWidth: 520, minHeight: 600)
                #endif
            }
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 620)
        #endif
    }

    private func enviar() async {
        enviando = true
        resultado = nil
        defer { enviando = false }

        let datos: [String: String] = [
            "access_key": Config.web3formsClave,
            "subject": "Nuevo mensaje desde la app GymApp",
            "from_name": "App GymApp",
            "name": nombre.trimmingCharacters(in: .whitespaces),
            "email": email.trimmingCharacters(in: .whitespaces),
            "tema": tema,
            "message": mensaje,
            "privacidad": "Aceptada"
        ]
        guard let url = URL(string: "https://api.web3forms.com/submit"),
              let cuerpo = try? JSONSerialization.data(withJSONObject: datos) else {
            resultado = .error("datos no válidos")
            return
        }
        var peticion = URLRequest(url: url)
        peticion.httpMethod = "POST"
        peticion.setValue("application/json", forHTTPHeaderField: "Content-Type")
        peticion.setValue("application/json", forHTTPHeaderField: "Accept")
        peticion.httpBody = cuerpo
        peticion.timeoutInterval = 20

        do {
            let (respuesta, http) = try await URLSession.shared.data(for: peticion)
            let json = (try? JSONSerialization.jsonObject(with: respuesta)) as? [String: Any]
            let exito = (json?["success"] as? Bool) ?? false
            if let codigo = (http as? HTTPURLResponse)?.statusCode, (200..<300).contains(codigo), exito {
                resultado = .ok
                mensaje = ""
                acepta = false
            } else {
                resultado = .error((json?["message"] as? String) ?? "error del servidor")
            }
        } catch {
            resultado = .error(error.localizedDescription)
        }
    }
}

#Preview {
    ContactoView()
}
