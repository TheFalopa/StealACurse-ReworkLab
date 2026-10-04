# Arquitectura de santuarios — revisión enfocada

Entrega: `build-sanctuary-architecture-polish.rbxlx`, 3 de octubre de 2026.
Solo cambia el generador `RestorationArchitecture.luau`; los 65 scripts restantes coinciden con la copia original guardada desde Studio. Checkpoint original y versión guardada conservados en `assets/review/sanctuary-architecture-polish/checkpoints/00-start`.

| Etapa | Capacidad | Diferencia visual |
|---|---:|---|
|0|5|Patio delimitado, acceso y remates|
|1|6|Pavimento restaurado, incrustaciones y obeliscos de entrada|
|2|8|Dos arcadas cubiertas en el patio de colección|
|3|10|Santuario cerrado de una planta con cubierta completa a dos aguas|
|4|14|Dos plantas cerradas, escalera y galería|
|5|18|Galería ampliada y cuatro pináculos en la cubierta|
|6|18|Portal ancho del sello con pilares y marcas visibles|
|7|22|Tercera planta integrada y cubierta reconstruida|
|8|26|Galería ampliada y lucernario cerrado sobre la cubierta|
|9|26|Torretas de fachada y remate consagrado|
|10|30|Colección completa y torre central con aguja|

La circulación conserva posiciones e IDs. Muros opacos de un stud, ventanas ornamentales enmarcadas, techo continuo con dos prismas triangulares cerrados. Luz interior sin sombras: dos apliques por planta más dos faroles de entrada. Los estilos conservan piedra/velas, madera/raíces y piedra oscura/símbolos astrales.

## Causa y solución

Los laterales y fondo eran grandes paneles de vidrio casi transparentes. La cubierta era un pequeño dosel trasero; las ventanas centrales superiores carecían de pared. Ahora hay muros opacos, paño central sobre el acceso, techo continuo y faldones sólidos con remates. Las ventanas laterales son paños ornamentales tintados con marcos, sobre muros sólidos. La torre y el lucernario son volúmenes decorativos cerrados; no añaden pisos jugables.

El volumen de colisión conserva su planta de 104 × 104 studs. Los marcos ornamentales sobresalen aproximadamente 1,1 studs, sin invadir las bases vecinas. No se añadieron transparencias globales ni controlador de oclusión. La cámara habitual funcionó durante el recorrido revisado; no se garantiza cualquier zoom o ángulo extremo.

## Comprobaciones realizadas

- Inspección visual en Play de CRYPT 0–10 desde la misma cámara; FOREST y OBSERVATORY en 3, 4, 7 y 10. Nivel 10 revisado también por detrás, ambos lados, arriba y dentro de sus tres plantas. Sin ventanas flotantes ni huecos de cubierta en esas vistas.
- 13 pruebas de arquitectura aprobadas: capacidades, 33 combinaciones de nivel/estilo, reconstrucción sin duplicados, conservación de identidad y ocupación, circulación, escalera, límites y restricciones del sello.
- Perfil aislado `qa-architecture-polish-090420`: mejora real 0→1 después de contrato, entrega, compra, colocación y ritual; solicitud repetida rechazada y guardado local confirmado. No se aprovisionó el perfil del usuario.
- 83 comprobaciones de flujo y recorrido aprobadas. The Void comprada y recogida legítimamente, recorrido físico de 54 segmentos por ambas escaleras, colocación en tercera planta y retorno físico a planta baja. El movimiento del avatar fue automatizado con Humanoid.MoveTo, observado en Play; no fue un recorrido manual con teclado. Solo hubo una reubicación inicial de preparación, ninguna para saltar las escaleras. Duración 70,16 s, sin muertes; ingresos suspendidos al llevarla y reanudados una vez al colocarla. Separación mínima al suelo 0,12 studs; margen estático bajo el techo superior 7,03 studs.
- Activación real del sello con barrera colisionable y conservación de sus restricciones de acceso comprobadas. No se hizo una nueva sesión de dos jugadores atravesando la entrada durante esta revisión.
- Archivo reconstruido: 66/66 fuentes idénticas al repositorio, 56/56 modelos y sus datos de rig conservados; ningún script QA en la entrega. Esto verifica conservación de assets, no repite las 56 pruebas visuales de animación.
- Confirmación final sobre el archivo guardado en disco y abierto en Studio: comprobación estática repetida tras su guardado, 66 fuentes y 56 modelos coincidentes. Play inicia, construye el mapa y ocho bases, y muestra ocho Curses activas al tomar la muestra. Consola de Play vacía. Se deja abierto con Play detenido. Evidencia: `final-disk-proof.json` y `final-startup-proof.json`. Antes de Play apareció un aviso del editor MaterialManager sobre profileEnd; no apareció en el arranque del juego.

Evidencia numérica: `assets/review/sanctuary-architecture-polish/gameplay-architecture-checks.json`, `source-comparison.json`, `build-proof.json` y `load-proof.json`.

## Coste y límites de rendimiento

Base completa de nivel 10: CRYPT 268→465 piezas, FOREST 281→478, OBSERVATORY 276→473 (conteo BasePart del modelo de base, incluye sus partes funcionales). Luces: 2→8 por base; los nuevos apliques no proyectan sombras. No hay imports nuevos ni ciclos por edificio.

Muestra de cinco segundos por estado, cámara fija, ocho bases avanzadas y procesión activa: media de cuadro 5,24→5,55 ms; percentil 95 de 6,20→6,71 ms. Son medidas de RenderStepped en este PC dentro de Studio, no del coste exclusivo de arquitectura ni de móvil.

Límite de la comparación: la base ocupada quedó pulida y la base de exposición se volvió a generar antes de medir. Por ello el punto inicial cronometrado contiene seis bases anteriores y dos nuevas (2.593 piezas), frente a ocho nuevas (3.775 piezas). No debe presentarse como una medición cronometrada de ocho bases antiguas contra ocho nuevas. Las bases no estaban llenas de 30 Curses cada una; esa carga y ocho clientes simultáneos quedan pendientes.

## Capturas comparables

Todas las imágenes son capturas reales de Roblox Studio. La etiqueta inferior indica el nivel arquitectónico mostrado; el HUD sigue el perfil QA.

| Vista | Antes | Después |
|---|---|---|
|Nivel 10, fachada CRYPT|[Antes](../assets/review/sanctuary-architecture-polish/before-10-crypt-front.png)|[Después](../assets/review/sanctuary-architecture-polish/after-10-crypt-front.png)|
|Nivel 10, posterior CRYPT|[Antes](../assets/review/sanctuary-architecture-polish/before-10-crypt-rear.png)|[Después](../assets/review/sanctuary-architecture-polish/after-10-crypt-rear.png)|

Las capturas `after-00-crypt-front.png` a `after-10-crypt-front.png` muestran la progresión completa. También se guardaron los estilos, interiores, cubierta, laterales y el transporte de The Void en la misma carpeta.

## Archivos y reproducción

- Cambio de producción: `src/server/Map/RestorationArchitecture.luau`.
- Pruebas: `tests/SanctuaryArchitecture.spec.luau`; escenario aislado `tests/ArchitecturePolish.server.luau`, `tests/ArchitecturePolish.client.luau` y `build-architecture-polish-review.project.json`.
- Checkpoints de partida y de arquitectura conservados en `assets/review/sanctuary-architecture-polish/checkpoints`.
- Rama utilizada: `codex/sanctuary-restoration-update`. Se conservaron los cambios anteriores. Sin commit, push, merge ni publicación.
- VFX: ningún cambio en modelos de Curses, huesos, nombres o anclajes. No se requiere correspondencia nueva para los efectos de tu amigo.

Reconstruir: `rojo build default.project.json --output build-sanctuary-architecture-polish.rbxlx`.

Abrir en PowerShell:

```powershell
Start-Process 'C:\RobloxProjects\StealACurse\build-sanctuary-architecture-polish.rbxlx'
```

Pendientes concretos de verificación: nuevo recorrido de dueño/visitante con el sello activo en dos clientes; todas las bases completamente ocupadas; comparación de rendimiento con ocho bases anteriores bajo condiciones idénticas. No se ha probado teléfono físico. La revisión enfocada no vuelve a validar todos los contratos ni las 56 animaciones.
