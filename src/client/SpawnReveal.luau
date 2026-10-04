-- Client-only reveal when a Curse joins the procession. Strength scales with
-- rarity: COMMON is a quiet rune puff, RARE adds a flash, LEGENDARY+ add a
-- light column, a notice and (near the player) a short screen tint.
-- Reads CurseId / CurseState on ActiveCurses models; changes nothing.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Catalog = require(ReplicatedStorage.Shared.CurseCatalog)
local VisualAssets = require(ReplicatedStorage.Shared.VisualAssets)
local Notify = require(script.Parent.UI.Notify)

local SpawnReveal = {}

local TIERS = {
	COMMON = { ring = 7, column = 0, flash = 0, motes = 10, seconds = 1.6 },
	RARE = { ring = 10, column = 0, flash = 6, motes = 18, seconds = 2 },
	LEGENDARY = { ring = 14, column = 26, flash = 10, motes = 30, seconds = 3, announce = true },
	MYTHIC = { ring = 18, column = 36, flash = 14, motes = 44, seconds = 3.4, announce = true, tint = 0.82 },
	SECRET = { ring = 22, column = 48, flash = 18, motes = 60, seconds = 4, announce = true, tint = 0.72 },
}
local RANGE = 260 -- studs from the camera; farther spawns stay quiet

local function tween(object, seconds, goals, style)
	local t = TweenService:Create(object, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goals)
	t:Play()
	return t
end

local function anchorPart(name, cframe, size)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery, part.CastShadow = true, false, false, false, false
	part.Transparency = 1
	part.Size = size
	part.CFrame = cframe
	return part
end

local function reveal(model: Model, gui: ScreenGui)
	local definition = Catalog.Definitions[model:GetAttribute("CurseId")]
	local root = model.PrimaryPart or model:FindFirstChild("CurseMesh")
	if not definition or not root then return end
	local rarity = Catalog.Rarities[definition.rarity]
	local tier = TIERS[definition.rarity] or TIERS.COMMON
	local camera = workspace.CurrentCamera
	if not camera or (camera.CFrame.Position - root.Position).Magnitude > RANGE then return end
	-- Ground under the Curse (chapel floor first, then the path outside).
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model.Parent, camera }
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -30, 0), params)
	local floorY = if hit then hit.Position.Y else root.Position.Y - root.Size.Y * 0.5
	local ground = Vector3.new(root.Position.X, floorY, root.Position.Z)
	local holder = Instance.new("Folder")
	holder.Name = "SpawnReveal"
	holder.Parent = camera -- local-only; keeps the map tree untouched

	-- Rune ring on the ground, expanding and spinning out.
	local base = anchorPart("Ring", CFrame.new(ground + Vector3.new(0, 0.08, 0)), Vector3.new(1, 0.05, 1))
	base.Parent = holder
	local decal = Instance.new("Decal")
	decal.Face = Enum.NormalId.Top
	decal.Texture = VisualAssets.Textures.rune_ring
	decal.Color3 = rarity.glow
	decal.Transparency = 0.05
	decal.Parent = base
	tween(base, tier.seconds, { Size = Vector3.new(tier.ring, 0.05, tier.ring) })
	task.delay(tier.seconds * 0.5, function() tween(decal, tier.seconds * 0.5, { Transparency = 1 }, Enum.EasingStyle.Sine) end)

	-- Rising motes in the rarity colour.
	local emitterPart = anchorPart("Motes", CFrame.new(ground + Vector3.new(0, 0.5, 0)), Vector3.new(tier.ring * 0.5, 0.2, tier.ring * 0.5))
	emitterPart.Parent = holder
	local motes = Instance.new("ParticleEmitter")
	motes.Texture = VisualAssets.Textures.mote
	motes.Color = ColorSequence.new(rarity.color, rarity.glow)
	motes.LightEmission = 1
	motes.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	motes.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	motes.Lifetime = NumberRange.new(0.8, 1.6)
	motes.Speed = NumberRange.new(4, 10)
	motes.SpreadAngle = Vector2.new(18, 18)
	motes.EmissionDirection = Enum.NormalId.Top
	motes.Rate = tier.motes / tier.seconds
	motes.Parent = emitterPart
	motes:Emit(math.ceil(tier.motes * 0.5))
	task.delay(tier.seconds * 0.7, function() motes.Enabled = false end)

	-- Flash of light at the body.
	if tier.flash > 0 then
		local light = Instance.new("PointLight")
		light.Color = rarity.glow
		light.Range = tier.flash
		light.Brightness = 4
		light.Shadows = false
		light.Parent = emitterPart
		tween(light, tier.seconds, { Brightness = 0 })
	end

	-- Column of light for the rare tiers.
	if tier.column > 0 then
		local column = anchorPart("Column", CFrame.new(ground + Vector3.new(0, tier.column * 0.5, 0)), Vector3.new(1, tier.column, 1))
		column.Parent = holder
		local top = Instance.new("Attachment")
		top.Position = Vector3.new(0, tier.column * 0.5, 0)
		top.Parent = column
		local bottom = Instance.new("Attachment")
		bottom.Position = Vector3.new(0, -tier.column * 0.5, 0)
		bottom.Parent = column
		local beam = Instance.new("Beam")
		beam.Attachment0, beam.Attachment1 = bottom, top
		beam.Texture = VisualAssets.Textures.streak
		beam.TextureMode = Enum.TextureMode.Stretch
		beam.Color = ColorSequence.new(rarity.color, rarity.glow)
		beam.LightEmission = 1
		beam.FaceCamera = true
		beam.Width0, beam.Width1 = tier.ring * 0.35, tier.ring * 0.08
		beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 0.9) })
		beam.Parent = column
		local fade = Instance.new("NumberValue")
		fade.Value = 0.1
		fade.Changed:Connect(function(v)
			beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, v), NumberSequenceKeypoint.new(1, math.max(v, 0.9)) })
		end)
		task.delay(tier.seconds * 0.4, function() tween(fade, tier.seconds * 0.6, { Value = 1 }) end)
		Debris:AddItem(fade, tier.seconds + 0.2)
	end

	-- Curses enter from inside the chapel: the reveal rides along with the
	-- walking Curse so it is seen as it steps out.
	local started = os.clock()
	local follow
	follow = RunService.Heartbeat:Connect(function()
		local t = os.clock() - started
		if t > tier.seconds + 0.5 or not model.Parent or not holder.Parent then follow:Disconnect() return end
		local p = model:GetPivot().Position
		local below = workspace:Raycast(p, Vector3.new(0, -30, 0), params)
		if below then floorY = below.Position.Y end
		local g = Vector3.new(p.X, floorY, p.Z)
		base.CFrame = CFrame.new(g + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, t * math.rad(120) / tier.seconds, 0)
		emitterPart.CFrame = CFrame.new(g + Vector3.new(0, 0.5, 0))
		local column = holder:FindFirstChild("Column")
		if column then column.CFrame = CFrame.new(g + Vector3.new(0, tier.column * 0.5, 0)) end
	end)

	if tier.announce then
		Notify.push(rarity.label .. " Curse appeared: " .. definition.displayName, "good")
		local character = Players.LocalPlayer.Character
		local body = character and character:FindFirstChild("HumanoidRootPart")
		if tier.tint and body and (body.Position - root.Position).Magnitude < 120 then
			local tint = Instance.new("Frame")
			tint.Name = "RevealTint"
			tint.Size = UDim2.fromScale(1, 1)
			tint.BorderSizePixel = 0
			tint.BackgroundColor3 = rarity.glow
			tint.BackgroundTransparency = 1
			tint.Parent = gui
			local glow = Instance.new("UIGradient")
			glow.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.25, 1), NumberSequenceKeypoint.new(0.75, 1), NumberSequenceKeypoint.new(1, 0) })
			glow.Parent = tint
			tween(tint, 0.25, { BackgroundTransparency = tier.tint })
			task.delay(0.35, function() tween(tint, 0.9, { BackgroundTransparency = 1 }) end)
			Debris:AddItem(tint, 1.5)
		end
	end
	Debris:AddItem(holder, tier.seconds + 2)
end

function SpawnReveal.start()
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "SpawnRevealUI"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	gui.Parent = player:WaitForChild("PlayerGui")
	local map = workspace:WaitForChild("StealACurseMap")
	local folder = map:WaitForChild("ActiveCurses")
	-- Curses already walking when we join are not "new": only reveal later ones.
	local ready = false
	task.delay(3, function() ready = true end)
	folder.ChildAdded:Connect(function(model)
		if not ready or not model:IsA("Model") then return end
		-- Attributes and PrimaryPart are set while the model streams in.
		task.delay(0.15, function()
			if model.Parent == folder and model:GetAttribute("CurseState") == "PROCESSION" then
				reveal(model, gui)
			end
		end)
	end)
end

return SpawnReveal
