# Steal A Curse — segunda pasada visual

Entrega local del **2 de octubre de 2026**. Archivo final: [build-curse-visual-pass2.rbxlx](../build-curse-visual-pass2.rbxlx), abierto en Studio y preparado para **F5 / Play**. El mapa se construye al iniciar Play. No se publicó la experiencia ni se hizo commit, push o merge.

## Resultado y evidencia

**56 Curses observadas y ajustadas; 30 mallas reimportadas realmente desde Blender:** seis rediseños completos y 24 mejoras de geometría, proporciones o materiales. Las otras 26 conservan su malla anterior, con escala propia y nueva presentación. No se cuentan como 56 modelos reconstruidos.

- [Galería de las 56](../assets/review/curse-pass2/index.html): capturas reales de Play, avatar de ≈5,74 studs y cámara de 65°. Hay **30 pares individuales a 22 studs**. Para las otras 26, el antes corresponde a grupos de cuatro a 22–25 studs; esa diferencia está indicada.
- [Medidas, fuentes Blender, FBX e IDs de las 56](CURSE_VISUAL_PASS2_MEASURES.csv), en orden **ancho × alto × profundidad**, observadas en Studio; [datos de comparación](../assets/review/curse-pass2/measures-56.json).
- [30 importaciones vigentes](../assets/imports/curse-visual-pass2-current.json): MeshIds observados, tamaños nativos, fuentes editables y SHA-256 de Blender/FBX. Las revisiones anteriores permanecen como historial; Coin Crawler y Cold Teacup usan sus importaciones posteriores indicadas en este registro.
- [Estado individual final](../assets/review/curse-pass2/final-status-56.json) y [verificación de la entrega](../assets/review/curse-pass2/final-delivery-proof.json).

La auditoría inicial clasificó seis rediseños, 20 mejoras de geometría/materiales y 30 de escala/presentación. Se amplió el trabajo de malla a cuatro de estos últimos. Studio tenía 15 IDs antiguos respecto del proyecto en disco: se registró la discrepancia, se conservó la sesión original y se revisaron archivos nuevos. Las fuentes previas están preservadas en `assets/review/curse-pass2/baseline/frozen`.

## Curses trabajadas

**Reconstruidos:** Cursed Doll, Haunted Mirror, Crying Mask, Watching Eye, Soul Chains y The Void. La muñeca tiene tela, costuras y pelo; el espejo, marco profundo y aparición; la máscara, huecos reales y lágrimas; el ojo, dos brazos con manos y puños; las cadenas, eslabones, grilletes y llama ámbar. **The Void** es una gran grieta vacía de bordes fracturados y fragmentos, con movimiento de efecto en su contorno.

**Fuentes existentes mejoradas y reimportadas:** Pale Guest, Cold Teacup, Coin Crawler, Pale Gramophone, Thorn Cathedral, Cathedral Heart, The Last Star, Blood Moon Rose, Eclipse Stag, Grave Key, Hollow Throne, Hourglass Hound, Judgement Scales, Mourning Ribbon, Nail Beetle, Night Harp, Raven Quill, The Last Funeral, The Unwritten, Thorn Reliquary, Umbrella Wraith, Veil Mourner, Wilted Sprout y Worldroot.

Se reforzaron volúmenes y contrastes visibles: cerámica fría y vapor curvado en Teacup; cuerpo ancho y monedas en Crawler; bocina abierta marfil y base de madera en Gramophone; rosetón y contrafuertes en Cathedral; corazón marfil con grieta dorada en Cathedral Heart; estrella de ocho puntas y jaula abierta en Last Star. Las paletas, materiales pintados y focos son propios de cada concepto. El máximo entre las 30 mallas actuales es **8.122 triángulos**; no se subdividieron por aumentar detalle sin propósito.

Fuentes: `assets/source/blender/curses_visual_pass2`, incluidas `revision02` y `batch02`; FBX: `assets/export/meshes/curses/visual-pass2`. Se conservaron las fuentes `.blend` reutilizadas y las comprobaciones locales de geometría y exportación. La aprobación visual procede de Studio, no de renders de Blender.

### Casos representativos: dimensiones observadas

| Curse | Antes, studs | Después, studs |
| --- | --- | --- |
| Cursed Doll | 2,46 × 3,24 × 1,05 | 2,97 × 4,80 × 2,06 |
| Haunted Mirror | 2,66 × 4,04 × 0,59 | 3,56 × 7,00 × 0,71 |
| Crying Mask | 2,11 × 3,05 × 0,87 | 5,53 × 5,80 × 1,62 |
| Watching Eye | 3,82 × 2,68 × 1,15 | 9,60 × 6,50 × 2,18 |
| Soul Chains | 4,02 × 2,60 × 0,92 | 6,61 × 9,50 × 2,40 |
| The Void | 4,17 × 4,45 × 1,67 | 10,26 × 12,60 × 1,96 |
| Pale Guest | 2,51 × 2,94 × 0,87 | 3,80 × 4,80 × 1,68 |
| Cold Teacup | 2,71 × 2,48 × 2,47 | 5,00 × 4,90 × 4,88 |
| Coin Crawler | 2,77 × 1,15 × 2,54 | 5,80 × 3,20 × 4,10 |
| Pale Gramophone | 3,35 × 4,10 × 2,77 | 5,53 × 6,20 × 4,39 |
| Thorn Cathedral | 2,77 × 4,06 × 1,98 | 5,60 × 8,20 × 3,99 |
| Cathedral Heart | 2,94 × 4,48 × 1,67 | 6,60 × 9,60 × 3,59 |
| The Last Star | 3,88 × 4,62 × 2,09 | 8,50 × 11,40 × 4,80 |

## Escala, juego y presentación

Alturas finales por concepto: Common **3,2–5,2**, Rare **3,6–7**, Legendary **6,5–8,6**, Mythic **8,9–10,2** y Secret **10–12,6** studs. Las criaturas bajas compensan con anchura; no se aplica un multiplicador idéntico. Nameless Door queda en 9,995 studs por su profundidad.

El límite anterior de diagonal de 7 studs se sustituyó por límites de **11 × 13 × 6**. La malla visible no tiene colisión, contacto ni consultas físicas; el prompt conserva alcance de 12 studs. El transporte calcula separación lateral y posterior a partir del tamaño, con oscilación moderada. Los soportes de los pedestales miden 5,6 × 5,6 y sus centros están separados al menos 13 studs.

La procesión mantiene seis ofertas, velocidad de 6,5 studs/s y cadencia de 10 s. En las 20 rutas completas de la última tanda, la separación conservadora mínima observada fue **43,82 studs**, sin solapamiento. Se comprobaron suelo, transporte, entrega y altura sobre pedestal.

Letreros: **202 × 98 → 152 × 66 píxeles**, con nombre, rareza, ingreso y precio; hasta dos cercanos y uno colocado, evitando solapamiento entre tarjetas. El prompt se desplaza hacia los pies. El precio se conserva también al transportar y colocar; la instrucción de regreso aparece en el aviso del HUD.

Los efectos usan perfiles por concepto, anclajes semánticos y un actualizador compartido de 20 Hz. Límite de escritorio: **20 emisores activos y dos luces**; móvil: **12 emisores y ninguna luz activa**, con apagado por distancia. Se verificaron los anclajes de bocina, platillos, pluma, relicario y velo, y el movimiento del contorno de Void. No se añadieron sonidos ni animación de rig compleja. Se revisó la legibilidad de los modelos con la iluminación nocturna existente; sus parámetros no se modificaron en esta pasada.

## Pruebas reales en Play

| Comprobación | Resultado / evidencia |
| --- | --- |
| 56 compras, transporte, entregas, pedestales e ingreso Souls | **56/56**, cero fallos: [informe final](../assets/review/curse-pass2/gameplay-final56-observed.json) |
| Rutas completas de las mallas de la última tanda, Void y Nameless Door | **20/20**; las otras 36 conservan la geometría/escala de la [prueba anterior de 56 rutas](../assets/review/curse-pass2/gameplay-batch01-observed.json) |
| 13 casos representativos en móvil emulado, incluidos los seis originales | **13/13**, compra/entrega/VFX y precio sin truncamiento: [informe móvil](../assets/review/curse-pass2/gameplay-mobile13-observed.json) |
| Inicio del archivo final sin pruebas incorporadas | **PASS**: 56 IDs coincidentes, procesión natural, avatar sano, santuario reclamado con E, salida sin errores: [observación](../assets/review/curse-pass2/final-production-play-observed.json) |

Las pruebas de 56/13 usaron los servicios de producción y prompts nativos, con selección determinista de ofertas, Souls iniciales de prueba y traslado del avatar para repetir los casos. Incluyen observaciones reales de mallas, efectos, transporte, pedestal e ingresos; no equivalen a recorrer manualmente las 56 con un jugador. Las capturas de apariencia se observaron separadamente. La última corrección fue exclusivamente mantener el precio en los letreros de entrega/pedestal: se comprobó después en los 13 casos móviles. El informe de 56 conserva las huellas anteriores a esa corrección.

The Last Funeral necesitó esperar la carga de su malla; la evidencia aprobada es `review03/the_last_funeral-play-avatar-recheck.jpg`. La toma inicial vacía permanece como historial y no certifica su aspecto.

### Rendimiento observado: 46 modelos

Carga de prueba: 40 modelos de presentación y seis ofertas reales, sin agregar ingresos ni Curses poseídas. Ventana cercana de 15 s; incluye el coste de observación de la prueba.

| Cliente de Studio | Viewport real | Media por fotograma | Percentil 95 | Emisores / luces activos máximos |
| --- | --- | ---: | ---: | ---: |
| Escritorio | 940 × 515 | 9,13 ms | 13,78 ms | 20 / 2 |
| iPhone 17 Pro emulado, táctil activo | 749 × 361 | 10,95 ms | 15,98 ms | 12 / 0 |

El simulador se configuró en horizontal a 874 × 402; la tabla recoge el viewport que informó el cliente. Cero fotogramas mayores de 33 ms en esas ventanas. A distancia, emisores y luces activos bajaron a cero; la limpieza retiró los 46 modelos. **Estas cifras pertenecen al ordenador ejecutando Studio, no a un iPhone físico.**

## Pendientes reales y prioridad

1. Medir en un teléfono físico de gama media, especialmente temperatura, memoria y carga inicial de mallas; revisar allí los textos a tamaño de pantalla real.
2. Comprobar robo y replicación con dos jugadores. Las compras y entregas de esta pasada se verificaron con un cliente; no certifican una sesión multijugador.
3. Si se continúa la autoría, priorizar **Nameless Door, Crown of Silence, The First Grave, Plague Monarch y The Undertow** por rareza. Están revisadas, escaladas y jugables, pero conservan la geometría previa. Las otras 21 de ese grupo también están identificadas en el CSV y el estado individual. No se declaran nuevos Blender/FBX para estas 26.

Los archivos y capturas quedan guardados por tanda. La galería y los registros permiten continuar desde este estado sin sustituir las pruebas ni perder las versiones anteriores.
