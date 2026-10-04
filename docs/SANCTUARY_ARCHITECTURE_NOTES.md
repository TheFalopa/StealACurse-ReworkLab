# Sanctuary architecture integration

The implementation is in `src/server/Map/RestorationArchitecture.luau`. `PlayerShrine.build(map)` keeps the existing map construction entry point and calls `Architecture.buildInitial(map)`.

## API and stable objects

`Architecture.apply(base, level, style, featuredPedestalId)` prepares one replacement decorative model outside the live base, then performs a synchronous swap. It does not yield, place a Curse, change ownership, produce income or write a profile. Failure during preparation destroys the replacement and retains the old decoration.

It returns `{ pedestals, altar, gate, ritualMarkers, recoveryBays, frame, footprint, capacity }`. `Architecture.getFrame(base)` derives the current world frame from the unchanged spawn. The shared `SanctuaryConfig.Levels[level].capacity` is the only capacity configuration.

These Instances survive every upgrade and style change:

- `PlayerSpawn`, `FutureCurseDisplayArea`, `SanctuaryFloor`.
- The thirty direct pedestal markers. The original five retain names `DisplayPlinth_1..5` and identities `floor1-slot1..5`; later names are `DisplayPlinth_floorN_slotM`.
- `RestorationAltar`, a BasePart at local `(-10, 3, -27)`.
- `SealBarrier`, a direct BasePart with `RestorationSealBarrier=true`. Architecture changes its palette only; it does not reset collision/transparency or remove owner collision constraints.
- `RitualMarkers/RitualMark_1..3` at local X/Z `(-7.5,-8)`, `(7.5,-8)`, `(0,13)`.
- `RecoveryBays/RecoveryBay_1..6`, X `-8/+8`, rows Z `-15/5/25`, at the lower court surface. These markers have 16 studs horizontal and 20 studs longitudinal separation.

Every pedestal has permanent `LogicalPedestalId`, `FloorIndex`, `SlotIndex`, `PedestalBaseId`, and, for the first five, `LegacySlotIndex`. Active markers have `PedestalId`, `PedestalActive=true` and simple collision. Inactive markers retain their Instances and logical identity, but have no `PedestalId` and have collision/query disabled. Existing `OccupiedCurseUid` and other gameplay attributes are never reset. Deactivating an occupied marker raises before any architectural mutation.

All pedestal CFrames are established at initial construction and remain identical across upgrades and styles. Current save records retain their logical pedestal IDs. Their physical arrangement changes from the older five-slot court when rebuilding this new architecture; apply a restored level **before** restoring placed Curses.

## Dimensions and physical layout

The common footprint is 104×104 studs: local X `-52..52`, local Z `-36..68`, center Z `16`. The old site, site elevation, orientation, spawn `(0,1.4,-18)` and claim approach remain. The entrance is at Z `-34` and has 24 studs clear width; its seal is 21 studs high.

The 66-stud-wide collection hall has two display banks at X `-23/+23`, in rows Z `-15/3/21/39/57`. This leaves a broad central aisle. Pedestal tops are `3.4`, `25.4`, `47.4`; walking surfaces are `1.15`, `23.15`, `45.15`. Floor spacing is 22 studs. Upper slab undersides leave 18.85 studs above the pedestal top below. Current visual configuration bounds of width 11, height 13 and depth 6 fit with margin; dynamic pose/VFX clearance still requires integrated visual review.

The west stair climbs from floor 1 to 2; the east stair climbs from floor 2 to 3. Centers X `-42/+42`, inner edge at the hall edge X `-33/+33`, outer edge at the perimeter wall's inner face X `-51/+51`. Each provides 18 usable studs, rises 22 over a 44-stud run (26.565°), has 24 visible treads, one continuous simple collision ramp and a 16-stud upper landing. Decorative treads and thin handrails do not add collision. Early gallery floors extend to Z `36`, providing 12 studs of landing/hall overlap for turning; later extend to `50`, then `66`.

| Level | Floor 1 | Floor 2 | Floor 3 | Total |
| --- | ---: | ---: | ---: | ---: |
| 0 | 5 | 0 | 0 | 5 |
| 1 | 6 | 0 | 0 | 6 |
| 2 | 8 | 0 | 0 | 8 |
| 3 | 10 | 0 | 0 | 10 |
| 4 | 10 | 4 | 0 | 14 |
| 5 | 10 | 8 | 0 | 18 |
| 6 | 10 | 8 | 0 | 18 |
| 7 | 10 | 8 | 4 | 22 |
| 8 | 10 | 8 | 8 | 26 |
| 9 | 10 | 8 | 8 | 26 |
| 10 | 10 | 10 | 10 | 30 |

The level-zero court is dark. Level 1 restores the court palette and ritual marks. Levels 2/3 enlarge the lower display court, and level 3 introduces glazed enclosure walls and a rear roof canopy. Levels 4/5 and 7/8 add then expand their galleries. Level 6 adds a seal emblem, level 9 a consecrated cornice, and level 10 the final crest plus the final two pedestals on each upper floor. The rear roof canopy leaves most of the collection open to the camera.

## Styles and existing assets

`CRYPT`, `FOREST`, `OBSERVATORY` share all functional geometry and collision. Cripta uses light stone, warm candles and ancestor plaques; Bosque uses wood, green lantern light, authored guardian roots and a timber crown; Observatorio uses dark stone, cool astral light and an astral emblem. Each base adds two modest shadowless lights only.

The implementation reuses real, already verified `final_collection_pedestal`, `final_gothic_doorway` and `root_serpent` templates from `MapMeshKit`; no new mesh IDs are fabricated. Mesh ornament collision is disabled and uses simple structural Parts. It does not alter any Curse meshes, rigs, animations or VFX attachments. Featured display selection adds small inlays around the existing selected pedestal; it creates no Curse copy and changes no production.

All owned Parts have `RestorationArchitecture=true`. `SurfaceArt.build` must skip them: its external pedestal wear and automatic palette changes would otherwise survive decorative regeneration and leave floating or mismatched marks. Architecture applies its own style colors.

## Static checks and integration dependencies

The nearest base centers are 202.87 studs apart, so these footprints do not overlap each other. A direct calculation using the original irregular outer boundary found rear corners outside the old fence by up to 17.61 studs at Base08. An outer fence radius of 406 instead of 380 gives at least 8.39 studs corner clearance; collision ground dimensions of 860×860 cover that perimeter. This is a perimeter adjustment, without changing the castle, procession or approach paths.

Three explicit nearby landmarks also need root integration review: ChainedTree near Base03 (3.89 studs outside the new boundary but tree radius 21), Crypt2 near Base08 (6.04 outside vs roughly 12 extent) and Crypt3 near Base02 (8.15 outside vs roughly 12 extent). `Layout.reserved` must use the new rectangular footprint, and explicit landmark sites need suitable separation. Merely changing procedural exclusion does not move fixed landmarks.

The architecture exposes `SanctuaryFrame`, `RestoreBoundaryExtents=(52,70,52)`, `RestoreBoundaryCenter=(0,35,16)`, `TerritoryWidth/Depth`, `TerritoryCenterZ`, `TerritoryMinZ/MaxZ`, `ArchitecturePartCount` and `ArchitecturePartBudget=300`. Because map construction translates all Instances after building, `SanctuaryFrame` is refreshed by `apply` on claim; code needing the frame earlier should call `getFrame` or recompute from `PlayerSpawn`.

Before the facade correction, construction used approximately 177 architecture Parts at level 10 with Cripta and a featured pedestal. The facade revision is estimated below 300 per advanced base, including a featured pedestal; `ArchitecturePartCount` records the actual runtime count. These are construction estimates, not Play performance measurements.

### Suggested integrated structural checks

Run against a disposable test base in a legitimate server test script, not a player's production collection:

1. Snapshot all thirty marker Instance references and CFrames. Apply levels 0..10 and all three styles. Assert the active count equals shared configuration; assert every previous marker reference and CFrame remains unchanged.
2. Assert `SealBarrier` reference/collision state and attached owner constraints survive a style swap. Assert occupied pedestal attributes survive; assert an occupied pedestal cannot be deactivated.
3. Assert inactive markers cannot be queried or collided with, and active pedestal tops equal `3.4 + (floor-1)*22` in base-local coordinates.
4. Assert each stair has one collision ramp, width 18, rotation 26.565°, top landing matching the destination walking surface, and no coincident visible floor planes.
5. Walk an actual avatar and carry the largest current Curse up both stairs, through the gate and around the landing turns. Check the view at low camera angles for seam flicker, and check pose bounds against floors/rails/roof.

This subtask did not access Studio or claim visual/Play verification. Root coordinates and records the integrated checks.

## Facade correction after native review

The native `crypt-level10-before-facade.png` showed two unarticulated, full-height frontal wall panels. The decorative revision keeps those structural colliders exactly intact and builds shallow facade ornament outside them.

- From level 1, the entrance wings gain dark plinth bands and tiered buttresses. Levels 1/2 retain the open court; no full-height decorative wall is introduced early.
- From level 3, every built floor has two pointed lancet windows on each wing, framed by the authored `final_gothic_window`. Its original source already contains a sill, transom and curved tracery. A lower pane, curved upper pane and dark central mullion make the openings readable against the structural wall. Upper floors also gain a wider central lancet above the actual entrance, joining the visual composition of the wings.
- Floor cornices break the wall height into recognizable stories. The existing partial rear canopy keeps its size, slope and collision and receives a narrow decorative front eave. The original level 9 consecrated cornice remains.
- CRYPT adds circular iron seals with sculpted skulls, eye sockets and jaws; these replace the blank `AncestorPlaque` rectangles. Candle flames and real lantern housings complete the entrance without adding lights.
- FOREST uses wooden mouldings, branching trunks and leaves in the wall bays between windows. The existing grounded guardian roots and timber entrance crown remain; the final crest shows a living tree carved on a wooden seal.
- OBSERVATORY uses dark glazing, brass orbital discs and crossed astral rays in the wall bays. Its final crest is an orbital star medallion.
- `DomainCrest` is a decorative Model containing a recognizable style emblem, replacing the former square Part. `AncestorPlaque_-1/1` are also decorative Models. These names are not gameplay markers or Curse/VFX attachment names.
- The level 6 protective sign is now a circular seal with two raised ward strokes. It remains presentation only; the permanent `SealBarrier` retains the real access rules.

Existing asset templates reused without import or new IDs:

| Template | Existing mesh ID | Purpose |
| --- | --- | --- |
| `final_gothic_window` | `rbxassetid://111779363059681` | Window frame, sill and tracery |
| `final_buttress` | `rbxassetid://121418058164290` | Shallow tiered facade buttresses |
| `final_lantern` | `rbxassetid://126649242262975` | Housing around the existing entrance light |

These IDs were read from `default.project.json`; no mesh asset was uploaded or reimported. Asset placement uses `collision="none"` and `castShadow=false`; all newly generated ornament is `CanCollide=false`, `CanQuery=false`, `CanTouch=false`, and marked `RestorationArchitecture=true`. Existing two entry lights remain the only lights per base. If an existing template is unavailable, windows/buttresses use bounded native decorative fallbacks rather than adding an unverified asset ID.

The shallow facade layers stay inside local X `-52..52`, Z `-36..68`, chiefly Z `-35.84..-34.72`; their separate depths avoid coincident planar faces. No new ornament enters the collection banks, stairs, gate opening, altar, recovery bays or walking floor volume. Stable markers, capacities, structural dimensions, ownership, animation/VFX anchors and server logic are unchanged. The existing FOREST/OBSERVATORY entry beams now also have query disabled as decorative geometry.

Static source and geometric bounds were reviewed here. Native comparison screenshots, all-style collision invariance and the affected load/performance measurements are coordinated by root and must supply the final visual approval; this subtask does not claim them executed.
