# Music Box Dancer y Thorn Reliquary — corrección tras la prueba del usuario

2026-10-03. Entrega: [build-curse-animations-polished.rbxlx](C:/RobloxProjects/StealACurse/build-curse-animations-polished.rbxlx).

Se revisaron los tres vídeos del usuario y las fuentes Blender, pesos, huesos e IDs realmente abiertos en Studio. Ambas plantillas conservan skinning nativo. El problema de esta revisión era la legibilidad de las actuaciones, no la pérdida del rig: los gestos anteriores de la caja y el movimiento interno de la jaula eran demasiado contenidos.

## Cambios

- **Music Box Dancer:** vuelta completa en 4,8 s, frase musical de 6,4 s, brazo que presenta y cambia de gesto, mirada/reverencia de cabeza y cuerpo, pequeños golpes de bisagra. La caja queda plantada y la tapa conserva su posición originalmente abierta.
- **Thorn Reliquary:** cautivo con esfuerzo ascendente, giro lateral, respuesta retrasada de la punta y retroceso. La jaula no se balancea; su Root permanece fijo. Elevación máxima del esfuerzo: 0,38 studs de autoría, escalada por el controlador existente.
- Solo cambian estos actos en [Creatures](C:/RobloxProjects/StealACurse/src/client/CurseActsCreatures.luau) y [Objects](C:/RobloxProjects/StealACurse/src/client/CurseActsObjects.luau). No cambian geometría, pesos, jerarquías, pivotes, nombres ni IDs. No se hizo otra importación.
- Se conservó y sincronizó tu configuración actual de Studio: aparición secuencial de las 56 habilitadas, intervalo 3 s y máximo 20 en procesión. Es la configuración de prueba que elegiste; ahora está también en las fuentes del repositorio.

## Comprobación y evidencia

Revisión visual por el coordinador en Play nativo a una distancia de cámara de 16 studs, con avatar y las plantillas/controladores reales: ambas Curses en `PLACED`, `PROCESSION` y `CARRYING`. Se comprobó deformación visible de la figura y del cautivo, no solo cambios de Transform. En las poses muestreadas la caja/jaula permanece fija y las piezas móviles conservan su estructura.

- [Vídeo nativo después, 30,02 s](C:/RobloxProjects/StealACurse/assets/review/animations-polished/user-two-curses/after-native.mp4).
- [Caja musical, contacto de fotogramas](C:/RobloxProjects/StealACurse/assets/review/animations-polished/user-two-curses/music_box_dancer-contact.png) / [detalle recortado de los mismos fotogramas](C:/RobloxProjects/StealACurse/assets/review/animations-polished/user-two-curses/music_box_dancer-detail.png).
- [Reliquary, contacto de fotogramas](C:/RobloxProjects/StealACurse/assets/review/animations-polished/user-two-curses/thorn_reliquary-contact.png) / [detalle recortado de los mismos fotogramas](C:/RobloxProjects/StealACurse/assets/review/animations-polished/user-two-curses/thorn_reliquary-detail.png).
- [Seis registros de estado y tiempos reales](C:/RobloxProjects/StealACurse/assets/review/animations-polished/user-two-curses/observed.json); carga Success, cero actos ausentes. Media de fotograma en la prueba: 5,92–6,95 ms, p95 7,01–8,68 ms. Son tiempos de escena en escritorio, no coste CPU aislado ni medición móvil.
- [Pesos de fuentes inspeccionados](C:/RobloxProjects/StealACurse/assets/review/animations-polished/user-two-curses/weights.json): Dancer/Head/ArmR/Lid y Thorn/ThornTip afectan a sus grupos reales.
- [Integridad del archivo guardado](C:/RobloxProjects/StealACurse/assets/review/animations-polished/user-two-curses/build-proof.json): 55/55 fuentes actuales y 56/56 plantillas nativas correctas; ningún script de galería dentro de la entrega.

Esta galería cambia de instancia al cambiar de estado: no sustituye una prueba nueva de compra/venta ni todos los ángulos posibles. Las reglas de administración no se modificaron; se conservan sus comprobaciones anteriores. No se volvió a revisar todo el catálogo ni se repitieron importaciones o pruebas multijugador válidas.

## VFX y recuperación

Los módulos y anclajes VFX permanecen sin cambios. Un efecto vinculado a Dancer, Head, ArmR, Lid, Thorn o ThornTip sigue el mismo hueso, ahora con una actuación más visible; conviene comprobar su separación al integrar los nuevos VFX del amigo. No hay correspondencias de nombres ni pivotes que migrar en esta corrección.

Respaldo anterior y evidencias: `assets/review/animations-polished/user-two-curses/before`. Todo sigue local en `codex/curse-animations-polished`, sin publicar ni commit, push o merge.
