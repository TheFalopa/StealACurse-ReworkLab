# Steal A Curse — World Expansion / Final Art / Curse Pipeline

Trabajo iniciado el 1 de octubre y cerrado el 2 de octubre de 2026. **Pase local cerrado con primera ola escalonada y límites explícitos; no roster completo ni publicación aprobados.** Los apartados distinguen código/exports, importación real, apariencia, pruebas de Play y comprobaciones humanas pendientes. Los resultados históricos de Final Map Polish V2 no se presentan como pruebas de esta expansión.

## 1. Rama

`feature/final-map-polish-v2`. No se cambia de rama, se hace merge ni se publica la experiencia.

## 2. Estado inicial del repositorio

Árbol limpio al inspeccionarlo; HEAD `6b9891d` (`Add polish v2 review documentation`). Los commits anteriores incluyen `0c469c7` (WIP de mapa/UI) y `1a3ad5f` (rework del entorno). Son el punto de partida recibido, no commits de este trabajo.

## 3. Trabajo inconcluso retomado

Se conserva el mapa Hollow Crown, Grounding, hulls, SurfaceArt, grupos Halloween, HUD modular y tienda futura. El informe previo dejaba pendiente la repetición responsive tras las tarjetas compactas de landscape y la auditoría de cierre. Sus pruebas históricas no se usan como aprobación de esta expansión.

Este pase ya cuenta con evidencia propia posterior al fix PluginSecurity de Materials: contratos/grounding y procesión natural de 110.1856 s, un ciclo de claim/compra/entrega de la Cursed Doll original con input de prompt y caminata asistidos, y cuatro categorías de desplazamiento físico a WalkSpeed16. También se observaron las siluetas y paletas de los 15 nuevos meshes en una galería Roblox test-only; eso no activa ni valida su gameplay. Alcance y límites: apartados 26–27 y [curse-wave1-appearance.json](review/world-expansion-2026-10-01/curse-wave1-appearance.json). La revisión responsive se registra por separado en el apartado 28: bounds correctos no demuestran un gesto real de scroll landscape.

## 4. Footprint del mapa

Configuración nueva: **820 × 800 studs**, frente a 620 × 610: superficie de soporte rectangular de 656,000 frente a 378,200 studs², aproximadamente **+73.5%**. El radio de referencia de la barrera irregular pasa de 282 a 380. Esto describe geometría/configuración; la barrera delimita la región jugable, no los enormes tiles visuales de horizonte.

El suelo físico es un único soporte invisible de 820 × 8 × 800, con cara superior local Y=0 y elevación global +1. Los nueve tiles visuales de 2,048 studs siguen sin colisión ni sombras; no cuentan como expansión jugable. `boundaryRadius` mantiene una variación de ±16 como cota conservadora, dentro de las medias dimensiones 410/400. Las 48 secciones de barrera bloqueante conservan solape en las juntas; paisaje exterior y grandes árboles de horizonte no añaden hulls jugables.

## 5. Distribución espacial

Ocho sitios de santuario con coordenadas X/Z explícitas y elevaciones locales, antes del +1 global:

| Base | Territorio | X | Z | Elevación local |
| --- | --- | ---: | ---: | ---: |
| Base01 | South Vigil | 15 | 286 | 0 |
| Base02 | Autumn Court | 218 | 224 | 1 |
| Base03 | Lantern Wood | 299 | 38 | 0 |
| Base04 | Ashen Rise | 207 | -216 | 2 |
| Base05 | North Reliquary | -12 | -299 | 1 |
| Base06 | Chapel Watch | -221 | -218 | 0 |
| Base07 | Widow's Grove | -295 | -18 | 2 |
| Base08 | Old Family Court | -212 | 227 | 1 |

Se conservan `baseFrame`, radios/grados derivados y cinco puntos de aproximación por base. La distancia recta de cada centro al origen varía entre 286.39 y 312.57 studs; entre centros vecinos, entre 202.87 y 270.15. Son cálculos X/Z del código, no tiempos ni recorridos físicos. Hay 11 conexiones internas authored y ocho enlaces a vecinos. Caminos de aproximación de 20 studs, rampas de 22, cross-trails internos de 14 y vecinos de 12. Las reservas usan medias anchuras de 11 para aproximaciones y 7 para cross-trails, más el radio de cada prop.

En Play se confirmaron ocho sitios, cuarenta slots, separación mínima entre centros de 202.8719 studs y ocho rutas navmesh al castillo con `Success`, sin failures/warnings del observador: [runtime-initial.json](review/world-expansion-2026-10-01/runtime-initial.json). Las caminatas físicas documentadas cubren Base08 → castillo → Base08, Base01 → Base02 y Base02 → Base06; no equivalen a recorrer las cinco aproximaciones de las ocho bases. Sus tiempos, tolerancias y el intento Base08 → Base01 que quedó en timeout sin causa confirmada se conservan en el apartado 27. Equidad de compra, todos los accesos laterales y lectura/cámara de cada área no quedan aprobados por estas muestras.

## 6. Castillo

Se mantiene el Hollow Crown Sanctum como origen de Curses, con undercroft norte/sur abierto y `CentralMausoleum.CurseSpawnPoint` local (0,2,0). Se preservan alas, torres, nave alta, vidrio, cadenas y puerta original: no se sustituye la arquitectura.

`CastleRitualGrounds` amplía la composición: ocho escalones laterales en X=±26, dos memoriales de llegada en X=±56/Z=25, tres memoriales exteriores y faroles/inlays discretos. Las escaleras quedan fuera del corredor central de Curses. `FrontCourtApproach` conecta Z=9→85 con anchura 24; `RearHallApproach` conecta Z=-72→-128 con anchura 22. El patio ritual de 65 × 46 conserva un centro transitable.

La integración ya arrancó en Play después del fix de Materials: el observador de mundo no registró failures/warnings, hubo siete emergencias naturales desde el castillo y el personaje llegó físicamente desde Base08 a `castle court` en 20.8321 s, sin saltos. Allí se compró una Cursed Doll original aparecida naturalmente y se llevó de vuelta a Base08: [runtime-initial.json](review/world-expansion-2026-10-01/runtime-initial.json) y [gameplay-return.json](review/world-expansion-2026-10-01/gameplay-return.json). Esa muestra confirma el origen y el acceso frontal usado, no todos los undercrofts, escaleras laterales, acceso trasero ni una barrida completa de cámara a altura de jugador.

## 7. Procesión

`Layout.ProcessionPoints` contiene **16 puntos**, aproximadamente **636.68 studs**: entrada → corte frontal → carretera funeraria occidental → costado y parte posterior → segundo lane oriental → salida. No es un círculo exacto. El pavimento, exclusiones de decoración y movimiento comparten estos puntos; el runtime registra 15 segmentos y 636.6768 studs tanto para arte de ruta como movimiento. A 6.5 studs/s, un ciclo geométrico completo dura aproximadamente 97.95 s; es un cálculo, no un cronómetro de vida observado ni un tiempo de desplazamiento del jugador.

La observación natural post-fix terminó `phase=passed` tras **110.1856 s**, con siete modelos observados/siete emergencias desde el castillo, pico de seis simultáneos y **una salida natural sin compra**. Sus 2,316 muestras dejaron vacíos `solidBoundsCandidates`, `visualTreeBoundsCandidates` y `unsupportedSegments`: [runtime-initial.json](review/world-expansion-2026-10-01/runtime-initial.json). Esto verifica el observador de esa ventana, no despeje de todos los triángulos, toda cámara ni comportamiento de las nuevas Curses disabled. `purchasedModels=0` pertenece a esa ventana inicial; la compra de la Doll ocurrió después y se documenta por separado.

Secuencia X/Z local compartida:

```text
(0,0) → (0,16) → (0,34) → (-25,61) → (-60,58) → (-83,31)
→ (-87,-25) → (-75,-82) → (-42,-105) → (15,-113)
→ (64,-96) → (91,-54) → (107,2) → (130,35) → (144,79) → (160,112)
```

El pavimento mide 14 studs; la reserva horizontal de procesión tiene media anchura 9 más el radio del prop. Velas y guías se sitúan en hombros, no en el eje. La fuente limita a seis Curses simultáneas, cadencia de 10 s y velocidad 6.5; el contador evita que la ruta larga se llene indefinidamente. El movimiento deriva Y del spawn y X/Z de Layout: con spawn X/Z=0 coinciden; un futuro traslado del castillo exigiría actualizar ese contrato. Los giros son tramos rectos con cambio de orientación en vértices, no un sistema de navegación nuevo.

## 8. Santuarios

Exactamente ocho santuarios y cuarenta slots físicos. Las bases siguen siendo patios abiertos de colección, no nuevas fortalezas ni un sistema de ownership diferente. Se conservan los nombres directos consumidos por BaseService/CurseService. QA comprueba soporte, contratos y separación de centros; el recorrido físico sigue siendo independiente.

Se mantienen `Base01`–`Base08`, `PlayerSpawn`, `FutureCurseDisplayArea` y cinco `DisplayPlinth_1`–`DisplayPlinth_5` directos por base. Suelo 60 × 66; slots locales (-13,3), (13,3), (-13,16), (13,16), (0,23), con top funcional Y=3.4 relativo al frame. El spawn sigue (0,1.4,-18). Aperturas laterales y trasera siguen disponibles; los side approaches usan rampas nativas suaves, no colisión de hojas. Se añade `TerritoryName` como metadata, sin cambiar claim/ownership ni economía.

## 9. Halloween

Se amplía la composición de grupos existentes en vez de eliminar el rework: vigils fuera del eje de procesión, grupos territoriales periféricos, grupos familiares sobre terraces y telarañas de woodland/landmarks. La fuente declara 20 sitios candidatos de cementerio frente a 12, cuatro sitios candidatos de crypts y claros específicos para chapel/gate/memorial/crystals; la construcción puede omitir candidatos que invadan reservas. Las telarañas siguen hechas de segmentos finos, no grandes planos opacos. Las hojas caídas cosméticas no añaden colisión ni sombras.

El presupuesto global ya se midió en Play: 4,233 BaseParts, incluidas 764 MeshParts, 13 luces y un emisor ambientales; no son conteos exclusivos de Halloween. El límite de SurfaceArt es 640 piezas y woodland prueba hasta 230 candidatos con tope de 128 árboles: son límites de fuente, no cantidades colocadas. `HalloweenClusterCount` y `PlayableForestTreeCount` se escriben durante build, pero no aparecen en [runtime-initial.json](review/world-expansion-2026-10-01/runtime-initial.json); no se inventa ese desglose ni se convierte 20/4 en un conteo runtime. La composición colocada tiene muestras visuales en [cementerio antiguo](review/world-expansion-2026-10-01/07-old-graveyard.png), [bosque muerto](review/world-expansion-2026-10-01/08-dead-forest.png) y [grupo Halloween](review/world-expansion-2026-10-01/09-halloween-cluster.png), sin aprobar todos los props/ángulos por una captura.

## 10. Árboles y follaje

Pipeline original bajo `assets/source/blender/foliage_expansion/`: tres clumps Blender importados, `foliage_crescent`, `foliage_tattered`, `foliage_swept`. Son hojas curvas cerradas con contornos asimétricos y espacios negativos; no esferas, billboards ni imágenes planas. Sus IDs reales están en el apartado 22. Los troncos anteriores se reutilizan; `treeFamily` diferencia haunted, dead, autumn, sparse, broken y stump mediante silueta, clumps y paleta. No se elimina el bosque. La selección de candidatos tiene un máximo de 128 árboles jugables; es un límite, no un conteo final.

Se corrigió una copa flotante de landmarks: `D.foliage` multiplicaba la altura de anclaje por la escala exagerada del tamaño de hojas. Ahora `anchorScale` es independiente de `ClumpScale`; los heroes usan tamaño `site.scale*1.5` pero anclaje `site.scale`. El clump superior de WidowsOak baja de 78.75 a 52.5 local respecto al suelo; ChainedTree de 66.15 a 44.1, dentro de árboles de 65/54.6 de altura. Los otros árboles mantienen la escala por defecto y las posiciones previas. Metadata `FoliageAnchorScale`, `FoliageClumpScale`, `FoliageAnchorHeight` permite inspeccionarlo. Los troncos bajos usan colisión simple; hojas, ramas y raíces cosméticas no bloquean cámara/rutas por sus propiedades, sin garantizar cero oclusión visual.

La [captura 10 en Play](review/world-expansion-2026-10-01/10-trees-foliage.png), encuadrada hacia WidowsOak, ya muestra sus clumps cyan/violeta a la altura de las ramas, no como una corona separada por encima de todo el árbol; los árboles cercanos conservan variantes orange/rosa y huecos entre hojas. [07](review/world-expansion-2026-10-01/07-old-graveyard.png) muestra esa mezcla en el cementerio y [08](review/world-expansion-2026-10-01/08-dead-forest.png) siluetas desnudas en el bosque muerto. Es revisión visual de esos encuadres, no prueba de cada clump, de ChainedTree desde todos los ángulos ni de cámara estándar en todas las rutas. El tope de 128 no se presenta como conteo final de woodland.

## 11. Materiales y texturas

Se conserva el tratamiento estilizado azul/violeta con tres PNG originales generados para el proyecto bajo `assets/source/textures/world_expansion/`. No son un atlas ni assets de terceros; generación con pincelada estilizada no significa pintura manual ni garantiza seamless. Se importaron como imágenes con IDs observados en Studio y se mapearon en `default.project.json`:

| Superficie / variante | Base | ColorMap real | Studs/tile | Patrón |
| --- | --- | --- | ---: | --- |
| Stone / HollowStonePainted | Slate | `rbxassetid://93394270586297` | 16 | Regular |
| Wood / TwilightWoodPainted | Wood | `rbxassetid://81623021739244` | 12 | Regular |
| Ground / DuskySoilPainted | Ground | `rbxassetid://117271298687011` | 28 | Organic |

`Materials.apply(map)` se ejecuta después de `SurfaceArt.build`. Usa categorías propias/variantes compartidas; excluye hulls, superficies invisibles, detalle superficial, Neon y materiales ajenos. Captura `CurrentPhysicalProperties` y los reaplica para conservar fricción/densidad. Los tiles amplios tienen categoría DuskySoil. Si falta una MaterialVariant, conserva la paleta nativa; no activa overrides globales.

Durante el primer arranque se detectó que leer `MaterialVariant.ColorMap` desde servidor exige PluginSecurity y detenía Build. Se eliminó esa lectura en producción: IDs/configuración se verifican estáticamente contra las evidencias; runtime solo comprueba que exista la MaterialVariant. El arranque posterior al fix completó el observador de mundo/procesión y el ciclo natural de la Doll, documentados en 26; el closeup de material está en la categoría 11 del índice de capturas. Esa revisión no certifica seamless, color perfecto ni memoria en hardware móvil. Las tres texturas originales se generaron mediante el flujo de imagen del proyecto; no son materiales descargados de terceros.

## 12. Colisión

Continúan los hulls simples invisibles existentes para arquitectura, vallas, grandes rocas y troncos. `QualityPass.server.luau` verifica flags, conteo y contención en bounds. `Expansion.server.luau` excluye soportes bajos y barreras amplias del barrido de la procesión e inspecciona volúmenes sólidos cercanos. Un bounding-box candidate no demuestra intersección de triángulos ni ausencia de snags físicos.

Auditoría de fuente: `AssetKit.place` desactiva CanCollide/CanQuery/CanTouch de las mallas artísticas; solo los perfiles nativos añaden sólidos. La puerta conserva dos jambs laterales, no una caja que rellene la entrada. Giant trees solo tienen el tronco inferior como hull; follaje nuevo es Soft sin hulls. Rocas grandes accesibles usan un hull inscrito; cliffs y árboles detrás de la barrera se colocan con colisión desactivada. RollingBank reserva radio 28 para su footprint 33 × 46, no el antiguo radio 14 que podía invadir rutas. Las graves/roots pequeños siguen suaves.

Riesgos pendientes de input físico: juntas entre caminos, apoyo lateral de rampas elevadas, troncos/rocas cerca de hombros y paso con cámara en puertas/cortes. La reserva es una prueba de colocación X/Z, no un raycast de cámara ni un sweep de un Humanoid. No se aprueba persecución simultánea de dos jugadores solo por revisar estas fórmulas.

## 13. Grounding

Se conserva el contrato `GroundedPlacement` / `SupportY` / `GroundInset` y el traslado global de un stud. En el Play post-fix, `QUALITY_WORLD_REPORT` recoge **557 registros de grounding / 557 mallas apoyadas**, con cero failures/warnings globales: [runtime-initial.json](review/world-expansion-2026-10-01/runtime-initial.json). La comprobación compara el fondo de la caja rotada y soporte declarado; props colgados quedan excluidos. No aprueba todos los triángulos ni cada ángulo.

Las capturas del último mundo ya incluyen muestras de [cementerio](review/world-expansion-2026-10-01/07-old-graveyard.png), [bosque](review/world-expansion-2026-10-01/08-dead-forest.png) y [WidowsOak](review/world-expansion-2026-10-01/10-trees-foliage.png). Son encuadres de inspección en Play, no una barrida física a altura de jugador ni certificación de todo contacto mesh/suelo. Las caminatas del apartado 27 aportan evidencia física de sus trayectos concretos, no de cada rampa o hull del mapa.

Grounding construye una caché débil de soportes solo durante build, con refresh después de terrain/paths y después de sanctuaries; no hace un GetDescendants ni raycasts por frame. Muestrea la cota superior de ellipsoids yaw-only y el hit real sobre el plano de ramps antes de comprobar sus bounds locales. Esto corrige la antigua prueba a Y central, que reducía artificialmente la zona aceptada de una rampa inclinada. `placeGrounded` usa media altura de caja rotada e inset acotado; crypts y props de woodland consultan soporte antes de colocarse. Un muestreo central no garantiza el contacto de toda la base de un mesh irregular; se deja esa limitación explícita para QA visual/física.

## 14. UI

Se mantiene CurrencyCard, Navigation, PanelFrame, iconografía propia y las rutas `SoulsHUD.Card.Amount`, `SoulsHUD.Card.SoulsPerSecond`, `AnimatedSouls`. CURSES muestra `Catalog.AllOrder` completo con nombre, rareza, valores DEV y estado real de producción/rollout. No es un inventario, unlock ni una afirmación de propiedad. SETTINGS sigue siendo una shell honesta.

## 15. Móvil

Las tarjetas mantienen 124 px de altura para landscape corto y 154 px normales. CTAs ahora son **44 px de alto también en portrait**, antes 35 px. En tarjetas estrechas se reduce moderadamente texto/ancho de botón para evitar solaparlo con precio; no se escala toda la UI. Los tres tabs usan PASSES / BOOSTS / SOULS en ancho estrecho.

La UI ya se probó sin cambios de producción en `build-expansion-qa2.rbxlx`: escritorio 1251 × 635, portrait emulado 401 × 777 y landscape emulado 749 × 361, con reports bounds/TextFits sin failures. Hubo clics/drags nativos, tabs, CTA Coming Soon y close. Portrait desplazó SoulPacks y Passes hasta Y=240; landscape desplazó SoulPacks inicio→final hasta Y=141 y Passes final→inicio hasta Y=0. Los intentos Passes landscape inicio→final no fueron fiables y no se aprueban. Resultados/input exactos en [ui-qa2.json](review/world-expansion-2026-10-01/ui-qa2.json), capturas QA2 en [CAPTURES.md](review/world-expansion-2026-10-01/CAPTURES.md) y alcance completo en el apartado 28. Esta evidencia no equivale a teléfono físico, todas las resoluciones/gestos ni FPS/memoria reales; escritorio tampoco certifica fullscreen 16:9.

## 16. Tienda

Tres secciones, **diez previews**: cuatro GAMEPASSES (X2 Souls, Lucky Curses, VIP, Extra Curse Slot), dos BOOSTS (X2 Souls/s, Faster Delivery) y cuatro Soul Packs (Small/Medium/Large/Mega). Todos muestran `TBD` / `COMING SOON`; CTAs solo explican el preview. No hay cantidades de packs, precios de Robux, IDs de producto, remotes de compra ni MarketplaceService.

## 17. Manifest completo

Se añaden **50 conceptos**, no 47: la imagen 10 también contiene Worldroot, The Undertow y The Last Funeral, omitidos en la lista textual. La imagen 13 repite la imagen 5 y no añade duplicados. Total del catálogo: **56**, incluidos los seis originales. `Catalog.Order` mantiene los seis activos; `AllOrder` incluye toda la expansión. Las definiciones nuevas empiezan `enabled = false`, `spawnWeight = 0`; exportar/importar no las habilita automáticamente.

Manifest durable: [curse_expansion_manifest.json](../assets/source/blender/curses_expansion/curse_expansion_manifest.json). Catálogo de datos: [CurseCatalog.luau](../src/shared/CurseCatalog.luau).

| Rareza | Nuevos conceptos |
| --- | --- |
| Common — 15 | Candle Wisp; Grave Hopper; Grave Key; Mourning Ribbon; Wilted Sprout; Ink Imp; Lost Locket; Ashen Book; Lantern Lurker; Hourglass Hound; Nail Beetle; Pale Guest; Cold Teacup; Coin Crawler; Umbrella Wraith |
| Rare — 14 | Marrow Dice; Veil Mourner; Grave Compass; Hollow Violin; Chime Triplets; Thimble Spider; Music Box Dancer; Raven Quill; Sorrow Chalice; Pale Gramophone; Thorn Reliquary; Anchor Crab; Sundial Sentinel; Sleepwalker Shoes |
| Legendary — 10 | Night Harp; Thorn Cathedral; Phantom Marionette; Blood Moon Rose; Judgement Scales; Clockwork Raven; Eclipse Stag; Endless Library; Sunken Crown; Silent Choir |
| Mythic — 6 | Cathedral Heart; Plague Monarch; Hollow Throne; Worldroot; The Undertow; The Last Funeral |
| Secret — 5 | Nameless Door; Crown of Silence; The First Grave; The Unwritten; The Last Star |

Los originales Cursed Doll, Haunted Mirror, Crying Mask, Watching Eye, Soul Chains y The Void permanecen con sus precios, tasa, pesos y orden anteriores.

## 18. Nuevos modelos producidos

Primera ola de **15 modelos Blender/FBX importados**: cinco Common, cuatro Rare, tres Legendary, dos Mythic y un Secret. Se construyen interpretaciones originales de baja complejidad; no se insertan renders planos como modelos. Los quince MeshIds reales están integrados como templates en `ServerStorage.CurseMeshKit`. El manifest tiene 15 entradas `IMPORTED` y 35 `PLANNED`; las quince siguen disabled. Ahora **la apariencia de los 15 está observada en Roblox Play**: siluetas y paletas originales renderizadas en la galería test-only `workspace.ExpansionReviewGallery`, centrada en (500,1,0), fuera del mapa y de `ActiveCurses`, con prompts desactivados. Las capturas se tomaron con cámara de revisión y labels temporalmente ocultos para leer las mallas. Esto no valida labels, el loop natural, compra, entrega ni ingreso de estas Curses; `gameplayValidated` permanece false. Los tres clumps de foliage elevan a **18 los FBX nuevos originales importados**, no a 18 nuevas Curses. Registro y capturas: [curse-wave1-appearance.json](review/world-expansion-2026-10-01/curse-wave1-appearance.json), [galería completa](review/world-expansion-2026-10-01/17-roblox-new-curses.png), [Common](review/world-expansion-2026-10-01/17a-common-close.png), [Rare](review/world-expansion-2026-10-01/17b-rare-close.png), [relics](review/world-expansion-2026-10-01/17c-relics-close.png).

## 19. Modelos restantes

**35 conceptos previstos** todavía sin producción de la primera ola. No se declara completado todo el roster. El manifest distingue PLANNED, EXPORTED, importación real, apariencia y gameplay; no deben colapsarse en un único “completo”.

## 20. Fuentes Blender

`assets/source/blender/curses_expansion/steal_a_curse_expansion_wave1.blend`, `generate_expansion.py`, `validate_expansion.py`, `first_wave_geometry.json`, `first_wave_validation.json` y manifest completo. Las fuentes originales anteriores se conservan. El FBX round-trip verificó un mesh por export, UVs y color por vértice; no certifica por sí solo que el importador de Roblox preserve ese color. La revisión de presentación posterior en Play aporta evidencia visual independiente para los 15 imports de esta ola, sin aprobar gameplay.

Foliage tiene fuente editable `assets/source/blender/foliage_expansion/steal_a_curse_foliage_expansion.blend`, generador/validador originales, `foliage_manifest.json`, README y preview. La fuente reutiliza helpers de geometría propios del proyecto sin sobrescribirlos. Sus closed blades usan un material compartido y centros de bounds; la validación de exportaciones comprobó las tres variantes. Los 15 modelos Curse usan color por vértice SACPaintedColor; los templates Roblox tienen tint blanco para no recolorearlos globalmente. La galería en Play muestra las paletas diferenciadas esperadas: crema/cyan, stone/moss, wood/cyan, ink/bone, violet/gold, blue-gray/red e ivory/gold, entre otras. El manifest marca `robloxAppearanceVerified=true` solamente para esos 15; no asegura equivalencia RGB exacta, todos los ángulos/dispositivos ni rendimiento. Es evidencia de renderizado real de presentación, no una inferencia del round-trip Blender.

## 21. FBXs

Quince archivos bajo `assets/export/meshes/curses/`, uno por ID de la ola. El manifest registra ruta y SHA-256; la auditoría verifica que los archivos reales correspondan a esos registros. Otros tres FBXs están en `assets/export/meshes/foliage_expansion/`, con nombres crescent/tattered/swept y fuentes separadas. En total se añaden 18 exportaciones; ninguna fuente ni FBX del kit recibido fue eliminado. Las dimensiones observadas de foliage en Roblox son aproximadamente 16 × 6 × 10, 14 × 7 × 12 y 15 × 8 × 9; coinciden con el cambio de ejes Blender Z→Roblox Y y escala de exportación 0.01.

## 22. IDs reales Roblox

Los treinta MeshIds originales se retienen. La evidencia de Studio registra 18 imports originales locales, creator Yo, con MeshId/MeshSize/Size observados en Output el 2026-10-01 a las 20:48:51.684 (timestamp local de Studio). La comparación estática de evidencia/manifest/proyecto confirma estos IDs:

| Template nuevo | MeshId real |
| --- | --- |
| candle_wisp | `rbxassetid://131441841706440` |
| grave_hopper | `rbxassetid://111985391427900` |
| grave_key | `rbxassetid://84656327821029` |
| ink_imp | `rbxassetid://104472040658209` |
| ashen_book | `rbxassetid://116088006645241` |
| marrow_dice | `rbxassetid://139995104770981` |
| grave_compass | `rbxassetid://74406539185855` |
| hollow_violin | `rbxassetid://107587916723576` |
| raven_quill | `rbxassetid://107610707886136` |
| night_harp | `rbxassetid://75368579112232` |
| thorn_cathedral | `rbxassetid://83008441866856` |
| judgement_scales | `rbxassetid://127729438322025` |
| cathedral_heart | `rbxassetid://100098877936582` |
| hollow_throne | `rbxassetid://71770033436309` |
| nameless_door | `rbxassetid://91097514366999` |
| foliage_crescent | `rbxassetid://93801806942626` |
| foliage_tattered | `rbxassetid://93606032304189` |
| foliage_swept | `rbxassetid://110491378095483` |

Evidencias durables: [meshes + dimensiones](../assets/imports/world_expansion_2026-10-01.json), [uploads de texturas](../assets/imports/world_expansion_textures_2026-10-01.json), [manifest de foliage](../assets/source/blender/foliage_expansion/foliage_manifest.json) y manifest Curse del apartado 17. Los tres ColorMaps reales se detallan en 11. `playValidated` continúa false en los registros de importación: upload/ID observado no demuestra por sí solo carga, apariencia, permiso efectivo en todos los contextos ni gameplay. La [revisión de galería posterior](review/world-expansion-2026-10-01/curse-wave1-appearance.json) sí confirma formas/paletas visibles para los 15 nuevos Curse MeshIds en esta sesión Play; su metadata de apariencia es independiente del estado `IMPORTED`. No cambia a `VALIDATED`, no habilita spawns ni aprueba el loop de gameplay. No se inventan IDs ni se usa Toolbox; publicar assets no equivale a publicar la experiencia.

## 23. Triángulos

Primera ola: **9,964 triángulos fuente**. FBX reimportado confirmó mismo total, 0 bordes non-manifold, vértices sueltos o caras degeneradas por modelo.

| Modelo | Triángulos |
| --- | ---: |
| Candle Wisp | 758 |
| Grave Hopper | 640 |
| Grave Key | 470 |
| Ink Imp | 586 |
| Ashen Book | 608 |
| Marrow Dice | 880 |
| Grave Compass | 1,116 |
| Hollow Violin | 594 |
| Raven Quill | 358 |
| Night Harp | 520 |
| Thorn Cathedral | 700 |
| Judgement Scales | 730 |
| Cathedral Heart | 818 |
| Hollow Throne | 418 |
| Nameless Door | 768 |

Foliage añade tres mallas únicas: crescent 504, tattered 672, swept 392; **1,568 triángulos**. Total de nueva geometría única de ambos pipelines: **11,532**. No es el total de triángulos instanciados del mapa: las copas se reutilizan muchas veces y tienen su propio coste de draw calls/overdraw. Las dimensiones importadas coinciden con las previstas, pero esos bounds no certifican la exactitud de colisión de cada triángulo.

## 24. Luces y partículas

En `build-expansion-final-review.rbxlx`, sesión Play iniciada el 2026-10-01 a las 22:11:14 local después del fix PluginSecurity de Materials: **13 luces Enabled y un ParticleEmitter Enabled ambientales**, igual que el WIP recibido. Ambos observadores cuentan descendientes del mapa excluyendo `ActiveCurses`; una gallery de presentación fuera del mapa no forma parte del conteo. Evidencia extraída de Output: [runtime-initial.json](review/world-expansion-2026-10-01/runtime-initial.json). Es un conteo del entorno, no un benchmark de FPS ni memoria.

## 25. BaseParts / MeshParts

El mismo Play registra **4,233 BaseParts, de las cuales 764 son MeshParts**, y **339 hulls** etiquetados. Frente al WIP recibido (3,395 / 530 / 289), aumenta en 838 BaseParts, 234 MeshParts y 50 hulls. No se suman BaseParts + MeshParts: estas últimas son un subconjunto. Los observadores excluyen `ActiveCurses`, y sus conteos coinciden.

`QUALITY_WORLD_REPORT` también registra 805 partes colisionables, 557 mallas con grounding, 24 MeshIds únicos del entorno y categorías de 192 mallas Blocking / 462 Soft / 110 NonBlocking. Los 339 hulls son un subconjunto de las 805 partes colisionables, no todos los sólidos. Los 24 IDs instanciados en entorno no son el número de templates retenidos/importados del proyecto. El total ambiental queda por debajo del objetivo de 4,500 partes; sigue habiendo aumento de render cost y no se declara rendimiento móvil aprobado. Datos completos y 557 registros de apoyo: [runtime-initial.json](review/world-expansion-2026-10-01/runtime-initial.json).

## 26. Regresión gameplay

En la sesión post-fix documentada, `QUALITY_WORLD_REPORT` tiene **cero failures y cero warnings**: ocho sitios/contratos, cuarenta slots, 557 records de apoyo, hulls y ocho rutas navmesh al castillo con `Success`. Son contratos/bounds y planificación, no ocho caminatas físicas ni aprobación visual de todos los meshes.

`EXPANSION_REPORT` termina con **phase=passed**, **110.1856 s observados**, cero failures/warnings, siete modelos observados y siete emergencias desde el castillo, máximo seis simultáneos y una salida natural unsold. Ruta 16 puntos / 15 segmentos / 636.6768 studs; 2,316 muestras, sin solidBoundsCandidates, visualTreeBoundsCandidates ni segmentos sin soporte. El catálogo runtime contiene 56 entradas, con 15 nuevos templates IMPORTED disponibles y 35 PLANNED; los nuevos siguen disabled. Esta evidencia aprueba el observador de procesión/contratos, no el ciclo de compra/entrega ni exact triangle clearance.

Después de esa observación inicial se completó un ciclo con una **Cursed Doll aparecida naturalmente**: claim Base08 por E nativa, ida física al castillo, compra a distancia válida mediante `ProximityPrompt.InputHoldBegin/End` acotado en cliente, **500 → 400 Souls**, transporte de vuelta, entrega en el pedestal de Base08 y **+3 Souls/s**. `NATURAL_BUY` registra 400 Souls / tasa 0 a las 22:28:32.788; `QUALITY_UI_RATE_PASS 3` registra la tasa tras entregar a las 22:30:43.583. No se otorgó crédito, se teletransportó al personaje ni se forzaron estados/eventos de servicio. Es una prueba de producción con input del prompt y caminata asistidos, no una compra realizada íntegramente con controles manuales. Evidencia: [gameplay-return.json](review/world-expansion-2026-10-01/gameplay-return.json), [compra](review/world-expansion-2026-10-01/gameplay-01-natural-purchase.png) y [pedestal tras entregar](review/world-expansion-2026-10-01/gameplay-02-delivered-pedestal.png).

`purchasedModels=0` en `runtime-initial.json` corresponde a la ventana inicial de 110 s, anterior a esa compra; no contradice el ciclo posterior. El 2026-10-02 se ejecutó una suite aislada fresca en `build-slice-tests.rbxlx`, posterior al último cambio de producción, y terminó **SLICE_DONE a las 00:02:29.631 local: 44 SLICE_PASS, ningún SLICE_FAIL registrado**. Incluyó compra sin base/insuficiencia rechazada, claim/respawn Base07, compra 500→400, ninguna producción antes de entrega, una entrega simultánea, retorno físicamente caminando/pedestal/+3, ingreso acumulado, cinco slots únicos/HUD222, base llena, pérdida de pedestal, refunds por display ausente/muerte, respawn y restauración sin duplicar ingresos, Void/tasa822 y escala/no-colisión/glows frontales de los seis originales. Evidencia: [slice-final.json](review/world-expansion-2026-10-01/slice-final.json) y [Output final](review/world-expansion-2026-10-01/slice-final-pass.png).

El fixture aislado usa prompts reales en cliente y prepara setup/teleports/crédito para los casos extremos; solo su primer retorno usa caminata física. Está excluido de `default.project.json` y se distingue del ciclo natural anterior sin teleport/crédito. BaseService, CurseService y SoulsService permanecen estáticamente iguales a `6b9891d`. La suite es single-client: no aprueba carreras de dos jugadores, integración de disconnect, todas las rutas ni gameplay de las Curses nuevas disabled. No se modificó producción para hacer pasar la suite. Las sesiones de revisión/pruebas quedaron detenidas sin guardar cambios de Play ni publicar la experiencia.

Evidencia: [runtime-initial.json](review/world-expansion-2026-10-01/runtime-initial.json). El `REVIEW_SUMMARY` incluido se tomó en contexto cliente: `world.available=false` / `expansion.available=false` allí no son fallos del servidor ni invalidan los reports server separados; sus globals no se comparten.

## 27. Tiempos de desplazamiento

`FINAL_WALK_RESULT` del mismo Play registra **Base08 entry → castle court en 20.8321 s de caminata real**, a WalkSpeed16, `reached=true`, `canceled=false`, cero saltos y cero jump waypoints. Planificación separada: 0.2747 s; total de la operación: 21.1070 s. Distancia recorrida muestreada: 282.34 studs; longitud de la ruta planificada: 283.26. Destino (0,4,24), distancia horizontal restante 0.648 studs. El helper test-only usa Pathfinding + Humanoid:MoveTo sobre un personaje físico normal, sin teleport ni cambio de velocidad; es una caminata asistida, no input manual ni una estimación distancia/16.

La vuelta **castle court → Base08 display court llevando la Cursed Doll** alcanzó el destino en **22.9647 s de caminata real**, WalkSpeed16, `reached=true`, `canceled=false`, cero saltos físicos. Distancia real muestreada: **313.36 studs**; ruta planificada: 314.37; planificación: 0.0497 s, separada del total 23.0146 s. Había un jump waypoint planificado, pero el personaje no saltó: número de navlinks y saltos físicos no son lo mismo. Distancia horizontal restante 0.683 studs. Ida y vuelta completas: [gameplay-return.json](review/world-expansion-2026-10-01/gameplay-return.json); la ida también está en [runtime-initial.json](review/world-expansion-2026-10-01/runtime-initial.json).

En un Play fresco de **`build-expansion-qa2.rbxlx`**, iniciado a las 23:11 local y registrado a las 23:15 del 2026-10-01, se completaron otros dos trayectos a WalkSpeed16, sin teleport, cambios de velocidad ni geometría:

- **Vecinas Base01 court → Base02 court:** 15.0830717 s de caminata real / 237.337467 studs muestreados, `reached=true`, cero saltos físicos. Ruta planificada 240.55 studs, planificación separada 0.1160 s; dos jump waypoints previstos. Distancia horizontal final al destino: 2.408 studs.
- **Cruce Base02 court → Base06 court:** 42.9655188 s de caminata real / 686.035568 studs muestreados, `reached=true`, cero saltos físicos. Ruta planificada 686.65 studs, planificación separada 0.2652 s; un jump waypoint previsto. Distancia horizontal final: 1.315 studs.

La preparación Base01 spawn/entry → Base01 court también llegó: 1.8003352 s / 28.9465 studs, pero es un movimiento de preparación, **no una quinta categoría ni el trayecto entre vecinos**. Los tres legs QA2 tienen `pathStatus=Success`, `canceled=false` y cero saltos físicos. La nueva versión del helper registra la señal `MoveToFinished` y admite llegada de waypoint dentro de 3 studs horizontales / 5 verticales; estos legs completaron por tolerancia, con cero `moveToFinishedArrivals`. Por ello `reached` no significa contacto exacto con el centro del marcador. Producción no cambió desde el fix de Materials; se corrigió solo el harness test-only. Evidencia completa: [travel-qa2.json](review/world-expansion-2026-10-01/travel-qa2.json).

Se conserva separado el intento anterior **Base08 court → Base01 court**, que quedó en timeout del helper cerca de (-48,295). Los overlaps inspeccionados allí no encontraron un obstáculo aparte del suelo/personaje; su causa sigue sin confirmarse y no se atribuye a terreno, árboles o geometría. El helper anterior ignoraba `MoveToFinished` y exigía llegada X/Z ≤1.15 studs. QA2 aprobó otra conexión vecina, **no repitió ni aprobó esa misma ruta fallida**; no justifica retirar props o alterar el mapa.

Las cuatro categorías solicitadas cuentan ahora con una muestra física documentada: Base08 → Castillo, Castillo → Base08, Base01 → Base02 y Base02 → Base06 cruzando mapa. Siguen pendientes más bases/rutas, la ruta fallida exacta y persecución entre jugadores. Estas muestras asistidas no garantizan todos los accesos laterales ni toda cámara. Los ~16 s del rework anterior son históricos y no se aplican como resultado de esta expansión.

## 28. Escritorio / móvil

La ejecución real de **`build-expansion-qa2.rbxlx`** probó escritorio y ambas orientaciones del emulador mediante clics, rueda y drags nativos. `QualityUI` observó bounds/TextFits y eventos reales SelectedTab/CanvasPosition/Activated; los reports recogidos tienen **`failures=[]`**. No programa botones ni cambia canvas/viewport/atributos. No se modificó la UI de producción durante esta ejecución QA2. Evidencia de input y eventos: [ui-qa2.json](review/world-expansion-2026-10-01/ui-qa2.json); imágenes relacionadas: [CAPTURES.md](review/world-expansion-2026-10-01/CAPTURES.md).

| Entorno / viewport | Resultado observado |
| --- | --- |
| Escritorio — 1251 × 635 | HUD y navegación; SHOP con sus tres tabs, CTA Coming Soon y close; CURSES abierto, scroll con rueda nativa y cierre; SETTINGS abierto/cerrado. |
| Portrait emulado — 401 × 777 | HUD/navegación, tres tabs y close. Drags nativos desplazaron SoulPacks y Passes desde el inicio hasta Y=240; SoulPacks rebotó 0→275.1884→240 y Passes aproximadamente 0→276.4136→240. Se activó el CTA de Mega Soul Pack sin compra. |
| Landscape emulado — 749 × 361 | HUD/navegación, tres tabs, CTA Coming Soon y close. SoulPacks se desplazó inicio→final, 0→152.0335→141, a las 23:42:57. Passes volvió final→inicio, 139.3523→−10.7374→0, a las 23:43:53. CURSES y SETTINGS se abrieron/cerraron nativamente entre 23:48:59 y 23:49:52. |

Los valores negativos o superiores al final incluyen rebote elástico observado, no un canvas fijado por scripts. Se aprueban **solo esas interacciones registradas**: en Passes landscape se verificó final→inicio, pero los intentos inicio→final no registraron movimiento de forma fiable y **no se consideran aprobados**. Otros intentos de wheel/drag o clicks sobre el scrollbar que fallaron o no dejaron evento tampoco cuentan como éxito. No se atribuye su causa a producción sin aislar el hit-target del input.

El emulador no sustituye un teléfono físico, toda resolución, accesibilidad ni mediciones de FPS/memoria. El viewport de escritorio 1251 × 635 **no es una certificación fullscreen 16:9**. Los reports geométricos sin fallos y las capturas no certifican todos los gestos ni rendimiento móvil. La tienda conserva previews/TBD/Coming Soon y no ejecuta compras; la exclusión de APIs/IDs de compra sigue comprobándose por la auditoría estática, no solo por pulsar un CTA.

## 29. Riesgos de rendimiento

Más superficie, árboles y arte pueden subir coste de partes, transparencia, memoria de texturas y draw calls. El observador de expansión es test-only y su muestreo no forma parte del build de producción. Se mantienen mallas reutilizadas, hulls simples y geometría ambiental anclada. No hay todavía medición de FPS/memoria en hardware móvil real.

Límites de fuente: hasta 128 árboles de woodland y hasta 640 piezas de SurfaceArt (antes 780); son máximos de esos subsistemas, no un presupuesto total demostrado. Las nuevas hojas comparten tres templates; materiales usan tres variantes/texturas reutilizadas y no nuevos PointLights/ParticleEmitters por prop. Grounding queda restringido a construcción. Se debe contrastar el total real de parts y el uso de memoria con los apartados 24–25 y hardware; un límite de candidatos no demuestra buen rendimiento.

## 30. Limitaciones conocidas

Importación de 18 meshes y tres texturas observada e integrada. El arranque post-fix, contratos/grounding y observación de procesión de 110.1856 s ya tienen evidencia runtime, junto con un ciclo de la Doll original y cuatro categorías de caminata física asistida; no quedan pendientes de forma general. El alcance exacto está en los apartados 24–27. No se convierte ese muestreo en aprobación de todas las rutas, cámaras o geometría.

La primera ola **15/50** también tiene evidencia de apariencia real en Roblox: las cuatro capturas de la galería estacionaria test-only muestran las 15 siluetas y paletas diferenciadas, con veredicto `APPEARANCE_PRESENTATION_OBSERVED` en [curse-wave1-appearance.json](review/world-expansion-2026-10-01/curse-wave1-appearance.json). Eso no demuestra RGB exacto, todos los vértices/ángulos/dispositivos ni labels, que se ocultaron temporalmente para inspeccionar meshes. Los registros originales de importación conservan `playValidated=false`; la verificación de apariencia más acotada queda en evidencia separada.

Esos 15 modelos permanecen **IMPORTED**, `enabled=false`, `spawnWeight=0`, `gameplayValidated=false` y `playValidated=false`: no se probaron su spawn natural, movimiento, compra, entrega o ingreso. El HUD +3 Souls/s corresponde a la Doll original, no a la galería. Los otros **35 permanecen PLANNED**, sin IDs ficticios. Ninguna Curse nueva se activa por tener un mesh y no se declara un roster entero listo para producción.

Bounding boxes y soporte central no sustituyen inspección de triángulos/ergonomía física. El timeout del intento Base08 → Base01 sigue sin causa confirmada; los overlaps revisados no mostraron un obstáculo y QA2 aprobó otra ruta vecina, no una repetición de aquella. Las distancias rectas a castillo son similares entre bases, pero la ruta irregular hace desigual su distancia al punto de compra más cercano; las cuatro muestras cronometradas no aprueban equidad entre las ocho bases ni persecuciones. No hay carrera simultánea de dos clientes ni FPS/memoria de hardware móvil real aprobados; tampoco se añadieron stealing, mutaciones, DataStore, quests, NPCs o monetización real. Los labels de mundo existentes se conservan y no se garantiza cero oclusión en toda cámara. Upload de PNG no demuestra seamless ni color perfecto; el arranque de Materials y el round-trip FBX tampoco certifican esos aspectos visuales por sí solos.

## 31. Comprobaciones humanas recomendadas / capturas

El [índice de las 17 categorías de capturas](review/world-expansion-2026-10-01/CAPTURES.md) ya está completo: archivos existentes/decodificados, dimensiones y MIME comprobados, variantes móviles, acercamientos de modelos y cuatro capturas nuevas de input QA2. Estas últimas acompañan scroll nativo portrait y SoulPacks landscape; Passes landscape final→inicio también tiene evento registrado, pero no se aprueba su gesto inicio→final ni otros intentos sin movimiento fiable. Contrastar el índice con [ui-qa2.json](review/world-expansion-2026-10-01/ui-qa2.json) y el apartado 28, sin convertir imágenes o bounds en aprobación universal de input.

La imagen 16 es un render de Blender, no una captura de su interfaz. Las capturas de Studio conservan extensión `.png`, aunque su MIME real es JPEG; no se editaron ni convirtieron para el índice. La galería Roblox test-only ya permite revisar la apariencia de 15 modelos, pero no habilita ni valida su gameplay. Las imágenes 07/08/10 muestran cementerio, siluetas de bosque y anclaje/paleta de WidowsOak; no sustituyen barridas de toda cámara ni inspección de todos los triángulos.

Comprobaciones adicionales recomendadas: realizar el ciclo sin asistencia, probar teléfono físico y persecuciones con otra persona; contrastar puertas, troncos, grandes rocas, rampas laterales y pedestales contra personaje/cámara estándar; recorrer todas las curvas/salida de la procesión y revisar los demás clumps/landmarks desde más ángulos. Son ampliaciones de cobertura, no una afirmación de que faltan todas las capturas o todos los gestos del pase actual.

## 32. Git / comandos / estado de cierre

Los cambios siguen locales para revisión. **No commit, push, merge ni publicación de experiencia.** Al cierre, HEAD sigue `6b9891d9cf7ec07ec14c4934392a2229ffa44367` y la rama `feature/final-map-polish-v2`. Snapshot del 2026-10-02: 26 archivos tracked modificados, 90 archivos untracked enumerados individualmente, cero staged y cero eliminaciones tracked. No se declara un árbol limpio. Assets subidos son los originales del proyecto; publicar esos assets autorizados no equivale a publicar la experiencia.

```powershell
rojo build default.project.json --output build-world-expansion.rbxlx
rojo sourcemap default.project.json --output build-world-expansion.sourcemap.json
pwsh -NoProfile -File .\tests\Audit-Expansion.ps1
pwsh -NoProfile -File .\tests\Build-StudioFixture.ps1 -Expansion
pwsh -NoProfile -File .\tests\Build-StudioFixture.ps1
git diff --check
```

La auditoría final se repitió después de importar e integrar assets: build Rojo, sourcemap, `Audit-Expansion.ps1` con PowerShell7.6.5 y `git diff --check` terminaron exit0. Confirmó 30 plantillas originales completas y seis definiciones originales preservadas, tres servicios core sin cambios, 50 conceptos nuevos (15 IMPORTED/35 PLANNED, todos disabled), 15 exports con 9,964 triángulos, 18 MeshIds/dimensiones y tres MaterialVariants/ColorMaps coincidentes con evidencia real. Sin purchase APIs ni entrypoints de prueba en producción. Comandos, hashes y alcance: [static-final.md](review/world-expansion-2026-10-01/static-final.md). Los avisos LF→CRLF no son errores de diff.

El arranque completo post-fix de Materials, observación natural `EXPANSION_DONE`, compra/entrega/ingreso de la Doll, cuatro categorías de caminata, UI QA2 y suite aislada `SLICE_DONE` están documentados en 24–28; las 17 categorías de capturas tienen archivos reales. La suite final y el cotejo documental no cambiaron producción después de ese ciclo. Se cierra este pase escalonado, no las limitaciones de 30: quedan 35 modelos por producir, rollout/gameplay de nuevos modelos, hardware móvil/multijugador y rutas/cámaras adicionales. En particular, desktop1251×635 no certifica16:9 y Passes landscape inicio→final no quedó aprobado. Ningún estado PLANNED/IMPORTED se convierte en VALIDATED por cerrar el informe.
