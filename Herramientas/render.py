"""Renderizador de referencia (Python) de la figura animada.
Se porta 1:1 a Swift (FiguraEjercicioView.swift) y a JavaScript (web)."""
import math
from PIL import Image, ImageDraw

L = dict(torso=30, brazo=15, antebrazo=14, muslo=22, pierna=21, pie=7, cuello=10)
W, H = 120, 110  # caja lógica; suelo en y=0

def P(o, ang, l):
    a = math.radians(ang)
    return (o[0] + l * math.cos(a), o[1] + l * math.sin(a))

def g(p, k, d=0):
    return p.get(k, d)

def side(p):
    """Vista de lado, mirando a la derecha. Ángulos absolutos (grados, 0=derecha, 90=arriba)."""
    br_a, an_a = p['brazo'], p['antebrazo']
    br_b, an_b = g(p, 'brazo_b', br_a), g(p, 'antebrazo_b', an_a)
    mu_a, pi_a = p['muslo'], p['pierna']
    mu_b, pi_b = g(p, 'muslo_b', mu_a), g(p, 'pierna_b', pi_a)
    an = g(p, 'anclaje', 'pie')
    if an == 'pie':
        ank = (p['x'], g(p, 'y'))
        hip = P(P(ank, pi_a + 180, L['pierna']), mu_a + 180, L['muslo'])
    elif an == 'mano':
        hand = (p['x'], g(p, 'y'))
        sh = P(P(hand, an_a + 180, L['antebrazo']), br_a + 180, L['brazo'])
        hip = P(sh, p['torso'] + 180, L['torso'])
    else:
        hip = (p['x'], p['y'])
    J = {'cadera': hip}
    sh = J['hombro'] = P(hip, p['torso'], L['torso'])
    J['cabeza'] = P(sh, p['torso'] + g(p, 'cuello', 0), L['cuello'])
    for s, br, anb, mu, pi, pie in (('a', br_a, an_a, mu_a, pi_a, g(p, 'pie', 0)),
                                    ('b', br_b, an_b, mu_b, pi_b, g(p, 'pie_b', g(p, 'pie', 0)))):
        J['codo' + s] = P(sh, br, L['brazo'])
        J['mano' + s] = P(J['codo' + s], anb, L['antebrazo'])
        J['rodilla' + s] = P(hip, mu, L['muslo'])
        J['tobillo' + s] = P(J['rodilla' + s], pi, L['pierna'])
        J['punta' + s] = P(J['tobillo' + s], pie, L['pie'])
    return J

def front(p):
    """Vista de frente. 'a' = lado derecho de la imagen, 'b' = izquierdo."""
    cx, by = p['x'], g(p, 'y')
    sent = g(p, 'sentado', 0)
    lm = 9 if sent else L['muslo']
    J = {}
    hipc = (cx, by + (0 if sent else L['muslo'] + L['pierna']))
    if sent:
        hipc = (cx, by + L['pierna'] + lm)
    J['cadera'] = hipc
    J['hombro'] = (cx, hipc[1] + 28 + g(p, 'hombros', 0))
    J['cabeza'] = (cx, hipc[1] + 28 + 10)
    for s, sg in (('a', 1), ('b', -1)):
        abd = g(p, 'abd_' + s, g(p, 'abd', 0))
        codo = g(p, 'codo_' + s, g(p, 'codo', 0))
        abre = g(p, 'abre_' + s, g(p, 'abre', 6))
        sh = (cx + sg * 9, J['hombro'][1])
        J['hom' + s] = sh
        ua = -90 + sg * abd
        J['codo' + s] = P(sh, ua, L['brazo'])
        J['mano' + s] = P(J['codo' + s], ua + sg * codo, L['antebrazo'])
        hp = (cx + sg * 5, hipc[1])
        J['cad' + s] = hp
        ta = -90 + sg * abre
        J['rodilla' + s] = P(hp, ta, lm)
        ka = -90 if sent else ta
        J['tobillo' + s] = P(J['rodilla' + s], ka, L['pierna'])
        J['punta' + s] = P(J['tobillo' + s], -90 + sg * 70, 4)
    rot = g(p, 'rot', 0)
    if rot:
        piv = (cx, by)
        r = math.radians(rot)
        for k, (x, y) in list(J.items()):
            dx, dy = x - piv[0], y - piv[1]
            J[k] = (piv[0] + dx * math.cos(r) - dy * math.sin(r), piv[1] + dx * math.sin(r) + dy * math.cos(r))
    return J

SIDE_KEYS = ['x', 'y', 'torso', 'cuello', 'brazo', 'antebrazo', 'brazo_b', 'antebrazo_b', 'muslo', 'pierna',
             'muslo_b', 'pierna_b', 'pie', 'pie_b']
FRONT_KEYS = ['x', 'y', 'rot', 'hombros', 'abd_a', 'abd_b', 'codo_a', 'codo_b', 'abre_a', 'abre_b']

def resolve(p, vista):
    """Rellena valores por defecto: así ambas poses tienen las mismas claves."""
    if vista == 'lado':
        r = dict(anclaje=g(p, 'anclaje', 'pie'), x=p['x'], y=g(p, 'y'), torso=p['torso'], cuello=g(p, 'cuello'),
                 brazo=p['brazo'], antebrazo=p['antebrazo'], muslo=p['muslo'], pierna=p['pierna'], pie=g(p, 'pie'))
        r['brazo_b'] = g(p, 'brazo_b', r['brazo']); r['antebrazo_b'] = g(p, 'antebrazo_b', r['antebrazo'])
        r['muslo_b'] = g(p, 'muslo_b', r['muslo']); r['pierna_b'] = g(p, 'pierna_b', r['pierna'])
        r['pie_b'] = g(p, 'pie_b', r['pie'])
        return r
    r = dict(x=p['x'], y=g(p, 'y'), rot=g(p, 'rot'), hombros=g(p, 'hombros'), sentado=g(p, 'sentado'))
    for s in ('a', 'b'):
        r['abd_' + s] = g(p, 'abd_' + s, g(p, 'abd', 0))
        r['codo_' + s] = g(p, 'codo_' + s, g(p, 'codo', 0))
        r['abre_' + s] = g(p, 'abre_' + s, g(p, 'abre', 6))
    return r

def lerp(A, B, t):
    out = dict(A)
    for k, v in B.items():
        if isinstance(v, (int, float)) and isinstance(A.get(k), (int, float)) and k not in ('sentado',):
            out[k] = A[k] + (v - A[k]) * t
    return out

TORSO = {'pecho', 'hombros', 'trapecio', 'espalda', 'abdominales', 'oblicuos', 'lumbares'}
BRAZO = {'biceps', 'triceps'}
MUSLO = {'cuadriceps', 'isquiotibiales', 'aductores', 'abductores', 'gluteos'}

C_BODY = (255, 255, 255); C_NEAR = (255, 255, 255); C_FAR = (236, 238, 241)
C_HOT = (230, 56, 61); C_HOT_FAR = (240, 140, 140); C_SEC = (250, 158, 51); C_SEC_FAR = (252, 200, 150)
C_LINE = (25, 25, 30); C_LINE_FAR = (120, 125, 135); C_EQ = (45, 50, 60); C_PROP = (175, 186, 200)

def render(anim, t, principales=(), S=4, secundarios=()):
    vista = anim.get('vista', 'lado')
    pose = lerp(resolve(anim['a'], vista), resolve(anim['b'], vista), t)
    J = side(pose) if vista == 'lado' else front(pose)
    pr = anim.get('props', {})
    im = Image.new('RGB', (W * S, H * S), 'white')
    d = ImageDraw.Draw(im)
    T = lambda q: (q[0] * S, (H - 8 - q[1]) * S)
    hot = set(principales); sec = set(secundarios) - hot

    def line(pts, col, w):
        d.line([T(q) for q in pts], fill=col, width=int(w * S), joint='curve')
        for q in pts:
            x, y = T(q); r = w * S / 2
            d.ellipse([x - r, y - r, x + r, y + r], fill=col)

    def seg(a, b, col, w):
        # miembro estilo lámina: contorno negro + relleno
        far = col in (C_FAR, C_HOT_FAR, C_SEC_FAR)
        line([J[a], J[b]], C_LINE_FAR if far else C_LINE, w + 1.5)
        line([J[a], J[b]], col, w)

    def cabeza(q):
        x, y = T(q); r = 6.9 * S; d.ellipse([x - r, y - r, x + r, y + r], fill=C_LINE)
        r = 6.2 * S; d.ellipse([x - r, y - r, x + r, y + r], fill=C_BODY)

    # suelo y accesorios fijos
    d.line([T((0, 0)), T((W, 0))], fill=(215, 220, 228), width=S)
    if 'esterilla' in pr:
        x0, x1 = pr['esterilla']; line([(x0, 0.6), (x1, 0.6)], (190, 215, 235), 1.6)
    if 'banco' in pr:
        x0, x1, h = pr['banco']
        line([(x0, h - 2), (x1, h - 2)], C_PROP, 4)
        for xx in (x0 + 3, x1 - 3): line([(xx, h - 2), (xx, 0)], C_PROP, 1.6)
    if 'escalon' in pr:
        x0, x1, h = pr['escalon']
        d.rectangle([T((x0, h))[0], T((x0, h))[1], T((x1, 0))[0], T((x1, 0))[1]], fill=C_PROP)
    if 'respaldo' in pr:
        x, y, a, l = pr['respaldo']; line([(x, y), P((x, y), a, l)], C_PROP, 4)
    if 'poste' in pr:
        x, h = pr['poste']; line([(x, 0), (x, h)], C_PROP, 2.5)
    if 'polea' in pr:
        x, y = pr['polea']
        for m in (('manoa',) if vista == 'lado' else ('manoa', 'manob')):
            d.line([T((x, y)), T(J[m])], fill=(120, 130, 145), width=int(0.6 * S))
        r = 2.2 * S; X, Y = T((x, y)); d.ellipse([X - r, Y - r, X + r, Y + r], fill=C_EQ)

    def toca(part, m):
        return (part == 'torso' and m & TORSO) or (part == 'brazo' and m & BRAZO) or \
               (part == 'antebrazo' and 'antebrazos' in m) or (part == 'muslo' and m & MUSLO) or \
               (part == 'pierna' and 'gemelos' in m)

    def col(part, near=True):
        if toca(part, hot): return C_HOT if near else C_HOT_FAR
        if toca(part, sec): return C_SEC if near else C_SEC_FAR
        return C_NEAR if near else C_FAR

    def mancuerna(q, c=C_EQ):
        x, y = T(q); d.rounded_rectangle([x - 4.5 * S, y - 1.8 * S, x + 4.5 * S, y + 1.8 * S], radius=S, fill=c)
        for dx in (-4.5, 4.5): d.rounded_rectangle([x + (dx - 1.2) * S, y - 3 * S, x + (dx + 1.2) * S, y + 3 * S], radius=S * .6, fill=c)

    if vista == 'lado':
        # lado lejano
        seg('hombro', 'codob', col('brazo', False), 4.5); seg('codob', 'manob', col('antebrazo', False), 4)
        seg('cadera', 'rodillab', col('muslo', False), 6); seg('rodillab', 'tobillob', col('pierna', False), 5)
        seg('tobillob', 'puntab', C_FAR, 3.5)
        if pr.get('mancuerna'): mancuerna(J['manob'], (140, 145, 155))
        # tronco y cabeza
        seg('cadera', 'hombro', col('torso'), 10)
        cabeza(J['cabeza'])
        # lado cercano
        seg('cadera', 'rodillaa', col('muslo'), 6.5); seg('rodillaa', 'tobilloa', col('pierna'), 5.5)
        seg('tobilloa', 'puntaa', C_NEAR, 3.5)
        if 'rodillo' in pr:
            x, y = T(J[pr['rodillo']]); r = 3 * S; d.ellipse([x - r, y - r, x + r, y + r], fill=C_EQ)
        if 'barra' in pr:
            x, y = T(J[pr['barra']]); r = 7 * S
            d.ellipse([x - r, y - r, x + r, y + r], fill=(70, 75, 85)); r2 = 1.6 * S
            d.ellipse([x - r2, y - r2, x + r2, y + r2], fill=(200, 205, 210))
        if pr.get('mochila'):
            x, y = T(J['manoa']); d.rounded_rectangle([x - 4 * S, y, x + 4 * S, y + 9 * S], radius=2 * S, fill=(232, 129, 127))
        seg('hombro', 'codoa', col('brazo'), 5); seg('codoa', 'manoa', col('antebrazo'), 4.5)
        if pr.get('mancuerna'): mancuerna(J['manoa'])
        if pr.get('asa'):
            x, y = T(J['manoa']); d.rounded_rectangle([x - 1.3 * S, y - 3.5 * S, x + 1.3 * S, y + 3.5 * S], radius=S, fill=C_EQ)
    else:
        if 'barra' in pr:
            line([P(J['manob'], 180, 6), P(J['manoa'], 0, 6)], C_EQ, 1.8)
        if pr.get('toalla'):
            line([J['manob'], J['manoa']], (232, 129, 127), 2.5)
        for s in ('a', 'b'):
            seg('cad' + s, 'rodilla' + s, col('muslo'), 6.5); seg('rodilla' + s, 'tobillo' + s, col('pierna'), 5.5)
            seg('tobillo' + s, 'punta' + s, C_NEAR, 3.5)
        # tronco (trapecio)
        tc = col('torso')
        line([J['cada'], J['cadb']], C_LINE, 8.5); line([J['homa'], J['homb']], C_LINE, 8.5)
        line([J['cadera'], J['hombro']], C_LINE, 14.5)
        line([J['cada'], J['cadb']], tc, 7); line([J['homa'], J['homb']], tc, 7)
        line([J['cadera'], J['hombro']], tc, 13)
        cabeza(J['cabeza'])
        for s in ('a', 'b'):
            seg('hom' + s, 'codo' + s, col('brazo'), 5); seg('codo' + s, 'mano' + s, col('antebrazo'), 4.5)
            if pr.get('mancuerna'): mancuerna(J['mano' + s])
            if pr.get('asa'):
                x, y = T(J['mano' + s]); r = 2 * S; d.ellipse([x - r, y - r, x + r, y + r], fill=C_EQ)
    return im.resize((W * 2, H * 2), Image.LANCZOS)
