# Original Steal A Curse foliage expansion

Three shared, solid curved-blade clumps complement the existing original tree
trunks. These are asymmetric leaf silhouettes, not alpha billboards, duplicated
spheres or downloaded assets. Each is one closed, centered, single-material mesh.

| Template | Triangles | Roblox target size X/Y/Z |
| --- | ---: | --- |
| `foliage_crescent` | 504 | 16 / 6 / 10 |
| `foliage_tattered` | 672 | 14 / 7 / 12 |
| `foliage_swept` | 392 | 15 / 8 / 9 |

The kit has 1,568 unique triangles. The manifest records import status and must
receive only IDs read from the actual Studio import. `null` means not imported,
not a placeholder ID. The FBXs live in `assets/export/meshes/foliage_expansion`.

Regenerate and validate using the installed Blender executable:

```powershell
& 'D:\blender.exe' -b --factory-startup --python assets/source/blender/foliage_expansion/generate_foliage.py
& 'D:\blender.exe' -b --factory-startup --python assets/source/blender/foliage_expansion/validate_foliage.py
```

The validator reimports each FBX and checks exactly one matching mesh, centered
bounds, export scale, manifold edges, nondegenerate faces, triangle counts and
one material. Blender Z becomes Roblox Y through the established `.01` FBX
export convention. Prior Blender sources and FBXs are not changed.

`Decorations.foliage` uses branch-specific rotations, offsets and three clump
shapes in haunted, autumn and sparse families. Bare, broken and rooted-stump
families preserve negative space; giant background silhouettes retain the prior
authored tree. Leaves have no collision/query/touch. Only low trunk hulls block
the character, keeping the camera and chase routes clear.

The preview is rendered from actual Blender geometry. It confirms silhouette,
not in-game art approval or phone performance. Final Studio review is separate.
