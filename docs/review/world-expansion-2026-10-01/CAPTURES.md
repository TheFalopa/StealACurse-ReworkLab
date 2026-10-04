# Índice de revisión visual — World Expansion

Fechas: 1–2 de octubre de 2026. Las 17 categorías solicitadas están representadas por 27 archivos de imagen, incluidas variantes móviles, cuatro capturas nuevas QA2 y acercamientos de modelos. Todos los archivos enlazados existen y se pudieron decodificar. Las dimensiones corresponden al archivo completo: las capturas de Studio incluyen su interfaz, no solo el viewport ni una pantalla de teléfono real.

**Formato comprobado por magic bytes y decodificación:** se conservan los nombres `.png` existentes. La herramienta nativa entregó las capturas de Studio codificadas como **JPEG/JFIF**, MIME real `image/jpeg`, pese a esa extensión; no se han convertido, renombrado ni editado para este índice. `16-blender-models.png` sí es PNG, MIME `image/png` (1800 × 1150), y es una copia idéntica del render fuente. La presencia de una captura no implica aprobación general de input móvil, colisión, rendimiento o gameplay.

| # | Revisión solicitada | Archivo existente | Dimensiones |
| --- | --- | --- | --- |
| 1 | Mapa completo, vista aérea | [01-aerial.png](01-aerial.png) | 1282 × 923 |
| 2 | Frente del castillo | [02-castle-front.png](02-castle-front.png) | 1282 × 923 |
| 3 | Costado del castillo | [03-castle-side.png](03-castle-side.png) | 1282 × 923 |
| 4 | Ruta de Curses alrededor del castillo | [04-procession-route.png](04-procession-route.png) | 1282 × 923 |
| 5 | Un santuario | [05-sanctuary.png](05-sanctuary.png) | 1282 × 923 |
| 6 | Espacio entre santuarios | [06-between-sanctuaries.png](06-between-sanctuaries.png) | 1282 × 923 |
| 7 | Cementerio antiguo | [07-old-graveyard.png](07-old-graveyard.png) | 1282 × 923 |
| 8 | Bosque muerto | [08-dead-forest.png](08-dead-forest.png) | 1282 × 923 |
| 9 | Grupo de decoración Halloween | [09-halloween-cluster.png](09-halloween-cluster.png) | 1282 × 923 |
| 10 | Árboles y follaje mejorados | [10-trees-foliage.png](10-trees-foliage.png) | 1282 × 923 |
| 11 | Material personalizado, acercamiento | [11-custom-material.png](11-custom-material.png) | 1282 × 923 |
| 12 | HUD en escritorio | [12-hud-desktop.png](12-hud-desktop.png) | 1282 × 923 |
| 13 | Tienda en escritorio | [13-shop-desktop.png](13-shop-desktop.png) | 1282 × 923 |
| 14 | HUD móvil, portrait / landscape emulados | [14-hud-mobile-portrait.png](14-hud-mobile-portrait.png), [14-hud-mobile-landscape.png](14-hud-mobile-landscape.png) | 1282 × 923 cada una |
| 15 | Tienda móvil, portrait / landscape y estado desplazado | [15-shop-mobile-portrait.png](15-shop-mobile-portrait.png), [15-shop-mobile-landscape.png](15-shop-mobile-landscape.png), [15-shop-mobile-portrait-scrolled.png](15-shop-mobile-portrait-scrolled.png) | 1282 × 923 cada una |
| 16 | Varios modelos nuevos en Blender | [16-blender-models.png](16-blender-models.png) | 1800 × 1150 |
| 17 | Varios modelos nuevos dentro de Roblox | [17-roblox-new-curses.png](17-roblox-new-curses.png), [17a-common-close.png](17a-common-close.png), [17b-rare-close.png](17b-rare-close.png), [17c-relics-close.png](17c-relics-close.png) | 1282 × 923 cada una |

La imagen 16 es un **render producido por Blender**, no una captura de la interfaz de Blender. Procede de [first_wave_gallery.png](../../../assets/source/blender/curses_expansion/first_wave_gallery.png), copiado sin editar el bitmap; ambos archivos tienen el mismo SHA-256. Presenta los 15 modelos de la primera ola.

Las imágenes 17 / 17a / 17b / 17c muestran la galería de revisión test-only en Roblox Play. Esa galería está fuera del mapa y no añade los modelos nuevos al spawn activo. El registro separado [curse-wave1-appearance.json](curse-wave1-appearance.json) documenta la observación de apariencia; no equivale a validar su compra, entrega o ingreso.

La imagen móvil desplazada anterior muestra el estado de Soul Packs en portrait. Las capturas por sí solas no aprueban todos los gestos, tabs ni CTAs de portrait/landscape: los resultados de input deben contrastarse con [ui-qa2.json](ui-qa2.json) y el apartado 28 del [informe principal](../../WORLD_EXPANSION.md).

## Capturas de input móvil QA2 — categoría 15

Estas cuatro imágenes nuevas acompañan los gestos nativos registrados en `build-expansion-qa2.rbxlx`. Todas tienen MIME real `image/jpeg`, aunque conservan extensión `.png`; no se convirtieron ni editaron.

| Estado observado | Archivo | Dimensiones |
| --- | --- | --- |
| Portrait: Soul Packs tras drag nativo hasta Y=240 | [15-qa2-portrait-touch-scroll.png](15-qa2-portrait-touch-scroll.png) | 1282 × 923 |
| Portrait: Passes tras drag nativo hasta Y=240 | [15-qa2-portrait-passes-scrolled.png](15-qa2-portrait-passes-scrolled.png) | 1282 × 923 |
| Landscape: Soul Packs al inicio del canvas | [15-qa2-landscape-souls-top.png](15-qa2-landscape-souls-top.png) | 1282 × 923 |
| Landscape: Soul Packs tras drag inicio→final, 0→152.0335→141 | [15-qa2-landscape-souls-scrolled.png](15-qa2-landscape-souls-scrolled.png) | 1920 × 1032 |

QA2 también registró Passes landscape final→inicio (139.3523→−10.7374→0), tabs, CTAs Coming Soon y close. Los intentos Passes inicio→final no fueron fiables y no se aprueban; otros gestos fallidos tampoco cuentan como éxito. Las pruebas de escritorio usaron viewport 1251 × 635, no fullscreen 16:9. Portrait 401 × 777 y landscape 749 × 361 son emulación de Studio, no teléfono físico ni pruebas de FPS/memoria. No se alteró la UI de producción durante esta ejecución.

## Evidencia complementaria del ciclo natural

No sustituye las 17 categorías visuales solicitadas:

- [gameplay-01-natural-purchase.png](gameplay-01-natural-purchase.png) — 1282 × 923, JPEG con extensión `.png`.
- [gameplay-02-delivered-pedestal.png](gameplay-02-delivered-pedestal.png) — 1282 × 923, JPEG con extensión `.png`.
- [runtime-initial.json](runtime-initial.json) y [gameplay-return.json](gameplay-return.json) — registros de pruebas separados, no imágenes.

## Regresión aislada final

[slice-final-pass.png](slice-final-pass.png) — 1282 × 923, JPEG con extensión `.png`: Output muestra `SLICE_DONE` y HUD +822 después de la suite single-client. [slice-final.json](slice-final.json) conserva sus 44 comprobaciones aprobadas y límites. Esta copia usa setup/créditos para casos extremos y no sustituye el ciclo natural anterior ni aprueba gameplay de las Curses nuevas.
