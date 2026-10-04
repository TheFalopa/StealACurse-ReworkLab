-- HUD layout static check (no Studio needed). Run from the repo root:
--   lune run tools/hud_layout_check.luau
-- Runs the pure HudLayout.compute at the documented viewport presets (safe-area
-- pixels) with every lane widget + Luck shown, and with them hidden. Fails
-- (exit 1) on: widget overlaps (tool bar and bench included), a widget in the
-- chat zone (desktop: any; touch: interactive ones; the passive lane may run
-- under the closed-by-default phone chat), an interactive widget in the
-- thumbstick frame, any widget in the thumb-rest zone, anything over the jump
-- button, a rect outside the safe area, a touch target under 44 px, or a
-- widget the layout could not place.
-- Arithmetic only: Studio still has to confirm the real chat window, jump
-- button and thumbstick against these fallbacks.
local process = require("@lune/process")

local HudLayout = require("../src/client/UI/HudLayout")

local PRESETS = {
	{ name = "640x324 touch", width = 640, height = 324, touch = true, objective = "lane" },
	{ name = "640x360 touch", width = 640, height = 360, touch = true, objective = "lane" },
	{ name = "667x339 touch", width = 667, height = 339, touch = true, objective = "lane" },
	{ name = "749x361 touch", width = 749, height = 361, touch = true, objective = "lane" },
	{ name = "844x354 touch", width = 844, height = 354, touch = true, objective = "lane" },
	{ name = "960x540 touch (hybrid)", width = 960, height = 540, touch = true, objective = "lane" },
	{ name = "1024x710 touch", width = 1024, height = 710, touch = true, objective = "lane" },
	{ name = "1279x662 desktop", width = 1279, height = 662, touch = false, objective = "lane" },
	{ name = "1904x980 desktop", width = 1904, height = 980, touch = false, objective = "lane" },
	-- Measured inputs larger than the fallbacks must still produce a clean frame.
	{ name = "1279x662 desktop, measured chat 470x330", width = 1279, height = 662, touch = false, chat = { x = 0, y = 0, w = 470, h = 330 } },
	{ name = "749x361 touch, measured jump 90 px", width = 749, height = 361, touch = true, jump = { x = 640, y = 250, w = 90, h = 90 } },
	{ name = "400x718 touch portrait", width = 400, height = 718, touch = true },
}

local failures, checks = {}, 0
local function check(ok: boolean, message: string)
	checks += 1
	if not ok then table.insert(failures, message) end
end
local function show(r): string
	return if r then `({r.x},{r.y} {r.w}x{r.h})` else "-"
end

-- Objective priority: ritual > contract > mission/event.
local P = HudLayout.ObjectivePriority
check(HudLayout.objectiveOwner({}) == nil, "no claim -> no objective")
check(HudLayout.objectiveOwner({ mission = P.mission }) == "mission", "mission alone shows")
check(HudLayout.objectiveOwner({ mission = P.mission, sanctuary = P.contract }) == "sanctuary", "contract hides mission")
check(HudLayout.objectiveOwner({ mission = P.event, sanctuary = P.ritual }) == "sanctuary", "ritual hides event task")
check(P.ritual > P.contract and P.contract > P.mission and P.mission == P.event, "priority order ritual > contract > mission = event")
check(HudLayout.compute({ width = 0, height = 0 }) == nil, "no layout before the safe area has a size")

for _, preset in PRESETS do
	for _, shown in { true, false } do
		local label = `{preset.name} [{if shown then "lane+luck shown" else "lane+luck hidden"}]`
		local layout = HudLayout.compute({
			width = preset.width, height = preset.height, touch = preset.touch, chat = preset.chat, jump = preset.jump,
			visible = { eventChip = shown, objective = shown, toast = shown, luck = shown },
		})
		check(layout ~= nil, `{label}: compute returned nil`)
		if not layout then continue end
		local zones = layout.zones
		local items = {}
		for _, name in HudLayout.Widgets do
			if layout.visible[name] then table.insert(items, { name = name, rect = layout[name] }) end
		end

		check(#layout.unresolved == 0, `{label}: could not place {table.concat(layout.unresolved, ", ")}`)
		for i, a in items do
			check(HudLayout.inside(a.rect, layout.width, layout.height), `{label}: {a.name} {show(a.rect)} leaves the safe area`)
			for j = i + 1, #items do
				local b = items[j]
				check(not HudLayout.intersects(a.rect, b.rect), `{label}: {a.name} {show(a.rect)} overlaps {b.name} {show(b.rect)}`)
			end
			local interactive = HudLayout.Interactive[a.name] == true
			if not preset.touch or interactive then
				check(not HudLayout.intersects(a.rect, zones.chat), `{label}: {a.name} {show(a.rect)} is in the chat zone {show(zones.chat)}`)
			end
			if interactive then
				check(not HudLayout.intersects(a.rect, zones.thumbstick), `{label}: {a.name} {show(a.rect)} is in the thumbstick frame {show(zones.thumbstick)}`)
			end
			check(not HudLayout.intersects(a.rect, zones.thumbRest), `{label}: {a.name} {show(a.rect)} is in the thumb-rest zone {show(zones.thumbRest)}`)
			check(not HudLayout.intersects(a.rect, zones.jump), `{label}: {a.name} {show(a.rect)} covers the jump button {show(zones.jump)}`)
		end
		if layout.visible.luck then
			check(not HudLayout.intersects(layout.drink, zones.chat) and not HudLayout.intersects(layout.drink, zones.jump), `{label}: DRINK in a reserved zone`)
		end
		if preset.touch then
			check(zones.jump ~= nil and zones.thumbstick ~= nil, `{label}: touch must reserve jump and thumbstick`)
			check(layout.navTile.w >= 44 and layout.navTile.h >= 44, `{label}: nav tile {layout.navTile.w}x{layout.navTile.h} < 44`)
			for _, name in { "drink", "launcher", "useButton", "bench" } do
				local r = layout[name]
				check(r.w >= 44 and r.h >= 44, `{label}: {name} {show(r)} is under 44 px`)
			end
		end
		if preset.objective then
			check(layout.objectivePlacement == preset.objective, `{label}: objective placed in {layout.objectivePlacement}, expected {preset.objective}`)
		end
		if shown then
			print(`[INFO] {preset.name}: chat {show(zones.chat)} jump {show(zones.jump)} thumb {show(zones.thumbstick)}`)
			print(`       souls {show(layout.souls)} nav {show(layout.nav)} luck {show(layout.luck)} drink {show(layout.drink)}`)
			print(`       event {show(layout.eventChip)} objective[{layout.objectivePlacement}] {show(layout.objective)} toast {show(layout.toast)}`)
			print(`       bar {show(layout.toolBar)} bench {show(layout.bench)} launcher {show(layout.launcher)} use {show(layout.useButton)}`)
		end
	end
end

if #failures > 0 then
	for _, message in failures do print("[FAIL] " .. message) end
	print(`[SUMMARY] {checks} checks, {#failures} failed`)
	process.exit(1)
end
print(`[PASS] hud layout: {checks} checks`)
