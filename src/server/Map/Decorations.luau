local Config = require(script.Parent.Config)
local P = require(script.Parent.Primitives)
local AssetKit = require(script.Parent.AssetKit)
local Grounding = require(script.Parent.Grounding)

local D = {}
local C = Config.Colors
local STONE = Enum.Material.Slate

function D.polar(radius: number, angle: number, height: number?): Vector3
	return Vector3.new(math.sin(angle) * radius, height or 0, math.cos(angle) * radius)
end

function D.slab(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material?, options: { [string]: any }?)
	return P.part(parent, name, size, CFrame.new(position), color, material or STONE, options)
end

function D.candle(parent: Instance, name: string, position: Vector3, ghostly: boolean?)
	position = Grounding.position(parent, position)
	local holder = P.model(parent, name)
	D.slab(holder, "Socket", Vector3.new(0.9, 0.2, 0.9), position + Vector3.new(0, 0.1, 0), C.iron, Enum.Material.Metal, { canCollide = false })
	D.slab(holder, "Wax", Vector3.new(0.42, 0.75, 0.42), position + Vector3.new(0, 0.52, 0), C.stoneLight, Enum.Material.SmoothPlastic, { canCollide = false })
	P.part(holder, "Flame", Vector3.new(0.34, 0.52, 0.34), CFrame.new(position + Vector3.new(0, 1.14, 0)), ghostly and C.cyan or C.candle, Enum.Material.Neon, { shape = Enum.PartType.Ball, canCollide = false, castShadow = false })
end

function D.lantern(parent: Instance, name: string, position: Vector3, height: number, color: Color3, lit: boolean?)
	position = Grounding.position(parent, position)
	local fixture = P.model(parent, name)
	D.slab(fixture, "Post", Vector3.new(0.65, height, 0.65), position + Vector3.new(0, height / 2, 0), C.iron, Enum.Material.Metal)
	if AssetKit.place(fixture, "IronCage", "final_lantern", Vector3.new(2.1, 3.5, 2.1),
		CFrame.new(position + Vector3.new(0, height + 1.7, 0)), C.iron, Enum.Material.Metal) then
		local flame = P.part(fixture, "SoulFlame", Vector3.new(0.65, 1.05, 0.65),
			CFrame.new(position + Vector3.new(0, height + 1.2, 0)), color, Enum.Material.Neon,
			{ shape = Enum.PartType.Ball, canCollide = false, castShadow = false })
		if lit then P.light(flame, color, 24, 0.7) end
		return fixture
	end
	D.slab(fixture, "Basket", Vector3.new(1.6, 1.65, 1.6), position + Vector3.new(0, height + 0.8, 0), C.stoneDark)
	local flame = P.part(fixture, "SoulFlame", Vector3.new(0.8, 1.05, 0.8), CFrame.new(position + Vector3.new(0, height + 0.85, 0)), color, Enum.Material.Neon, { shape = Enum.PartType.Ball, canCollide = false, castShadow = false })
	D.slab(fixture, "Hood", Vector3.new(2, 0.35, 2), position + Vector3.new(0, height + 1.82, 0), C.roof)
	if lit then
		P.light(flame, color, 24, 1)
	end
end

function D.rubble(parent: Instance, name: string, position: Vector3, angle: number, scale: number)
	position = Grounding.position(parent, position)
	local frame = CFrame.new(position) * CFrame.Angles(0, angle, math.rad(10))
	if AssetKit.placeGrounded(parent, name, "rock_crag", Vector3.new(3.2, 1.7, 3.2) * scale, frame, C.stoneMoss, STONE, { groundInset = 0.16*scale }) then
		return
	end
	P.part(parent, name, Vector3.new(3.2 * scale, 1.7 * scale, 2.1 * scale), frame * CFrame.new(0, 0.55 * scale, 0), C.stoneMoss, STONE, { shape = Enum.PartType.Ball, canCollide = false })
end

function D.deadTree(parent: Instance, name: string, position: Vector3, angle: number, variant: number, scale: number?)
	position = Grounding.position(parent, position)
	local tree = P.model(parent, name)
	local s = scale or 1
	local templateNames = { "tree_widow", "tree_claw", "tree_sundered", "tree_claw" }
	local dimensions = {
		Vector3.new(19.93, 21.96, 15.18),
		Vector3.new(27.09, 19.05, 17.29),
		Vector3.new(14.55, 13.93, 7.37),
		Vector3.new(24.5, 23.2, 19.1),
	}
	local meshSize = dimensions[variant] * s
	local meshFrame = CFrame.new(position) * CFrame.Angles(0, angle, 0)
	if AssetKit.placeGrounded(tree, "TwistedCanopy", templateNames[variant], meshSize, meshFrame, C.wood, Enum.Material.Wood, { castShadow = true, groundInset = 0.18*s }) then
		-- A simple low trunk blocks the player without giving every branch camera collision.
		P.part(tree, "TrunkCollision", Vector3.new(2.7 * s, math.min(8 * s, meshSize.Y * 0.48), 2.7 * s),
			CFrame.new(position + Vector3.new(0, math.min(8 * s, meshSize.Y * 0.48) / 2, 0)),
			C.root, Enum.Material.Wood, { transparency = 1, castShadow = false })
		return tree
	end
	local height = ({ 21, 29, 12, 24 })[variant] * s
	local spread = ({ 8, 5, 4, 7 })[variant] * s
	local lean = Vector3.new(math.cos(angle) * (variant == 4 and 5 or 2) * s, 0, math.sin(angle) * (variant == 4 and 5 or 2) * s)
	local root = position + Vector3.new(0, 0.2, 0)
	local fork = position + Vector3.new(0, height * 0.58, 0) + lean
	local top = position + Vector3.new(0, height, 0) + lean * 1.8
	P.beam(tree, "HeavyTrunk", root, fork, (variant == 3 and 3 or 3.4) * s, C.root, Enum.Material.Wood)
	P.beam(tree, variant == 3 and "SnappedTrunk" or "CrookedTrunk", fork, top, (variant == 3 and 1.8 or 2) * s, C.wood, Enum.Material.Wood, { canCollide = false })
	local count = ({ 4, 3, 2, 3 })[variant]
	for branch = 1, count do
		local direction = angle + branch * (math.pi * 2 / count) + variant * 0.21
		local start = position + Vector3.new(0, height * (0.36 + branch * 0.07), 0) + lean * (0.7 + branch * 0.12)
		local elbow = start + Vector3.new(math.cos(direction) * spread * 0.55, 2 + branch * 0.55, math.sin(direction) * spread * 0.55)
		local tip = elbow + Vector3.new(math.cos(direction + 0.3) * spread * 0.65, 1.7 + branch % 2 * 2, math.sin(direction + 0.3) * spread * 0.65)
		P.beam(tree, string.format("Claw_%d", branch), start, elbow, 1.05 * s, C.wood, Enum.Material.Wood, { canCollide = false })
		P.beam(tree, string.format("Twig_%d", branch), elbow, tip, 0.52 * s, C.wood, Enum.Material.Wood, { canCollide = false })
	end
	for rootIndex = 0, 1 do
		local direction = angle + rootIndex * 2.1
		P.beam(tree, string.format("ExposedRoot_%d", rootIndex), root + Vector3.new(0, s, 0), root + Vector3.new(math.cos(direction) * (4 + variant) * s, 0.08, math.sin(direction) * (4 + variant) * s), s, C.root, Enum.Material.Wood, { canCollide = false })
	end
	return tree
end

-- Reusable curved leaf shells are original Blender assets, not alpha planes.
-- Branch-specific transforms preserve open gaps and asymmetric silhouettes.
-- A small wedge-blade fallback remains visible while imports are pending.
function D.foliage(parent: Instance, name: string, position: Vector3, angle: number, scale: number, family: string, height: number?, anchorScale: number?)
	position = Grounding.position(parent,position)
	local group=P.model(parent,name)
	group:SetAttribute("FoliageFamily",family)
	local sparse=family=="sparse"
	-- Clump size may be exaggerated, but attachment offsets follow the trunk's
	-- scale. Otherwise a 1.5x canopy size also raises it above the actual tree.
	local branchScale=anchorScale or scale
	local top=height or (sparse and 15.5 or 20)
	group:SetAttribute("FoliageAnchorScale",branchScale)
	group:SetAttribute("FoliageClumpScale",scale)
	group:SetAttribute("FoliageAnchorHeight",top*branchScale)
	local frame=CFrame.new(position)*CFrame.Angles(0,angle,0)
	local clusters={
		{template="foliage_crescent",at=Vector3.new(-5,top-2,2),size=Vector3.new(13,5.5,9),turn=-0.55},
		{template="foliage_tattered",at=Vector3.new(4.5,top-4,-1.5),size=Vector3.new(12,6.5,10),turn=1.2},
		{template="foliage_swept",at=Vector3.new(-0.7,top,-5),size=Vector3.new(11,6,8),turn=2.35},
	}
	for index,clump in ipairs(clusters) do
		if sparse and index==2 then continue end
		local tint=family=="autumn" and (index==2 and C.autumn or C.pumpkin)
			or (index==2 and C.foliageBlue or C.foliage)
		local size=clump.size*scale*(sparse and 0.62 or 1)
		local placement=frame*CFrame.new(clump.at*branchScale)*CFrame.Angles(math.rad(index*6-9),clump.turn,math.rad(index==2 and 12 or -8))
		local mesh=AssetKit.place(group,"CurvedLeafClump"..index,clump.template,size,placement,tint,Enum.Material.SmoothPlastic,
			{collision="none",castShadow=true})
		if not mesh then
			for blade=0,3 do
				P.part(group,"FallbackBlade"..index.."_"..blade,Vector3.new(1.1,0.25,4.3)*scale,
					placement*CFrame.new((blade-1.5)*1.4,math.sin(blade)*0.55,blade*0.25)*CFrame.Angles(0,math.rad(blade*16-24),math.rad(blade*3)),
					tint,Enum.Material.SmoothPlastic,{className="WedgePart",canCollide=false,canQuery=false,castShadow=true})
			end
		end
	end
	return group
end

function D.treeFamily(parent: Instance, name: string, position: Vector3, angle: number, family: string, scale: number)
	if family=="stump" then
		position=Grounding.position(parent,position)
		local tree=P.model(parent,name)
		local frame=CFrame.new(position)*CFrame.Angles(0,angle,0)
		P.beam(tree,"BrokenTrunk",position+Vector3.new(0,0.1,0),frame:PointToWorldSpace(Vector3.new(0.7,4.1*scale,0.2)),2.4*scale,C.wood,Enum.Material.Wood)
		AssetKit.placeGrounded(tree,"RootFan","root_serpent",Vector3.new(8.5,2.8,5.5)*scale,frame,C.root,Enum.Material.Wood,{groundInset=0.15})
		tree:SetAttribute("TreeFamily",family)
		return tree
	end
	local variant=family=="broken" and 3 or (family=="sparse" and 2 or (family=="dead" and 4 or 1))
	local tree=D.deadTree(parent,name,position,angle,variant,scale)
	tree:SetAttribute("TreeFamily",family)
	if family=="haunted" or family=="autumn" or family=="sparse" then
		D.foliage(tree,"BranchLeafClusters",position,angle,scale,family,family=="sparse" and 17 or 20)
	end
	return tree
end

function D.tombstone(parent: Instance, name: string, position: Vector3, lean: number, style: number)
	position = Grounding.position(parent, position)
	local grave = P.model(parent, name)
	local facing = CFrame.lookAt(position, Vector3.new(0, position.Y, 0))
	P.part(grave, "GraveBase", Vector3.new(4.6, 0.32, 2.9), facing * CFrame.new(0, 0.16, 0), C.stoneDark, STONE, { canCollide = false })
	local templates = { "grave_arched", "grave_spire", "grave_broken" }
	local sizes = {
		Vector3.new(3.7, 5.15, 0.9),
		Vector3.new(2.85, 7.4, 1.25),
		Vector3.new(4.1, 3.7, 1.1),
	}
	local meshSize = sizes[style]
	local meshFrame = facing * CFrame.new(0, 0.28, 0) * CFrame.Angles(0, 0, math.rad(lean))
	if AssetKit.placeGrounded(grave, "Headstone", templates[style], meshSize, meshFrame, style == 3 and C.stoneMoss or C.stone, STONE, { groundInset = 0.09 }) then
		return
	end
	local height = style == 2 and 5.4 or (style == 3 and 3.3 or 4.1)
	local tilted = facing * CFrame.new(0, height / 2 + 0.3, 0) * CFrame.Angles(0, 0, math.rad(lean))
	P.part(grave, "Headstone", Vector3.new(style == 2 and 2.3 or 3, height, 0.85), tilted, style == 3 and C.stoneMoss or C.stone, STONE)
	if style == 1 then
		P.part(grave, "RoundCrown", Vector3.new(3, 1.2, 0.95), tilted * CFrame.new(0, height / 2, 0), C.stoneLight, STONE, { shape = Enum.PartType.Ball, canCollide = false })
	elseif style == 2 then
		P.part(grave, "CrossArm", Vector3.new(4.3, 0.9, 1), tilted * CFrame.new(0, 1.2, 0), C.stoneLight, STONE, { canCollide = false })
	elseif style == 3 then
		P.part(grave, "BrokenCap", Vector3.new(2, 0.7, 0.9), tilted * CFrame.new(0.6, height / 2 + 0.3, 0) * CFrame.Angles(0, 0, math.rad(17)), C.stoneWarm, STONE, { canCollide = false })
	end
end

function D.mushrooms(parent: Instance, name: string, position: Vector3)
	position = Grounding.position(parent, position)
	local group = P.model(parent, name)
	for index = 0, 2 do
		local offset = Vector3.new(index * 1.5 - 1.5, 0, index % 2 * 1.1)
		local height = 0.65 + index * 0.25
		D.slab(group, string.format("Stem_%d", index), Vector3.new(0.24, height, 0.24), position + offset + Vector3.new(0, height / 2, 0), C.stoneLight, Enum.Material.SmoothPlastic, { canCollide = false })
		P.part(group, string.format("Cap_%d", index), Vector3.new(0.9 + index * 0.2, 0.4, 0.9 + index * 0.2), CFrame.new(position + offset + Vector3.new(0, height, 0)), index == 1 and C.violet or C.pumpkin, Enum.Material.SmoothPlastic, { shape = Enum.PartType.Ball, canCollide = false })
	end
end

function D.brokenFence(parent: Instance, name: string, position: Vector3, angle: number)
	position = Grounding.position(parent, position)
	local fence = P.model(parent, name)
	local frame = CFrame.new(position) * CFrame.Angles(0, angle, 0)
	for _, side in ipairs({ -1, 1 }) do
		P.part(fence, side < 0 and "LeftPost" or "RightPost", Vector3.new(0.85, 4, 0.85), frame * CFrame.new(side * 4.8, 2, 0) * CFrame.Angles(0, 0, math.rad(side * 8)), C.iron, Enum.Material.Metal, { canCollide = false })
	end
	P.part(fence, "SaggingRail", Vector3.new(9.5, 0.3, 0.35), frame * CFrame.new(0, 2.1, 0) * CFrame.Angles(0, 0, math.rad(-13)), C.iron, Enum.Material.Metal, { canCollide = false })
	P.part(fence, "BrokenRail", Vector3.new(4.6, 0.3, 0.35), frame * CFrame.new(-2.4, 3.2, 0) * CFrame.Angles(0, 0, math.rad(11)), C.iron, Enum.Material.Metal, { canCollide = false })
end

function D.pumpkin(parent: Instance, name: string, position: Vector3, scale: number?, turn: number?, variant: number?)
	position = Grounding.position(parent, position)
	local s = scale or 1
	local frame = CFrame.new(position) * CFrame.Angles(0, turn or math.pi, 0)
	local model = P.model(parent, name)
	local tint = variant == 2 and Color3.fromRGB(155, 80, 50) or (variant == 3 and Color3.fromRGB(97,140,134) or C.pumpkin)
	if AssetKit.placeGrounded(model, "RibbedPumpkin", "final_pumpkin", Vector3.new(3.5, 3, 3.5)*s,
		frame, tint, Enum.Material.SmoothPlastic, {groundInset=0.04*s}) then
		for _, side in ipairs({ -1, 1 }) do
			P.part(model, "Eye" .. side, Vector3.new(0.48, 0.47, 0.09)*s,
				frame*CFrame.new(Vector3.new(side * 0.55, 1.54, -1.65)*s) * CFrame.Angles(0, 0, math.rad(side * 15)),
				variant==3 and C.cyan or C.candle, Enum.Material.Neon, { className = "WedgePart", canCollide = false, canQuery = false, castShadow = false })
		end
		P.part(model, "JackOLanternSmile", Vector3.new(1.2, 0.22, 0.09)*s, frame*CFrame.new(Vector3.new(0,0.88,-1.66)*s),
			variant==3 and C.cyan or C.candle, Enum.Material.Neon, { canCollide = false, canQuery = false, castShadow = false })
		return model
	end
	P.part(model, "Pumpkin", Vector3.new(2.5, 2, 2.3), CFrame.new(position + Vector3.new(0, 1, 0)), C.pumpkin, Enum.Material.SmoothPlastic, { shape = Enum.PartType.Ball, canCollide = false })
	D.slab(model, "Stem", Vector3.new(0.35, 0.55, 0.35), position + Vector3.new(0, 2.2, 0), C.wood, Enum.Material.Wood, { canCollide = false })
	P.part(model, "JackOLantern", Vector3.new(0.85, 0.3, 0.08), CFrame.new(position + Vector3.new(0, 1.15, -1.14)), C.candle, Enum.Material.Neon, { canCollide = false, castShadow = false })
end

return D
