local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VisualAssets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VisualAssets"))
local Theme = require(script.Parent.Theme)
local Icons = require(script.Parent.Icons)
local OfferAdapter = require(script.Parent.OfferAdapter)
local C, F = Theme.colors, Theme.fonts
local ShopCard = {}

local function ctaState(offer)
	if offer.Owned then return "OWNED", C.soulGreen end
	if OfferAdapter.isPurchasable(offer) then
		local currency = if offer.Currency == nil or offer.Currency == "Robux" then "R$ " else offer.Currency .. " "
		return currency .. tostring(offer.Price), C.white
	end
	return "COMING SOON", nil
end

-- Vertical product tile: lit icon stage, name, one-line benefit, CTA.
-- Renders one offer from OfferAdapter; it never knows IDs or ownership rules.
function ShopCard.create(parent: Instance, offer, onRequest)
	local accent = C[offer.AccentKey] or C.violet
	local card = Theme.make("Frame", {
		Name = string.gsub(offer.OfferKey, "[^%w_]", "_"), BackgroundColor3 = C.card, BorderSizePixel = 0,
		Size = UDim2.fromOffset(190, 236), ZIndex = 22,
	}, parent)
	card:SetAttribute("OfferKey", offer.OfferKey)
	card:SetAttribute("Purchasable", OfferAdapter.isPurchasable(offer))
	Theme.corner(card, 16)
	Theme.gradient(card, accent:Lerp(C.card, 0.72), C.ink)
	local stroke = Theme.stroke(card, accent, 1.4, 0.55)
	local stage = Theme.make("Frame", {
		Name = "Stage", BackgroundTransparency = 1, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 120), ZIndex = 22,
	}, card)
	local glow = Theme.image(stage, "Glow", VisualAssets.Textures.glow_soft, UDim2.fromScale(0.5, 0.52), UDim2.fromScale(1.1, 1.1), {
		AnchorPoint = Vector2.new(0.5, 0.5), ImageColor3 = accent, ImageTransparency = 0.55, ZIndex = 22,
	})
	Theme.make("UIAspectRatioConstraint", { AspectRatio = 1 }, glow)
	local icon = Icons.create(offer.IconPresentationKey or "gamepass", stage, UDim2.fromScale(0.5, 0.54), UDim2.fromScale(0.72, 0.72))
	icon.Name = "ProductIcon"
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.ZIndex = 23
	Theme.make("UIAspectRatioConstraint", { AspectRatio = 1 }, icon)
	local iconScale = Theme.make("UIScale", { Scale = 1 }, icon)
	if offer.Badge then
		local badge = Theme.make("TextLabel", {
			Name = "Badge", Text = offer.Badge, AutomaticSize = Enum.AutomaticSize.X,
			Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(0, 20),
			BackgroundColor3 = accent, BorderSizePixel = 0, TextColor3 = C.ink, TextSize = 11,
			FontFace = F.heavy, ZIndex = 24,
		}, card)
		Theme.corner(badge, 6)
		Theme.make("UIPadding", { PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7) }, badge)
	end
	local title = Theme.label(card, "Title", offer.DisplayName or offer.OfferKey, UDim2.new(0, 12, 0, 122), UDim2.new(1, -24, 0, 22), 18, C.white, F.heavy)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.ZIndex = 23
	local detail = Theme.label(card, "Benefit", offer.Description or "", UDim2.new(0, 12, 0, 146), UDim2.new(1, -24, 0, 32), 12, C.muted, F.medium)
	detail.TextWrapped = true
	detail.TextXAlignment = Enum.TextXAlignment.Center
	detail.TextYAlignment = Enum.TextYAlignment.Top
	detail.ZIndex = 23
	local label, labelColor = ctaState(offer)
	local button = Theme.make("TextButton", {
		Name = "ComingSoonButton", Text = label,
		AutoButtonColor = false, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.new(1, -20, 0, 40), BackgroundColor3 = C.ink, BorderSizePixel = 0,
		FontFace = F.heavy, TextSize = 13, TextColor3 = labelColor or accent:Lerp(C.white, 0.35),
		Selectable = true, ZIndex = 24,
	}, card)
	button:SetAttribute("CtaState", if offer.Owned then "Owned" elseif OfferAdapter.isPurchasable(offer) then "Price" else "ComingSoon")
	Theme.corner(button, 10)
	local buttonStroke = Theme.stroke(button, accent, 1.2, 0.4)
	local buttonScale = Theme.make("UIScale", { Scale = 1 }, button)
	Theme.buttonFeedback(button, C.ink, accent:Lerp(C.ink, 0.65), { scale = buttonScale, stroke = buttonStroke, accent = accent })
	card.MouseEnter:Connect(function()
		Theme.tween(stroke, 0.15, { Transparency = 0.05 })
		Theme.tween(glow, 0.2, { ImageTransparency = 0.3 })
		Theme.tween(iconScale, 0.2, { Scale = 1.07 }, Enum.EasingStyle.Back)
	end)
	card.MouseLeave:Connect(function()
		Theme.tween(stroke, 0.2, { Transparency = 0.55 })
		Theme.tween(glow, 0.25, { ImageTransparency = 0.55 })
		Theme.tween(iconScale, 0.2, { Scale = 1 })
	end)
	button.Activated:Connect(function()
		iconScale.Scale = 0.92
		Theme.tween(iconScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
		onRequest(offer)
	end)
	return card
end

-- Size-aware layout so phone tiles keep legible text and a 40px CTA.
function ShopCard.fit(card: Frame, width: number, height: number)
	local stageHeight = math.floor(height - 116)
	card.Stage.Size = UDim2.new(1, 0, 0, stageHeight)
	local small = width < 160
	card.Title.Position = UDim2.new(0, 8, 0, stageHeight)
	card.Title.Size = UDim2.new(1, -16, 0, 22)
	card.Title.TextSize = if small then 15 else 18
	card.Benefit.Position = UDim2.new(0, 10, 0, stageHeight + 23)
	card.Benefit.Size = UDim2.new(1, -20, 0, 32)
	card.Benefit.TextSize = if small then 11 else 12
	card.ComingSoonButton.TextSize = if small then 11 else 13
	card.ComingSoonButton.Size = UDim2.new(1, if small then -14 else -20, 0, 40)
end

function ShopCard.height(width: number, short: boolean): number
	return math.floor(math.clamp(width * (if short then 1.08 else 1.24), 196, 252))
end

return ShopCard
