# Final static production audit — world expansion

Snapshot rerun: 2026-10-02 02:46:52 UTC (2026-10-01 in America/Montevideo).
Workspace: `C:/RobloxProjects/StealACurse`.
Branch: `feature/final-map-polish-v2`.
HEAD and comparison baseline: `6b9891d9cf7ec07ec14c4934392a2229ffa44367`.
The expansion remains uncommitted working-tree changes; this audit did not commit, push, publish, or operate Studio.
At this snapshot Git reported 26 modified tracked files, 87 untracked files, no staged files and no tracked deletions relative to the baseline. These counts include assets/evidence; they are a timestamped snapshot, not a claim that the workspace is clean.

## Commands and observed results

All commands ran from the workspace above.

```powershell
git rev-parse HEAD
# Exit 0: 6b9891d9cf7ec07ec14c4934392a2229ffa44367

git branch --show-current
# Exit 0: feature/final-map-polish-v2

rojo build default.project.json --output build-world-expansion.rbxlx
# Exit 0:
# Building project 'StealACurse'
# Built project to build-world-expansion.rbxlx

rojo sourcemap default.project.json --output build-world-expansion.sourcemap.json
# Exit 0: Created sourcemap at build-world-expansion.sourcemap.json

& 'C:/Users/patho/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/powershell/pwsh.exe' -NoProfile -File './tests/Audit-Expansion.ps1'
# Exit 0:
# EXPANSION_STATIC_PASS branch=feature/final-map-polish-v2 head=6b9891d baseline=6b9891d retainedVerifiedMeshes=30 coreServicesUnchanged=true originalSixEconomyOrderPreserved=true expansionConcepts=50 expectedTotalCatalog=56 firstWaveExports=15 sourceTriangles=9964 noPurchaseIntegration=true fixturesExcluded=true
# Executable ProductVersion: PowerShell 7.6.5.

git diff --check
# Exit 0; no whitespace errors.

git diff --name-only 6b9891d -- src/server/Gameplay/BaseService.luau src/server/Gameplay/CurseService.luau src/server/Gameplay/SoulsService.luau
# Exit 0; empty output.

git diff --name-only 6b9891d -- assets/export/meshes assets/source/blender
# Exit 0; empty output for previously tracked authoring/export files.

git diff --cached --name-status
# Exit 0; empty output (nothing staged).

git diff --name-status --diff-filter=D 6b9891d --
# Exit 0; empty output (no tracked deletions).

git check-ignore -- build-world-expansion.rbxlx build-world-expansion.sourcemap.json
# Exit 0:
# build-world-expansion.rbxlx
# build-world-expansion.sourcemap.json
```

Git emitted existing LF-to-CRLF normalization warnings, not build/audit failures.
New untracked expansion assets are separately verified by the manifest/FBX checks; empty tracked-file diffs do not claim those new files are absent.

## Independent preservation and integration comparison

Baseline JSON was read with `git show 6b9891d:default.project.json`, and the current project with `Get-Content -LiteralPath default.project.json -Raw`. Every old template node was compared in full after JSON parsing, including its complete properties, not only its MeshId. The six original definition bodies were independently compared against `git show 6b9891d:src/shared/CurseCatalog.luau` (line-ending normalization only).

```json
{
  "baseline": "6b9891d9cf7ec07ec14c4934392a2229ffa44367",
  "oldFullMeshTemplatesPreserved": 30,
  "oldCompleteCurseDefinitionsPreserved": 6,
  "importedMeshEvidenceMatches": 18,
  "materialVariantEvidenceMatches": 3,
  "newImported": 15,
  "newPlanned": 35,
  "newVerifiedImports": 15,
  "newDisabled": 50,
  "allNewDisabled": true,
  "originalTrackedBlenderAndExportFilesUnchanged": true,
  "threeCoreServicesUnchanged": true
}
```

The 18 new mesh templates match every real MeshId, Size and MeshSize recorded in `assets/imports/world_expansion_2026-10-01.json`. Rojo's serialized `InitialSize` equals the observed runtime `MeshSize`; `Size` equals the same bounds. The three MaterialVariants match the real ColorMap IDs, base materials, tile scales and patterns recorded in `assets/imports/world_expansion_textures_2026-10-01.json`.

The old six catalog entries, their active order and development economy remain unchanged. The full UI catalog contains 56 entries: six originals plus 50 distinct new concepts. All 50 new entries remain disabled with spawn weight zero: 15 IMPORTED and 35 PLANNED. Actual import evidence is not automatically gameplay enablement or appearance validation.

Core services were independently compared using the baseline Git blob and the working file's filtered Git hash (not just the audit script's diff list):

| Core service | Unchanged Git blob |
| --- | --- |
| `BaseService.luau` | `888a024bc665adcca1e59803d81a167e5f902d35` |
| `CurseService.luau` | `7010550c0d500af2fc3f1c55a0aa4dc5f55c36d8` |
| `SoulsService.luau` | `2aa5ed6d5b278f0d040726add77408fdc3fdfd1e` |

The production project contains no fixture/test mapping. The source scan contains no real purchase API/product IDs or test validator/control names. The 15 FBX exports' SHA-256 hashes match the durable manifest; first-wave topology/UV records pass the scripted contract with 9,964 source triangles in total. This is validation of saved source records/exports, not a new Blender or Studio session.

## Artifact and source hashes

| Artifact | SHA-256 |
| --- | --- |
| `build-world-expansion.rbxlx` (ignored) | `332051679819EE9222684887753C6884C86D0185EF1F39A3CD009D87C22EA0D7` |
| `build-world-expansion.sourcemap.json` (ignored) | `9F6D09842901A557972502E9FC5D02F67680C93F0DFCEE892EE509BC67E476C9` |
| `default.project.json` | `A93F3E822097218BF72F9555C41931045F55D0FE69EDA81D287653CBFDFF4593` |
| `src/shared/CurseCatalog.luau` | `8780BFB08DEBFB83AE47CBEBB2BD929A58282952BFD5FE15DD8BC9F208541F24` |
| `assets/imports/world_expansion_2026-10-01.json` | `1B5517083B93B434FD5FA4ABBAFB11CD6A8F1108404E0BD99B148C7C9B5E661D` |
| `assets/imports/world_expansion_textures_2026-10-01.json` | `9BEEB1A0A998E9444C53019E79A9D40C095456BF4A2F9BCE57C515101AA81D9C` |
| `assets/source/blender/curses_expansion/curse_expansion_manifest.json` | `721158DD921B2E83A9174BDC2FD9F2DC5A50EABAA3619DEDD5194850944231D8` |
| `assets/source/blender/curses_expansion/first_wave_validation.json` | `B005A71908110CC01EEF214FCA534C616B9F7EC9A6BF7DB7A973D047E1845734` |
| `assets/source/blender/curses_expansion/first_wave_geometry.json` | `04B68CFD857B5DA40B084FD8669112D867D5ABF91121452CAD72CE44F2B90728` |
| `src/client/UI/ShopPanel.luau` | `DF96652C40394444F75AD7B3F4D83CB4886C196D4282DDB9848A286CC73503C7` |
| `src/client/UI/ShopCard.luau` | `6F621F64E6C564C630B2FED947426D76A11356A128467232C1CFA3124FF78EC7` |

## Limits

This is a production build/source audit, not an engine Play test. Rojo success does not establish Luau runtime behavior, moderation/asset access, visual seam continuity, authored vertex-color preservation, physical traversal, responsive input or real-device FPS. WORLD/EXPANSION Play observations and gallery captures are separate evidence owned by the Studio review. This record neither declares those checks pending nor passes them; it does not claim any disabled expansion Curse naturally spawned, was purchased, delivered or generated income. Test gallery/camera/helpers are excluded from the production mapping. The import evidence files' `playValidated: false` fields are import-time metadata, not a substitute for later runtime evidence.

Only this Markdown evidence file was edited by this audit; the requested ignored build/sourcemap artifacts were regenerated. No source code, UI, Git staging, commit, push or Studio state was changed.
