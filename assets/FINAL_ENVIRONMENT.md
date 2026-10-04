# Final haunted-world modular mesh kit

The twelve meshes in this kit are original Steal A Curse assets generated in
Blender 5.2.2 LTS. They extend the existing environment kit without replacing its
source, exports, verified templates, or the six Curse models. No third-party
models, Toolbox assets, downloaded meshes, borrowed textures, or invented IDs are
used.

## Source and exports

- [Editable Blender source](source/blender/steal_a_curse_final_environment.blend)
- [Reproducible generator](source/blender/generate_final_environment.py)
- [FBX round-trip validator](source/blender/validate_final_environment.py)
- [Geometry and import manifest](source/blender/final_environment_manifest.json)
- [Actual-geometry contact sheet](source/blender/final_environment_preview.png)
- [Local authoring geometry JSON](source/blender/final_environment_geometry.json)
- Game-ready single-mesh FBXs: `export/meshes/final_*.fbx`

The `.blend` contains one named collection per module. Each module is centered at
its own bounding-box origin with zero location and rotation and unit object
scale. The doorway collection is visible initially; enable another collection
in the Outliner to inspect it. Camera and contact-sheet labels are grouped under
`Preview_Only`; they are excluded from every FBX.

The geometry JSON contains the same centered, triangulated authoring vertices
and faces as the FBX exports. It is a local inspection/preview aid, not an
uploaded Roblox asset and not a substitute for a real MeshId.

## Dimensions and triangle budget

Bounds below are the expected Roblox `Size` in studs, ordered **X width,
Y height, Z depth**. The manifest also records the Blender X/Y/Z dimensions.
All modules use one simple preview material; runtime placement chooses the
Roblox color and material.

| Mesh / FBX basename | Triangles | Roblox bounds X × Y × Z | Intended role | Verified MeshId |
| --- | ---: | --- | --- | --- |
| `final_gothic_doorway` | 112 | 20 × 25 × 3 | Open pointed manor doorway | `rbxassetid://93984507446049` |
| `final_gothic_window` | 128 | 6 × 13 × 1 | Hollow lancet frame and tracery | `rbxassetid://111779363059681` |
| `final_crooked_roof` | 34 | 28 × 18 × 26 | Steep canted roof and finial | `rbxassetid://88083283938508` |
| `final_buttress` | 68 | 4 × 18 × 7 | Projecting stone support | `rbxassetid://121418058164290` |
| `final_collection_pedestal` | 172 | 6 × 2.5 × 6 | Octagonal Curse display dais | `rbxassetid://136578707816851` |
| `final_iron_fence` | 244 | 12 × 7 × 1 | Open pointed cemetery railing | `rbxassetid://125211551490808` |
| `final_pumpkin` | 246 | 3.5 × 3 × 3.5 | Ribbed pumpkin with bent stem | `rbxassetid://85694347830310` |
| `final_giant_tree` | 464 | 40 × 52 × 30 | Twisted branching landmark tree | `rbxassetid://106911067618583` |
| `final_cliff_cluster` | 152 | 38 × 15 × 25 | Layered faceted embankment | `rbxassetid://102007331454332` |
| `final_hero_grave` | 120 | 7 × 11 × 3 | Pointed ward memorial | `rbxassetid://114437295252890` |
| `final_lantern` | 248 | 3 × 5 × 3 | Open hexagonal cage | `rbxassetid://126649242262975` |
| `final_chain` | 480 | 2 × 10 × 1.5 | Six alternating oversized links | `rbxassetid://137302239107896` |

**Total: 12 unique meshes, 2,468 unique triangles before repeated instances.**
This is a geometry budget, not a measurement of complete map draw cost.

The doorway is an open U-shaped shell with no bottom crossbar. At authored size
its central opening is 13.2 studs wide up to 15.1 studs high, narrowing to a
21.3-stud pointed apex. The window, iron fence, lantern cage, and chain have
actual openings. Place native glowing panes/flames behind or inside their
frames as needed. The tree and cliff cluster remain decoration; use simple
native geometry for gameplay collision where necessary.

## Scale and placement

Authoring geometry uses stud-sized Blender units, Z up. The generator follows
the established project FBX settings: `global_scale=0.01`, unit-scale export,
mesh objects only, no leaf bones, no baked space transform. Blender Z becomes
Roblox Y at import; Blender depth becomes Roblox Z.

The validator's Blender FBX reimport sees world bounds at **0.01 × authored
dimensions**. This is expected for this established export pipeline. Studio's
imported MeshPart must separately be inspected; do not infer its real MeshId or
`InitialSize` from the authored mesh.

Center placement at `CFrame` is the center of the whole mesh bounds. For an
upright asset resting on a surface, use the surface height plus half of its
final Y height. `AssetKit.place` clones verified MeshPart templates and sets
their final requested `Size`, color, material, and anchored decorative state.

Keep template `InitialSize` and `Size` equal to the **actual imported Roblox
dimensions** in `default.project.json`. A MeshId-only template can render at an
incorrect scale even if the placement code sets `Size` later.

## Reproduce and validate locally

Run from the repository root in PowerShell using the installed Blender path:

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' -b --factory-startup --python assets/source/blender/generate_final_environment.py
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' -b --factory-startup --python assets/source/blender/validate_final_environment.py
```

The generator writes the `.blend`, twelve FBXs, contact sheet, manifest, and
geometry JSON. It does not upload or publish assets. Regeneration resets the
generated manifest's import fields to pending; preserve or restore verified
import metadata when regenerating an already imported kit.

The validator imports each FBX into a fresh Blender scene and checks:

- Exactly one correctly named mesh per export.
- Closed manifold shells and no degenerate triangle faces.
- Bounding-box center at the origin.
- Expected established FBX scale and dimensions.
- Manifest-matching triangle counts and one material per mesh.
- Aggregate geometry budget below 8,000 triangles.

The twelve exports passed these checks. The contact sheet was rendered from
their actual Blender geometry and visually inspected. This validates source
geometry and export conventions; Studio import and final Play validation are
separate checks.

## Roblox import status

All twelve original FBXs completed the project's established Studio 3D Importer
workflow. Their real `MeshId`, `InitialSize`, and `Size` were read from the
actual imported MeshParts and recorded in the
[manifest](source/blender/final_environment_manifest.json). All entries are
`verified_actual_studio_import`; their verified templates are mapped under
`ServerStorage.MapMeshKit` in `default.project.json`.

The bounds table rounds tiny import floating-point differences for readability;
the manifest and Rojo templates retain the exact imported dimensions. Importing
these original mesh assets did not publish the Roblox place. Place changes
remain local for review. Final scene appearance, gameplay movement, and
performance still depend on the complete map and its Play validation.
