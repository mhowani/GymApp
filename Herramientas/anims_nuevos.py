"""Animaciones de los ejercicios añadidos en el hilo de diseño (los que no estaban en anims.py).
Mismo formato que anims.py: a = posición inicial, b = posición final, props = accesorios."""
import copy
from anims import A, de_pie, tumbado_banco, sentado, frente, BANCO, ASIENTO


def como(id_base, **cambios):
    """Copia la animación de otro ejercicio y cambia lo indicado (props se mezclan)."""
    d = copy.deepcopy(A[id_base])
    props = cambios.pop('props', None)
    quitar = cambios.pop('quitar', ())
    d.update(cambios)
    if props is not None:
        p = dict(d.get('props', {}))
        p.update(props)
        for k in quitar:
            p.pop(k, None)
        d['props'] = p
    return d


def cuadrupedia(**k):  # a cuatro patas, cabeza a la derecha
    p = dict(anclaje='mano', x=80, y=0, torso=13.5, brazo=-90, antebrazo=-90, brazo_b=-91, antebrazo_b=-91,
             muslo=-90, pierna=180, pie=180, muslo_b=-91, pierna_b=180, pie_b=180)
    p.update(k); return p


def boca_arriba(**k):  # tumbado en el suelo, cabeza a la izquierda
    p = dict(anclaje='cadera', x=58, y=4, torso=178, muslo=35, pierna=-80, muslo_b=33, pierna_b=-82,
             brazo=-2, antebrazo=0, brazo_b=-3, antebrazo_b=-1)
    p.update(k); return p


INCLINADO = dict(torso=35, muslo=-70, pierna=-100, muslo_b=-73, pierna_b=-101)

E = {
# ---------------- PESAS ----------------
'press-banca-mancuernas': como('press-banca-barra', props=dict(mancuerna=True), quitar=('barra',)),
'press-inclinado-barra': como('press-inclinado-mancuernas', props=dict(barra='manoa'), quitar=('mancuerna',)),
'pullover-mancuerna': dict(a=tumbado_banco(brazo=172, antebrazo=176, brazo_b=170, antebrazo_b=174),
                           b=tumbado_banco(brazo=95, antebrazo=95, brazo_b=93, antebrazo_b=93),
                           props=dict(BANCO, mancuerna=True)),
'press-militar-barra': como('press-militar-mancuernas', props=dict(barra='manoa'), quitar=('mancuerna',)),
'pajaros-mancuernas': dict(vista='frente', a=frente(abd=10, codo=12), b=frente(abd=88, codo=12),
                           props=dict(mancuerna=True)),
'elevaciones-frontales': dict(a=de_pie(brazo=-85, antebrazo=-85, brazo_b=-90, antebrazo_b=-90),
                              b=de_pie(brazo=0, antebrazo=0, brazo_b=-90, antebrazo_b=-90),
                              props=dict(mancuerna=True)),
'remo-al-menton': dict(vista='frente', a=frente(abd=8, codo=0), b=frente(abd=78, codo=150),
                       props=dict(mancuerna=True)),
'remo-barra': dict(a=de_pie(brazo=-90, antebrazo=-90, brazo_b=-92, antebrazo_b=-92, **INCLINADO),
                   b=de_pie(brazo=-155, antebrazo=-55, brazo_b=-157, antebrazo_b=-57, **INCLINADO),
                   props=dict(barra='manoa')),
'curl-barra': como('curl-biceps-mancuernas', props=dict(barra='manoa'), quitar=('mancuerna',)),
'curl-concentrado': dict(a=sentado(torso=58, brazo=-82, antebrazo=-80, brazo_b=-100, antebrazo_b=-60),
                         b=sentado(torso=58, brazo=-82, antebrazo=75, brazo_b=-100, antebrazo_b=-60),
                         props=dict(banco=[24, 50, 21], mancuerna=True)),
'curl-inverso': como('curl-biceps-mancuernas', props=dict(barra='manoa'), quitar=('mancuerna',)),
'press-cerrado': como('press-banca-barra'),
'patada-triceps': dict(
    a=dict(A['remo-mancuerna']['a'], brazo=172, antebrazo=-90),
    b=dict(A['remo-mancuerna']['a'], brazo=172, antebrazo=176),
    props=dict(banco=[14, 76, 21], mancuerna=True)),
'sentadilla-goblet': dict(a=de_pie(brazo=-70, antebrazo=100, brazo_b=-72, antebrazo_b=98),
                          b=de_pie(torso=62, muslo=-10, pierna=-115, muslo_b=-13, pierna_b=-116,
                                   brazo=-95, antebrazo=75, brazo_b=-97, antebrazo_b=73),
                          props=dict(mancuerna=True)),
'sentadilla-frontal': dict(a=de_pie(brazo=8, antebrazo=168, brazo_b=6, antebrazo_b=166),
                           b=de_pie(torso=70, muslo=-10, pierna=-115, muslo_b=-13, pierna_b=-116,
                                    brazo=-12, antebrazo=148, brazo_b=-14, antebrazo_b=146),
                           props=dict(barra='manoa')),
'subida-banco-mancuernas': dict(
    a=dict(anclaje='cadera', x=40, y=43, torso=90, muslo=-33, pierna=-95, muslo_b=-90, pierna_b=-90,
           brazo=-90, antebrazo=-90, brazo_b=-93, antebrazo_b=-91),
    b=dict(anclaje='cadera', x=57, y=53, torso=90, muslo=-90, pierna=-90, muslo_b=-60, pierna_b=-120,
           brazo=-90, antebrazo=-90, brazo_b=-93, antebrazo_b=-91),
    props=dict(escalon=[50, 78, 10], mancuerna=True)),
'peso-muerto-sumo': como('peso-muerto'),
'buenos-dias': dict(a=de_pie(brazo=-150, antebrazo=60, brazo_b=-146, antebrazo_b=62),
                    b=de_pie(torso=12, muslo=-82, pierna=-96, muslo_b=-84, pierna_b=-97,
                             brazo=132, antebrazo=-18, brazo_b=136, antebrazo_b=-16),
                    props=dict(barra='hombro')),
'paseo-granjero': dict(a=de_pie(muslo=-75, pierna=-100, muslo_b=-105, pierna_b=-92),
                       b=de_pie(muslo=-105, pierna=-92, muslo_b=-75, pierna_b=-100),
                       props=dict(mancuerna=True)),
'giro-ruso-disco': dict(a=dict(anclaje='cadera', x=55, y=4, torso=125, muslo=45, pierna=-30, muslo_b=43, pierna_b=-32,
                               brazo=-25, antebrazo=15, brazo_b=-27, antebrazo_b=13),
                        b=dict(anclaje='cadera', x=55, y=4, torso=118, muslo=45, pierna=-30, muslo_b=43, pierna_b=-32,
                               brazo=-75, antebrazo=-45, brazo_b=-77, antebrazo_b=-47),
                        props=dict(esterilla=[25, 95], barra='manoa')),
# ---------------- MÁQUINAS ----------------
'press-inclinado-maquina': como('press-pecho-maquina',
                                b=sentado(brazo=38, antebrazo=38, brazo_b=36, antebrazo_b=36)),
'fondos-asistidos': dict(
    a=dict(anclaje='mano', x=62, y=48, torso=90, brazo=-90, antebrazo=-90, brazo_b=-91, antebrazo_b=-91,
           muslo=-95, pierna=180, muslo_b=-97, pierna_b=180, pie=180, pie_b=180),
    b=dict(anclaje='mano', x=62, y=48, torso=82, brazo=-160, antebrazo=-60, brazo_b=-161, antebrazo_b=-61,
           muslo=-95, pierna=180, muslo_b=-97, pierna_b=180, pie=180, pie_b=180),
    props=dict(poste=[64, 46], asa=True)),
'elevacion-lateral-polea': como('elevaciones-laterales', props=dict(asa=True), quitar=('mancuerna',)),
'pajaros-maquina': dict(vista='frente', a=frente(sentado=1, abre=12, abd=40, codo=150),
                        b=frente(sentado=1, abre=12, abd=92, codo=0),
                        props=dict(asa=True, banco=[44, 76, 32])),
'dominadas-asistidas': dict(vista='frente', a=frente(y=0, abd=150, codo=0), b=frente(y=10, abd=70, codo=125),
                            props=dict(barra=True)),
'jalon-agarre-estrecho': dict(a=sentado(torso=100, brazo=82, antebrazo=86, brazo_b=80, antebrazo_b=84),
                              b=sentado(torso=104, brazo=-100, antebrazo=72, brazo_b=-102, antebrazo_b=70),
                              props=dict(banco=[24, 50, 21], polea=[46, 104], asa=True)),
'remo-maquina-pecho': dict(a=sentado(torso=82, brazo=0, antebrazo=0, brazo_b=-2, antebrazo_b=-2),
                           b=sentado(torso=82, brazo=-172, antebrazo=8, brazo_b=-174, antebrazo_b=6),
                           props=dict(banco=[24, 50, 21], respaldo=[56, 36, 88, 30], asa=True)),
'pullover-polea': dict(a=de_pie(torso=62, muslo=-80, pierna=-96, muslo_b=-83, pierna_b=-97,
                                brazo=55, antebrazo=58, brazo_b=53, antebrazo_b=56),
                       b=de_pie(torso=62, muslo=-80, pierna=-96, muslo_b=-83, pierna_b=-97,
                                brazo=-80, antebrazo=-78, brazo_b=-82, antebrazo_b=-80),
                       props=dict(polea=[104, 92], poste=[104, 94], asa=True)),
'curl-scott-maquina': dict(a=sentado(torso=78, brazo=-40, antebrazo=-28, brazo_b=-42, antebrazo_b=-30),
                           b=sentado(torso=78, brazo=-40, antebrazo=85, brazo_b=-42, antebrazo_b=83),
                           props=dict(banco=[24, 50, 21], asa=True)),
'extension-triceps-cuerda': dict(
    a=de_pie(torso=72, muslo=-75, pierna=-95, muslo_b=-105, pierna_b=-92, brazo=112, antebrazo=-112, brazo_b=110, antebrazo_b=-114),
    b=de_pie(torso=72, muslo=-75, pierna=-95, muslo_b=-105, pierna_b=-92, brazo=112, antebrazo=62, brazo_b=110, antebrazo_b=60),
    props=dict(polea=[22, 8], poste=[22, 14], asa=True)),
'sentadilla-hack': como('sentadilla-barra',
                        b=de_pie(torso=72, muslo=-10, pierna=-115, muslo_b=-13, pierna_b=-116,
                                 brazo=-168, antebrazo=42, brazo_b=-164, antebrazo_b=44)),
'sentadilla-multipower': como('sentadilla-barra', props=dict(poste=[84, 100])),
'curl-femoral-sentado': dict(a=sentado(muslo=0, pierna=-5, muslo_b=-3, pierna_b=-7, brazo=-100, antebrazo=-60),
                             b=sentado(muslo=0, pierna=-112, muslo_b=-3, pierna_b=-114, brazo=-100, antebrazo=-60),
                             props=dict(ASIENTO, rodillo='tobilloa')),
'patada-gluteo-polea': dict(
    a=de_pie(torso=80, brazo=-20, antebrazo=0, brazo_b=-22, antebrazo_b=-2, muslo_b=-95, pierna_b=-95),
    b=de_pie(torso=78, brazo=-20, antebrazo=0, brazo_b=-22, antebrazo_b=-2, muslo_b=-145, pierna_b=-150),
    props=dict(poste=[93, 62])),
'hip-thrust-maquina': como('hip-thrust-barra'),
'gemelos-sentado': dict(a=sentado(pie=0, brazo=-80, antebrazo=-20, brazo_b=-82, antebrazo_b=-22),
                        b=sentado(y=27, pie=-50, brazo=-80, antebrazo=-20, brazo_b=-82, antebrazo_b=-22),
                        props=dict(banco=[24, 50, 21], rodillo='rodillaa')),
'crunch-maquina': dict(a=sentado(torso=92, brazo=100, antebrazo=-80, brazo_b=98, antebrazo_b=-82),
                       b=sentado(torso=48, brazo=56, antebrazo=-124, brazo_b=54, antebrazo_b=-126),
                       props=dict(banco=[24, 50, 21], asa=True)),
'elevacion-piernas-paralelas': dict(
    a=dict(anclaje='cadera', x=55, y=50, torso=92, brazo=-90, antebrazo=0, brazo_b=-91, antebrazo_b=-1,
           muslo=-90, pierna=-90, muslo_b=-92, pierna_b=-92),
    b=dict(anclaje='cadera', x=55, y=50, torso=95, brazo=-90, antebrazo=0, brazo_b=-91, antebrazo_b=-1,
           muslo=8, pierna=-60, muslo_b=6, pierna_b=-62),
    props=dict(respaldo=[50, 44, 92, 40], poste=[50, 64])),
# ---------------- EN CASA ----------------
'flexiones-inclinadas': dict(
    a=dict(anclaje='mano', x=80, y=21, torso=45, muslo=-143, pierna=-143, muslo_b=-144, pierna_b=-144, pie=-90,
           brazo=-90, antebrazo=-90, brazo_b=-91, antebrazo_b=-91),
    b=dict(anclaje='mano', x=80, y=21, torso=35, muslo=-157, pierna=-157, muslo_b=-158, pierna_b=-158, pie=-90,
           brazo=-150, antebrazo=-35, brazo_b=-151, antebrazo_b=-36),
    props=dict(banco=[70, 102, 23])),
'flexiones-declinadas': dict(
    a=dict(anclaje='mano', x=85, y=0, torso=-20, muslo=-155, pierna=-155, muslo_b=-156, pierna_b=-156, pie=-90,
           brazo=-90, antebrazo=-90, brazo_b=-91, antebrazo_b=-91),
    b=dict(anclaje='mano', x=85, y=0, torso=-26, muslo=-162, pierna=-162, muslo_b=-163, pierna_b=-163, pie=-90,
           brazo=-150, antebrazo=-35, brazo_b=-151, antebrazo_b=-36),
    props=dict(banco=[6, 30, 23])),
'flexiones-abiertas': como('flexiones'),
'ytw-suelo': dict(a=dict(A['superman']['a']),
                  b=dict(A['superman']['a'], torso=8, brazo=22, antebrazo=22, brazo_b=24, antebrazo_b=24),
                  props=dict(esterilla=[0, 120])),
'isometrico-biceps-toalla': dict(a=de_pie(brazo=-85, antebrazo=0, brazo_b=-87, antebrazo_b=-2),
                                 b=de_pie(brazo=-85, antebrazo=8, brazo_b=-87, antebrazo_b=6)),
'sentadilla-sumo': como('sentadilla',
                        b=de_pie(torso=78, muslo=-20, pierna=-105, muslo_b=-23, pierna_b=-106,
                                 brazo=-70, antebrazo=100, brazo_b=-72, antebrazo_b=98)),
'sentadilla-salto': dict(a=copy.deepcopy(A['sentadilla']['b']),
                         b=de_pie(y=5, pie=-60, pie_b=-60, brazo=30, antebrazo=40, brazo_b=28, antebrazo_b=38)),
'sentadilla-pared': dict(a=dict(anclaje='cadera', x=40, y=22, torso=90, muslo=0, pierna=-90, muslo_b=-3, pierna_b=-92,
                                brazo=-90, antebrazo=-90, brazo_b=-93, antebrazo_b=-92),
                         b=dict(anclaje='cadera', x=40, y=21, torso=90, muslo=-2, pierna=-90, muslo_b=-5, pierna_b=-92,
                                brazo=-90, antebrazo=0, brazo_b=-93, antebrazo_b=-2),
                         props=dict(poste=[34, 92])),
'zancada-inversa': como('zancadas'),
'puente-una-pierna': dict(a=boca_arriba(muslo_b=35, pierna_b=35),
                          b=boca_arriba(y=20, torso=208, cuello=-28, muslo=8, pierna=-75, muslo_b=8, pierna_b=8),
                          props=dict(esterilla=[5, 85])),
'patada-gluteo-cuadrupedia': dict(a=cuadrupedia(), b=cuadrupedia(muslo_b=175, pierna_b=95, pie_b=180),
                                  props=dict(esterilla=[20, 100])),
'almeja': como('patada-lateral', b=frente(x=100, y=10, rot=90, abd=10, codo=0, abre_b=4, abre_a=32)),
'curl-nordico': dict(
    a=dict(anclaje='cadera', x=50, y=22, torso=90, muslo=-90, pierna=180, pie=180, muslo_b=-91, pierna_b=180, pie_b=180,
           brazo=-70, antebrazo=100, brazo_b=-72, antebrazo_b=98),
    b=dict(anclaje='cadera', x=64, y=17, torso=50, muslo=-130, pierna=180, pie=180, muslo_b=-131, pierna_b=180, pie_b=180,
           brazo=-30, antebrazo=0, brazo_b=-32, antebrazo_b=-2),
    props=dict(esterilla=[15, 100])),
'gemelos-una-pierna': dict(a=de_pie(y=6, pie=-10, muslo_b=-100, pierna_b=-160, brazo=-60, antebrazo=0),
                           b=de_pie(y=10.5, pie=-55, muslo_b=-100, pierna_b=-160, brazo=-60, antebrazo=0),
                           props=dict(escalon=[62, 90, 5])),
'bicho-muerto': dict(a=boca_arriba(muslo=90, pierna=0, muslo_b=88, pierna_b=-2, brazo=90, antebrazo=90, brazo_b=88, antebrazo_b=88),
                     b=boca_arriba(muslo=90, pierna=0, muslo_b=12, pierna_b=10, brazo=172, antebrazo=174, brazo_b=88, antebrazo_b=88),
                     props=dict(esterilla=[5, 100])),
'elevacion-piernas-suelo': dict(a=boca_arriba(muslo=88, pierna=88, muslo_b=86, pierna_b=86),
                                b=boca_arriba(muslo=12, pierna=12, muslo_b=10, pierna_b=10),
                                props=dict(esterilla=[5, 115])),
'crunch-bicicleta': dict(
    a=dict(A['crunch']['a'], torso=150, muslo=72, pierna=-20, muslo_b=18, pierna_b=16),
    b=dict(A['crunch']['b'], torso=150, muslo=18, pierna=16, muslo_b=72, pierna_b=-20),
    props=dict(esterilla=[5, 110])),
'bird-dog': dict(a=cuadrupedia(), b=cuadrupedia(brazo_b=8, antebrazo_b=8, muslo_b=180, pierna_b=180, pie_b=-90),
                 props=dict(esterilla=[5, 100])),
'burpees': dict(a=dict(anclaje='cadera', x=60, y=43, torso=90, muslo=-90, pierna=-90, muslo_b=-93, pierna_b=-92,
                       brazo=45, antebrazo=50, brazo_b=43, antebrazo_b=48),
                b=dict(anclaje='cadera', x=50.4, y=17.3, torso=23, muslo=-157, pierna=-157, muslo_b=-158, pierna_b=-158, pie=-90,
                       brazo=-90, antebrazo=-90, brazo_b=-91, antebrazo_b=-91),
                props=dict(esterilla=[10, 95])),
}
