-- World presence for progression: Mortimer the Gravekeeper (mission NPC) and
-- the Wheel of Fate. Placed beside the existing gravekeeper board, grounded
-- by raycast. Pure presentation + ProximityPrompts; rules live server-side in
-- ProgressionService. Simple collision hulls, no mesh collision.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.ProgressionConfig)

local World = {}

local INK = Color3.fromRGB(22, 18, 30)
local COAT = Color3.fromRGB(46, 38, 58)
local SKIN = Color3.fromRGB(196, 182, 168)
local BRASS = Color3.fromRGB(176, 128, 60)
local STONE = Color3.fromRGB(70, 64, 84)

local function ground(at: Vector3, ignore): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.RespectCanCollide = true
	local hit = workspace:Raycast(at + Vector3.new(0, 40, 0), Vector3.new(0, -90, 0), params)
	return if hit then hit.Position else at
end

local function part(parent, name, size, cframe, color, material, props)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props or {} do p[k] = v end
	p.Parent = parent
	return p
end

local function hull(parent, name, size, cframe)
	local h = part(parent, name, size, cframe, Color3.new(), Enum.Material.SmoothPlastic, { Transparency = 1, CanCollide = true, CanQuery = true, CastShadow = false })
	h:SetAttribute("EnvironmentCollisionHull", true)
	h:SetAttribute("CollisionSource", name)
	return h
end

local function weldTo(base: BasePart, p: BasePart)
	p.Anchored = false
	p.Massless = true
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = base, p
	w.Parent = p
end

function World.buildNpc(map: Model, board: BasePart)
	local folder = Instance.new("Model")
	folder.Name = "MortimerTheGravekeeper"
	local spot = board.Position + board.CFrame.RightVector * -7 + board.CFrame.LookVector * 3
	local floor = ground(spot, { map:FindFirstChild("ActiveCurses"), board.Parent })
	local description = Instance.new("HumanoidDescription")
	description.HeadColor, description.LeftArmColor, description.RightArmColor = SKIN, SKIN, SKIN
	description.TorsoColor, description.LeftLegColor, description.RightLegColor = COAT, INK, INK
	description.HeightScale, description.WidthScale, description.DepthScale = 1.08, 0.92, 0.9
	local ok, npc = pcall(function() return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15) end)
	if not ok or not npc then warn("Mortimer could not be built: " .. tostring(npc)) return nil end
	npc.Name = "Mortimer"
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.MaxHealth, humanoid.Health = math.huge, math.huge
	local root = npc:FindFirstChild("HumanoidRootPart")
	local facing = board.CFrame.LookVector
	local hipHeight = humanoid.HipHeight + root.Size.Y * 0.5
	npc:PivotTo(CFrame.lookAt(floor + Vector3.new(0, hipHeight, 0), floor + Vector3.new(0, hipHeight, 0) + Vector3.new(facing.X, 0, facing.Z)))
	for _, p in npc:GetDescendants() do if p:IsA("BasePart") then p.Anchored = true p.CanCollide = false end end
	npc:SetAttribute("ProgressionNpc", true)
	-- Silhouette: tall crooked top hat, long coat tails, lantern, shovel on back.
	local head = npc:FindFirstChild("Head")
	local torso = npc:FindFirstChild("UpperTorso")
	local lower = npc:FindFirstChild("LowerTorso")
	local hand = npc:FindFirstChild("RightHand")
	if head then
		local brim = part(npc, "HatBrim", Vector3.new(0.18, 2.3, 2.3), head.CFrame * CFrame.new(0, 0.62, 0), INK, Enum.Material.Fabric, { Shape = Enum.PartType.Cylinder })
		brim.CFrame = head.CFrame * CFrame.new(0, 0.62, 0) * CFrame.Angles(0, 0, math.pi / 2)
		local crown = part(npc, "HatCrown", Vector3.new(1.4, 1.5, 1.4), head.CFrame * CFrame.new(0.05, 1.42, 0) * CFrame.Angles(0, 0, math.rad(-6)), INK, Enum.Material.Fabric)
		part(npc, "HatBand", Vector3.new(1.45, 0.22, 1.45), crown.CFrame * CFrame.new(0, -0.55, 0), Color3.fromRGB(120, 40, 60), Enum.Material.Fabric)
		local eyeL = part(npc, "EyeGlowL", Vector3.new(0.16, 0.12, 0.05), head.CFrame * CFrame.new(-0.22, 0.12, -0.6), Color3.fromRGB(150, 255, 230), Enum.Material.Neon)
		local eyeR = part(npc, "EyeGlowR", Vector3.new(0.16, 0.12, 0.05), head.CFrame * CFrame.new(0.22, 0.12, -0.6), Color3.fromRGB(150, 255, 230), Enum.Material.Neon)
		for _, p in { brim, crown, eyeL, eyeR } do p.CanQuery = false end
	end
	if lower then
		part(npc, "CoatTails", Vector3.new(2.1, 2.1, 1.25), lower.CFrame * CFrame.new(0, -1.2, 0.05), COAT, Enum.Material.Fabric)
		part(npc, "CoatCollar", Vector3.new(2.3, 0.6, 1.3), (torso or lower).CFrame * CFrame.new(0, 0.85, 0), COAT, Enum.Material.Fabric)
	end
	if torso then
		local shaft = part(npc, "BackShovelShaft", Vector3.new(0.2, 4.2, 0.2), torso.CFrame * CFrame.new(0.4, 0.4, 0.75) * CFrame.Angles(0, 0, math.rad(22)), Color3.fromRGB(92, 58, 34), Enum.Material.Wood)
		part(npc, "BackShovelBlade", Vector3.new(0.95, 1.1, 0.12), shaft.CFrame * CFrame.new(0, 2.3, 0), Color3.fromRGB(120, 126, 136), Enum.Material.Metal)
	end
	if hand then
		local lamp = part(npc, "Lantern", Vector3.new(0.7, 0.95, 0.7), hand.CFrame * CFrame.new(0, -0.9, -0.2), Color3.fromRGB(140, 230, 210), Enum.Material.Neon, { Transparency = 0.25 })
		part(npc, "LanternCap", Vector3.new(0.85, 0.2, 0.85), lamp.CFrame * CFrame.new(0, 0.55, 0), BRASS, Enum.Material.Metal)
		part(npc, "LanternBase", Vector3.new(0.85, 0.16, 0.85), lamp.CFrame * CFrame.new(0, -0.55, 0), BRASS, Enum.Material.Metal)
		local light = Instance.new("PointLight")
		light.Color, light.Range, light.Brightness, light.Shadows = Color3.fromRGB(150, 240, 220), 14, 1.4, false
		light.Parent = lamp
	end
	-- Accessories follow animated limbs (client animator writes Motor transforms).
	local extras = { HatBrim = true, HatCrown = true, HatBand = true, EyeGlowL = true, EyeGlowR = true, CoatTails = true, CoatCollar = true,
		BackShovelShaft = true, BackShovelBlade = true, Lantern = true, LanternCap = true, LanternBase = true }
	for _, p in npc:GetChildren() do
		if p:IsA("BasePart") and extras[p.Name] then
			local anchorPart = if string.find(p.Name, "Hat") or string.find(p.Name, "Eye") then head
				elseif string.find(p.Name, "Lantern") then hand
				elseif string.find(p.Name, "Coat") then lower
				else torso
			if anchorPart then weldTo(anchorPart, p) end
		end
	end
	for _, p in npc:GetDescendants() do if p:IsA("BasePart") and p ~= root then p.Anchored = false end end
	root.Anchored = true
	hull(folder, "MortimerHull", Vector3.new(2.2, 6, 2), root.CFrame * CFrame.new(0, -0.3, 0))
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TalkToMortimer"
	prompt.ActionText = "Talk"
	prompt.ObjectText = Config.NpcName
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.UIOffset = Vector2.new(0, 60)
	prompt.Parent = root
	npc.Parent = folder
	folder.Parent = map
	return npc, root.Position
end

function World.buildWheel(map: Model, near: Vector3, facing: Vector3)
	local model = Instance.new("Model")
	model.Name = "WheelOfFate"
	local floor = ground(near, { map:FindFirstChild("ActiveCurses") })
	local yaw = CFrame.lookAt(floor, floor + Vector3.new(facing.X, 0, facing.Z))
	local base = part(model, "Plinth", Vector3.new(9, 1.2, 4), yaw * CFrame.new(0, 0.6, 0), STONE, Enum.Material.Slate)
	part(model, "PlinthStep", Vector3.new(10.5, 0.5, 5.5), yaw * CFrame.new(0, 0.25, 0), Color3.fromRGB(56, 50, 68), Enum.Material.Slate)
	for side = -1, 1, 2 do
		part(model, "Pillar", Vector3.new(1.2, 10, 1.2), yaw * CFrame.new(side * 4.6, 6, 0), STONE, Enum.Material.Slate)
		local cap = part(model, "PillarSkull", Vector3.new(1.4, 1.2, 1.3), yaw * CFrame.new(side * 4.6, 11.6, 0), Color3.fromRGB(226, 214, 188), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Ball })
		cap.Size = Vector3.new(1.5, 1.5, 1.5)
		local candle = part(model, "Candle", Vector3.new(0.4, 0.9, 0.4), yaw * CFrame.new(side * 3.6, 1.65, -1.4), Color3.fromRGB(230, 214, 176), Enum.Material.SmoothPlastic)
		local flame = part(model, "CandleFlame", Vector3.new(0.25, 0.45, 0.25), candle.CFrame * CFrame.new(0, 0.7, 0), Color3.fromRGB(255, 190, 110), Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Color, light.Range, light.Brightness, light.Shadows = Color3.fromRGB(255, 170, 100), 8, 0.8, false
		light.Parent = flame
	end
	part(model, "Axle", Vector3.new(9.2, 0.6, 0.6), yaw * CFrame.new(0, 6.5, 0), Color3.fromRGB(60, 56, 70), Enum.Material.Metal)
	-- The rotating face: a thin disc whose SurfaceGui draws the real sectors.
	local face = part(model, "WheelFace", Vector3.new(0.5, 8, 8), yaw * CFrame.new(0, 6.5, -0.5) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(28, 22, 40), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
	face:SetAttribute("BaseCFrame", face.CFrame)
	part(model, "WheelRim", Vector3.new(0.6, 8.4, 8.4), face.CFrame * CFrame.new(-0.05, 0, 0), BRASS, Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
	local pointer = part(model, "Pointer", Vector3.new(0.9, 1.4, 0.5), yaw * CFrame.new(0, 11.1, -0.9) * CFrame.Angles(0, 0, math.rad(45)), Color3.fromRGB(240, 70, 90), Enum.Material.Neon)
	pointer.Size = Vector3.new(0.9, 0.9, 0.4)
	hull(model, "WheelHull", Vector3.new(10.5, 12, 4), yaw * CFrame.new(0, 6, 0))
	local sign = Instance.new("BillboardGui")
	sign.Name = "WheelSign"
	sign.Size = UDim2.fromOffset(220, 40)
	sign.StudsOffsetWorldSpace = Vector3.new(0, 13.6, 0)
	sign.MaxDistance = 90
	sign.LightInfluence = 0
	sign.Adornee = base
	sign.Parent = model
	local label = Instance.new("TextLabel")
	label.Name = "Title"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = string.upper(Config.Wheel.Name)
	label.TextColor3 = Color3.fromRGB(255, 220, 160)
	label.TextStrokeTransparency = 0.3
	label.TextScaled = true
	label.FontFace = Font.new("rbxasset://fonts/families/GrenzeGotisch.json", Enum.FontWeight.Bold)
	label.Parent = sign
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SpinWheel"
	prompt.ActionText = "Spin"
	prompt.ObjectText = Config.Wheel.Name
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = base
	model.PrimaryPart = base
	model.Parent = map
	return model, base.Position
end

return World
