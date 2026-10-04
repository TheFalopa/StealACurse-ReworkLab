# Studio regression fixtures

These are test-only entrypoints, excluded from `default.project.json`. The
builder derives a temporary project from the real project and reuses the exact
production Map, Gameplay, Shared, HUD, and MeshPart templates. It never changes
the production project or imports/publishes assets.

From the repository root:

```powershell
./tests/Build-StudioFixture.ps1
./tests/Build-StudioFixture.ps1 -Multiplayer
```

Open the generated `build-slice-tests.rbxlx` and use **Play**. Keep its client
viewport active. The single-client suite must finish with `SLICE_DONE`, not just
an early `SLICE_PASS`. It uses the real client ProximityPrompt input methods.
The first return walks through Pathfinding/Humanoid movement; setup and isolated
edge-case deliveries use teleports. Rare purchases use test-only Soul credit.
The fixture deliberately removes display geometry and recreates a placed mesh.
Do not publish either fixture.

The multiplayer fixture requires **Server and Clients**, with two actual
clients. Inputs are scheduled at the same server timestamp. The automated
background-window inputs did not activate the claim prompts in the 2026-09-30
run: `MULTI_FAIL ... same-base race has exactly one winner`. Neither player had
claimed at that point. A focused client's real E input then claimed successfully;
exiting that owner client left one connected player, no owner, an enabled claim
prompt, and `UNCLAIMED` on the server. This is not a passed simultaneous-race
test. Recheck claim/purchase contention with two active human clients; do not
treat client acknowledgements alone as proof that Triggered reached the server.

The normal production build must also be tested after production-code changes.
The fixtures intentionally isolate purchases from the random timed procession,
so they do not replace a route/spawn/unsold-exit test in the normal map.

Generated `.rbxlx`, fixture `.project.json`, and sourcemap files are ignored.
Session Souls are intentionally not persisted. No stealing or effects are enabled.

## 2026-09-30 single-client result

The final fixture reached `SLICE_DONE` after the last gameplay/UI changes. It
passed claim/respawn target, no-base and insufficient-balance rejection,
500-to-400 purchase, no carried income, one simultaneous delivery, physical
return walk, first physical pedestal, +3 income and accumulation. All six
definitions were purchased and placed across the run. Five initial Curses summed
to +222; after a removed pedestal and its refund, replacing that slot with The
Void summed to +822. All five occupied slots were distinct.

Missing area and pedestal refunded safely without killing the updater. Death
refunded delivery; respawn retained the base and placed production. A destroyed
placed model was recreated without duplicated rate. All six roots were below
7 studs diagonal and noncolliding. Chains/Void glow centers were verified in
front of their solid mesh surfaces and visually visible. The client HUD read
`+222 Souls/s`; only the closest placed pedestal detail was enabled (local UI,
25-stud range, 5 Hz). Procession/delivery cards remain unchanged.

The adjusted production route was observed in Play and sampled through a full
cycle: maximum 3 active models, 4 unsold model exits, 0 sampled overlaps against
the crypt structure/ritual obelisks using conservative model bounding spheres.
This is a geometry sample and visual review, not a proof for every camera angle.

The normal production build was also retested after the final UI changes:
Base02 claimed with real keyboard input, player walked to the natural procession,
bought a randomly spawned Cursed Doll (400 Souls, 0 Souls/s during delivery),
walked back, and reached `NORMAL_LOOP_PASS Cursed Doll 3 6.25`. No teleport or
test credit was used in that normal-map loop; movement was command-assisted
Pathfinding/Humanoid walking, not a manual usability playthrough.

The same normal build was played in the iPhone XR device simulator. A touch
claim succeeded in landscape; Souls, rate and the claim notice fit the viewport.
The HUD also fit the portrait view. This is not a real-device FPS or full mobile
loop test. Some camera angles still place world-space labels behind the fixed
top HUD; the nearest-pedestal filter reduces peer-card overlap, not all HUD
occlusion. Play was stopped and the simulator disabled after the checks.

## 2026-10-01 second quality pass — validation in progress

The environment/UI pass adds a separate read-only observation fixture. It keeps
the production entrypoint and natural procession; its validators do not grant
Souls, teleport players, buy Curses or force delivery states. Do not publish it.

```powershell
./tests/Build-StudioFixture.ps1 -QualityPass
./tests/Audit-QualityPass.ps1
rojo build default.project.json --output build-polish-v2-final.rbxlx
rojo sourcemap default.project.json --output build-polish-v2-final.sourcemap.json
git diff --check
```

Open `build-quality-pass-tests.rbxlx`, use Play and keep the client viewport
focused. `QUALITY_WORLD_PASS` checks eight sanctuary contracts, forty slots,
grounding metadata, simple hull bounds and eight navmesh routes. It is not a
physical traversal test. `QUALITY_UI_PASS` checks safe bounds, legacy HUD paths,
replicated balance/rate and nine mock store cards. It does not replace a visual
review or prove touch scrolling. `-QualityPass`, `-Multiplayer` and `-AllBases`
are mutually exclusive builder modes. The original single-client fixture still
requires `SLICE_DONE`; an earlier `SLICE_PASS` is not completion.

After the last world change, `QUALITY_WORLD_PASS` reported 3,395 environmental
BaseParts, 530 MeshParts, 289 hulls, 689 colliders, 422 grounded meshes, 21 unique
environment MeshIds, 13 lights and one ParticleEmitter. Static audit retained
all thirty verified templates, found gameplay unchanged from `1a3ad5f`, no
purchase integration and no test entrypoints mapped into production. Build,
sourcemap and diff checks passed at that stage.

In the natural-procession fixture, Base05 was claimed with real E input. The
player walked to a natural Cursed Doll and purchased with E: 500 to 400 Souls,
zero rate while carrying. Physical return placed it on slot 1 and produced
`POLISH_LOOP_PASS 3 5.5` (+3 Souls/s; +5.5 Souls in approximately two seconds).
No teleport or test credit was used. Walking used command-assisted
Pathfinding/Humanoid movement, not an unassisted human usability playthrough.
An initial automatic approach snagged a gate jamb; an explicit centered
approach crossed the gate both ways. The rear barrier blocked at local Z
30.5905, below its limit of 32, and the player backed away successfully
(`POLISH_WALL_BLOCK_PASS` / `POLISH_DISENGAGE_PASS`). This does not establish
robust physical movement for all generated path waypoints or every hull.

UI was checked in Desktop HD 720 (effective viewport 1279 x 720) and iPhone 17
Pro portrait (initial effective viewport 400 x 776; dimensions varied with
Studio panels). In portrait, focused touch scrolling reached Extra Curse
Slot/Faster Delivery and Mega Soul Pack. Tabs, Coming Soon CTA and close X
worked without a balance change or Robux prompt. CURSES and SETTINGS shells
opened and closed. Six player-height environment views and desktop/portrait
screenshots are linked in `docs/FINAL_MAP_POLISH_V2.md`.

Landscape HUD passed at 749 x 361, but visual review found a store body shorter
than its cards. A compact layout correction has been implemented. The build,
sourcemap and fixtures were regenerated after that change at 13:01. Fresh Play
of `build-polish-v2-slice-final.rbxlx` reached `SLICE_DONE` at 13:03:40.401 on
2026-10-01, with no failures; this is a new run, not the September 30 result.

The fresh suite passed claim/respawn target, no-base/insufficient rejection,
500-to-400 purchase, no carried income, one simultaneous transport and a
physical Pathfinding return to Base07 without an observed snag. It placed five
distinct initial pedestals, verified +222 HUD and the nearest-detail filter,
rejected a full base, refunded missing area/pedestal and death, preserved owner
and rate after respawn, restored a removed placed model without duplicated
rate, and replaced a slot with The Void for +822. All six definitions retained
noncolliding roots below seven studs diagonal; Chains/Void front glows passed.
The suite capture is `docs/polish-v2-review/15-slice-regression-done.png`.

A fresh normal-procession fixture after the compact change passed
`QUALITY_WORLD_PASS` at 13:05:57 with unchanged counts and `QUALITY_UI_PASS`
at 934 x 497. Base07 was claimed with real E input. Command-assisted physical
walking reached the castle and followed a naturally spawned Doll; real E
purchased it at 13:10:52 (400 Souls, zero rate). Physical return did not snag,
slot 1 received the Doll, and `FINAL_NORMAL_LOOP_PASS Base07 3
6.300000000000011` completed at 13:12:19.123 (+3 Souls/s, approximately +6.3
Souls in two seconds). No teleport, test credit or forced spawn was used in
this loop. SHOP opened and closed with real clicks; `QUALITY_SHOP_OPEN_PASS
934 497` included TextFits checks of visible cards. Capture:
`docs/polish-v2-review/16-final-natural-loop.png`.

Responsive landscape review and static audit/diff checks of closure remain
pending. The suite intentionally isolates purchases and uses setup
teleports/test credit; its results remain separate from the natural loop.
This run also does not establish real-device FPS, full touch gameplay or a
simultaneous two-client contention pass.

## 2026-10-02 — evidencia de la expansión de cincuenta Curses

El informe actual y sus anexos están en
[CURSE_EXPANSION_50_REWORK.md](../docs/CURSE_EXPANSION_50_REWORK.md).
Las pruebas separan referencias/modelado/importación/apariencia de VFX,
gameplay y habilitación. Una captura, un `PASS` parcial o el registro de una
importación no sustituye el resultado final de la fase solicitada.

### Informe completo del mundo, sin depender de la consola

La versión actual de `QualityPass.server.luau` publica el JSON completo al
final de sus comprobaciones en
`ReplicatedStorage.QualityPassObservedReport`, un `StringValue`. Lo publica
antes de imprimir `QUALITY_WORLD_REPORT` y antes de la aserción final, de modo
que también conserva la lista de fallos de una ejecución fallida. Sus
atributos `Completed`, `FailureCount`, `WarningCount` y `ReportByteCount`
permiten comprobar el estado de la observación. El transporte evita el límite
de 200.000 bytes de un único `StringValue`: si el JSON tiene hasta 90.000 bytes,
`Value` contiene el informe y `PartCount=0`; por encima de ese umbral, `Value`
contiene un manifest `StringValueChunksV1` y sus hijos `Chunk001`, `Chunk002`,
etc. contienen partes de hasta 90.000 bytes, respetando los límites UTF-8.

El protocolo coincide con el de `CurseReworkObservedReport`. Cada hijo tiene
el atributo `Generation`; el principal contiene `Generation`, `PartCount`,
`TotalByteCount`, `ReportByteCount` y `Publishing`. El manifest registra
`generation`, `partCount`, `totalByteCount`, `phase` y `requestedPhase`.

Después de regenerar el fixture y ejecutar Play, leer el valor de ese objeto
mediante el acceso al datamodel de Studio. El lector MCP debe comprobar que
`Publishing=false`, guardar `Generation`, leer `Value` y, si hay partes,
concatenar sus valores por índice. Comprobar que cada hijo tiene esa misma
generación y que `Generation` sigue igual y `Publishing` sigue siendo falso al
terminar. El total de bytes UTF-8 concatenados debe coincidir con ambos
atributos de tamaño y con el manifest antes de decodificar el JSON. Si el
conector limita una respuesta, leer cada valor en páginas conservando el orden
y aplicar las mismas comprobaciones después de reunirlas. Guardar el JSON
junto con la identificación de la ejecución y su fecha. Este objeto sólo pertenece al fixture de pruebas;
no se añadió al proyecto de producción. La consola sigue siendo útil para los
marcadores de estado.

El logger nativo de Studio recortó las líneas largas a aproximadamente 1.022
caracteres en las ejecuciones de esta sesión. Por tanto, el antiguo
`CURSE_REWORK_REPORT` y `QUALITY_WORLD_REPORT` de los logs no son JSON íntegros.
Los lectores en [docs/tools](../docs/tools/) preservan los fragmentos, las
líneas originales y sus marcas de tiempo; no reconstruyen fuentes cargadas ni
conceden una aprobación a datos ausentes. La publicación durable se añadió
después de esos ensayos: **su lectura en la próxima ejecución sigue pendiente**.

### Evidencia ya guardada

- [Ruta anterior, cincuenta observaciones completas](../assets/review/curse-rework/route-observed-all50.json):
  los cincuenta IDs/FBX actuales terminaron los quince segmentos y desaparecieron
  al salir. La selección fue determinista y el fixture aceleró el primer
  retraso/cadencia a 0,1/0,15 s; conserva el alcance de ese ensayo.
- [Comparación independiente del núcleo con HEAD](../assets/review/curse-rework/route-production-core-proof.json):
  siete archivos sin diferencias Git, con SHA256 iguales después de normalizar
  CRLF a LF. Es una comprobación del disco actual; no reconstruye fingerprints
  de fuentes que el fixture anterior no registró.
- [Fragmentos de la fase All anterior](../assets/review/curse-rework/legacy-all-observed.json):
  incluyen el `DONE All 50` real, pero su reporte final y sus cincuenta marcadores
  de compra fueron truncados. No se presentan como un informe completo de
  gameplay/VFX de la versión nueva.
- [Regresión de las seis originales](../assets/review/curse-rework/original-six-regression.txt):
  resultado de la suite original guardado por separado.
- [UI de escritorio](../assets/review/curse-rework/quality-ui-observed-desktop.json):
  seis reportes completos, `failures=[]`, viewports efectivos 1296×633 y
  1580×633; Souls/HUD 252×82. Se abrió SHOP, se visitaron Boosts/Soul Packs y se
  cerró mediante controles reales. El observador de geometría no demuestra por
  sí solo esas entradas.
- [UI móvil simulada](../assets/review/curse-rework/quality-ui-observed-mobile.json):
  seis reportes completos, `failures=[]`, paisaje efectivo 706×339 y retrato
  360×719 / 359×718; Souls/HUD 198×70. La inspección del datamodel confirmó
  `TouchEnabled=true` y pequeñas variaciones de viewport 705×338 / 706×339.
  SHOP y SETTINGS se abrieron/cerraron con controles reales. La configuración
  mantiene paisaje; Studio mostró una advertencia de `ScreenOrientation` al
  simular retrato. Esto prueba el ajuste de geometría en el emulador, no que el
  juego habilite rotación ni que se haya probado un teléfono físico.

Capturas reales: [escritorio](../assets/review/curse-rework/desktop-shop.jpg),
[paisaje móvil](../assets/review/curse-rework/mobile-landscape-shop.jpg) y
[retrato móvil](../assets/review/curse-rework/mobile-portrait-shop.jpg). La
última es una captura de 144×320 píxeles con el emulador ajustado a la ventana;
no equivale a una captura nativa de 360×719 ni permite medir FPS.

**Pendiente:** desplazamiento táctil nativo del contenido de la tienda. Se
intentaron arrastre y rueda, pero no se observó movimiento de `CanvasPosition`;
no se declara aprobado. Las fases frescas FinalRoute y Purchase de cincuenta
Curses están en ejecución; sus resultados finales deben guardarse y revisarse
antes de habilitar modelos. La lectura durable del próximo Quality World y la
prueba final con la aparición normal habilitada también siguen pendientes.
