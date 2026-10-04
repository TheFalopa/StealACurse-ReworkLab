# Steal A Curse

Rojo project for a playable, session-only Roblox vertical slice. Build with
`rojo build default.project.json --output build-vertical-slice.rbxlx`, open the
place in Roblox Studio, and press **Play**. The server creates
`Workspace.StealACurseMap` at runtime; the map is not visible in Edit mode.
Use `rojo serve` if you want to sync further source changes into Studio.

## Final haunted environment

The earlier rework WIP established the Hollow Crown manor, eight separated
sanctuary territories, raised family graveyards, crooked forests and ruins.
That historical pass expanded its playable boundary to approximately 1.56
times the prior area and measured sanctuary/castle runs around 16 seconds,
with twelve additional original Blender modules imported through Studio.
Those figures describe the earlier WIP, not the current world-expansion
footprint or travel results; the previous asset kit remains preserved.

Build the review place with
`rojo build default.project.json --output build-final-rework.rbxlx`.
See [the full rework report](docs/FINAL_MAP_REWORK.md) for screenshots, measured
walks, mesh IDs, validation evidence and remaining device review.
Studio-only validators under `tests/` are excluded from the production project.

The second quality pass preserves this layout and gameplay, adding grounded
placement, simple collision hulls, painted surface treatments, Halloween
clusters and a modular right-side HUD. SHOP is a future-concept preview only:
its preview cards have no purchase APIs, product IDs or rewards. See
[Final Map Polish V2](docs/FINAL_MAP_POLISH_V2.md) for the complete change list,
Studio checks, screenshots and known limitations.

The world expansion provides 820×800 ground support, eight sanctuary territories,
a shared 16-point castle route and three original foliage exports. SHOP has ten
previews across three tabs. The earlier [World Expansion](docs/WORLD_EXPANSION.md)
report preserves that pass's implementation and observations.

## Completed 50-Curse visual expansion

All 50 new Curses have current-reference Blender models, validated FBXs, fresh
Studio imports, reviewed authored vertex colors and concept-specific client VFX.
They are enabled alongside the six preserved originals: **56 playable Curses**.
Actual Studio tests cover all fifty route exits, purchases, following, delivery,
pedestals, labels and Souls production, plus desktop/mobile-emulated VFX budgets
with forty presentation displays and six real offers. The castle grounds,
cemetery and forest received bounded decoration and grounding improvements.

Open `build-curse-expansion-50.rbxlx` in Studio and press **Play**, or rebuild it
with `rojo build default.project.json --output build-curse-expansion-50.rbxlx`.
The production place contains no review gallery or test scripts. The
[complete local report](docs/CURSE_EXPANSION_50_REWORK.md) links all fifty sources,
actual mesh IDs and sizes, independent progress stages, screenshots and test
evidence. Physical-device performance remains separate from Studio emulation.

## Current loop

Claim one of eight sanctuaries with its ProximityPrompt. Each player begins
with 500 Souls. The central mausoleum releases a weighted Curse about every
10 seconds along a visible, fixed spectral route (maximum six unsold Curses
at a time). Inspect its name, rarity, price, and Souls/s, then buy it using
its ProximityPrompt. The Curse floats with its purchaser until they enter
their own sanctuary's display area. It occupies the first of five free
pedestals and begins producing Souls. The HUD shows balance and total Souls/s.

The server owns claims, purchase prices, balance, state transitions, delivery,
slot occupancy, and income. An undelivered purchase is fully refunded on
death/reset or disconnect. Placed Curses disappear when their owner leaves.
All state resets with the server: there is no DataStore, stealing, Curse
debuffs, mutation, or monetization yet. Set the experience's **MaxPlayers to
8** in Roblox settings; Rojo cannot set that experience-level setting.

## Source layout

- `src/server/Map/`: existing runtime-generated cemetery, mausoleum, and
  sanctuary art. Its markers are consumed only after `MapBuilder.build()`.
- `src/server/Gameplay/`: claim, economy, procession, Curse state, and visual
  services. Test tuning lives in `Gameplay/Config.luau`.
- `src/shared/CurseCatalog.luau`: six existing definitions and 50 expansion
  concepts, prices, income, rarity presentation, rollout states, weights and
  reserved future effect identifiers. Pending models cannot spawn.
- `src/shared/NumberFormat.luau`: reusable compact numeric formatting.
- `src/client/UI/HUD.luau`: attribute-driven Souls HUD and feedback.
- `default.project.json`: Rojo mapping and verified, imported MeshPart
  templates under `ServerStorage.MapMeshKit` and `ServerStorage.CurseMeshKit`.
- `assets/`: original editable Blender source and FBX exports; see
  `assets/README.md` for mesh details and Roblox asset IDs.

The place itself has not been published by this workflow. To reproduce the
local checks, run `rojo build default.project.json`,
`rojo sourcemap default.project.json`, and `git diff --check`, then inspect
the generated place in Studio Play. Multiplayer and phone-sized testing are
separate Studio validation steps before publishing.
