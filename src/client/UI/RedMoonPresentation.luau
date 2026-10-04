-- Client presentation of the Red Moon event. Reads ReplicatedStorage.RedMoonState
-- (written only by the server RedMoonService) and animates everything locally:
-- lighting/atmosphere/sky blend, a crimson corona at the real moon direction,
-- drifting ash, the RED MOON RISING banner and a small persistent indicator.
-- Lighting is restored exactly to the values captured at start-up.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("RedMoonConfig"))
local VisualAssets = require(Shared:WaitForChild("VisualAssets"))
local Theme = require(script.Parent.Theme)
local ClientSettings = require(script.Parent.ClientSettings)
local C, F = Theme.colors, Theme.fonts

local CRIMSON = Color3.fromRGB(255, 70, 88)
local BLOOD = Color3.fromRGB(150, 12, 36)

-- Event targets per object/property. The normal night is whatever the place
-- already uses (captured at start), so the map's own lighting stays canonical.
local TARGETS = {
	Lighting = {
		Ambient = Color3.new(0.52, 0.36, 0.46), OutdoorAmbient = Color3.new(0.6, 0.4, 0.5),
		FogColor = Color3.new(0.28, 0.06, 0.11), ExposureCompensation = 0.6,
	},
	Atmosphere = {
		Color = Color3.new(0.56, 0.2, 0.28), Decay = Color3.new(0.34, 0.05, 0.12), Density = 0.33, Haze = 2,
	},
	ColorCorrectionEffect = {
		TintColor = Color3.new(1, 0.9, 0.92), Saturation = 0.06, Contrast = 0.1,
	},
	BloomEffect = { Intensity = 0.32 },
	Sky = { StarCount = 60, MoonAngularSize = 24 },
}

local RedMoonPresentation = {}

local function lerpValue(a, b, t)
	if typeof(a) == "Color3" then return a:Lerp(b, t) end
	return a + (b - a) * t
end

-- Shortest-path ClockTime blend across midnight.
local function lerpClock(a: number, b: number, t: number): number
	local delta = ((b - a + 12) % 24) - 12
	return (a + delta * t) % 24
end

function RedMoonPresentation.start(gui: ScreenGui, requestFit)
	local blend = Instance.new("NumberValue")
	blend.Name = "RedMoonBlend"
	local blendTween: Tween? = nil
	local baseline = {}
	local objects = {}
	local function capture(className: string, object: Instance?)
		if not object then return end
		objects[className] = object
		baseline[className] = {}
		for property in TARGETS[className] do baseline[className][property] = object[property] end
	end
	capture("Lighting", Lighting)
	capture("Atmosphere", Lighting:FindFirstChildOfClass("Atmosphere"))
	capture("ColorCorrectionEffect", Lighting:FindFirstChildOfClass("ColorCorrectionEffect"))
	capture("BloomEffect", Lighting:FindFirstChildOfClass("BloomEffect"))
	local sky = Lighting:FindFirstChildOfClass("Sky")
	capture("Sky", sky)
	local baseClock = Lighting.ClockTime
	local baseMoon = sky and sky.MoonTextureId

	-- World layers (client-only, under the camera so they never replicate).
	local corona = Instance.new("Part")
	corona.Name = "RedMoonCorona"
	corona.Anchored, corona.CanCollide, corona.CanQuery, corona.CanTouch = true, false, false, false
	corona.Transparency, corona.Size, corona.CastShadow = 1, Vector3.one, false
	local coronaGui = Theme.make("BillboardGui", {
		Name = "Corona", LightInfluence = 0, AlwaysOnTop = false, Enabled = false,
		Size = UDim2.fromScale(300, 300), MaxDistance = 100000,
	}, corona)
	local halo = Theme.image(coronaGui, "Halo", VisualAssets.Textures.glow_soft, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), {
		ImageColor3 = CRIMSON, ImageTransparency = 1,
	})
	local rays = Theme.image(coronaGui, "Rays", VisualAssets.Textures.glow_core, UDim2.fromScale(0.15, 0.15), UDim2.fromScale(0.7, 0.7), {
		ImageColor3 = Color3.fromRGB(255, 120, 120), ImageTransparency = 1,
	})
	local ashSource = Instance.new("Part")
	ashSource.Name = "RedMoonAsh"
	ashSource.Anchored, ashSource.CanCollide, ashSource.CanQuery, ashSource.CanTouch = true, false, false, false
	ashSource.Transparency, ashSource.Size, ashSource.CastShadow = 1, Vector3.new(90, 1, 90), false
	local ash = Instance.new("ParticleEmitter")
	ash.Name = "Ash"
	ash.Texture = VisualAssets.Textures.ember
	ash.Shape = Enum.ParticleEmitterShape.Box
	ash.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	ash.EmissionDirection = Enum.NormalId.Bottom
	ash.Speed = NumberRange.new(0.8, 1.6)
	ash.Acceleration = Vector3.new(0.6, -0.5, 0.2)
	ash.Lifetime = NumberRange.new(7, 10)
	ash.Rate = 0
	ash.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.1, 0.4), NumberSequenceKeypoint.new(1, 0.18) })
	ash.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.25), NumberSequenceKeypoint.new(1, 1) })
	ash.Color = ColorSequence.new(Color3.fromRGB(255, 110, 100), BLOOD)
	ash.RotSpeed = NumberRange.new(-60, 60)
	ash.LightEmission = 1
	ash.Parent = ashSource

	local function apply()
		local k = blend.Value
		for className, props in TARGETS do
			local object = objects[className]
			if object then
				for property, target in props do object[property] = lerpValue(baseline[className][property], target, k) end
			end
		end
		Lighting.ClockTime = lerpClock(baseClock, Config.EventClockTime, math.clamp(k * 1.25, 0, 1))
		-- Swap the moon at the darkest, most hazy point of the transition.
		if sky and baseMoon ~= nil then
			sky.MoonTextureId = if k >= 0.5 then VisualAssets.Textures.moon_blood else baseMoon
		end
		coronaGui.Enabled = k > 0.02
		local camera = workspace.CurrentCamera
		corona.Parent = if k > 0.02 then camera else nil
		ashSource.Parent = if k > 0.02 then camera else nil
		ash.Rate = 36 * math.clamp((k - 0.4) / 0.6, 0, 1) * (if ClientSettings.get("vfxQuality") == "Reduced" then 0.4 else 1)
	end
	blend.Changed:Connect(apply)

	local function blendTo(value: number, seconds: number)
		if blendTween then blendTween:Cancel() end
		blendTween = TweenService:Create(blend, TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Value = value })
		blendTween:Play()
	end

	-- The corona follows the real moon direction and breathes slowly.
	RunService.RenderStepped:Connect(function()
		if blend.Value <= 0.02 then return end
		local camera = workspace.CurrentCamera
		if not camera then return end
		-- Far enough to sit behind the map, near enough to avoid far-fog culling.
		local distance = 300
		local direction = Lighting:GetMoonDirection()
		corona.CFrame = CFrame.new(camera.CFrame.Position + direction * distance)
		local angular = (sky and sky.MoonAngularSize or 20)
		local diameter = 2 * distance * math.tan(math.rad(angular) * 0.5) * 3.2
		coronaGui.Size = UDim2.fromScale(diameter, diameter)
		local t = os.clock()
		local k = math.clamp((blend.Value - 0.4) / 0.6, 0, 1)
		halo.ImageTransparency = 1 - k * (0.7 + 0.1 * math.sin(t * 0.9))
		rays.ImageTransparency = 1 - k * (0.35 + 0.08 * math.sin(t * 1.7 + 1))
		rays.Rotation = t * 3
		ashSource.CFrame = CFrame.new(camera.CFrame.Position + camera.CFrame.LookVector * 25 + Vector3.new(0, 16, 0))
	end)

	-- UI: lead-in line, banner and persistent indicator.
	local warning = Theme.label(gui, "RedMoonWhisper", "", UDim2.fromScale(0.5, 0.2), UDim2.fromOffset(520, 34), 28, Color3.fromRGB(255, 140, 150), F.display)
	warning.AnchorPoint = Vector2.new(0.5, 0)
	warning.TextXAlignment = Enum.TextXAlignment.Center
	warning.TextTransparency = 1
	warning.ZIndex = 40
	local warningStroke = Theme.make("UIStroke", { Color = Color3.fromRGB(30, 4, 10), Thickness = 2, Transparency = 1 }, warning)

	-- Outer frame carries the screen-size fit; the inner group animates.
	local bannerHolder = Theme.make("Frame", {
		Name = "RedMoonBanner", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.15),
		Size = UDim2.fromOffset(600, 150), BackgroundTransparency = 1, ZIndex = 40,
	}, gui)
	local fitScale = Theme.make("UIScale", { Scale = 1 }, bannerHolder)
	local banner = Theme.make("CanvasGroup", {
		Name = "Reveal", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1, Visible = false, ZIndex = 40,
	}, bannerHolder)
	local bannerScale = Theme.make("UIScale", { Scale = 1 }, banner)
	local bannerMoon = Theme.image(banner, "Moon", VisualAssets.Icons.red_moon, UDim2.new(0.5, -32, 0, 0), UDim2.fromOffset(64, 64))
	local moonGlow = Theme.image(banner, "MoonGlow", VisualAssets.Textures.glow_soft, UDim2.new(0.5, -64, 0, -32), UDim2.fromOffset(128, 128), {
		ImageColor3 = CRIMSON, ImageTransparency = 0.4, ZIndex = 0,
	})
	local title = Theme.label(banner, "Title", "RED MOON RISING", UDim2.fromOffset(0, 62), UDim2.new(1, 0, 0, 52), 48, CRIMSON, F.display)
	title.TextXAlignment = Enum.TextXAlignment.Center
	Theme.make("UIStroke", { Color = Color3.fromRGB(28, 2, 8), Thickness = 2.5 }, title)
	local lines = {}
	for index, side in { -1, 1 } do
		local line = Theme.make("Frame", {
			Name = "Ornament" .. index, AnchorPoint = Vector2.new(if side < 0 then 1 else 0, 0.5),
			Position = UDim2.new(0.5, side * 40, 0, 32), Size = UDim2.fromOffset(0, 2),
			BackgroundColor3 = CRIMSON, BorderSizePixel = 0,
		}, banner)
		Theme.make("UIGradient", {
			Transparency = NumberSequence.new(if side < 0 then 1 else 0, if side < 0 then 0 else 1),
		}, line)
		lines[index] = line
	end
	local subtitle = Theme.label(banner, "Subtitle", "Mutated Curses are appearing.", UDim2.fromOffset(0, 116), UDim2.new(1, 0, 0, 22), 18, Color3.fromRGB(255, 214, 220), F.bold)
	subtitle.TextXAlignment = Enum.TextXAlignment.Center
	Theme.make("UIStroke", { Color = Color3.fromRGB(28, 2, 8), Thickness = 1.5, Transparency = 0.2 }, subtitle)

	-- Below HUD modals (ZIndex 20+) so an open panel always covers it.
	local indicator = Theme.make("Frame", {
		Name = "RedMoonIndicator", AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(218, 40),
		BackgroundColor3 = Color3.fromRGB(26, 6, 14), BackgroundTransparency = 0.1, BorderSizePixel = 0, Visible = false, ZIndex = 15,
	}, gui)
	Theme.corner(indicator, 12)
	local indicatorStroke = Theme.stroke(indicator, CRIMSON, 1.4, 0.2)
	local chipGlow = Theme.image(indicator, "Glow", VisualAssets.Textures.glow_soft, UDim2.fromOffset(-8, -8), UDim2.fromOffset(56, 56), {
		ImageColor3 = CRIMSON, ImageTransparency = 0.5, ZIndex = 15,
	})
	local chipMoon = Theme.image(indicator, "Moon", VisualAssets.Icons.red_moon, UDim2.fromOffset(8, 7), UDim2.fromOffset(26, 26), { ZIndex = 16 })
	local chipTitle = Theme.label(indicator, "Title", "RED MOON", UDim2.fromOffset(42, 4), UDim2.new(1, -50, 0, 16), 14, Color3.fromRGB(255, 120, 130), F.heavy)
	chipTitle.ZIndex = 16
	local chipDetail = Theme.label(indicator, "Detail", "Mutated Curses", UDim2.fromOffset(42, 20), UDim2.new(1, -50, 0, 14), 11, C.muted, F.medium)
	chipDetail.ZIndex = 16

	local function whisper(text: string, hold: number)
		warning.Text = text
		Theme.tween(warning, 0.8, { TextTransparency = 0.05 })
		Theme.tween(warningStroke, 0.8, { Transparency = 0.2 })
		task.delay(hold, function()
			if warning.Text ~= text then return end
			Theme.tween(warning, 1, { TextTransparency = 1 })
			Theme.tween(warningStroke, 1, { Transparency = 1 })
		end)
	end

	local bannerGeneration = 0
	local function announce()
		if ClientSettings.get("announcements") == "Minimal" then return end
		bannerGeneration += 1
		local generation = bannerGeneration
		warning.Text = ""
		banner.Visible = true
		banner.GroupTransparency = 1
		bannerScale.Scale = 1.12
		for _, line in lines do line.Size = UDim2.fromOffset(0, 2) end
		Theme.tween(banner, 0.5, { GroupTransparency = 0 })
		TweenService:Create(bannerScale, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		for _, line in lines do Theme.tween(line, 0.9, { Size = UDim2.fromOffset(150, 2) }) end
		moonGlow.ImageTransparency = 0.1
		Theme.tween(moonGlow, 1.4, { ImageTransparency = 0.45 })
		bannerMoon.Rotation = -12
		Theme.tween(bannerMoon, 1.2, { Rotation = 0 })
		task.delay(Config.AnnouncementSeconds, function()
			if generation ~= bannerGeneration then return end
			Theme.tween(banner, 0.7, { GroupTransparency = 1 })
			task.delay(0.75, function() if generation == bannerGeneration then banner.Visible = false end end)
		end)
	end

	local indicatorVisible = false
	local function setIndicator(visible: boolean)
		if indicatorVisible == visible then return end
		indicatorVisible = visible
		indicator.Visible = visible
		if requestFit then requestFit(visible) end
	end

	local state: Folder? = nil
	local lastAnnounced = nil
	local currentPhase = "OFF"
	local function onPhase()
		if not state then return end
		local phase = state:GetAttribute("Phase") or "OFF"
		local startsAt = state:GetAttribute("StartsAt")
		local previous = currentPhase
		currentPhase = phase
		gui:SetAttribute("RedMoonPhase", phase)
		if phase == "WARNING" then
			blendTo(0.12, Config.WarningSeconds)
			if ClientSettings.get("announcements") == "Full" then whisper("The moon stirs…", Config.WarningSeconds - 1) end
		elseif phase == "ACTIVE" then
			blendTo(1, if previous == "OFF" and workspace:GetServerTimeNow() - (startsAt or 0) > Config.RiseSeconds then 0.1 else Config.RiseSeconds)
			setIndicator(true)
			-- Announce once per window; late joiners mid-event get no banner.
			if lastAnnounced ~= startsAt and workspace:GetServerTimeNow() - (startsAt or 0) < 30 then
				lastAnnounced = startsAt
				task.delay(math.min(1.5, Config.RiseSeconds * 0.3), announce)
			end
		else
			setIndicator(false)
			if previous == "ACTIVE" or previous == "WARNING" then
				blendTo(0, Config.SetSeconds)
				if previous == "ACTIVE" and ClientSettings.get("announcements") == "Full" then whisper("The Red Moon sets.", 3) end
			else
				blendTo(0, 0.1)
			end
		end
	end

	-- Countdown + gentle pulse on the indicator.
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		if not indicatorVisible or not state then return end
		elapsed += dt
		if elapsed < 0.25 then return end
		elapsed = 0
		local remaining = math.max(0, (state:GetAttribute("EndsAt") or 0) - workspace:GetServerTimeNow())
		chipDetail.Text = string.format("Mutated Curses  ·  %d:%02d", remaining // 60, remaining % 60)
		local t = os.clock()
		chipGlow.ImageTransparency = 0.5 + 0.15 * math.sin(t * 2.2)
		indicatorStroke.Transparency = 0.2 + 0.15 * math.sin(t * 2.2)
	end)

	task.spawn(function()
		state = ReplicatedStorage:WaitForChild("RedMoonState", 60)
		if not state then return end
		state:GetAttributeChangedSignal("Phase"):Connect(onPhase)
		onPhase()
	end)

	local controller = {}
	-- HUD applies the eventChip rect from HudLayout (top of the centre lane).
	function controller.fit(rect: { x: number, y: number, w: number, h: number }, compact: boolean)
		indicator.AnchorPoint = Vector2.zero
		indicator.Position = UDim2.fromOffset(rect.x, rect.y)
		indicator.Size = UDim2.fromOffset(rect.w, rect.h)
		-- Narrow phone lanes drop the moon glyph so the countdown keeps its room.
		local narrow = rect.w < 200
		local textX = if narrow then 10 else 42
		chipMoon.Visible = not narrow
		chipGlow.Visible = not narrow
		chipTitle.Position = UDim2.fromOffset(textX, 4)
		chipTitle.Size = UDim2.new(1, -(textX + 8), 0, 16)
		chipDetail.Position = UDim2.fromOffset(textX, 20)
		chipDetail.Size = UDim2.new(1, -(textX + 8), 0, 14)
		local safeWidth = gui.AbsoluteSize.X
		fitScale.Scale = math.min(1, safeWidth / 680)
		warning.TextSize = if compact then 22 else 28
	end
	function controller.phase(): string return currentPhase end
	return controller
end

return RedMoonPresentation
