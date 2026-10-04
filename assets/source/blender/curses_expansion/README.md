# Curse expansion: original first wave

The references contain **50 distinct labeled concepts**, not just the 47 in
the written rarity lists. Sheet10 also contains **Worldroot, The Undertow and
The Last Funeral**, retained as planned Mythics. Sheet13 repeats sheet5 and
does not add duplicates. The complete manifest is
[curse_expansion_manifest.json](curse_expansion_manifest.json).

The old six Curses, their source `.blend`, exported FBXs, IDs, prices, income,
spawn weights and active order are preserved. The shared catalog has 56
display definitions, an unchanged six-entry `Order`, `AllOrder`,
`ExpansionOrder`, `FirstWaveOrder`, and `enabledSpawnIds()`. Expansion data is
centralized; it does not add scripts per Curse or any debuff/gameplay system.

## First wave

| Curse | Rarity | Triangles | Intended Roblox bounds X,Y,Z (studs) |
| --- | --- | ---: | --- |
| Candle Wisp | Common | 758 | 2.070, 3.005, 1.613 |
| Grave Hopper | Common | 640 | 2.343, 2.560, 1.287 |
| Grave Key | Common | 470 | 1.698, 2.810, 0.470 |
| Ink Imp | Common | 586 | 2.282, 2.150, 0.856 |
| Ashen Book | Common | 608 | 1.935, 1.658, 1.327 |
| Marrow Dice | Rare | 880 | 2.325, 2.373, 1.176 |
| Grave Compass | Rare | 1116 | 2.760, 2.419, 1.600 |
| Hollow Violin | Rare | 594 | 1.540, 2.937, 0.525 |
| Raven Quill | Rare | 358 | 1.715, 2.842, 0.488 |
| Night Harp | Legendary | 520 | 2.509, 4.023, 0.591 |
| Thorn Cathedral | Legendary | 700 | 2.500, 4.109, 1.542 |
| Judgement Scales | Legendary | 730 | 3.660, 3.448, 1.000 |
| Cathedral Heart | Mythic | 818 | 2.625, 4.018, 1.350 |
| Hollow Throne | Mythic | 418 | 2.337, 3.983, 1.390 |
| Nameless Door | Secret | 768 | 2.849, 4.080, 1.105 |

Total: **9,964 unique source triangles**, not the runtime instance/render cost.
All 15 contain exactly one closed root mesh with applied geometry, one UV
layer, one material and one per-corner painted color layer. The local FBX
round trip preserved actual triangle/vertex counts, centered finite bounds,
the established 0.01 export scale and 112–304 quantized original colors per
mesh. All reported non-manifold, loose-vertex and degenerate-face counts are
zero. See [first_wave_geometry.json](first_wave_geometry.json) and
[first_wave_validation.json](first_wave_validation.json).

The forms are original optimized interpretations, not traced render cards,
downloaded models, high-poly sculpts, or reused silhouettes with renamed
labels. Closed curved ribbons, faceted volumes, beveled cuboids and modeled
negative space are used deliberately. Nameless Door has real open nested
frames, not an opaque black plane.

## Reproduction

Blender installed on the authoring host: `D:/blender.exe`, version 5.2.2 LTS.

```powershell
& 'D:/blender.exe' -b --factory-startup --python 'assets/source/blender/curses_expansion/generate_expansion.py'
& 'D:/blender.exe' -b --factory-startup --python 'assets/source/blender/curses_expansion/validate_expansion.py'
& 'D:/blender.exe' -b --factory-startup --python 'assets/source/blender/curses_expansion/write_manifest.py'
```

The editable source is `steal_a_curse_expansion_wave1.blend`. Named mesh
objects are arranged in a source-only gallery. Cameras/lights are preview
objects and do not enter the FBX. FBX outputs are in
`assets/export/meshes/curses/`. The source geometry helpers import the existing
`generate_curses.py` module without running its generator or changing it.
To refresh the preview without touching exported/uploaded FBXs:

```powershell
& 'D:/blender.exe' -b --factory-startup --python 'assets/source/blender/curses_expansion/generate_expansion.py' -- --preview-only
```

## Color and import contracts

Original material colors use broad per-corner gradients stored in
`SACPaintedColor`, exported as sRGB FBX vertex colors. This is supported by
[Studio's Importer](https://create.roblox.com/docs/studio/importer), but the
actual Roblox result must be visually reviewed. No raster textures or
TextureIds are necessary in this Curse pipeline. Native white tint preserves
the imported vertex colors; the old six keep their original native tint.
Do not assume successful local Blender validation proves successful upload,
color preservation, moderation, scale, or gameplay in Roblox.

Real imported `MeshId`, `MeshSize` and `Size` must be recorded from Studio.
`InitialSize` is Rojo's serialized field, not a public runtime member; populate
it with the observed `MeshSize`. Keep serialized `InitialSize` and `Size` equal
to those actual imported bounds; Blender Z becomes Roblox Y. Every root stays
below the existing seven-stud diagonal
clearance contract. The visual service rejects new entries until their
implementation status is `IMPORTED` or `VALIDATED` and their template scale
is consistent. A root `Attachment` named `CurseVFXHook` carries the authored
profile and one small static neon glint. Expansion adds no particle emitters,
PointLights, or separate constant update loops.

## Staged release

On **2026-10-01**, all 15 first-wave FBXs were imported through Studio. Their
actual MeshIds, MeshSize and Size were read directly from Studio Output at
20:48:51.684 and recorded in
[`assets/imports/world_expansion_2026-10-01.json`](../../../imports/world_expansion_2026-10-01.json).
The production `CurseMeshKit` now contains these 15 real templates, with
`InitialSize` and `Size` matching the observed bounds. The complete manifest
records each real ID and import evidence; the shared catalog marks the wave
`IMPORTED`. No TextureIds were required or fabricated.

**Import is not gameplay validation.** All 15 remain `enabled=false` and
`spawnWeight=0` until the separate final Play review. The six original live
entries retain their original IDs, bounds, development values and order.
Actual in-game color/appearance, labels, motion, purchase, delivery and income
still require Play review and are not marked as verified by the import record.

- `PLANNED`: data/concept only; 35 unmodeled concepts remain.
- `EXPORTED`: `.blend`/FBX/local validation exist; no upload is claimed.
- `IMPORTED`: real Studio identity/bounds recorded; still disabled by default.
- `VALIDATED`: actual imported appearance and gameplay reviewed; enablement
  remains a separate explicit decision.

New definitions start with `enabled=false` and `spawnWeight=0`. Importing does
not automatically enable random spawning. Existing six continue to be the
active production-development pool. Prices/income for all planned entries
are centralized development values, not final balance or real monetization.
The manifest generator preserves recorded import evidence only when the
FBX hash matches; re-exporting a changed mesh requires renewed import review.
No IDs are fabricated by the generator or validator.
