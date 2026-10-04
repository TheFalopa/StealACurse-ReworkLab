local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Profiles = require(ReplicatedStorage.Shared.CurseVFXProfiles)
local Kit = require(script.Parent.VFX.Kit)
local Heroes = require(script.Parent.VFX.Heroes)
local Mutations = require(script.Parent.VFX.Mutations)
local ClientSettings = require(script.Parent.UI.ClientSettings)

local VFX = {}
local tracked = {}
local pending = {}
local started = false
local elapsed, budgetElapsed = 0, 0
local mobile = UserInputService.TouchEnabled
local smoke = "rbxasset://textures/particles/smoke_main.dds"
local spark = "rbxasset://textures/particles/sparkles_main.dds"

local function poseBinding(root,point)
	local nearest,distance
	for _,bone in root:GetDescendants() do
		if bone:IsA('Bone') then
			local rest=root.CFrame:ToObjectSpace(bone.WorldCFrame)
			local d=(rest.Position-point).Magnitude
			if not distance or d<distance then nearest={bone=bone,rest=rest};distance=d end
		end
	end
	return nearest
end

local function tryAdd(model)
	local root = model:FindFirstChild("CurseMesh")
	local hook = root and root:FindFirstChild("CurseVFXHook")
	local profile = Profiles.Definitions[model:GetAttribute("CurseId")]
	if not root or not hook or not profile then return false end
	if model:GetAttribute("CurseId") == "thorn_reliquary" and not root:FindFirstChild("VFX_urnCenter") then return false end
	local hero = Heroes[model:GetAttribute("CurseId")]
	if hero then
		-- Authored effect replaces the generic profile layer entirely.
		local fx = Kit.new(model, root)
		local ok, controller = pcall(hero, fx)
		if ok then
			tracked[model] = { root = root, hook = hook, profile = profile, near = false, hero = fx, controller = controller }
			return true
		end
		-- Never leave a half-built effect behind; fall back to the profile layer.
		fx:destroy()
		warn("Hero VFX failed for " .. tostring(model:GetAttribute("CurseId")) .. ": " .. tostring(controller))
	end
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "ConceptParticles"
	emitter.Texture = if profile.kind == "mist" or profile.kind == "steam" or profile.kind == "flame" then smoke else spark
	emitter.Color = ColorSequence.new(profile.color)
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(profile.lifetime * 0.7, profile.lifetime)
	emitter.Speed = NumberRange.new(profile.speed * 0.7, profile.speed)
	emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, profile.size * 0.35), NumberSequenceKeypoint.new(0.25, profile.size), NumberSequenceKeypoint.new(1, 0)})
	emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(0.2, if profile.kind == "mist" then 0.65 else 0.25), NumberSequenceKeypoint.new(1, 1)})
	emitter.LightEmission = if profile.kind == "ash" or profile.kind == "drop" or profile.kind == "rising_drop" or profile.kind == "sand" then 0.05 else 0.65
	emitter.LightInfluence = 0.25
	emitter.LockedToPart = profile.kind ~= "ash" and profile.kind ~= "drop"
	emitter.SpreadAngle = Vector2.new(18, 18)
	emitter.Rotation = NumberRange.new(-35, 35)
	emitter.RotSpeed = NumberRange.new(-15, 15)
	if profile.kind == "rising_drop" then
		emitter.EmissionDirection = Enum.NormalId.Top
		emitter.Acceleration = Vector3.new(0, 0.4, 0)
		emitter.Orientation = Enum.ParticleOrientation.VelocityParallel
	elseif profile.kind == "drop" or profile.kind == "sand" then
		emitter.EmissionDirection = Enum.NormalId.Bottom
		emitter.Acceleration = Vector3.new(0, -1.1, 0)
		emitter.Orientation = Enum.ParticleOrientation.VelocityParallel
	elseif profile.kind == "steam" or profile.kind == "flame" then
		emitter.Acceleration = Vector3.new(0.06, 0.25, 0)
	elseif profile.kind == "dust" or profile.kind == "ash" then
		emitter.SpreadAngle = Vector2.new(85, 85)
		emitter.Acceleration = Vector3.new(0.12, 0.02, 0)
	end
	emitter.Parent = hook
	local light
	if profile.light > 0 then
		light = Instance.new("PointLight")
		light.Name = "ConceptLight"
		light.Color = profile.color
		light.Range = 4
		light.Brightness = 0
		light.Shadows = false
		light.Parent = hook
	end
	local mote = Instance.new("SphereHandleAdornment")
	mote.Name = "ConceptFocus"
	mote.Adornee = root
	mote.Radius = if profile.motion == "rift" then 0.09 elseif profile.kind == "mist" or profile.kind == "ash" then 0.035 else 0.055
	mote.Color3 = profile.color
	mote.Transparency = 0.5
	mote.CFrame = CFrame.new(hook.Position)
	mote.Visible = false
	mote.AlwaysOnTop = false
	mote.ZIndex = 0
	mote.Parent = hook
	local panes = {}
	local presentationScale = (model:GetAttribute("PresentationScale") or 1) * (model:GetAttribute("VFXGeometryScale") or 1)
	if model:GetAttribute("CurseId") == "thorn_reliquary" then
		local center = root:FindFirstChild("VFX_urnCenter")
		if center then
			for side = 0, 3 do
				local pane = Instance.new("Part")
				pane.Name = "ReliquaryGlass_" .. side
				pane.Size = Vector3.new(1.00, 2.10, 0.025) * presentationScale
				pane.Material = Enum.Material.Glass
				pane.Color = Color3.fromRGB(139, 196, 173)
				pane.Transparency = 0.87
				pane.Reflectance = 0.08
				pane.Anchored = true
				pane.CanCollide = false
				pane.CanTouch = false
				pane.CanQuery = false
				pane.CastShadow = false
				local offset = CFrame.new(center.Position) * CFrame.Angles(0, side * math.pi / 2, 0) * CFrame.new(0, 0, 0.70 * presentationScale)
				pane.CFrame = root.CFrame * offset
				pane.Parent = hook
				table.insert(panes, {part = pane, offset = offset})
			end
		end
	end
	local bindings={}
	for _,attachment in root:GetChildren() do
		if attachment:IsA('Attachment') and not attachment:IsA('Bone') then
			bindings[attachment]=poseBinding(root,attachment.Position)
		end
	end
	tracked[model] = { root = root, hook = hook, origin = hook.Position, emitter = emitter,
		bindings=bindings,requestedPoint=hook.Position,
		light = light, mote = mote, panes = panes, profile = profile, near = false,
		baseRate = 0, rateMultiplier = 1,
		phase = root.Size.X * 1.7 + root.Size.Y * 0.9 }
	return true
end

local function add(model)
	if tracked[model] or pending[model] or not model:IsA("Model") then return end
	if not model:IsDescendantOf(workspace) or not CollectionService:HasTag(model, "ExpansionCurseVFX") then return end
	if tryAdd(model) then return end
	-- Tags can arrive before their descendants; keep one short retry per model.
	local token = {}
	pending[model] = token
	task.spawn(function()
		local deadline = os.clock() + 5
		for attempt = 1, 20 do
			task.wait(if attempt == 1 then 0.1 else 0.25)
			if pending[model] ~= token then return end
			if os.clock() >= deadline or not model:IsDescendantOf(workspace)
				or not CollectionService:HasTag(model, "ExpansionCurseVFX") then break end
			if tryAdd(model) then break end
		end
		if pending[model] == token then pending[model] = nil end
	end)
end

local function remove(model)
	pending[model] = nil
	local entry = tracked[model]
	if not entry then return end
	if entry.mutation then entry.mutation.fx:destroy() entry.mutation = nil end
	if entry.hero then
		entry.hero:destroy()
		tracked[model] = nil
		return
	end
	entry.emitter:Destroy()
	entry.mote:Destroy()
	for _, pane in entry.panes do pane.part:Destroy() end
	if entry.light then entry.light:Destroy() end
	tracked[model] = nil
end

local function setEmission(entry, multiplier)
	entry.rateMultiplier = multiplier
	entry.emitter.Rate = if entry.near then entry.baseRate * multiplier else 0
	entry.mote.Visible = entry.near and multiplier > 0
end

local function budgets()
	mobile = UserInputService.TouchEnabled
	local camera = workspace.CurrentCamera
	if not camera then return end
	local ordered = {}
	for model, entry in tracked do
		if not model:IsDescendantOf(workspace) then remove(model) else
			entry.distance = (entry.root.Position - camera.CFrame.Position).Magnitude
			table.insert(ordered, entry)
		end
	end
	table.sort(ordered, function(a, b) return a.distance < b.distance end)
	local lights, live = 0, 0
	-- Player preference (Settings > Curse effects) and Red Moon intensity.
	local reduced = ClientSettings.get("vfxQuality") == "Reduced"
	local cap = if reduced then (if mobile then 6 else 8) else (if mobile then 12 else 20)
	local redMoon = ReplicatedStorage:FindFirstChild("RedMoonState")
	local redMoonActive = redMoon ~= nil and redMoon:GetAttribute("Phase") == "ACTIVE"
	for _, entry in ordered do
		local close = entry.distance < (if mobile then 58 else 85)
		local tier = (if entry.distance < 38 then 1 else 0.4) * (if reduced then 0.6 else 1)
		-- Mutation accent layer (model attribute "Mutation"), rebuilt on change.
		local model = entry.root.Parent
		local kind = Mutations.kind(model)
		if kind ~= (entry.mutation and entry.mutation.kind) then
			if entry.mutation then entry.mutation.fx:destroy() end
			entry.mutation = if kind then Mutations.build(model, entry.root) else nil
		end
		if entry.mutation then
			local on = close and live < cap
			local mutationLight = on and entry.distance < 40 and lights < 2 and not mobile and not reduced
			if entry.mutation.fx:setActive(on, tier, mobile, mutationLight) then lights += 1 end
			if redMoonActive then entry.mutation.fx:boost(1.5) end
		end
		if entry.hero then
			local on = close and live < cap
			if on then live += 1 end
			entry.near = on
			local allowLight = on and entry.distance < 40 and lights < 2 and not mobile and not reduced
			if entry.hero:setActive(on, tier, mobile, allowLight) then lights += 1 end
			continue
		end
		if close and live < cap then
			live += 1
			entry.near = true
			entry.baseRate = entry.profile.rate * tier * (if mobile then 0.7 else 1)
		else
			entry.near = false
			entry.baseRate = 0
		end
		setEmission(entry, entry.rateMultiplier)
		for _, pane in entry.panes do pane.part.Transparency = if entry.near then 0.87 else 1 end
		if entry.light then
			local on = entry.near and entry.distance < 32 and lights < 2 and not mobile and not reduced
			entry.light.Enabled = on
			if on then lights += 1 end
		end
	end
end

local function animate(entry, time)
	local p = entry.profile
	local t = time + entry.phase
	local offset = Vector3.zero
	local pulse = 0.5 + 0.5 * math.sin(t * 2)
	local rateMultiplier = 1
	local semanticHook
	if p.motion == "rift" then
		-- A sparse cold trail follows the actual tall aperture. The visible
		-- geometry remains empty; there is no glowing sphere over its center.
		local boundary = Vector3.new(math.cos(t * 0.65) * entry.root.Size.X * 0.24,
			math.sin(t * 0.65) * entry.root.Size.Y * 0.31, entry.root.Size.Z * 0.55)
		offset = boundary - entry.origin
		pulse = 0.65 + 0.2 * math.sin(t * 1.3)
	elseif p.motion == "orbit" or p.motion == "vortex" then
		local radius = if p.motion == "vortex" then 0.22 else 0.10
		offset = Vector3.new(math.cos(t * 1.3) * radius, math.sin(t * 0.8) * 0.045, math.sin(t * 1.3) * radius)
	elseif p.motion == "sway" or p.motion == "strings" then
		offset = Vector3.new(math.sin(t * 1.6) * 0.075, math.cos(t) * 0.025, 0)
	elseif p.motion == "chime" then
		offset = Vector3.new(math.sin(t * 2.3) * 0.16, 0, 0)
		local names = { "VFX_leftBell", "VFX_middleBell", "VFX_rightBell" }
		local bell = entry.root:FindFirstChild(names[math.floor(t) % 3 + 1])
		if bell then offset += bell.Position - entry.origin end
	elseif p.motion == "choir" then
		local names = { "VFX_leftHead", "VFX_middleHead", "VFX_rightHead" }
		semanticHook = entry.root:FindFirstChild(names[math.floor(t) % 3 + 1])
		if semanticHook then offset = semanticHook.Position - entry.origin + Vector3.new(math.sin(t * 1.6) * 0.03, 0, 0) end
	elseif p.motion == "scales" then
		semanticHook = entry.root:FindFirstChild(if math.floor(t / 1.6) % 2 == 0 then "VFX_leftPan" else "VFX_rightPan")
		if semanticHook then offset = semanticHook.Position - entry.origin + Vector3.new(0, math.sin(t * 1.4) * 0.025, 0) end
	elseif p.motion == "gramophone" then
		local record = t % 4 >= 3
		semanticHook = entry.root:FindFirstChild(if record then "VFX_turntable" else "VFX_hornMouth")
		if semanticHook then
			local detailOffset = if record then Vector3.new(math.cos(t * math.pi * 2) * 0.62, 0.025, math.sin(t * math.pi * 2) * 0.62)
				else Vector3.new(math.sin(t * 1.5) * 0.035, math.cos(t * 2) * 0.02, 0)
			offset = semanticHook.Position - entry.origin + detailOffset
		end
	elseif p.motion == "step" then
		offset = Vector3.new(math.sin(t * 3) * 0.17, -0.03, 0)
		local cuff = entry.root:FindFirstChild(if math.floor(t * 2) % 2 == 0 then "VFX_leftCuff" else "VFX_rightCuff")
		if cuff then
			offset = Vector3.new(cuff.Position.X, -entry.root.Size.Y * 0.5 + 0.06, cuff.Position.Z) - entry.origin
		end
	elseif p.motion == "flicker" then
		pulse = 0.65 + 0.15 * math.sin(t * 7) + 0.1 * math.sin(t * 11)
	elseif p.motion == "heartbeat" then
		pulse = math.max(0, math.sin(t * 2.2)) ^ 6
		rateMultiplier = 0.65 + 0.95 * pulse
	elseif p.motion == "tick" then
		local beat = t % 1 < 0.15
		pulse = if beat then 0.9 else 0.15
		rateMultiplier = if beat then 1.6 else 0.65
	elseif p.motion == "silence" or p.motion == "erase" then
		local quiet = t % 3.5 < 1.2
		pulse = if quiet then 0 else 0.5 + 0.5 * math.sin(t * 2)
		rateMultiplier = if quiet then 0 else 1
	elseif p.motion == "star" then
		pulse = 0.65 + 0.25 * math.sin(t * 1.3)
	end
	if semanticHook and entry.semanticHook ~= semanticHook then
		-- Locked particles follow their attachment; clear the old phrase before
		-- selecting another head, pan or instrument component.
		entry.emitter:Clear()
		entry.semanticHook = semanticHook
	end
	entry.requestedPoint=entry.origin+offset
	entry.selectedHook=semanticHook or entry.hook
	entry.mote.Transparency = 0.35 + (1 - pulse) * 0.5
	setEmission(entry, rateMultiplier)
	if entry.light then entry.light.Brightness = p.light * (0.65 + pulse * 0.35) end
end

function VFX.render()
	local now = workspace.DistributedGameTime
	for _, entry in tracked do
		if entry.mutation and entry.mutation.fx.active then entry.mutation.fx:render() end
		if entry.hero then
			if entry.near then
				entry.hero:render()
				if entry.controller and entry.controller.frame then entry.controller.frame(now) end
			end
		elseif entry.near then
			-- Bone poses never move the authority anchor. Resolve the authored VFX
			-- point through the current decorative pose after the shared animator.
			local point=entry.requestedPoint
			local binding=entry.bindings[entry.selectedHook or entry.hook]
			if binding and binding.bone.Parent then
				local posed=entry.root.CFrame:ToObjectSpace(binding.bone.TransformedWorldCFrame)
				point=(posed*binding.rest:Inverse()):PointToWorldSpace(point)
				entry.hook:SetAttribute('AnimatedVFXBone',binding.bone.Name)
			end
			entry.hook.Position=point
			entry.mote.CFrame=CFrame.new(point)
			for _, pane in entry.panes do pane.part.CFrame = entry.root.CFrame * pane.offset end
		end
	end
end

function VFX.start()
	if started then return end
	started = true
	CollectionService:GetInstanceAddedSignal("ExpansionCurseVFX"):Connect(add)
	CollectionService:GetInstanceRemovedSignal("ExpansionCurseVFX"):Connect(remove)
	workspace.DescendantAdded:Connect(function(item)
		if item:IsA("Model") and CollectionService:HasTag(item,"ExpansionCurseVFX") then add(item) end
	end)
	for _, model in CollectionService:GetTagged("ExpansionCurseVFX") do add(model) end
	-- One bounded update for the entire roster; no per-Curse connections or loops.
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		budgetElapsed += dt
		if budgetElapsed >= 0.5 then budgets() budgetElapsed = 0 end
		if elapsed < 0.05 then return end
		elapsed = 0
		local time = workspace.DistributedGameTime
		for _, entry in tracked do
			if entry.mutation and entry.mutation.fx.active and entry.mutation.controller then
				entry.mutation.controller.update(time)
			end
			if entry.near then
				if entry.hero then
					if entry.controller and entry.controller.update then entry.controller.update(time) end
				else
					animate(entry, time)
				end
			end
		end
	end)
end

return VFX
