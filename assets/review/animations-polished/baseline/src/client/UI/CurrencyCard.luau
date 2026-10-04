local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local NumberFormat = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NumberFormat"))
local Theme = require(script.Parent.Theme)
local Icons = require(script.Parent.Icons)
local C = Theme.colors
local CurrencyCard = {}

function CurrencyCard.create(gui: ScreenGui)
	local player = Players.LocalPlayer
	local holder = Theme.make("Frame", {
		Name = "SoulsHUD", AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(252, 82),
	}, gui)
	local shadow = Theme.make("Frame", {
		Name = "Shadow", BackgroundColor3 = C.ink, BackgroundTransparency = 0.4,
		BorderSizePixel = 0, Position = UDim2.fromOffset(0, 3), Size = UDim2.fromScale(1, 1),
	}, holder)
	Theme.corner(shadow, 12)
	local card = Theme.make("Frame", {
		Name = "Card", BackgroundColor3 = C.panel,
		BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
	}, holder)
	Theme.corner(card, 12)
	Theme.gradient(card, C.panelTop, C.panel)
	local border = Theme.stroke(card, C.violet, 1.4, 0.25)
	local scale = Theme.make("UIScale", { Scale = 1 }, card)
	local rail = Theme.make("Frame", {
		Name = "SoulLight", BackgroundColor3 = C.cyan, BackgroundTransparency = 0.15,
		BorderSizePixel = 0, Position = UDim2.fromOffset(0, 17), Size = UDim2.fromOffset(3, 48),
	}, card)
	Theme.corner(rail, 3)
	local icon = Icons.create("souls", card, UDim2.fromOffset(12, 10), UDim2.fromOffset(56, 56), C.cyan)
	local title = Theme.label(card, "Title", "SOULS", UDim2.fromOffset(78, 10), UDim2.new(1, -88, 0, 13), 10, C.muted, Enum.Font.GothamBold)
	local amount = Theme.label(card, "Amount", "—", UDim2.fromOffset(77, 24), UDim2.new(1, -89, 0, 31), 27, C.white, Enum.Font.GothamBlack)
	amount.TextScaled = true
	amount.TextTruncate = Enum.TextTruncate.AtEnd
	Theme.make("UITextSizeConstraint", { MinTextSize = 18, MaxTextSize = 29 }, amount)
	local rate = Theme.label(card, "SoulsPerSecond", "+0 Souls/s", UDim2.fromOffset(78, 58), UDim2.new(1, -88, 0, 17), 12, C.cyan, Enum.Font.GothamBold)
	rate.TextTruncate = Enum.TextTruncate.AtEnd
	local rateScale = Theme.make("UIScale", { Scale = 1 }, rate)
	local animated = Theme.make("NumberValue", { Name = "AnimatedSouls", Value = 0 }, gui)
	local connections = {}
	local balanceTween: Tween? = nil
	local pulseTween: Tween? = nil
	local pulseGeneration = 0
	local lastTarget: number? = nil
	local lastGainAt = -math.huge
	local lastPulseAt = -math.huge
	local previousRate: number? = nil

	local function pulse()
		pulseGeneration += 1
		local generation = pulseGeneration
		if pulseTween then pulseTween:Cancel() end
		scale.Scale = 1
		border.Color = C.cyan
		pulseTween = TweenService:Create(scale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.025 })
		pulseTween:Play()
		pulseTween.Completed:Once(function()
			if generation ~= pulseGeneration or not holder.Parent then return end
			TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			TweenService:Create(border, TweenInfo.new(0.5), { Color = C.violet }):Play()
		end)
	end

	local function updateSouls()
		local target = player:GetAttribute("Souls")
		if typeof(target) ~= "number" or target ~= target or math.abs(target) == math.huge then return end
		local prior = lastTarget
		lastTarget = target
		if not prior then animated.Value = target; return end
		if balanceTween then balanceTween:Cancel() end
		balanceTween = TweenService:Create(animated, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = target })
		balanceTween:Play()
		if target > prior then
			local now = os.clock()
			-- Pulse once when income starts, not continuously on every economy tick.
			local quiet = now - lastGainAt > 1.2
			local significant = target - prior >= math.max(100, prior * 0.2)
			if (quiet or significant) and now - lastPulseAt > 1.2 then
				lastPulseAt = now
				pulse()
			end
			lastGainAt = now
		end
	end
	local function updateRate()
		local value = player:GetAttribute("SoulsPerSecond")
		if typeof(value) ~= "number" or value ~= value then return end
		rate.Text = "+" .. NumberFormat.compact(value) .. " Souls/s"
		if previousRate and value > previousRate then
			rate.TextColor3 = C.white
			rateScale.Scale = 1.04
			TweenService:Create(rate, TweenInfo.new(0.4), { TextColor3 = C.cyan }):Play()
			TweenService:Create(rateScale, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Scale = 1 }):Play()
		end
		previousRate = value
	end
	table.insert(connections, animated:GetPropertyChangedSignal("Value"):Connect(function() amount.Text = NumberFormat.compact(animated.Value) end))
	table.insert(connections, player:GetAttributeChangedSignal("Souls"):Connect(updateSouls))
	table.insert(connections, player:GetAttributeChangedSignal("SoulsPerSecond"):Connect(updateRate))
	updateSouls()
	updateRate()

	local controller = { holder = holder }
	function controller.fit(compact: boolean, width: number)
		holder.Size = UDim2.fromOffset(width, if compact then 70 else 82)
		icon.Position = UDim2.fromOffset(if compact then 9 else 12, if compact then 8 else 10)
		icon.Size = UDim2.fromOffset(if compact then 48 else 56, if compact then 48 else 56)
		local x = if compact then 65 else 78
		title.Position = UDim2.fromOffset(x, if compact then 7 else 10)
		title.Size = UDim2.new(1, -x - 12, 0, 13)
		amount.Position = UDim2.fromOffset(x - 1, if compact then 20 else 24)
		amount.Size = UDim2.new(1, -x - 13, 0, if compact then 27 else 31)
		rate.Position = UDim2.fromOffset(x, if compact then 49 else 58)
		rate.Size = UDim2.new(1, -x - 12, 0, 17)
		rate.TextSize = if compact then 11 else 12
		rail.Position = UDim2.fromOffset(0, if compact then 14 else 17)
		rail.Size = UDim2.fromOffset(3, if compact then 40 else 48)
	end
	function controller.destroy()
		pulseGeneration += 1
		for _, connection in connections do connection:Disconnect() end
		if balanceTween then balanceTween:Cancel() end
		if pulseTween then pulseTween:Cancel() end
	end
	return controller
end

return CurrencyCard
