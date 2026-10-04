local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local NumberFormat = require(Shared:WaitForChild("NumberFormat"))
local VisualAssets = require(Shared:WaitForChild("VisualAssets"))
local Theme = require(script.Parent.Theme)
local Icons = require(script.Parent.Icons)
local SoulsSource = require(script.Parent.SoulsSource)
local C, F = Theme.colors, Theme.fonts
local CurrencyCard = {}

-- Right-side Souls card. Reads authoritative data only through SoulsSource;
-- it never writes economy state.
function CurrencyCard.create(gui: ScreenGui)
	local holder = Theme.make("Frame", {
		Name = "SoulsHUD", AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		Position = UDim2.new(1, -14, 0, 12), Size = UDim2.fromOffset(232, 78),
	}, gui)
	-- The pre-Phase-1 card the owner kept: violet gradient, line stroke, a
	-- soft cyan halo behind the soul, two corner studs and a lit bevel. All of
	-- it is static at rest; only balance and rate changes animate.
	local shadow = Theme.make("Frame", {
		Name = "Shadow", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55,
		BorderSizePixel = 0, Position = UDim2.fromOffset(0, 4), Size = UDim2.fromScale(1, 1),
	}, holder)
	Theme.corner(shadow, Theme.radius.panel)
	local card = Theme.make("Frame", {
		Name = "Card", BackgroundColor3 = C.panel, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
	}, holder)
	Theme.corner(card, Theme.radius.panel)
	Theme.gradient(card, Color3.fromRGB(52, 36, 88), Color3.fromRGB(16, 13, 30))
	local BORDER_REST = 0.15
	local border = Theme.stroke(card, C.line, 1.5, BORDER_REST)
	-- Small gothic diamond studs on two corners.
	for index, anchor in { Vector2.new(0, 0), Vector2.new(1, 1) } do
		local stud = Theme.make("Frame", {
			Name = "CornerStud" .. index, AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 45,
			Position = UDim2.new(anchor.X, if anchor.X == 0 then 9 else -9, anchor.Y, if anchor.Y == 0 then 9 else -9),
			Size = UDim2.fromOffset(5, 5), BackgroundColor3 = C.violet, BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 2,
		}, card)
		stud:SetAttribute("Ornament", true)
	end
	local scale = Theme.make("UIScale", { Scale = 1 }, card)
	-- A faint inner top edge gives the card a lit bevel without a neon border.
	Theme.make("Frame", {
		Name = "Bevel", BackgroundColor3 = C.white, BackgroundTransparency = 0.9,
		BorderSizePixel = 0, Position = UDim2.new(0, 14, 0, 1), Size = UDim2.new(1, -28, 0, 1),
	}, card)
	-- Static soft halo behind the soul; a gain flashes it, then it settles back.
	local HALO_REST = 0.72
	local halo = Theme.image(card, "SoulHalo", VisualAssets.Textures.glow_soft, UDim2.fromOffset(-6, -6), UDim2.fromOffset(88, 88), {
		ImageColor3 = C.cyan, ImageTransparency = HALO_REST, ZIndex = 1,
	})
	local icon = Icons.create("souls", card, UDim2.fromOffset(12, 13), UDim2.fromOffset(52, 52))
	icon.ZIndex = 2
	local iconScale = Theme.make("UIScale", { Scale = 1 }, icon)
	local title = Theme.label(card, "Title", "SOULS", UDim2.fromOffset(74, 10), UDim2.new(1, -86, 0, 14), Theme.textSize.caption, C.muted, F.heavy)
	-- Hero number.
	local amount = Theme.label(card, "Amount", "0", UDim2.fromOffset(73, 22), UDim2.new(1, -84, 0, 32), Theme.textSize.hero, C.white, F.number)
	amount.TextScaled = true
	amount.TextTruncate = Enum.TextTruncate.AtEnd
	Theme.make("UITextSizeConstraint", { MinTextSize = 18, MaxTextSize = 31 }, amount)
	Theme.make("UIStroke", { Color = C.ink, Thickness = 1.2, Transparency = 0.3 }, amount)
	local rate = Theme.label(card, "SoulsPerSecond", "", UDim2.fromOffset(74, 54), UDim2.new(1, -84, 0, 16), Theme.textSize.body, C.soulGreen, F.bold)
	rate.TextTruncate = Enum.TextTruncate.AtEnd
	local rateScale = Theme.make("UIScale", { Scale = 1 }, rate)
	local animated = Theme.make("NumberValue", { Name = "AnimatedSouls", Value = 0 }, gui)
	local connections = {}
	local balanceTween: Tween? = nil
	local lastTarget: number? = nil
	local previousRate: number? = nil
	local pendingGain, lastPopAt, lastPulseAt = 0, -math.huge, -math.huge
	local rateSize = Theme.textSize.body
	local rateTween: Tween? = nil

	-- Short spectral "+N" that rises off the amount. Gains are pooled so a
	-- per-second income tick produces at most one quiet pop every few seconds.
	local function pop(text: string, big: boolean)
		local label = Theme.label(card, "GainPop", text, UDim2.new(0, amount.Position.X.Offset + amount.TextBounds.X + 8, 0, amount.Position.Y.Offset + 4),
			UDim2.fromOffset(90, 18), if big then 16 else 13, C.soulGreen, F.heavy)
		label.ZIndex = 3
		label.TextTransparency = 0.05
		Theme.make("UIStroke", { Color = C.ink, Thickness = 1, Transparency = 0.4 }, label)
		Theme.tween(label, 0.9, { Position = label.Position - UDim2.fromOffset(0, 14), TextTransparency = 1 })
		task.delay(0.95, function() label:Destroy() end)
	end

	local function pulse(strong: boolean)
		local now = os.clock()
		if now - lastPulseAt < 0.6 then return end
		lastPulseAt = now
		iconScale.Scale = if strong then 1.18 else 1.08
		TweenService:Create(iconScale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		halo.ImageTransparency = if strong then 0.35 else 0.55
		Theme.tween(halo, 0.8, { ImageTransparency = HALO_REST })
		if strong then
			border.Color = C.cyan
			border.Transparency = 0
			scale.Scale = 1.03
			Theme.tween(scale, 0.3, { Scale = 1 })
			Theme.tween(border, 0.7, { Color = C.line, Transparency = BORDER_REST })
		end
	end

	local function updateSouls()
		local target = SoulsSource.balance()
		if not target then
			-- No authoritative balance yet (loading / unavailable profile).
			if not lastTarget then amount.Text = "—" end
			return
		end
		local prior = lastTarget
		lastTarget = target
		if not prior then animated.Value = target; amount.Text = NumberFormat.compact(target); return end
		if balanceTween then balanceTween:Cancel() end
		balanceTween = TweenService:Create(animated, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = target })
		balanceTween:Play()
		local gain = target - prior
		if gain <= 0 then return end
		local significant = gain >= math.max(100, prior * 0.15)
		pendingGain += gain
		local now = os.clock()
		if significant or now - lastPopAt > 3 then
			lastPopAt = now
			pop("+" .. NumberFormat.compact(pendingGain), significant)
			pendingGain = 0
			pulse(significant)
		end
	end

	local function updateRate()
		local value = SoulsSource.rate()
		if not value then return end
		-- Zero income gets a next step instead of "+0/s".
		local earning = value > 0
		rate.Text = if earning then "+" .. NumberFormat.compact(value) .. "/s" else "Place a Curse to earn"
		-- A running flash tween would otherwise repaint the help text green.
		if rateTween then
			rateTween:Cancel()
			rateTween = nil
		end
		rate.TextColor3 = if earning then C.soulGreen else C.muted
		rate.FontFace = if earning then F.bold else F.medium
		rate.TextSize = if earning then rateSize else Theme.textSize.caption
		if previousRate and value > previousRate then
			rate.TextColor3 = C.white
			rateScale.Scale = 1.12
			rateTween = Theme.tween(rate, 0.5, { TextColor3 = C.soulGreen })
			TweenService:Create(rateScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			pulse(true)
		end
		previousRate = value
	end
	table.insert(connections, animated:GetPropertyChangedSignal("Value"):Connect(function()
		if lastTarget then amount.Text = NumberFormat.compact(animated.Value) end
	end))
	table.insert(connections, SoulsSource.onBalanceChanged(updateSouls))
	table.insert(connections, SoulsSource.onRateChanged(updateRate))
	updateSouls()
	updateRate()

	local controller = { holder = holder }
	function controller.fit(compact: boolean, width: number, height: number)
		holder.Size = UDim2.fromOffset(width, height)
		local iconSize = if compact then 40 else 52
		local x = if compact then 56 else 74
		icon.Position = UDim2.fromOffset(if compact then 9 else 12, math.floor((height - iconSize) / 2))
		icon.Size = UDim2.fromOffset(iconSize, iconSize)
		halo.Size = UDim2.fromOffset(iconSize + 36, iconSize + 36)
		halo.Position = UDim2.fromOffset(icon.Position.X.Offset - 18, icon.Position.Y.Offset - 18)
		title.Visible = not compact
		title.Position = UDim2.fromOffset(x, 10)
		title.Size = UDim2.new(1, -x - 12, 0, 14)
		amount.Position = UDim2.fromOffset(x - 1, if compact then 5 else 22)
		amount.Size = UDim2.new(1, -x - 10, 0, if compact then 28 else 32)
		rate.Position = UDim2.fromOffset(x, if compact then 34 else 55)
		rate.Size = UDim2.new(1, -x - 10, 0, if compact then 14 else 16)
		rateSize = if compact then Theme.textSize.caption else Theme.textSize.body
		updateRate()
	end
	function controller.destroy()
		for _, connection in connections do connection:Disconnect() end
		if balanceTween then balanceTween:Cancel() end
		if rateTween then rateTween:Cancel() end
	end
	return controller
end

return CurrencyCard
