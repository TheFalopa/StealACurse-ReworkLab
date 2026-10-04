# Santuario: interiores y acabados

Entrega local: `C:\RobloxProjects\StealACurse\build-sanctuary-interior-polish.rbxlx`.
Fecha: 3 de octubre de 2026. Rama conservada: `codex/sanctuary-restoration-update`. Sin commit, push, merge ni publicación.

## Cambios terminados

Único módulo de producción modificado en esta revisión: `src/server/Map/RestorationArchitecture.luau`. Conservados capacidades, precios, requisitos, datos guardados, IDs y posiciones de pedestales. Modelos, animaciones y anclajes VFX intactos.

- Las plataformas tenían 66 studs de ancho dentro de un recinto de 102: franjas laterales de 18 studs y espacios posteriores sin suelo. Ahora conectan con paredes y descansillos mediante suelo sólido a la misma altura, sin superponer sus superficies superiores.
- Se conserva exclusivamente el hueco necesario para cada escalera. Está delimitado por vidrio colisionable con marco, pasamanos y remate inferior claro. No se añadió suelo de vidrio.
- Retirado el alto panel negro GalleryRearRail. Incorporados fascias, zócalos, molduras, soportes y marcos de nichos.
- Escaleras integradas con largueros, balaustres y pasamanos claros. Pendiente, ancho útil, rampa continua y descansillos mantienen las dimensiones anteriores.
- Grandes emblemas interiores desde nivel 5 en la galería de colección y nivel 8 en la de reliquias: calavera CRYPT, árbol FOREST y símbolo astral OBSERVATORY. Primer prototipo corregido tras comprobar en Roblox que las piezas planas eran poco legibles.
- Máximo de ocho luces por base conservado. Sin nuevas importaciones ni luces.

## Parpadeo: causa confirmada

Comparación antes/después dentro de Play con el mismo movimiento de cámara: la rampa de colisión era opaca e intersectaba la escalera decorativa. Sus triángulos oscuros aparecían entre peldaños al variar el ángulo. Además, el espesor de cada peldaño excedía su incremento vertical en 0,05 studs.

La rampa mantiene exactamente su colisión y transformación, pero ahora es invisible. Peldaños con espesor 22/24 studs y profundidad ligeramente inferior a 44/24 eliminan el solape entre caras vecinas. No se redujo calidad gráfica ni se transparentaron globalmente paredes.

Vídeos nativos comparables de 30 segundos: [antes](../assets/review/sanctuary-interior-polish/stair-before-native.mp4) / [después](../assets/review/sanctuary-interior-polish/stair-after-native.mp4). El ajuste posterior de emblemas no modificó las escaleras comprobadas.

## Diferencias por etapa

Se conservaron las siluetas existentes y se completaron sus interiores. Los grandes emblemas refuerzan especialmente 4→5 y 7→8.

| Nivel | Capacidad | Presentación revisada y progresión conservada |
|---|---:|---|
| 0 | 5 | Patio inicial con circulación lateral/posterior sólida. |
| 1 | 6 | Patio restaurado, pavimento unido, incrustaciones y obeliscos. |
| 2 | 8 | Colección ampliada y arcadas laterales con apoyo completo. |
| 3 | 10 | Una planta cerrada y cubierta; zócalos y nichos enmarcados. |
| 4 | 14 | Dos plantas completas; galería conectada, abertura protegida y escalera acabada. |
| 5 | 18 | Galería expandida, gran emblema de colección y pináculos. |
| 6 | 18 | Portal protector destacado; galerías terminadas y cierre funcional. |
| 7 | 22 | Tercera planta y segunda escalera con los mismos acabados seguros. |
| 8 | 26 | Sala expandida, gran emblema de reliquias y linterna de cubierta. |
| 9 | 26 | Torres y entrada consagrada; remates interiores continuos. |
| 10 | 30 | Tres plantas completas, campanario y ambas galerías terminadas. |

## Verificación

- Inspección visual Roblox de niveles 0–10 con cámara exterior comparable. Interior detallado de 4, 5, 8 y 10. Tres estilos revisados nativamente en la galería superior. Las vistas temporales no cambian el nivel de perfil; el HUD puede mostrar otro nivel.
- **14/14 pruebas de arquitectura en Play**: 33 combinaciones nivel/estilo, capacidades, pedestales, reconstrucción repetida sin restos, nuevo suelo y huecos deliberados. Comparación exacta de colliders originales, rampa, descansillos y elementos funcionales frente al checkpoint de partida.
- **The Void caminó 54 tramos en 70,46 s**, subiendo y bajando ambas escaleras. Sin muertes ni teletransportes durante los tramos; una colocación inicial del avatar preparó la prueba. Cámara en tercera persona observada durante el transporte.
- Compra real, recogida, colocación manual en tercer piso, nueva recogida, retorno caminando y colocación abajo. Una sola instancia; ingresos cero al transportar y 750 Souls/s al colocar. Perfil aislado, sin alterar el progreso del usuario.
- Sello activado mediante servicio real y colisión comprobada. Altar, marcas, recuperación y pedestales conservan referencias y espacio.
- Holgura mínima del objetivo de transporte sobre apoyo: 0,12 studs. The Void mide 12,6 studs en geometría nativa; holgura estática al techo del pedestal superior comprobado: 7,03 studs. No es una medición exhaustiva de todas las poses animadas.
- Archivo reconstruido: **66/66 fuentes exactas y 56/56 plantillas con rigs conservados**, sin scripts de revisión en la entrega.

Resultados: [Play y circulación](../assets/review/sanctuary-interior-polish/play-proof.json), [carga](../assets/review/sanctuary-interior-polish/load-proof.json), [fuentes](../assets/review/sanctuary-interior-polish/build-proof.json).

## Geometría y rendimiento

Comparación nativa: ocho bases nivel 10, estilos alternados, misma procesión. Cinco segundos de muestras por estado después de estabilizar la escena.

| Estilo, nivel 10 | Piezas antes | Después | Luces antes/después |
|---|---:|---:|---:|
| CRYPT | 465 | 566 | 8 / 8 |
| FOREST | 478 | 585 | 8 / 8 |
| OBSERVATORY | 473 | 564 | 8 / 8 |
| Ocho bases combinadas | 3775 | 4581 | 64 / 64 |

Aumento: 806 piezas, 21,35 %. Media de cuadro: 8,38→8,17 ms; percentil 95: 10,56→10,54 ms. No se observó deterioro evidente en esta muestra breve de escritorio; la pequeña diferencia no demuestra una optimización. Presupuesto ajustado a 600 piezas/base, máximo observado 585.

## Evidencia visual

- Nivel 8: [antes](../assets/review/sanctuary-interior-polish/gallery-before.png) / [después](../assets/review/sanctuary-interior-polish/gallery-after.png).
- Interiores: [Cripta](../assets/review/sanctuary-interior-polish/style-crypt-interior.png), [Bosque](../assets/review/sanctuary-interior-polish/style-forest-interior.png), [Observatorio](../assets/review/sanctuary-interior-polish/style-observatory-interior.png).
- level-00.png a level-10.png: vistas exteriores comparables; level-04-interior.png y level-05-interior.png: transición de galería.

## Recuperación y pendientes reales

Checkpoint inicial: `assets/review/sanctuary-interior-polish/checkpoints/00-start/build-sanctuary-architecture-polish.rbxlx`. Intermedios reconstruidos: 01-geometry y 02-finish.

Último checkpoint utilizable: `assets/review/sanctuary-interior-polish/checkpoints/03-verified/build-sanctuary-interior-polish.rbxlx`, con fuentes, pruebas, informe y resultados. Reconstrucción: `rojo build default.project.json --output build-sanctuary-interior-polish.rbxlx`; plantillas reales en `assets/imports/CurseMeshKit.rbxmx`.

Sin bloqueos conocidos de arquitectura. En el arranque final Roblox informó errores de descarga de siete MeshIds existentes: Cold Teacup 134975446540424, Coin Crawler 74159266876686, Umbrella Wraith 128916833526652, Marrow Dice 93842267716498, Veil Mourner 137006334533562, Hollow Violin 74267295029639 y Chime Triplets 82307616424520. No bloquearon mapa, perfil ni interfaz. La causa de disponibilidad de esos assets no se diagnosticó en esta tarea y queda pendiente; no se modificaron ni sustituyeron sus IDs. No se repitieron las 56 animaciones, todos los contratos, persistencia online ni robo con dos jugadores: se conservan verificaciones anteriores. No se midió teléfono físico ni ocho colecciones completamente llenas. La inspección visual de todos los niveles fue CRYPT; las pruebas de lógica abarcan los tres estilos en todos los niveles.

Uso consultado por hitos: cinco horas 13→24→32→38→45→50 % consumido; semanal 64→66→67→68→69→70 %. Sin créditos de reinicio consumidos.

## Abrir

```powershell
Start-Process -FilePath 'C:\RobloxProjects\StealACurse\build-sanctuary-interior-polish.rbxlx'
```

Confirmado: archivo final abierto desde disco e iniciado Play. Mapa, ocho bases, interfaz y perfil READY cargaron; sin errores Luau bloqueantes, con los siete errores de descarga de assets descritos arriba. No se realizaron compras, mejoras ni reclamación de base durante este arranque. La comprobación funcional previa sí utilizó un perfil QA aislado. Play quedó detenido, Rojo desconectado y el archivo final abierto. El atributo temporal de namespace del arranque se retiró sin guardarlo en el archivo. Evidencia: assets/review/sanctuary-interior-polish/final-startup-proof.json y final-startup.png.
