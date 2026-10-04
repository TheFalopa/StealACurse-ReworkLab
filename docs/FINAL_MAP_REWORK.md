# Steal A Curse — informe del rediseño del entorno

Fecha de revisión: **30 de septiembre de 2026**, zona America/Bogota. Rama: **`feature/final-map-rework`**. Los cambios del lugar y del repositorio permanecen locales para revisión. Las doce mallas originales sí se importaron como assets de Roblox mediante el flujo autorizado de Studio.

**La implementación y las pruebas del alcance autorizado están completas.** Se recomienda revisar el resultado visual y jugar con personas antes de decidir su incorporación; esa revisión no bloquea la entrega local.

Este informe cubre los 36 puntos solicitados. Los tiempos proceden de un personaje real en Play con `WalkSpeed = 16`; la asistencia dirigió `Humanoid`/Pathfinding. La revisión distingue esos recorridos de los cálculos de distancia y de las pruebas aisladas que preparan estados de juego.

1. **Observaciones iniciales.** La rama requerida tenía el árbol de trabajo limpio antes de editar. El proyecto ya conservaba el ciclo de reclamar, comprar, transportar, entregar y producir Souls; sus dependencias eran hijos directos con nombres estables. El suelo anterior medía 480 × 480 studs, los centros de los santuarios estaban a 166–183 studs y el radio de referencia del borde era 226. Las referencias se aplicaron según su contenido visible: imagen 1 para profundidad de bosque/cementerio, imagen 2 para la mansión central, imagen 3 para iluminación y contraste, e imagen 4 para el lenguaje de módulos de Halloween. Esto resuelve la numeración intercambiada del texto sin copiar sus composiciones.

2. **Diseño general elegido.** Un castillo central, **Hollow Crown Sanctum**, organiza ocho territorios de jugador. Caminos curvos, doce parcelas familiares, una capilla derrumbada, árboles monumentales y taludes interrumpen la simetría a altura de personaje. La red de pasos centrales y senderos transversales permite acercarse, cambiar de base y escapar; los elementos periféricos aportan profundidad visual sin introducir misiones, poblaciones ni progresión de zonas.

3. **Huella jugable anterior y nueva.** El soporte físico pasa de 480 × 480 a **620 × 610 studs**: 230,400 → 378,200 studs², un incremento aproximado del 64%. El área contenida por el borde jugable irregular se aproxima mediante su radio de referencia: 226 → **282 studs**, aproximadamente **1.56 veces** la superficie anterior. La continuación visual final utiliza nueve tiles planos de 2,048 × 2,048, formando **6,144 × 6,144 studs** sin colisión; los elementos lejanos son fondo, no terreno jugable adicional. La tabla comparativa más abajo especifica qué mide cada cifra.

4. **Rediseño del castillo.** Se sustituyó el mausoleo compacto por alas de diferente altura, nave elevada, gabletes escalonados, contrafuertes y tres torres asimétricas. El campanario occidental alcanza aproximadamente **107.5 studs antes de la elevación global de 1 stud**; las torres menores alcanzan aproximadamente 66 y 68. Ventanas góticas, un rosetón con ojo ocultista, guardianes de piedra, raíces y cadenas forman una identidad original. El corredor bajo la nave permanece abierto de norte a sur para conservar el acceso de los santuarios traseros.

5. **Entrada de las Curses.** La entrada principal mira hacia +Z y el `CurseSpawnPoint` sigue siendo hijo directo de `CentralMausoleum`, situado en **(0, 2, 0)** antes de elevar el mapa. Un arco de 26 × 29 × 3.2 studs deja aproximadamente **17.16 studs de apertura** en su geometría importada. El umbral es bajo, el velo violeta no tiene colisión y el jugador puede ver y atravesar el pasaje. Runa vertical, faroles, velas y niebla discreta refuerzan el origen visible de los objetos.

6. **Ruta de la procesión.** Se mantuvieron los offsets y el funcionamiento de `CurseProcessionService`. La presentación incorpora adoquines bajos, inlays tenues y vigilias en los laterales. El trazado mide aproximadamente **183.531 studs**. La revisión final tomó **197 muestras con una esfera de radio 3.5**, sin candidatos de colisión sólida ni segmentos sin suelo. La única caja de malla candidata fue el arco principal: su caja contiene el hueco real de la puerta y se revisó visualmente. Se observaron tres Curses simultáneas y 22 salidas naturales de objetos sin comprar; un ciclo observado duró aproximadamente 28.07 segundos hasta el final cercano a (0, 5, 28).

7. **Rediseño de los santuarios.** Hay exactamente **Base01–Base08**, cada territorio de 60 × 66 studs. Una entrada de 30 studs de ancho, muros bajos interrumpidos, rejas, tierra elevada, vigilia familiar y un árbol periférico distinguen sus límites. La colección ocupa una terraza recortada con dos pares de pedestales laterales y un pedestal protagonista al fondo. El corredor central y las aperturas laterales permiten entrar y salir sin depender de un único paso estrecho.

8. **Lógica de separación.** Los centros se sitúan a **214–224 studs** del origen; antes estaban a 166–183. La separación geométrica entre centros vecinos aumenta de aproximadamente **112.39–158.48** a **153.68–178.75 studs**. Los ocho sitios conservan la misma estructura funcional, con pequeñas variaciones de ángulo, elevación y decoración. Dieciséis rutas de navegación —ocho al patio central y ocho a la base vecina— devolvieron `Success`. Las rutas colección → patio central midieron aproximadamente **223–279 studs**, razón máxima/mínima **1.249**; esa diferencia debe seguir revisándose durante pruebas de persecución con jugadores.

9. **Terreno.** El suelo sólido cubre todo el borde invisible para evitar caídas antes de alcanzarlo. Parcelas elevadas, hombros de tierra, taludes, masas de suelo de santuario y variaciones de color sustituyen el plano uniforme. `Layout` reserva corredores para no colocar vegetación o relieves sobre los caminos y la procesión. Rampas amplias conectan los santuarios con elevaciones de 0–2 studs; los recorridos cronometrados finalizaron con **cero saltos**.

10. **Cementerio.** Se compusieron **doce parcelas familiares** con filas, losas, memoriales mayores, fragmentos de reja, velas y esquinas derrumbadas. Las criptas secundarias, ruinas y monumentos se agrupan fuera de los corredores reservados. La validación del mapa confirmó que las doce parcelas previstas sobrevivieron al filtrado de espacio y se construyeron.

11. **Bosque.** Los tres árboles existentes se reutilizan con escala y orientación variables; las nuevas siluetas gigantes aportan ramas y raíces exageradas. Copas ocasionales de tonos rojizos y naranja enmarcan la piedra azulada. La distribución respeta rutas y claros de monumentos. Las ramas decorativas no colisionan; los troncos que delimitan paso usan formas simples de baja altura.

12. **Fondo y borde del mundo.** El contorno deja de ser un cerco visual regular: masas rocosas fragmentadas, bosque externo, árboles gigantes, acantilados lejanos y tres campanarios perdidos ocultan el límite. Nueve tiles sin colisión ni sombras alejan el borde visual del suelo a 3,072 studs del origen; cada parte respeta el límite de tamaño de 2,048 studs. El suelo de soporte de 620 × 610 se volvió invisible, manteniendo sus dimensiones y colisión. Una barrera invisible segmentada contiene el área jugable; su cobertura completa sobre ese soporte se comprobó en la validación final.

13. **Iluminación.** La paleta base es azul/índigo con piedra más legible, madera oscura y toques otoñales. El castillo recibe violeta y ventanas cálidas, los accesos de santuarios cian y las vigilias naranja. La configuración final mantiene noche a las 1.2, `Brightness = 3`, `ExposureCompensation = 0.9`, `ShadowMap`, atmósfera con densidad 0.28 y bloom moderado de intensidad 0.25. La niebla usa referencias 180–640 studs. La exposición global ayuda a leer caminos y cuerpos del edificio; el neón se limita a focos e inlays.

14. **VFX.** Todo el entorno utiliza **un ParticleEmitter**, en la entrada del castillo, a tres partículas por segundo y vida de 3–4 segundos. Usa la textura integrada `rbxasset://textures/particles/smoke_main.dds`, con transparencia elevada. No existen bucles de animación del entorno por frame; cristales, fuego y ventanas estáticas emplean materiales emisivos.

15. **Archivos modificados.** `README.md`; `default.project.json`; `assets/README.md`; `src/server/Map/AssetKit.luau`, `Build.luau`, `Cemetery.luau`, `Config.luau`, `Decorations.luau`, `Landmarks.luau`, `Mausoleum.luau`, `PlayerShrine.luau`, `TerrainArt.luau` y `World.luau`; `src/client/UI/HUD.luau`; `tests/Build-StudioFixture.ps1` y `tests/Slice.client.luau`. El único cambio de cliente de producción adapta posición/tamaño del HUD en pantallas menores de 900 píxeles para dejar libre el centro. El helper de prueba repite de forma acotada el input real de un prompt recién replicado. `src/server/Gameplay` y `src/shared` no presentan diferencias; economía, labels y reglas conservan su implementación.

16. **Archivos creados.** `src/server/Map/Layout.luau`; `tests/AllBases.server.luau`, `tests/FinalMap.server.luau` y `tests/FinalWalk.client.luau`; `assets/FINAL_ENVIRONMENT.md`; este informe; el `.blend`, los dos scripts, dos JSON, preview y doce FBX detallados en los puntos siguientes. Las capturas reales de revisión y su inventario enlazado están guardados en `docs/review/`; también se conservaron `validation-results.json`, `all-bases-results.json`, `slice-test.log`, `all-bases-test.log` y `git-status.txt` en esa carpeta. El inventario global cuenta **47 archivos nuevos**, incluidas capturas, assets y documentación. Los proyectos, lugares y mapas de código generados para pruebas quedan ignorados por Git.

17. **Fuente Blender.** `assets/source/blender/steal_a_curse_final_environment.blend`, generado con Blender 5.2.2 LTS. Contiene colecciones por módulo, origen centrado en sus límites, transformaciones limpias y un material sencillo por malla. Los archivos `steal_a_curse_kit.blend` y `steal_a_curse_curses.blend` y sus exportaciones anteriores se conservan.

18. **Scripts auxiliares.** `assets/source/blender/generate_final_environment.py` reproduce las fuentes y exportaciones; `validate_final_environment.py` reimporta los FBX y comprueba nombres, malla única, escala, límites, triángulos, superficies cerradas y ausencia de caras degeneradas. `final_environment_manifest.json` conserva métricas e importaciones reales; `final_environment_geometry.json` permite inspección local de geometría. `tests/FinalMap.server.luau` valida contratos, límites, suelo y navegación; `FinalWalk.client.luau` mide recorridos físicos; `AllBases.server.luau` ejercita las ocho bases. Estos fixtures quedan fuera del proyecto de producción.

19. **FBX nuevos.** Se crearon doce exportaciones de malla individual bajo `assets/export/meshes/`, con nombres `final_gothic_doorway`, `final_gothic_window`, `final_crooked_roof`, `final_buttress`, `final_collection_pedestal`, `final_iron_fence`, `final_pumpkin`, `final_giant_tree`, `final_cliff_cluster`, `final_hero_grave`, `final_lantern` y `final_chain`. La tabla de assets incluye el sufijo `.fbx` implícito. Las doce pasaron la reimportación de validación.

20. **MeshIds importados reales.** Los doce assets se importaron mediante el 3D Importer de Studio. `MeshId`, `InitialSize` y `Size` se leyeron de los MeshParts importados y se registraron en el manifest y en `ServerStorage.MapMeshKit` de `default.project.json`. Todas las entradas están marcadas `verified_actual_studio_import`; la tabla inferior reproduce sus IDs verificados. Los pequeños decimales de tamaño se conservan exactamente en el manifest y en Rojo.

21. **Triángulos de cada malla.** La tabla registra entre 34 y 480 triángulos por módulo, **2,468 triángulos únicos nuevos** en total. Sumados al kit de entorno existente, hay aproximadamente 3,728 triángulos de fuentes de entorno antes de instanciar. Estas cifras no equivalen al coste de dibujo de las 500 instancias del mapa.

22. **Mallas únicas.** Hay **12 módulos nuevos**, **24 plantillas de entorno** disponibles y **21 MeshIds distintos utilizados** en el entorno generado final. Los seis modelos de Curse constituyen un kit independiente. No se incorporó geometría externa ni se sustituyeron sus definiciones.

23. **MeshParts ambientales.** La cuenta en Play fue **500**, excluyendo los modelos de `ActiveCurses`. Todas las instancias proceden de plantillas verificadas reutilizadas. El contexto de conteo es el mapa completo construido, con la inicialización de las bases.

24. **BaseParts.** El mapa inicializado final contenía **1,815 BaseParts**, incluyendo sus 500 MeshParts y los ocho `ClaimMarker` creados por el servicio. Los ocho tiles visuales adicionales explican el incremento frente a la medición intermedia de 1,807. Había **414 partes con colisión** y **cero partes ambientales sin anclar**. Los detalles visuales usan colisión simple separada cuando es necesaria; no hay simulación física de decoración.

25. **Luces.** Se contaron **13 luces ambientales**: tres en el castillo, una por santuario y dos en puntos principales del entorno. Ventanas, la mayoría de faroles, velas y marcas luminosas no añaden luces. Las luces propias de una Curse activa, como The Void, quedan fuera de esta cuenta ambiental.

26. **ParticleEmitters.** **Uno**, habilitado en el umbral del castillo. No se añaden emisores a todas las bases ni a todo el bosque. El consumo depende también de la calidad gráfica y de la superposición de transparencias; no se midió el coste en un dispositivo real.

27. **Tiempos de viaje.** La tabla inferior resume Play real. Tras el último cambio del mapa, Base03 → castillo/procesión tomó **13.872 s** y el retorno llevando Cursed Doll **18.018 s**, con cero saltos. Se retienen las mediciones previas de Base07: llegada desde `PlayerSpawn` **13.69 s**; retorno con Haunted Mirror **16.29 s**; colección → castillo **15.99 s** y regreso **15.97 s**; vecino Base07 → Base08 **13.15 s**; cruce Base08 → Base04 **33.22 s**. Se usó el personaje normal a velocidad 16, sin teletransporte ni crédito de Souls en los ciclos de producción. Son medidas aproximadas de rutas concretas asistidas, no un promedio de sesiones humanas.

28. **Compatibilidad del ciclo de Curse.** El último ciclo normal, ejecutado **después del último cambio del mapa**, reclamó Base03 y compró mediante interacción real una **Cursed Doll natural de 100 Souls**. El saldo pasó de 500 a 400; durante transporte no produjo ingreso. Tras caminar de vuelta apareció en el slot 1, HUD y tasa mostraron **+3 Souls/s** y el saldo observado alcanzó **644.63**. Se conserva también el ciclo anterior de Base07 con Haunted Mirror natural: precio 450, saldo 500 → 50, slot 1 y **+10 Souls/s**. Se comprobó la procesión con varios objetos y la salida de objetos sin vender. El sistema de robo y sus efectos futuros queda fuera de esta implementación.

29. **Validación de reclamar bases.** Los ocho contratos de base, sus `PlayerSpawn`, área de entrega, marcador de reclamo y prompt pasaron en la validación del mapa. Base07 y, después del último cambio, Base03 también se reclamaron en Play de producción con entrada real. La repetición final, posterior al último World y HUD, alcanzó **`ALL_BASES_DONE`**, con reporte `status = passed`: ocho reclamos con prompts reales, propietario autoritativo, atributo de base y `RespawnLocation` correctos. Dos repeticiones previas agotaron el tiempo del primer prompt por su registro inicial en el cliente del fixture; se corrigió únicamente el helper de pruebas para repetir hasta seis inputs reales acotados y se completó de nuevo toda la suite. No se cambió el servicio de producción ni se disparó `Triggered` artificialmente. Se utilizó un cliente y ocho contextos de mapa/servicios recreados secuencialmente, con teletransporte y crédito sólo para preparar pruebas; no representa ocho dueños simultáneos ni una carrera entre clientes.

30. **Validación de cinco pedestales.** Se comprobaron **40 slots directos**, separados al menos nueve studs y contenidos en sus áreas de entrega. Los ciclos de producción entregaron al slot 1 de Base07 y Base03. La repetición final **`ALL_BASES_DONE`** confirmó cuarenta compras con prompts reales y cuarenta entregas físicas por encima del pedestal esperado: cinco posiciones distintas por cada una de las ocho bases, tasa acumulada correcta y prompt de compra deshabilitado tras colocar. **`SLICE_DONE`** confirmó cinco slots únicos, HUD `+222 Souls/s` y los escenarios de rechazo, refund, pedestal/área eliminados, muerte, respawn y recreación del modelo. Esas suites aíslan escenarios con preparación de estados; el ciclo natural se probó aparte. El reporte final registra **8 contextos, 8 reclamos, 40 compras y 40 colocaciones verificadas**, sin fallos finales.

31. **Compatibilidad de las seis Curses.** Cursed Doll, Haunted Mirror, Crying Mask, Watching Eye, Soul Chains y The Void mantienen código, catálogo, mallas y lógica anteriores. **`SLICE_DONE`** probó los seis tipos, tamaño físico y ausencia de colisión; la repetición final **`ALL_BASES_DONE`** rotó las seis definiciones entre cuarenta compras y entregas en las ocho bases y confirmó las seis entradas de `definitionsCovered`. La muestra conservadora de la ruta cubre las dimensiones de sus raíces. Haunted Mirror y Cursed Doll se probaron de extremo a extremo en producción con apariciones naturales; Cursed Doll después del último cambio del mapa.

32. **Prueba visual móvil.** Se revisó el preset **Samsung Galaxy A06, 800 × 360**, con viewport interno de 706 × 339 y `TouchEnabled = true`. Se guardaron `docs/review/mobile-sanctuary.jpg` y `mobile-castle-before-hud.jpg`. La vista central mostró solapamiento entre HUD y labels de Curses; se ajustó únicamente `src/client/UI/HUD.luau` para usar un panel de 214 × 82 en la esquina superior derecha cuando el ancho sea menor de 900. **El nuevo Play confirmó ese tamaño y posición**, conservando el centro libre, y se guardó `docs/review/mobile-castle.jpg`. La emulación revisa composición y controles; no demuestra FPS en hardware móvil.

33. **Aspectos de rendimiento.** La escena usa geometría modular ligera, materiales simples, objetos anclados, trece luces y un único emisor. Aun así, **500 MeshParts/1,815 BaseParts**, sombras de árboles y fondo, vidrio/niebla transparentes y luces pueden afectar teléfonos modestos. Los nueve tiles planos del horizonte no colisionan ni proyectan sombras. No hay cifras verificadas de FPS, memoria ni tiempo de render en dispositivo real. La revisión de navegación y las cuentas de objetos confirman estructura y presupuestos, no un rendimiento objetivo.

34. **Limitaciones conocidas.** Los tiempos se midieron con movimiento asistido y deben contrastarse con jugadores; la navegación satisfactoria no prueba todas las persecuciones o cámaras. La detección de mallas por cajas no calcula intersecciones de cada triángulo; el arco candidato se revisó como geometría abierta. Existe un warning externo de carga de animación del avatar `114302219876492`, no introducido por cambios de mapa. El Play posterior al ajuste del HUD móvil, el ciclo normal posterior al último cambio del mapa y la repetición final completa de AllBases pasaron. Los dos timeouts iniciales pertenecían a la preparación del primer prompt del fixture y se resolvieron con el helper descrito en el punto 29. Las diez capturas de revisión final están guardadas y enlazadas. No se ha efectuado un benchmark móvil ni una nueva carrera de reclamos con dos clientes humanos; las ocho bases se probaron secuencialmente con un cliente.

35. **Revisión manual recomendada.** Abrir el lugar local construido desde `default.project.json`, iniciar Play y repetir reclamo → caminar al castillo → comprar una Curse natural → volver → confirmar pedestal, HUD y Souls/s. Revisar la entrada desde el frente y el corredor desde atrás; observar la procesión hasta desaparecer un objeto sin vender. Recorrer las salidas laterales de Base01–Base08 y dos rutas entre vecinos; comparar con un segundo jugador para escapes y fairness. Inspeccionar a altura de jugador el santuario, su salida, camino de cementerio, aproximación al castillo, puerta y seguimiento de una Curse; luego revisar desde arriba el mapa y su borde. En emulación móvil y en un teléfono real comprobar prompts/labels/HUD, sombras y legibilidad. La secuencia reproducible y las capturas se detallan abajo.

36. **Estado Git y validación estática.** Estado inicial: rama requerida y árbol limpio. El estado completo final, guardado en [git-status.txt](review/git-status.txt), registra **16 archivos ya existentes modificados** y **47 nuevos sin seguimiento**, incluidas capturas, assets y documentación. Los cambios siguen locales, sin commit, push, merge ni publicación del lugar. `git diff --quiet` confirmó ausencia de cambios en gameplay, shared, inicialización y labels del cliente. **La última ejecución de `rojo build`, `rojo sourcemap` y `git diff --check` pasó.** Los resultados finales están registrados en `docs/review/validation-results.json`. El lugar de producción y los datos vivos no se sobrescribieron; la importación sólo subió las doce mallas originales autorizadas.

## Comparación de escala

| Medida | Anterior | Nuevo | Interpretación |
| --- | ---: | ---: | --- |
| Suelo de soporte | 480 × 480 | 620 × 610 studs | +64% de área física; parte queda detrás del borde invisible |
| Radio de referencia jugable | 226 | 282 studs | Aproximación de superficie +56%; borde nuevo irregular |
| Radios de centros de bases | 166–183 | 214–224 studs | Separación mayor con trayectos cortos |
| Separación entre centros vecinos | 112.39–158.48 | 153.68–178.75 studs | Cálculo geométrico, no tiempo de marcha |
| Piso de territorio individual | 48 × 52 | 60 × 66 studs | +59% de área de santuario |
| Bases / slots | 8 / 40 | 8 / 40 | Mismos contratos funcionales |

## Kit nuevo e importaciones verificadas

Los nombres identifican los FBX bajo `assets/export/meshes/`. Límites X × Y × Z de Roblox en studs; los decimales minúsculos de importación se redondean en esta tabla. La precisión original está en `assets/source/blender/final_environment_manifest.json`.

| Módulo | Triángulos | Tamaño importado aproximado | MeshId verificado |
| --- | ---: | --- | --- |
| `final_gothic_doorway` | 112 | 20 × 25 × 3 | `rbxassetid://93984507446049` |
| `final_gothic_window` | 128 | 6 × 13 × 1 | `rbxassetid://111779363059681` |
| `final_crooked_roof` | 34 | 28 × 18 × 26 | `rbxassetid://88083283938508` |
| `final_buttress` | 68 | 4 × 18 × 7 | `rbxassetid://121418058164290` |
| `final_collection_pedestal` | 172 | 6 × 2.5 × 6 | `rbxassetid://136578707816851` |
| `final_iron_fence` | 244 | 12 × 7 × 1 | `rbxassetid://125211551490808` |
| `final_pumpkin` | 246 | 3.5 × 3 × 3.5 | `rbxassetid://85694347830310` |
| `final_giant_tree` | 464 | 40 × 52 × 30 | `rbxassetid://106911067618583` |
| `final_cliff_cluster` | 152 | 38 × 15 × 25 | `rbxassetid://102007331454332` |
| `final_hero_grave` | 120 | 7 × 11 × 3 | `rbxassetid://114437295252890` |
| `final_lantern` | 248 | 3 × 5 × 3 | `rbxassetid://126649242262975` |
| `final_chain` | 480 | 2 × 10 × 1.5 | `rbxassetid://137302239107896` |
| **Total nuevo** | **2,468** | **12 mallas** | **12 importaciones reales verificadas** |

## Recorridos físicos medidos

| Ruta real en Play | Tiempo | Método y alcance |
| --- | ---: | --- |
| Base03 → castillo/procesión | 13.872 s | Ciclo normal después del último cambio de mapa; caminata asistida |
| Procesión → entrega Base03, llevando Cursed Doll | 18.018 s | Mismo ciclo final, sin teletransporte ni crédito; cero saltos |
| Base07 `PlayerSpawn` → castillo/procesión | 13.688 s | Ciclo normal después de reclamar; caminata asistida |
| Procesión → entrega Base07, llevando Haunted Mirror | 16.288 s | Sin teletransporte, sin crédito de prueba |
| Colección Base07 → castillo | 15.990 s | Medición física de recorrido |
| Castillo → colección Base07 | 15.970 s | Medición física de recorrido inverso |
| Colección Base07 → colección Base08 | 13.146 s | Vecino; caminata asistida |
| Colección Base08 → colección Base04 | 33.224 s | Cruce del mapa; caminata asistida |

Todos usaron velocidad normal 16; cero saltos observados en estos recorridos. Las 16 rutas de navegación con resultado `Success` complementan las mediciones, pero sus longitudes divididas por 16 no se presentan como tiempos físicos de otras bases.

## Reproducir la revisión local

Desde `C:\RobloxProjects\StealACurse`, construir el lugar de revisión y su mapa de código:

```powershell
rojo build default.project.json --output build-final-map-review.rbxlx
rojo sourcemap default.project.json --output build-final-map-review.sourcemap.json
git diff --check
```

Abrir `build-final-map-review.rbxlx` en Studio. Ese lugar conserva la entrada de producción y sirve para la prueba de unirse, reclamar, comprar, entregar y producir. No publicar el lugar ni activar los fixtures en producción.

Las pruebas aisladas se reproducen por separado:

```powershell
./tests/Build-StudioFixture.ps1
./tests/Build-StudioFixture.ps1 -AllBases
```

Abrir respectivamente `build-slice-tests.rbxlx` y `build-slice-all-bases.rbxlx`, iniciar Play y mantener el viewport del cliente activo. Comprobar los marcadores finales de la suite; un mensaje parcial de PASS no significa que haya terminado. Los fixtures preparan créditos y estados para ejercitar casos aislados y no sustituyen el ciclo natural del lugar normal.

Para revisar contratos y navegación del lugar normal, ejecutar `tests/FinalMap.server.luau` mediante el datamodel servidor de Studio después de que termine la inicialización. El resultado requerido es `FINAL_MAP_PASS` acompañado del reporte completo. Volver a ejecutar las pruebas afectadas si se cambia el mapa o código después de la validación.

## Capturas de revisión

Son vistas reales de Studio. Las PNG que proceden de una captura JPG sólo recortan el viewport; no retocan ni regeneran el contenido de la imagen. La vista aérea utilizó la cámara en (180, 360, 270). El castillo anterior se conserva como referencia de comparación; las vistas nuevas corresponden al rediseño final.

| Vista | Captura local |
| --- | --- |
| Mapa completo desde arriba | [aerial.png](review/aerial.png) |
| Fachada del castillo | [castle-front.png](review/castle-front.png) |
| Entrada de las Curses y umbral | [castle-entrance.png](review/castle-entrance.png) |
| Camino del cementerio y aproximación al castillo | [cemetery-path.png](review/cemetery-path.png) |
| Parcela familiar del cementerio | [cemetery-family-plot.png](review/cemetery-family-plot.png) |
| Interior del santuario | [sanctuary.png](review/sanctuary.png) |
| Salida de un santuario | [leaving-sanctuary.png](review/leaving-sanctuary.png) |
| Trayecto entre santuarios | [between-sanctuaries.png](review/between-sanctuaries.png) |
| Emulación móvil tras adaptar el HUD | [mobile-castle.jpg](review/mobile-castle.jpg) |
| Castillo anterior para comparación | [baseline-castle.png](review/baseline-castle.png) |

Para comprobar el cambio móvil también se guardaron [el santuario emulado](review/mobile-sanctuary.jpg) y [el castillo antes de mover el HUD](review/mobile-castle-before-hud.jpg). Los datos de validación están en [validation-results.json](review/validation-results.json) y [el resultado final de las ocho bases](review/all-bases-results.json); los registros completos están en [slice-test.log](review/slice-test.log) y [all-bases-test.log](review/all-bases-test.log). Las suites cerraron con `SLICE_DONE` y `ALL_BASES_DONE`; el último reporte de AllBases registra `passed` tras verificar ocho reclamos y cuarenta colocaciones.

## Inventario Git final

| Tipo de archivo | Cantidad | Estado |
| --- | ---: | --- |
| Archivos existentes | 16 | Modificados localmente |
| Archivos nuevos | 47 | Sin seguimiento; incluye fuentes, FBX, capturas, informes y el archivo de estado |

El [estado Git completo](review/git-status.txt) conserva los nombres individuales. La rama sigue siendo `feature/final-map-rework`; no se creó ningún commit ni se hizo push, merge o publicación del lugar.
