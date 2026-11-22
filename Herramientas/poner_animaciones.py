"""Escribe el campo "animacion" de cada ejercicio en ejercicios.json (y opcionalmente una hoja de prueba).
Uso:  python3 Herramientas/poner_animaciones.py GymApp/ejercicios.json [hoja.png]"""
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from anims import A
from anims_nuevos import E

TODAS = {**A, **E}
ruta = sys.argv[1]
datos = json.load(open(ruta, encoding='utf-8'))
faltan = []
for e in datos:
    anim = TODAS.get(e['id'])
    if anim is None:
        faltan.append(e['id']); continue
    d = {'vista': anim.get('vista', 'lado'), 'a': anim['a'], 'b': anim['b']}
    if anim.get('props'): d['props'] = anim['props']
    e['animacion'] = d
with open(ruta, 'w', encoding='utf-8') as f:
    json.dump(datos, f, ensure_ascii=False, indent=2)
    f.write('\n')
print(len(datos) - len(faltan), 'ejercicios con animación; sin animación:', faltan)

if len(sys.argv) > 2:
    from PIL import Image, ImageDraw
    from render import render
    sel = [e for e in datos if 'animacion' in e and (len(sys.argv) < 4 or e['id'] in sys.argv[3].split(','))]
    cw, ch = 240 * 2 + 10, 240
    cols = 4
    filas = (len(sel) + cols - 1) // cols
    hoja = Image.new('RGB', (cols * cw, filas * (ch + 16)), 'white')
    dr = ImageDraw.Draw(hoja)
    for i, e in enumerate(sel):
        x, y = (i % cols) * cw, (i // cols) * (ch + 16)
        for k, t in enumerate((0, 1)):
            hoja.paste(render(e['animacion'], t, e['principales'], secundarios=e['secundarios']), (x + k * 240, y + 16))
        dr.text((x + 4, y + 2), e['id'], fill=(0, 0, 0))
    hoja.save(sys.argv[2])
