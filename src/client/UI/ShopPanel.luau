local Theme = require(script.Parent.Theme)
local PanelFrame = require(script.Parent.PanelFrame)
local ShopCard = require(script.Parent.ShopCard)
local StorePresentationConfig = require(script.Parent.StorePresentationConfig)
local OfferAdapter = require(script.Parent.OfferAdapter)
local C, F = Theme.colors, Theme.fonts
local ShopPanel = {}

-- Preview store: GAMEPASSES (permanent) and SHOP (consumables) tabs.
-- Cards render OfferAdapter offers (gameplay provider or presentation previews).
function ShopPanel.create(gui: ScreenGui, onClose)
	local chrome = PanelFrame.create(gui, "ShopOverlay", "ShopPanel", "Cursed Curios", "Gamepasses & Soul shop  ·  preview", "gamepass", C.magenta, onClose)
	local panel = chrome.panel
	local tabBar = Theme.make("Frame", {
		Name = "Tabs", BackgroundColor3 = C.ink, BackgroundTransparency = 0.2, BorderSizePixel = 0,
		Position = UDim2.fromOffset(18, 84), Size = UDim2.fromOffset(320, 42), ZIndex = 22,
	}, panel)
	Theme.corner(tabBar, 12)
	Theme.stroke(tabBar, C.line, 1, 0.5)
	local selector = Theme.make("Frame", {
		Name = "Selector", BackgroundColor3 = C.cardHi, BorderSizePixel = 0,
		Position = UDim2.fromOffset(4, 4), Size = UDim2.new(0.5, -6, 1, -8), ZIndex = 22,
	}, tabBar)
	Theme.corner(selector, 9)
	local selectorStroke = Theme.stroke(selector, C.magenta, 1.2, 0.2)
	local notice = Theme.label(panel, "MockupDisclaimer", "PREVIEW  ·  Not purchasable yet", UDim2.new(1, -18, 0, 94), UDim2.fromOffset(260, 20), 12, C.amber, F.bold)
	notice.AnchorPoint = Vector2.new(1, 0)
	notice.TextXAlignment = Enum.TextXAlignment.Right
	notice.ZIndex = 22
	local tabs, pages, grids, cards = {}, {}, {}, {}
	local selected = ""
	local function selectTab(name: string)
		selected = name
		for index, tab in StorePresentationConfig.Tabs do
			local on = tab.key == name
			pages[tab.key].Visible = on
			tabs[tab.key].TextColor3 = if on then C.white else C.subtle
			if on then
				Theme.tween(selector, 0.18, { Position = UDim2.new((index - 1) * 0.5, if index == 1 then 4 else 2, 0, 4) })
				selectorStroke.Color = if tab.key == "Passes" then C.magenta else C.amber
			end
		end
		panel:SetAttribute("SelectedTab", name)
		chrome.footer.Text = if OfferAdapter.hasProvider() then "Purchases are handled by Roblox." else "Previews only. No Robux purchases or gameplay effects are active."
	end
	local function onRequest(offer)
		if OfferAdapter.isPurchasable(offer) and OfferAdapter.request(offer.OfferKey) then return end
		chrome.footer.Text = (offer.DisplayName or "Offer") .. "  ·  " .. (if offer.Owned then "Already owned." else "Coming soon. Nothing was purchased.")
		chrome.footer.TextColor3 = C.amber
		Theme.tween(chrome.footer, 1.2, { TextColor3 = C.subtle })
	end
	local lastFit: Vector2? = nil
	local controller
	for index, tab in StorePresentationConfig.Tabs do
		local button = Theme.make("TextButton", {
			Name = tab.key .. "Tab", Text = tab.label, AutoButtonColor = false, BackgroundTransparency = 1,
			Position = UDim2.new((index - 1) * 0.5, 0, 0, 0), Size = UDim2.fromScale(0.5, 1),
			FontFace = F.heavy, TextSize = 15, TextColor3 = C.subtle, ZIndex = 23, Selectable = true,
		}, tabBar)
		button.Activated:Connect(function() selectTab(tab.key) end)
		tabs[tab.key] = button
		local page = Theme.make("ScrollingFrame", {
			Name = tab.key .. "Page", Visible = false, Active = true, ClipsDescendants = true,
			BackgroundTransparency = 1, BorderSizePixel = 0,
			Position = UDim2.fromOffset(18, 138), Size = UDim2.new(1, -36, 1, -176),
			ScrollBarThickness = 4, ScrollBarImageColor3 = C.violet, ScrollingDirection = Enum.ScrollingDirection.Y,
			CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 22,
		}, panel)
		Theme.make("UIPadding", {
			PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 8),
		}, page)
		local grid = Theme.make("UIGridLayout", {
			CellPadding = UDim2.fromOffset(12, 12), CellSize = UDim2.fromOffset(190, 236),
			SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Left,
		}, page)
		pages[tab.key], grids[tab.key] = page, grid
	end
	local function populate()
		for _, card in cards do card:Destroy() end
		table.clear(cards)
		for _, tab in StorePresentationConfig.Tabs do
			for order, offer in OfferAdapter.offers(tab.offerType) do
				local card = ShopCard.create(pages[tab.key], offer, onRequest)
				card.LayoutOrder = order
				table.insert(cards, card)
			end
		end
		notice.Text = if OfferAdapter.hasProvider() then "" else "PREVIEW  ·  Not purchasable yet"
		if lastFit then controller.fit(lastFit) end
	end
	populate()
	selectTab("Passes")
	OfferAdapter.onChanged(populate)

	controller = { overlay = chrome.overlay, panel = panel }
	function controller.fit(safeSize: Vector2)
		lastFit = safeSize
		local width, _, short = chrome.fit(safeSize)
		local narrow = width < 520
		-- Short (phone landscape): tabs move into the header row, beside the
		-- title, so the cards get the whole remaining height.
		local tabY = if short then 10 else 84
		local tabWidth = if short then math.min(220, math.floor(width * 0.42)) elseif narrow then width - 28 else 320
		tabBar.AnchorPoint = if short then Vector2.new(1, 0) else Vector2.new(0, 0)
		tabBar.Position = if short then UDim2.new(1, -66, 0, tabY) else UDim2.fromOffset(14, tabY)
		tabBar.Size = UDim2.fromOffset(tabWidth, if short then 38 else 42)
		chrome.heading.Size = UDim2.new(1, if short then -(tabWidth + 130) else -138, 0, chrome.heading.Size.Y.Offset)
		for _, tab in StorePresentationConfig.Tabs do
			tabs[tab.key].Text = if narrow or short then tab.short else tab.label
			tabs[tab.key].TextSize = if short then 13 else 15
		end
		notice.Visible = not narrow and not short
		notice.Position = UDim2.new(1, -18, 0, tabY + 11)
		local bodyY = if short then 58 else tabY + 54
		local available = width - 28 - 10
		local columns = if available >= 760 then 4 elseif available >= 540 or (short and available >= 380) then 3 else 2
		local cellWidth = math.floor((available - (columns - 1) * 12) / columns)
		local pageHeight = chrome.panel.Size.Y.Offset - bodyY - 34
		local cellHeight = ShopCard.height(cellWidth, short)
		if short then cellHeight = math.max(172, math.min(cellHeight, pageHeight - 12)) end
		for key, page in pages do
			page.Position = UDim2.fromOffset(14, bodyY)
			page.Size = UDim2.new(1, -28, 1, -bodyY - 34)
			grids[key].CellSize = UDim2.fromOffset(cellWidth, cellHeight)
			grids[key].FillDirectionMaxCells = columns
		end
		for _, card in cards do ShopCard.fit(card, cellWidth, cellHeight) end
	end
	function controller.show(visible: boolean) chrome.show(visible) end
	function controller.selectTab(name: string) if pages[name] then selectTab(name) end end
	function controller.selected() return selected end
	return controller
end

return ShopPanel
