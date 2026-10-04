local Theme = require(script.Parent.Theme)
local PanelFrame = require(script.Parent.PanelFrame)
local ShopCard = require(script.Parent.ShopCard)
local C = Theme.colors
local ShopPanel = {}

local PASSES = {
	{ name = "DoubleSouls", title = "X2 SOULS", detail = "Income multiplier concept. Not active.", icon = "double", accent = C.cyan },
	{ name = "LuckyCurses", title = "LUCKY CURSES", detail = "Luck concept. Odds remain undecided.", icon = "luck", accent = C.violet },
	{ name = "VIP", title = "VIP", detail = "Cosmetic identity. Benefits undecided.", icon = "vip", accent = C.amber },
	{ name = "ExtraCurseSlot", title = "EXTRA CURSE SLOT", detail = "Capacity concept. Current limit: 5 slots.", icon = "slot", accent = C.violet },
}
local BOOSTS = {
	{ name = "DoubleSoulRate", title = "X2 SOULS/S", detail = "Production boost concept. Not active.", icon = "double", accent = C.violet },
	{ name = "FasterDelivery", title = "FASTER DELIVERY", detail = "Delivery concept. Current speed unchanged.", icon = "speed", accent = C.cyan },
}
local PACKS = {
	{ name = "SmallSoulPack", title = "SMALL SOUL PACK", detail = "Souls bundle concept. Amount and price TBD.", icon = "souls", accent = C.cyan },
	{ name = "MediumSoulPack", title = "MEDIUM SOUL PACK", detail = "Souls bundle concept. Not purchasable yet.", icon = "souls", accent = C.violet },
	{ name = "LargeSoulPack", title = "LARGE SOUL PACK", detail = "Souls bundle concept. Contents undecided.", icon = "souls", accent = C.amber },
	{ name = "MegaSoulPack", title = "MEGA SOUL PACK", detail = "Souls bundle preview. No Souls granted.", icon = "souls", accent = C.cyan },
}

function ShopPanel.create(gui: ScreenGui, onClose)
	local chrome = PanelFrame.create(gui, "ShopOverlay", "ShopPanel", "CURSED CURIOS", "STEAL A CURSE / FUTURE SHOP", "shop", C.amber, onClose)
	local panel = chrome.panel
	local disclaimer = Theme.label(panel, "MockupDisclaimer", "CONCEPT PREVIEW · No purchases or active perks", UDim2.fromOffset(20, 83), UDim2.new(1, -40, 0, 17), 11, C.amber, Enum.Font.GothamBold)
	disclaimer.ZIndex = 22
	local tabs, pages, grids, cards = {}, {}, {}, {}
	local function selectTab(name: string)
		for key, page in pages do page.Visible = key == name end
		for key, button in tabs do
			button.BackgroundColor3 = if key == name then C.panelTop else C.ink
			button.TextColor3 = if key == name then C.white else C.muted
			button.SelectedIndicator.Visible = key == name
		end
		panel:SetAttribute("SelectedTab", name)
		chrome.footer.Text = "Future concepts only. No Robux transactions or gameplay changes."
	end
	local sections = { { "Passes", "GAMEPASSES", PASSES }, { "Boosts", "BOOSTS", BOOSTS }, { "SoulPacks", "SOUL PACKS", PACKS } }
	for index, data in sections do
		local name = data[1]
		local tab = Theme.make("TextButton", {
			Name = name .. "Tab", Text = data[2], AutoButtonColor = false,
			BackgroundColor3 = C.ink, BorderSizePixel = 0,
			Position = UDim2.fromOffset(20 + (index - 1) * 170, 108), Size = UDim2.fromOffset(160, 38),
			Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.muted, ZIndex = 23,
		}, panel)
		Theme.corner(tab, 8)
		Theme.stroke(tab, C.line, 1, 0.4)
		Theme.make("Frame", {
			Name = "SelectedIndicator", BackgroundColor3 = C.amber,
			BorderSizePixel = 0, Position = UDim2.new(0, 10, 1, -3), Size = UDim2.new(1, -20, 0, 2), ZIndex = 24,
		}, tab)
		tab.Activated:Connect(function() selectTab(name) end)
		tabs[name] = tab
		local page = Theme.make("ScrollingFrame", {
			Name = name .. "Page", Visible = index == 1, Active = true, ClipsDescendants = true,
			BackgroundTransparency = 1, BorderSizePixel = 0,
			Position = UDim2.fromOffset(20, 158), Size = UDim2.new(1, -40, 1, -203),
			ScrollBarThickness = 5, ScrollBarImageColor3 = C.violet, ScrollingEnabled = true,
			ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.fromOffset(0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 22,
		}, panel)
		Theme.make("UIPadding", {
			PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 8),
		}, page)
		local grid = Theme.make("UIGridLayout", {
			CellPadding = UDim2.fromOffset(12, 12), CellSize = UDim2.fromOffset(400, ShopCard.height(false)),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, page)
		for order, definition in data[3] do
			local card = ShopCard.create(page, definition, function(title: string)
				chrome.footer.Text = title .. " · Coming soon. Preview only; nothing was purchased."
			end)
			card.LayoutOrder = order
			table.insert(cards, card)
		end
		pages[name], grids[name] = page, grid
	end
	selectTab("Passes")
	local controller = { overlay = chrome.overlay, panel = panel }
	function controller.fit(safeSize: Vector2)
		local width, _, short = chrome.fit(safeSize)
		local tabY = if short then 65 else 108
		local bodyY = tabY + (if short then 42 else 47)
		disclaimer.Position = UDim2.fromOffset(20, if short then 44 else 86)
		disclaimer.Size = UDim2.new(1, if short then -86 else -40, 0, if short then 15 else 17)
		disclaimer.Text = if short then "CONCEPT PREVIEW · No purchases" else "CONCEPT PREVIEW · No purchases or active perks"
		disclaimer.TextSize = if width < 500 then 9 else (if short then 10 else 11)
		local tabWidth = math.min(160, math.floor((width - 60) / 3))
		for index, data in sections do
			local name = data[1]
			tabs[name].Position = UDim2.fromOffset(20 + (index - 1) * (tabWidth + 10), tabY)
			tabs[name].Size = UDim2.fromOffset(tabWidth, 36)
			tabs[name].TextSize = if width < 500 then 10 else 11
			tabs[name].Text = if width < 500 and name == "Passes" then "PASSES" else (if width < 500 and name == "SoulPacks" then "SOULS" else data[2])
		end
		local columns = if width >= 620 then 2 else 1
		local available = width - 50
		local cardWidth = math.floor((available - (columns - 1) * 12) / columns)
		for name, page in pages do
			page.Position = UDim2.fromOffset(20, bodyY)
			page.Size = UDim2.new(1, -40, 1, -bodyY - 43)
			grids[name].FillDirectionMaxCells = columns
			grids[name].CellSize = UDim2.fromOffset(cardWidth, ShopCard.height(short))
		end
		for _, card in cards do ShopCard.fit(card, short, cardWidth) end
	end
	function controller.show(visible: boolean) chrome.show(visible) end
	return controller
end

return ShopPanel
