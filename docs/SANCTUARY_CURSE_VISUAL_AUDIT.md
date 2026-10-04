# Auditoría visual de Curses — restauración del santuario

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
| Grave Hopper | Lápida con borde cortado, cruz elevada e inscripción RIP real; ojos de piedra, mandíbula definida, musgo agrupado y juntas visibles. | 2400 → 4708 | 4.074, 4.200, 2.720 |
| Nail Beetle | Placas a ambos lados del clavo, caras de acero, labio forjado y marca cuadrada; pupilas, mandíbulas y las seis rodillas separadas. | 1594 → 2526 | 5.600, 3.200, 5.400 |
| Coin Crawler | Bronce acuñado con cantos fresados, tres monedas reales con sello y patina verde; cuerpo grafito, ojos/mandíbula y cuatro rodillas anatómicas. | 2172 → 4080 | 5.800, 3.200, 4.100 |

Se conservan los 56 nombres lógicos, precios y rarezas. Music Box Dancer y Marrow Dice conservan sus comportamientos: sus marchas pendientes son una tarea posterior indicada por el usuario. No se modifica Thorn Reliquary.

### Rigs y compatibilidad VFX

Grave Hopper conserva las matrices, nombres, jerarquía y pesos existentes. Solo la cruz se eleva 0,20 studs en la fuente; los nuevos ojos, bordes y letras siguen `Shell`. Nail Beetle conserva sus 14 rest bones y los pesos anteriores; las dos lentes se retrasan 0,055 studs para alojar pupilas y los detalles siguen `Root`, `Nail` o sus articulaciones originales. Se conservan sus seis patas y sus seis rodillas reparadas.

Coin Crawler conservaba rodillas antiguas por debajo y hacia dentro del codo real. La reparación puntual mueve solo `Knee0`–`Knee3` y redistribuye proximal/distal los pesos de sus cuatro tubos/pies. Se conservan posiciones de hips y contactos, geometría de reposo, nombres y jerarquía. El solver compartido lee las nuevas matrices de reposo. La importación nativa conserva las cuatro cadenas y el coordinador revisó su actuación en procesión, transporte y pedestal; las poses muestreadas no certifican contacto perfecto en cada cuadro. La tabla siguiente usa **coordenadas de fuente Blender**, no coordenadas observadas de Studio.

| Bone Coin Crawler | Rest head anterior (Blender) | Rest head nuevo (Blender) |
|---|---|---|
| Knee0 | -1.519, -0.710, -0.655 | -2.073, -0.674, 0.123 |
| Knee1 | -1.519, 0.597, -0.655 | -2.073, 0.567, 0.123 |
| Knee2 | 1.519, -0.710, -0.655 | 2.073, -0.674, 0.123 |
| Knee3 | 1.519, 0.597, -0.655 | 2.073, 0.567, 0.123 |

Se reasignaron **201 vértices anteriores** de los tubos/pies de Coin Crawler; el registro conserva antes/después de cada peso y las matrices completas. Su amigo debe conservar nombres de anclajes y revisar offsets de efectos sujetos a estas cuatro rodillas; un offset antiguo sobre `Knee` puede quedar desplazado. Efectos sujetos a los hips, `Root`, `Gaze` o `CoinLid` conservan su referencia. Ningún módulo VFX se reescribe en esta producción.

### Archivos y reconstrucción

- Fuentes nuevas: `assets/source/blender/sanctuary-restoration/{grave_hopper,nail_beetle,coin_crawler}.blend`.
- FBX individuales con rigs reales: `assets/export/meshes/curses/sanctuary-restoration/{grave_hopper,nail_beetle,coin_crawler}.fbx`.
- Lote de importación único: `assets/export/meshes/curses/sanctuary-restoration/sanctuary-curse-remodel-03.fbx`, con 3 mallas y 35 huesos `id__Nombre`.
- Reconstrucción: Blender 5.2.2, `tools/Remodel-RestorationCurses.py -- --produce`; validación `-- --verify`; auditoría de fuentes `-- --inspect`.
- Hashes reales, colores, recuentos, matrices y modificaciones: `assets/review/sanctuary-restoration/visuals/source-production-batch.json` y los tres `*-source-production.json`.
- Validación real de exportación y aislamiento por hueso: `rig-deformation-checks.json`.

Los renders `*-blender-before.png`, `*-blender-after.png` y `*-blender-articulation.png` son diagnósticos de producción. **No sustituyen Play ni se cuentan como aprobaciones en Roblox.** El manifiesto de producción conserva su estado anterior a la importación, con `newMeshId` vacío. Los IDs siguientes fueron importados e integrados realmente por el coordinador; su tamaño y jerarquía se observaron en [el registro nativo](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/native-remodel-observed.json).

### Integración y revisión nativa final

| Curse | MeshId real | Tamaño observado W/H/D, studs | Fuente editable / FBX individual |
|---|---|---|---|
| Grave Hopper | `rbxassetid://130614622379245` | 4.074 / 4.200 / 2.720 | [Blender](C:/RobloxProjects/StealACurse/assets/source/blender/sanctuary-restoration/grave_hopper.blend) / [FBX](C:/RobloxProjects/StealACurse/assets/export/meshes/curses/sanctuary-restoration/grave_hopper.fbx) |
| Nail Beetle | `rbxassetid://73295688458517` | 5.600 / 3.200 / 5.400 | [Blender](C:/RobloxProjects/StealACurse/assets/source/blender/sanctuary-restoration/nail_beetle.blend) / [FBX](C:/RobloxProjects/StealACurse/assets/export/meshes/curses/sanctuary-restoration/nail_beetle.fbx) |
| Coin Crawler | `rbxassetid://74159266876686` | 5.800 / 3.200 / 4.100 | [Blender](C:/RobloxProjects/StealACurse/assets/source/blender/sanctuary-restoration/coin_crawler.blend) / [FBX](C:/RobloxProjects/StealACurse/assets/export/meshes/curses/sanctuary-restoration/coin_crawler.fbx) |

Las tres importaciones proceden del [lote FBX real](C:/RobloxProjects/StealACurse/assets/export/meshes/curses/sanctuary-restoration/sanctuary-curse-remodel-03.fbx), con SHA256 compartido `c7676a0f18761925b5d7753c8519e5e933b2f1ca2169898d064674baff7e0567`. Se mantienen los tamaños aprobados. Los IDs se registran también en `assets/imports/curse-animation-current.json` y `src/shared/CurseAnimationAssets.luau`.

El coordinador inspeccionó **los tres modelos integrados** a distancia de juego en procesión, transporte y reposo en un pedestal normal. Grave Hopper muestra el borde cortado, RIP y expresión; Nail Beetle separa sus seis patas, cabeza y clavo móvil; Coin Crawler distingue bronce, monedas claras, rostro oscuro y patas. Las grabaciones de 30 segundos incluyen compra real, transporte, colocación, reposo y venta, además de la procesión.

| Curse | Comparación nativa | Grabación de Play |
|---|---|---|
| Grave Hopper | [Antes del usuario](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/grave-hopper-before-user.png) / [Después, pedestal](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/grave-hopper-native-pedestal.png) | [Vídeo](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/videos/grave-hopper-native.mp4) |
| Nail Beetle | [Antes del usuario](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/nail-beetle-before-user.png) / [Después, pedestal](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/nail-beetle-native-pedestal.png) | [Vídeo](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/videos/nail-beetle-native.mp4) |
| Coin Crawler | [Antes del usuario](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/coin-crawler-before-user.png) / [Después, pedestal](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/coin-crawler-native-pedestal.png) | [Vídeo](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/videos/coin-crawler-native.mp4) |

Las comparaciones usan capturas reales, pero no son una cámara idéntica antes/después. [La revisión visual](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/native-visual-review.json) contiene el alcance y los hashes de los vídeos; [los fotogramas próximos](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/videos/native-gait-detail.png) permiten consultar poses. Esta revisión nueva cubre tres Curses: las otras **53 conservan la auditoría y evidencia anteriores**.

## Las 56 Curses

La siguiente tabla clasifica el acabado de la versión de partida, no declara 56 aprobaciones nuevas. Los vídeos enlazados se capturaron durante la entrega animada anterior y siguen siendo evidencia de los diseños conservados. Para Music Box y Thorn se conserva además la corrección posterior en `animations-polished/user-two-curses`.

| Curse | Clasificación | Evidencia e inspección | Tris / huesos de partida |
|---|---|---|---:|
| Cursed Doll | Conservar | Rostro, pelo, vestido ciruela y extremidades se separan; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch01.mp4) | 2646 / 11 |
| Watching Eye | Conservar | Iris vertical, párpados, brazos y dedos legibles sobre marco violeta; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch01.mp4) | 3344 / 21 |
| Soul Chains | Conservar | Eslabones grises, grilletes anaranjados y alma clara tienen separación suficiente; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch02.mp4) | 6092 / 24 |
| Plague Monarch | Conservar | Placas verdes/ocres, máscara blanca y cuatro extremidades distinguen su anatomía; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch02.mp4) | 2828 / 12 |
| The Void | Conservar | Vacío negro intencional, contorno claro y fragmentos separados; conservar el negro focal. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch03.mp4) | 1018 / 9 |
| Haunted Mirror | Conservar | Marco dorado, espejo azul y fantasma blanco con silueta clara; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch03.mp4) | 1164 / 7 |
| Crying Mask | Conservar | Porcelana clara, ojo negro y lágrimas azules se distinguen; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch04.mp4) | 1436 / 4 |
| Candle Wisp | Conservar | Cera marfil, ojos negros, manos y llama azul muestran profundidad; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch04.mp4) | 3606 / 4 |
| Grave Hopper | Remodelar geometría/material | Piedra/cabeza/patas se mezclan; borde de lápida y expresión débiles. Remodelar bordes, ojos, inscripción, musgo y separación de color. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch05.mp4) | 2400 / 10 |
| Grave Key | Conservar | Hueco del aro, hierro gris y bufanda azul reconocibles; conservar la rotura del aro. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch05.mp4) | 1526 / 6 |
| Mourning Ribbon | Conservar | Bucles y colas volumétricos; costuras claras sobre paño ciruela legibles; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch06.mp4) | 1728 / 5 |
| Wilted Sprout | Conservar | Tallo verde, pétalos ocres y rostro negro distinguen la planta; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch06.mp4) | 2220 / 4 |
| Ink Imp | Conservar | Contraste entre tinta negra, ojos claros y sobre crema; conservar el negro de tinta. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch07.mp4) | 1772 / 5 |
| Lost Locket | Conservar | Dos tapas de bronce y mano fantasmal separadas con volumen; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch07.mp4) | 2500 / 6 |
| Ashen Book | Conservar | Páginas crema, cubierta negra y página alzada tienen silueta clara; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch08.mp4) | 2324 / 7 |
| Lantern Lurker | Conservar | Jaula oscura permite leer el cautivo verde; patas tienen contorno propio; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch08.mp4) | 2950 / 11 |
| Hourglass Hound | Conservar | Marco arena abierto, conos y patas/hocico contrastados; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch09.mp4) | 2546 / 11 |
| Nail Beetle | Remodelar geometría/material | Hierro uniforme oculta placas y clavo; cara y rodillas poco separadas. Remodelar placas, labio del clavo, pupilas/mandíbulas y collars de seis patas. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch09.mp4) | 1594 / 14 |
| Pale Guest | Conservar | Madera/latón, lienzo roto y fantasma marfil separados; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch10.mp4) | 1716 / 5 |
| Cold Teacup | Conservar | Porcelana, pintura azul y vapor gris muestran su concepto; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch10.mp4) | 2456 / 3 |
| Coin Crawler | Remodelar geometría/material | Cuerpo/ribete/relieve uniformes: parece cuenco sin monedas. Remodelar cantos acuñados, tres monedas reconocibles, cara y articulaciones. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch11.mp4) | 2172 / 11 |
| Umbrella Wraith | Conservar | Pliegues azules, ojo marfil y detalles dorados claramente separados; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch11.mp4) | 1566 / 5 |
| Marrow Dice | Conservar | Dados marfil y puntos negros legibles. Marcha de pies pendiente expresamente fuera de esta tarea. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch12.mp4) | 4138 / 6 |
| Veil Mourner | Conservar | Paño azul con pliegues, vacío negro y peineta marfil contrastados; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch12.mp4) | 3280 / 6 |
| Grave Compass | Conservar | Brújula y tapa distinguen bronce, verde y dial oscuro; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch13.mp4) | 3242 / 4 |
| Hollow Violin | Conservar | Madera cálida, cuerdas azules y hueco central mantienen identidad; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch13.mp4) | 2150 / 9 |
| Chime Triplets | Conservar | Campanas con distintos tonos y borde dorado legibles; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch14.mp4) | 5332 / 4 |
| Thimble Spider | Conservar | Dedal perforado ocre, cabeza negra, ojos de botón y ocho patas distinguibles; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch14.mp4) | 5620 / 18 |
| Music Box Dancer | Conservar | Caja madera/latón y bailarina legibles; actuación recién corregida conservada. Marcha de la caja pendiente fuera de alcance. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch15.mp4) | 3988 / 5 |
| Raven Quill | Conservar | Pluma negra intencional con barbas claras, pico/patas ocres y ojo; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch15.mp4) | 1394 / 8 |
| Sorrow Chalice | Conservar | Copa azul/dorada y espíritu marfil legibles; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch16.mp4) | 2828 / 5 |
| Pale Gramophone | Conservar | Corneta marfil, caja madera/latón y disco oscuro legibles; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch16.mp4) | 6316 / 12 |
| Thorn Reliquary | Conservar | Barras doradas y espina verde con huecos visibles; conservar actuación corregida posterior a la galería. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch17.mp4) | 2060 / 3 |
| Anchor Crab | Conservar | Ancla jade, pinzas con caras cálidas y cabeza negra legibles; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch17.mp4) | 3128 / 17 |
| Sundial Sentinel | Conservar | Dial marfil, aguja ocre y sombra negra separados; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch18.mp4) | 2316 / 6 |
| Sleepwalker Shoes | Conservar | Botas azul/marrón con bordes claros y cordones; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch18.mp4) | 5176 / 3 |
| Night Harp | Conservar | Arco azul, cuerdas doradas, cabeza marfil y patas separadas; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch19.mp4) | 3452 / 14 |
| Thorn Cathedral | Conservar | Arquitectura gris clara, ventanal rojo, espinas y pies legibles; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch19.mp4) | 3064 / 11 |
| Phantom Marionette | Conservar | Cuerpo marfil, juntas ocres, hilos finos y cruz negra distinguen el títere; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch20.mp4) | 1964 / 11 |
| Blood Moon Rose | Conservar | Pétalos rojos facetados y tallo verde diferenciados, centro oscuro intencional; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch20.mp4) | 5166 / 16 |
| Judgement Scales | Conservar | Mitades de metal/marfil, platos y cadenas distinguibles; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch21.mp4) | 2112 / 9 |
| Clockwork Raven | Conservar | Ruedas doradas, cara clara, plumas azules y cuerpo negro distinguen mecanismos; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch21.mp4) | 3880 / 10 |
| Eclipse Stag | Conservar | Cuernos blancos, torso gris y rasgos jade legibles; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch22.mp4) | 1882 / 12 |
| Endless Library | Conservar | Cubiertas distintas y adornos claros separan tres volúmenes/libros; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch22.mp4) | 4812 / 15 |
| Sunken Crown | Conservar | Corona marfil, joya azul y tentáculos saturados legibles; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch23.mp4) | 3408 / 13 |
| Silent Choir | Conservar | Cantantes negro/marfil/azul con bordes dorados diferenciados; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch23.mp4) | 2680 / 7 |
| Cathedral Heart | Conservar | Arco gótico gris y corazón marfil con fisuras doradas se distinguen; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch24.mp4) | 3618 / 11 |
| Hollow Throne | Conservar | Trono vacío mantiene hueco y contorno claro; negro interior intencional; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch24.mp4) | 2416 / 11 |
| Worldroot | Conservar | Madera cálida, musgo verde agrupado y semilla jade separan el árbol; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch25.mp4) | 3456 / 14 |
| The Undertow | Conservar | Campana jade/bronce y apéndices azules legibles; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch25.mp4) | 2498 / 6 |
| The Last Funeral | Conservar | Ataúd ciruela, flores marfil, piernas y pies contrastados; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch26.mp4) | 3030 / 9 |
| Nameless Door | Conservar | Marco/tarima claros, puerta jade/dorada y hueco profundo legibles; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch26.mp4) | 3232 / 7 |
| Crown Of Silence | Conservar | Corona flotante dorada y túnica marfil con volumen claro; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch27.mp4) | 7204 / 11 |
| The First Grave | Conservar | Piedra blanca angular, brazos pardos y musgo seleccionado legibles; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch27.mp4) | 2136 / 11 |
| The Unwritten | Conservar | Paño oscuro con pliegues claros, cabeza marfil y grafismos se distinguen; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch28.mp4) | 8122 / 10 |
| The Last Star | Conservar | Armadura gris, marco abierto y estrella blanca tienen separación suficiente; conservar. [Vídeo previo](C:/RobloxProjects/StealACurse/assets/review/animations-polished/videos/native-batch28.mp4) | 4792 / 15 |

## Alcance verificado y pendiente

Comprobado en Blender: 56 fuentes existentes, datos de color/UV, normales planas, jerarquías y grupos; los 3 FBX reales se vuelven a importar, conservan nombres, huesos, colores, UV y triángulos; pesos normalizados y deformación aislada de 35 huesos sin mover vértices ajenos. Los renders diagnósticos muestran macrogeometría y separación de colores.

Comprobado en la integración nativa por el coordinador: IDs y tamaños reales de las tres remodeladas, actuación visible en procesión/transporte/pedestal y flujo habitual de compra, transporte, colocación y venta. [El registro de Play](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/native-production-play.json) conserva **15 aserciones de Curses satisfactorias**: cinco por modelo para malla nativa, compra, colocación manual, retirada al vender y limpieza del controlador. Su campo global `Stage: FAILED` corresponde a un error posterior al cargar el módulo espacial de QA; ese registro no acredita la prueba espacial ni invalida los 15 resultados individuales. Las verificaciones generales del santuario se documentan en el informe principal.

Pendientes fuera de esta pasada: marchas específicas de Music Box Dancer y Marrow Dice, y revisión de offsets VFX del amigo si sus efectos usan las cuatro rodillas reparadas de Coin Crawler. No se declaran 56 nuevas aprobaciones de Play, contacto perfecto de todas las poses, comprobación en teléfono físico ni FPS medidos por esta auditoría.
