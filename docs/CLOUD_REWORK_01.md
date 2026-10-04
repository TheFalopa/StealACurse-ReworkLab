# Cloud rework 01: direction, plan and status

Branch `claude/cloud-rework-01` in `TheFalopa/StealACurse-ReworkLab` (lab only).
Base: `main` @ `d4bab77`. This is the single living status document for the
cloud rework. It supersedes `REWORK_AUDIT.md` for current decisions. The older
audit is kept for history.

Evidence levels used below:
- **code**: read in the repository.
- **static**: checked by a tool here (rojo build, luau-compile, luau-lsp with
  Roblox types, lune scripts).
- **Studio**: observed in a Studio play session. Only the owner can provide this.
  Nothing in this document is Studio-verified unless it says so.

## Core loop contract (code)

What must remain true:
1. **Procession.** One shared server stream spawns a Curse every 3 s from the
   mausoleum along a fixed route. The cap is 20, unsold Curses leave at the end,
   and selection is a weighted tier roll x Luck.
2. **Purchase.** The first player to buy at 12 studs or less wins. It needs a
   claimed base, a free pedestal and enough Souls. Authority is server-only.
3. **Carry and deliver.** The buyer carries the Curse home and places it on a
   free pedestal. Dying, resetting or leaving sends it UNPLACED to the recovery
   bay. It is never lost.
4. **Income.** Souls/s is the sum of the base rates of PLACED Curses that are
   not being stolen, applied every 0.25 s. Selling a Curse returns 50%.
5. **Theft.** The full loop works only in Studio with the ToolsLedger plugin.
   Online it is disabled (`TheftService:16`). A thief carries the Curse home.
   Tools and a sealed base interrupt or prevent theft.
6. **Progression.** Sanctuary L0-10 is paid with Souls, fragments (contracts),
   discoveries, rituals and milestones. Mortimer gives one-time onboarding
   missions, plus the daily Wheel and Luck potions.
7. **Persistence.** One profile per player. Studio uses the local plugin store.
   Live uses the lab-only DataStore and is disabled until a lab universe is
   allowlisted.
8. **Red Moon.** It starts daily at 22:00 America/Los_Angeles (DST verified),
   with a 12 s warning and 20 min active, Luck +0.5 and an event mission.

## Art and experience direction

**Identity.** A greedy night market in a haunted family cemetery. The tone is
mischievous storybook-noir, not grim horror. Collecting is the joy. Being
watched (thieves, the Curses themselves) is the tension.

**Palette.**
- World: cold moonlit stone and fog (blue-grey), dark silhouettes, warm candle
  and lantern amber as wayfinding.
- Spectral green belongs to Souls.
- Blood red is reserved for Red Moon and danger.
- UI surfaces: solid warm-ink panels (no glassmorphism), hairline strokes, bone
  white text.
- Accent roles: green = Souls/income, amber = reward/cost, red = danger/event,
  rarity colours only on rarity marks.

**Typography.** BuilderSans everywhere, with Heavy for numbers. GrenzeGotisch
only for event titles and NPC names. Sizes: 12 caption (minimum), 14 body,
18 heading, 26-32 hero numbers.

**Shape and icons.** Two corner radii: 6 for controls and 10 for panels. One
meaning per icon. No decorative studs, chevrons, rotating border sweeps or
always-on halos. Motion is feedback for a change, not idle decoration.

**Curse VFX.**
- Each Curse gets one signature effect bound to a model feature and timed to
  its procedural act.
- Rarity shows as more deliberate or unusual behaviour (timing, stillness,
  distortion), not as more glow or particles.
- Light emission is reserved for the focal feature.

**Materials.** Authored vertex colours stay. We add sheen (Reflectance) and
cast shadows where a Curse needs depth and grounding. No textured materials on
Curse meshes: their UVs are palette tiles.

**Environment.**
- Composition before prop count: quiet, then a denser transition, then a
  landmark, then breathing space.
- Silhouettes read against fog. Candles guide routes. Clutter that blocks routes
  is removed.

**Mobile.**
- Top-left belongs to Roblox chat, bottom-left to the thumbstick, bottom-right
  to jump.
- The right column holds persistent economy.
- A top-centre lane holds transient and event information.
- Interactive controls never sit in the chat zone.

## Phase plan

| Phase | Scope | Gate |
|---|---|---|
| 0 | Verify repo and branch; audit 8 subsystems; P0 isolation | done |
| 1 | P0 fixes; HUD layout + chat zone + HUD restyle sample; The Void quality sample; Base08 forecourt + base grounding fixes | Studio direction review |
| 2 | Extend approved UI to the panels; collision and grounding sweep; lifecycle and perf fixes | gameplay/mobile check |
| 3 | Red Moon: true red grade, intro/outro, OFF-phase countdown after the outro, truthful mechanics | event lifecycle check |
| 4 | Daily missions (UTC reset, idempotent claims, Mortimer) | reset/claim/rejoin check |
| 5 | Wheel correctness then presentation; tool roster rework (owner-interrupt bug, boots, chain, mirror/lantern) | multiplayer feel check |
| 6 | Roll approved Curse/env direction out; trees; NPCs; new Curse (one) | visual review |
| 7 | Integration, cleanup, measured performance | final review |

## Phase 0 findings that drive the plan (code + static)

- **P0 persistence.** Live profiles used `StealACurseProfilesV1` with no
  universe guard. Fixed in `d45f39b`: a lab store name plus an empty GameId
  allowlist, so live fails closed.
- **P0 commerce.** All offers have `id=0` and `enabled=false`, there is a single
  ProcessReceipt, and prompts are guarded. This is now asserted by
  `tools/lab_safety_check.luau`.
- **P0 product.** Online theft is disabled, but the Steal prompt still shows
  online. This is deferred to the theft/tools phase. Studio theft works with
  the plugin.
- **UI.** The mission tracker, Luck chip with DRINK button, and touch SANCTUARY
  launcher sit in the chat zone. Five modules position themselves
  independently, which makes the top band collide on phones.
- **The Void.** The hero VFX is concentric discs, rings, a ball and orbit
  trails. This contradicts the mesh identity (an empty asymmetric rift).
- **Curses look like cardboard.** Causes: forced SmoothPlastic, flat vertex
  colours, no reflectance, CastShadow=false and a high flat night ambient.
- **Map.**
  - 5 elevated sanctuary floors float 1-2 studs above the ground at the
    perimeter.
  - The 8 territory offerings are built inside the sanctuary aisles.
  - A legacy block "Gravekeeper" stands 3 studs from Mortimer.
- **Red Moon.** The scene stays blue, and the copy promises "Mutated Curses"
  that never spawn. There is no outro and no next-event countdown.
- **Tools.** Hitting the owner cancels the thief's own theft (`TheftService:10`).
  Ash Boots end on swap. The chain misses moving targets. Mirror and lantern do
  nothing.

## Checkpoints

| Commit | Content | Static checks | Studio |
|---|---|---|---|
| `d45f39b` | Lab persistence isolation + lab safety check | rojo build, compile, lsp no new findings, lune safety PASS (and negative test FAIL as expected) | pending |

## Deferred ideas (short list)

- Global lighting A/B for specular (EnvironmentSpecularScale) after the Void
  sample is reviewed.
- A Blood mutation roll on Red Moon to make the event matter for collecting.
- Lab Studio profile namespace separate from other local places.
