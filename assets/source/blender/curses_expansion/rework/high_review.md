# High rarity Curse rework — local authoring review

21 actual editable Blender sources and individually exported meshes follow current reference sheets 07–12. The final geometry uses distinct object identities, closed shells and authored material-specific vertex paint with normalized UVs. All models remain below the existing seven-stud diagonal contract.

Local evidence: **74,792 total triangles**, maximum diagonal **6.386 studs**. All21 individual FBX roundtrips pass. Combined HIGH21 import FBX also passes exact individual color-set, UV, scale, origin and topology comparisons.

Frozen batch SHA256: `d861310d893abc1b26d37ca576a6bccc2f07cd28280b5b06b27c25eec00b18f7`

## Review artifacts

- Front and rear sheets: `high_legendary_preview_sheet.png`, `high_legendary_rear_sheet.png`, equivalent Mythic/Secret sheets.
- Four-angle geometry rotations: `high_night_harp_turnaround.png`, `high_worldroot_turnaround.png`, `high_the_last_star_turnaround.png`.
- Exact source paths, component hashes, palette roles, centered native VFX hooks and design notes: `high_geometry.json` and `high_local_review.json`.
- Actual FBX evidence: `high_validation.json` and `high_import_batch_validation.json`.
- Rerunnable authoring: `high_generate.py`; shared primitive/FBX helper: `rework_geometry.py`.
- Actual component batch builder: `high_import_batch.py`. It imports the frozen individual FBXs, restores100× authored scale, exports distinct names at0.01 and reimports the batch. It never joins components or rewrites individual FBXs.

## Reference corrections accepted during review

- The Last Funeral is a horizontal long coffin on four tall curved strap legs, with real wrap bands and raised ivory memorial lilies.
- Blood Moon Rose has21 closed curved petals in three overlapping cupped rings, dark garnet surfaces and a small restrained core.
- Crown of Silence has a broad pale cloth robe, ten physical circumferential folds, six wide sleeve folds, an open collar and four separate floating crown fragments.
- The Unwritten has a coat of folded black pages, curved page shoulders/sleeves and an irregular torn faceless parchment head.

## Integration scope

This review verifies local authoring and FBX exports. The parent task records real Roblox import IDs, checks actual Studio appearance, native VFX and production gameplay before enabling any new Curse. The six originals, economy and gameplay code were not edited by this authoring agent.

## Per-Curse geometry

| Curse | Rarity | Triangles | Roblox width × height × depth | Native VFX hook profile |
|---|---|---:|---|---|
| Blood Moon Rose | Legendary | 5,166 | 3.37 × 3.65 × 1.39 | `rose_pulse` |
| Clockwork Raven | Legendary | 3,880 | 3.88 × 3.61 × 1.60 | `raven_clock` |
| Eclipse Stag | Legendary | 1,882 | 3.06 × 4.05 × 1.19 | `eclipse_antlers` |
| Endless Library | Legendary | 4,812 | 2.78 × 3.02 × 1.11 | `library_pages` |
| Judgement Scales | Legendary | 2,112 | 3.57 × 3.62 × 1.11 | `unequal_scales` |
| Night Harp | Legendary | 2,492 | 2.82 × 3.88 × 1.40 | `harp_strings` |
| Phantom Marionette | Legendary | 1,964 | 3.01 × 3.83 × 0.86 | `puppet_strings` |
| Silent Choir | Legendary | 2,680 | 3.11 × 3.37 × 0.93 | `silent_choir_chimes` |
| Sunken Crown | Legendary | 3,408 | 2.48 × 3.08 × 2.26 | `sunken_tides` |
| Thorn Cathedral | Legendary | 3,064 | 2.77 × 4.06 × 1.98 | `rose_window` |
| Cathedral Heart | Mythic | 3,618 | 2.94 × 4.48 × 1.67 | `cathedral_heart_seam` |
| Hollow Throne | Mythic | 2,416 | 2.67 × 4.38 × 1.88 | `hollow_throne_presence` |
| Plague Monarch | Mythic | 2,828 | 2.53 × 3.90 × 1.55 | `plague_monarch_breath` |
| The Last Funeral | Mythic | 3,030 | 3.68 × 3.13 × 2.00 | `last_funeral_lilies` |
| The Undertow | Mythic | 2,498 | 3.59 × 3.18 × 1.58 | `undertow_spiral` |
| Worldroot | Mythic | 3,456 | 3.24 × 4.19 × 1.56 | `worldroot_seed` |
| Crown of Silence | Secret | 7,204 | 3.14 × 4.18 × 1.54 | `crown_silence` |
| Nameless Door | Secret | 3,232 | 3.26 × 3.76 × 2.26 | `nameless_threshold` |
| The First Grave | Secret | 2,136 | 3.06 × 3.69 × 0.93 | `first_grave_crack` |
| The Last Star | Secret | 4,792 | 3.88 × 4.62 × 2.09 | `last_star_cage` |
| The Unwritten | Secret | 8,122 | 3.34 × 4.08 × 1.43 | `unwritten_erasure` |
