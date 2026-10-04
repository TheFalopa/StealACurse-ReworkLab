# Plan de restauración — 2026-10-03

Rama local `codex/sanctuary-restoration-update`. Punto de partida conservado en `assets/review/sanctuary-restoration/checkpoints/00-polished-start`: 55 fuentes coinciden con Studio y el archivo animado; 56 plantillas tienen skinning nativo. No se publica ni se hace commit.

1. **Infraestructura y primer recorrido:** configuración central y migración; generalizar BaseService, registrar descubrimientos únicamente al colocar; contrato físico con recompensa única; primer ritual y mejora, guardar y recargar.
2. **Progresión permanente:** diez capacidades, conjuntos alternativos, costes reales del catálogo, estilos y exhibidor sin copias de producción. Perfiles V1 conservan Souls, UID y pedestal.
3. **Actividades:** Sepulturero/tablón y nodos accesibles; recuperación, transporte y sellado; carga exclusiva con Curses; recuperación tras muerte/desconexión; rituales con ecos visuales sin ingresos.
4. **Arquitectura:** estructura compartida, tres pisos, escaleras amplias, recinto y cierre temporal validado en servidor. Los pedestales y sus CFrames no cambian al cambiar estilo. El acceso físico no se presenta como robo probado: el servicio de robo todavía no está operativo.
5. **Visual:** auditoría de 56 usando referencias reales existentes y fuentes; remodelación prioritaria de tres Curses con exportación/importación real y revisión en Play. Music Box Dancer y Marrow Dice quedan pendientes para su encargo posterior.
6. **Entrega:** pruebas de lógica y Play, recarga local, dos clientes, móvil emulado, arquitectura/carga/rendimiento, `.rbxlx` autónomo y reporte con evidencia y límites reales.

## Responsabilidades y dependencias

- Configuración y migración: `SanctuaryConfig`, `SanctuaryProgression`, `ProfileStore`.
- Arquitectura: `RestorationArchitecture`, `PlayerShrine`, exclusiones de `Layout`; integración mediante `BaseService`.
- Gameplay: `SanctuaryService`, `ContractService`, `CarryService`, `RitualService`; hooks pequeños en `CurseService`, inicialización en servidor.
- UI: panel contextual único de restauración/Grimorio/contratos/estilos, indicación de carga y ritual; conserva UI y venta actuales.
- Mallas: fuentes/exportaciones separadas en `sanctuary-restoration`; coordinador único importa y conserva datos nativos en `CurseMeshKit.rbxmx`.

El coordinador es el único que controla Studio. Los grupos paralelos tienen archivos exclusivos. Cada checkpoint conserva fuentes, kit nativo y archivo disponible; no equivale a una aprobación visual.
