# Steal A Curse — Final Map Polish V2

Fecha: 1 de octubre de 2026.

Estado del informe: **cierre de validación en curso**. El mundo, el ciclo natural, escritorio y móvil portrait ya se revisaron en Play. La tienda landscape recibió un ajuste compacto. La suite posterior alcanzó `SLICE_DONE` a las 13:03:40 y un nuevo ciclo natural alcanzó `FINAL_NORMAL_LOOP_PASS` a las 13:12:19 del 1 de octubre, ambos tras la última modificación de UI. Faltan la repetición responsive sobre esa UI y la auditoría estática de cierre.

## 1. Rama y alcance

Rama de trabajo: `feature/final-map-polish-v2`. Punto de partida: `1a3ad5f` (`Rework final haunted map environment`), con árbol limpio al comenzar. Se continúa el rework existente: no se reconstruye el mapa desde cero ni se cambia su distribución fundamental.

El alcance es entorno, colisiones, asentamiento de decoración, iluminación y UI. No se añade stealing, efectos de Curse, mutations, DataStore, progresión, economía nueva ni monetización real. No se utilizan Toolbox ni assets de terceros.

## 2. Problemas encontrados inicialmente

La inspección del código, documentación y capturas del primer rework identificó varios problemas concretos:

- Las mallas ambientales se instanciaban sin una clasificación central de colisión; varios volúmenes estructurales visibles no bloqueaban al personaje.
- La colocación usaba principalmente centros calculados a partir de `Size.Y`, insuficientes para mallas inclinadas y soportes elevados.
- La parte superior de algunas colinas de cementerio sobresalía por encima de la terraza plana donde se colocaban tumbas y losas.
- Los pedestales penetraban demasiado en el patio; losas y umbrales bajos tenían pequeñas separaciones respecto a sus soportes.
- Algunos faroles no estaban conectados visualmente a sus postes y las losas de tumbas no seguían la orientación real de sus lápidas.
- El aspecto dependía mucho de materiales genéricos; faltaban tratamientos de superficie y grupos Halloween deliberados.
- El HUD anterior era monolítico y sencillo, sin una navegación ni una tienda futura modular.

Estos hallazgos se contrastaron después con las seis vistas a altura de jugador del apartado 25: santuario, corredor entre bases, frente y entrada del castillo, cementerio y grupo Halloween.

## 3. Correcciones de flotación y alineación

`AssetKit.placeGrounded` interpreta el `CFrame` recibido como soporte inferior, no centro. Calcula la altura de la caja rotada usando sus tres ejes, levanta la malla y aplica un pequeño `groundInset` controlado. Registra `SupportY` antes de la elevación global del mapa para poder comprobar la colocación en Play.

`Grounding.position` consulta, durante la construcción fuera de Workspace, suelo, relieves, caminos y pisos de santuario. Es una consulta puntual de construcción, no un raycast ni un escaneo por frame. Se aplica a velas, árboles, raíces, rocas, tumbas, hongos, rejas y calabazas.

Cambios concretos:

- Colinas funerarias: centro reducido para que su cima coincida con la terraza; plataforma ampliada de 22 × 18 a 26 × 20 studs.
- Losas de tumbas: orientación hacia el mismo centro que las lápidas y cara inferior ligeramente hundida en su soporte.
- Pedestales: altura visual ajustada entre `COURT_TOP = 1.15` y `PLINTH_TOP = 3.4`, conservando el plano funcional de entrega.
- Arcos, contrafuertes, grandes memoriales, árboles principales, raíces, tejados y ventana derrumbada: soporte explícito y hundimiento controlado.
- Piso del undercroft y umbral: espesor extendido hacia abajo sin elevar su cara superior jugable; flagstones asentados sobre el piso.
- Faroles de santuario: zócalo, poste exterior, brazo y suspensión conectados; faroles genéricos ajustados al poste.
- Tableta de reclamo inclinada: soporte inferior calculado con su inclinación y runa adherida al mismo marco.
- Calabazas: cuerpo, ojos y sonrisa comparten orientación y escala.

Play del último mundo verificó **422 MeshParts con contrato de colocación grounded**. Las seis vistas revisadas muestran apoyos asentados, sin grandes superficies negras que tapen la imagen. El contrato comprueba límites y metadatos, no que cada triángulo de todos los props toque el terreno.

## 4. Correcciones de colisión

Las mallas visibles continúan sin colisión exacta. `AssetKit` crea cajas nativas invisibles solo para módulos que deben bloquear: jambas de puertas, contrafuertes, rejas, pedestales, grandes memoriales, guardianes, tronco central de árboles gigantes y grandes rocas accesibles.

Las jambas dejan libre el hueco de las puertas. Los árboles bloquean por el tronco bajo, no por todas las ramas. Los pedestales tienen tres niveles de cajas ajustadas. Las rejas usan un panel delgado bajo las puntas. Se eliminó el collider duplicado de los árboles protagonistas. Los muros nativos de la capilla pasan a bloquear.

Las escarpas de fondo situadas detrás de la barrera invisible existente no reciben hulls redundantes; los árboles y rocas de horizonte tampoco. El último ajuste retiró 96 hulls de escenario inaccesible respecto a la medición intermedia.

Play del último mundo: **289 hulls simples**, dentro de **689 partes ambientales con colisión**. En Base05 se atravesó el centro del acceso en ambos sentidos, se recorrió el patio y se comprobó el bloqueo de la barrera trasera: el personaje quedó en `Z` local 30.5905, antes del límite 32, y pudo retroceder sin quedar atrapado (`POLISH_WALL_BLOCK_PASS` / `POLISH_DISENGAGE_PASS`).

Una aproximación automática inicial por Pathfinding se enganchó en una jamba; una aproximación centrada pasó. Es una limitación de ese recorrido automático, no una prueba de que todos los waypoints físicos sean robustos. No se ha ensayado caminar contra cada muro, tronco o hull de las ocho bases.

## 5. Materiales y tratamientos de superficie

Se creó `SurfaceArt`, un tratamiento estilizado mediante color y geometría nativa reutilizada, no un atlas de imágenes ni texturas raster importadas. La identidad combina piedra azul/violeta, madera oscura teñida, tierra de lectura simple y acentos cian/naranja.

- Piedra: variación discreta de tres tonos, mortero escalonado, juntas, grandes manchas pintadas y desgaste de bordes.
- Losas y caminos seleccionados: lavados de color y grietas finas de baja frecuencia.
- Pedestales: marcas de desgaste en la cara superior.
- Madera: tono oscuro violeta/marrón coherente en árboles y elementos seleccionados.
- Tierra y horizonte: superficies simples que evitan ruido de materiales genéricos.

Los tratamientos son estáticos, sin sombras, sin colisión y sin query. El límite por construcción es **780 partes de SurfaceArt**. No se usó PBR, normal maps ni texturas 4K. Este pase no debe describirse como creación de texturas de imagen.

## 6. Decoración Halloween añadida

`HalloweenArt` añade **ocho grupos focales**: dos vigilias laterales en la aproximación al castillo y seis en esquinas seleccionadas del cementerio. Cada grupo combina tres calabazas de escala/color controlados y dos velas; algunas esquinas añaden un cartel torcido, un motivo de huesos abstracto y no gráfico o una pequeña silueta espectral estática.

Se añadieron dos telarañas en el portal y tres en parcelas seleccionadas. Son radios y anillos poligonales de beams finos, no superficies transparentes grandes delante de la cámara. También hay velas de esquina y calabazas conmemorativas en parcelas alternas.

La decoración conserva espacio negativo. Los grupos del castillo están al lado de la envolvente de la procesión, no sobre ella. No añaden luces ni ParticleEmitters.

## 7. Mejoras de los santuarios

Se conservan exactamente ocho bases y cinco slots por base, con los mismos nombres directos y referencias de gameplay.

Los accesos reciben pies de arco alineados, bandas de piedra, runas adheridas, pequeños remates de ruina y marcas territoriales bajas. El reclamo tiene tableta asentada, inlay de aproximación y vela lateral. Los faroles enmarcan la entrada sin colocar el poste dentro de la llama. El patio de colección conserva sus posiciones y plano funcional; su malla de pedestal ahora encaja entre patio y superficie de entrega.

Los corredores no se estrechan con nuevos muros ni se modifica la separación de bases del primer rework. Se comprobó el reclamo real de **Base05 mediante la tecla E**, el acceso físico al patio y el regreso desde una compra natural hasta el primer pedestal; el ciclo natural se repitió después de la UI compacta en **Base07**, sin enganche observado. Las ocho bases y cuarenta slots pasaron la validación de contratos. La suite aislada, repetida tras la UI compacta, colocó cinco Curses en pedestales distintos y verificó +222 Souls/s.

## 8. Rediseño del HUD

La tarjeta de Souls se sitúa en la esquina superior derecha, respetando `CoreUISafeInsets`. Presenta icono, título, saldo y `+X Souls/s`. Mide 252 × 82 px en escritorio amplio y 198 × 70 px en el modo compacto; el ancho se limita al espacio disponible.

Usa panel oscuro, borde violeta, rail cian, gradiente suave y jerarquía tipográfica. El saldo conserva `NumberFormat.compact`. Sus cambios tienen tween breve; la ganancia inicia un pulso discreto y no rebota en cada tick de ingreso. El aumento de Souls/s tiene feedback corto de color/escala.

Se conservan las rutas de UI utilizadas por las pruebas existentes: `SoulsHUD.Card.Amount`, `SoulsHUD.Card.SoulsPerSecond` y `AnimatedSouls`. El GUI sobrevive al respawn; las conexiones se limpian al destruirlo. El aviso de gameplay queda bajo la navegación y desaparece tras un intervalo breve.

## 9. Diseño del icono de Soul

Icono original construido con formas de UI: llama espectral con tres lenguas, cola curvada, rostro oscuro y brillo interior. Sus coordenadas normalizadas permiten reutilizarlo a diferentes tamaños. No es un emoji, un icono de terceros ni una imagen subida.

La misma familia geométrica se utiliza en el HUD y en las tarjetas de Souls de la tienda.

## 10. Navegación añadida

Se añaden `SHOP`, `CURSES` y `SETTINGS` debajo de la tarjeta de moneda, en la esquina derecha. Los botones usan `Activated`, compatible con mouse, touch y selección de gamepad, con feedback complementario de hover/selección.

`SHOP` abre la tienda; `CURSES` muestra el catálogo actual de seis Curses en modo lectura, no un inventario ni sistema de desbloqueo; `SETTINGS` es una shell de preferencias futuras, sin controles que aparenten modificar funciones inexistentes. Los paneles comparten chrome y cierre; también admiten Escape/B cuando el input no está procesado por Roblox.

## 11. Implementación de tienda mockup

El panel original `CURSED CURIOS` tiene encabezado, disclaimer visible de preview, pestañas `FUTURE PASSES` / `SOUL PACKS`, cierre de 44 × 44 px y páginas con scroll vertical.

Las tarjetas incluyen icono, título, beneficio propuesto, precio `TBD` y CTA `COMING SOON`. El CTA solo cambia el texto del pie para aclarar que no hubo compra. No envía remotes, no debita Souls, no concede perks ni abre prompts de Robux.

La composición adapta dos columnas desde 620 px de ancho de panel y una columna por debajo. Apertura, ambas pestañas, CTA y cierre se observaron en escritorio y portrait. En el landscape de 749 × 361 la altura de cuerpo inicial de 100 px cortaba tarjetas de 154 px. La corrección para áreas seguras menores de 430 px de alto oculta el subtítulo redundante, eleva pestañas/cuerpo y usa tarjetas de 124 px, sin escalar todo el panel; el CTA compacto conserva un objetivo de 44 px. Debe repetirse en Play antes de aprobar ese resultado.

## 12. Items del mockup

Cinco conceptos de passes: **X2 SOULS, LUCKY CURSES, VIP, EXTRA CURSE SLOT y FASTER DELIVERY**.

Cuatro conceptos de productos: **SMALL, MEDIUM, LARGE y MEGA SOUL PACK**.

Son nueve tarjetas. Los textos explican que beneficios, contenido, probabilidades y precios no son decisiones finales. Extra Curse Slot no cambia los cinco slots actuales. No hay cantidades de packs ni precios de Robux inventados.

## 13. Archivos existentes modificados

- `default.project.json`: exposición, bloom y saturación únicamente; no se cambiaron MeshIds.
- `src/client/UI/HUD.luau`: composición modular, posición, responsive, navegación y avisos.
- `src/server/Map/AssetKit.luau`: placement grounded, categorías y hulls simples.
- `src/server/Map/Build.luau`: integra el arte de superficies/Halloween y versiona el entorno.
- `src/server/Map/Cemetery.luau`: asentamiento, losas, rejas y vigilias.
- `src/server/Map/Decorations.luau`: grounding y alineación de decoración común.
- `src/server/Map/Landmarks.luau`: grandes props asentados y colisión de ruinas.
- `src/server/Map/Mausoleum.luau`: asentamiento de arquitectura y continuidad de pisos.
- `src/server/Map/PlayerShrine.luau`: accesos, pedestal, faroles, reclamo y límites.
- `src/server/Map/Primitives.luau`: opción explícita `canQuery`.
- `src/server/Map/TerrainArt.luau`: relación colina/terraza funeraria.
- `src/server/Map/World.luau`: suelo visual y exclusión de hulls en fondo inaccesible.
- `tests/Build-StudioFixture.ps1`: fixture de observación `-QualityPass` separado de producción.
- `tests/README.md`: comandos, alcance y resultados del pase del 1 de octubre, preservando la validación anterior.
- `README.md`: enlace al informe de este pase de calidad.

Son 15 archivos existentes modificados: 13 de configuración/código/fixture y dos actualizaciones de documentación. `src/server/Gameplay`, `src/shared`, la inicialización de producción, los modelos de Curse y los world labels no se modificaron.

## 14. Archivos creados

UI:

- `src/client/UI/CurrencyCard.luau`
- `src/client/UI/Icons.luau`
- `src/client/UI/Navigation.luau`
- `src/client/UI/PanelFrame.luau`
- `src/client/UI/ShellPanel.luau`
- `src/client/UI/ShopCard.luau`
- `src/client/UI/ShopPanel.luau`
- `src/client/UI/Theme.luau`

Entorno:

- `src/server/Map/Grounding.luau`
- `src/server/Map/HalloweenArt.luau`
- `src/server/Map/SurfaceArt.luau`

Pruebas y documentación:

- `tests/Audit-QualityPass.ps1`
- `tests/QualityPass.server.luau`
- `tests/QualityUI.client.luau`
- `docs/FINAL_MAP_POLISH_V2.md`

Los lugares, proyectos fixture y sourcemaps generados bajo nombres `build-*` son artefactos locales ignorados por Git. Las capturas locales están inventariadas en el apartado 25; la tienda landscape anterior al ajuste está identificada expresamente como evidencia del defecto, no del resultado final.

## 15. Assets Blender creados

**Ninguno en este segundo pase.** Se reutilizan las fuentes `.blend`, FBX y mallas originales ya importadas y documentadas en [FINAL_MAP_REWORK.md](FINAL_MAP_REWORK.md) y [FINAL_ENVIRONMENT.md](../assets/FINAL_ENVIRONMENT.md). No se borran ni se sustituyen árboles o módulos para resolver colisiones.

## 16. Assets de textura creados

**Ninguno.** No hay PNG, atlas, TextureId, SurfaceAppearance ni upload de textura nuevo. La identidad visual añadida es tratamiento de superficie mediante código, colores y geometría nativa estática; los iconos son formas de UI. Esto evita nuevas dependencias de permisos de imagen y memoria de texturas, a cambio de un presupuesto de partes adicional que debe perfilarse.

## 17. Asset IDs importados

No se importaron ni subieron assets nuevos en este pase. La auditoría compara `default.project.json` contra `1a3ad5f` y confirma **30 MeshIds originales preservados**: 24 plantillas ambientales y seis de Curse. Las instancias del entorno final utilizan **21 MeshIds ambientales únicos**.

Los IDs reales siguen registrados en `default.project.json` y en la documentación del primer rework. No se inventan IDs de malla, imagen, gamepass ni producto.

## 18. Estrategia de colisión

Cada malla tiene `CollisionCategory` y `CollisionHullCount`:

- `Blocking`: caja(s) nativa(s) invisibles inscritas en la estructura visible; no se usa la caja total de un arco o una copa.
- `Soft`: calabazas, tumbas pequeñas, raíces, árboles decorativos y rocas pequeñas no bloquean mediante triángulos. Los árboles comunes conservan su collider independiente de tronco bajo cuando corresponde.
- `NonBlocking`: cadenas, lámparas decorativas, ventanas, tejados y escenario inaccesible sin hulls.

Los hulls están anclados, transparentes, sin sombras ni touch, con `CanCollide` y `CanQuery` habilitados. Las mallas visibles tienen ambos deshabilitados. La geometría simple se crea una vez y se eleva junto con todo el mapa.

La clasificación final de las 530 mallas es **159 Blocking / 272 Soft / 99 NonBlocking**. Esta cifra no incluye la categoría de todos los Parts nativos ni las Curses activas.

## 19. Rendimiento e iluminación

Medición verificada en Play después del último cambio de mundo, excluyendo `ActiveCurses`:

| Métrica | Valor |
| --- | ---: |
| BaseParts ambientales | 3,395 |
| MeshParts ambientales | 530 |
| Hulls simples | 289 |
| Partes con colisión, incluyendo hulls y suelo/muros nativos | 689 |
| Mallas con contrato grounded | 422 |
| MeshIds ambientales únicos | 21 |
| Luces ambientales habilitadas | 13 |
| ParticleEmitters ambientales habilitados | 1 |

El primer rework documentó 1,815 BaseParts y 500 MeshParts. El segundo pase aumenta geometría estática por hulls, pintura de superficies y grupos Halloween; no es coste gratuito. Se limitó `SurfaceArt` a 780 partes y se retiraron hulls redundantes de fondo. No hay nuevos loops de mundo por frame, luces por calabaza ni emisores masivos. La UI actualiza atributos/eventos y usa tweens breves; no mantiene un contador de economía por frame.

Lighting conserva noche y visibilidad ambiental. Únicos cambios de propiedades en este pase:

- `ExposureCompensation`: 0.9 → **0.75**, para contener la exposición sobre superficies más legibles.
- `GraveyardBloom.Intensity`: 0.25 → **0.2**, para controlar el brillo de los acentos.
- `GraveyardColor.Saturation`: −0.08 → **−0.03**, para recuperar color sin hiper-neón.

Sin cambios: `Brightness = 3`, `ClockTime = 1.2`, `Ambient = [0.62, 0.6, 0.78]`, `OutdoorAmbient = [0.65, 0.67, 0.83]`, `ShadowMap`, `Atmosphere.Density = 0.28`, niebla 180–640, contraste 0.06 y tintado azul existente. No se convierte el mapa a día ni se llena de PointLights.

No hay benchmark de FPS, memoria, draw calls ni render time en teléfono real. Las cuentas confirman estructura, no rendimiento móvil objetivo.

## 20. Prueba de UI escritorio

Se obtuvo **`QUALITY_UI_PASS` con viewport 934 × 497** y después con el preset Desktop HD 720, viewport efectivo **1279 × 720**: HUD y navegación dentro del área segura, saldo/tasa concordantes con atributos y nueve tarjetas `TBD`/`COMING SOON`. El preset representa la revisión 16:9 de escritorio; la lectura efectiva difiere un píxel del ancho nominal de 1280.

La tarjeta amplia mide 252 × 82 px. SHOP muestra los cinco passes en dos columnas, con scroll para el contenido restante, y cuatro packs en la segunda pestaña. Se activaron pestañas, CTA Coming Soon y cierre X. El CTA mantuvo el saldo de 500 y mostró que no hubo compra; no apareció un prompt de Robux. Se capturaron HUD y tienda. La repetición tras el último ajuste compacto sigue pendiente.

## 21. Prueba móvil portrait

En Device Simulator, preset iPhone 17 Pro portrait, se observó **`QUALITY_UI_PASS` inicialmente con viewport efectivo 400 × 776**. Al cambiar paneles de Studio el área efectiva varió; estas cifras describen la sesión, no todos los tamaños de teléfono. La tarjeta compacta de 198 × 70 px y la navegación quedaron dentro del área segura, sin tapar joystick ni salto.

Se abrió SHOP por toque, se cambiaron las dos pestañas y, con el viewport enfocado, se hizo scroll hasta **EXTRA CURSE SLOT / FASTER DELIVERY** y **MEGA SOUL PACK**. Los beneficios y precios revisados eran legibles; el CTA Coming Soon no modificó el saldo y el cierre X funcionó. También se abrieron/cerraron las shells CURSES y SETTINGS, que comunican su alcance de lectura/preview. Hay capturas del HUD, tienda y ambos finales de scroll.

La revisión no demuestra ajuste de texto en cada ancho posible, por ejemplo 320 px, ni una sesión completa de gameplay con touch. Debe repetirse el smoke test tras la última modificación compacta compartida por las tarjetas.

## 22. Prueba móvil landscape

El HUD pasó **`QUALITY_UI_PASS` en el viewport efectivo 749 × 361** y se capturó con los controles táctiles. La tienda inicial, aunque contenida dentro del área segura, tenía solamente 100 px de cuerpo y recortaba tarjetas de 154 px. Esta observación provocó la corrección compacta de encabezado/tarjetas descrita en el apartado 11; **la validación visual del resultado está pendiente**.

Todavía deben repetirse apertura, pestañas, scroll hasta el último item, CTA y cierre con el nuevo layout. La captura `12-shop-mobile-landscape-before-compact.png` documenta el defecto previo y no debe utilizarse para presentar la tienda final como aprobada. La emulación de Studio no equivale a FPS ni ergonomía comprobados en hardware real.

## 23. Regresión de gameplay y verificaciones

Resultados del último mundo y repeticiones posteriores a la UI compacta final:

- `QUALITY_WORLD_PASS`: ocho contratos de santuario, cuarenta slots, soporte de spawn/reclamo, límites de hulls, metadatos grounded y ocho rutas de navmesh al castillo correctos.
- `QUALITY_UI_PASS`: viewports efectivos 934 × 497, escritorio HD 720 1279 × 720, portrait inicial 400 × 776 y landscape 749 × 361. Un PASS de límites/contratos no suplanta la revisión visual: la tienda landscape necesitó una corrección.
- Ciclo natural de Base05: reclamo y compra con E; caminata de ida/regreso mediante Humanoid/Pathfinding, sin teletransporte ni crédito de prueba; compra de Cursed Doll natural **500 → 400**, **0 Souls/s** durante entrega; colocación en slot 1 y **+3 Souls/s**, con aumento observado de **5.5 Souls en aproximadamente dos segundos** (`POLISH_LOOP_PASS 3 5.5`). Después se abrió/cerró la tienda. Fue movimiento asistido por comandos, no un recorrido de usabilidad humano sin asistencia.
- Acceso centrado al santuario en ambos sentidos, recorrido del patio, barrera trasera bloqueante y retirada sin atasco observados. El primer trayecto automático se enganchó en una jamba; no se oculta ese límite de Pathfinding.
- Seis vistas de mundo a altura de jugador y capturas de escritorio/portrait revisadas. Scroll táctil hasta las últimas tarjetas portrait comprobado; landscape final sigue pendiente.
- `Audit-QualityPass.ps1`: `QUALITY_STATIC_PASS`, 30 MeshIds retenidos, gameplay sin diferencias contra `1a3ad5f`, ausencia de purchase APIs/IDs y fixtures excluidos de producción.
- `git diff --check`: sin errores; los avisos LF → CRLF son de normalización Git, no fallos de whitespace.
- Build normal de Rojo, sourcemap y fixtures QualityPass / Slice regenerados correctamente después de la UI compacta final, el 1 de octubre a las 13:01.
- Suite fresca `build-polish-v2-slice-final.rbxlx`: **`SLICE_DONE` a las 13:03:40.401**, sin fallos. Pasaron reclamo/objetivo de respawn, rechazo sin base y por saldo insuficiente, compra 500 → 400, ausencia de ingreso durante transporte, un transporte simultáneo y regreso físico por Pathfinding a Base07 sin enganche observado.
- En esa suite: cinco pedestales distintos, HUD +222 y filtro del detalle más cercano; rechazo por base llena; refund de pedestal/área ausentes y muerte; propiedad/tasa conservadas tras respawn; restauración del modelo sin tasa duplicada; reemplazo por The Void con +822 Souls/s. Las seis definiciones conservaron raíz menor de siete studs de diagonal, sin colisión; brillo frontal de Chains/Void verificado.
- Repetición fresca del fixture de observación después de esa UI: **`QUALITY_WORLD_PASS` a las 13:05:57**, con las mismas cuentas, y `QUALITY_UI_PASS` 934 × 497.
- Nuevo ciclo natural final: reclamo real de **Base07**, ida física hasta el castillo, seguimiento por Humanoid de una Doll generada por la procesión natural, compra real con E a las 13:10:52 (**400 Souls / 0 Souls/s**), regreso físico sin enganche, entrega a slot 1 y **`FINAL_NORMAL_LOOP_PASS Base07 3 6.300000000000011` a las 13:12:19.123** (+3 Souls/s, aproximadamente +6.3 Souls en dos segundos). Sin teletransporte, crédito ni spawn forzado; caminata asistida por comandos, no prueba humana sin asistencia.
- SHOP abrió/cerró por clic real en ese Play final; `QUALITY_SHOP_OPEN_PASS 934 497` incluyó comprobaciones `TextFits` de las tarjetas visibles.

**Pendientes de cierre:** revisión landscape y repetición responsive de UI después del ajuste compacto; auditoría/diff check de cierre. La suite y el ciclo natural ya se repitieron sobre el build posterior a la última modificación relevante.

No se atribuyen a este pase los resultados `SLICE_DONE` o `ALL_BASES_DONE` del primer rework. Las rutas de navmesh exitosas no prueban un recorrido físico ni ausencia de snags. El fixture `-QualityPass` mantiene inicialización/procesión de producción y sus validadores son observadores: no otorgan crédito, no teletransportan ni fuerzan estados.

Comandos reproducibles desde la raíz del proyecto:

```powershell
rojo build default.project.json --output build-polish-v2-final.rbxlx
rojo sourcemap default.project.json --output build-polish-v2-final.sourcemap.json
git diff --check
.\tests\Audit-QualityPass.ps1
.\tests\Build-StudioFixture.ps1 -QualityPass
.\tests\Build-StudioFixture.ps1
```

El lugar QualityPass es para revisión real y observación; el fixture Slice aísla regresiones y debe documentarse separado del ciclo natural.

## 24. Limitaciones conocidas

- La entrega todavía no está completada: falta repetir la revisión responsive tras la última UI, además de la auditoría de cierre.
- Las comprobaciones grounded validan cajas y soporte declarado, no todos los triángulos visibles ni props colgantes.
- Hulls dentro de la caja de una malla no demuestran por sí solos ajuste visual ni ausencia de enganches.
- La navegación satisfactoria no sustituye caminar con personaje y cámara estándar por entradas, salidas y rutas de entrega.
- Los tratamientos custom son geometría/color, no texturas raster ni un nuevo kit Blender.
- El coste total de partes aumenta frente al primer rework; falta medición móvil real.
- El portrait observado fue legible y tuvo scroll funcional; no se cubrieron todos los anchos estrechos ni hardware real.
- No se probó en este pase una carrera multijugador de reclamo ni todos los escapes/persecuciones; las reglas de gameplay siguen intactas.
- Algunos ángulos superponen world labels y HUD; se preservan los labels de gameplay existentes y no se pretende que esta revisión elimine toda oclusión.

## 25. Capturas revisadas y comprobaciones manuales recomendadas

Abrir el lugar local recién construido, iniciar Play y realizar el ciclo completo sin teletransporte ni crédito de prueba. Comprobar saldo antes/después de comprar, ausencia de ingreso durante transporte, slot de entrega y aumento de Souls/s. Revisar los seis tipos y cinco posiciones mediante la suite aislada por separado.

Caminar contra un muro del castillo, una reja y un gran volumen de malla; atravesar el centro libre de dos arcos en ambos sentidos y recorrer el patio alrededor de los pedestales. Revisar troncos y raíces sin que ramas decorativas bloqueen la cámara. Confirmar que la procesión natural sigue atravesando el undercroft y sus caminos.

Las seis vistas de mundo usan cámara a altura de jugador, sin teletransportar al personaje. Se revisaron apoyos, accesos, visibilidad azul/violeta y ausencia de enormes superficies negras. Son muestras de ángulos concretos, no una garantía de cada posición de cámara. Las capturas incluyen el marco de Studio y se guardan sin edición de imagen.

| Vista | Evidencia local |
| --- | --- |
| Santuario, Doll colocada y +3 Souls/s | [01-sanctuary.png](polish-v2-review/01-sanctuary.png) |
| Entre santuarios | [02-between-sanctuaries.png](polish-v2-review/02-between-sanctuaries.png) |
| Frente del castillo | [03-castle-front.png](polish-v2-review/03-castle-front.png) |
| Entrada del castillo | [04-castle-entrance.png](polish-v2-review/04-castle-entrance.png) |
| Camino del cementerio | [05-cemetery-path.png](polish-v2-review/05-cemetery-path.png) |
| Grupo Halloween | [06-halloween-cluster.png](polish-v2-review/06-halloween-cluster.png) |
| HUD escritorio HD 720 | [07-hud-desktop.png](polish-v2-review/07-hud-desktop.png) |
| Tienda escritorio | [08-shop-desktop.png](polish-v2-review/08-shop-desktop.png) |
| HUD móvil portrait | [09-hud-mobile-portrait.png](polish-v2-review/09-hud-mobile-portrait.png) |
| Tienda móvil portrait | [10-shop-mobile-portrait.png](polish-v2-review/10-shop-mobile-portrait.png) |
| HUD móvil landscape | [11-hud-mobile-landscape.png](polish-v2-review/11-hud-mobile-landscape.png) |
| Últimos passes por scroll portrait | [13-shop-mobile-passes-bottom.png](polish-v2-review/13-shop-mobile-passes-bottom.png) |
| Último pack por scroll portrait | [14-shop-mobile-packs-bottom.png](polish-v2-review/14-shop-mobile-packs-bottom.png) |
| Final de la suite posterior a la UI compacta | [15-slice-regression-done.png](polish-v2-review/15-slice-regression-done.png) |
| Ciclo natural repetido tras la UI compacta | [16-final-natural-loop.png](polish-v2-review/16-final-natural-loop.png) |

La captura [12-shop-mobile-landscape-before-compact.png](polish-v2-review/12-shop-mobile-landscape-before-compact.png) es diagnóstico anterior a la corrección; falta añadir su reemplazo aprobado. En vistas de castillo algunos world labels se superponen a la composición; no se ocultaron para mejorar artificialmente las capturas.

En móvil portrait/landscape comprobar ambos tabs, scroll hasta última tarjeta, CTA Coming Soon, close y legibilidad de beneficio/precio. Contrastar después con teléfono real y una segunda persona para ergonomía, FPS y recorridos de persecución.

## 26. Estado Git y cierre pendiente

Los cambios continúan locales en `feature/final-map-polish-v2`; HEAD permanece en `1a3ad5f`. No se hizo commit, push, merge ni publicación de experiencia. No se subieron assets nuevos.

El pase tiene **15 archivos existentes modificados** (13 de configuración/código/fixture más `README.md` y `tests/README.md`) y **14 nuevos de código/pruebas**, además de este informe y las capturas. Los artefactos locales `build-*` continúan ignorados. El inventario definitivo de evidencias debe comprobarse al cerrar, sin confundirlas con nuevos assets subidos a Roblox.

La auditoría del mundo no encontró una regresión concreta de código; la revisión visual sí detectó el recorte de tarjetas landscape, cuya corrección está implementada y pendiente de revisión responsive. La suite y el ciclo natural posteriores a esa corrección pasaron. La aprobación final queda pendiente de las verificaciones indicadas en los puntos 20–23 y del nuevo screenshot landscape. No se declara el trabajo terminado mientras quede una comprobación requerida sin ejecutar.
