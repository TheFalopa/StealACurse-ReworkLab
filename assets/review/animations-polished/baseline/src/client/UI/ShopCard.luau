local Theme = require(script.Parent.Theme)
local Icons = require(script.Parent.Icons)
local C = Theme.colors
local ShopCard = {}

function ShopCard.height(compact: boolean): number
	return if compact then 124 else 154
end

function ShopCard.create(parent: Instance, definition, onPreview)
	local card = Theme.make("Frame", {
		Name = definition.name, BackgroundColor3 = C.card,
		BorderSizePixel = 0, Size = UDim2.fromOffset(360, ShopCard.height(false)), ZIndex = 22,
	}, parent)
	Theme.corner(card, 12)
	Theme.gradient(card, definition.accent:Lerp(C.card, 0.82), C.card)
	Theme.stroke(card, definition.accent, 1.1, 0.3)
	local medallion = Theme.make("Frame", {
		Name = "Medallion", BackgroundColor3 = C.ink, BackgroundTransparency = 0.15,
		BorderSizePixel = 0, Position = UDim2.fromOffset(14, 17), Size = UDim2.fromOffset(58, 58), ZIndex = 23,
	}, card)
	Theme.corner(medallion, 15)
	Theme.stroke(medallion, definition.accent, 1, 0.6)
	local icon = Icons.create(definition.icon, medallion, UDim2.fromOffset(3, 3), UDim2.fromOffset(52, 52), definition.accent)
	icon.Name = "ProductIcon"
	icon.ZIndex = 24
	local title = Theme.label(card, "Title", definition.title, UDim2.fromOffset(86, 18), UDim2.new(1, -99, 0, 21), 15, C.white, Enum.Font.GothamBold)
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.ZIndex = 23
	local detail = Theme.label(card, "Benefit", definition.detail, UDim2.fromOffset(86, 45), UDim2.new(1, -99, 0, 43), 12, C.muted)
	detail.TextWrapped = true
	detail.TextYAlignment = Enum.TextYAlignment.Top
	detail.ZIndex = 23
	local price = Theme.label(card, "Price", "TBD", UDim2.new(0, 16, 1, -43), UDim2.fromOffset(74, 21), 17, definition.accent, Enum.Font.GothamBlack)
	price.ZIndex = 23
	local priceLabel = Theme.label(card, "PriceLabel", "FUTURE PRICE", UDim2.new(0, 16, 1, -22), UDim2.fromOffset(93, 12), 8, C.subtle, Enum.Font.GothamBold)
	priceLabel.ZIndex = 23
	local button = Theme.make("TextButton", {
		Name = "ComingSoonButton", Text = "COMING SOON", AutoButtonColor = false,
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -13, 1, -14),
		Size = UDim2.fromOffset(133, 44), BackgroundColor3 = C.ink, BorderSizePixel = 0,
		Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = definition.accent,
		Selectable = true, ZIndex = 24,
	}, card)
	Theme.corner(button, 8)
	Theme.stroke(button, definition.accent, 1, 0.4)
	Theme.buttonFeedback(button, C.ink, C.panelTop)
	-- Preview only: deliberately no IDs, currency debit, or server request.
	button.Activated:Connect(function() onPreview(definition.title) end)
	return card
end

-- Compact is a vertical layout, not a global UIScale: phone landscape keeps
-- text legible and the CTA a real 44px target while one entire card can fit.
function ShopCard.fit(card: Frame, compact: boolean, cardWidth: number?)
	local narrow = cardWidth ~= nil and cardWidth < 280
	local medallion = card.Medallion
	medallion.Position = UDim2.fromOffset(14, if compact then 13 else 17)
	medallion.Size = UDim2.fromOffset(if compact then 48 else 58, if compact then 48 else 58)
	medallion.ProductIcon.Size = UDim2.fromOffset(if compact then 42 else 52, if compact then 42 else 52)
	local x = if compact then 75 else 86
	card.Title.Position = UDim2.fromOffset(x, if compact then 12 else 18)
	card.Title.Size = UDim2.new(1, -x - 13, 0, 21)
	card.Title.TextSize = if narrow then 13 else (if compact then 14 else 15)
	card.Benefit.Position = UDim2.fromOffset(x, if compact then 37 else 45)
	card.Benefit.Size = UDim2.new(1, -x - 13, 0, if compact then 28 else 43)
	card.Benefit.TextSize = if compact or narrow then 11 else 12
	card.Price.Position = UDim2.new(0, 16, 1, if compact then -40 else -43)
	card.PriceLabel.Position = UDim2.new(0, 16, 1, if compact then -19 else -22)
	card.ComingSoonButton.Position = UDim2.new(1, -13, 1, if compact then -9 else -14)
	-- Keep a real touch target in portrait as well as landscape. On narrow
	-- cards, its width yields to the future-price label rather than overlapping it.
	card.ComingSoonButton.Size = UDim2.fromOffset(if cardWidth then math.min(133, math.max(100, cardWidth - 122)) else 133, 44)
	card:SetAttribute("CompactLayout", compact)
end

return ShopCard
