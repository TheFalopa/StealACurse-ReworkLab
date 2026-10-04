# Steal A Curse — restauración del santuario

**Rama:** `codex/sanctuary-restoration-update`. Todo permanece local: sin publicación, commit, push ni merge.

**Estado: entrega local guardada y verificada, 2026-10-03.** Archivo recargado desde disco, F5 normal comprobado y Play detenido. Las comprobaciones se enumeran con su alcance.

Entrega: [build-sanctuary-restoration-update.rbxlx](C:/RobloxProjects/StealACurse/build-sanctuary-restoration-update.rbxlx). Evidencia: [assets/review/sanctuary-restoration](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration).

## 1. Conservación y estado funcional

El checkpoint de partida conserva la entrega animada, las fuentes y los datos nativos de importación: 55 fuentes coincidían con Studio y el archivo de partida; las 56 plantillas contenían skinning nativo. Se mantienen identidades, rarezas, precios, tamaños y animaciones de las Curses, salvo las reparaciones de geometría/rig descritas abajo. Los checkpoints desde `00-polished-start` hasta `10-final-delivery` incluyen importación, integración, remodelación, transporte, multijugador, migración/móvil y fachada/rendimiento; guardan avances recuperables y manifiestos, sin sustituir la revisión visual.

| Función | Estado y evidencia disponible |
|---|---|
| Diez mejoras permanentes | Implementadas; capacidades, requisitos, descuentos únicos y reconstrucción comprobados en Play mediante servicios reales. |
| Grimorio y seis conjuntos | 56 especies etiquetadas; primera colocación propia registra una especie una vez. Venta y duplicados conservan el historial. Pruebas de reglas y primer recorrido completas. |
| Sepulturero y contratos | 12 variantes de recuperación, transporte y sellado comprobadas; recompensa única, orden, distancia, abandono y recuperación validados. |
| Reliquias físicas | Carga exclusiva, entrega física y recuperación; réplica, entrega única y retirada comprobadas con dos clientes. |
| Rituales | Cinco actuaciones con ecos temporales animados sin ingresos; salida, orden incorrecto y reintento comprobados. |
| Arquitectura y pedestales | Tres pisos, hasta 30 IDs estables, tres estilos y exhibidor de una única Curse real; reglas, recarga y recorrido físico con The Void comprobados. |
| Sello protector | Dueño e intruso, intento de colisión local, expiración de 40 s y vulnerabilidad real de 60 s comprobados con dos clientes. El robo no está operativo. |
| Administración existente | Compra, venta al 50 %, recogida, transporte, reubicación entre pisos e ingresos comprobados; sin retorno automático tras muerte o reinicio. |
| Remodelación | 3 mallas importadas realmente y revisadas en Play; 53 conservadas según auditoría y evidencia anterior. |
| Interfaz | Panel contextual; pruebas táctiles de primera mejora/ritual, estilo, contrato, recoger/colocar y confirmación de venta en iPhone 7 emulado. Alcance y límites abajo. |

## 2. Progresión y economía

Configuración central: [SanctuaryConfig.luau](C:/RobloxProjects/StealACurse/src/shared/SanctuaryConfig.luau). Las mejoras conservan dinero restante, colección y descubrimientos; no consumen Curses, requieren rebirth, Robux ni una Secret determinada. No añaden multiplicadores de producción. Los fragmentos se obtienen mediante actividades, sin generación pasiva ni compra ilimitada con Souls.

Los costes son **por etapa**. El siguiente nivel y todos sus requisitos se calculan en el servidor antes del descuento; una confirmación repetida del nivel anterior no vuelve a cobrar.

| Etapa / transformación | Capacidad | Souls | Fragmentos | Especies descubiertas | Requisitos adicionales |
|---|---:|---:|---:|---:|---|
| 0. Sin restaurar | 5 | — | — | — | Conserva las posiciones existentes |
| 1. Patio restaurado: altar, suelo y entrada | 6 | 150 | 0 | 1 | Primera vigilia |
| 2. Ala de colección | 8 | 750 | 6 | 3 | 1 contrato; Casa encantada |
| 3. Santuario cerrado: fachada, ventanas, techo parcial | 10 | 2.200 | 14 | 5 | 3 contratos; 1 recuperación y 1 sellado |
| 4. Galería superior: segundo piso | 14 | 6.500 | 24 | 7 | Compañeros inquietos y Casa encantada; vigilia de colección |
| 5. Galería expandida | 18 | 13.000 | 36 | 10 | 8 contratos, 2 transportes; Arboleda viva y Melodías perdidas |
| 6. Sello protector | 18 | 22.000 | 48 | 12 | 3 sellados y 9 marcas activadas |
| 7. Sala de reliquias: tercer piso | 22 | 45.000 | 70 | 15 | 14 contratos, 1 reliquia mayor; consagración |
| 8. Cámara expandida | 26 | 80.000 | 90 | 20 | 3 conjuntos entre 6 alternativas |
| 9. Santuario consagrado: emblema y cierre mejorado | 26 | 140.000 | 120 | 24 | 22 contratos, 18 marcas; gran sello |
| 10. Dominio: arquitectura y exhibición completas | 30 | 220.000 | 160 | 28 | 30 contratos, 2 reliquias mayores; 5 conjuntos; ritual final y tres anteriores |

Total: **529.600 Souls y 568 Fragmentos**. Los seis conjuntos aceptan especies alternativas: Compañeros inquietos, Casa encantada, Guardianes de la memoria, Arboleda viva, Melodías perdidas y Relojes sin dueño. Las 32 Common/Rare bastan para todos los requisitos de colección; no es necesario depender de una especie extremadamente rara.

El balance usa el catálogo actual: Common de 80–290 Souls con 2–5,5 Souls/s; Rare de 400–1.700 con 10–36 Souls/s. Con 500 Souls iniciales, una Common y la primera mejora de 150 son alcanzables pronto. Como estimación de diseño, completar la restauración podría requerir **2–4 horas activas**, con unos 45–75 contratos mezclados y una colección creciente. No son datos de jugadores ni tiempos medidos; requieren calibración posterior. Los saldos sembrados por QA no se usaron para fijar costes. [Notas de economía y reglas](C:/RobloxProjects/StealACurse/docs/SANCTUARY_PROGRESSION_NOTES.md).

## 3. Contratos y rituales

Un contrato activo por jugador; disponibles continuamente, sin horarios diarios. El objetivo y la recompensa se muestran antes de aceptar. La entrega/activación se valida por propiedad, contrato, token, paso y distancia en el servidor. La misma operación no concede una segunda recompensa. Abandonar conserva los materiales ya obtenidos; objetivos desaparecidos admiten reparación o reinicio controlado.

| Contrato | Tipo | Nivel mínimo | Fragmentos | Recorrido |
|---|---|---:|---:|---|
| Una pieza perdida | Recuperación | 0 | 4 | Cementerio → altar propio |
| Recuerdo del pozo | Recuperación | 1 | 5 | Pozo → altar propio |
| Raíz del recuerdo | Recuperación | 3 | 8 | Bosque → altar propio |
| Luz para la capilla | Transporte | 0 | 4 | Sepulturero → capilla |
| Farol entre raíces | Transporte | 2 | 7 | Sepulturero → bosque |
| Luz de estrellas | Transporte | 5 | 11 | Sepulturero → piedra astral |
| Tres marcas del camposanto | Sellado | 0 | 5 | Cementerio → pozo → patio |
| La senda sellada | Sellado | 3 | 9 | Pozo → bosque → capilla |
| Constelación terrestre | Sellado | 6 | 12 | Capilla → piedra astral → patio |
| La reliquia mayor | Recuperación mayor | 6 | 14 | Piedra astral → altar propio |
| Memoria del castillo | Recuperación mayor | 8 | 14 | Patio → altar propio |
| El círculo completo | Sellado | 8 | 14 | Bosque → patio → piedra astral |

Las reliquias no se disputan entre jugadores. El sistema de carga impide llevar una Curse y una reliquia simultáneamente. Muerte o recarga permiten recuperar la actividad, sin pago automático ni recolocación automática de Curses.

| Ritual | Disponible desde | Especies distintas propias colocadas | Marcas en orden | Requisito especial |
|---|---:|---:|---|---|
| Primera vigilia | 0 | 1 | 1, 2 | Tutorial |
| Vigilia de colección | 3 | 3 | 1, 3, 2 | — |
| Consagración de la reliquia | 6 | 4 | 2, 1, 3, 2 | 1 reliquia mayor entregada |
| El gran sello | 8 | 5 | 3, 1, 2, 3, 2 | — |
| Vigilia del dominio | 9 | 6 | 1, 2, 3, 1, 3, 2 | 2 reliquias mayores entregadas |

Los ecos muestran su condición temporal y sin ingresos. Las Curses originales permanecen en sus pedestales; sus UIDs, propiedad y producción no se duplican ni consumen. Orden incorrecto, salida y reintento no destruyen criaturas ni recursos.

## 4. Mapa, estilos y protección

Una estructura funcional compartida sirve a los diez niveles y tres estilos: **Cripta** (piedra clara, hierro y velas), **Bosque maldito** (madera, raíces y faroles) y **Observatorio** (piedra oscura y símbolos astrales). Cambiar estilo conserva marcadores, colisiones, capacidad, colección y barrera. El exhibidor resalta el pedestal de un UID propio colocado, sin copia, ingreso extra ni protección especial.

Las bases usan una huella de 104 × 104 studs, galerías separadas por 22 studs, escaleras de 18 studs y entrada de 24 studs. Hay diez posiciones lógicas por piso: `floor1-slot1` a `floor3-slot10`; los cinco IDs anteriores se conservan. Nuevos pedestales comienzan vacíos y la mejora no coloca inventario automáticamente. Las posiciones se guardan por identidad lógica, independientes de la base asignada.

Se añadieron el Sepulturero/tablón, instalaciones de contratos y altares propios. Se preservan castillo y procesión; la exclusión de decoración contempla las nuevas huellas. El perímetro pasó a radio 406 y suelo 860 × 860; ChainedTree y criptas cercanas se redistribuyeron para dejar espacio. La arquitectura usa colisiones simples y no recibe la pintura/desgaste automático del suelo anterior. [Notas de arquitectura](C:/RobloxProjects/StealACurse/docs/SANCTUARY_ARCHITECTURE_NOTES.md).

La revisión exterior detectó paños demasiado lisos. Se añadieron ventanas góticas nativas, marcos, cornisas, contrafuertes y relieves propios de cada estilo. Las 13 comprobaciones de arquitectura pasaron; una compara cada collider anterior/nuevo en los 33 casos de nivel/estilo. Todas las adiciones son decorativas, sin colisión/consulta ni luces adicionales. Capturas reales del mismo ángulo: [Cripta](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/crypt-level10-native.png), [Bosque](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/forest-level10-native.png), [Observatorio](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/observatory-level10-native.png). Las imágenes `*-level10-before-facade.png` conservan el estado anterior.

El cierre dura **30 segundos desde nivel 6**, **40 desde nivel 9**, con **60 segundos de vulnerabilidad después**. La barrera reside en servidor; el dueño tiene acceso, y una comprobación del servidor impide permanecer dentro a un intruso que cambie colisiones localmente. Esto protege el acceso físico implementado: **no se declara robo comprobado ni inmunidad total de la colección**.

**Transporte entre pisos comprobado.** La revisión espacial encontró enterramiento del modelo en rampas (mínimo anterior: −1,835 studs respecto al apoyo). Una revisión intermedia corrigió las rampas, pero detectó una intersección con el altar y quedó como fallo diagnóstico. El cálculo compartido `CurseCarryGeometry` limita ahora la huella en corredores, rampas y entrada; cinco rayos acotados contemplan los apoyos y el altar. Cliente y servidor usan el mismo cálculo sin cambiar propiedad ni alcance de las acciones.

La revisión final con una **The Void real comprada** completó 54 tramos caminando, subida al tercer piso, colocación manual, bajada y venta de la instancia temporal: cero muertes, cero invasión de los límites medidos y mínimo de 0,12 studs sobre los apoyos. Solo el posicionamiento inicial del avatar usó teleport de QA. Se conservaron las seis Curses anteriores. [Medidas finales](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/native-spatial-final.json), [vídeo](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/videos/the-void-stairs-native.mp4). Algunos ángulos de cámara del vídeo quedan tapados brevemente por muros/modelo; no se declara una cámara perfecta en todas las perspectivas. La [captura del tercer piso](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/the-void-third-floor-native.png) muestra una representación adicional de ajuste espacial, sin propiedad ni ingresos; no es una segunda Curse adquirida. Los registros `native-spatial-before.json` y `native-spatial-interim.json` se conservan como diagnósticos previos.

## 5. Auditoría y remodelación de las Curses

Auditoría de **56 fuentes/rigs** y capturas nativas previas: **53 conservar, 3 remodelar, 0 correcciones exclusivamente de material**. Los problemas prioritarios procedían de volúmenes y colores poco separados, reforzados por iluminación nocturna; no se atribuyeron sin evidencia a texturas borrosas o LOD. Se mejoraron formas, relieves, expresión y paleta, manteniendo estilo Roblox y tamaños aprobados.

| Curse | Cambio | Triángulos antes → después | W/H/D observados, studs | MeshId real |
|---|---|---:|---|---|
| Grave Hopper | Borde de lápida, RIP y cruz, expresión, musgo agrupado y articulaciones | 2.400 → 4.708 | 4.074 / 4.200 / 2.720 | `130614622379245` |
| Nail Beetle | Placas de caparazón, clavo forjado, pupilas/mandíbulas y seis patas legibles | 1.594 → 2.526 | 5.600 / 3.200 / 5.400 | `73295688458517` |
| Coin Crawler | Bronce, cantos, tres monedas acuñadas, cara oscura y cuatro rodillas | 2.172 → 4.080 | 5.800 / 3.200 / 4.100 | `74159266876686` |

| Curse | Comparación real en Roblox | Vídeo de Play |
|---|---|---|
| Grave Hopper | [Antes](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/grave-hopper-before-user.png) / [Después](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/grave-hopper-native-pedestal.png) | [Procesión, compra, transporte, pedestal y venta](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/videos/grave-hopper-native.mp4) |
| Nail Beetle | [Antes](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/nail-beetle-before-user.png) / [Después](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/nail-beetle-native-pedestal.png) | [Play](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/videos/nail-beetle-native.mp4) |
| Coin Crawler | [Antes](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/coin-crawler-before-user.png) / [Después](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/coin-crawler-native-pedestal.png) | [Play](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/videos/coin-crawler-native.mp4) |

Las comparaciones tienen cámaras distintas. Las tres mallas fueron revisadas integradas en procesión, transporte y pedestal; no se cuentan renders Blender como aprobaciones de Roblox. Las otras 53 conservan evidencia anterior: [tabla de las 56 y compatibilidad](C:/RobloxProjects/StealACurse/docs/SANCTUARY_CURSE_VISUAL_AUDIT.md).

Fuentes Blender 5.2.2: `assets/source/blender/sanctuary-restoration/{grave_hopper,nail_beetle,coin_crawler}.blend`. FBX individuales y [lote real de tres mallas/35 huesos](C:/RobloxProjects/StealACurse/assets/export/meshes/curses/sanctuary-restoration/sanctuary-curse-remodel-03.fbx) en `assets/export/meshes/curses/sanctuary-restoration`. Producción reproducible: `tools/Remodel-RestorationCurses.py`; registros [fuentes](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/source-production-batch.json), [deformaciones](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/rig-deformation-checks.json) e [importaciones observadas](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/native-remodel-observed.json).

Los datos nativos/skinning están en `assets/imports/CurseMeshKit.rbxmx`; IDs actuales en `assets/imports/curse-animation-current.json` y `src/shared/CurseAnimationAssets.luau`. No se inventaron IDs ni clips publicados.

Se conserva la configuración local de aparición rápida de la copia del usuario: ciclo de las 56 habilitadas, una oferta cada 3 segundos y máximo 20. Esta entrega no restablece una distribución comercial por probabilidades; esos valores están en `Gameplay/Config` y `CurseProcessionService`.

### Animaciones y VFX del colaborador

No se rehacen los VFX. Grave Hopper y Nail Beetle conservan nombres, jerarquías y pesos anteriores; sus detalles nuevos siguen huesos existentes. En Coin Crawler se conservan hips y contactos, pero se ajustan las posiciones de reposo de **Knee0–Knee3** y los pesos de **201 vértices** de tubos/pies para doblar correctamente. El solver utiliza sus nuevas matrices; el amigo debe revisar offsets de VFX sujetos a esas cuatro rodillas. `Root`, `Gaze`, `CoinLid`, hips y nombres de anclajes conservan su referencia. La correspondencia exacta anterior/nueva está en la auditoría enlazada.

Music Box Dancer y Marrow Dice conservan sus actuaciones actuales; sus marchas pendientes se reservan al encargo posterior indicado por el usuario. Thorn Reliquary no se modifica en esta actualización.

## 6. Guardado y migración

Se amplía el perfil existente conservando Souls, inventario, UID, revisión y posición lógica. Se guardan nivel, estilo, fragmentos, descubrimientos, hitos, rituales, contrato recuperable y exhibidor. La validación rechaza cuentas base inválidas sin sustituirlas por una cuenta vacía; normaliza únicamente campos nuevos dañados y falla de forma conservadora ante un esquema futuro.

Un perfil antiguo sin `sanctuary` recibe descubrimientos de las especies legítimamente poseídas, incluidas `UNPLACED`: el esquema anterior carecía de historial de primera colocación. Es una concesión única de migración documentada. En perfiles nuevos una compra sin colocar no se descubre por recargar; solo cuenta la colocación propia validada.

Muerte/reinicio dejan una Curse propia `UNPLACED`, recuperable manualmente y sin ingresos. Recargar no la devuelve a su antiguo pedestal. Un contrato de reliquia guardado en transporte vuelve a `RECOVERABLE`, sin recompensa automática. Se conserva el puente local de perfiles y su journal con reconocimiento de revisión; no se escribe por movimiento/fotograma. La persistencia online mantiene `UpdateAsync`/lease, pero **no se probó online ni se publicó para hacerlo**.

La prueba nativa específica de migración conservó los dos UIDs de un perfil antiguo, su dinero y posición lógica, y registró dos especies sin duplicarlas. Tras muerte real, Grave Hopper quedó sin colocar; se guardó un contrato con reliquia transportada y token estable. Al detener Play se persistió su estado recuperable. Se cerró, guardó y reabrió el archivo en otra instancia de Studio; se reclamó Base04 en lugar de Base03. La misma reliquia se recuperó y entregó manualmente al nuevo altar, con cuatro fragmentos una sola vez; el altar anterior rechazó la entrega. La Curse se recuperó y colocó manualmente en `floor1-slot3`. Son **38 comprobaciones iniciales y 40 de recarga aprobadas**. No se presenta esta recarga como una carga directa de `CARRYING`: Stop ya había guardado `RECOVERABLE`; la conversión de datos en transporte también tiene cobertura de lógica. [Antes de cerrar](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/persistence-legacy-pending.json), [recarga nativa](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/persistence-native-reload.json).

### Interacción táctil

En iPhone 7 emulado, `TouchEnabled=true`, ventana de juego 666 × 374, se usaron toques nativos para ritual inicial, mejora, cambio a Bosque, recogida/entrega del contrato del pozo (+5 fragmentos), confirmación de venta de Grave Hopper (47 Souls, sin vender el UID antiguo), recogida y colocación manual. Su producción pasó de 5,25 a 3 y volvió a 5,25 Souls/s. Se corrigieron la recepción de arrastre del panel (`Active=true`), el botón Santuario para dejar libres salto/joystick/prompt Colocar y el objetivo contextual para evitar el HUD. Las instalaciones de contratos usan toque/E directo; permanecen las validaciones del servidor.

La herramienta permitió un desplazamiento táctil completo de la lista, pero sus arrastres muy breves limitaron la revisión extensa: no se certifican las 56 filas individualmente en móvil. Se inspeccionó una vista vertical de Studio; el juego conserva su orientación horizontal, sin declarar soporte vertical. Los posicionamientos de prueba no equivalen a caminar toda la actividad con el joystick. No se probó teléfono físico. [Registro y alcance](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/mobile-native-review.json), [colocación](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/mobile-manual-placed.png), [confirmación de venta](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/mobile-sale-confirmation.png).

## 7. Verificación y límites

| Evidencia | Resultado y alcance |
|---|---|
| [Primer recorrido](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/first-flow-play.json) | **54/54 unitarias; 19 comprobaciones del recorrido aprobadas.** Cuenta nueva con 500, contrato/reliquia/recompensa real, compra/colocación/descubrimiento, primera vigilia, mejora a 6 y guardado reconocido. |
| [Primera recarga](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/first-flow-reload.json) | **5 comprobaciones aprobadas:** nivel, ritual, contrato, UID/posición y seis pedestales desde el journal real. |
| [Integración completa](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/full-integration-play.json) | **350/350 comprobaciones aprobadas** sobre servicios de producción: diez niveles, doce contratos, cinco rituales, repetición/distancia/ocupación, muerte/reinicio, venta, estilos y exhibidor. |
| [Recarga avanzada](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/full-profile-reload.json) | **5 comprobaciones aprobadas:** nivel 10, estilo Observatorio, capacidad 30, rituales y UIDs/posiciones reconstruidos. |
| [Recarga real sin colocar](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/unplaced-native-reload.json) | Grave Hopper conserva UID y propiedad como `UNPLACED` tras Stop/reinicio, sin pedestal ni retorno automático. Producción de las otras cinco: 20,75 Souls/s. |
| [Gameplay de remodeladas](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/native-production-play.json) | **15 comprobaciones aprobadas**: IDs, compra, colocación, venta y limpieza de las tres. El registro global indica `FAILED` por un módulo QA espacial; no invalida esas 15 ni aprueba el recorrido espacial. |
| [Revisión visual nativa](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/native-visual-review.json) | Tres remodeladas observadas a distancia de juego y en tres estados; vídeos de 30 segundos y poses conservados. |
| [Dos clientes](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/multiplayer-summary.json) | **478/478 comprobaciones aprobadas**, niveles 10/2, seis Curses reales, propiedad, compra, transporte, reubicación, venta y entrega de reliquia. Cierre de 40 s y recuperación de 60 s medidos sin acortar el reloj. |
| [Recorrido entre pisos](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/native-spatial-final.json) | The Void comprada, 54 tramos caminando, colocación manual en piso 3 y vuelta al piso 1; mínimo de apoyo medido 0,12 studs. |
| [Migración y cambio de base](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/persistence-native-reload.json) | **38 comprobaciones iniciales y 40 de recarga aprobadas**, perfil antiguo, muerte real, dos UIDs conservados, contrato/token recuperado y entrega manual válida en Base04. |
| [Móvil emulado](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/mobile-native-review.json) | Toques reales de UI/prompts, primera mejora/ritual, estilo, reliquia y recoger/colocar; alcance parcial de desplazamiento de listas documentado. |
| [Carga de ocho bases finales](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/performance-native-review.json) | **20/20 comprobaciones aprobadas**, más **13/13 de arquitectura**: 56 skins cargadas, suspensión, reanudación, limpieza y colisiones conservadas tras el acabado de fachada. |
| [Integridad del build](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/build-proof.json) | **66/66 fuentes exactas y 56/56 plantillas con skinning/payload nativo** tras la última corrección. No monta scripts QA; esta prueba estática no equivale a Play. |

Las pruebas amplias usan posiciones de setup teletransportadas que siguen pasando las validaciones del servidor. Se declararon semillas QA de recursos, descubrimientos Common/Rare y algunos hitos para alcanzar todos los niveles; no representan progresión ganada jugando ni tiempos de balance reales. La primera mejora sí usa compra, contrato y ritual efectivos. Los espacios de perfiles QA están aislados de cuentas normales.

Los [16 vídeos multijugador](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/videos/multiplayer-captures.json) conservan dueño/observador para protección, reliquia y seis Curses. La revisión de fotogramas muestra réplica y geometría; algunos quedan tapados por ofertas normales de la procesión o el avatar junto al pedestal. No se convierte esta revisión en 56 aprobaciones nuevas. Las medidas de cuadro de los dos procesos fueron distintas (aproximadamente 30–35 ms en dueño y 13–15 ms en observador durante estas muestras), con captura nativa activa y ventanas de tamaño diferente; no son una prueba de teléfono ni de latencia simulada.

### Rendimiento y límites de la revisión

La muestra nativa final usa ocho bases etapa 10, tres estilos, 56 representaciones sin propiedad/ingresos y hasta 20 ofertas normales, con controladores de producción. Viewport 1639 × 682, captura nativa activa durante las muestras con modelos. Carga de las 56 skins: **1,024 s con caché local disponible**; no es una prueba de descarga fría.

| Muestra | FPS medio | Cuadro medio / p95 |
|---|---:|---:|
| Ocho bases, sin las 56 representaciones | 103,5 | 9,66 / 13,35 ms |
| 56 de cerca | 85,8 | 11,66 / 15,03 ms |
| Distancia media | 90,9 | 11,00 / 14,50 ms |
| Lejos | 96,5 | 10,36 / 13,76 ms |
| Regreso de cerca | 85,3 | 11,73 / 15,76 ms |
| Después de destruir las 56 | 105,7 | 9,46 / 13,03 ms |

Las bases finales tienen **268/281/276 partes** según estilo, dos luces cada una y presupuesto 300. En el conjunto se midieron 5.916 partes, 1.174 MeshParts y 23 luces de mapa. La animación pasó de unas 5.853 escrituras de hueso/s de cerca a cero lejos y reanudó al regresar; al retirar las 56 quedó seguimiento de 20/20 modelos vivos, sin sus registros residuales. Estas cifras incluyen Studio y captura; no son tiempo CPU aislado, resultados de teléfono ni una garantía de FPS en otros equipos. La cámara media tapa parte del interior: este ensayo de carga no aprueba visualmente las 56 especies.

[Vídeo nativo final](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/videos/performance-8-bases-56-models-native.mp4), [fotogramas revisados](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/videos/performance-8-bases-56-models-contact.png). Se conserva la muestra previa en `performance-before-facade.json` y `performance-before-facade-native.mp4`; no se interpreta la diferencia de FPS entre sesiones como una mejora causal de la fachada.

Fuera de las verificaciones autorizadas/disponibles: persistencia online y teléfono físico sin entorno de prueba; robo de colección no operativo; marchas de Music Box Dancer/Marrow Dice aplazadas expresamente. No se declara aprobación nueva de las 56 animaciones ni contacto perfecto en cada cuadro de poses muestreadas.

## 8. Reconstrucción y apertura

El proyecto normal usa `default.project.json`, las fuentes actuales y el kit nativo conservado. Los fixtures de QA no se montan en esa configuración. Para reconstruir localmente con Rojo ya instalado:

```powershell
Set-Location 'C:\RobloxProjects\StealACurse'
& "$env:USERPROFILE\.rokit\bin\rojo.exe" build .\default.project.json --output .\build-sanctuary-restoration-update.rbxlx
```

Comprobación estática reproducible, después de reconstruir:

```powershell
& 'C:\Users\vbran\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' .\tools\Verify-PolishedBuild.py --build .\build-sanctuary-restoration-update.rbxlx --output .\assets\review\sanctuary-restoration\build-proof.json
```

Para abrir la entrega:

```powershell
Start-Process -FilePath 'C:\RobloxProjects\StealACurse\build-sanctuary-restoration-update.rbxlx'
```

**Cierre de entrega comprobado.** Se abrió el archivo final en una instancia nueva de Studio, se compararon sus 66 fuentes con los archivos actuales y se inició con F5, sin scripts QA ni comandos manuales de inicialización. Perfil normal `READY`/`SAVED`, migración de datos anterior conservada, ocho bases, interfaces de administración/restauración y procesión funcionando; las tres remodeladas aparecieron con los IDs registrados, skinning y carga `Success`. La consola leída no tenía errores bloqueantes. El saldo local de pruebas anterior se conservó y no se usó para equilibrar la actualización.

Se detuvo Play, se guardó desde Studio y se verificó nuevamente el archivo guardado: **66 fuentes exactas / 56 plantillas nativas aprobadas**. Queda abierto en primer plano, con Play detenido, listo para F5. En Edit la vista azul es esperada: el mapa se genera al iniciar Play.

Evidencia: [fuentes observadas desde disco](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/final-studio-source-proof.json), [arranque normal](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/final-release-startup.json), [captura de Play](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/final-release-f5-native.png), [archivo abierto y detenido](C:/RobloxProjects/StealACurse/assets/review/sanctuary-restoration/visuals/final-release-ready-native.png). SHA-256 del `.rbxlx` final guardado: `db91b82cafea873176a85334e6efa9eadd09e7e787ec0c676c0b23b3064aaa1c`.
