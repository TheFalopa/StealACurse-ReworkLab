-- Wheel of Fate panel. The server picks the sector (Progression.Request
-- "spin"); this module only animates toward that result, ticks per sector,
-- and shows the real configured probabilities.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local VisualAssets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VisualAssets"))
local Config = require(ReplicatedStorage.Shared.ProgressionConfig)
local Theme = require(script.Parent.Theme)
local PanelFrame = require(script.Parent.PanelFrame)
local C, F = Theme.colors, Theme.fonts

local Wheel = {}
local SECTORS = Config.Wheel.Sectors
local STEP = 360 / #SECTORS

local function tick(pitch)
	local s = Instance.new("Sound")
	s.SoundId = "rbxasset://sounds/volume_slider.ogg"
	s.Volume = 0.35
	s.PlaybackSpeed = pitch
	SoundService:PlayLocalSound(s)
end

function Wheel.start(gui: ScreenGui, request: RemoteFunction, onAnswer)
	local chrome = PanelFrame.create(gui, "WheelOverlay", "WheelPanel", Config.Wheel.Name, "One free spin every day  ·  real odds", "gamepass", C.amber, function() Wheel.show(false) end)
	local panel = chrome.panel
	local stage = Theme.make("Frame", { Name = "Stage", BackgroundTransparency = 1, Position = UDim2.fromOffset(24, 84), Size = UDim2.fromOffset(380, 380), ZIndex = 22 }, panel)
	Theme.make("UIAspectRatioConstraint", { AspectRatio = 1 }, stage)
	local glow = Theme.image(stage, "Glow", VisualAssets.Textures.glow_soft, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1.35, 1.35), { AnchorPoint = Vector2.new(0.5, 0.5), ImageColor3 = C.violet, ImageTransparency = 0.6, ZIndex = 22 })
	local disc = Theme.make("Frame", { Name = "Disc", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), ZIndex = 23 }, stage)
	local rim = Theme.make("Frame", { Name = "Rim", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.03, 1.03), BackgroundColor3 = Color3.fromRGB(176, 128, 60), ZIndex = 22 }, stage)
	Theme.corner(rim, 999)
	for i, s in SECTORS do
		local wedge = Theme.image(disc, "Sector" .. i, VisualAssets.Textures.wheel_wedge, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), {
			ImageColor3 = Config.WheelRarityColors[s.rarity] or C.card, Rotation = (i - 1) * STEP, ZIndex = 24,
		})
		local angle = math.rad((i - 1) * STEP)
		local r = 0.33
		local icon = Theme.image(disc, "Icon" .. i, VisualAssets.Icons[s.icon] or VisualAssets.Icons.soul,
			UDim2.fromScale(0.5 + math.sin(angle) * r, 0.5 - math.cos(angle) * r), UDim2.fromScale(0.15, 0.15),
			{ AnchorPoint = Vector2.new(0.5, 0.5), Rotation = (i - 1) * STEP, ZIndex = 25 })
		-- Icons only on the disc; names live in the result line and odds list.
		wedge:SetAttribute("SectorId", s.id)
		icon:SetAttribute("SectorId", s.id)
	end
	local hub = Theme.make("Frame", { Name = "Hub", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.22, 0.22), BackgroundColor3 = C.ink, ZIndex = 26 }, stage)
	Theme.corner(hub, 999)
	Theme.stroke(hub, Color3.fromRGB(176, 128, 60), 3, 0)
	Theme.image(hub, "Skull", VisualAssets.Icons.red_moon, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.7, 0.7), { AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 27 })
	local pointer = Theme.make("Frame", { Name = "Pointer", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, -4), Size = UDim2.fromOffset(26, 26), Rotation = 45, BackgroundColor3 = Color3.fromRGB(240, 70, 90), ZIndex = 27 }, stage)
	Theme.corner(pointer, 4)
	Theme.stroke(pointer, C.white, 2, 0)
	local pointerScale = Theme.make("UIScale", { Scale = 1 }, pointer)

	-- Right column: status, spin, odds, paid spin (disabled).
	local side = Theme.make("Frame", { Name = "Side", BackgroundTransparency = 1, Position = UDim2.new(0, 430, 0, 84), Size = UDim2.new(1, -454, 1, -130), ZIndex = 22 }, panel)
	local status = Theme.label(side, "Status", "", UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 28), 22, C.soulGreen, F.heavy)
	status.ZIndex = 23
	local sub = Theme.label(side, "Sub", "", UDim2.fromOffset(0, 30), UDim2.new(1, 0, 0, 18), 14, C.muted, F.bold)
	sub.ZIndex = 23
	local spin = Theme.make("TextButton", {
		Name = "Spin", Text = "SPIN", AutoButtonColor = false, Position = UDim2.fromOffset(0, 62), Size = UDim2.new(1, 0, 0, 58),
		BackgroundColor3 = C.amber, TextColor3 = C.ink, FontFace = F.heavy, TextSize = 24, BorderSizePixel = 0, ZIndex = 23,
	}, side)
	Theme.corner(spin, 14)
	Theme.buttonFeedback(spin, C.amber, Color3.fromRGB(255, 214, 140), { scale = Theme.make("UIScale", { Scale = 1 }, spin) })
	local result = Theme.label(side, "Result", "", UDim2.fromOffset(0, 128), UDim2.new(1, 0, 0, 52), 20, C.white, F.heavy)
	result.TextWrapped = true
	result.ZIndex = 23
	local paid = Theme.make("TextButton", {
		Name = "ExtraSpin", Text = "EXTRA SPIN  ·  COMING SOON", AutoButtonColor = false, Position = UDim2.fromOffset(0, 188), Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = C.ink, TextColor3 = C.subtle, FontFace = F.heavy, TextSize = 13, BorderSizePixel = 0, ZIndex = 23,
	}, side)
	Theme.corner(paid, 10)
	Theme.stroke(paid, C.line, 1, 0.5)
	local oddsButton = Theme.make("TextButton", {
		Name = "Odds", Text = "SHOW ODDS", AutoButtonColor = true, Position = UDim2.fromOffset(0, 236), Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = C.card, TextColor3 = C.white, FontFace = F.bold, TextSize = 13, BorderSizePixel = 0, ZIndex = 23,
	}, side)
	Theme.corner(oddsButton, 10)
	local odds = Theme.make("Frame", { Name = "OddsList", Position = UDim2.fromOffset(0, 276), Size = UDim2.new(1, 0, 0, #SECTORS * 20), BackgroundTransparency = 1, Visible = false, ZIndex = 23 }, side)
	Theme.make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, odds)
	local total = Config.wheelTotalWeight()
	for i, s in SECTORS do
		local row = Theme.label(odds, "Odd" .. i, string.format("%-22s %5.1f%%", s.label, s.weight / total * 100), UDim2.new(), UDim2.new(1, 0, 0, 20), 13, Config.WheelRarityColors[s.rarity]:Lerp(C.white, 0.45), F.bold)
		row.LayoutOrder = i
		row.ZIndex = 24
	end
	oddsButton.Activated:Connect(function() odds.Visible = not odds.Visible oddsButton.Text = if odds.Visible then "HIDE ODDS" else "SHOW ODDS" end)
	chrome.footer.Text = "Results are decided by the server with the odds shown. Cursed results are harmless and short."

	local wheelState = nil
	local spinning = false
	local rotation = 0
	local function setRotation(r)
		rotation = r
		disc.Rotation = r
		-- Mirror on the physical wheel in the world (local-only visual).
		local map = workspace:FindFirstChild("StealACurseMap")
		local face = map and map:FindFirstChild("WheelOfFate") and map.WheelOfFate:FindFirstChild("WheelFace")
		local base = face and face:GetAttribute("BaseCFrame")
		if base then face.CFrame = base * CFrame.Angles(math.rad(-r), 0, 0) end
	end

	local function renderStatus()
		local w = wheelState
		if not w then return end
		local now = workspace:GetServerTimeNow()
		if w.freeAvailable then
			status.Text = "FREE SPIN READY"
			status.TextColor3 = C.soulGreen
		elseif w.bonusSpins > 0 then
			status.Text = string.format("%d BONUS SPIN%s", w.bonusSpins, if w.bonusSpins > 1 then "S" else "")
			status.TextColor3 = C.amber
		else
			status.Text = "COME BACK TOMORROW"
			status.TextColor3 = C.muted
		end
		local left = math.max(0, w.nextFreeAt - now)
		sub.Text = if w.freeAvailable then "Resets daily at 00:00 UTC" else string.format("Next free spin in %02d:%02d:%02d", left // 3600, (left % 3600) // 60, left % 60)
		local can = (w.freeAvailable or w.bonusSpins > 0) and not spinning
		spin.Active = can
		spin.BackgroundColor3 = if can then C.amber else C.card
		spin.TextColor3 = if can then C.ink else C.subtle
	end
	RunService.Heartbeat:Connect(function() if chrome.overlay.Visible then renderStatus() end end)

	local function animateTo(index, seconds, onDone)
		spinning = true
		renderStatus()
		result.Text = ""
		-- Pointer is at the top: sector i is centred at rotation -(i-1)*STEP.
		local target = -((index - 1) * STEP) + math.random(-14, 14) * STEP / 40
		local current = rotation % 360
		local final = rotation - current + target - 360 * 5
		if final > rotation - 360 * 4 then final -= 360 end
		-- Anticipation: a small backswing, then a long decelerating spin.
		local value = Instance.new("NumberValue")
		value.Value = rotation
		local lastSector = math.floor(rotation / STEP)
		value.Changed:Connect(function(v)
			setRotation(v)
			local sector = math.floor(v / STEP)
			if sector ~= lastSector then
				lastSector = sector
				tick(1.1 + math.random() * 0.15)
				pointerScale.Scale = 1.18
				Theme.tween(pointerScale, 0.08, { Scale = 1 })
			end
		end)
		local back = TweenService:Create(value, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Value = rotation + 18 })
		back:Play()
		back.Completed:Wait()
		local main = TweenService:Create(value, TweenInfo.new(seconds - 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Value = final })
		main:Play()
		main.Completed:Wait()
		value:Destroy()
		spinning = false
		onDone()
	end

	spin.Activated:Connect(function()
		if spinning then return end
		local ok, answer = pcall(function() return request:InvokeServer("spin") end)
		if not ok or typeof(answer) ~= "table" then return end
		if not answer.ok or not answer.index then result.Text = answer.message or "" return end
		local sector = SECTORS[answer.index]
		if answer.state then wheelState = answer.state.wheel end
		task.spawn(animateTo, answer.index, answer.spinSeconds or Config.Wheel.SpinSeconds, function()
			result.Text = answer.message
			result.TextColor3 = if sector.rarity == "CURSED" then Color3.fromRGB(255, 150, 170) else Config.WheelRarityColors[sector.rarity]:Lerp(C.white, 0.5)
			glow.ImageColor3 = Config.WheelRarityColors[sector.rarity]
			glow.ImageTransparency = 0.1
			Theme.tween(glow, 1.4, { ImageTransparency = 0.6 })
			local wedge = disc:FindFirstChild("Sector" .. answer.index)
			if wedge then
				wedge.ImageColor3 = C.white
				Theme.tween(wedge, 0.8, { ImageColor3 = Config.WheelRarityColors[sector.rarity] })
			end
			if onAnswer then onAnswer(answer) end
			renderStatus()
		end)
	end)

	function Wheel.setState(s) wheelState = s and s.wheel or wheelState renderStatus() end
	function Wheel.show(v)
		chrome.show(v)
		gui.DisplayOrder = if v then 36 else 12
	end
	function Wheel.fit(size)
		local width, height, short = chrome.fit(size)
		-- Stack only on tall narrow screens (portrait); otherwise two columns.
		local narrow = width < 640 and not short and height > width
		local top = if short then 56 else 84
		local stageSize = if narrow then math.min(width - 48, height - 330)
			else math.min(380, height - top - 40, math.floor(width * 0.48))
		stageSize = math.max(120, stageSize)
		stage.Size = UDim2.fromOffset(stageSize, stageSize)
		stage.Position = if narrow then UDim2.new(0.5, -stageSize / 2, 0, 76) else UDim2.fromOffset(20, top)
		side.Position = if narrow then UDim2.new(0, 20, 0, 84 + stageSize) else UDim2.new(0, stageSize + 44, 0, top)
		side.Size = if narrow then UDim2.new(1, -40, 0, 260) else UDim2.new(1, -(stageSize + 64), 1, -(top + 36))
		-- Compact column on short screens.
		local compact = short or height < 420
		spin.Size = UDim2.new(1, 0, 0, if compact then 46 else 58)
		spin.Position = UDim2.fromOffset(0, if compact then 50 else 62)
		result.Position = UDim2.fromOffset(0, if compact then 100 else 128)
		paid.Position = UDim2.fromOffset(0, if compact then 140 else 188)
		oddsButton.Position = UDim2.fromOffset(0, if compact then 184 else 236)
		odds.Position = UDim2.fromOffset(0, if compact then 222 else 276)
	end
	return Wheel
end

return Wheel
