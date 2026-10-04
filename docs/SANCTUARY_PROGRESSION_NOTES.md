# Restauración: reglas, economía y migración

Configuración: `src/shared/SanctuaryConfig.luau`. Reglas puras: `src/shared/SanctuaryProgression.luau`. Los servicios del servidor autorizan las interacciones físicas, orden, distancia, propiedad y exclusión de operaciones; las tablas compartidas no otorgan autoridad al cliente.

## Diez etapas

Los costes son por etapa, no acumulados. Ninguna compra consume una Curse, borra descubrimientos, hace rebirth, requiere Robux o aumenta el ingreso por criatura.

| Etapa | Capacidad | Souls | Fragmentos | Especies | Otros requisitos permanentes |
|---|---:|---:|---:|---:|---|
| 0: sin restaurar | 5 | — | — | — | Punto de partida y posiciones existentes |
| 1: Patio restaurado | 6 | 150 | 0 | 1 | Primera vigilia: una especie propia colocada y dos marcas |
| 2: Ala de colección | 8 | 750 | 6 | 3 | Un contrato; Casa encantada, tres especies alternativas |
| 3: Santuario cerrado | 10 | 2.200 | 14 | 5 | Tres contratos, una recuperación y una secuencia de sellado |
| 4: Galería superior | 14 | 6.500 | 24 | 7 | Compañeros inquietos y Casa encantada; vigilia de colección |
| 5: Galería expandida | 18 | 13.000 | 36 | 10 | Ocho contratos, dos transportes; Arboleda viva y Melodías perdidas |
| 6: Sello protector | 18 | 22.000 | 48 | 12 | Tres secuencias de sellado y nueve marcas activadas |
| 7: Sala de reliquias | 22 | 45.000 | 70 | 15 | Catorce contratos, una reliquia mayor entregada; consagración |
| 8: Cámara expandida | 26 | 80.000 | 90 | 20 | Tres conjuntos a elegir entre seis |
| 9: Santuario consagrado | 26 | 140.000 | 120 | 24 | Veintidós contratos, dieciocho marcas; gran sello |
| 10: Dominio de las Curses | 30 | 220.000 | 160 | 28 | Treinta contratos, dos reliquias mayores; cinco conjuntos a elegir, ritual final y tres rituales anteriores |

Total de mejoras: **529.600 Souls y 568 Fragmentos**. Los fragmentos se gastan; especies, conjuntos, hitos y rituales se conservan. El servidor vuelve a evaluar la siguiente etapa inmediatamente antes del descuento. Una confirmación repetida del nivel anterior falla sin descontar otra vez.

### Ritmo estimado, no datos de jugadores

El catálogo leído mantiene Common de 80–290 Souls con 2–5,5 Souls/s (incluida Cursed Doll, 100/3) y Rare de 400–1.700 con 10–36 Souls/s. Una cuenta comienza con 500: después de una primera Common y 150 de restauración conserva recursos para seguir jugando. Los costes superiores se apoyan en una colección creciente; ninguna Secret es requisito.

Las 32 especies Common/Rare bastan para satisfacer todos los conjuntos y el umbral final de 28. Melodías perdidas acepta dos entre Hollow Violin, Chime Triplets, Music Box Dancer, Pale Gramophone y alternativas superiores. Arboleda viva acepta tres entre Grave Hopper, Wilted Sprout, Nail Beetle, Raven Quill, Anchor Crab, Thorn Reliquary y alternativas superiores. Relojes sin dueño acepta dos entre Hourglass Hound, Grave Compass, Music Box Dancer y Sundial Sentinel, entre otras. Se muestran alternativas pendientes, no una lista que obligue a obtenerlas todas.

Una colección inicial de cinco Common produce aproximadamente 10–25 Souls/s; mezcla de Common/Rare y mayor capacidad puede superar 100–250 Souls/s sin multiplicadores. Las actividades pagan 4–14 fragmentos y pueden repetirse continuamente. Los 568 fragmentos equivalen aproximadamente a 45–75 contratos con una combinación creciente de variantes; a 45–100 segundos de desplazamiento/actividad por contrato son unos 35–125 minutos de actividad. Considerando adquisición de especies y crecimiento económico, un objetivo inicial de unas **2–4 horas de juego activo** para la restauración completa es una estimación de diseño, no una medición ni una promesa. La disponibilidad y tiempos reales requieren pruebas con jugadores; los pesos y la procesión secuencial local actuales siguen siendo configuración de desarrollo.

## Contratos

Un contrato activo por perfil. `step` cuenta nodos completados: empieza en 0, el objetivo es `nodes[step+1]`, y tras validar el último nodo vale `#nodes`. El pago exige el ID y token del contrato activo, una fase activa/de carga y todos los pasos completados. El mismo bloque sin esperas elimina el contrato, suma fragmentos y actualiza hitos; un segundo mensaje ya no tiene un contrato que pagar. El servicio valida la entrega física antes de llamar a estas reglas.

| Contrato | Tipo | Etapa mínima | Fragmentos | Recorrido |
|---|---|---:|---:|---|
| Una pieza perdida | Recuperación | 0 | 4 | Entrada del cementerio → altar propio |
| Recuerdo del pozo | Recuperación | 1 | 5 | Pozo antiguo → altar propio |
| Raíz del recuerdo | Recuperación | 3 | 8 | Santuario del bosque → altar propio |
| Luz para la capilla | Transporte | 0 | 4 | Sepulturero → escalinata |
| Farol entre raíces | Transporte | 2 | 7 | Sepulturero → santuario del bosque |
| Luz de estrellas | Transporte | 5 | 11 | Sepulturero → piedra astral |
| Tres marcas del camposanto | Sellado | 0 | 5 | Entrada → pozo → patio del castillo |
| La senda sellada | Sellado | 3 | 9 | Pozo → bosque → escalinata |
| Constelación terrestre | Sellado | 6 | 12 | Escalinata → piedra astral → patio |
| La reliquia mayor | Recuperación mayor | 6 | 14 | Piedra astral → altar propio |
| Memoria del castillo | Recuperación mayor | 8 | 14 | Patio del castillo → altar propio |
| El círculo completo | Sellado | 8 | 14 | Bosque → patio → piedra astral |

Solo las entregas de las dos variantes mayores incrementan `majorRelics`. Cada marca de sellado validada incrementa `sealActivations`; repetir el mensaje del mismo paso no debe invocar ese incremento nuevamente. Abandonar elimina únicamente el contrato activo, sin descontar recompensas anteriores.

## Rituales

| ID | Disponible desde | Especies distintas propias colocadas | Secuencia | Otros requisitos |
|---|---:|---:|---|---|
| `first_vigil` | 0 | 1 | 1, 2 | Tutorial de presentación |
| `collection_vigil` | 3 | 3 | 1, 3, 2 | Desbloqueo de etapa 4 |
| `relic_consecration` | 6 | 4 | 2, 1, 3, 2 | Una reliquia mayor ya entregada |
| `grand_seal` | 8 | 5 | 3, 1, 2, 3, 2 | Desbloqueo de etapa 9 |
| `dominion` | 9 | 6 | 1, 2, 3, 1, 3, 2 | Dos reliquias mayores ya entregadas |

Descubrimientos históricos no sustituyen a especies propias colocadas durante el ritual. Duplicados de una especie cuentan una sola vez. Las representaciones rituales son temporales, sin propiedad o ingresos nuevos. Las reglas no mueven inventario ni cambian pedestales. La finalización se registra una vez después de que el servicio haya validado la secuencia física; si se cancela o falla, el servicio limpia la representación y permite reintento.

## Perfil y migración

El esquema base permanece en `schema=1`, con Souls, `curses` y `revision` conservados. Campo nuevo:

```text
sanctuary = {
  schema = 1, level = 0..10, style = CRYPT|FOREST|OBSERVATORY,
  fragments = entero 0..1000000,
  discoveries = { [ID válido de especie] = true },
  milestones = { contracts, recovery, transport, sealing, majorRelics, sealActivations },
  rituals = { [ID válido de ritual] = true },
  contract = nil | { id, token, step, phase, startedAt, carryState? = { nodeId } },
  featuredUid = nil | UID de una única Curse propia colocada
}
```

- La carga valida primero la cuenta base. Un error de lectura o cuenta inválida deja el perfil no disponible y conserva los datos; no crea una cuenta nueva sobre ellos.
- Perfiles antiguos **sin** campo `sanctuary` registran una vez las especies de su inventario legítimo, incluidas `UNPLACED`: el esquema antiguo no conserva el historial de primera colocación y sí conserva la propiedad. Es una concesión de migración documentada, no la regla para compras nuevas.
- Una vez que existe el campo, recargar una nueva compra `UNPLACED` no concede descubrimiento. Solo el hook de colocación legítima del servidor llama a `discover`.
- Especies ya descubiertas permanecen al vender o perder su instancia. Campos nuevos inválidos se normalizan individualmente, sin sustituir Souls, inventario, revisiones o posiciones.
- Números no finitos, fracciones o valores fuera de límites reciben valores seguros. Se descartan IDs desconocidos. Una versión futura del esquema de santuario falla de forma conservadora y no se sobrescribe.
- Un contrato guardado `CARRYING` se carga como `RECOVERABLE`, conservando ID y token. La etapa física vuelve a la recogida del primer nodo alcanzable; no se entrega ni paga automáticamente. Los pasos completados de un contrato de sellado sí se conservan, ya que no transportan una reliquia.
- Un exhibidor apunta al UID de una Curse real colocada. Referencias ajenas, vendidas o sin colocar se eliminan; no se crea una copia.
- En Studio se utiliza el plugin de perfiles local existente y su journal con reconocimiento de revisión. Una migración/perfil nuevo genera un commit al completar la inicialización; se mantiene el autosave existente, sin escrituras por movimiento o fotograma.
- Online se mantiene `UpdateAsync` y la lease de sesión; la migración ocurre después de validar y dentro de esa operación. No se publicó ni se creó un entorno online para probar persistencia.

## API de integración

`migrate(profile)` devuelve `sanctuary, changed, notes`; modifica solo el nuevo campo. `newProgress()` crea valores iniciales. `snapshot(sanctuary)` copia tablas para la UI sin compartir memoria autoritativa.

`evaluate(profile,nextLevel)` devuelve `{eligible,nextLevel,title,capacity,benefit,requirements}`. Cada requisito incluye `id,kind,label,current,target,complete`; conjuntos incluyen `found/missing`, requisitos alternativos incluyen `alternatives`. `tryUpgrade(profile,nextLevel)` devuelve `ok,report` y descuenta exactamente una vez sin esperas; el servicio valida ubicación, exclusión y arquitectura antes de llamarlo.

`discover(profile,id)` devuelve si se registró por primera vez. `setProgress(sanctuary,id)` da alternativas y conteo. `ritualEligibility`, `ownedPlacedSpecies` y `completeRitual` operan sobre inventario propio colocado. `awardContract(profile,id,token)` devuelve `ok,rewardFragments`; `recordSealActivation` registra una marca ya validada. `selectStyle` y `selectFeatured` validan identificadores; no alteran capacidad, ingresos o propiedad.

## Verificación disponible

`tests/SanctuaryProgression.spec.luau` contiene 27 casos para el runner existente: catálogo completo, capacidades, migración conservadora/idempotente, nuevas compras sin discovery, corrupción numérica, esquema futuro, recuperación de reliquias, deduplicación, costes atómicos, progresión sin Legendary/Mythic/Secret, pago único y rituales sin consumir inventario. Debe montarse como ModuleScript bajo `UnitTest.Cases` para ejecutarlo en la integración. Esta nota no atribuye resultados de Play ni guardado a pruebas todavía no ejecutadas; la evidencia de ejecución queda en el informe integrado.
