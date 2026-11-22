import SwiftUI

/// Manual de usuario dentro de la app (el mismo contenido que docs/manual.html en la web)
struct ManualView: View {
    @State private var verContacto = false

    private var ejemplo: Ejercicio? {
        Catalogo.ejercicios.first { $0.id == "press-banca-barra" } ?? Catalogo.ejercicios.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                cabecera

                apartado(1, "Inicio", icono: "house.fill") {
                    paso("Busca cualquier ejercicio o músculo en el buscador de arriba.")
                    paso("Toca Pesas, Máquinas o En casa para ver solo lo que puedes hacer donde estás.")
                    paso("Cada día hay un «Ejercicio del día» distinto, y abajo tienes tus favoritos y accesos rápidos.")
                    paso("El botón de información abre esta sección: apariencia, contacto, manual y privacidad.")
                }

                apartado(2, "Ejercicios", icono: "dumbbell.fill") {
                    paso("Con «Por músculo» los ejercicios salen agrupados; toca la cabecera de un grupo para plegarlo o desplegarlo. Con «Todos» salen en una sola cuadrícula.")
                    paso("Filtra por lugar con los botones de arriba, o por músculo y nivel con el botón de filtro.")
                    paso("Pulsa el corazón ♡ de un ejercicio para guardarlo en Favoritos.")
                }

                apartado(3, "La ficha del ejercicio", icono: "doc.text.image") {
                    if let e = ejemplo {
                        HStack(spacing: 10) {
                            FiguraEjercicioView(ejercicio: e)
                                .frame(maxWidth: 220)
                                .padding(6)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.97)))
                            MapaMuscularView(principales: Set(e.principales), secundarios: Set(e.secundarios))
                                .frame(maxWidth: 220)
                                .padding(6)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.97)))
                        }
                        .environment(\.colorScheme, .light)
                    }
                    paso("La figura repite el movimiento del ejercicio. Con ⏸︎ la paras y con ▶︎ la vuelves a mover.")
                    paso("En la figura y en el dibujo del cuerpo, en rojo los músculos principales y en naranja los secundarios.")
                    paso("Toca el dibujo o «Ampliar» para verlo en grande: pellizca para hacer zoom.")
                    paso("Debajo tienes los pasos, un consejo y ejercicios parecidos.")
                }

                apartado(4, "Músculos", icono: "figure.strengthtraining.traditional") {
                    MapaMuscularView(principales: [.cuadriceps])
                        .frame(maxWidth: 340)
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.97)))
                        .environment(\.colorScheme, .light)
                    paso("Toca cualquier músculo del dibujo (de frente o de espalda) y verás sus ejercicios.")
                    paso("Primero salen los ejercicios donde ese músculo es el principal y después donde es secundario.")
                }

                apartado(5, "Mi plan", icono: "calendar") {
                    paso("Elige cuántos días entrenas a la semana y dónde.")
                    paso("La app reparte los músculos por días y propone los ejercicios con sus series.")
                    paso("Toca un ejercicio para ver cómo se hace.")
                }

                apartado(6, "Correr", icono: "figure.run") {
                    paso("Elige la distancia: 5 km, 10 km, media maratón, maratón o la que quieras con la barra (de 3 a 42,2 km).")
                    paso("Elige tu nivel, los días para correr y las semanas hasta la carrera, y pulsa «Empezar el plan».")
                    paso("En «Tus ritmos» pon un tiempo reciente y la app calcula tus ritmos para cada tipo de entrenamiento.")
                    paso("Toca cada semana para ver sus días y marca las sesiones hechas. También tienes calentamiento, estiramientos y fuerza para corredores.")
                }

                apartado(7, "Menús", icono: "fork.knife") {
                    paso("Pon «Mis datos» (sexo, edad, peso, altura y actividad) para ajustar las calorías.")
                    paso("Elige el objetivo (ganar músculo, adelgazar, mantenerte…) y, si quieres, vegetariano, sin gluten o sin lactosa.")
                    paso("Verás un menú de 7 días con 5 comidas. «Cambiar» cambia un plato y «Otra semana» hace un menú nuevo.")
                    paso("La lista de la compra se calcula sola y se puede compartir. En Registro guardas tu peso y ves tu evolución.")
                }

                apartado(8, "Información", icono: "info.circle.fill") {
                    paso("Cambia la apariencia: automática, clara u oscura.")
                    paso("«Contacto» abre un formulario para escribirnos sin salir de la app.")
                    paso("Aquí están también este manual, la política de privacidad y la versión web.")
                }

                apartado(9, "Consejos", icono: "lightbulb.fill") {
                    paso("Calienta 5-10 minutos antes de empezar y estira al terminar.")
                    paso("Empieza con poco peso y buena técnica; sube poco a poco.")
                    paso("Deja al menos un día de descanso entre sesiones de los mismos músculos.")
                    paso("Si tienes alguna lesión o problema de salud, consulta antes con un profesional.")
                }

                #if os(iOS)
                Label("En el iPhone, Correr y Menús están dentro de la pestaña «Más» (también se abren desde Inicio).",
                      systemImage: "iphone")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                #endif

                HStack(spacing: 12) {
                    Button {
                        verContacto = true
                    } label: {
                        Label("¿Dudas? Escríbenos", systemImage: "envelope.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Tema.coral)

                    Link(destination: Config.manualURL) {
                        Label("Manual en la web", systemImage: "globe")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(Tema.acento)
                }
            }
            .padding()
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .background(Tema.fondo.ignoresSafeArea())
        .navigationTitle("Manual")
        .sheet(isPresented: $verContacto) {
            ContactoView()
        }
    }

    // MARK: - Piezas

    private var cabecera: some View {
        HStack(spacing: 14) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .padding(6)
                .frame(width: 64, height: 64)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
            VStack(alignment: .leading, spacing: 2) {
                Text("Manual de usuario")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("Cómo sacar partido a \(Config.nombreApp)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Tema.degradado))
    }

    private func apartado<Contenido: View>(_ n: Int, _ titulo: String, icono: String,
                                           @ViewBuilder contenido: () -> Contenido) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("\(n)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Tema.degradado))
                Label(titulo, systemImage: icono)
                    .font(.title3.bold())
            }
            contenido()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .tarjeta()
    }

    private func paso(_ texto: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Tema.acento)
            Text(texto)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack { ManualView() }
}
