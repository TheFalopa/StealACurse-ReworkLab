# Original world-expansion painted textures

Original painted-style PNGs generated specifically for Steal A Curse with the
built-in image-generation tool. No third-party images, texture packs or copied
game assets were used. The broad painted gradients are generated bitmap artwork,
not a claim that these were manually hand-painted or proven seamless.

| Source | Real Studio image ID | Reusable material | Pattern / scale |
| --- | --- | --- | --- |
| hollow_stone_v1.png | rbxassetid://93394270586297 | HollowStonePainted / Slate | Regular; irregular broad stone courses, 16 studs per tile |
| twilight_wood_v1.png | rbxassetid://81623021739244 | TwilightWoodPainted / Wood | Regular; broad curved plum-brown grain, 12 studs per tile |
| dusky_soil_v1.png | rbxassetid://117271298687011 | DuskySoilPainted / Ground | Organic; violet soil, stones and sparse fallen leaves, 28 studs per tile |

These three original local PNGs were uploaded through Roblox Studio Asset Manager
on 2026-10-01, with creator `Yo`. All upload rows completed and the exact image
IDs above were observed in Studio inventory. The durable evidence is
[world_expansion_textures_2026-10-01.json](../../../imports/world_expansion_textures_2026-10-01.json).
Production `MaterialService` maps these IDs as the corresponding three variants'
`ColorMap` values. Upload and static integration do not prove appearance in Play,
seam continuity, asset availability to every account, or performance. The record
does not claim that the experience was published or that Play was validated.

Use only real Studio-imported ColorMap IDs under MaterialService. No global
material overrides, guessed asset IDs, normal maps or excessive roughness noise.
Map/Materials applies variants after the existing SurfaceArt pass; missing uploads
retain its native palette. Collision hulls, Neon, Metal, Glass and Curses are not
retextured. Map physical properties are preserved when applying a visual variant.

## Generation prompts

Stone: Square, tileable flat orthographic texture, edge-to-edge large irregular
gothic stone blocks; broad hand-painted blue-gray/violet gradients, sparse cracks,
muted moss, worn lavender edges, medium albedo, uniform neutral lighting. No scene,
cast shadows, text, runes, photorealism, tiny noise or crushed-black gaps.

Wood: Square, seamless flat texture, broad curving vertical grain in cool
plum-brown, sparse knots, hand-painted low-frequency neutral shading. No objects,
board seams, photographic surface, text or harsh specular highlights.

Ground: Square, top-down seamless texture of broad violet soil and muted
blue-green earth, a few large embedded flat stones and sparse orange leaf clusters,
smooth medium-value painted gradients. No grass blades, runes, tiny grain, scene,
directional shadows or photorealism.

Seam continuity, scale and night readability still require actual Studio visual
review; requesting a tileable image does not establish a seamless result.
