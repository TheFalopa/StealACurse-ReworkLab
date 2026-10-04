# VFX / UI ↔ Gameplay integration (codex/vfx-ui)

This branch owns presentation only. It never writes economy, ownership,
claims, carrying, theft, profiles, purchases or mutation rules. Everything
below is either new and isolated, or a read-only binding to data gameplay
already publishes. `default.project.json`, `src/server/init.server.luau`,
`src/client/init.client.luau` and every file in `src/server/Gameplay` are
unchanged.

## Files

**New (isolated)**

| Path | Role |
| --- | --- |
| `src/shared/VisualAssets.luau` | Uploaded icon/texture IDs (single source). |
| `src/shared/RedMoonConfig.luau` | Red Moon schedule, duration, transitions, debug length. |
| `src/server/Presentation/RedMoonService.luau` | Server Red Moon state + small public API. |
| `src/server/Presentation/RedMoon.server.luau` | Starts the service (keeps `init.server.luau` untouched). |
| `src/client/UI/SoulsSource.luau` | The HUD's only Souls binding (read-only). |
| `src/client/UI/OfferAdapter.luau` | Store ↔ gameplay offer boundary. |
| `src/client/UI/StorePresentationConfig.luau` | Presentation-only preview offers (no IDs/prices). |
| `src/client/UI/ClientSettings.luau`, `SettingsPanel.luau` | Local display preferences. |
| `src/client/UI/SanctuaryBeacon.luau` | Locator for the local player's own sanctuary. |
| `src/client/UI/RedMoonPresentation.luau` | Client lighting/sky/announcement/indicator. |
| `src/client/VFX/Kit.luau`, `VFX/Heroes/*`, `VFX/Mutations.luau` | Authored Curse VFX + mutation accent. |
| `tools/visuals/*`, `assets/ui/icons/*`, `assets/vfx/textures/*` | Reproducible source art. |

**Modified (presentation files, all on this branch's side)**

`src/client/CurseVFX.luau` (hero/mutation dispatch, quality setting, Red Moon
boost; the generic profile path is unchanged for non-hero Curses) and
`src/client/UI/{HUD,CurrencyCard,Navigation,PanelFrame,ShopPanel,ShopCard,Icons,Theme}.luau`.
`StoreCatalog.luau` was replaced by `StorePresentationConfig` + `OfferAdapter`.
`ShellPanel.luau` is no longer used by the HUD (left in place).

## Data the UI reads (no writes)

| Source | Written by | Used for |
| --- | --- | --- |
| `Player.Souls`, `Player.SoulsPerSecond` | `SoulsService` | Souls HUD via `SoulsSource` |
| `Player.ProfileStatus` | `ProfileStore` | "—" while no balance exists |
| `Player.HUDNotice`, `HUDNoticeSerial` | `SoulsService`/`BaseService` | Toast |
| `Player.ClaimedBaseId`, `Map.PlayerSanctuaries[id]` | `BaseService` | Sanctuary beacon |
| Curse model `CurseId`, `CurseState`, `PresentationScale`, `VFXGeometryScale`, bones | `CurseVisualService` / rigs | Hero VFX |

If gameplay moves Souls elsewhere, change only `SoulsSource.luau`.

## Red Moon

- Schedule: daily at `StartHour:StartMinute` (22:00) **US Pacific**, with
  PDT/PST computed from the US rule (2nd Sunday of March 10:00 UTC → 1st Sunday
  of November 09:00 UTC) using `DateTime`, so it never shifts with DST or
  with the host's own time zone. Duration `DurationSeconds` (20 min), warning
  `WarningSeconds` (12 s), client rise/set transitions `RiseSeconds`/`SetSeconds`.
  All in `RedMoonConfig.luau`.
- Published state: `ReplicatedStorage.RedMoonState` attributes
  `Phase` (`OFF`/`WARNING`/`ACTIVE`), `StartsAt`, `EndsAt` (unix UTC),
  `Source` (`Schedule`/`Debug`), `MutationWeightMultiplier`.
- Server API for gameplay:
  ```lua
  local RedMoon = require(game.ServerScriptService.Server.Presentation.RedMoonService)
  RedMoon.isActive()                    -- boolean
  RedMoon.getMutationWeightMultiplier() -- Config.MutationWeightMultiplier while ACTIVE, else 1
  RedMoon.Changed:Connect(function(phase) end)
  ```
- **Studio-only debug** (server command bar during Play; ignored outside
  Studio; clients cannot write server attributes):
  ```lua
  game.ReplicatedStorage.RedMoonState:SetAttribute("DebugOverride", "ON")       -- full warning → active → end run (90 s)
  game.ReplicatedStorage.RedMoonState:SetAttribute("DebugOverride", "OFF")      -- force off
  game.ReplicatedStorage.RedMoonState:SetAttribute("DebugOverride", "SCHEDULE") -- back to the real schedule
  ```
- Client restores Lighting, Atmosphere, ColorCorrection, Bloom and Sky to the
  values captured at start (verified after a full debug run).

## Mutations (integration point)

No mutation system exists in this branch. Contract for gameplay:

- Set Curse model attribute `Mutation = "Blood"` (server). The client adds a
  crimson accent layer (`VFX/Mutations.luau`) on top of the Curse's own VFX and
  boosts it ×1.5 while Red Moon is ACTIVE. Clearing the attribute removes it.
- During Red Moon, read `RedMoon.getMutationWeightMultiplier()` when rolling
  mutations. Nothing in this branch changes spawning.

## Store / monetization UI contract

The store renders offers from `OfferAdapter`. It never prompts purchases by
itself, owns no IDs, prices or ownership. Gameplay can plug in later by adding
`ReplicatedStorage.StoreOffers` (ModuleScript) returning:

```lua
{
  getOffers = function() return { --[[ Offer ]] } end,
  Changed = someSignal,          -- optional, re-renders the store
  prompt = function(offerKey) end, -- where MarketplaceService lives (gameplay)
}
-- Offer fields read by the UI:
-- OfferKey, DisplayName, Description, OfferType ("GamePass" | "DevProduct"),
-- Owned, Available, Price, Currency ("Robux"), IconPresentationKey, Badge?, AccentKey?
```

Until that module exists, `StorePresentationConfig.PreviewOffers` is shown with
COMING SOON and the CTA only explains that nothing was purchased.

## Client settings (local only)

`ClientSettings` keys: `vfxQuality` (High/Reduced: lower emitter cap, rates and
no nearby lights), `sanctuaryMarker` (On/Off), `announcements` (Full/Minimal).
Not saved to profiles.

## VFX status (2026-10-03 review)

| Curse | Status | Notes |
| --- | --- | --- |
| The Void | VFX approved / **model blocked** | Singularity, asymmetric vortex, suction, debris, comets, compression + flare. The mesh's three giant black arcs (bones `ArcL/ArcR/ArcBase`) remain a model issue; needs a mesh/rig decision. |
| Blood Moon Rose | Approved | Heartbeat, petals, embers, blood-moon backlight, stronger 4th beat. |
| Judgement Scales | Needs small polish | Soul vs light concept + transfer arc reads close; weaker beyond ~35 studs. |
| Soul Chains | Needs small polish | Travelling energy, tension pulse, link sparks; trapped soul toned down after review. |
| Nameless Door | Needs small polish | Depth flow + dark interior + drawn motes + escape burst; door-opening geometry was estimated from bones. |
| Cathedral Heart | Approved | Warm heartbeat, crack light, golden shaft, sacred motes. |
| Plague Monarch | Needs small polish | Irregular pulse, low haze, spores; haze subtle. |
| Hollow Throne | Approved | Faint occupant, apparition, ascent, cold aura. |
| Eclipse Stag | Approved | Eclipse halo, crescents, hoof embers/trails, totality flare. |
| The Last Star | Approved | Eight-point flare, orbiting crystals, rare pulse. |

Budget: 6–9 emitters per hero, all gated by the existing distance budget
(desktop 20 / mobile 12 live effects; Reduced 8 / 6), rate tiers by distance,
≤ 2 PointLights near the camera on desktop, none on mobile.
