import SwiftUI

@main
struct GymAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 800)
        #endif
    }
}

struct ContentView: View {
    @StateObject private var estado = EstadoApp()
    @StateObject private var favoritos = Favoritos()
    @AppStorage("apariencia") private var apariencia: Apariencia = .sistema

    var body: some View {
        TabView(selection: $estado.pestana) {
            InicioView()
                .tabItem { Label("Inicio", systemImage: "house.fill") }
                .tag(Pestana.inicio)
            EjerciciosView()
                .tabItem { Label("Ejercicios", systemImage: "dumbbell.fill") }
                .tag(Pestana.ejercicios)
            MusculosView()
                .tabItem { Label("Músculos", systemImage: "figure.strengthtraining.traditional") }
                .tag(Pestana.musculos)
            PlanView()
                .tabItem { Label("Mi plan", systemImage: "calendar") }
                .tag(Pestana.plan)
            CorrerView()
                .tabItem { Label("Correr", systemImage: "figure.run") }
                .tag(Pestana.correr)
            MenusView()
                .tabItem { Label("Menús", systemImage: "fork.knife") }
                .tag(Pestana.menus)
        }
        .tint(Tema.acento)
        .environmentObject(estado)
        .environmentObject(favoritos)
        .preferredColorScheme(apariencia.esquema)
    }
}

#Preview {
    ContentView()
}
