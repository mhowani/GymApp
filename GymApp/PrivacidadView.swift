import SwiftUI

/// Política de privacidad (el mismo texto que la web: docs/privacidad.html)
struct PrivacidadView: View {
    @State private var verContacto = false

    private struct Apartado: Identifiable {
        let id: Int
        let titulo: String
        let texto: String
    }

    private let apartados: [Apartado] = [
        Apartado(id: 1, titulo: "Responsable",
                 texto: "\(Config.responsable). Para cualquier consulta sobre privacidad, usa el formulario de contacto (botón de abajo o página Contacto de la web)."),
        Apartado(id: 2, titulo: "Qué datos guarda la app",
                 texto: "\(Config.nombreApp) no pide registro ni cuenta, no muestra publicidad, no usa herramientas de análisis y no envía tus datos a ningún servidor.\n\nLo que configuras se guarda solo en tu dispositivo: favoritos, apariencia, tu plan, tu plan de correr (distancia, días, tiempos y sesiones hechas) y, en Menús, «Mis datos» (sexo, edad, peso, altura, actividad, objetivo y tipo de dieta) y el registro de peso y altura. Nosotros no podemos ver nada de eso."),
        Apartado(id: 3, titulo: "Datos de salud",
                 texto: "El peso, la altura y el IMC son datos de salud. Se usan solo para calcular tus calorías y mostrar tu evolución dentro de la app, y nunca salen del dispositivo. Puedes borrar cualquier medida desde el Historial del Registro."),
        Apartado(id: 4, titulo: "Copias de seguridad",
                 texto: "Si tienes activadas las copias de iCloud, Apple puede incluir los datos de la app en tu copia de seguridad, según su propia política de privacidad. Nosotros no tenemos acceso a esas copias."),
        Apartado(id: 5, titulo: "Formulario de contacto",
                 texto: "Si nos escribes desde la app o la web, se envían tu nombre, tu correo, el asunto y tu mensaje a través del servicio Web3Forms, que nos lo reenvía por correo.\n• Finalidad: responderte.\n• Base legal: tu consentimiento (la casilla del formulario).\n• Conservación: lo necesario para atenderte y como máximo un año desde el último mensaje.\nNo cedemos tus datos a nadie más."),
        Apartado(id: 6, titulo: "La web",
                 texto: "La web está alojada en GitHub Pages, que puede registrar datos técnicos como tu dirección IP por seguridad. La web no usa cookies de seguimiento ni publicidad; lo que eliges en ella se guarda en el almacenamiento local de tu navegador."),
        Apartado(id: 7, titulo: "Tus derechos",
                 texto: "Puedes pedir el acceso, la rectificación, la supresión, la oposición, la limitación o la portabilidad de tus datos, y retirar tu consentimiento, desde el formulario de contacto (asunto «Privacidad o mis datos»). Si no te atendemos bien, puedes reclamar ante la Agencia Española de Protección de Datos (aepd.es).\n\nLos datos guardados en la app los borras tú mismo eliminando la app."),
        Apartado(id: 8, titulo: "Menores",
                 texto: "La app y la web no están dirigidas a menores de 14 años. Si tienes menos de 14 años, no uses el formulario de contacto."),
        Apartado(id: 9, titulo: "Salud",
                 texto: "Los ejercicios, planes, menús y consejos son orientativos y no sustituyen el consejo de un médico, fisioterapeuta o dietista-nutricionista."),
        Apartado(id: 10, titulo: "Cambios",
                 texto: "Si cambiamos esta política, publicaremos la nueva versión en la app y en la web con su fecha."),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Tus datos se quedan en tu dispositivo", systemImage: "lock.shield.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Última actualización: \(Config.fechaPrivacidad)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Tema.degradado))

                ForEach(apartados) { a in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(a.id). \(a.titulo)")
                            .font(.headline)
                            .foregroundStyle(Tema.acento)
                        Text(a.texto)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .tarjeta(radio: 16)
                }

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

                Link(destination: Config.privacidadURL) {
                    Label("Ver en la web", systemImage: "globe")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(Tema.fondo.ignoresSafeArea())
        .navigationTitle("Privacidad")
        .sheet(isPresented: $verContacto) {
            ContactoView()
        }
    }
}

#Preview {
    NavigationStack { PrivacidadView() }
}
