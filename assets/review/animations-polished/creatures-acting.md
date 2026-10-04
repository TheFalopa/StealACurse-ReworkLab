# Actuación de 16 Curses: criaturas, títeres e instrumentos

## Estado real

Implementación editable preparada en `src/client/CurseActsCreatures.luau`. Las 16 fuentes se inspeccionaron en Blender 5.2.2 mediante la geometría, los pesos, los pivotes y la jerarquía reales; el registro está en `creatures-rig-audit.json`. Este documento no concede aprobaciones visuales en Studio. La revisión del proyecto integrado, sus importaciones y sus pruebas de gameplay corresponde al coordinador principal.

El módulo devuelve 16 funciones al controlador compartido. Escribe únicamente `Bone.Transform`, sin modificar posición autoritativa, prompts, pedestales, propiedad ni VFX. Requiere `e.rest`, `e.distance`, `e.scale` y las funciones `H.pose`, `H.gait`, `H.pulse`, `H.smooth`. La descomposición de rotación usa `ToEulerAnglesXYZ`, coherente con `CFrame.Angles` del escritor compartido.

## Intención y anatomía

| Curse | Estructura real y reposo | Ruta y acompañamiento |
|---|---|---|
| Grave Hopper | Cuatro patas, cuerpo/caparazón pétreo. Explora ladeándose y da un sobresalto ocasional. | Pares delantero/trasero coordinados; preparación, elevación y aterrizaje de salto, con vuelo común y flexión del caparazón. |
| Hourglass Hound | Cuatro patas, cabeza y cola; reloj de arena permanece rígido. Olfatea, orienta la cabeza y mueve la cola. | Trote diagonal, cuerpo bajo y apoyos compensados; cola acompaña los pasos y cabeza busca el recorrido. |
| Nail Beetle | Seis patas y placa de clavo diferenciada. Clavo da una contracción breve. | Dos trípodes alternos, apoyos prolongados y retorno corto; placa reacciona sin deformar el caparazón. |
| Coin Crawler | Cuatro patas, carapacho/moneda y ojos. Asoma los ojos elevando brevemente la moneda. | Rastreo bajo, diagonales coordinadas y pequeños balanceos del cuerpo; las patas conservan apoyo mientras el carapacho mira. |
| Thimble Spider | Ocho patas y colmillos. Acecha agachándose y prueba los colmillos. | Tetrapodos alternos; las ocho patas se doblan alrededor de sus rodillas reales y avanzan en fases opuestas entre ambos lados. |
| Anchor Crab | Seis patas, pinza pequeña y pinza grande, cada una con mandíbula. Amenaza primero con la pinza grande. | Onda de apoyos entre tres patas de cada lado; retorno suave, contrapeso del cuerpo y apertura diferida de las dos pinzas. |
| Hollow Violin | Dos patas, tres cuerdas reales y voluta. Se inclina para escuchar y responde con una frase de cuerdas. | Pasos medidos, apoyos compensados y mirada de la voluta; cuerda 0/1/2 resuenan en secuencia. |
| Clockwork Raven | Dos patas, dos alas distintas, cabeza, rueda posterior y cola. Mira, abre las alas con retraso y hace funcionar la rueda. | Pasos de ave, cola como contrapeso y alas elevadas. Se corrigieron los signos que anteriormente bajaban las puntas hacia el suelo. |
| Eclipse Stag | Cuatro pezuñas, cabeza/astas, crin y cola. Inspecciona desde postura alta y mueve la crin por separado. | Diagonales elegantes, flexión de patas y compensación del cuerpo; las grandes astas no reciben un balanceo indiscriminado. |
| Thorn Cathedral | Cuatro apoyos de piedra, rosetón y campanario. Rosetón gira y sostiene pose; campanario da una respuesta corta. | Marcha de cuatro tiempos con apoyo largo y altura contenida; no se hace saltar toda la catedral. |
| Endless Library | Cuatro patas, tres libros independientes, páginas superiores y marcapáginas. Consulta tomos y abre las páginas en secuencia. | Marcha de biblioteca pesada, apoyos diagonales; marcapáginas siguen el avance mientras los tomos conservan su volumen. |
| Marrow Dice | Dos dados y tres puntos/sustancias separados, sin patas. Los dados dialogan mediante inclinaciones y elevaciones desfasadas. | Flotación corta e irregular, con dado grande anticipando al pequeño; puntos reaccionan después. No se fuerza una caminata. |
| Music Box Dancer | Caja, tapa, bailarina, cabeza y un brazo ponderado independiente. La bailarina gira, saluda y hace reverencia. | La caja permanece estable mientras actúa la bailarina; brazo, cabeza y tapa acompañan la frase. El otro brazo conserva su pose esculpida y participa con el giro de la bailarina. |
| Sleepwalker Shoes | Dos botas asimétricas ponderadas por separado. Una da pequeños golpes impacientes, la otra espera. | Pasos alternos talón/punta, elevación de suela y retorno suave; corrección conservadora de altura usando sus volúmenes medidos. |
| Phantom Marionette | Cuerpo, cabeza, cuatro miembros con codos/rodillas y cuatro cuerdas. Las tensiones se transmiten de una mano al cuerpo y a la otra. | Patadas desiguales por distancia, suspensión y respuesta tardía de los extremos; no se simulan pies plantados para un títere colgado. |
| Sunken Crown | Circlet rígido y seis tentáculos con puntas propias. Una onda recorre los seis con retraso adicional en las puntas. | Flotación moderada sobre el suelo y tentáculos algo retrasados; movimientos radiales adaptados a la estructura, sin piernas inventadas. |

Reposo/estado sin colocar usa los gestos de cada concepto; procesión, entrega y transporte usan el avance real acumulado. El cambio entre actuación estacionaria y marcha se mezcla con la ganancia compartida. Las transiciones de recogida/colocación y la reducción de detalle por distancia pertenecen al controlador común; este módulo no crea un segundo escritor.

## Reparaciones necesarias conservando apariencia

Cuatro fuentes nuevas están en `assets/source/blender/animations-polished/`; los FBX están en `assets/export/meshes/curses/animations-polished/`. Los archivos anteriores permanecen disponibles. El manifest `creatures-rig-repairs.json` contiene rutas, hashes, tamaños, huesos y coordenadas de contacto. El hash de vértices, caras, materiales, UV y colores es idéntico antes/después en los cuatro modelos.

| Curse | Problema comprobado en fuente | Reparación |
|---|---|---|
| Thimble Spider | La selección de patas por centro 3D vinculaba segmentos distales a otra pata; Leg3/Knee3 no incluían su apoyo al suelo. Rodillas nominales estaban demasiado cerca del cuerpo. | Ocho trayectorias anatómicas, cada una con 70 vértices propios; articulación y mezcla de pesos en cada rodilla real. |
| Anchor Crab | Las rodillas estaban cerca del torso, con peso distal casi limitado a la punta. | Seis trayectorias de 82 vértices y pivotes en sus uniones de bronce. |
| Nail Beetle | Pivotes de Knee# en x≈1,04 studs cuando la geometría se dobla más afuera y por encima del arranque. | Seis trayectorias de 50 vértices, con la rodilla en la unión real del hierro doblado. |
| Phantom Marionette | ArmL/ArmR/LegL/LegR tenían cero vértices directos; cada miembro completo seguía el hueso distal. | Mezcla proximal/distal en los cuatro codos/rodillas; proximales ahora ponderan 76/75/75/76 vértices. Extremos superiores de cuerdas siguen Root e inferiores siguen ArmLTip, Head, ArmRTip y Body. |

No se cambian nombres ni padres de huesos. Exportación individual: FBX .01, Armature NULL, sin leaf bones ni clips horneados. El coordinador aplica el prefijo `id__` del lote e importa assets reales. Este subtrabajo no inventa ni asigna IDs importados.

## Integración VFX

No se modificó ningún archivo de VFX ni ningún Attachment. Nombres y superficie original permanecen. En los tres artrópodos cambian los bind pivots de `Leg#/Knee#`; en Marionette cambian ligeramente los pivotes de sus miembros y los pesos de las cuerdas. Si un efecto de un amigo usa offsets de la rodilla anterior, debe revisarlos respecto a la nueva articulación: el manifest conserva coordenadas anterior/nueva. Los anclajes que siguen Root conservan el espacio del modelo. Los efectos ligados a partes ahora siguen su geometría articulada real.

## Comprobaciones y límites

- Lectura real de los 16 `.blend`, grupos ponderados y jerarquías, sin basarse únicamente en metadatos del catálogo.
- Cuatro reparaciones exportadas con geometría/apariencia idénticas y fuentes anteriores conservadas.
- 17.328 objetivos de marcha calculados sobre 48 patas: con las longitudes, la flexión y el centrado elegidos, ningún objetivo del caso numérico excede el alcance de los dos segmentos. Datos: `creatures-foot-markers.json` y `creatures-gait-reach-check.json`. Esta comprobación es geométrica, en marcha completa con traslación del cuerpo; no sustituye la revisión de deformación, pequeños giros ni cambios de dirección en Play.
- Ajustes numéricos de IK dependen del bind nativo realmente importado y de que el escritor compartido use XYZ. El coordinador debe revisar las mallas reparadas y las restantes sobre el archivo integrado.
- Los pivotes anteriores de algunos modelos conservados (en especial Library/Stag) son aproximados. El solver emplea los pivotes existentes; cualquier deformación inadecuada observada requiere corrección concreta, no declarar aprobación por existir Transform.
- Compilación/reproducción nativa, compra/transporte/colocación, dos clientes y evidencia final están pendientes de revisión del coordinador en el juego integrado.
