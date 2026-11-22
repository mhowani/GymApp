# Genera menus.json para GymApp (app y web)
import json, sys

# id, nombre, seccion, kcal, prot, hc, grasa (por 100 g o 100 ml), extras
S_FV = "Frutas y verduras"
S_CA = "Carne"
S_PE = "Pescado y marisco"
S_HL = "Huevos y lácteos"
S_PC = "Pan, cereales y pasta"
S_LE = "Legumbres y tofu"
S_FS = "Frutos secos y semillas"
S_DE = "Despensa"
S_BV = "Bebidas vegetales"

ING = []
def I(id, nombre, sec, kcal, p, hc, g, **kw):
    d = {"id": id, "nombre": nombre, "seccion": sec, "unidad": kw.pop("unidad", "g"),
         "kcal": kcal, "proteinas": p, "hidratos": hc, "grasas": g,
         "vegetariano": kw.pop("veg", True), "gluten": kw.pop("gluten", False),
         "lactosa": kw.pop("lactosa", False)}
    if "pu" in kw: d["pesoUnidad"] = kw.pop("pu")
    if "nu" in kw: d["nombreUnidad"] = kw.pop("nu")
    if "sg" in kw: d["sinGluten"] = kw.pop("sg")
    if "sl" in kw: d["sinLactosa"] = kw.pop("sl")
    assert not kw, kw
    ING.append(d)

# Frutas y verduras
I("platano", "Plátano", S_FV, 89, 1.1, 23, 0.3, pu=120, nu="ud")
I("manzana", "Manzana", S_FV, 52, 0.3, 14, 0.2, pu=180, nu="ud")
I("naranja", "Naranja", S_FV, 47, 0.9, 12, 0.1, pu=200, nu="ud")
I("pera", "Pera", S_FV, 57, 0.4, 15, 0.1, pu=180, nu="ud")
I("kiwi", "Kiwi", S_FV, 61, 1.1, 15, 0.5, pu=75, nu="ud")
I("fresas", "Fresas", S_FV, 32, 0.7, 7.7, 0.3)
I("frutos_rojos", "Arándanos o frutos rojos", S_FV, 50, 0.8, 12, 0.3)
I("limon", "Limón", S_FV, 29, 1.1, 9, 0.3, pu=100, nu="ud")
I("aguacate", "Aguacate", S_FV, 160, 2, 8.5, 14.7, pu=150, nu="ud")
I("tomate", "Tomate", S_FV, 18, 0.9, 3.9, 0.2, pu=150, nu="ud")
I("lechuga", "Lechuga", S_FV, 15, 1.4, 2.9, 0.2)
I("rucula", "Rúcula o canónigos", S_FV, 25, 2.6, 3.7, 0.7)
I("espinacas", "Espinacas", S_FV, 23, 2.9, 3.6, 0.4)
I("cebolla", "Cebolla", S_FV, 40, 1.1, 9.3, 0.1, pu=150, nu="ud")
I("ajo", "Ajo", S_FV, 149, 6.4, 33, 0.5, pu=5, nu="diente")
I("pimiento_rojo", "Pimiento rojo", S_FV, 31, 1, 6, 0.3, pu=150, nu="ud")
I("pimiento_verde", "Pimiento verde", S_FV, 20, 0.9, 4.6, 0.2, pu=120, nu="ud")
I("calabacin", "Calabacín", S_FV, 17, 1.2, 3.1, 0.3, pu=250, nu="ud")
I("berenjena", "Berenjena", S_FV, 25, 1, 6, 0.2, pu=300, nu="ud")
I("zanahoria", "Zanahoria", S_FV, 41, 0.9, 10, 0.2, pu=80, nu="ud")
I("brocoli", "Brócoli", S_FV, 34, 2.8, 7, 0.4)
I("judias_verdes", "Judías verdes", S_FV, 31, 1.8, 7, 0.2)
I("champinones", "Champiñones", S_FV, 22, 3.1, 3.3, 0.3)
I("pepino", "Pepino", S_FV, 15, 0.7, 3.6, 0.1, pu=250, nu="ud")
I("calabaza", "Calabaza", S_FV, 26, 1, 6.5, 0.1)
I("patata", "Patata", S_FV, 77, 2, 17, 0.1)
I("boniato", "Boniato", S_FV, 86, 1.6, 20, 0.1)
# Carne
I("pollo", "Pechuga de pollo", S_CA, 120, 22.5, 0, 2.6, veg=False)
I("pavo", "Pechuga de pavo (filetes)", S_CA, 114, 24, 0, 1.5, veg=False)
I("ternera", "Ternera magra (filetes)", S_CA, 130, 21, 0, 5, veg=False)
I("lomo_cerdo", "Lomo de cerdo", S_CA, 143, 21, 0, 6, veg=False)
I("jamon", "Jamón serrano", S_CA, 241, 31, 0, 13, veg=False)
I("pavo_fiambre", "Pechuga de pavo en lonchas", S_CA, 100, 19, 1.5, 2, veg=False)
# Pescado
I("salmon", "Salmón", S_PE, 208, 20, 0, 13, veg=False)
I("merluza", "Merluza", S_PE, 86, 17.7, 0, 1.3, veg=False)
I("bacalao", "Bacalao fresco o desalado", S_PE, 82, 18, 0, 0.7, veg=False)
I("dorada", "Dorada o lubina", S_PE, 100, 19.7, 0, 2.3, veg=False)
I("gambas", "Gambas peladas", S_PE, 85, 18, 0.2, 1, veg=False)
I("atun", "Atún al natural (lata)", S_PE, 116, 26, 0, 1, veg=False)
I("sardinas", "Sardinas en aceite (lata)", S_PE, 208, 24.6, 0, 11.5, veg=False)
# Huevos y lácteos
I("huevo", "Huevos", S_HL, 143, 12.6, 0.7, 9.5, pu=60, nu="ud")
I("leche", "Leche semidesnatada", S_HL, 46, 3.2, 4.7, 1.6, unidad="ml", lactosa=True, sl="leche_sl")
I("leche_sl", "Leche semidesnatada sin lactosa", S_HL, 46, 3.2, 4.7, 1.6, unidad="ml")
I("yogur", "Yogur natural", S_HL, 61, 3.5, 4.7, 3.3, pu=125, nu="ud", lactosa=True, sl="yogur_sl")
I("yogur_sl", "Yogur natural sin lactosa", S_HL, 61, 3.5, 4.7, 3.3, pu=125, nu="ud")
I("skyr", "Skyr o yogur proteico natural", S_HL, 63, 11, 4, 0.2, pu=150, nu="ud", lactosa=True, sl="skyr_sl")
I("skyr_sl", "Yogur proteico sin lactosa", S_HL, 63, 11, 4, 0.2, pu=150, nu="ud")
I("queso_batido", "Queso fresco batido 0 %", S_HL, 46, 8, 3.5, 0.2, lactosa=True, sl="queso_batido_sl")
I("queso_batido_sl", "Queso fresco batido sin lactosa", S_HL, 46, 8, 3.5, 0.2)
I("queso_fresco", "Queso fresco tipo Burgos light", S_HL, 98, 12.5, 3, 4, lactosa=True, sl="queso_fresco_sl")
I("queso_fresco_sl", "Queso fresco sin lactosa", S_HL, 98, 12.5, 3, 4)
I("queso_curado", "Queso curado", S_HL, 390, 26, 0, 32, lactosa=True, sl="queso_curado_sl")
I("queso_curado_sl", "Queso curado sin lactosa", S_HL, 390, 26, 0, 32)
# Pan, cereales y pasta
I("pan", "Pan integral", S_PC, 250, 10, 43, 3.5, gluten=True, sg="pan_sg")
I("pan_sg", "Pan sin gluten", S_PC, 260, 4, 46, 6)
I("avena", "Copos de avena", S_PC, 372, 13.5, 59, 7, gluten=True, sg="avena_sg")
I("avena_sg", "Copos de avena sin gluten (certificada)", S_PC, 372, 13.5, 59, 7)
I("arroz", "Arroz", S_PC, 360, 6.7, 79, 0.6)
I("arroz_integral", "Arroz integral", S_PC, 350, 7.5, 73, 2.7)
I("pasta", "Pasta integral", S_PC, 350, 13, 66, 2.5, gluten=True, sg="pasta_sg")
I("pasta_sg", "Pasta sin gluten", S_PC, 355, 7, 77, 1.5)
I("cuscus", "Cuscús", S_PC, 376, 12.8, 77, 0.6, gluten=True)
I("quinoa", "Quinoa", S_PC, 368, 14, 64, 6)
I("wrap", "Tortillas de trigo integral (wraps)", S_PC, 290, 9, 48, 7, pu=60, nu="ud", gluten=True, sg="tortilla_maiz")
I("tortilla_maiz", "Tortillas de maíz", S_PC, 218, 5.7, 45, 2.9, pu=30, nu="ud")
I("tortitas_arroz", "Tortitas de arroz", S_PC, 387, 8, 81, 3, pu=10, nu="ud")
# Legumbres y tofu
I("lentejas", "Lentejas (secas)", S_LE, 340, 24, 55, 1.5)
I("garbanzos", "Garbanzos cocidos (bote)", S_LE, 140, 7.5, 19, 2.6)
I("alubias", "Alubias blancas cocidas (bote)", S_LE, 110, 7, 17, 0.5)
I("tofu", "Tofu firme", S_LE, 144, 15.8, 2.8, 8.7)
I("hummus", "Hummus", S_LE, 230, 7, 14, 16)
I("guisantes", "Guisantes (congelados)", S_LE, 81, 5.4, 14, 0.4)
# Frutos secos y semillas
I("nueces", "Nueces", S_FS, 650, 15, 7, 65)
I("almendras", "Almendras", S_FS, 600, 21, 7, 52)
I("crema_cacahuete", "Crema de cacahuete 100 %", S_FS, 590, 25, 13, 49)
I("chia", "Semillas de chía", S_FS, 490, 17, 8, 31)
# Despensa
I("aceite", "Aceite de oliva virgen extra", S_DE, 900, 0, 0, 100, unidad="ml")
I("tomate_triturado", "Tomate triturado", S_DE, 32, 1.6, 5, 0.3)
I("aceitunas", "Aceitunas", S_DE, 145, 1, 3.8, 15)
I("maiz", "Maíz dulce (lata)", S_DE, 86, 3.3, 19, 1.4)
I("miel", "Miel", S_DE, 304, 0.3, 82, 0)
I("cacao", "Cacao puro en polvo", S_DE, 360, 20, 12, 21)
I("caldo", "Caldo de verduras", S_DE, 5, 0.3, 0.6, 0.2, unidad="ml")
# Bebidas vegetales
I("bebida_soja", "Bebida de soja sin azúcar", S_BV, 39, 3.3, 2.5, 1.8, unidad="ml")

IDS = {i["id"]: i for i in ING}

PLATOS = []
def P(id, nombre, comidas, ingredientes, prep, minutos):
    for k, _ in ingredientes:
        assert k in IDS, k
    PLATOS.append({"id": id, "nombre": nombre, "comidas": comidas, "minutos": minutos,
                   "preparacion": prep,
                   "ingredientes": [{"id": k, "cantidad": c} for k, c in ingredientes]})

D = ["desayuno"]; T = ["media_manana", "merienda"]; C = ["comida"]; N = ["cena"]; CN = ["comida", "cena"]

# ---------- Desayunos ----------
P("d_tostada_jamon", "Tostadas con tomate, aceite y jamón + naranja", D,
  [("pan", 80), ("tomate", 100), ("aceite", 10), ("jamon", 40), ("naranja", 200)],
  "Tuesta el pan, ralla el tomate encima, añade un chorrito de aceite y el jamón. La naranja, entera o en zumo sin colar.", 5)
P("d_tostada_queso", "Tostadas con tomate y queso fresco + kiwi", D,
  [("pan", 80), ("tomate", 100), ("aceite", 8), ("queso_fresco", 80), ("kiwi", 75)],
  "Tuesta el pan, añade tomate rallado, aceite y el queso fresco en lonchas. De postre, el kiwi.", 5)
P("d_porridge", "Porridge de avena con plátano y nueces", D,
  [("avena", 60), ("leche", 250), ("platano", 120), ("nueces", 15)],
  "Calienta la leche con la avena 3-4 minutos removiendo. Sirve con el plátano en rodajas y las nueces troceadas.", 8)
P("d_bowl_skyr", "Bol de yogur proteico con avena, frutos rojos y almendras", D,
  [("skyr", 150), ("avena", 40), ("frutos_rojos", 100), ("almendras", 15), ("miel", 8)],
  "Mezcla en un bol el yogur con la avena y pon encima la fruta, las almendras y un hilo de miel.", 3)
P("d_tortilla_francesa", "Tortilla francesa con pan y tomate + café con leche", D,
  [("huevo", 120), ("pan", 60), ("tomate", 100), ("aceite", 5), ("leche", 150)],
  "Bate los huevos y cuájalos en la sartén con unas gotas de aceite. Acompaña con pan con tomate y café con leche.", 7)
P("d_tostada_aguacate_huevo", "Tostada de aguacate y huevo + naranja", D,
  [("pan", 70), ("aguacate", 60), ("huevo", 60), ("tomate", 50), ("naranja", 200)],
  "Chafa el aguacate sobre el pan tostado, añade tomate en rodajas y un huevo a la plancha o cocido.", 8)
P("d_tostada_aguacate_soja", "Tostadas de aguacate y tomate + café con bebida de soja", D,
  [("pan", 80), ("aguacate", 70), ("tomate", 100), ("chia", 5), ("bebida_soja", 250)],
  "Tuesta el pan, pon el aguacate chafado, el tomate y unas semillas de chía. Café o cacao con bebida de soja.", 5)
P("d_tortitas_cacahuete", "Tortitas de arroz con crema de cacahuete y plátano", D,
  [("tortitas_arroz", 30), ("crema_cacahuete", 20), ("platano", 120), ("bebida_soja", 250)],
  "Unta las tortitas con la crema de cacahuete y pon el plátano en rodajas. Acompaña con bebida de soja.", 3)
P("d_pudin_chia", "Pudin de chía con frutos rojos", D,
  [("chia", 25), ("bebida_soja", 200), ("avena", 30), ("frutos_rojos", 100), ("almendras", 10)],
  "La noche anterior mezcla la chía, la avena y la bebida de soja y deja en la nevera. Por la mañana añade fruta y almendras.", 5)
P("d_tostada_pavo", "Tostadas con tomate y pavo + vaso de leche", D,
  [("pan", 80), ("tomate", 80), ("aceite", 5), ("pavo_fiambre", 50), ("leche", 200)],
  "Pan tostado con tomate rallado, aceite y lonchas de pavo. Un vaso de leche o café con leche.", 5)
P("d_revuelto_tofu", "Revuelto de tofu con espinacas y pan + naranja", D,
  [("tofu", 120), ("espinacas", 50), ("aceite", 5), ("pan", 60), ("naranja", 200)],
  "Desmiga el tofu y saltéalo con las espinacas y una pizca de cúrcuma y sal. Acompaña con pan tostado.", 10)
P("d_batido", "Batido de plátano, avena y cacao", D,
  [("leche", 300), ("platano", 120), ("avena", 40), ("cacao", 5)],
  "Tritura todo en la batidora hasta que quede fino. Ideal si tienes poco tiempo.", 3)

# ---------- Media mañana y merienda ----------
P("t_manzana_nueces", "Manzana y un puñado de nueces", T,
  [("manzana", 180), ("nueces", 20)], "Lista para llevar.", 1)
P("t_yogur_kiwi", "Yogur natural con kiwi y almendras", T,
  [("yogur", 125), ("kiwi", 75), ("almendras", 10)], "Trocea el kiwi sobre el yogur y añade las almendras.", 2)
P("t_bocadillo_pavo", "Bocadillo pequeño de pavo y tomate", T,
  [("pan", 50), ("pavo_fiambre", 40), ("tomate", 40)], "Pan con tomate en rodajas y lonchas de pavo.", 3)
P("t_tortitas_hummus", "Tortitas de arroz con hummus y zanahoria", T,
  [("tortitas_arroz", 20), ("hummus", 40), ("zanahoria", 80)], "Unta el hummus en las tortitas; la zanahoria en bastones.", 3)
P("t_skyr_frutos", "Yogur proteico con frutos rojos", T,
  [("skyr", 150), ("frutos_rojos", 80)], "Mezcla y listo.", 1)
P("t_platano_almendras", "Plátano y almendras", T,
  [("platano", 120), ("almendras", 15)], "Listo para llevar; buena opción antes de entrenar.", 1)
P("t_tostada_queso", "Tostada con tomate y queso fresco", T,
  [("pan", 40), ("tomate", 50), ("aceite", 5), ("queso_fresco", 40)], "Pan tostado con tomate, aceite y queso fresco.", 3)
P("t_huevos_naranja", "Dos huevos cocidos y una naranja", T,
  [("huevo", 120), ("naranja", 200)], "Cuece los huevos 10 minutos (puedes dejarlos hechos para varios días).", 10)
P("t_bocadillo_atun", "Bocadillo pequeño de atún y tomate", T,
  [("pan", 50), ("atun", 40), ("tomate", 30)], "Pan con atún escurrido y tomate.", 3)
P("t_queso_batido_fresas", "Queso batido con fresas y avena", T,
  [("queso_batido", 150), ("fresas", 100), ("avena", 20)], "Mezcla el queso batido con la avena y las fresas troceadas.", 3)
P("t_batido_cacahuete", "Batido de leche, plátano y crema de cacahuete", T,
  [("leche", 250), ("platano", 100), ("crema_cacahuete", 15)], "Tritura todo. Muy útil después de entrenar.", 3)
P("t_pera_queso", "Pera y queso curado", T,
  [("pera", 180), ("queso_curado", 25)], "La pera en gajos con unas lascas de queso.", 2)
P("t_hummus_crudites", "Hummus con palitos de pepino y zanahoria", T,
  [("hummus", 60), ("pepino", 100), ("zanahoria", 80)], "Corta las verduras en bastones para mojar en el hummus.", 5)
P("t_soja_cacao", "Bebida de soja con cacao y tortitas de arroz", T,
  [("bebida_soja", 250), ("cacao", 10), ("tortitas_arroz", 20)], "Disuelve el cacao en la bebida de soja (fría o caliente).", 2)

# ---------- Comidas ----------
P("c_lentejas", "Lentejas estofadas con verduras + naranja", C,
  [("lentejas", 70), ("patata", 80), ("zanahoria", 60), ("cebolla", 50), ("pimiento_verde", 40),
   ("tomate_triturado", 50), ("ajo", 5), ("aceite", 10), ("naranja", 200)],
  "Sofríe cebolla, ajo y pimiento, añade el tomate, las lentejas, la patata y la zanahoria troceadas, cubre de agua y cuece 35-40 minutos.", 45)
P("c_garbanzos_espinacas", "Garbanzos con espinacas y huevo + manzana", C,
  [("garbanzos", 200), ("espinacas", 100), ("huevo", 60), ("cebolla", 40), ("ajo", 5),
   ("tomate_triturado", 40), ("aceite", 10), ("manzana", 180)],
  "Sofríe cebolla y ajo, añade el tomate, las espinacas y los garbanzos escurridos. Sirve con un huevo cocido en cuartos.", 20)
P("c_paella_pollo", "Paella de pollo y verduras + ensalada", C,
  [("arroz", 80), ("pollo", 120), ("judias_verdes", 60), ("pimiento_rojo", 50), ("tomate_triturado", 40),
   ("ajo", 5), ("aceite", 10), ("lechuga", 50), ("kiwi", 75)],
  "Dora el pollo troceado, añade las verduras y el tomate, luego el arroz y el doble de agua o caldo. Cuece 18 minutos.", 40)
P("c_pasta_atun", "Pasta integral con atún y tomate + ensalada", C,
  [("pasta", 80), ("atun", 80), ("tomate_triturado", 120), ("cebolla", 40), ("aceite", 10),
   ("lechuga", 50), ("tomate", 80), ("pera", 180)],
  "Cuece la pasta. Mientras, sofríe la cebolla, añade el tomate y al final el atún. Mezcla con la pasta.", 20)
P("c_pollo_patatas", "Pollo al horno con patatas y ensalada + fruta", C,
  [("pollo", 150), ("patata", 200), ("lechuga", 60), ("tomate", 100), ("aceite", 15), ("naranja", 200)],
  "Hornea el pollo y la patata en rodajas a 200 °C unos 35 minutos con aceite, ajo y hierbas. Ensalada al lado.", 40)
P("c_salmon_boniato", "Salmón al horno con boniato y brócoli", C,
  [("salmon", 130), ("boniato", 180), ("brocoli", 150), ("aceite", 8), ("limon", 20), ("kiwi", 75)],
  "Hornea el boniato en dados 20 minutos a 200 °C, añade el salmón y el brócoli y hornea 12 minutos más. Limón por encima.", 35)
P("c_ensalada_quinoa", "Ensalada de quinoa con garbanzos y verduras", C,
  [("quinoa", 60), ("garbanzos", 120), ("tomate", 100), ("pepino", 80), ("pimiento_rojo", 50),
   ("aceitunas", 20), ("aceite", 10), ("limon", 20), ("manzana", 180)],
  "Cuece la quinoa 12 minutos y enfríala. Mezcla con los garbanzos y las verduras troceadas; aliña con aceite y limón.", 20)
P("c_alubias_verduras", "Alubias blancas estofadas con verduras + pera", C,
  [("alubias", 220), ("calabacin", 100), ("zanahoria", 60), ("cebolla", 50), ("tomate_triturado", 50),
   ("aceite", 10), ("pera", 180)],
  "Sofríe la cebolla, la zanahoria y el calabacín, añade el tomate y las alubias con un poco de agua y cuece 10 minutos.", 25)
P("c_arroz_tofu", "Arroz salteado con verduras y tofu + naranja", C,
  [("arroz", 75), ("tofu", 120), ("brocoli", 100), ("pimiento_rojo", 60), ("zanahoria", 60),
   ("ajo", 5), ("aceite", 10), ("naranja", 200)],
  "Cuece el arroz. Dora el tofu en dados, saltea las verduras con ajo y mezcla todo en la sartén.", 25)
P("c_ternera_arroz", "Ternera a la plancha con arroz y pimientos + fruta", C,
  [("ternera", 150), ("arroz", 70), ("pimiento_rojo", 100), ("pimiento_verde", 50), ("aceite", 10), ("fresas", 150)],
  "Cuece el arroz, asa los pimientos en tiras en la sartén y haz la ternera a la plancha.", 25)
P("c_merluza_verde", "Merluza en salsa verde con patatas y guisantes", C,
  [("merluza", 180), ("patata", 200), ("guisantes", 50), ("ajo", 5), ("aceite", 10), ("caldo", 100), ("manzana", 180)],
  "Cuece la patata en rodajas en el caldo, añade la merluza, el ajo picado con perejil y los guisantes. 8 minutos a fuego suave.", 30)
P("c_macarrones_verduras", "Macarrones integrales con verduras y queso", C,
  [("pasta", 80), ("calabacin", 100), ("berenjena", 80), ("tomate_triturado", 100), ("queso_curado", 20),
   ("aceite", 10), ("naranja", 200)],
  "Saltea el calabacín y la berenjena en dados, añade el tomate, mezcla con la pasta cocida y ralla el queso por encima.", 25)
P("c_cuscus_garbanzos", "Cuscús con verduras y garbanzos + kiwi", C,
  [("cuscus", 70), ("garbanzos", 120), ("calabacin", 80), ("zanahoria", 60), ("cebolla", 40), ("aceite", 10), ("kiwi", 75)],
  "Hidrata el cuscús con el mismo peso de agua caliente 5 minutos. Saltea las verduras y mezcla con los garbanzos.", 20)
P("c_lomo_patata", "Lomo de cerdo con patata y judías verdes + fruta", C,
  [("lomo_cerdo", 140), ("patata", 180), ("judias_verdes", 150), ("aceite", 10), ("pera", 180)],
  "Cuece la patata y las judías verdes juntas 15 minutos. Haz el lomo a la plancha y aliña la verdura con aceite.", 25)
P("c_pavo_arroz_integral", "Pavo salteado con verduras y arroz integral", C,
  [("pavo", 140), ("arroz_integral", 70), ("calabacin", 80), ("pimiento_rojo", 60), ("cebolla", 40),
   ("aceite", 10), ("manzana", 180)],
  "Cuece el arroz integral (unos 30 minutos). Saltea el pavo en tiras con las verduras y sirve junto al arroz.", 35)
P("c_sardinas_patata", "Ensalada de patata con sardinas + naranja", C,
  [("sardinas", 100), ("patata", 200), ("tomate", 100), ("cebolla", 30), ("aceite", 8), ("naranja", 200)],
  "Cuece la patata, déjala templar y mézclala con tomate, cebolla y las sardinas escurridas.", 25)
P("c_pasta_lentejas", "Pasta con boloñesa de lentejas + fruta", C,
  [("pasta", 70), ("lentejas", 40), ("tomate_triturado", 150), ("zanahoria", 50), ("cebolla", 40),
   ("aceite", 10), ("fresas", 150)],
  "Cuece las lentejas 20 minutos (o usa de bote). Sofríe cebolla y zanahoria picadas, añade tomate y lentejas y mezcla con la pasta.", 30)

# ---------- Cenas ----------
P("n_tortilla_calabacin", "Tortilla de calabacín con ensalada", N,
  [("huevo", 120), ("calabacin", 150), ("cebolla", 40), ("aceite", 10), ("lechuga", 60), ("tomate", 100), ("pan", 30)],
  "Pocha el calabacín y la cebolla, mézclalos con los huevos batidos y cuaja la tortilla. Ensalada al lado.", 20)
P("n_merluza_verduras", "Merluza a la plancha con verduras asadas", N,
  [("merluza", 170), ("calabacin", 100), ("berenjena", 100), ("pimiento_rojo", 60), ("aceite", 10), ("pan", 30)],
  "Asa las verduras en el horno o la sartén y haz la merluza a la plancha con ajo y perejil.", 25)
P("n_crema_calabaza", "Crema de calabaza con huevo cocido", N,
  [("calabaza", 250), ("patata", 60), ("cebolla", 50), ("aceite", 10), ("huevo", 60), ("pan", 30)],
  "Cuece calabaza, patata y cebolla 20 minutos, tritura con el aceite. Sirve con huevo cocido picado por encima.", 30)
P("n_ensalada_campera", "Ensalada campera (patata, atún y huevo)", N,
  [("patata", 150), ("atun", 60), ("huevo", 60), ("tomate", 100), ("pimiento_verde", 40), ("cebolla", 20),
   ("aceitunas", 15), ("aceite", 10)],
  "Cuece patata y huevo, deja templar y mezcla con el resto troceado. Aliña con aceite y vinagre.", 25)
P("n_pavo_ensalada", "Pavo a la plancha con ensalada y maíz", N,
  [("pavo", 140), ("lechuga", 80), ("tomate", 100), ("maiz", 40), ("aceite", 10), ("pan", 40)],
  "Filetes de pavo a la plancha y ensalada de lechuga, tomate y maíz.", 15)
P("n_dorada_horno", "Dorada al horno con patata y cebolla", N,
  [("dorada", 180), ("patata", 150), ("cebolla", 60), ("aceite", 10), ("limon", 20)],
  "Hornea patata y cebolla en rodajas 20 minutos a 200 °C, pon el pescado encima y hornea 15 minutos más.", 40)
P("n_revuelto_gambas", "Revuelto de champiñones y gambas", N,
  [("huevo", 120), ("champinones", 120), ("gambas", 80), ("ajo", 5), ("aceite", 8), ("pan", 30)],
  "Saltea el ajo, los champiñones y las gambas; añade los huevos batidos y remueve hasta que cuajen.", 15)
P("n_wrap_pollo", "Wrap de pollo con verduras y queso fresco", N,
  [("wrap", 60), ("pollo", 100), ("lechuga", 40), ("tomate", 60), ("aguacate", 40), ("queso_fresco", 30)],
  "Haz el pollo en tiras a la plancha y rellena la tortilla con todo. Enrolla y listo.", 15)
P("n_tofu_quinoa", "Tofu a la plancha con verduras salteadas y quinoa", N,
  [("tofu", 150), ("quinoa", 40), ("brocoli", 100), ("champinones", 80), ("ajo", 5), ("aceite", 10)],
  "Cuece la quinoa, dora el tofu en lonchas y saltea el brócoli y los champiñones con ajo.", 25)
P("n_gazpacho_tostada", "Gazpacho con tostada de queso fresco", N,
  [("tomate", 250), ("pepino", 60), ("pimiento_verde", 40), ("ajo", 3), ("aceite", 15), ("pan", 50), ("queso_fresco", 60)],
  "Tritura tomate, pepino, pimiento, ajo, aceite, sal y un chorrito de vinagre; enfría. Tostada con queso fresco al lado.", 10)
P("n_berenjena_rellena", "Berenjena rellena de lentejas y queso", N,
  [("berenjena", 300), ("lentejas", 40), ("tomate_triturado", 80), ("cebolla", 40), ("queso_curado", 20), ("aceite", 10)],
  "Asa la berenjena partida 25 minutos, vacíala y mezcla la pulpa con sofrito, tomate y lentejas cocidas. Rellena, pon el queso y gratina.", 45)
P("n_brocoli_huevo", "Brócoli con patata y huevo pochado", N,
  [("brocoli", 200), ("patata", 150), ("huevo", 60), ("ajo", 5), ("aceite", 10)],
  "Cuece brócoli y patata 12 minutos, saltéalos con ajo y aceite y sirve con un huevo pochado encima.", 20)
P("n_ensalada_lentejas", "Ensalada de lentejas con verduras", N,
  [("lentejas", 50), ("tomate", 100), ("pimiento_rojo", 50), ("cebolla", 30), ("pepino", 80), ("aceite", 10)],
  "Cuece las lentejas 20 minutos (o usa de bote) y mézclalas frías con las verduras picadas. Aliña con aceite y vinagre.", 25)
P("n_bacalao_tomate", "Bacalao con tomate y pimientos", N,
  [("bacalao", 170), ("tomate_triturado", 150), ("pimiento_rojo", 80), ("cebolla", 50), ("aceite", 10), ("pan", 30)],
  "Haz un sofrito con cebolla y pimiento, añade el tomate y cuece el bacalao encima 8 minutos.", 25)
P("n_ensalada_garbanzos", "Ensalada de garbanzos con aguacate y tomate", N,
  [("garbanzos", 150), ("aguacate", 50), ("tomate", 100), ("cebolla", 20), ("pepino", 60), ("aceite", 8), ("limon", 10)],
  "Mezcla los garbanzos escurridos con las verduras y el aguacate en dados. Aliña con aceite, limón y comino.", 10)
P("n_sandwich_pavo", "Sándwich integral de pavo, queso y tomate", N,
  [("pan", 80), ("pavo_fiambre", 60), ("queso_fresco", 40), ("tomate", 60), ("lechuga", 20)],
  "Monta el sándwich y, si quieres, pásalo por la sartén o la sandwichera.", 5)
P("n_salmon_ensalada", "Salmón a la plancha con ensalada de rúcula", N,
  [("salmon", 120), ("rucula", 60), ("tomate", 100), ("aceite", 5), ("pan", 30)],
  "Haz el salmón a la plancha por los dos lados y sírvelo con la ensalada.", 15)

OBJETIVOS = [
    {"id": "ganar_musculo", "nombre": "Ganar músculo", "icono": "figure.strengthtraining.traditional",
     "descripcion": "Ligero superávit de calorías y proteína alta para construir músculo con poca grasa.",
     "ajusteCalorias": 0.10, "proteinaPorKg": 1.8, "grasaPorcentaje": 0.27, "preferencia": "proteina",
     "consejos": ["Reparte la proteína en las 5 comidas.", "Come algo con hidratos y proteína 1-2 horas antes y después de entrenar.",
                  "Si en 3-4 semanas no sube nada el peso, añade unas 150 kcal al día."]},
    {"id": "perder_grasa", "nombre": "Adelgazar", "icono": "flame.fill",
     "descripcion": "Déficit moderado de calorías manteniendo la proteína alta para no perder músculo.",
     "ajusteCalorias": -0.20, "proteinaPorKg": 2.0, "grasaPorcentaje": 0.28, "preferencia": "proteina",
     "consejos": ["Un ritmo sano es perder entre el 0,5 y el 1 % del peso a la semana.", "Llena medio plato de verdura en comida y cena.",
                  "Bebe agua y evita bebidas azucaradas y alcohol."]},
    {"id": "mantener", "nombre": "Mantenerme", "icono": "equal.circle.fill",
     "descripcion": "Las calorías que gastas, con una dieta mediterránea variada y equilibrada.",
     "ajusteCalorias": 0.0, "proteinaPorKg": 1.6, "grasaPorcentaje": 0.30, "preferencia": "equilibrado",
     "consejos": ["Legumbres 3-4 veces por semana y pescado otras 3-4.", "Fruta y verdura todos los días.",
                  "Usa aceite de oliva virgen extra como grasa principal."]},
    {"id": "definicion", "nombre": "Definición", "icono": "scissors",
     "descripcion": "Déficit suave con proteína muy alta para marcar músculo sin perder fuerza.",
     "ajusteCalorias": -0.12, "proteinaPorKg": 2.2, "grasaPorcentaje": 0.25, "preferencia": "proteina",
     "consejos": ["Mantén el entrenamiento de fuerza: es lo que conserva el músculo.", "Los días de descanso, menos pan y arroz y más verdura.",
                  "Pésate 2-3 veces por semana a la misma hora y mira la media."]},
    {"id": "fuerza", "nombre": "Ganar fuerza", "icono": "dumbbell.fill",
     "descripcion": "Calorías un poco por encima de lo que gastas y suficientes hidratos para rendir en series pesadas.",
     "ajusteCalorias": 0.05, "proteinaPorKg": 1.8, "grasaPorcentaje": 0.28, "preferencia": "equilibrado",
     "consejos": ["No entrenes en ayunas: toma hidratos 1-3 horas antes.", "Duerme 7-9 horas: la fuerza también se gana descansando.",
                  "Después de entrenar, proteína e hidratos en la siguiente comida."]},
    {"id": "resistencia", "nombre": "Resistencia", "icono": "figure.run",
     "descripcion": "Para deportes de fondo (correr, ciclismo, natación): más hidratos para tener energía en sesiones largas.",
     "ajusteCalorias": 0.05, "proteinaPorKg": 1.5, "grasaPorcentaje": 0.25, "preferencia": "hidratos",
     "consejos": ["Los días de sesión larga aumenta pasta, arroz, patata o pan.", "En salidas de más de 75-90 minutos, toma hidratos durante el ejercicio.",
                  "Hidrátate bien antes, durante y después."]},
]

ACTIVIDAD = [
    {"id": "sedentaria", "nombre": "Sedentaria", "descripcion": "Trabajo sentado, poco movimiento", "factor": 1.2},
    {"id": "ligera", "nombre": "Ligera", "descripcion": "Caminas a ratos o trabajas de pie", "factor": 1.3},
    {"id": "activa", "nombre": "Activa", "descripcion": "Trabajo físico o muchos pasos al día", "factor": 1.45},
    {"id": "muy_activa", "nombre": "Muy activa", "descripcion": "Trabajo físico duro todo el día", "factor": 1.6},
]

COMIDAS = [
    {"id": "desayuno", "nombre": "Desayuno", "icono": "sun.horizon.fill", "porcentaje": 0.22},
    {"id": "media_manana", "nombre": "Media mañana", "icono": "cup.and.saucer.fill", "porcentaje": 0.10},
    {"id": "comida", "nombre": "Comida", "icono": "fork.knife", "porcentaje": 0.33},
    {"id": "merienda", "nombre": "Merienda", "icono": "carrot.fill", "porcentaje": 0.12},
    {"id": "cena", "nombre": "Cena", "icono": "moon.stars.fill", "porcentaje": 0.23},
]

DATOS = {
    "version": 1,
    "aviso": ("Estos menús y cifras son orientativos y se calculan con fórmulas generales. No sustituyen el consejo de un "
              "dietista-nutricionista ni de un médico. Si tienes alguna enfermedad, alergia, estás embarazada o en lactancia, "
              "eres menor de 18 años o tienes o has tenido problemas con la comida, consulta antes con un profesional."),
    "calculo": {
        "formula": "Mifflin-St Jeor",
        "factorPorDiaEntreno": 0.04,
        "variacionDiaEntreno": 0.10,
        "minimoKcalMujer": 1300,
        "minimoKcalHombre": 1600,
        "escalaMinima": 0.5,
        "escalaMaxima": 2.5
    },
    "objetivos": OBJETIVOS,
    "actividad": ACTIVIDAD,
    "comidas": COMIDAS,
    "ingredientes": ING,
    "platos": PLATOS,
}

# ---------- Comprobaciones ----------
def ingr(id, sg, sl):
    i = IDS[id]
    if sg and i["gluten"]:
        if "sinGluten" not in i: return None
        i = IDS[i["sinGluten"]]
    if sl and i["lactosa"]:
        if "sinLactosa" not in i: return None
        i = IDS[i["sinLactosa"]]
    return i

def apto(p, veg, sg, sl):
    for x in p["ingredientes"]:
        i = ingr(x["id"], sg, sl)
        if i is None: return False
        if veg and not i["vegetariano"]: return False
    return True

def macros(p):
    k = pr = 0
    for x in p["ingredientes"]:
        i = IDS[x["id"]]; k += i["kcal"] * x["cantidad"] / 100; pr += i["proteinas"] * x["cantidad"] / 100
    return round(k), round(pr, 1)

for a in IDS.values():
    for key in ("sinGluten", "sinLactosa"):
        if key in a: assert a[key] in IDS
if "--info" in sys.argv:
    for p in PLATOS:
        print(p["comidas"][0][:6], macros(p), p["nombre"])
    for c in ["desayuno", "media_manana", "comida", "merienda", "cena"]:
        fila = []
        for veg in (0, 1):
            for sg in (0, 1):
                for sl in (0, 1):
                    n = sum(1 for p in PLATOS if c in p["comidas"] and apto(p, veg, sg, sl))
                    fila.append(n)
        print(c, fila)
ids = [p["id"] for p in PLATOS]; assert len(ids) == len(set(ids))

with open(sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("--") else "menus.json", "w", encoding="utf-8") as f:
    json.dump(DATOS, f, ensure_ascii=False, indent=1)
