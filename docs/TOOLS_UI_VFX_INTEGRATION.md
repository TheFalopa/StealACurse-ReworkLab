# Integración de herramientas, UI y VFX

Fecha: 2026-10-03. Rama `codex/gameplay`, base `5194c0c`. Todo local, sin commit ni publicación. La interfaz auxiliar puede sustituirse sin modificar la autoridad del servidor.

## Contrato de datos y acciones

`ReplicatedStorage.ToolsFoundation.Request` es RemoteFunction. Firma: `InvokeServer(action, itemId?, value?)`. Devuelve `{ok, message, data?}`. `data` es un snapshot: `items[id] = {id,name,owned,charges,kind,equipped,price,pack,level,cooldownEnds}`, `equipped` es una lista ordenada, `maxEquipped=3`; `theft` y `carried` son UID opcionales. Las marcas de cooldown usan `workspace:GetServerTimeNow()`.

| Acción | Argumentos | Regla |
|---|---|---|
| snapshot | ninguno | Solo lectura |
| buy | id | Souls y etapa; cerca del banco; paquete configurable |
| equip | id, boolean | Hasta tres, posesión o pase verificado; no equivale a tenerlo en mano |
| hold | id | Equipa el Tool existente en el personaje |
| use | id, Vector3 de apuntado | Validación de estado, cargas, rango y colocación por servidor |
| trial | chain/mirror | Solo Studio, radio 20 del banco; derecho temporal, no persistente |

`Changed` (RemoteEvent, obtener con `WaitForChild('Changed')`, no mediante `.Changed`) envía `(snapshot, openPanel?)`. `snapshot` no concede derechos y no acepta duraciones o precios desde UI. Rechazos incluyen un texto breve; no gastar cargas en rechazos. Un uso aceptado consume la carga aun si después se interrumpe su anticipación.

IDs estables: `shovel`, `ash_boots`, `impact_urn`, `mist_censer`, `exorcist_lantern`, `consecrated_salt`, `root_trap`, `break_talisman`, `jailer_chain`, `double_mirror`.

## Robo y colocación

`ReplicatedStorage.CurseTheft.Request:InvokeServer('start', uid)` o `('place', logicalPedestalId)`. Respuesta `{ok,message}`. También hay prompts `StealCurse` sobre la PrimaryPart de una Curse ajena y `PlaceCurse` sobre el pedestal; la entrega pasa por el servicio existente de Curses. F: mantener para robar; E: colocar. Móvil usa prompts estándar.

Atributos del jugador: `CarriedCurseUid`, `StolenCurseUid`; `TheftDeliveryUid` es solo la reserva transitoria del servidor, no una acción de UI. En el modelo: `OwnerUserId`, `CarrierUserId`, `StealingUserId`, `OperationLocked`, `CarryBaseId`, `BaseId`, `PedestalId`. Mostrar claramente que la propiedad sigue siendo original hasta una entrega confirmada. Una interrupción produce UNPLACED recuperable para el dueño; no devolver visualmente al pedestal.

## Sustitución de presentación

`src/client/ToolsInput.luau`: panel auxiliar separado `ToolsFoundationUI`, H, tres slots 1/2/3, botón USAR y feedback. Se puede retirar su arranque y conectar la UI nueva a los remotos descritos. No sustituye el HUD general ni la tienda definitiva; no modifica SetCoreGuiEnabled. Compatibilidad táctil completa todavía requiere revisión.

`src/client/ToolPresentation.luau`: efectos aislados en `workspace.LocalToolEffects`. `ToolsFoundation.Effect` envía `(effectId, worldPosition:Vector3, data:table)`:

| ID de efecto | Datos útiles |
|---|---|
| anticipate | id de herramienta, userId, duration |
| ash_boots | userId, duration; anclaje local temporal ToolAshHook en pies |
| mist_censer | duration, radius, token |
| consecrated_salt / root_trap / double_mirror | duration, radius, token; geometría de zona replicada |
| chain | finish:Vector3, duration |
| reveal | token = nombre del modelo de zona, duration |
| impact / lantern | radius |
| cleanse / roots / decoy_break / disarm | posición; reacción breve |

La presentación actual descarta eventos a más de 120 studs. Una nube iniciada fuera de ese radio no reconstruye sus partículas al acercarse: mejora futura concreta. Sus zonas sí se replican. Los efectos temporales se limpian con Debris y al retirar la zona; no deben quedarse tras muerte/desequipamiento de inventario.

`ToolService` genera modelos autoritativos en `StealACurseMap.ToolEffects`. Cada zona tiene `Kind`, `OwnerUserId`, `EffectToken`, `EndsAt`. Mirror: `Decoy=true`, `HitPoints=1`; no UID, propiedad ni producción de Curse. Niebla/sal/cepo se consultan mediante este estado, nunca mediante partículas. No borrar zonas desde la UI ni sustituir colisiones/validación por VFX.

`ToolModels.luau` genera Tools con Handle y attachments estables `UseHook`, `ImpactHook`, `VFXHook`. La geometría se suelda al Handle. Las botas añaden `AshFootTalismans` con Left/Right Cuff/Seal al personaje mientras están en mano. Se conservan todos los anclajes, rigs y VFX de las 56 Curses. No hubo importaciones ni IDs nuevos.

## Compras

`ToolsFoundation.Commerce:InvokeServer('offer', offerId)` devuelve oferta configurada `{ok,id,kind,item,enabled}` o rechazo. Adaptador aislado `ToolOffers.describe(id)` consulta precio en el cliente mediante MarketplaceService:GetProductInfoAsync; `ToolOffers.prompt(id)` abre el diálogo. La concesión permanece en servidor.

Ofertas: `chain_pass`, `mirror_pass` (pases); `urn_bundle`, `salt_bundle`, `talisman_bundle` (productos, diez cargas). Actualmente IDs=0, enabled=false y RealPurchasesEnabled=false. No habilitar antes de configurar IDs propios reales y verificar permisos/persistencia. Solo `ToolCommerce` asigna ProcessReceipt. No conceder al cerrar el diálogo. Los recibos se guardan junto a las cargas y solo se reconocen tras flush durable; un reintento no añade otra recompensa.

Referencias oficiales consultadas: [productos](https://create.roblox.com/docs/production/monetization/developer-products), [guardado de compras](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing), [precios regionales](https://create.roblox.com/docs/production/monetization/regional-pricing). Compras reales sin probar.

## Archivos centrales y recuperación

- `src/server/init.server.luau`: líneas 29–33 arrancan ToolService, TheftService y ToolCommerce y enlazan interrupciones.
- `src/client/init.client.luau`: líneas 18–19 arrancan módulos aislados de entrada/presentación.
- `ProfileStore.luau`: migración tools y toolTransfers; recuperación idempotente del diario local antes de aceptar perfil Studio.
- `CurseService.luau`: prompts/operaciones de robo, reservas y proyección a los mismos registros de colección/ocupación; no hay segundo inventario de Curses.
- `CursePresentation.luau`: durante robo sigue la base del transportista para el suelo/seguimiento.
- `rokit.toml`: cambio local anterior conservado; no forma parte de un rework de UI/VFX.

Para Studio se necesita el plugin local del diario ya instalado en `%LOCALAPPDATA%\Roblox\Plugins\StealACurseToolsLedger.rbxmx`, junto al plugin existente de perfiles. Fuente en `tools/ToolsLedger.plugin.luau`; generar mediante `tools/Build-ToolsLedger.py`. Después de actualizarlo, abrir otra sesión de Studio para cargar su versión actual. No contiene accesos externos. Si falta o está corrupto, el perfil se bloquea sin sustituir datos válidos.

El diario usa namespace separado, ATTEMPT/COMMITTED y RequestId por cada intento, incluidas escrituras idénticas. Robo online deshabilitado: no hay diario DataStore entre propietarios verificado. Cambiar un flag no implementa ese backend.
