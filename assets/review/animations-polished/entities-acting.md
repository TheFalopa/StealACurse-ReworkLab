# Entidades: actuación preparada para 17 Curses

Fecha: 2026-10-03. Responsable de integración y Studio: agente raíz.

## Estado real

Actuaciones escritas en `src/client/CurseActsEntities.luau`, inspeccionadas contra las 17 fuentes Blender y sus grupos ponderados. **No son aprobaciones visuales en Play**: la revisión del proyecto integrado corresponde al coordinador. No se accedió a Studio ni se modificaron archivos compartidos de integración, gameplay o VFX.

El módulo usa los helpers compartidos `pose`, `pulse`, `smooth` y `gait`. `gait` devuelve fase a partir de distancia real y escala; este módulo aplica las articulaciones. Las marchas tienen 62 % de apoyo y un arco de recuperación separado, flexión de rodilla y compensación de altura de la articulación superior. Los cuatro apoyos de cada cuadrúpedo reciben movimientos coordinados; no hay cuatro patas con solo dos animadas. Su ajuste final de apoyos, penetraciones y lectura a distancia debe comprobarse en Play.

Las actuaciones solo escriben `Bone.Transform`. No escriben anclas de gameplay, `MeshPart.CFrame`, prompts, ingresos, propiedad o efectos. No crean conexiones, tareas ni bucles por Curse. Recogida/colocación usan `e.stateAge`; el controlador integrado suaviza las poses y reduce trabajo a distancia.

## Inventario y actuación

| Curse | Estructura real | Procesión | Transporte | Reposo y colocación | Necesidad de rig/importación |
|---|---|---|---|---|---|
| Veil Mourner | Capa/velo dividido, dos manos, peine; 6 huesos | Deslizamiento, velo arrastrado y hombros encogidos | Aprieta el velo al recoger; conserva el temblor de manos | Respira, sostiene el duelo y tiene un escalofrío breve; peine se inclina | Fuente existente sirve; sin cambios |
| Umbrella Wraith | Eje rígido, dos alas plegadas y dos jirones; 5 huesos | Batida conjunta del paraguas; jirones siguen con retraso | Pliega las alas al recoger y vuelve a desplegarlas | Despliega lentamente la tela y mantiene una pausa abierta | Fuente existente sirve; sin cambios |
| Sundial Sentinel | Disco de piedra, dos piernas/rodillas y sombra independiente; 6 huesos | Dos pasos amplios y lentos según distancia; disco contrapesa | La sombra se estabiliza durante recogida | Sombra salta entre tres direcciones con aceleración y pausas | Gnomon original rígido; no se inventa un control inexistente |
| Blood Moon Rose | Cuatro raíces articuladas, cuatro sectores de pétalos, flor padre, dos brazos de espinas; 16 huesos | Marcha diagonal contenida; flor observa y pétalos se abren | Las espinas se cierran protectoras al recoger | Flor despliega pétalos en oleada, pausa y pinza los brazos; colocación abre la flor | `Bloom` es padre válido de pétalos ponderados; fuente sirve |
| Night Harp | Cuatro patas/rodillas, cabeza real y cuatro cuerdas físicas; 14 huesos | Paso silencioso, cabeza escucha | Cabeza ladea al recoger; cuerdas continúan el arpegio | Cuatro pulsaciones sucesivas con cuerda realmente deformable y extremos sujetos | **Pesos corregidos y FBX nuevo preparado**: ver abajo |
| Judgement Scales | Dos piernas/rodillas, dos brazos de balanza y dos platos; 9 huesos | Paso firme; estabiliza algo la balanza | Nivela brevemente los brazos al recoger | Sube un plato y baja el otro, sostiene el veredicto; platos contrarrotan para seguir horizontales | Fuente existente sirve; sin cambios |
| Cathedral Heart | Cuatro apoyos/rodillas, arquitectura rígida y dos mitades del corazón; 11 huesos | Marcha solemne de cuatro apoyos | Conserva el doble latido al seguir al jugador | Latido doble abre/bulga las dos mitades; latido adicional al colocar | Fuente existente sirve; amplitud final pendiente de Play |
| Hollow Throne | Trono rígido, cuatro pies/rodillas, espectro vacío y manto; 11 huesos | Marcha diagonal con el asiento estabilizado | El espectro se recoge brevemente dentro del trono al levantar | Presencia se eleva desde el asiento, se inclina hacia delante y vuelve; manto acompaña | Fuente existente sirve; sin cambios |
| Nameless Door | Umbral con dos piernas/rodillas, hoja física con bisagra y musgo; 7 huesos | Pasos cortos y musgo con arrastre | Hoja se cierra parcialmente al recoger | Hoja abre, espera invitando y golpea dos veces; al colocar abre de nuevo | Conserva bisagra actual y corredor rígido |
| Silent Choir | Tres cantantes independientes con cuerpo y campana hija; 7 huesos | Se deslizan juntos, cada cantante entra en una frase propia | Mantienen la frase sin una caminata forzada | Campanas se inclinan una tras otra y las tres presencias hacen una cadencia; al colocar inclinan juntas | **Pesos corregidos y FBX nuevo preparado**: cada campana mueve su cabeza, no una túnica entera |
| The First Grave | Golem de lápida, dos piernas/rodillas, dos brazos/dedos de madera y musgo; 11 huesos | Pasos pesados, brazos coordinados, musgo retrasado | Brazos se acercan al cuerpo al recoger | Lleva los dedos a un recuerdo, sostiene el gesto y baja los brazos | `FingersL/R` controlan cada mano ramificada, no dedos individuales; sin nuevos huesos |
| The Last Funeral | Ataúd rígido suspendido por cuatro correas/patas con rodillas; 9 huesos | Los cuatro portadores avanzan en diagonal; el ataúd acompaña su carga | Cuatro apoyos se tensan al recoger | Portadores se afianzan y el ataúd asienta lentamente su peso; al colocar flexionan | **Pesos corregidos y FBX nuevo preparado**: correas superiores no giran fuera del ataúd |
| The Last Star | Cuatro patas/rodillas, estrella presa, yelmo, dos brazos/garras; 15 huesos | Marcha de guardián con cuatro apoyos | Aprieta garras hacia la estrella al recoger | Estrella gira un octavo de vuelta y queda suspendida; yelmo vigila y garras se cierran | Fuente existente sirve; estrella indexada con límites continuos |
| Crown of Silence | Regente sin cabeza, cuatro fragmentos de corona, cuatro sectores de túnica y dos mangas; 11 huesos | Deslizamiento con cola de túnica y mangas | Fragmentos se aproximan brevemente al vacío al recoger | Fragmentos suben de uno en uno, mangas imponen silencio y túnica transmite la oleada; al colocar extiende mangas | Fuente existente sirve; sin renombrar fragmentos |
| The Undertow | Campana hueca, badajo, dos grandes hojas de agua, remolino y asa; 6 huesos | Arrastre de hojas con avance flotante y péndulo de badajo | Amortigua badajo al recoger | Surge una marea, brazos se cierran, remolino gira y sube; asa retrasa el péndulo | Fuente existente sirve; sin caminata ni VFX nuevos |
| The Unwritten | Espectro de páginas, cabeza, cuatro colas de papel, dos mangas/manos de escritura; 10 huesos | Páginas arrastradas en secuencia, manos protegidas | Prepara el manuscrito al recoger | Anticipa, escribe varios trazos, pasa páginas y borra con la otra mano; cabeza sigue la acción | Fuente existente sirve; no se simula una articulación de dedos ausente |
| Worldroot | Cuatro piernas de raíz/rodillas, dos arcos de tronco, musgo y semilla; 14 huesos | Cuatro raíces avanzan con peso; musgo sigue el paso | Semilla se recoge hacia el tronco al levantar | Arcos se abren ligeramente, semilla asciende y gira, musgo cae en oleadas | Fuente existente sirve; sin alterar ramas/anclajes |

Fuentes de las 17: `assets/source/blender/curse_animation/{id}.blend`. Los 14 rigs conservados usan sus importaciones reales registradas en `assets/imports/curse-animation-current.json`. No se asignaron IDs ficticios a las tres reparaciones.

## Reparaciones esenciales y pruebas realizadas

Herramienta: Blender **5.2.2 LTS**, en segundo plano; no plugins nuevos. Procedimiento reproducible: `assets/review/animations-polished/repair-entities-rigs.py`. Exportaciones separadas listas para importación real:

| Curse | Vertices antes/después | Corrección | FBX |
|---|---:|---|---|
| Silent Choir | 1402 / 1402 | Error de límites de piezas: la marca de una cabeza incluía la túnica del siguiente cantante. Ahora cada `Singer0/1/2` tiene 240 vértices y cada `Bell0/1/2` 210. | `assets/export/meshes/curses/animations-polished/entities/silent_choir.fbx` |
| Night Harp | 1358 / 1838 | Marco, placas y anillos vuelven a `Root`; `Head` solo posee 59 vértices de cabeza/visor. Cuatro cuerdas reciben vértices longitudinales para poder deformar sus centros conservando extremos sujetos. | `assets/export/meshes/curses/animations-polished/entities/night_harp.fbx` |
| The Last Funeral | 1611 / 1611 | Influencia de cada pata desaparece suavemente antes de la unión con el ataúd; las correas superiores quedan rígidas sobre el féretro. | `assets/export/meshes/curses/animations-polished/entities/the_last_funeral.fbx` |

La subdivisión de cuerdas conserva sus superficies rectas, silueta, UV/materiales y proporciones de reposo. Los 480 vértices adicionales permiten una deformación efectiva; no se añadieron por densidad decorativa. No se cambiaron huesos, nombres, pivotes, jerarquías, tamaños objetivo ni anclajes.

`entities-rig-repairs.json` contiene hashes reales de fuentes/exportaciones, pesos y marca `realImportRecorded: false`. El coordinador debe registrar importaciones e IDs reales en la integración. `entities-blender-audit.json` conserva el inventario previo; `entities-components-audit.json` identifica las piezas afectadas. `verify-entities-repaired-weights.py` ejecutó **11 comprobaciones de aislamiento de deformación Blender**, guardadas en `entities-deformation-verification.json`: dos cabezas de Choir, cuatro cuerdas y cabeza de Harp, cuatro portadores de Funeral. Todos movieron vértices del control previsto; **cero vértices ajenos**. Ninguna prueba se presenta como una comprobación en Play.

## Integración de VFX del amigo

Correspondencia de nombres: **anterior = nuevo en las 17 Curses**. Se mantienen `Root`, nombres semánticos, prefijos exportados, anclajes `VFX_*` y jerarquías. Este módulo no altera los efectos existentes.

Tres cambios de vinculación de geometría que conviene conocer:

- **Silent Choir:** `Bell1/2` ahora solo mueve la cabeza y sus adornos; la túnica correspondiente sigue `Singer1/2`. Efectos de abertura de campana deben seguir `Bell0/1/2`; efectos sobre tela, su `Singer`.
- **Night Harp:** `Head` ahora solo gira cabeza/visor. Marco y placas siguen `Root`. Chispas de cuerdas pueden seguir `String0/1/2/3` en el centro; sus puntos de unión al marco permanecen fijos y deben seguir `Root`. Orden izquierda/derecha de las cuatro cuerdas y pivotes no cambiaron.
- **The Last Funeral:** correas sobre la tapa siguen `Root`, secciones bajas siguen `Leg0..3/Knee0..3`. Efectos ligados al féretro deben seguir `Root`; efectos de patas, la articulación correspondiente.

Los anclajes actuales se conservan; estas notas permiten elegir correctamente el control al integrar efectos posteriores. No se hizo una pasada de VFX.

## Pendiente exclusivo de integración

Importación real de los tres FBX reparados, registro de IDs/tamaños observados y revisión nativa de las 17 actuaciones en los estados del juego. El coordinador debe revisar especialmente apoyos de Funeral/First Grave, extremos de cuerdas de Harp, nivelación de platos de Scales, desplazamiento de mitades de Heart y las grandes hojas de Undertow. Ninguno de estos controles se declaró aprobado basándose en cambios de `Transform` o pruebas Blender.
