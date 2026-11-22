import SwiftUI

// MARK: - Datos de la animación (vienen de ejercicios.json → "animacion")

struct Pose: Codable, Hashable {
    // Vista de lado
    var anclaje: String?
    var x: Double?
    var y: Double?
    var torso: Double?
    var cuello: Double?
    var brazo: Double?
    var antebrazo: Double?
    var brazo_b: Double?
    var antebrazo_b: Double?
    var muslo: Double?
    var pierna: Double?
    var muslo_b: Double?
    var pierna_b: Double?
    var pie: Double?
    var pie_b: Double?
    // Vista de frente
    var rot: Double?
    var hombros: Double?
    var sentado: Double?
    var abd: Double?
    var abd_a: Double?
    var abd_b: Double?
    var codo: Double?
    var codo_a: Double?
    var codo_b: Double?
    var abre: Double?
    var abre_a: Double?
    var abre_b: Double?

    /// Devuelve todos los valores con sus valores por defecto, para poder mezclar dos poses.
    func resuelta(deFrente: Bool) -> [String: Double] {
        var r: [String: Double] = [:]
        r["x"] = x ?? 60
        r["y"] = y ?? 0
        if deFrente {
            r["rot"] = rot ?? 0
            r["hombros"] = hombros ?? 0
            r["sentado"] = sentado ?? 0
            r["abd_a"] = abd_a ?? abd ?? 0
            r["abd_b"] = abd_b ?? abd ?? 0
            r["codo_a"] = codo_a ?? codo ?? 0
            r["codo_b"] = codo_b ?? codo ?? 0
            r["abre_a"] = abre_a ?? abre ?? 6
            r["abre_b"] = abre_b ?? abre ?? 6
        } else {
            let br = brazo ?? -90
            let an = antebrazo ?? -90
            let mu = muslo ?? -90
            let pi = pierna ?? -90
            let pe = pie ?? 0
            r["torso"] = torso ?? 90
            r["cuello"] = cuello ?? 0
            r["brazo"] = br
            r["antebrazo"] = an
            r["brazo_b"] = brazo_b ?? br
            r["antebrazo_b"] = antebrazo_b ?? an
            r["muslo"] = mu
            r["pierna"] = pi
            r["muslo_b"] = muslo_b ?? mu
            r["pierna_b"] = pierna_b ?? pi
            r["pie"] = pe
            r["pie_b"] = pie_b ?? pe
        }
        return r
    }
}

struct Accesorios: Codable, Hashable {
    var banco: [Double]?
    var respaldo: [Double]?
    var escalon: [Double]?
    var esterilla: [Double]?
    var poste: [Double]?
    var polea: [Double]?
    var mancuerna: Bool?
    /// Articulación donde va la barra ("manoa", "hombro", "cadera"); de frente puede venir como true
    var barra: String?
    var rodillo: String?
    var mochila: Bool?
    var asa: Bool?
    var toalla: Bool?

    init() {}

    private enum CodingKeys: String, CodingKey {
        case banco, respaldo, escalon, esterilla, poste, polea, mancuerna, barra, rodillo, mochila, asa, toalla
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        banco = try? c.decodeIfPresent([Double].self, forKey: .banco)
        respaldo = try? c.decodeIfPresent([Double].self, forKey: .respaldo)
        escalon = try? c.decodeIfPresent([Double].self, forKey: .escalon)
        esterilla = try? c.decodeIfPresent([Double].self, forKey: .esterilla)
        poste = try? c.decodeIfPresent([Double].self, forKey: .poste)
        polea = try? c.decodeIfPresent([Double].self, forKey: .polea)
        mancuerna = try? c.decodeIfPresent(Bool.self, forKey: .mancuerna)
        rodillo = try? c.decodeIfPresent(String.self, forKey: .rodillo)
        mochila = try? c.decodeIfPresent(Bool.self, forKey: .mochila)
        asa = try? c.decodeIfPresent(Bool.self, forKey: .asa)
        toalla = try? c.decodeIfPresent(Bool.self, forKey: .toalla)
        if let texto = try? c.decodeIfPresent(String.self, forKey: .barra) {
            barra = texto
        } else if let si = try? c.decodeIfPresent(Bool.self, forKey: .barra), si {
            barra = "manos"
        } else {
            barra = nil
        }
    }
}

struct Animacion: Codable, Hashable {
    var vista: String?
    var a: Pose
    var b: Pose
    var props: Accesorios?
}

// MARK: - Vista animada

/// Figura que se mueve entre la posición inicial y la final del ejercicio.
/// Estilo de la lámina de músculos: figura blanca con contorno negro;
/// en rojo lo que trabaja como principal y en naranja lo secundario.
struct FiguraEjercicioView: View {
    let ejercicio: Ejercicio
    var animada: Bool = true
    var duracion: Double = 2.6

    var body: some View {
        Group {
            if let anim = ejercicio.animacion {
                if animada {
                    TimelineView(.animation) { contexto in
                        let s = contexto.date.timeIntervalSinceReferenceDate
                        let fase = s.truncatingRemainder(dividingBy: duracion) / duracion
                        let t = (1 - cos(fase * 2 * .pi)) / 2
                        lienzo(anim, t: t)
                    }
                } else {
                    lienzo(anim, t: 1)
                }
            } else {
                Image(systemName: ejercicio.lugar.icono)
                    .resizable()
                    .scaledToFit()
                    .padding(20)
                    .foregroundStyle(ejercicio.lugar.color)
            }
        }
        .aspectRatio(DibujoFigura.ancho / DibujoFigura.alto, contentMode: .fit)
        .accessibilityLabel(Text("Animación de \(ejercicio.nombre)"))
    }

    private func lienzo(_ anim: Animacion, t: Double) -> some View {
        Canvas { gc, tam in
            DibujoFigura(anim: anim, t: t,
                         principales: Set(ejercicio.principales),
                         secundarios: Set(ejercicio.secundarios)).dibujar(en: &gc, tam: tam)
        }
    }
}

// MARK: - Dibujo (misma lógica que la versión web)

struct DibujoFigura {
    static let ancho: CGFloat = 120
    static let alto: CGFloat = 110

    let anim: Animacion
    let t: Double
    let principales: Set<Musculo>
    var secundarios: Set<Musculo> = []

    // Longitudes del cuerpo
    private let lTorso = 30.0, lBrazo = 15.0, lAntebrazo = 14.0, lMuslo = 22.0, lPierna = 21.0, lPie = 7.0, lCuello = 10.0

    // Colores (estilo lámina, iguales que el mapa muscular)
    private let cCuerpo = Color.white
    private let cCerca = Color.white
    private let cLejos = Color(red: 0.93, green: 0.93, blue: 0.95)
    private let cTrabaja = Color(red: 0.90, green: 0.22, blue: 0.24)
    private let cTrabajaLejos = Color(red: 0.94, green: 0.55, blue: 0.55)
    private let cSecundario = Color(red: 0.98, green: 0.62, blue: 0.20)
    private let cSecundarioLejos = Color(red: 0.99, green: 0.78, blue: 0.59)
    private let cContorno = Color(red: 0.10, green: 0.10, blue: 0.12)
    private let cContornoLejos = Color(red: 0.47, green: 0.49, blue: 0.53)
    private let cEquipo = Color(red: 0.18, green: 0.20, blue: 0.24)
    private let cMueble = Color(red: 0.69, green: 0.73, blue: 0.78)

    private var deFrente: Bool { anim.vista == "frente" }

    private func pose() -> [String: Double] {
        let a = anim.a.resuelta(deFrente: deFrente)
        let b = anim.b.resuelta(deFrente: deFrente)
        var r = a
        for (k, va) in a {
            if k == "sentado" { continue }
            let vb = b[k] ?? va
            r[k] = va + (vb - va) * t
        }
        return r
    }

    private func punto(_ o: CGPoint, _ angulo: Double, _ largo: Double) -> CGPoint {
        let a = angulo * .pi / 180
        return CGPoint(x: o.x + largo * cos(a), y: o.y + largo * sin(a))
    }

    // MARK: Articulaciones

    private func articulacionesLado(_ p: [String: Double]) -> [String: CGPoint] {
        func v(_ k: String) -> Double { p[k] ?? 0 }
        let anclaje = (t < 0.5 ? anim.a.anclaje : anim.b.anclaje) ?? "pie"
        var cadera: CGPoint
        switch anclaje {
        case "pie":
            let tobillo = CGPoint(x: v("x"), y: v("y"))
            let rodilla = punto(tobillo, v("pierna") + 180, lPierna)
            cadera = punto(rodilla, v("muslo") + 180, lMuslo)
        case "mano":
            let mano = CGPoint(x: v("x"), y: v("y"))
            let codo = punto(mano, v("antebrazo") + 180, lAntebrazo)
            let hombro = punto(codo, v("brazo") + 180, lBrazo)
            cadera = punto(hombro, v("torso") + 180, lTorso)
        default:
            cadera = CGPoint(x: v("x"), y: v("y"))
        }
        var j: [String: CGPoint] = ["cadera": cadera]
        let hombro = punto(cadera, v("torso"), lTorso)
        j["hombro"] = hombro
        j["cabeza"] = punto(hombro, v("torso") + v("cuello"), lCuello)
        for lado in ["a", "b"] {
            let suf = lado == "a" ? "" : "_b"
            let codo = punto(hombro, v("brazo" + suf), lBrazo)
            j["codo" + lado] = codo
            j["mano" + lado] = punto(codo, v("antebrazo" + suf), lAntebrazo)
            let rodilla = punto(cadera, v("muslo" + suf), lMuslo)
            j["rodilla" + lado] = rodilla
            let tobillo = punto(rodilla, v("pierna" + suf), lPierna)
            j["tobillo" + lado] = tobillo
            j["punta" + lado] = punto(tobillo, v("pie" + suf), lPie)
        }
        return j
    }

    private func articulacionesFrente(_ p: [String: Double]) -> [String: CGPoint] {
        func v(_ k: String) -> Double { p[k] ?? 0 }
        let cx = v("x"), by = v("y")
        let sentado = v("sentado") > 0.5
        let lm = sentado ? 9.0 : lMuslo
        let caderaY = sentado ? by + lPierna + lm : by + lMuslo + lPierna
        var j: [String: CGPoint] = [:]
        let cadera = CGPoint(x: cx, y: caderaY)
        j["cadera"] = cadera
        j["hombro"] = CGPoint(x: cx, y: caderaY + 28 + v("hombros"))
        j["cabeza"] = CGPoint(x: cx, y: caderaY + 38)
        for (lado, sg) in [("a", 1.0), ("b", -1.0)] {
            let hom = CGPoint(x: cx + sg * 9, y: caderaY + 28 + v("hombros"))
            j["hom" + lado] = hom
            let ua = -90 + sg * v("abd_" + lado)
            let codo = punto(hom, ua, lBrazo)
            j["codo" + lado] = codo
            j["mano" + lado] = punto(codo, ua + sg * v("codo_" + lado), lAntebrazo)
            let cad = CGPoint(x: cx + sg * 5, y: caderaY)
            j["cad" + lado] = cad
            let ta = -90 + sg * v("abre_" + lado)
            let rodilla = punto(cad, ta, lm)
            j["rodilla" + lado] = rodilla
            let tobillo = punto(rodilla, sentado ? -90 : ta, lPierna)
            j["tobillo" + lado] = tobillo
            j["punta" + lado] = punto(tobillo, -90 + sg * 70, 4)
        }
        let rot = v("rot")
        if rot != 0 {
            let r = rot * .pi / 180
            for (k, q) in j {
                let dx = q.x - cx, dy = q.y - by
                j[k] = CGPoint(x: cx + dx * cos(r) - dy * sin(r), y: by + dx * sin(r) + dy * cos(r))
            }
        }
        return j
    }

    // MARK: Colores según músculo trabajado

    private func toca(_ parte: String, _ m: Set<Musculo>) -> Bool {
        let torso: Set<Musculo> = [.pecho, .hombros, .trapecio, .espalda, .abdominales, .oblicuos, .lumbares]
        let brazo: Set<Musculo> = [.biceps, .triceps]
        let muslo: Set<Musculo> = [.cuadriceps, .isquiotibiales, .aductores, .abductores, .gluteos]
        switch parte {
        case "torso": return !m.isDisjoint(with: torso)
        case "brazo": return !m.isDisjoint(with: brazo)
        case "antebrazo": return m.contains(.antebrazos)
        case "muslo": return !m.isDisjoint(with: muslo)
        case "pierna": return m.contains(.gemelos)
        default: return false
        }
    }

    private func color(_ parte: String, cerca: Bool = true) -> Color {
        if toca(parte, principales) { return cerca ? cTrabaja : cTrabajaLejos }
        if toca(parte, secundarios.subtracting(principales)) { return cerca ? cSecundario : cSecundarioLejos }
        return cerca ? cCerca : cLejos
    }

    // MARK: Dibujo

    func dibujar(en gc: inout GraphicsContext, tam: CGSize) {
        let s = min(tam.width / Self.ancho, tam.height / Self.alto)
        let ox = (tam.width - Self.ancho * s) / 2
        let oy = (tam.height - Self.alto * s) / 2
        func T(_ q: CGPoint) -> CGPoint { CGPoint(x: ox + q.x * s, y: oy + (Self.alto - 8 - q.y) * s) }

        func linea(_ pts: [CGPoint], _ c: Color, _ w: CGFloat) {
            guard let primero = pts.first else { return }
            var path = Path()
            path.move(to: T(primero))
            for q in pts.dropFirst() { path.addLine(to: T(q)) }
            gc.stroke(path, with: .color(c), style: StrokeStyle(lineWidth: w * s, lineCap: .round, lineJoin: .round))
        }
        func circulo(_ q: CGPoint, _ r: CGFloat, _ c: Color) {
            let p = T(q)
            gc.fill(Path(ellipseIn: CGRect(x: p.x - r * s, y: p.y - r * s, width: 2 * r * s, height: 2 * r * s)), with: .color(c))
        }
        func mancuerna(_ q: CGPoint, _ c: Color) {
            let p = T(q)
            gc.fill(Path(roundedRect: CGRect(x: p.x - 4.5 * s, y: p.y - 1.8 * s, width: 9 * s, height: 3.6 * s), cornerRadius: s), with: .color(c))
            for dx in [-4.5, 4.5] {
                gc.fill(Path(roundedRect: CGRect(x: p.x + (dx - 1.2) * s, y: p.y - 3 * s, width: 2.4 * s, height: 6 * s), cornerRadius: 0.6 * s), with: .color(c))
            }
        }
        func pt(_ arr: [Double], _ i: Int) -> CGPoint { CGPoint(x: arr[i], y: arr[i + 1]) }

        let pr = anim.props ?? Accesorios()
        let j = deFrente ? articulacionesFrente(pose()) : articulacionesLado(pose())
        func J(_ k: String) -> CGPoint { j[k] ?? .zero }
        // Miembro estilo lámina: primero el contorno y encima el relleno
        func seg(_ a: String, _ b: String, _ c: Color, _ w: CGFloat, lejos: Bool = false) {
            linea([J(a), J(b)], lejos ? cContornoLejos : cContorno, w + 1.5)
            linea([J(a), J(b)], c, w)
        }
        func cabeza() {
            circulo(J("cabeza"), 6.9, cContorno)
            circulo(J("cabeza"), 6.2, cCuerpo)
        }

        // Suelo y accesorios fijos
        linea([CGPoint(x: 0, y: 0), CGPoint(x: Self.ancho, y: 0)], Color.gray.opacity(0.25), 1)
        if let e = pr.esterilla, e.count >= 2 {
            linea([CGPoint(x: e[0], y: 0.6), CGPoint(x: e[1], y: 0.6)], Color(red: 0.75, green: 0.85, blue: 0.93), 1.6)
        }
        if let b = pr.banco, b.count >= 3 {
            linea([CGPoint(x: b[0], y: b[2] - 2), CGPoint(x: b[1], y: b[2] - 2)], cMueble, 4)
            for xx in [b[0] + 3, b[1] - 3] { linea([CGPoint(x: xx, y: b[2] - 2), CGPoint(x: xx, y: 0)], cMueble, 1.6) }
        }
        if let e = pr.escalon, e.count >= 3 {
            let a = T(CGPoint(x: e[0], y: e[2])), b = T(CGPoint(x: e[1], y: 0))
            gc.fill(Path(CGRect(x: a.x, y: a.y, width: b.x - a.x, height: b.y - a.y)), with: .color(cMueble))
        }
        if let r = pr.respaldo, r.count >= 4 {
            let o = pt(r, 0)
            linea([o, punto(o, r[2], r[3])], cMueble, 4)
        }
        if let p = pr.poste, p.count >= 2 {
            linea([CGPoint(x: p[0], y: 0), CGPoint(x: p[0], y: p[1])], cMueble, 2.5)
        }
        if let p = pr.polea, p.count >= 2 {
            let o = pt(p, 0)
            for m in (deFrente ? ["manoa", "manob"] : ["manoa"]) { linea([o, J(m)], Color.gray.opacity(0.7), 0.6) }
            circulo(o, 2.2, cEquipo)
        }

        if !deFrente {
            // Lado lejano
            seg("hombro", "codob", color("brazo", cerca: false), 4.5, lejos: true)
            seg("codob", "manob", color("antebrazo", cerca: false), 4, lejos: true)
            seg("cadera", "rodillab", color("muslo", cerca: false), 6, lejos: true)
            seg("rodillab", "tobillob", color("pierna", cerca: false), 5, lejos: true)
            seg("tobillob", "puntab", cLejos, 3.5, lejos: true)
            if pr.mancuerna == true { mancuerna(J("manob"), cEquipo.opacity(0.55)) }
            // Tronco y cabeza
            seg("cadera", "hombro", color("torso"), 10)
            cabeza()
            // Lado cercano
            seg("cadera", "rodillaa", color("muslo"), 6.5)
            seg("rodillaa", "tobilloa", color("pierna"), 5.5)
            seg("tobilloa", "puntaa", cCerca, 3.5)
            if let r = pr.rodillo { circulo(J(r), 3, cEquipo) }
            if let b = pr.barra {
                let donde = j[b] == nil ? "manoa" : b
                circulo(J(donde), 7, Color(red: 0.27, green: 0.29, blue: 0.33))
                circulo(J(donde), 1.6, Color(white: 0.8))
            }
            if pr.mochila == true {
                let p = T(J("manoa"))
                gc.fill(Path(roundedRect: CGRect(x: p.x - 4 * s, y: p.y, width: 8 * s, height: 9 * s), cornerRadius: 2 * s), with: .color(cTrabaja))
            }
            seg("hombro", "codoa", color("brazo"), 5)
            seg("codoa", "manoa", color("antebrazo"), 4.5)
            if pr.mancuerna == true { mancuerna(J("manoa"), cEquipo) }
            if pr.asa == true {
                let p = T(J("manoa"))
                gc.fill(Path(roundedRect: CGRect(x: p.x - 1.3 * s, y: p.y - 3.5 * s, width: 2.6 * s, height: 7 * s), cornerRadius: s), with: .color(cEquipo))
            }
        } else {
            if pr.barra != nil { linea([punto(J("manob"), 180, 6), punto(J("manoa"), 0, 6)], cEquipo, 1.8) }
            if pr.toalla == true { linea([J("manob"), J("manoa")], cTrabaja, 2.5) }
            for lado in ["a", "b"] {
                seg("cad" + lado, "rodilla" + lado, color("muslo"), 6.5)
                seg("rodilla" + lado, "tobillo" + lado, color("pierna"), 5.5)
                seg("tobillo" + lado, "punta" + lado, cCerca, 3.5)
            }
            let ct = color("torso")
            linea([J("cada"), J("cadb")], cContorno, 8.5)
            linea([J("homa"), J("homb")], cContorno, 8.5)
            linea([J("cadera"), J("hombro")], cContorno, 14.5)
            linea([J("cada"), J("cadb")], ct, 7)
            linea([J("homa"), J("homb")], ct, 7)
            linea([J("cadera"), J("hombro")], ct, 13)
            cabeza()
            for lado in ["a", "b"] {
                seg("hom" + lado, "codo" + lado, color("brazo"), 5)
                seg("codo" + lado, "mano" + lado, color("antebrazo"), 4.5)
                if pr.mancuerna == true { mancuerna(J("mano" + lado), cEquipo) }
                if pr.asa == true { circulo(J("mano" + lado), 2, cEquipo) }
            }
        }
    }
}

#Preview {
    if let e = Catalogo.ejercicios.first {
        FiguraEjercicioView(ejercicio: e).frame(width: 300).padding()
    }
}
