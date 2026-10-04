"""Document current source audit and the existing native evidence honestly."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent
sources=json.loads((OUT/'source-audit56.json').read_text())
reviews=json.loads((ROOT/'assets/review/animations-polished/visual-reviewed.json').read_text())
byid={r['id']:r for r in sources}
notes={
'cursed_doll':'Rostro, pelo, vestido ciruela y extremidades se separan; conservar.',
'watching_eye':'Iris vertical, párpados, brazos y dedos legibles sobre marco violeta; conservar.',
'soul_chains':'Eslabones grises, grilletes anaranjados y alma clara tienen separación suficiente; conservar.',
'plague_monarch':'Placas verdes/ocres, máscara blanca y cuatro extremidades distinguen su anatomía; conservar.',
'the_void':'Vacío negro intencional, contorno claro y fragmentos separados; conservar el negro focal.',
'haunted_mirror':'Marco dorado, espejo azul y fantasma blanco con silueta clara; conservar.',
'crying_mask':'Porcelana clara, ojo negro y lágrimas azules se distinguen; conservar.',
'candle_wisp':'Cera marfil, ojos negros, manos y llama azul muestran profundidad; conservar.',
'grave_hopper':'Piedra/cabeza/patas se mezclan; borde de lápida y expresión débiles. Remodelar bordes, ojos, inscripción, musgo y separación de color.',
'grave_key':'Hueco del aro, hierro gris y bufanda azul reconocibles; conservar la rotura del aro.',
'mourning_ribbon':'Bucles y colas volumétricos; costuras claras sobre paño ciruela legibles; conservar.',
'wilted_sprout':'Tallo verde, pétalos ocres y rostro negro distinguen la planta; conservar.',
'ink_imp':'Contraste entre tinta negra, ojos claros y sobre crema; conservar el negro de tinta.',
'lost_locket':'Dos tapas de bronce y mano fantasmal separadas con volumen; conservar.',
'ashen_book':'Páginas crema, cubierta negra y página alzada tienen silueta clara; conservar.',
'lantern_lurker':'Jaula oscura permite leer el cautivo verde; patas tienen contorno propio; conservar.',
'hourglass_hound':'Marco arena abierto, conos y patas/hocico contrastados; conservar.',
'nail_beetle':'Hierro uniforme oculta placas y clavo; cara y rodillas poco separadas. Remodelar placas, labio del clavo, pupilas/mandíbulas y collars de seis patas.',
'pale_guest':'Madera/latón, lienzo roto y fantasma marfil separados; conservar.',
'cold_teacup':'Porcelana, pintura azul y vapor gris muestran su concepto; conservar.',
'coin_crawler':'Cuerpo/ribete/relieve uniformes: parece cuenco sin monedas. Remodelar cantos acuñados, tres monedas reconocibles, cara y articulaciones.',
'umbrella_wraith':'Pliegues azules, ojo marfil y detalles dorados claramente separados; conservar.',
'marrow_dice':'Dados marfil y puntos negros legibles. Marcha de pies pendiente expresamente fuera de esta tarea.',
'veil_mourner':'Paño azul con pliegues, vacío negro y peineta marfil contrastados; conservar.',
'grave_compass':'Brújula y tapa distinguen bronce, verde y dial oscuro; conservar.',
'hollow_violin':'Madera cálida, cuerdas azules y hueco central mantienen identidad; conservar.',
'chime_triplets':'Campanas con distintos tonos y borde dorado legibles; conservar.',
'thimble_spider':'Dedal perforado ocre, cabeza negra, ojos de botón y ocho patas distinguibles; conservar.',
'music_box_dancer':'Caja madera/latón y bailarina legibles; actuación recién corregida conservada. Marcha de la caja pendiente fuera de alcance.',
'raven_quill':'Pluma negra intencional con barbas claras, pico/patas ocres y ojo; conservar.',
'sorrow_chalice':'Copa azul/dorada y espíritu marfil legibles; conservar.',
'pale_gramophone':'Corneta marfil, caja madera/latón y disco oscuro legibles; conservar.',
'thorn_reliquary':'Barras doradas y espina verde con huecos visibles; conservar actuación corregida posterior a la galería.',
'anchor_crab':'Ancla jade, pinzas con caras cálidas y cabeza negra legibles; conservar.',
'sundial_sentinel':'Dial marfil, aguja ocre y sombra negra separados; conservar.',
'sleepwalker_shoes':'Botas azul/marrón con bordes claros y cordones; conservar.',
'night_harp':'Arco azul, cuerdas doradas, cabeza marfil y patas separadas; conservar.',
'thorn_cathedral':'Arquitectura gris clara, ventanal rojo, espinas y pies legibles; conservar.',
'phantom_marionette':'Cuerpo marfil, juntas ocres, hilos finos y cruz negra distinguen el títere; conservar.',
'blood_moon_rose':'Pétalos rojos facetados y tallo verde diferenciados, centro oscuro intencional; conservar.',
'judgement_scales':'Mitades de metal/marfil, platos y cadenas distinguibles; conservar.',
'clockwork_raven':'Ruedas doradas, cara clara, plumas azules y cuerpo negro distinguen mecanismos; conservar.',
'eclipse_stag':'Cuernos blancos, torso gris y rasgos jade legibles; conservar.',
'endless_library':'Cubiertas distintas y adornos claros separan tres volúmenes/libros; conservar.',
'sunken_crown':'Corona marfil, joya azul y tentáculos saturados legibles; conservar.',
'silent_choir':'Cantantes negro/marfil/azul con bordes dorados diferenciados; conservar.',
'cathedral_heart':'Arco gótico gris y corazón marfil con fisuras doradas se distinguen; conservar.',
'hollow_throne':'Trono vacío mantiene hueco y contorno claro; negro interior intencional; conservar.',
'worldroot':'Madera cálida, musgo verde agrupado y semilla jade separan el árbol; conservar.',
'the_undertow':'Campana jade/bronce y apéndices azules legibles; conservar.',
'the_last_funeral':'Ataúd ciruela, flores marfil, piernas y pies contrastados; conservar.',
'nameless_door':'Marco/tarima claros, puerta jade/dorada y hueco profundo legibles; conservar.',
'crown_of_silence':'Corona flotante dorada y túnica marfil con volumen claro; conservar.',
'the_first_grave':'Piedra blanca angular, brazos pardos y musgo seleccionado legibles; conservar.',
'the_unwritten':'Paño oscuro con pliegues claros, cabeza marfil y grafismos se distinguen; conservar.',
'the_last_star':'Armadura gris, marco abierto y estrella blanca tienen separación suficiente; conservar.',
}
assert set(notes)==set(byid)
rows=[]
for r in reviews:
    ident=r['id'];s=byid[ident]
    rows.append({'id':ident,'classification':'GEOMETRY_AND_MATERIAL_REMODEL'if ident in {'grave_hopper','nail_beetle','coin_crawler'}else'KEEP',
        'reason':notes[ident],'source':s['source'],'sourceSHA256':s['sourceSHA256'],'nativeMeshIdAtAudit':s['nativeMeshId'],
        'trianglesBefore':s['triangles'],'bonesBefore':len(s['bones']),'existingNativeEvidence':f'assets/review/animations-polished/videos/native-batch{r["batch"]:02d}.mp4',
        'newIntegratedPlayReview':False})
(OUT/'audit-classification56.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2))
text='''# Auditoría visual de Curses — restauración del santuario

Auditoría de **56 fuentes reales**, sus rigs y las capturas nativas existentes de `animations-polished`. Se inspeccionaron los píxeles de las 28 galerías conservadas, con sus primeros planos recortados para lectura, y la anatomía/color/UV de las fuentes Blender actuales. Los recortes no representan una nueva cámara ni una nueva sesión de Play. El registro de actuación previo sigue siendo histórico. La aprobación de la integración nueva corresponde a los registros de esta actualización.

## Clasificación y diagnóstico

- **53 conservar**: silueta, separación focal y colores permiten reconocer su concepto en la evidencia nativa existente.
- **3 remodelar geometría y separación de materiales**: Grave Hopper, Nail Beetle y Coin Crawler. Coinciden con los ejemplos del usuario y no se corrigen solo aumentando resolución.
- **0 correcciones exclusivas de material**: en esta inspección no se identificó otro caso equivalente que requiriese reimportación independiente.

Las tres fuentes usan `SACPaintedColor`, un material pintado compartido y una UV auxiliar `CurseMaterialUV`. Todas sus caras están en sombreado plano. El shader real no usa nodos de textura de imagen; la UV heredada sirve a la paleta del autor. El aspecto suave de las capturas nace de grandes volúmenes redondeados poco separados y pintura de bajo contraste (Grave Hopper tenía 410 variantes de color), reforzado por la luz nocturna. No se atribuye a mipmaps ni se declara observado un fallo de LOD.

Las remodelaciones usan una sola familia de material/colores de vértices por malla, con acabados visualmente distintos mediante siluetas, relieves y paletas. No se afirma que un único MeshPart contenga varios materiales PBR físicamente distintos. No se añaden imágenes de máxima resolución ni se disimula la forma con VFX.

## Producción de los tres prioritarios

| Curse | Corrección concreta | Tris antes → después | Tamaño W/H/D, studs |
|---|---|---:|---|
'''
for ident in ['grave_hopper','nail_beetle','coin_crawler']:
    p=json.loads((OUT/f'{ident}-source-production.json').read_text())
    correction={'grave_hopper':'Lápida con borde cortado, cruz elevada e inscripción RIP real; ojos de piedra, mandíbula definida, musgo agrupado y juntas visibles.',
        'nail_beetle':'Placas a ambos lados del clavo, caras de acero, labio forjado y marca cuadrada; pupilas, mandíbulas y las seis rodillas separadas.',
        'coin_crawler':'Bronce acuñado con cantos fresados, tres monedas reales con sello y patina verde; cuerpo grafito, ojos/mandíbula y cuatro rodillas anatómicas.'}[ident]
    dims=', '.join(f'{v:.3f}'for v in p['targetSize'])
    text+=f'| {ident.replace("_"," ").title()} | {correction} | {p["before"]["triangles"]} → {p["after"]["triangles"]} | {dims} |\n'
text+='''
Se conservan los 56 nombres lógicos, precios y rarezas. Music Box Dancer y Marrow Dice conservan sus comportamientos: sus marchas pendientes son una tarea posterior indicada por el usuario. No se modifica Thorn Reliquary.

### Rigs y compatibilidad VFX

Grave Hopper conserva las matrices, nombres, jerarquía y pesos existentes. Solo la cruz se eleva 0,20 studs en la fuente; los nuevos ojos, bordes y letras siguen `Shell`. Nail Beetle conserva sus 14 rest bones y los pesos anteriores; las dos lentes se retrasan 0,055 studs para alojar pupilas y los detalles siguen `Root`, `Nail` o sus articulaciones originales. Se conservan sus seis patas y sus seis rodillas reparadas.

Coin Crawler conservaba rodillas antiguas por debajo y hacia dentro del codo real. La reparación puntual mueve solo `Knee0`–`Knee3` y redistribuye proximal/distal los pesos de sus cuatro tubos/pies. Se conservan posiciones de hips y contactos, geometría de reposo, nombres y jerarquía. El solver compartido lee las nuevas matrices de reposo; la integración debe verificar las cuatro patas en Play. La tabla siguiente usa **coordenadas de fuente Blender**, no coordenadas observadas de Studio.

| Bone Coin Crawler | Rest head anterior (Blender) | Rest head nuevo (Blender) |
|---|---|---|
'''
coin=json.loads((OUT/'coin_crawler-source-production.json').read_text())['coinAnatomicalRepair']
for b,a in zip(coin['bonesBefore'],coin['bonesAfter']):
    if b['name']in coin['changedBoneNames']:
        text+=f'| {b["name"]} | '+', '.join(f'{v:.3f}'for v in b['head'])+' | '+', '.join(f'{v:.3f}'for v in a['head'])+' |\n'
text+=f'''
Se reasignaron **{coin['changedWeightCount']} vértices anteriores** de los tubos/pies de Coin Crawler; el registro conserva antes/después de cada peso y las matrices completas. Su amigo debe conservar nombres de anclajes y revisar offsets de efectos sujetos a estas cuatro rodillas; un offset antiguo sobre `Knee` puede quedar desplazado. Efectos sujetos a los hips, `Root`, `Gaze` o `CoinLid` conservan su referencia. Ningún módulo VFX se reescribe en esta producción.

### Archivos y reconstrucción

- Fuentes nuevas: `assets/source/blender/sanctuary-restoration/{{grave_hopper,nail_beetle,coin_crawler}}.blend`.
- FBX individuales con rigs reales: `assets/export/meshes/curses/sanctuary-restoration/{{grave_hopper,nail_beetle,coin_crawler}}.fbx`.
- Lote de importación único: `assets/export/meshes/curses/sanctuary-restoration/sanctuary-curse-remodel-03.fbx`, con 3 mallas y 35 huesos `id__Nombre`.
- Reconstrucción: Blender 5.2.2, `tools/Remodel-RestorationCurses.py -- --produce`; validación `-- --verify`; auditoría de fuentes `-- --inspect`.
- Hashes reales, colores, recuentos, matrices y modificaciones: `assets/review/sanctuary-restoration/visuals/source-production-batch.json` y los tres `*-source-production.json`.
- Validación real de exportación y aislamiento por hueso: `rig-deformation-checks.json`.

Los renders `*-blender-before.png`, `*-blender-after.png` y `*-blender-articulation.png` son diagnósticos de producción. **No sustituyen Play ni se cuentan como aprobaciones en Roblox.** Esta producción no inventa IDs: `newMeshId` permanece vacío hasta la importación del coordinador. Los registros de integración y capturas nativas finales deben citarse desde el informe principal.

## Las 56 Curses

La siguiente tabla clasifica el acabado de la versión de partida, no declara 56 aprobaciones nuevas. Los vídeos enlazados se capturaron durante la entrega animada anterior y siguen siendo evidencia de los diseños conservados. Para Music Box y Thorn se conserva además la corrección posterior en `animations-polished/user-two-curses`.

| Curse | Clasificación | Evidencia e inspección | Tris / huesos de partida |
|---|---|---|---:|
'''
for r in rows:
    cat='Remodelar geometría/material'if r['classification']!='KEEP'else'Conservar'
    url=f'C:/RobloxProjects/StealACurse/{r["existingNativeEvidence"]}'
    text+=f'| {r["id"].replace("_"," ").title()} | {cat} | {r["reason"]} [Vídeo previo]({url}) | {r["trianglesBefore"]} / {r["bonesBefore"]} |\n'
text+='''
## Alcance verificado y pendiente

Comprobado en Blender: 56 fuentes existentes, datos de color/UV, normales planas, jerarquías y grupos; los 3 FBX reales se vuelven a importar, conservan nombres, huesos, colores, UV y triángulos; pesos normalizados y deformación aislada de 35 huesos sin mover vértices ajenos. Los renders diagnósticos muestran macrogeometría y separación de colores.

La producción por sí sola deja pendiente importación nativa y apariencia/animaciones de los 3 remodellados en reposo, procesión y transporte dentro de la integración final. No se declara probado un teléfono ni se atribuyen FPS a una prueba de Blender. El informe principal debe actualizar este estado usando los registros reales del coordinador.
'''
(ROOT/'docs/SANCTUARY_CURSE_VISUAL_AUDIT.md').write_text(text,encoding='utf-8')
print('VISUAL_AUDIT_REPORT',len(rows))
