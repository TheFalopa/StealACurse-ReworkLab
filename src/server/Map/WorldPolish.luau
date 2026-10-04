-- Composed, static details for the established haunted world. This module
-- changes no floor, wall, route, sanctuary contract or gameplay object.
local Config = require(script.Parent.Config)
local P = require(script.Parent.Primitives)
local D = require(script.Parent.Decorations)
local AssetKit = require(script.Parent.AssetKit)
local Grounding = require(script.Parent.Grounding)
local Layout = require(script.Parent.Layout)
local TerrainArt = require(script.Parent.TerrainArt)

local WorldPolish = {}
local C = Config.Colors
local PART_BUDGET = 214
local meshSoft = { collision = "none", canCollide = false, castShadow = false, groundInset = 0.035 }
local leafColors = {
	Color3.fromRGB(62, 88, 98),
	Color3.fromRGB(73, 75, 110),
	Color3.fromRGB(77, 65, 105),
}

function WorldPolish.build(map: Model)
	local art = P.model(map, "HauntedWorldPolish")
	art:SetAttribute("VisualDesign", "Hollow Crown autumn vigil")
	local count = { parts = 0, meshes = 0, lights = 0, missing = 0, pockets = 0 }
	local function floorAt(at: Vector3): Vector3
		-- Child offsets from a grounded frame can leave a rounded hill. Sample
		-- their own support from Y=0 instead of retaining the parent's height.
		return Grounding.position(art, Vector3.new(at.X, 0, at.Z))
	end

	local function prepare(item: BasePart)
		item.CanCollide = false
		item.CanQuery = false
		item.CanTouch = false
		item.Anchored = true
		item:SetAttribute("WorldPolishDecoration", true)
		count.parts += 1
		if item:IsA("MeshPart") then count.meshes += 1 end
		if item.Material == Enum.Material.Wood then
			item:SetAttribute("ArtMaterial", "TwilightWood")
		elseif item.Material == Enum.Material.Slate then
			item:SetAttribute("ArtMaterial", "HollowStone")
		end
	end

	local function mesh(parent: Instance, name: string, template: string, size: Vector3, frame: CFrame,
		color: Color3, material: Enum.Material, grounded: boolean?, shadow: boolean?): MeshPart?
		if count.parts >= PART_BUDGET then return nil end
		local options = if shadow then { collision = "none", castShadow = true, groundInset = 0.08 } else meshSoft
		local item = if grounded
			then AssetKit.placeGrounded(parent, name, template, size, frame, color, material, options)
			else AssetKit.place(parent, name, template, size, frame, color, material, options)
		if item then prepare(item) else count.missing += 1 end
		return item
	end

	local function accent(parent: Instance, name: string, size: Vector3, frame: CFrame, color: Color3,
		material: Enum.Material, transparency: number?): BasePart?
		if count.parts >= PART_BUDGET then return nil end
		local item = P.part(parent, name, size, frame, color, material,
			{ shape = Enum.PartType.Ball, canCollide = false, canQuery = false,
				castShadow = false, transparency = transparency or 0 })
		prepare(item)
		return item
	end

	local function pumpkin(parent: Instance, name: string, at: Vector3, scale: number, turn: number, style: number)
		-- Both the verified mesh form and its existing native fallback fit four
		-- parts. Reserve that space before making the whole decoration group.
		if count.parts > PART_BUDGET - 4 then return end
		local group = D.pumpkin(parent, name, floorAt(at), scale, turn, style) or parent:FindFirstChild(name)
		if not group then return end
		for _, item in ipairs(group:GetDescendants()) do
			if item:IsA("BasePart") then prepare(item) end
		end
	end

	local function tuft(parent: Instance, name: string, at: Vector3, angle: number, tint: Color3, size: Vector3)
		local grounded = floorAt(at)
		mesh(parent, name, "foliage_swept", size,
			CFrame.new(grounded) * CFrame.Angles(0, angle, math.rad(3)), tint,
			Enum.Material.SmoothPlastic, true)
	end

	local function smallPocket(parent: Instance, name: string, at: Vector3, angle: number, index: number)
		if count.parts > PART_BUDGET - 12 then return end
		local group = P.model(parent, name)
		group:SetAttribute("DecorationCluster", "MoonlitUnderstory")
		local frame = CFrame.new(floorAt(at)) * CFrame.Angles(0, angle, 0)
		for blade = 1, 3 do
			local point = frame:PointToWorldSpace(Vector3.new((blade - 2) * 1.9, 0, blade % 2 * 1.5))
			tuft(group, "CurvedGrass" .. blade, point, angle + blade * 0.8,
				leafColors[(index + blade) % #leafColors + 1], Vector3.new(2.7, 0.72 + blade * 0.14, 1.8))
		end
		for leaf = 1, 2 do
			local point = floorAt(frame:PointToWorldSpace(Vector3.new(-0.9 + leaf * 1.8, 0, -1.5)))
			mesh(group, "FallenCurvedLeaf" .. leaf, "foliage_tattered", Vector3.new(1.4, 0.16, 0.95),
				CFrame.new(point) * CFrame.Angles(0, angle + leaf, 0),
				leaf == 1 and C.autumn or Color3.fromRGB(109, 82, 76), Enum.Material.SmoothPlastic, true)
		end
		if index % 3 == 0 then
			local point = floorAt(frame:PointToWorldSpace(Vector3.new(1.3, 0, 2.6)))
			mesh(group, "BuriedRootFan", "root_serpent", Vector3.new(4.3, 0.8, 2.4),
				CFrame.new(point) * CFrame.Angles(0, angle + 0.6, 0), C.root, Enum.Material.Wood, true)
		end
		if index % 4 == 0 then
			pumpkin(group, "QuietAutumnOffering", frame:PointToWorldSpace(Vector3.new(-1.7, 0, -1.8)),
				0.42, angle + math.pi, index % 2 + 1)
		end
		count.pockets += 1
	end

	local entrance = P.model(art, "CastleEntranceVigil")
	-- These two authored shoulder sites intentionally sit inside the castle's
	-- broad decoration reservation. They are outside the actual undercroft,
	-- manor wings and full procession envelope; all new pieces remain soft.
	for index, spec in ipairs({
		{ at = Vector3.new(-52, 0, 13), template = "tree_widow", size = Vector3.new(23, 25, 17), angle = -0.20 },
		{ at = Vector3.new(64, 0, 30), template = "tree_claw", size = Vector3.new(30, 27, 20), angle = 2.48 },
	}) do
		if not Layout.processionReserved(spec.at, 13) then
			local tree = P.model(entrance, "FramingTree" .. index)
			local grounded = Grounding.position(art, spec.at)
			local frame = CFrame.new(grounded) * CFrame.Angles(0, spec.angle, 0)
			mesh(tree, "CrookedTrunk", spec.template, spec.size, frame, C.wood, Enum.Material.Wood, true, true)
			for crown = 1, 2 do
				local offset = index == 1 and Vector3.new(crown == 1 and -4 or 3, crown == 1 and 18 or 21, crown == 1 and 2 or -3)
					or Vector3.new(crown == 1 and -4 or 5, crown == 1 and 17 or 21, crown == 1 and 3 or -2)
				mesh(tree, "GatheredMoonLeaves" .. crown, crown == 1 and "foliage_crescent" or "foliage_swept",
					Vector3.new(12, crown == 1 and 3.4 or 4.0, 7.5), frame * CFrame.new(offset)
						* CFrame.Angles(math.rad(8), crown * 0.65, math.rad(-9)),
					leafColors[(index + crown) % #leafColors + 1], Enum.Material.SmoothPlastic, false, true)
			end
			for glint = 1, 2 do
				accent(tree, "QuietVioletWisp" .. glint, Vector3.new(0.45, 1.35, 0.34),
					frame * CFrame.new(index == 1 and -4 or 4, 10.0 + glint * 2.1, 1.9)
						* CFrame.Angles(0, 0, math.rad(glint * 17 - 21)), C.violetBright, Enum.Material.Neon, 0.50)
			end
		end
	end

	for _, side in ipairs({ -1, 1 }) do
		local frame = CFrame.new(Grounding.position(art, Vector3.new(side * 38, 0, 7)))
			* CFrame.Angles(0, side * 0.25, 0)
		local bed = P.model(entrance, side < 0 and "WestRootGarden" or "EastRootGarden")
		mesh(bed, "FoundationRootCurl", "root_serpent", Vector3.new(9.5, 1.15, 5.2), frame,
			C.root, Enum.Material.Wood, true)
		for blade = 1, 3 do
			tuft(bed, "MourningGrass" .. blade, frame:PointToWorldSpace(Vector3.new(-3.5 + blade * 2.5, 0, 2.4)),
				side * 0.25 + blade, leafColors[blade], Vector3.new(4.2, 1.2, 2.6))
		end
		for offering = 1, 3 do
			pumpkin(bed, "CarvedAutumnOffering" .. offering,
				frame:PointToWorldSpace(Vector3.new(-4.0 + offering * 2.4, 0, -2.2 + offering % 2)),
				offering == 1 and 0.92 or (offering == 2 and 0.61 or 0.38),
				side * 0.25 + math.pi, offering == 3 and 2 or 1)
		end

		local point = Grounding.position(art, Vector3.new(side * 34, 0, 29))
		local lantern = P.model(entrance, side < 0 and "WestGroundWatchlight" or "EastGroundWatchlight")
		mesh(lantern, "BuriedMoonSocket", "rock_crag", Vector3.new(2.6, 0.86, 2.4),
			CFrame.new(point), C.stoneMoss, Enum.Material.Slate, true)
		mesh(lantern, "HandLanternHousing", "final_lantern", Vector3.new(2.4, 3.5, 2.4),
			CFrame.new(point + Vector3.new(0, 0.65, 0)), C.iron, Enum.Material.Metal, true)
		local tint = side < 0 and Color3.fromRGB(220, 167, 120) or Color3.fromRGB(170, 123, 231)
		local flame = accent(lantern, "LowVigilFlame", Vector3.new(0.56, 0.90, 0.56),
			CFrame.new(point + Vector3.new(0, 2.15, 0)), tint, Enum.Material.Neon, 0.25)
		if flame and count.lights < 2 then
			P.light(flame, tint, side < 0 and 21 or 25, side < 0 and 0.75 or 0.90)
			count.lights += 1
		end
		-- Funeral accents attach beside the existing entrance, above all player
		-- and Curse interaction height; they leave the gothic opening readable.
		local wingHeight = side < 0 and 33 or 28
		local wingFaceZ = side < 0 and -14.25 or -8.25
		mesh(entrance, "HighMourningChain" .. side, "final_chain", Vector3.new(0.62, 5.2, 0.42),
			CFrame.new(side * 35.5, wingHeight - 2.6, wingFaceZ) * CFrame.Angles(0, 0, side * 0.05), C.iron, Enum.Material.Metal)
		mesh(entrance, "TatteredGateOffering" .. side, "foliage_tattered", Vector3.new(2.0, 3.5, 0.50),
			CFrame.new(side * 35.7, wingHeight - 6.7, wingFaceZ) * CFrame.Angles(0, side * 0.06, side * 0.05),
			Color3.fromRGB(85, 62, 108), Enum.Material.Fabric)
	end

	local burial = P.model(art, "CemeteryUnderstory")
	local burialCount = 0
	for index, plot in ipairs(TerrainArt.Plots) do
		if not plot.active or burialCount >= 8 then continue end
		local frame = CFrame.new(plot.x, 0, plot.z) * CFrame.Angles(0, math.rad(plot.angle), 0)
		local at = frame:PointToWorldSpace(Vector3.new(index % 2 == 0 and 12.2 or -12.2, 0, -7.8))
		if not Layout.reserved(at, 6) then
			burialCount += 1
			smallPocket(burial, "WildBurialEdge" .. index, at, math.rad(plot.angle) + 0.4, burialCount)
		end
	end

	local forest = P.model(art, "ForestFloorVigils")
	local forestCount = 0
	for candidate = 1, 64 do
		if forestCount >= 12 or count.parts > PART_BUDGET - 12 then break end
		local angle = math.rad(candidate * 137.508 + 37)
		local at = D.polar(118 + candidate * 41 % 212, angle)
		if not Layout.reserved(at, 8) then
			forestCount += 1
			smallPocket(forest, "MoonlitFloorPocket" .. forestCount, at, angle - 0.4, forestCount + 8)
		end
	end

	art:SetAttribute("PartBudget", PART_BUDGET)
	art:SetAttribute("BasePartCount", count.parts)
	art:SetAttribute("MeshPartCount", count.meshes)
	art:SetAttribute("AddedLightCount", count.lights)
	art:SetAttribute("MissingVerifiedTemplateCount", count.missing)
	art:SetAttribute("BurialPocketCount", burialCount)
	art:SetAttribute("ForestPocketCount", forestCount)
	map:SetAttribute("WorldPolishParts", count.parts)
	map:SetAttribute("WorldPolishMeshParts", count.meshes)
	map:SetAttribute("WorldPolishLights", count.lights)
	map:SetAttribute("WorldPolishMissingTemplates", count.missing)
	assert(count.parts <= PART_BUDGET, "World polish exceeded its static part budget")
	return art
end

return WorldPolish
