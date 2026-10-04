# Steal a Curse: expansión visual de 50 Curses

> **Informe histórico de la primera pasada.** El estado visual vigente, incluidos los seis originales ahora rediseñados, está en [la segunda pasada](CURSE_VISUAL_PASS2.md). Archivo actual: `build-curse-visual-pass2.rbxlx`.

Informe final de revisión local, 2 de octubre de 2026. **Las cincuenta nuevas Curses están modeladas, importadas, comprobadas y habilitadas localmente**, con los seis originales conservados. Hay informes completos de ruta, cincuenta compras/entregas y VFX, carga en escritorio/móvil simulado, Quality del mapa habilitado y observación de la procesión natural; también cinco vistas reales de presentación por rareza y el catálogo final de 56 en la interfaz. El [anexo de las cincuenta](CURSE_EXPANSION_50_REWORK_STATUS.md) contiene nombres, etapas, fuentes, MeshIds, medidas y evidencia individual. El [registro de progreso](../assets/curse-expansion-progress.json) conserva la trazabilidad del FBX actual por SHA256.

## 1. Rama y estado inicial

Se continuó en `feature/final-map-polish-v2`, desde HEAD `21dbc52`. El árbol inicial no tenía cambios en archivos seguidos; `assets/reference/` ya estaba sin seguimiento, aportado por el usuario. Se conservaron las referencias anteriores y las exportaciones de la primera tanda. Blender verificado: **5.2.2 LTS**, en `C:/Program Files/Blender Foundation/Blender 5.2/blender.exe`.

El trabajo permanece local. Las importaciones de las cincuenta mallas nuevas/reconstruidas mediante el importador 3D de Studio están registradas; la experiencia no se ha publicado. No se ha hecho commit, push ni merge.

## 2. Cantidades y nombres por etapa real

El catálogo contiene **50 nuevas Curses + 6 originales = 56**. Se usaron las doce hojas actuales `rework-*`: **15 Common, 14 Rare, 10 Legendary, 6 Mythic y 5 Secret**, incluidos Worldroot, The Undertow y The Last Funeral. Sus nombres y estados individuales aparecen en el [anexo](CURSE_EXPANSION_50_REWORK_STATUS.md#estado-y-nombres-exactos).

| Etapa | Cantidad registrada |
| --- | ---: |
| Planificadas en el catálogo | 50 |
| Referencia actual revisada | 50 |
| Modelo Blender terminado | 50 |
| Validación local del FBX | 50 |
| FBX exportado | 50 |
| Importación real en Roblox registrada | 50 |
| Apariencia revisada en Studio | 50 |
| Ruta completa con tiempos de producción | 50, PASS independiente |
| VFX comprobado en Play | 50 |
| Gameplay validado para el modelo actual | 50 |
| Habilitadas localmente para aparición normal | 50 |

No quedan Curses pendientes en las nueve etapas del registro. La comprobación de apariencia revisó el frente y la parte posterior de las importaciones actuales, con su pintura de vértices visible. La habilitación se aplicó después de reunir las evidencias de cada fase: [activación local](../assets/review/curse-rework/local-activation.json) y [2.148 comprobaciones de elegibilidad](../assets/review/curse-rework/verification-eligibility.json). Los [metadatos observados en la ejecución habilitada](../assets/review/curse-rework/normal-gallery-metadata-current-source-observed.json) confirman **56 definiciones habilitadas y 50 templates importados actuales**.

## 3. Modelos creados y reconstruidos

**Los quince modelos iniciales se reconstruyeron y reimportaron; se crearon otros treinta y cinco.** Los quince FBX actuales tienen hashes distintos de sus exportaciones históricas. Hay **50 fuentes `.blend` de modelo y 50 FBX individuales**, además de dos escenas Blender agregadas de revisión y tres lotes FBX de importación; estos agregados no cuentan como Curses adicionales. Cada modelo tiene validación de reimportación; sus rutas exactas están en la [tabla de fuentes](CURSE_EXPANSION_50_REWORK_STATUS.md#fuentes-editables-fbx-y-perfiles-de-efectos).

Las superficies incorporan pintura de vértices con variación de tonos, bordes y desgaste según el material, con UV conservadas. La geometría incluye volúmenes curvos, huecos reales, relieves y detalles propios de cada concepto: la bocina abierta de Pale Gramophone, las extremidades de Thimble Spider, la anatomía vegetal de Worldroot y la forma suspendida de The Last Funeral, entre otros. Se diseñaron y revisaron las caras posteriores.

Fuentes y herramientas reproducibles: [carpeta Blender actual](../assets/source/blender/curses_expansion/rework/), [FBX actuales](../assets/export/meshes/curses/rework/), informes [Common](../assets/source/blender/curses_expansion/rework/common_geometry.json), [Rare](../assets/source/blender/curses_expansion/rework/rare_geometry.json) y [raridades altas](../assets/source/blender/curses_expansion/rework/high_geometry.json). Los modelos anteriores permanecen como evidencia histórica.

## 4. MeshIds, medidas y materiales reales

Las **50 importaciones actuales** tienen MeshIds observados y medidas `Size`/`MeshSize` registradas en Studio. Los tres lotes contienen 15, 14 y 21 componentes separados. Cada registro vincula el ID al hash del lote y del FBX individual; modificar la geometría exige una importación y revisión nuevas.

La [tabla de importaciones](CURSE_EXPANSION_50_REWORK_STATUS.md#meshids-y-medidas-realmente-observadas) muestra los cincuenta IDs y tamaños. Por ejemplo, Candle Wisp usa `rbxassetid://120691798070914`, con `Size` observado **2.5200 × 3.9259 × 1.6050 studs**; Pale Gramophone usa `rbxassetid://94119998367472`, **3.3487 × 4.1044 × 2.7654 studs**. El segundo corresponde al lote final, no a su importación de prototipo.

**TextureID vacío en los cincuenta:** sus colores pintados viajan en la geometría y se verificaron en Studio. No se ha registrado una textura subida inexistente. Fuente primaria: [registro de importaciones y revisión visual](../assets/imports/curse_rework_2026-10-01.json).

## 5. VFX implementados y comprobación real

Se implementaron **50 perfiles por concepto** en [CurseVFXProfiles.luau](../src/shared/CurseVFXProfiles.luau) y un controlador compartido [CurseVFX.luau](../src/client/CurseVFX.luau). Incluyen llama azul, tinta, arena, luz verde atrapada, polvo, vapor, resonancia y movimientos discretos como pasos, pulsación o balanceo. El [mapa actual de efectos](../assets/review/curse-rework/vfx-semantic-mapping.md) documenta cincuenta puntos principales y veintisiete puntos adicionales, con ubicación focal y movimiento por concepto, incluidos bocina/plato del gramófono y las tres campanas.

El controlador usa partículas integradas de Roblox y limita emisiones por distancia. Presupuestos implementados: hasta **20 emisores activos en escritorio / 12 en modo táctil**, actualización de movimiento hasta 20 Hz, y hasta **2 luces cercanas adicionales en escritorio**, sin estas luces en modo táctil. Thorn Reliquary incorpora cuatro paneles finos de vidrio sin colisión para conservar su identidad de urna.

**Comprobación actual: PASS para las cincuenta.** El [informe móvil completo](../assets/review/curse-rework/purchase-stress-mobile-current-source-observed.json) conserva **100 ventanas de observación de al menos 4,2 s**, una en `DELIVERING` y otra en `PLACED` por Curse: emisores nativos, focos, movimiento/pulsación, puntos semánticos y etiquetas. Incluye las cuatro láminas de vidrio de Thorn Reliquary. El [informe escritorio](../assets/review/curse-rework/desktop-stress-current-source-observed.json) repitió compra y revisión para Candle Wisp, Pale Gramophone, Thorn Cathedral, Cathedral Heart y The Last Star, una por rareza; no se presenta como cincuenta compras adicionales.

Ambos informes aprobaron la convivencia de 46 modelos y sus límites por distancia; las métricas están en el punto 8. Las capturas de contexto [Candle Wisp](../assets/review/curse-rework/candle-wisp-placed-avatar-context-desktop.jpg) y [Thorn Cathedral](../assets/review/curse-rework/thorn-cathedral-placed-avatar-context-desktop.jpg) son de escritorio y muestran parte del modelo tapada por el avatar. Se conservaron con nombres y alcance honestos; las cinco vistas despejadas actuales están enlazadas en el punto 8.

## 6. Escala y resultados de gameplay

Los tamaños importados varían según el concepto; no se aplicó un multiplicador uniforme. Las diagonales observadas abarcan **3.5869–6.3856 studs**, por debajo del límite geométrico de 7. Los cincuenta suman **158.836 triángulos**; este total del catálogo no representa la carga simultánea de una partida. La auditoría vincula tamaños, colores, UV, topología y hashes a los FBX reimportados y las observaciones de Studio.

Se conservó la economía y los sistemas compartidos: las nuevas Curses usan el catálogo de precios, ingresos e interacción. La integración conserva los seis modelos originales. La [regresión de las seis originales](../assets/review/curse-rework/original-six-regression.txt) llegó a `SLICE_DONE` y quedó guardada por separado. El [auditor estático](../tests/check_curse_rework.py) compara las fuentes actuales, los IDs y los contratos existentes; no sustituye pruebas de movimiento o compra.

**Ruta actual: PASS completo.** El [informe íntegro de Studio](../assets/review/curse-rework/route-current-source-observed.json), correspondiente al fixture construido a las `05:39:55.6129205Z`, contiene las cincuenta filas con sus MeshIds/hashes actuales y treinta y seis fingerprints de las fuentes cargadas. Se mantuvieron los **16 puntos, 15 segmentos, 636,6768 studs, velocidad 6,5 studs/s, retraso inicial 3 s y cadencia 10 s**. La selección fue determinista para cubrir el catálogo; el movimiento y la salida usaron los servicios de producción. Alcanzó seis modelos activos simultáneos, el máximo configurado.

Los cincuenta completaron todos los segmentos, permanecieron en estado de procesión antes de salir y desaparecieron del estado al final. Tiempos individuales: **97,877–98,025 s**; error lateral máximo muestreado **0,00001706 studs**; distancia máxima al extremo antes de retirar el modelo **0,5441 studs**. El informe tiene `phase=passed`, `completed=50` y `failures=[]`. Esto comprueba la ruta de las Curses, no todos los ángulos de cámara ni un paseo humano por cada tramo.

**Compra/entrega actual: PASS para las cincuenta.** El [informe móvil íntegro](../assets/review/curse-rework/purchase-stress-mobile-current-source-observed.json) tiene `phase=passed`, `purchase.completed=50`, cincuenta filas `PASS` y `failures=[]`. En Base07 verificó el precio cobrado, entrada real del `ProximityPrompt`, seguimiento fuera del santuario, ausencia de ingreso nuevo mientras se transporta, colocación en pedestal, suma de producción y acumulación de Souls, además de etiquetas y VFX en ambos estados. El informe de escritorio aprobó las cinco repeticiones por rareza citadas arriba.

Es una suite automatizada de un cliente: usa crédito y teleports de preparación, la API real `InputHoldBegin/InputHoldEnd` del prompt y limpieza entre grupos de cinco slots. No se describe como cincuenta compras táctiles manuales, ocho clientes simultáneos o cincuenta recorridos humanos. La ruta completa usa el movimiento y los tiempos de producción. Los [escenarios de servidor](../tests/CurseRework.server.luau), [cliente](../tests/CurseRework.client.luau) y [constructor](../tests/Build-CurseReworkFixture.ps1) conservan esas fases separadas. Los reportes antiguos recortados son trazas históricas parciales y no sustituyen los JSON completos actuales.

**Procesión natural del catálogo habilitado: observada durante 62,03 s.** El [informe final de Workspace](../assets/review/curse-rework/normal-weighted-procession-observed.json) guarda doce muestras, diez UIDs de ocho conceptos y cuatro llegadas posteriores a la primera muestra. Hubo entre cinco y seis ofertas nativas; todas estaban en `PROCESSION`, con los MeshIds/hashes actuales comprobados. Se observaron cinco nuevas —Lantern Lurker, Nail Beetle, Lost Locket, Mourning Ribbon y Raven Quill— y tres originales —Haunted Mirror, Watching Eye y Cursed Doll—. Los cinco clones de galería quedaron excluidos de todas las muestras.

El observador fue de solo lectura: no forzó selección, compras, saldo, cámara o movimiento del jugador. Nueve trayectorias con varias muestras dieron velocidades medias derivadas **6,4851–6,5098 studs/s** y error lateral máximo **0,00000661 studs**. Los tiempos y posiciones nativos se conservan; los intervalos estimados entre llegadas fueron 9,9503, 10,0839 y 9,9745 s. Son estimaciones a partir de progreso, con la incertidumbre de los pasos de producción de 0,08 s, no eventos de spawn capturados directamente. Esta muestra acredita apariciones naturales de los ocho conceptos listados, mientras la cobertura individual de las cincuenta pertenece a las suites completas. La comparación final de las 29 fuentes de producción no detectó cambios.

## 7. Mundo, castillo, ruta, vegetación, luces y UI

El pulido usa dos archivos: [HalloweenArt.luau](../src/server/Map/HalloweenArt.luau) y [WorldPolish.luau](../src/server/Map/WorldPolish.luau), integrado por [Build.luau](../src/server/Map/Build.luau). Se compuso la entrada del castillo con árboles originales, jardines bajos, calabazas, faroles, cadenas y ofrendas sobre las cornisas. Se añadieron pequeños grupos de hierba, hojas caídas y raíces en los bordes del cementerio y el bosque, usando meshes ambientales verificados y materiales existentes.

Los elementos se apoyan en la altura del suelo de cada posición; se corrigió el cálculo de apoyo de calabazas, velas y carteles de Halloween. Los carteles tienen lectura en ambas caras. Los grupos evitan las áreas reservadas de rutas y santuarios y sus adornos no crean colisiones.

| Elemento | Presupuesto | Observado |
| --- | ---: | ---: |
| WorldPolish: BaseParts | 214 | 178 |
| WorldPolish: MeshParts | Dentro de las 214 partes | 139 |
| WorldPolish: luces adicionales | 2 | 2 |
| WorldPolish: partes con colisión | 0 | 0 |
| WorldPolish: templates verificados ausentes | 0 | 0 |
| HalloweenArt: meshes pequeños de sotobosque | 60 | 60 |

El [informe de ruta actual](../assets/review/curse-rework/route-current-source-observed.json) también contiene la comprobación acotada de WorldPolish: **131 meshes con metadatos de apoyo**, sin metadatos ausentes y con error máximo de límite de apoyo **0,00000187 studs**, estado `PASS`. Los elementos colgados se revisan bajo su condición de decoración suspendida. El código de estos dos módulos no añade emisores.

El [Quality íntegro del mapa habilitado](../assets/review/curse-rework/quality-normal-current-source-observed.json) registró **4.471 BaseParts, 963 MeshParts, 748 meshes con apoyo, 339 hulls de colisión, 805 partes con colisión, 15 luces, 1 emisor y 24 MeshIds ambientales distintos**. Tiene `failures=[]` y `warnings=[]`; incluye ocho santuarios, cuarenta slots y **ocho caminos navmesh Success**. La separación mínima observada entre centros de santuarios es 202,8719 studs. Estos recuentos del ambiente no incluyen las cinco piezas de la galería ni se presentan como un coste por fotograma.

El castillo conserva su arquitectura y tiene [captura real de la entrada](../assets/review/curse-rework/world-castle-desktop.jpg). Esta pasada conserva el tamaño existente **820×800**, la procesión que rodea el castillo y los ocho santuarios. Se mantuvo la distribución del HUD y se integró el controlador cliente de VFX en la inicialización existente. El Quality final se recuperó íntegro: **120.270 bytes del JSON nativo en dos partes de generación 1**, con comprobación de tamaño/generación y publicación completa, junto con la proveniencia de la misma ejecución habilitada. Los informes anteriores recortados se conservan como históricos. Los caminos navmesh y los límites de apoyo no se presentan como una prueba de recorrido físico de todos los jugadores.

## 8. Capturas, verificaciones y rendimiento

La revisión visual de Studio está documentada en [studio-appearance-review.json](../assets/review/curse-rework/studio-appearance-review.json), con **once grupos vistos de frente y por detrás**. Los enlaces exactos de cada Curse apuntan a las capturas `.jpg` actuales en el [anexo de evidencia](CURSE_EXPANSION_50_REWORK_STATUS.md#evidencia-por-curse). Las vistas de Blender prueban la geometría modelada: [Common](../assets/source/blender/curses_expansion/rework/common_contact_sheet.png), [Rare](../assets/source/blender/curses_expansion/rework/rare_gallery.png), [Rare posterior](../assets/source/blender/curses_expansion/rework/rare_gallery_rear.png), [Legendary](../assets/source/blender/curses_expansion/rework/high_legendary_preview_sheet.png), [Mythic](../assets/source/blender/curses_expansion/rework/high_mythic_preview_sheet.png) y [Secret](../assets/source/blender/curses_expansion/rework/high_secret_preview_sheet.png).

La [auditoría estática después de habilitar](../assets/review/curse-rework/static-audit.json) de `06:34:06.456438Z` registra **3.079 comprobaciones aprobadas, cero fallidas**, las nueve etapas con cincuenta aprobaciones, catálogo de 56 y preservación de las seis originales. Las validaciones Blender por familia/lote están enlazadas en el registro. Las pruebas actuales conservan JSON íntegros; la publicación en StringValues por partes evita el límite de tamaño de la consola y de un valor único. La extracción móvil preservó 246.493 bytes del JSON nativo, generación 69; la de escritorio, 107.911 bytes, generación 24, verificando publicación estable, generación y tamaños. El archivo envolvente de evidencia puede ocupar más bytes que el JSON nativo.

**Carga simultánea: PASS en ambos contextos.** Cada ensayo usó seis ofertas de producción y cuarenta clones de presentación, **46 modelos con VFX nativos**. Esos cuarenta clones no añaden propiedad lógica ni ingresos: ambas observaciones registran `ownedDisplaysAdded=0` y `earnedIncomeFromPresentation=0`. Se midieron aproximadamente quince segundos cerca y quince lejos mediante `RenderStepped`, con el coste del observador incluido.

| Contexto / cámara | Emisores activos máximos | Luces activas máximas | P95 de intervalo de frame | Frames >33 / >50 ms | Resultado |
| --- | ---: | ---: | ---: | ---: | --- |
| Escritorio, cerca | 20 | 2 | 20,897 ms | 1 / 0 | PASS |
| Escritorio, lejos | 0 | 0 | 19,915 ms | 0 / 0 | PASS |
| Móvil simulado, cerca | 12 | 0 | 17,788 ms | 0 / 0 | PASS |
| Móvil simulado, lejos | 0 | 0 | 17,872 ms | 0 / 0 | PASS |

El viewport de stress fue **1580×633, TouchEnabled=false** en escritorio y **705×338, TouchEnabled=true** en el emulador. Lejos se desactivaron emisores/focos/luces; después se retiraron los 46 modelos y quedaron **cero tags vivos** en ambos casos. Son intervalos observados del cliente local de Studio y ventanas breves de carga, sin benchmark GPU aislado ni garantía de FPS para otro equipo o teléfono físico.

La [UI de escritorio](../assets/review/curse-rework/quality-ui-observed-desktop.json) tiene seis reportes completos con `failures=[]`, viewports 1296×633 y 1580×633, HUD 252×82. Se abrió la tienda, se visitaron Boosts/Soul Packs y se cerró con controles reales. La [UI móvil simulada](../assets/review/curse-rework/quality-ui-observed-mobile.json) tiene seis reportes completos con `failures=[]`, paisaje 706×339 y retrato 360×719 / 359×718, HUD 198×70; el datamodel confirmó `TouchEnabled=true`. SHOP y SETTINGS se abrieron/cerraron. El observador de límites comprueba geometría; por sí solo no demuestra las entradas nativas.

Capturas: [tienda escritorio](../assets/review/curse-rework/desktop-shop.jpg), [tienda paisaje móvil](../assets/review/curse-rework/mobile-landscape-shop.jpg), [tienda retrato](../assets/review/curse-rework/mobile-portrait-shop.jpg) y [contexto de santuario móvil](../assets/review/curse-rework/mobile-sanctuary-context.jpg). La imagen de retrato es una captura real de **144×320 píxeles con Fit Window**, no una captura nativa de 360×719. Studio mostró una advertencia de `ScreenOrientation` al simular retrato; la configuración conserva paisaje. **Scroll táctil móvil sin confirmar:** el arrastre y la rueda ensayados en ese contexto no produjeron un cambio observado de `CanvasPosition`.

**UI del catálogo final de 56: comprobada en escritorio.** Las capturas actuales muestran [la lista habilitada](../assets/review/curse-rework/normal-56-live-catalog-desktop.jpg), [sus últimas entradas Secret](../assets/review/curse-rework/normal-56-live-catalog-secret-desktop.jpg) y [la tienda](../assets/review/curse-rework/normal-56-shop-desktop.jpg). El pie de CURSES indicó **56 live · 0 expansion concepts**. Se abrió y cerró el catálogo; dos entradas reales de rueda, 5.600 y 3.600, desplazaron la lista desde las originales hasta Legendary y las tres últimas Secret. Se abrió y cerró Shop/Gamepasses sin realizar transacciones. La [proveniencia de capturas y entradas observadas](../assets/review/curse-rework/gameplay-distance-captures-provenance.json) conserva estos resultados; el scroll de escritorio está confirmado, el táctil móvil no.

El [estado final leído de la interfaz](../assets/review/curse-rework/normal-gui-final-observed.json) confirma **56/56 filas LIVE**, posición final de scroll `[0,6539]`, paneles cerrados, **500 Souls y +0 Souls/s**. El [estado final de Quality](../assets/review/curse-rework/normal-quality-final-state-observed.json) confirma generación 1 publicada por completo, cero fallos y cero advertencias. La [cola exacta de consola](../assets/review/curse-rework/normal-console-final-observed.log) conserva su aviso de recorte y los errores de las primeras consultas de observación —capacidad de `require` y una Part temporal sin `PrimaryPart`—; se corrigió el lector y se obtuvieron las muestras finales. No se contabilizan como fallos de los servicios de producción ni se describe esta cola parcial como un log completo.

**Cinco vistas actuales a distancia de juego:** capturas reales de Studio a aproximadamente **11 studs, 15° de frente y FOV 65**, con las mismas mallas, VFX e iluminación de producción. Los [metadatos observados](../assets/review/curse-rework/normal-gallery-metadata-current-source-observed.json) conservan los cinco IDs/hashes/tamaños, posiciones de cámara, apoyo y 35 fingerprints del build cargado. La [proveniencia de las imágenes](../assets/review/curse-rework/gameplay-distance-captures-provenance.json) registra hashes, revisión visual y tamaño **1920×1032 de la ventana nativa**, con juego en **1580×633**: son capturas JPEG sin editar.

| Rareza | Vista de presentación |
| --- | --- |
| Common | [Candle Wisp](../assets/review/curse-rework/candle-wisp-gameplay-distance-vfx-desktop.jpg) |
| Rare | [Pale Gramophone](../assets/review/curse-rework/pale-gramophone-gameplay-distance-vfx-desktop.jpg) |
| Legendary | [Thorn Cathedral](../assets/review/curse-rework/thorn-cathedral-gameplay-distance-vfx-desktop.jpg) |
| Mythic | [Cathedral Heart](../assets/review/curse-rework/cathedral-heart-gameplay-distance-vfx-desktop.jpg) |
| Secret | [The Last Star](../assets/review/curse-rework/the-last-star-gameplay-distance-vfx-desktop.jpg) |

Son **clones de presentación**, con prompt inactivo, sin registro privado de Curse, propietario ni ingresos; no se describen como compras o pedestales propios. El gameplay real lo prueban las cincuenta compras móviles y cinco repeticiones escritorio, con su alcance de fixture declarado. La galería documenta `ownedDisplaysAdded=0`, `incomeCreatedByGallery=0` y `gameplayValidatedByGallery=false`. Sus fuentes cargadas de producción y `default.project.json` coinciden con las actuales. La única diferencia registrada corresponde al constructor de pruebas, que recibió después una opción AutoCamera; esa opción no se usó en estas capturas y los módulos cargados de la galería siguen coincidiendo. No se ha probado un teléfono físico y los tiempos medidos en Studio no se presentan como rendimiento de ese dispositivo.

## 9. Trabajo restante y bloqueos

**Ninguna de las cincuenta Curses tiene etapas pendientes.** Los cincuenta nombres aparecen en el [anexo](CURSE_EXPANSION_50_REWORK_STATUS.md#estado-y-nombres-exactos), y [la activación local](../assets/review/curse-rework/local-activation.json) confirma 50 habilitadas y 6 originales conservadas. En runtime las nuevas usan `VALIDATED` y `enabled=true`; se habilitaron tras aprobar las pruebas completas y 2.148 verificaciones de elegibilidad, sin publicar la experiencia.

**El trabajo autorizado está completo y no hay Curses pendientes ni acciones bloqueadas.** La procesión normal quedó observada durante 62,03 s; Quality íntegro, interfaz final y las cinco vistas despejadas están guardados. Los límites de la evidencia permanecen explícitos: scroll táctil móvil sin movimiento confirmado y ausencia de pruebas en un teléfono físico. La muestra aleatoria natural cubrió ocho conceptos; la validación de los cincuenta se realizó en fixtures con preparación declarada y un cliente. Los clones de galería no se confunden con Curses compradas. No queda ningún modelo, importación, VFX, prueba individual ni habilitación pendiente entre las cincuenta.

## 10. Archivos modificados y estado local

Los cambios abarcan las fuentes Blender/exportaciones y evidencia actuales, el catálogo y sus referencias, el kit de meshes de Rojo, la integración visual y VFX, los dos módulos de ambiente, pruebas y documentación. El [inventario Git](CURSE_EXPANSION_50_REWORK_FILES.md), capturado a las **07:16:55 UTC**, enumera **12 archivos seguidos modificados y 453 sin seguimiento**, incluidos **59 archivos de referencia preexistentes** que no se cuentan como modelos creados. Registra cada ruta y su estado. Se conserva la rama `feature/final-map-polish-v2` y HEAD `21dbc52`; la comprobación de diferencias terminó sin errores.

Está listo el [build de producción local](../build-curse-expansion-50.rbxlx), **sin fixtures ni galería**, con 50 nuevas habilitadas y 56 definiciones totales. Su [prueba de construcción](../assets/review/curse-rework/production-build-proof.json) registra 311.152 bytes y SHA256 `17cf6f2517e514e619becb9a2e68811d961e0a3477a7504fb7f85a67505c4769`, junto con los hashes del proyecto, datos generados y 29 fuentes de producción. Es un archivo local para revisión; la experiencia no se publicó.

El archivo limpio quedó abierto en Studio, en Edit. El mapa se genera al iniciar Play; la [captura de apertura](../assets/review/curse-rework/production-place-opened-desktop.jpg) acredita ese archivo abierto, no sustituye las capturas del mundo durante la ejecución.

Para actualizar las tablas e inventario se usa [generate_curse_rework_report.py](tools/generate_curse_rework_report.py). Es un lector de la evidencia: comprueba hashes actuales, no concede etapas ni modifica manifests, catálogo o runtime, y conserva este informe narrativo. El inventario final se generó después de guardar la observación normal y la interfaz final. Todos los cambios permanecen sin commit, push o merge para revisión local; la entrega es el build limpio enlazado, listo para Play, y sus fuentes editables.
