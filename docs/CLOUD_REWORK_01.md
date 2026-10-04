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
7. **Persistence.** One profile per player. Studio uses the local plugin store
   in the lab's own slot (see "Lab save isolation"). Live uses the lab-only
   DataStore and is disabled until a lab universe is allowlisted.
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

## Lab save isolation (owner decision 2026-10-04)

| Context | Lab slot / store | Real project (never touched by lab builds) |
|---|---|---|
| Studio profiles (LocalProfileStore plugin setting) | `StealACurseLocalProfilesV1reworklab` | `StealACurseLocalProfilesV1play` |
| Studio theft ledger (ToolsLedger plugin setting) | `StealACurseToolLedgerV1reworklab` | `StealACurseToolLedgerV1play` |
| Live DataStore | `StealACurseReworkLab_ProfilesV1`, only in allowlisted universes (none) | `StealACurseProfilesV1` |

- Namespace **`reworklab`** is set as an attribute on
  `ServerStorage.LocalProfileBridge` in `default.project.json`. It is mirrored by
  `Config.LocalProfileNamespace`. Both installed plugins append it to their
  settings key; they were not changed.
- `ProfileStore` and `TheftLedger` refuse any Studio slot that is not
  `reworklab` or a `qa-*` test fixture. A missing or default namespace therefore
  gives `ProfileStatus=UNAVAILABLE` and reads or writes nothing, instead of
  falling back to the shared `play` slot.
- There is no migration and no deletion: the real project's `play` slots are
  never read. The lab starts fresh at 500 Souls.
- Verified by `tools/lab_safety_check.luau` and by decoding the built place
  (static). Studio confirmation is pending.

## Phase plan

| Phase | Scope | Gate |
|---|---|---|
| 0 | Verify repo and branch; audit 8 subsystems; P0 isolation | done |
| 1 | P0 fixes; HUD layout + chat zone + HUD restyle sample; The Void quality sample; Base08 forecourt + base grounding fixes | **awaiting Studio direction review** |
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
| `36fc1c6` | Lab Studio save slot `reworklab` + guards + safety checks | rojo build (attribute decoded in place file), compile, lsp no new findings, lune safety PASS 25/25, negative test FAIL as expected | pending |
| `fd3a159` | Phase 1 HUD frame (merge of `7f67c83` + review fixes `8ec8ad0`) | build, compile, lsp/lint = baseline, hud_layout_check PASS 1215 (+ negative test), safety PASS | pending |
| `0decc3a` | Phase 1 The Void (merge of `a471fa7` + review fixes `cac87b4`) | build, compile, lsp/lint = baseline, void_motion_check PASS 32, safety PASS | pending |
| `6affe64` | Phase 1 Base08 forecourt + foundations (merge of `6aa2c7d` + review fixes `0584d34`) | build, compile, lsp/lint = baseline, Lune map-build simulation (only intended parts changed, 0 new lights/emitters), safety PASS | pending |
| `81ddcf7` | Studio-only QA hooks (`QANextCurse`, Progression `souls n`) | build, compile, lsp/lint = baseline, safety PASS | pending |

## Phase 1: ready for Studio validation (not yet approved)

The direction sample is one UI area, one Curse and one base area. Each track
went through an implementer, an independent adversarial review (Roblox runtime
plus spec/design) and a fix pass before merge.

**HUD frame (UI/mobile).**
- `UI/HudLayout.luau` is the single layout authority. It is pure `compute()`
  (Lune-tested) plus an event-driven runtime that measures the safe area, the
  TextChatService chat window and the touch JumpButton.
- The right column holds the Souls card, the nav and the Luck pill (with
  DRINK).
- The top-centre lane holds the Red Moon chip, one objective chip
  (ritual > contract > mission) and the toast.
- Touch:
  - The tool bar sits right of the thumbstick frame.
  - The bench and the SANCTUARY icon sit beside or above slot 3.
  - USE sits beside the jump button.
  - Nothing interactive is in the chat zone; the passive lane may run under the
    closed-by-default phone chat.
- The toast queue holds at most 3, drops duplicates and puts 'bad' first.
- Restyle sample: the Souls card and nav use solid warm ink, a hairline stroke
  and radii 10/6. There are no sweeps, studs, chevrons or idle tweens. The rate
  reads `+N/s`, or "Place a Curse to earn" when it is 0.

**The Void (Curse quality sample).**
- Removed the rings, discs, ball and orbit trails.
- The rift is now a jagged three-cut tear of absence along the rift's own
  skewed axis, sheathed in narrow Glass for real refraction on desktop.
- Cold fragments trace the inner edges and suction flows from both rims into
  the tear.
- Shard glints fire at tension. On release, dark shards are spat at the camera
  and a cold flash runs up the edges. Sill mist and one cold back light (on the
  far side from the camera) complete it.
- It reads from both sides (carried view) and nothing smears while it moves.
- `Motion.voidPull` drives both the bones and the VFX on one act clock. The
  act has hold, then a visible anticipation lean, then draw, strain, snap and
  settle.
- Surface: Reflectance 0.15 and CastShadow on this Curse only.
- Budget: 7 emitters, 1 light, 0 trails. On mobile/Reduced the glass fades out
  and the tear stays.

**Base08 forecourt + grounding.**
- Base08: two leaning `tree_widow` framing trees with autumn clumps and
  stacked trunk colliders, a family-grave group (kerb, railing, candles,
  pumpkin) and two unlit Neon gate lanterns. Soil and roots seat the pieces.
  That is 66 parts, 0 lights and 0 emitters.
- All 5 elevated sanctuaries get a non-colliding stone foundation, with a lip
  at the ramp on height-2 bases.
- All 8 territory offerings move out of the aisles; Base01's also moves off
  the GateWatch lantern.
- The legacy block Gravekeeper is removed; Mortimer stays.

**Known limits (honest).**
- No Studio run happened in the cloud.
- Glass refraction, the chat-window measurement space, the real thumbstick and
  jump rects, the tree pose and the foundation colour all need eyes in Studio.
- The Red Moon chip still says "Mutated Curses" (Phase 3).

## Deferred ideas (short list)

- Global lighting A/B for specular (EnvironmentSpecularScale) after the Void
  sample is reviewed.
- A Blood mutation roll on Red Moon to make the event matter for collecting.
