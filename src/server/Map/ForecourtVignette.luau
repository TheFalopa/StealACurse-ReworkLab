-- Authored sanctuary forecourt vignettes (rework sample: Base08 "Old Family
-- Court"). The approach reads quiet lane -> denser transition at the two path
-- wedges (framing trees, a family grave group) -> the gate as landmark (two
-- unlit lanterns) -> an open forecourt as breathing space before the ramp.
-- Anchors are base-local (castle toward -Z, gate at z=-34) and were checked
-- numerically against that base's lane, cross trails, ramp, footprint,
-- contract node and landmarks only, so a listed base without an authored site
-- is skipped. Static: no lights, emitters, connections or per-frame work.
-- Revert by removing the Build call and Config.ForecourtVignetteBases.
local Config = require(script.Parent.Config)
local P = require(script.Parent.Primitives)
local D = require(script.Parent.Decorations)
local AssetKit = require(script.Parent.AssetKit)
local Grounding = require(script.Parent.Grounding)

local ForecourtVignette = {}
local C = Config.Colors
local PART_BUDGET = 80
local SOIL = Color3.fromRGB(52, 43, 58)
local softFlat = { shape = Enum.PartType.Ball, canCollide = false, canQuery = false, castShadow = false }
-- Muted autumn leaves: warm against the blue fog but darker than candle
-- amber, so the wayfinding flames stay the brightest warm accent.
local AUTUMN = {
	Color3.fromRGB(150, 74, 46), -- ember
	Color3.fromRGB(148, 107, 58), -- ochre
	C.autumn, -- rust rose
	Color3.fromRGB(98, 46, 60), -- wine
	Color3.fromRGB(84, 63, 96), -- dusk plum
}

-- tree_widow measured from assets/source/blender/generate_kit.py and
-- normalized to its template bounds. The trunk origin is off the box centre,
-- so a leaning tree is seated by its trunk and root tips, not by its box.
local WIDOW = {
	size = Vector3.new(19.93, 21.96, 15.18),
	trunk = Vector3.new(0.0201, -0.4891, -0.1034),
	rootTips = {
		Vector3.new(0.3663, -0.4866, -0.2548), Vector3.new(-0.3211, -0.4866, 0.0549),
		Vector3.new(0.1204, -0.4866, 0.3712), Vector3.new(-0.0903, -0.4866, -0.4986),
	},
	-- Four claw tips and the trunk crown carry the leaf clumps.
	crowns = {
		Vector3.new(0.4967, 0.3900, -0.0044), Vector3.new(-0.4967, 0.4993, -0.3668),
		Vector3.new(0.1606, 0.4856, 0.4963), Vector3.new(-0.2709, 0.1987, 0.3250),
		Vector3.new(-0.0803, 0.4537, -0.0769),
	},
}
-- Clump sizes are authored for a 1.5x tree and follow its scale.
local CLUMPS = {
	{ template = "foliage_tattered", size = Vector3.new(9.5, 4.6, 8) },
	{ template = "foliage_crescent", size = Vector3.new(11, 4.2, 7) },
	{ template = "foliage_swept", size = Vector3.new(9.5, 5, 6) },
	{ template = "foliage_crescent", size = Vector3.new(8, 3.4, 5.5) },
	{ template = "foliage_tattered", size = Vector3.new(8.5, 4.2, 7) },
}

-- Base-local anchors. Base08 footprint clearances to the nearest road edge
-- (studs): trunk colliders 10.4/11.6, headstones and railing >= 8.3, ground
-- decor >= 5.1, lantern posts 6.5 (trail) and 7.0 (ramp). Ground pieces stay
-- >= 6.4 from the forest_shrine contract stone; only high canopy reaches over.
local SITES = {
	[8] = {
		gate = Vector3.new(0, 0, -34),
		viewer = Vector3.new(-8, 0, -118),
		trees = {
			{ name = "WestFramingTree", at = Vector3.new(-27, 0, -79), scale = 1.48, tilt = 4, turn = 0.15,
				palette = { 3, 1, 4, 2, 5 }, tufts = { Vector3.new(-31.5, 0, -75), Vector3.new(-22.4, 0, -76.5) } },
			{ name = "EastFramingTree", at = Vector3.new(21, 0, -82), scale = 1.56, tilt = 3.5, turn = -0.1,
				palette = { 1, 4, 2, 5, 3 }, tufts = { Vector3.new(25.6, 0, -78), Vector3.new(16.4, 0, -79.5) } },
		},
		pumpkins = { { at = Vector3.new(-22.8, 0, -83.6), scale = 0.72, style = 1 }, { at = Vector3.new(-20.6, 0, -81.8), scale = 0.46, style = 2 } },
		candles = { Vector3.new(-24.8, 0, -85.4), Vector3.new(17.6, 0, -86.2) },
		graves = Vector3.new(37, 0, -93),
		lanterns = { Vector3.new(-18.5, 0, -39.5), Vector3.new(18.5, 0, -39.5) },
	},
}

-- Grounding treats the sample Y as a floor: sample from Y=0 at the element's
-- own X/Z, as HalloweenArt and WorldPolish do.
local function ground(parent: Instance, at: Vector3): Vector3
	return Grounding.position(parent, Vector3.new(at.X, 0, at.Z))
end

-- Yaw (for CFrame.Angles(0, yaw, 0)) whose -Z faces from `from` toward `to`.
local function faceToward(from: Vector3, to: Vector3): number
	return math.atan2(from.X - to.X, from.Z - to.Z)
end

-- SurfaceArt's stone output applied up front (Materials still paints it);
-- SurfaceArt then skips these, leaving its tint sequence for existing stone.
local function paintStone(item: BasePart?)
	if not item then return end
	item.Material = Enum.Material.SmoothPlastic
	item:SetAttribute("ArtMaterial", "HollowStone")
end

local function soilPatch(parent: Instance, name: string, at: Vector3, size: Vector3, yaw: number)
	P.part(parent, name, size, CFrame.new(at) * CFrame.Angles(0, yaw, 0), SOIL, Enum.Material.Ground, softFlat)
end

local function framingTree(parent: Instance, frame: CFrame, spec, gate: Vector3)
	local tree = P.model(parent, spec.name)
	local base = ground(tree, frame:PointToWorldSpace(spec.at))
	local toGate = gate - base
	local lean = Vector3.new(toGate.X, 0, toGate.Z).Unit
	local heading = CFrame.lookAt(Vector3.zero, lean)
	-- The trunk already leans toward template -X: turn that to the gate, tilt a
	-- few degrees further about the trunk base, then vary the branch turn.
	local pose = heading * CFrame.Angles(0, -math.pi / 2, 0) * CFrame.Angles(0, 0, math.rad(spec.tilt))
		* CFrame.Angles(0, spec.turn, 0)
	local size = WIDOW.size * spec.scale
	local trunk = size * WIDOW.trunk
	-- Sink until the highest root tip is in the soil; the flared base follows.
	local sink = 0.15
	for _, tip in WIDOW.rootTips do
		sink = math.max(sink, pose:VectorToWorldSpace(size * tip - trunk).Y + 0.05)
	end
	local trunkBase = CFrame.new(base - Vector3.new(0, sink, 0)) * pose
	local meshFrame = trunkBase * CFrame.new(-trunk)
	local mesh = AssetKit.place(tree, "LeaningTrunk", "tree_widow", size, meshFrame, C.wood, Enum.Material.Wood,
		{ castShadow = true, collision = "none" })
	if not mesh then
		return tree
	end
	-- Same grounding contract as AssetKit.placeGrounded: the rotated box bottom
	-- sits GroundInset below SupportY. The tilted box corner is lower than the
	-- seated trunk, whose own depth is recorded as TrunkSink.
	local half = size * 0.5
	local boxBottom = meshFrame.Position.Y - math.abs(meshFrame.RightVector.Y) * half.X
		- math.abs(meshFrame.UpVector.Y) * half.Y - math.abs(meshFrame.LookVector.Y) * half.Z
	mesh:SetAttribute("GroundedPlacement", true)
	mesh:SetAttribute("SupportY", base.Y)
	mesh:SetAttribute("GroundInset", base.Y - boxBottom)
	mesh:SetAttribute("TrunkSink", sink)
	-- One collider replaces the template's short hull (0.16 of the mesh height,
	-- ~4 studs above the soil here), which a player could jump onto inside the
	-- bark. It rises from the seated trunk base along
	-- the modelled trunk axis (template lean (-0.7, 8.8, -0.5) plus the pose)
	-- to 6.2x scale; branches stay soft. AssetKit hull attributes, so audits
	-- and the mesh-bounds contract treat it alike.
	local hulls = Instance.new("Folder")
	hulls.Name = "CollisionHulls"
	hulls.Parent = mesh
	local height = 6.2 * spec.scale
	local hull = P.part(hulls, "CollisionHull_01", Vector3.new(1.7 * spec.scale, height, 1.7 * spec.scale),
		trunkBase * CFrame.Angles(math.rad(-3.3), 0, math.rad(4.5)) * CFrame.new(0, height / 2, 0),
		C.root, Enum.Material.Wood, { transparency = 1, castShadow = false })
	hull:SetAttribute("EnvironmentCollisionHull", true)
	hull:SetAttribute("CollisionSource", "tree_widow")
	hull:SetAttribute("CollisionCategory", "Blocking")
	mesh:SetAttribute("CollisionCategory", "Blocking")
	mesh:SetAttribute("CollisionHullCount", 1)
	local grow = spec.scale / 1.5
	for index, crown in WIDOW.crowns do
		local clump = CLUMPS[index]
		local clumpSize = clump.size * grow
		local tip = meshFrame:PointToWorldSpace(size * crown)
		-- Blades spring from the clump's upper centre, so it sits just above the tip.
		local placement = CFrame.new(tip + Vector3.new(0, clumpSize.Y * 0.2, 0)) * heading
			* CFrame.Angles(0, spec.turn + index * 1.3, 0) * CFrame.Angles(math.rad(index * 5 - 15), 0, math.rad(index % 2 == 0 and 9 or -7))
		AssetKit.place(tree, "AutumnClump" .. index, clump.template, clumpSize, placement,
			AUTUMN[spec.palette[index]], Enum.Material.SmoothPlastic, { collision = "none", castShadow = true })
	end
	-- A bracing root behind the lean and turned soil seat the pose.
	local rootAt = ground(tree, base - lean * (2.2 * spec.scale))
	local root = AssetKit.placeGrounded(tree, "BracingRoot", "root_serpent", Vector3.new(8.6, 1.4, 4.6) * grow,
		CFrame.new(rootAt) * heading * CFrame.Angles(0, spec.turn, 0), C.root, Enum.Material.Wood,
		{ collision = "none", castShadow = true, groundInset = 0.3 })
	if root then root:SetAttribute("ArtMaterial", "TwilightWood") end
	soilPatch(tree, "TurnedSoil", base, Vector3.new(13, 0.16, 9.5) * grow, math.atan2(lean.X, lean.Z))
	for index, at in spec.tufts do
		local point = ground(tree, frame:PointToWorldSpace(at))
		AssetKit.placeGrounded(tree, "RootGrass" .. index, "foliage_swept", Vector3.new(3.4, 1.0, 2.2),
			CFrame.new(point) * CFrame.Angles(0, index * 1.7 + spec.turn, math.rad(3)), index == 1 and C.foliageBlue or C.foliage,
			Enum.Material.SmoothPlastic, { collision = "none", castShadow = false, groundInset = 0.04 })
	end
	return tree
end

local function familyGraves(parent: Instance, frame: CFrame, at: Vector3, viewer: Vector3)
	local group = P.model(parent, "FamilyGraves")
	local center = ground(group, frame:PointToWorldSpace(at))
	-- Front (-Z) turns toward the approach, so arriving players read the stones.
	local front = CFrame.lookAt(center, Vector3.new(viewer.X, center.Y, viewer.Z))
	local function spot(x: number, z: number): Vector3
		return ground(group, front:PointToWorldSpace(Vector3.new(x, 0, z)))
	end
	soilPatch(group, "TurnedSoil", front:PointToWorldSpace(Vector3.new(0.4, 0, 0.6)), Vector3.new(14, 0.16, 8), faceToward(center, viewer))
	local kerbTop = 0.22
	paintStone(P.part(group, "FamilyKerb", Vector3.new(10.6, kerbTop, 4.6), front * CFrame.new(0, kerbTop / 2, 0.4),
		C.stoneDark, Enum.Material.Slate, { canCollide = false, canQuery = false }))
	-- Headstones stand on the kerb and keep their template hulls (off-path).
	for index, stone in {
		{ template = "grave_spire", size = Vector3.new(2.42, 6.29, 1.06), x = -3.4, pitch = 3, roll = 1.5, color = C.stone },
		{ template = "grave_arched", size = Vector3.new(3.15, 4.38, 0.77), x = 0.3, pitch = -2.5, roll = -1, color = C.stoneLight },
		{ template = "grave_broken", size = Vector3.new(2.6, 2.35, 0.75), x = 3.7, pitch = 5, roll = 2, color = C.stoneMoss },
	} do
		local p = spot(stone.x, 1.0)
		paintStone(AssetKit.placeGrounded(group, "FamilyHeadstone" .. index, stone.template, stone.size,
			CFrame.new(p.X, p.Y + kerbTop, p.Z) * front.Rotation * CFrame.Angles(math.rad(stone.pitch), 0, math.rad(stone.roll)),
			stone.color, Enum.Material.Slate, { groundInset = 0.12 }))
	end
	-- One old railing panel behind the stones, leaning back a little.
	AssetKit.placeGrounded(group, "IronRailing", "final_iron_fence", Vector3.new(11.2, 4.2, 0.8),
		CFrame.new(spot(0.3, 3.4)) * front.Rotation * CFrame.Angles(math.rad(4), 0.05, 0), C.iron, Enum.Material.Metal, { groundInset = 0.05 })
	for index, x in { -1.2, 1.6 } do
		local p = spot(x, -1.3)
		D.candle(group, "GraveCandle" .. index, Vector3.new(p.X, p.Y + kerbTop, p.Z), false)
	end
	local pumpkinAt = spot(6.6, -0.6)
	D.pumpkin(group, "GravePumpkin", pumpkinAt, 0.55, faceToward(pumpkinAt, viewer), 1)
	return group
end

function ForecourtVignette.build(map: Model)
	local forecourts = P.model(map, "SanctuaryForecourts")
	for _, baseIndex in ipairs(Config.ForecourtVignetteBases or {}) do
		local site = SITES[baseIndex]
		if not site then
			warn(string.format("No authored forecourt vignette for base %d", baseIndex))
			continue
		end
		local frame = Config.baseFrame(baseIndex)
		local court = P.model(forecourts, string.format("Base%02d", baseIndex))
		court:SetAttribute("BaseIndex", baseIndex)
		local gate = frame:PointToWorldSpace(site.gate)
		local viewer = frame:PointToWorldSpace(site.viewer)
		for _, spec in site.trees do
			framingTree(court, frame, spec, gate)
		end
		local offerings = P.model(court, "TreeOfferings")
		for index, pumpkin in site.pumpkins do
			local at = ground(offerings, frame:PointToWorldSpace(pumpkin.at))
			D.pumpkin(offerings, "RootPumpkin" .. index, at, pumpkin.scale, faceToward(at, viewer), pumpkin.style)
		end
		for index, at in site.candles do
			D.candle(offerings, "RootCandle" .. index, ground(offerings, frame:PointToWorldSpace(at)), false)
		end
		familyGraves(court, frame, site.graves, viewer)
		-- Unlit gate lanterns: Neon flames only, no PointLight.
		for index, at in site.lanterns do
			D.lantern(court, "GateLantern" .. index, ground(court, frame:PointToWorldSpace(at)), 4.6, C.candle, false)
		end
		local parts, emitters = 0, 0
		for _, item in court:GetDescendants() do
			if item:IsA("BasePart") then
				parts += 1
			elseif item:IsA("Light") or item:IsA("ParticleEmitter") then
				emitters += 1
			end
		end
		court:SetAttribute("PartCount", parts)
		court:SetAttribute("PartBudget", PART_BUDGET)
		assert(parts <= PART_BUDGET and emitters == 0, "Forecourt vignette exceeded its static budget")
	end
	return forecourts
end

return ForecourtVignette
