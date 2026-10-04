# Tools + Theft Foundation — entrega local parcial

Fecha: 2026-10-03. Rama `codex/gameplay`, base `5194c0c`. Sin commit, push, merge ni publicación. Se preservaron bases, 56 plantillas nativas, animaciones, VFX y el cambio local anterior de rokit.toml. Cierre al alcanzar el 85 % de uso de la ventana (15 % restante), conforme al encargo.

## Archivos y recuperación

- Proyecto: C:\RobloxProjects\StealACurse\build-tools-theft-foundation.rbxlx
- Checkpoint final: assets/review/tools-theft-foundation/checkpoints/04-delivery/
- Checkpoint previo conservado: checkpoints/03-retry-fix/, con proyecto y sources.zip.
- Evidencia: play-round1.json, play-round2.json, play-round3.json, models-first-five.png, models-second-five.png y build-proof.json en assets/review/tools-theft-foundation/.
- Integración UI/VFX: docs/TOOLS_UI_VFX_INTEGRATION.md.
- Prueba estática existente: 79 fuentes exactas y 56 plantillas PASS. No equivale a aprobación visual.
- Archivo final abierto desde disco y Play iniciado: perfil READY, ocho bases y herramientas disponibles, sin errores bloqueantes observados. Play detenido al terminar. Las sesiones QA anteriores usaron dos clientes.

~~~powershell
Start-Process -FilePath 'C:\RobloxProjects\StealACurse\build-tools-theft-foundation.rbxlx'
~~~

## Implementado

Inventario persistente de permanentes y cargas; hasta tres equipadas, respawn, cooldowns, servidor valida posesión, herramienta en mano, estado, rango, apuntado finito, colocación y consumo. Pala inicial; compras con Souls junto al banco. Una sola infraestructura compartida de efectos recalcula velocidad, limita empujes/raíces y limpia restricciones temporales.

Diez modelos reproducibles mediante Parts/soldaduras, con siluetas distintas y UseHook/ImpactHook/VFXHook. Botas con detalles en ambos pies. Sin nuevas importaciones ni IDs. Presentación separada de los VFX de Curses. No existe todavía aprobación visual de reposo/uso para los diez.

| Herramienta | Souls / etapa | Cooldown | Estado real de verificación |
|---|---:|---:|---|
| Pala | 0 / 0 | 1.8 s | Anticipación, empuje e interrupción; desplazamiento integrado 3.46 studs |
| Botas | 450 / 0 | 12 s | 3 s, +10 libre/+3 transporte; velocidad 26 y detalles de pies comprobados; cambio dinámico pendiente |
| Urna | 120 por 3 / 0 | 3 s | Proyectil/impacto limitado; uso aceptado; prueba dedicada contra paredes pendiente |
| Incensario | 850 / 1 | 18 s | Niebla 6 s; seis piezas en ambos clientes y retirada comprobadas |
| Linterna | 650 / 1 | 8 s | Respuesta vacía y revelado de dos señales comprobados |
| Sal | 100 por 3 / 0 | 3 s | Franja 8 s, máximo dos; velocidad 10.4 y consumo comprobados |
| Cepo | 1100 / 2 | 10 s | Una trampa, raíz 1.1 s; velocidad 0 y retirada comprobadas; desarmado/inmunidad repetida pendientes |
| Talismán | 150 por 3 / 0 | 5 s | Limpia sal/raíces/cadena, inmunidad negativa breve; 10.4 → 16 y consumo comprobados |
| Cadena | 4200 / 3 | 10 s | Anticipación, alcance 28, tirón breve; desplazamiento 4.37 studs y limpieza comprobados |
| Espejo | 3800 / 3 | 16 s | Doble 8 s, máximo uno, un golpe; uso/revelado comprobados; destrucción/límite/última LOS pendientes |

Controles: H abre panel auxiliar; 1/2/3 seleccionan; activación estándar o USAR; comprar/equipar en banco. F mantenida roba, E coloca. Botones y prompts táctiles implementados; móvil emulado y teléfono físico sin comprobar.

## Robo y guardado

Solo Curse ajena colocada elegible. Durante robo mantiene dueño original, libera pedestal inicial y suspende ingresos. Venta/reubicación bloqueadas; carga única incompatible con reliquia. Entrega explícita cerca de pedestal lógico libre propio cambia propiedad una vez.

Interrupción, muerte o desconexión recuperan para dueño original como UNPLACED: recoger y colocar manualmente, sin ingresos ni retorno automático al pedestal. En la prueba de desconexión la instantánea a un segundo seguía CARRYING; después pasó la recogida manual y el cliente ya no estaba en Players. No se afirma recuperación instantánea.

Diario durable local ATTEMPT/COMMITTED por UID, con proyección idempotente a los mismos perfiles; no se representan dos escrituras independientes como transferencia atómica. Marcadores evitan resucitar ventas posteriores. Plugin valida estado/distancia/pedestal en el límite durable. Se corrigió el reintento idéntico de una escritura fallida usando RequestId nuevo; dos entregas concurrentes produjeron una aceptación y un rechazo.

Studio requiere el plugin local propio ya instalado: %LOCALAPPDATA%\Roblox\Plugins\StealACurseToolsLedger.rbxmx y el puente de perfiles existente. Fuente/generador: tools/ToolsLedger.plugin.luau y tools/Build-ToolsLedger.py. Falta/corrupción bloquea perfil sin sustituir cuenta válida.

**Robo online desactivado**: OnlineTheftEnabled=false. Diario online entre propietarios no verificado; un flag no implementa ese backend.

## Compras e integración

Un único ProcessReceipt; cargas y marcador de recibo persistidos antes de reconocer. Error deja recibo pendiente; repetición no duplica. Pases consultados por servidor y precios mediante GetProductInfoAsync en cliente.

**Compras reales desactivadas**: RealPurchasesEnabled=false; dos pases y tres paquetes tienen ID 0 y enabled=false. Solo simulaciones Studio/namespace QA verificadas. No hubo pagos ni publicación.

UI auxiliar y efectos aislados, sin rehacer HUD/tienda/VFX ajenos. Documento de integración contiene snapshots, eventos, IDs y hooks. Limitación: nube iniciada fuera de 120 studs no reconstruye partículas al acercarse; la zona de servidor sí se replica.

## Pruebas existentes

- 16/16 casos de lógica PASS: migración, límites, cargas, recibos, efectos y recuperación de diario, incluida venta posterior.
- Dos clientes reales en namespace aislado qa-tools-20261003-190655: reclamar bases, compra, colocación, robo y entrega única; venta durante robo y entrega repetida rechazadas.
- Guardado/recarga conservan propiedad, inventario, tres equipadas y recibos. Muerte conserva dueño original UNPLACED; recarga exige recuperación manual.
- Interrupción por pala, desconexión seguida de recogida/colocación/venta por 50 Souls; venta duplicada rechazada y pedestal libre.
- Fallos ATTEMPT/COMMITTED conservan estado recuperable. Reintento idéntico corregido; entrega concurrente exactamente una, ambos perfiles guardados.
- Sello activo rechaza robo; cuarto slot, datos no finitos, distancia inválida y spam rechazados en casos muestreados.
- Diez usos aceptados y nueve compras adicionales con Souls aceptadas. Botas, sal, cepo y talismán tienen medidas concretas en tabla.
- Recibos simulados repetidos y fallo de flush/reintento sin concesión doble; pase simulado no concede propiedad permanente.
- Limpieza de efectos locales/world y restricciones físicas comprobada. Dos capturas de galería en Roblox: algunos modelos parcialmente tapados por avatar; no son diez aprobaciones de agarre/uso.
- No se repitió todo el catálogo ni todos los contratos.

Rendimiento breve: 90 cuadros, cliente secundario 677×673, 21 Curses, dos clientes y servidor en un PC. Base media 32.21 ms/p95 42.44 ms/memoria 2202.74 MB; niebla+doble+linterna 34.87 ms/p95 50.42 ms/2201.53 MB, dos zonas y ocho efectos locales. No extrapolar a móvil/ocho jugadores ni atribuir CPU individual.

## Manifiesto y reconstrucción

Nuevos: shared ToolCatalog, ToolInventory, ToolEffectsMath, TheftLedgerMath; servidor ToolModels, ToolService, ToolStatusService, TheftLedger, TheftService, ToolCommerce; cliente ToolsInput, ToolPresentation, ToolOffers; pruebas/generador QA; plugin/generador local.

Modificados: init servidor/cliente, CurseService, ProfileStore y CursePresentation (base del transportista para seguimiento). Arquitectura, datos/economía de Curses, rigs y recursos conservados. Estación práctica generada por ToolService.

Reconstruir con `rojo build default.project.json --output build-tools-theft-foundation.rbxlx`. Configuración normal sin seed ni API QA. tests/Build-ToolsReview.py admite --namespace qa-tools-... para perfiles aislados. tools/Finish-ToolsCore.py fue un auxiliar de edición: no volver a ejecutarlo para reconstruir.

## Pendientes reales y continuación

1. Revisión visual de agarres, anticipación/acción/recuperación de los diez y controles/apuntado táctiles. Sin aprobación móvil.
2. Base llena, desconexión del propietario, liberación/cambio de etapa durante robo, pedestal original ocupado y cortes adicionales de guardado. Venta posterior cubierta por lógica; falta recarga real tras la última venta.
3. Paredes para pala/urna/cadena; destrucción única/límite de doble y última validación LOS; desarmado e inmunidad repetida; bonus dinámico de botas al comenzar transporte.
4. Regresión enfocada de reliquias/rituales, escaleras avanzadas y ocho jugadores. No repetir las 56 animaciones por defecto.
5. Persistencia online de transferencias y pagos reales con IDs/autorización disponibles. Mantener desactivados.

Siguiente paso concreto: desde checkpoint 04, completar revisión visual/táctil y los casos de carrera listados. Esta entrega es utilizable localmente pero parcial; no declara cumplidos todos los criterios.

## Nota final de cierre

2026-10-03: el archivo normal final abrió desde disco e inició Play sin errores bloqueantes observados (consola consultada vacía). Perfil READY, ocho bases, ToolTemplates y remotos presentes; ToolsReviewAPI ausente; ambas disponibilidades online false. Se observó HUD y personaje en la captura final-startup.png. No se reclamó base, compró ni alteró la colección personal para este cierre. Play detenido al terminar. El hash del archivo coincide con build-proof.json y checkpoint 03; las 79 fuentes siguen iguales al comprobante existente: no fue necesaria reconstrucción ni repetir pruebas.

Checkpoint 04 actualizado con proyecto, sources.zip recuperable del checkpoint 03 (fuentes sin cambios), ambos informes actuales y manifiesto SHA256. Recursos nativos continúan en assets/imports; no se duplican checkpoints anteriores ni vídeos.
