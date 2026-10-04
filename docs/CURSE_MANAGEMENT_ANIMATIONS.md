# Steal A Curse — entrega local de gestión y animaciones

Estado al cierre solicitado el **2 de octubre de 2026**. Se conserva la implementación y la evidencia existente; la entrega no declara terminadas las verificaciones que quedaron pendientes. No se publicó la experiencia ni se hizo commit, push o merge.

Proyecto: [build-curse-management-animations.rbxlx](../build-curse-management-animations.rbxlx). El mapa se genera al iniciar Play. El archivo se reconstruyó desde `default.project.json` y las fuentes actuales. [Comprobación del build](../assets/review/management-animations/final-build-proof.json); [evidencia y checkpoints](../assets/review/management-animations/).

**Comprobación final:** 51 fuentes coincidentes con el build, sin scripts de prueba; 56 plantillas nativas coincidentes con los IDs importados, todas con huesos. La apertura desde disco e inicio de Play generaron mapa, interfaz y perfil `READY`, con ofertas cargadas y sin errores en la consola de esa sesión: [resultado](../assets/review/management-animations/final-play-check.json). Se detectó y evitó una sesión anterior que conservaba MeshIds antiguos tras sincronizar Rojo: el build actualizado se recargó desde disco. Para esta entrega, usa el archivo recargado; conectar una sesión antigua a Rojo no reemplazó esas mallas.

## Estado de las cuatro fases

| Fase | Implementado y comprobado | Límite de la comprobación |
| --- | --- | --- |
| Movimiento | Posición autoritativa independiente de la malla; procesión calculada continuamente en cliente y seguimiento suavizado; un controlador escribe la transformación visible. Preparación acotada de mallas y tratamiento de cambios de estado. Mediciones en Play y dos clientes reales con latencia simulada. | Falta el vídeo comparable del movimiento anterior. La separación visual respecto de la autoridad aumenta en giros bruscos bajo latencia; véase abajo. |
| Parpadeo | Se identificaron 127 pares de superficies coplanares entre 76 caminos planos. La superficie visible se particiona sin cambiar los soportes de colisión; se conservan ocho rampas. Comprobación nativa de 4.116 puntos: cero huecos y cero fallos de apoyo. | Hay vídeo posterior; quedó pendiente grabar y revisar la comparación exacta antes/después en las dos zonas preparadas. |
| Venta y reubicación | Venta confirmada por el 50 % del catálogo, redondeada hacia abajo; validación del servidor y token de una sola operación. Recoger, transportar y colocar cerca de un pedestal libre identificado del santuario propio. Sin ingresos mientras está sin colocar, sin devolución al cerrar la interfaz. Muerte/reinicio dejan recuperación manual; guardado conserva propiedad y estado. | Pruebas funcionales, concurrencia, recuperación, pedestal elevado y móvil emulado guardadas. La regresión específica de las 56 se detuvo en la reclamación del santuario de prueba; no se cuenta como aprobada. |
| Animaciones | **56 mallas reales con huesos importadas**, conservando las fuentes actuales, colores y dimensiones. Actuación de articulaciones por concepto, estados de reposo/procesión/transporte, transición breve, controlador compartido y reducción de detalle a distancia. Anclajes de VFX ligados a las poses. | Revisión visual completa documentada hasta la tanda 10: **40 Curses**. Vídeos de las tandas 11 y 12 conservados; queda su revisión completa y las tandas 13 y 14. No se declaran 56 aprobaciones visuales. |

## Controles y recuperación

Usa el prompt de una Curse propia para **Administrar**: **Recoger** o **Vender**. Vender abre una confirmación con nombre, rareza y Souls exactas. Durante transporte, acércate a un pedestal libre propio y usa **Colocar**. Hay botones y prompts para móvil; cerrar el menú no coloca ni devuelve la Curse.

Al morir o reiniciar, vuelve al santuario, recoge la Curse recuperable y colócala manualmente. Tras desconectarte se conserva como **sin colocar**, sin producción. La recuperación presenta hasta seis modelos en zonas alcanzables; un inventario mayor queda en una cola conservada que se materializa al liberar espacio. La prueba de **128 Curses** verificó esa recuperación, venta, liberación y guardado local: [resultado](../assets/review/management-animations/phase3-recovery-queue128-observed.json).

## Evidencia conservada

- Movimiento: [mediciones anteriores](../assets/review/management-animations/before/motion-observed.json), [sesión individual](../assets/review/management-animations/phase1-solo-observed.json), [dos clientes](../assets/review/management-animations/phase1-multiplayer-synchronized.json), [comparación con autoridad](../assets/review/management-animations/phase1-authority-aligned.json), [vídeo de transporte](../assets/review/management-animations/videos/phase1-after-carry-two-clients.mp4).
- Pavimento: [comprobación geométrica en Play](../assets/review/management-animations/phase2-native-surfaces.json), [vídeo posterior](../assets/review/management-animations/videos/phase2-after-pavement-camera.mp4).
- Gestión: [concurrencia, reinicio y recuperación](../assets/review/management-animations/phase3-reconnect-concurrency-reset-play-log.json), [móvil emulado](../assets/review/management-animations/phase3-mobile-observed.json). No se probó un teléfono físico.
- Animaciones: [registro de las 56 con IDs reales, tamaños, huesos, Blender, FBX y hashes](../assets/imports/curse-animation-current.json). [Vídeos y capturas por tanda](../assets/review/management-animations/videos/); las observaciones de cada tanda están en la carpeta de evidencia. Los indicadores históricos `playReviewed` del registro no sustituyen la cobertura explícita de esta entrega.

## Pendientes reales

1. Completar la revisión visual de las últimas 16 Curses y sus estados; finalizar la regresión de gestión de las 56 y la prueba preparada de carga simultánea, suspensión y limpieza de animaciones. Las métricas de las tandas corresponden a una Curse examinada y las ofertas naturales, no a 56 animadas simultáneamente.
2. Comparaciones de vídeo anteriores pendientes y revisión completa de los últimos ajustes de anclajes VFX. Los vídeos ya guardados siguen siendo evidencia válida de sus versiones.
3. En la sesión con latencia, el movimiento visual no tuvo cuadros inmóviles mientras avanzaba, pero la diferencia respecto de la autoridad alcanzó **3,96 studs en el propietario y 12,23 en el observador** durante giros bruscos. No se confunde fluidez con precisión de posición ni se declara resuelto ese extremo.
4. El proyecto de partida no incluía un servicio operativo de robo/protección. Hay validaciones de propiedad y bloqueo de operación, pero falta verificar su integración con un sistema real de robo y cambios de propietario. El guardado local de Studio fue probado; la persistencia DataStore en servidores publicados no fue probada.

Los checkpoints conservan las fuentes y builds anteriores. Las pruebas de galería, gestión y rendimiento están separadas del proyecto final y no se incluyen en él.
