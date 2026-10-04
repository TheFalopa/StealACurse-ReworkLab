# Actuación de 18 Curses: objetos y entidades contenidas

Entrega del grupo `acts_objects`, 2026-10-03. Estado: fuentes y módulo preparados para integración; la aprobación visual en Play pertenece al coordinador y no se declara en este documento.

## Archivos y contrato

- Módulo: `src/client/CurseActsObjects.luau`. Devuelve una factoría `function(H)` que entrega 18 funciones `act(e,t,g,idle)`.
- Un único controlador compartido invoca cada actuación. `H.pose` escribe únicamente `Bone.Transform`; ninguna actuación cambia la malla, el ancla de gameplay, propiedad, prompts, precios, producción o VFX.
- La marcha utiliza `H.gait` con distancia visual acumulada, escalada según la altura real. Contacto largo y recuperación corta con flexión de rodilla; al detenerse, la fase de marcha se detiene y la actividad disminuye mediante el controlador.
- `e.stateAge` añade acentos breves a la llama/manos, página, fantasma o lazo cuando cambia el estado. El controlador conserva la transición continua y la autoridad del servidor.
- Cada actuación escribe su `Root` y sus articulaciones en la misma llamada. No se crean conexiones, tweens, bucles por modelo, RemoteEvents ni clips externos.
- Las fuentes editables actuales son `assets/source/blender/curse_animation/<id>.blend`. Los 15 rigs sin cambios siguen utilizando sus importaciones reales existentes. Los otros tres requieren importar los FBX reparados indicados abajo.

## Inspección y diseño por Curse

| Curse / ID | Estructura real | Procesión | Transporte | Pedestal / sin colocar | Necesidad de rig y límites |
|---|---|---|---|---|---|
| Haunted Mirror / `haunted_mirror` | Marco rígido; 2 pies con rodillas; Reflection → GhostHead | Pasos cortos alternos; fantasma asciende y gira antes de asomar | Mantiene pies activos según velocidad y asoma con el marco estable | Mirada de dos tiempos, inclinación y aparición parcial del reflejo | 7 huesos existentes. Desplazamiento del reflejo limitado a 0,20 stud vertical y 0,10 de profundidad a altura 6; no se deforma el marco |
| Crying Mask / `crying_mask` | Sorrow mueve porcelana completa; dos tiras laterales | Máscara flotante que solloza; tiras quedan rezagadas | Mayor arrastre de tiras, sin giro de máscara que obstruya la cámara | Anticipación, inclinación del rostro y temblor breve después del sollozo | 4 huesos existentes. No existen articulaciones de lágrimas; no se inventan. Elevación decorativa de 0,30 stud evita introducir las tiras en el suelo |
| Candle Wisp / `candle_wisp` | Cera rígida, llama y dos manos caídas | Llama se dobla con el avance; manos protegen la luz | La llama conserva su actividad y las manos se coordinan alrededor de ella | Gesto ocasional de invitación de una mano y llama irregular | 4 huesos existentes. Llama ≤0,27 rad; gesto de mano izquierda hasta 0,76 rad durante saludo, con menor gesto de la derecha |
| Grave Key / `grave_key` | Hierro rígido, dos dientes/patas desiguales, rodillas y bufanda | Marcha desigual ligada a distancia, con recuperación desfasada | Conserva ese ritmo al caminar/parar; bufanda se retrasa | Tanteo de giro como si intentara encontrar una cerradura | 6 huesos existentes. Los pivotes de cadera originales están desplazados: se corrige el centro efectivo mediante traslación de la pose, conservando bind/rest. Comprobar unión visual de dientes en Play |
| Mourning Ribbon / `mourning_ribbon` | Dos bucles y dos colas, cada una como volumen articulado | Bucles se contraen y sueltan; colas se doblan hacia atrás con fase distinta | Colas aumentan arrastre sin giro amplio lateral | Contracción, pequeña liberación y ondulación de colas desfasadas | 5 huesos existentes. Rotación lateral de cola ≤0,09 rad para que sus extremos anchos no atraviesen el suelo; flexión principal en profundidad; elevación 0,34 stud |
| Wilted Sprout / `wilted_sprout` | Raíces, tallo, Bloom y Leaf bajo Stem | Tallo acompaña el avance, flor intenta levantarse y vuelve a marchitarse | Recuperación moderada y hoja rezagada | Flor se incorpora, sostiene la pose y cae; hoja responde después | **Pesos reparados Root/Stem**. Mantiene nombres, jerarquía y pivotes. El tallo alto ahora sigue Stem y los pies de raíz permanecen en Root |
| Ink Imp / `ink_imp` | Sobre rígido, criatura Ink con manos y cola | Se estira para alcanzar y se recoge, conservando el sobre estable | Extensión de manos y cola acompañan el avance sin marcha ficticia | Una mano limpia el cuerpo; cola reacciona al repliegue | 5 huesos existentes. Manos con actos asimétricos, cuerpo se eleva ≤0,16 stud; no se mueve el sobre |
| Lost Locket / `lost_locket` | Medallón rígido, tapa, palma y 3 dedos separados | Tapa abre lentamente; mano intenta salir, dedos golpean en sucesión | Tapa algo más recogida, mano no atraviesa hacia el jugador | Abrir, sostener, golpear y casi cerrar con pausa | 6 huesos existentes. El cuarto detalle de la mano pertenece a Palm; solo los 3 dedos realmente ponderados se articulan. Tapa ≤0,52 rad; palma emerge ≤0,18 stud |
| Ashen Book / `ashen_book` | Libro/encuadernación, dos pies pequeños con rodillas, Cover y PageWing | Pies alternos de recorrido corto; página impulsa pequeños deslizamientos estilizados | Página se agita con la velocidad, pies detienen fase al parar | Cubierta abre y página quemada da vueltas cortas con anticipación | 7 huesos existentes. Los pies de encuadernación son cortos y no permiten una zancada humana. Revisar contacto y deslizamiento residual de este artefacto en Play; página ≤0,53 rad |
| Lantern Lurker / `lantern_lurker` | Jaula rígida, 4 patas con rodillas, asa y cautivo | Parejas diagonales, patas traseras responden con pequeño desfase | Conserva las cuatro patas activas y el asa reacciona con retraso | Cautivo forcejea en ráfagas, el asa recibe el tirón | 11 huesos existentes. Orden real delantero izquierdo/derecho, trasero izquierdo/derecho. Flexión de las 4 rodillas; cautivo se mueve dentro de la jaula ≤0,12 stud |
| Pale Guest / `pale_guest` | Marco rígido, Ghost → Head y dos apoyos Grip | Fantasma se inclina y mira fuera del retrato; marco permanece rígido | Apoyos se aferran y la mirada acompaña al movimiento | Asoma, gira la cabeza y se esconde tímidamente | 5 huesos existentes. Solo el fantasma avanza ≤0,15 stud de profundidad; los apoyos no se presentan como dedos separados |
| Cold Teacup / `cold_teacup` | Taza y plato rígidos; Steam → SteamTip | Vapor oscuro se enrolla y la punta responde después | Vapor se inclina ligeramente con la velocidad, sin caminar la taza | Espiral tensa, giro de punta y latigazo contenido | **Pesos reparados Steam/SteamTip**. El vapor inferior sigue Steam y el superior SteamTip; taza, plato y pintura no cambian |
| Grave Compass / `grave_compass` | Carcasa, aguja, tapa y anilla | Aguja busca una dirección falsa, duda y vuelve a señalar | Anilla oscila con el avance; tapa mantiene apertura contenida | Búsqueda, pausa decidida y breve vibración de aguja | 4 huesos existentes. Aguja ≤0,59 rad; se corrige el pivote efectivo de la anilla según su suspensión real. No se cambia el bind/rest |
| Pale Gramophone / `pale_gramophone` | Caja rígida, 4 patas/rodillas, trompa, disco y manivela | Marcha diagonal adecuada al orden real de huesos, disco gira y trompa escucha | Patas siguen velocidad, trompa mira lateralmente de forma contenida | Disco/manivela giran; trompa inclina y sostiene su escucha | 12 huesos existentes. Orden real izquierda delante/detrás y derecha delante/detrás; las cuatro patas se animan. Corrección del pivote efectivo del disco para evitar órbita. El grupo Record incluye un pequeño detalle del brazo: revisar su unión visual |
| Raven Quill / `raven_quill` | Dos patas con rodillas, pico/nib y dos grupos de barbas | Pasos de ave; plumas se retrasan y el pico observa | Pies responden a velocidad; barbas vibran moderadamente | Inclina el pico para escribir, hace pequeños trazos y eriza las plumas | 8 huesos existentes. No hay cuello aparte: Nib incluye ojo y pico. Los grupos Barbs contienen las mitades del plumaje; rizado moderado ≤0,16 rad evita partir demasiado la silueta |
| Sorrow Chalice / `sorrow_chalice` | Copa rígida, Spirit y tres gotas separadas | Lamento contenido del espíritu; gotas descienden por turnos | Mantiene copa estable y gesto del espíritu dentro de su volumen | El espíritu asciende, inclina y deja caer tres lágrimas con retraso | 5 huesos existentes. Gotas desplazan ≤0,28 stud, espíritu ≤0,12 stud; la copa no se deforma |
| Thorn Reliquary / `thorn_reliquary` | Jaula y base rígidas; Thorn → ThornTip | Cautivo empuja, punta responde más tarde y retrocede | Reacción interna pequeña para conservar la lectura de la jaula | Tensión, pausa y retroceso con movimientos contrapuestos de tronco/punta | **Pesos reparados Thorn/ThornTip**. Tronco/raíces siguen Thorn, extremo alto ThornTip. Rotaciones del tronco ≤0,10 rad y punta ≤0,23; confirmar que no toca barrotes |
| Chime Triplets / `chime_triplets` | Travesaño rígido y 3 campanas completas con rostros/cadenas incluidos | Oscilación longitudinal moderada y secuencia llamada/respuestas | Las 3 campanas responden con fases propias al avance | Primera campana llama; otras dos responden; oscilación amortiguada | 4 huesos existentes. No hay badajos independientes; se actúa la campana completa. Oscilación principal delante/detrás para evitar choques laterales; elevación 0,18 stud para conservar separación del suelo |

Los movimientos de marcha usan fases de distancia distintas por concepto; los mecanismos tienen ventanas de anticipación, pausa y recuperación propias. Se requieren aproximadamente 7–8 segundos para observar un ciclo completo de sus gestos de reposo; una captura de 2 segundos puede no incluir el acto principal.

## Reparaciones reales de rig

El generador anterior reutilizaba una función de pesos para cadenas descendentes en tres cadenas ascendentes. Se intercambiaron únicamente los pesos de los dos grupos afectados:

| Curse | Correspondencia corregida | Vértices con pesos distintos | FBX real pendiente de importación coordinada |
|---|---|---:|---|
| Wilted Sprout | Root/Stem: raíz fija y tallo alto articulado | 294 | `assets/export/meshes/curses/animations-polished/wilted_sprout.fbx` |
| Cold Teacup | Steam/SteamTip: tramo inferior y punta superior | 206 | `assets/export/meshes/curses/animations-polished/cold_teacup.fbx` |
| Thorn Reliquary | Thorn/ThornTip: tronco inferior y extremo alto | 356 | `assets/export/meshes/curses/animations-polished/thorn_reliquary.fbx` |

Los 18 `.blend` se inspeccionaron en Blender 5.2.2 sin abrir la interfaz ni alterar los otros 15. Todas las sumas de pesos fueron válidas. Las tres reparaciones se compararon con las copias originales: posiciones de todos los vértices, polígonos, materiales, UVs, colores y matrices rest de los huesos **exactamente iguales**; pesos suman 1. Evidencia en `objects-weight-audit.json` y `objects-rig-repairs-verified.json`. Esto verifica las fuentes y no sustituye Play.

El procedimiento reproducible, las copias originales y hashes reales están en:

- `objects-repair-upward-weights.py`, que restaura su copia original antes de intercambiar grupos y exportar; repetirlo no invierte la reparación.
- `objects-rigs-before/`: originales recuperables de los tres `.blend`.
- `objects-rig-repairs.json`: fuentes, FBX y SHA256. No asigna IDs inventados ni declara importación terminada.
- `objects-verify-rig-repairs.py`: comparación completa de geometría/acabado/rest y pesos.

## Integración con VFX

No se cambiaron nombres, jerarquías, huesos rest, materiales ni anclajes `VFX_*`. No se editó `CurseVFX` ni sus perfiles. Los efectos siguen las transformaciones de los huesos mediante el controlador existente.

Para los VFX del amigo:

- **Wilted Sprout:** efectos del suelo/raíces deben seguir `Root`; efectos del tallo deben seguir `Stem`; `Bloom` y `Leaf` mantienen nombres y descendencia. Antes el reparto de geometría Root/Stem estaba invertido.
- **Cold Teacup:** vapor basal debe seguir `Steam`, punta/humo alto `SteamTip`. Los nombres se conservan y ahora la geometría corresponde a sus significados.
- **Thorn Reliquary:** jaula/glass/base siguen `Root`; entidad inferior `Thorn`; efectos de ojos/punta alta `ThornTip`. Antes las zonas ponderadas inferior/superior estaban invertidas.
- **Grave Key, Grave Compass, Pale Gramophone:** correcciones de pivote son poses, sin modificaciones de matrices rest. Los anclajes existentes que ya siguen esos huesos recibirán también el movimiento corregido; verificar los efectos fijados manualmente a posiciones de la malla.

## Revisión pendiente del coordinador

1. Importar realmente los tres FBX reparados mediante el lote nativo; observar sus IDs y conservar el prefijo de huesos compatible con el juego. Actualizar el registro solo después de obtener esos datos reales.
2. Comprobar las 18 en el proyecto integrado, con skinning funcional: reposo de ciclo completo, procesión, transporte, recoger/colocar; medir legibilidad a distancia normal.
3. Vigilar contacto/deslizamiento de los pies cortos de Ashen Book y Grave Key; unión de dientes de Key; pequeño detalle ponderado con Record; cadenas/campanas completas sin badajo articulado; margen de Thorn frente a barrotes.
4. Confirmar que el controlador central no sobrescribe `Root` después de estas actuaciones ni mantiene poses antiguas al detenerse/cambiar estado, y que la reducción de detalle/reactivación sigue funcionando.

No se usó Studio, UI ni herramientas de importación desde este subagente. No hay aprobaciones de Play inventadas ni se reclama completar la revisión de estas 18.
