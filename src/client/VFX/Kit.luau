-- Building blocks for authored ("hero") Curse VFX.
--
-- An effect owns its instances under the CurseMesh, follows the Curse's
-- animated bones through rest/posed bindings, and only spends particles while
-- CurseVFX's distance budget marks it near. It never touches gameplay state,
-- prompts, anchors, CurseVFXHook or the mesh itself.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VisualAssets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VisualAssets"))

local Kit = {}
Kit.Textures = VisualAssets.Textures

local function range(value)
	if typeof(value) == "table" then return NumberRange.new(value[1], value[2]) end
	return NumberRange.new(value)
end

local function sequence(value)
	if typeof(value) == "number" then return NumberSequence.new(value) end
	local points = {}
	for _, p in value do table.insert(points, NumberSequenceKeypoint.new(p[1], p[2], p[3] or 0)) end
	return NumberSequence.new(points)
end

local function colors(value)
	if typeof(value) == "Color3" then return ColorSequence.new(value) end
	local points = {}
	for _, p in value do table.insert(points, ColorSequenceKeypoint.new(p[1], p[2])) end
	return ColorSequence.new(points)
end

Kit.range, Kit.sequence, Kit.colors = range, sequence, colors

local CONVERT = {
	Lifetime = range, Speed = range, Rotation = range, RotSpeed = range,
	Size = sequence, Transparency = sequence, Squash = sequence, Color = colors,
}
-- Trails and Beams take a plain Lifetime and sequence-valued widths.
local CONVERT_RIBBON = { Transparency = sequence, WidthScale = sequence, Color = colors }

local function apply(instance: Instance, props, convertMap)
	for key, value in props do
		if key == "Texture" and Kit.Textures[value] then value = Kit.Textures[value] end
		local convert = convertMap[key]
		instance[key] = if convert then convert(value) else value
	end
end

local Effect = {}
Effect.__index = Effect

function Kit.new(model: Model, root: BasePart)
	local self = setmetatable({}, Effect)
	self.model = model
	self.root = root
	self.size = root.Size
	self.scale = (model:GetAttribute("PresentationScale") or 1) * (model:GetAttribute("VFXGeometryScale") or 1)
	self.instances = {}
	self.emitters = {}
	self.bindings = {}
	self.lights = {}
	self.active = false
	self.rateScale = 1
	self.phase = (root.Size.X * 1.7 + root.Size.Y * 0.9) % 10
	return self
end

function Effect:own(instance: Instance)
	table.insert(self.instances, instance)
	return instance
end

-- Bones are named "<curseId>__<Name>"; look them up by their short name.
function Effect:bone(shortName: string): Bone?
	for _, item in self.root:GetDescendants() do
		if item:IsA("Bone") and (item.Name == shortName or string.sub(item.Name, -(#shortName + 2)) == "__" .. shortName) then
			return item
		end
	end
	return nil
end

-- Root-local attachment that follows the given bone's animated pose.
function Effect:attach(name: string, localPosition: Vector3, boneName: string?, orientation: CFrame?)
	local attachment = Instance.new("Attachment")
	attachment.Name = "HeroVFX_" .. name
	attachment.CFrame = CFrame.new(localPosition) * (orientation or CFrame.identity)
	attachment.Parent = self.root
	self:own(attachment)
	local bone = boneName and self:bone(boneName)
	if bone then
		local rest = self.root.CFrame:ToObjectSpace(bone.WorldCFrame)
		table.insert(self.bindings, { attachment = attachment, bone = bone, rest = rest, base = attachment.CFrame })
	end
	return attachment
end

-- Current animated position of a bone in root space (for paths along rigs).
function Effect:posed(boneName: string): Vector3?
	self.boneCache = self.boneCache or {}
	local bone = self.boneCache[boneName]
	if bone == nil then
		bone = self:bone(boneName) or false
		self.boneCache[boneName] = bone
	end
	if not bone or not bone.Parent then return nil end
	return self.root.CFrame:PointToObjectSpace(bone.TransformedWorldCFrame.Position)
end

-- Position along a polyline of root-space points, u in [0, 1].
function Kit.along(points: { Vector3 }, u: number): Vector3
	local n = #points
	if n == 0 then return Vector3.zero end
	if n == 1 then return points[1] end
	local f = math.clamp(u, 0, 1) * (n - 1)
	local i = math.min(n - 1, math.floor(f) + 1)
	return points[i]:Lerp(points[i + 1], f - (i - 1))
end

-- Attachment placed relative to a bone's rest position (root space), so
-- authored offsets read as "just in front of / above this joint".
function Effect:at(name: string, boneName: string, offset: Vector3, orientation: CFrame?)
	local bone = self:bone(boneName)
	local base = if bone then self.root.CFrame:PointToObjectSpace(bone.WorldPosition) else Vector3.zero
	return self:attach(name, base + offset * self.scale, boneName, orientation)
end

-- Invisible helper part used when an emitter needs a volume Shape.
function Effect:volume(name: string, size: Vector3, attachment: Attachment)
	local part = Instance.new("Part")
	part.Name = "HeroVFXVolume_" .. name
	part.Size = size
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Massless = true
	part.CFrame = attachment.WorldCFrame
	part.Parent = self.root
	self:own(part)
	self.volumes = self.volumes or {}
	table.insert(self.volumes, { part = part, attachment = attachment })
	return part
end

-- Persistent emitters take `rate`; burst-only emitters use rate = 0 and :burst.
function Effect:emitter(name: string, parent: Instance, rate: number, props)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "HeroVFX_" .. name
	emitter.Rate = 0
	emitter.LightInfluence = 0
	emitter.LockedToPart = false
	apply(emitter, props, CONVERT)
	emitter.Parent = parent
	self:own(emitter)
	table.insert(self.emitters, { emitter = emitter, rate = rate })
	return emitter
end

function Effect:light(name: string, parent: Instance, color: Color3, range: number, brightness: number)
	local light = Instance.new("PointLight")
	light.Name = "HeroVFX_" .. name
	light.Color = color
	light.Range = range
	light.Brightness = 0
	light.Shadows = false
	light.Enabled = false
	light.Parent = parent
	self:own(light)
	table.insert(self.lights, { light = light, brightness = brightness })
	return light
end

function Effect:trail(name: string, a0: Attachment, a1: Attachment, props)
	local trail = Instance.new("Trail")
	trail.Name = "HeroVFX_" .. name
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.FaceCamera = true
	trail.LightInfluence = 0
	apply(trail, props, CONVERT_RIBBON)
	trail.Enabled = false
	trail.Parent = self.root
	self:own(trail)
	self.trails = self.trails or {}
	table.insert(self.trails, trail)
	return trail
end

function Effect:beam(name: string, a0: Attachment, a1: Attachment, props)
	local beam = Instance.new("Beam")
	beam.Name = "HeroVFX_" .. name
	beam.Attachment0, beam.Attachment1 = a0, a1
	beam.FaceCamera = true
	beam.LightInfluence = 0
	beam.Segments = 12
	apply(beam, props, CONVERT_RIBBON)
	beam.Enabled = false
	beam.Parent = self.root
	self:own(beam)
	self.beams = self.beams or {}
	table.insert(self.beams, beam)
	return beam
end

-- Called by the CurseVFX budget (2 Hz). `tier` is 1 close, ~0.4 mid-range.
function Effect:setActive(active: boolean, tier: number, mobile: boolean, allowLight: boolean)
	self.active = active
	self.rateScale = if active then tier * (if mobile then 0.65 else 1) else 0
	for _, item in self.emitters do item.emitter.Rate = item.rate * self.rateScale end
	for _, item in self.lights do item.light.Enabled = active and allowLight end
	for _, trail in self.trails or {} do trail.Enabled = active end
	for _, beam in self.beams or {} do beam.Enabled = active end
	if not active then
		for _, item in self.emitters do item.emitter:Clear() end
	end
	return #self.lights > 0 and active and allowLight
end

-- Extra multiplier on top of the budget (e.g. Red Moon intensity).
function Effect:boost(multiplier: number)
	if not self.active then return end
	for _, item in self.emitters do item.emitter.Rate = item.rate * self.rateScale * multiplier end
end

function Effect:setLight(index: number, multiplier: number)
	local item = self.lights[index]
	if item then item.light.Brightness = item.brightness * multiplier end
end

function Effect:burst(emitter: ParticleEmitter, count: number)
	if self.active then emitter:Emit(math.max(1, math.floor(count * (self.rateScale > 0 and math.min(1, self.rateScale + 0.35) or 0) + 0.5))) end
end

-- Per-frame: re-pose bound attachments after the shared animator has run.
function Effect:render()
	local rootFrame = self.root.CFrame
	for _, b in self.bindings do
		if b.bone.Parent then
			local posed = rootFrame:ToObjectSpace(b.bone.TransformedWorldCFrame)
			b.attachment.CFrame = posed * b.rest:Inverse() * b.base
		end
	end
	for _, v in self.volumes or {} do
		v.part.CFrame = v.attachment.WorldCFrame
	end
end

function Effect:destroy()
	for _, instance in self.instances do instance:Destroy() end
	table.clear(self.instances)
	table.clear(self.emitters)
end

return Kit
