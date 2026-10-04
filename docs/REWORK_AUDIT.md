# Full-game rework — audit (2026-10-04)

Branch `claude/full-game-rework` from the tested integration checkpoint
`0d7e0e3` (tag `checkpoint/integration-stable`). Audited by reading the code and
playing `build-rework.rbxlx` in Studio (single client).

## KEEP
- Server-authoritative tool backend (`ToolService`, `ToolInventory`, persistence,
  rate limit, cooldowns, LOS checks, sealed-sanctuary protection).
- Central movement math (`ToolEffectsMath.speed`) and `ToolStatusService`
  (one place computes WalkSpeed from all effects; control immunity window).
- Theft ledger / ownership transfer, Curse carry, sanctuary levels 0–10,
  contracts → seal fragments, rituals, Red Moon, Souls HUD, hero VFX.
- Economy scale: Commons ~80–100 Souls / 2–3 per s, Secrets ~50K / 750 per s;
  sanctuary upgrades 150 → 220K Souls.

## IMPROVE
- Gravekeeper Shovel only pushes (impulse 18). Needs wind-up, swing, a real
  ~1 s ragdoll and readable recovery.
- Tool effects use flat cylinders/parts; reuse the VFX kit textures.
- Tool models are basic welded blocks; silhouettes can be much stronger.
- Mist Censer has no gameplay effect beyond visuals (only the Lantern reads it).

## REWORK
- Tool UI (`ToolsInput`): text-only slots, a separate "HERRAMIENTAS · H"
  button, a spreadsheet-style 650×430 panel, a floating USAR button, no icons,
  no cooldown fill. Slots overlap the panel. Replace with quick slots + a bench
  panel in the shared UI style.
- Mission giver: the "Sepulturero" is a small board prop, not a character.
  Contracts UI is a text tab inside the sanctuary panel.
- Sanctuary panel: text-only tabs, no progress bars or reward icons.
- Language is mixed (HUD English, gameplay Spanish). New player-facing UI and
  tool names move to English; Spanish server messages are translated as their
  systems are touched.

## REMOVE / REPLACE
- Nothing deleted yet. "ShellPanel" is unused by the HUD.

## Not present (new work)
- Ragdoll, tool animations, Luck, mutations, Daily Wheel, cinematics,
  mission NPC character, onboarding missions.

## Phase 4 finding — Curse materials (blocked, not shipped)
A shared PBR atlas (SurfaceAppearance) was generated and A/B tested in Play
on Judgement Scales, Cathedral Heart and Grave Key. Rejected:
- SurfaceAppearance replaces the authored vertex colours entirely, so the
  painted gradients that give these meshes their look are lost.
- The live MeshIds come from several exporters (historical builder 4×4 tiles,
  rework 7×7 tiles, high/rare batches, rigged animation re-exports); the UV
  tile a face uses is not the same across them, so one atlas mis-colours parts.
Correct path: re-export the priority Curses from Blender with one documented
atlas layout and bake the vertex colour into ColorMap. Blender is not
installed on this machine; deferred.

## Collision census (visible parts > 40 stud³)
734 total, 514 non-collidable. Large categories: leaf clumps and distant
world (fine), but also railings, buttresses, memorials, statues, ruins and
gothic frames that should block. 333 invisible collision hulls already exist;
coverage must be checked per object (phase 3).

## Systems added in the rework (contracts for the gameplay side)

**Progression** (`ProgressionService`, `ProgressionConfig`, folder `ReplicatedStorage.Progression`)
- `Request:InvokeServer(action, value)`: `state`, `accept`, `claim` (`"event"` for the Red Moon task), `drink` (`"luck_potion"`), `spin`, `seen`. The NPC and Wheel actions check distance (14 / 16 studs) and are rate limited to 0.25 s.
- `Changed` (state snapshot) and `Cinematic` (id) remote events. The tracker reads player attributes `MissionTitle/Objective/Progress/Target/State`.
- Profile fields: `items`, `missions {index, accepted, eventClaimed}`, `wheel {lastFreeDay, bonusSpins}`, `seen`. They are migrated on load.
- Mission progress is derived from existing state (placed Curses, Souls/s, sanctuary level, species, rarity), so nothing is counted twice. Claims are idempotent.

**Luck** (`LuckService`): the only Luck multiplier. Potions (+1.0 for 5 min, stacking to 30 min) plus Red Moon (+0.5), capped at x3. It feeds the rarity-tier procession weights (`SpawnRarityShare`); COMMON is unaffected. It is published as `ReplicatedStorage.ServerLuck`/`ServerLuckEndsAt` and on the player as `LuckPotionEndsAt`. `Config.ProcessionSelection = "cycle"` keeps full-roster QA.

**Wheel of Fate**: the server picks the sector by weight. The odds shown in the panel are these same weights. One free spin per UTC day (`floor(serverTime/86400)`, resets 00:00 UTC), plus bonus spins from missions and the Wheel. Pranks are harmless and timed. Paid spins are shown as COMING SOON only: there are no product IDs and no receipt handling, and the single `ProcessReceipt` is unchanged. Enabling them needs a policy review (paid random items) and real product tests.

**Studio-only debug** (`RunService:IsStudio()` guard): set the attribute `Debug` on `ReplicatedStorage.Progression` to `reset_daily`, `spins n`, `potion n`, `mission n` or `reset_missions`. The result appears in `DebugResult`. The tool practice dummy and TRY buttons are also Studio-only.

**Client UI**
- `UI.Notify.push(text, tone)` is the single notice path. HUD renders it, together with the server's `HUDNotice`, in the `Notifications` layer (DisplayOrder 50).
- `SpawnReveal` is a client-only, rarity-scaled reveal for new procession Curses.
- The Sanctuary panel uses the shared `PanelFrame`. Its `SanctuaryRestoration` requests are unchanged.

**Language**: all player-facing text is English. Only display strings were translated; ids, remotes and saved data are unchanged.
