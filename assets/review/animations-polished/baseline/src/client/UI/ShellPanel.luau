local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CurseCatalog"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NumberFormat"))
local Theme = require(script.Parent.Theme)
local PanelFrame = require(script.Parent.PanelFrame)
local Icons = require(script.Parent.Icons)
local C = Theme.colors
local ShellPanel = {}

function ShellPanel.create(gui: ScreenGui, kind: string, onClose)
	local isCurses = kind == "CURSES"
	local chrome = PanelFrame.create(gui,
		if isCurses then "CursesOverlay" else "SettingsOverlay",
		if isCurses then "CursesPanel" else "SettingsPanel",
		if isCurses then "THE RELIQUARY" else "SETTINGS",
		if isCurses then "CURSE ROSTER / DEVELOPMENT CATALOG" else "STEAL A CURSE / FUTURE PREFERENCES",
		if isCurses then "curses" else "settings", if isCurses then C.violet else C.cyan, onClose)
	local list = Theme.make("ScrollingFrame", {
		Name = "Content", Active = true, ClipsDescendants = true, BackgroundTransparency = 1, BorderSizePixel = 0,
		Position = UDim2.fromOffset(20, 105), Size = UDim2.new(1, -40, 1, -148),
		CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 5, ScrollBarImageColor3 = C.violet,
		ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 22,
	}, chrome.panel)
	Theme.make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	Theme.make("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, list)
	local rows = {}
	if isCurses then
		local orderList = Catalog.AllOrder or Catalog.Order
		local activeCount = 0
		for order, id in orderList do
			local definition = Catalog.Definitions[id]
			local rarity = Catalog.Rarities[definition.rarity]
			local manifest = Catalog.ExpansionManifest and Catalog.ExpansionManifest[id]
			local enabled = definition.enabled ~= false and (not manifest or manifest.enabled ~= false)
			if enabled then activeCount += 1 end
			local row = Theme.make("Frame", { Name = id, LayoutOrder = order, BackgroundColor3 = C.card, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 114), ZIndex = 23 }, list)
			row:SetAttribute("CurseId", id)
			row:SetAttribute("RolloutEnabled", enabled)
			row:SetAttribute("SourceReference", definition.sourceReference or (manifest and manifest.sourceReference) or "Original Steal A Curse roster")
			Theme.corner(row, 10)
			Theme.stroke(row, rarity.color, 1, 0.45)
			Icons.create("curses", row, UDim2.fromOffset(12, 21), UDim2.fromOffset(46, 46), rarity.color).ZIndex = 24
			local name = Theme.label(row, "Title", definition.displayName, UDim2.fromOffset(70, 13), UDim2.new(1, -85, 0, 21), 15, C.white, Enum.Font.GothamBold)
			name.TextTruncate = Enum.TextTruncate.AtEnd
			name.ZIndex = 24
			Theme.label(row, "Rarity", rarity.label, UDim2.fromOffset(71, 38), UDim2.new(1, -86, 0, 15), 10, rarity.color, Enum.Font.GothamBold).ZIndex = 24
			local stats = Theme.label(row, "Stats", (if enabled then "" else "DEV ") .. NumberFormat.compact(definition.price) .. " Souls · +" .. NumberFormat.compact(definition.baseSoulsPerSecond) .. " Souls/s", UDim2.fromOffset(71, 60), UDim2.new(1, -86, 0, 17), 11, C.muted)
			stats.ZIndex = 24
			local status = definition.implementationStatus or (manifest and manifest.status) or "PLANNED"
			local statusLabels = {
				PLANNED = "CONCEPT · Not spawning", GENERATED_FBX = "FBX READY · Not spawning", EXPORTED = "FBX READY · Not spawning",
				IMPORTED = "IMPORTED · Not spawning", VALIDATED = "VALIDATED · Not spawning",
			}
			local statusText = if enabled then "LIVE · Natural procession" else (statusLabels[string.upper(status)] or string.gsub(string.upper(status), "_", " ") .. " · Not spawning")
			local statusLabel = Theme.label(row, "ImplementationStatus", statusText, UDim2.fromOffset(71, 81), UDim2.new(1, -86, 0, 27), 10, if enabled then C.cyan else C.muted)
			statusLabel.TextWrapped = true
			statusLabel.TextYAlignment = Enum.TextYAlignment.Top
			statusLabel.ZIndex = 24
			table.insert(rows, row)
		end
		chrome.panel:SetAttribute("RosterCount", #orderList)
		chrome.panel:SetAttribute("LiveRosterCount", activeCount)
		chrome.footer.Text = string.format("%d live · %d expansion concepts. Catalog only; not an inventory.", activeCount, #orderList - activeCount)
	else
		chrome.footer.Text = "Preferences are a future UI shell. Nothing changes your gameplay."
		for order, data in { { "Audio mix", "Future sound and music controls." }, { "Interface", "Future display and notification preferences." }, { "Accessibility", "Future motion and readability options." } } do
			local row = Theme.make("Frame", { Name = "Preference" .. order, LayoutOrder = order, BackgroundColor3 = C.card, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 105), ZIndex = 23 }, list)
			Theme.corner(row, 10)
			Theme.stroke(row, C.line, 1, 0.4)
			Theme.label(row, "Title", data[1], UDim2.fromOffset(16, 14), UDim2.new(1, -32, 0, 22), 16, C.white, Enum.Font.GothamBold).ZIndex = 24
			Theme.label(row, "Detail", data[2], UDim2.fromOffset(16, 42), UDim2.new(1, -32, 0, 22), 11, C.muted).ZIndex = 24
			Theme.label(row, "Status", "COMING SOON", UDim2.fromOffset(16, 73), UDim2.new(1, -32, 0, 17), 10, C.cyan, Enum.Font.GothamBold).ZIndex = 24
			table.insert(rows, row)
		end
	end
	return {
		overlay = chrome.overlay,
		show = chrome.show,
		fit = function(safeSize: Vector2)
			local width, _, short = chrome.fit(safeSize)
			local y = if short then 78 else 105
			list.Position = UDim2.fromOffset(20, y)
			list.Size = UDim2.new(1, -40, 1, -y - 43)
			for _, row in rows do
				row.Title.TextSize = if width < 360 then 13 else (if isCurses then 15 else 16)
				if isCurses then row.Stats.TextSize = if width < 360 then 10 else 11 end
			end
		end,
	}
end

return ShellPanel
