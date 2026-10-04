local Config = require(script.Parent.Config)
local P = require(script.Parent.Primitives)
local D = require(script.Parent.Decorations)
local AssetKit = require(script.Parent.AssetKit)

local Mausoleum = {}
local C = Config.Colors
local STONE = Enum.Material.Slate
local TRIM = Color3.fromRGB(142, 133, 158)
local GLOW = Color3.fromRGB(236, 194, 138)
local WINDOW_VIOLET = Color3.fromRGB(177, 120, 228)

local function stone(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3?)
	return D.slab(parent, name, size, position, color or C.stone)
end

-- Modules retain native fallbacks. AssetKit adds inscribed structural hulls;
-- the simple wall parts still define the castle's original footprint.
local function roof(parent: Instance, name: string, position: Vector3, width: number, depth: number, height: number, lean: number?)
	local group = P.model(parent, name)
	if AssetKit.placeGrounded(group, "CrookedRoof", "final_crooked_roof", Vector3.new(width, height, depth),
		CFrame.new(position), C.roof, STONE) then
		return
	end
	local ridgeX = lean or 1.2
	for _, side in ipairs({ -1, 1 }) do
		local horizontal = width / 2 - side * ridgeX
		local span = math.sqrt(horizontal * horizontal + height * height)
		P.part(group, side < 0 and "WestPitch" or "EastPitch", Vector3.new(span, 1.4, depth),
			CFrame.new(position + Vector3.new(side * width / 4 + ridgeX / 2, height / 2, 0))
				* CFrame.Angles(0, 0, -side * math.atan(height / horizontal)), C.roof, STONE, { canCollide = false })
	end
	stone(group, "BentRidge", Vector3.new(1.7, 1.3, depth + 1), position + Vector3.new(ridgeX, height, 0), C.iron).CanCollide = false
end

local function window(parent: Instance, name: string, position: Vector3, scale: number, color: Color3, angle: number?)
	local group = P.model(parent, name)
	local frame = CFrame.new(position) * CFrame.Angles(0, angle or 0, 0)
	local s = scale
	P.part(group, "HauntedGlass", Vector3.new(3.7, 9, 0.13) * s, frame * CFrame.new(0, -0.6 * s, 0.18 * s),
		color, Enum.Material.Neon, { transparency = 0.2, canCollide = false, castShadow = false })
	if not AssetKit.place(group, "GothicFrame", "final_gothic_window", Vector3.new(6, 13, 1) * s, frame, TRIM, STONE) then
		for _, side in ipairs({ -1, 1 }) do
			P.part(group, side < 0 and "WestJamb" or "EastJamb", Vector3.new(0.72, 8.8, 0.65) * s,
				frame * CFrame.new(side * 2.2 * s, -1.5 * s, 0), TRIM, STONE, { canCollide = false })
			P.beam(group, side < 0 and "WestArch" or "EastArch",
				frame:PointToWorldSpace(Vector3.new(side * 2.2, 2.9, 0) * s),
				frame:PointToWorldSpace(Vector3.new(0, 6, 0) * s), 0.75 * s, TRIM, STONE, { canCollide = false })
		end
		P.part(group, "Sill", Vector3.new(5.8, 0.8, 1.4) * s, frame * CFrame.new(0, -5.7 * s, 0), TRIM, STONE, { canCollide = false })
	end
	P.part(group, "IronMullion", Vector3.new(0.26, 9.2, 0.17) * s, frame * CFrame.new(0, -0.5 * s, 0.35 * s),
		C.iron, Enum.Material.Metal, { canCollide = false })
	P.part(group, "IronTransom", Vector3.new(4.3, 0.26, 0.17) * s, frame * CFrame.new(0, -0.5 * s, 0.35 * s),
		C.iron, Enum.Material.Metal, { canCollide = false })
end

local function buttress(parent: Instance, name: string, position: Vector3, angle: number?)
	local support = CFrame.new(position) * CFrame.Angles(0, angle or 0, 0)
	local frame = support * CFrame.new(0, 9, 0)
	if AssetKit.placeGrounded(parent, name, "final_buttress", Vector3.new(4, 18, 7), support, C.stoneDark, STONE) then
		return
	end
	local group = P.model(parent, name)
	P.part(group, "Pier", Vector3.new(3, 18, 3), frame, C.stoneDark, STONE)
	P.part(group, "SlopedFoot", Vector3.new(4, 7, 7), frame * CFrame.new(0, -5.5, 1.8), C.stoneMoss, STONE, { className = "WedgePart" })
	P.part(group, "WeatheredCap", Vector3.new(4.5, 1, 4.5), frame * CFrame.new(0, 9, 0), TRIM, STONE)
end

local function chain(parent: Instance, name: string, position: Vector3, length: number, angle: number?)
	local frame = CFrame.new(position) * CFrame.Angles(0, 0, angle or 0)
	if not AssetKit.place(parent, name, "final_chain", Vector3.new(1.3, length, 0.95), frame, C.iron, Enum.Material.Metal) then
		P.part(parent, name, Vector3.new(0.23, length, 0.23), frame, C.iron, Enum.Material.Metal, { canCollide = false })
	end
end

local function hangingLantern(parent: Instance, name: string, position: Vector3)
	local fixture = P.model(parent, name)
	if not AssetKit.place(fixture, "IronHousing", "final_lantern", Vector3.new(2.4, 4, 2.4), CFrame.new(position), C.iron, Enum.Material.Metal) then
		stone(fixture, "Hood", Vector3.new(2.4, 0.4, 2.4), position + Vector3.new(0, 1.4, 0), C.roof).CanCollide = false
		stone(fixture, "Foot", Vector3.new(1.8, 0.4, 1.8), position + Vector3.new(0, -1.5, 0), C.iron).CanCollide = false
	end
	P.part(fixture, "SoulFlame", Vector3.new(1, 1.8, 1), CFrame.new(position), GLOW, Enum.Material.Neon,
		{ shape = Enum.PartType.Ball, transparency = 0.15, canCollide = false, castShadow = false })
end

local function guardian(parent: Instance, name: string, position: Vector3, inward: number)
	local figure = P.model(parent, name)
	stone(figure, "Plinth", Vector3.new(6, 1.2, 6), position + Vector3.new(0, 0.6, 0), C.stoneLight)
	if not AssetKit.placeGrounded(figure, "StoneWarden", "stone_warden", Vector3.new(6.6, 15.3, 4.2),
		CFrame.new(position + Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, inward, 0), C.stoneDark, STONE) then
		stone(figure, "Robe", Vector3.new(4, 9, 3.2), position + Vector3.new(0, 5.7, 0), C.stoneDark)
		P.part(figure, "Hood", Vector3.new(4.2, 4, 3.8), CFrame.new(position + Vector3.new(0, 12.2, 0)), C.stoneMoss, STONE,
			{ shape = Enum.PartType.Ball, canCollide = false })
		stone(figure, "FaceVoid", Vector3.new(2, 1.7, 0.18), position + Vector3.new(0, 12, 1.92), C.roof).CanCollide = false
	end
	P.part(figure, "HeldSoul", Vector3.new(1.2, 1.8, 1.2), CFrame.new(position + Vector3.new(2.2, 10.6, 1.6)),
		WINDOW_VIOLET, Enum.Material.Neon, { shape = Enum.PartType.Ball, canCollide = false, castShadow = false })
end

local function doorway(parent: Instance, name: string, position: Vector3, turn: number?)
	local group = P.model(parent, name)
	local frame = CFrame.new(position) * CFrame.Angles(0, turn or 0, 0)
	if AssetKit.placeGrounded(group, "GreatGothicArch", "final_gothic_doorway", Vector3.new(26, 29, 3.2),
		frame, TRIM, STONE) then
		return group
	end
	for _, side in ipairs({ -1, 1 }) do
		P.part(group, side < 0 and "WestGatePier" or "EastGatePier", Vector3.new(4, 19, 3.2),
			frame * CFrame.new(side * 11, 9.5, 0), TRIM, STONE)
		P.beam(group, side < 0 and "WestPointedArch" or "EastPointedArch",
			frame:PointToWorldSpace(Vector3.new(side * 11, 19, 0)), frame:PointToWorldSpace(Vector3.new(0, 28, 0)),
			2.5, TRIM, STONE, { canCollide = false })
		P.part(group, side < 0 and "WestGateSocket" or "EastGateSocket", Vector3.new(4.7, 1.2, 4.3),
			frame * CFrame.new(side * 11, 0.6, 0), C.stoneDark, STONE)
	end
	return group
end

local function tower(parent: Instance, name: string, x: number, z: number, width: number, height: number, roofHeight: number, belfry: boolean)
	local group = P.model(parent, name)
	stone(group, "MassiveShaft", Vector3.new(width, height, width), Vector3.new(x, height / 2, z), C.stoneDark)
	stone(group, "Footing", Vector3.new(width + 3, 2.3, width + 3), Vector3.new(x, 1.15, z), C.stoneMoss)
	for _, level in ipairs({ height * 0.42, height * 0.78, height }) do
		stone(group, string.format("StoneBelt_%d", math.floor(level)), Vector3.new(width + 1.8, 1.3, width + 1.8), Vector3.new(x, level, z), TRIM)
	end
	local roofBase = height + 1
	if belfry then
		for _, side in ipairs({ -1, 1 }) do
			for _, front in ipairs({ -1, 1 }) do
				stone(group, string.format("BellPier_%d_%d", side, front), Vector3.new(2.5, 14, 2.5),
					Vector3.new(x + side * (width / 2 - 2), height + 8, z + front * (width / 2 - 2)), C.stoneLight)
			end
		end
		stone(group, "BellCrown", Vector3.new(width + 3, 1.8, width + 3), Vector3.new(x, height + 15.6, z), C.stoneMoss)
		P.part(group, "OccultBell", Vector3.new(5, 6.5, 5), CFrame.new(x, height + 8.3, z), C.stoneWarm, Enum.Material.Metal,
			{ shape = Enum.PartType.Ball, canCollide = false })
		chain(group, "BellSuspension", Vector3.new(x, height + 12, z), 6)
		roofBase = height + 16.5
	end
	roof(group, "JaggedTowerCrown", Vector3.new(x, roofBase, z), width + 4, width + 4, roofHeight, x < 0 and -2.5 or 2)
	P.beam(group, "CrookedNeedle", Vector3.new(x + 1.5, roofBase + roofHeight - 1, z),
		Vector3.new(x - 1.5, roofBase + roofHeight + 9, z - 1), 1.15, C.iron, Enum.Material.Metal, { canCollide = false })
	window(group, "TowerWindow", Vector3.new(x, height * 0.64, z + width / 2 + 0.18), width > 16 and 1.15 or 0.8, WINDOW_VIOLET)
end

function Mausoleum.build(map: Model)
	-- These direct-child names are consumed by CurseProcessionService.
	local center = P.model(map, "CentralMausoleum")
	center:SetAttribute("EnvironmentDesign", "The Hollow Crown Sanctum")
	local castle = P.model(center, "HollowCrownCastle")

	-- Solid side wings flank an open north/south ground-level undercroft.
	-- Rear sanctuaries can reach the procession without circling the building.
	for _, side in ipairs({ -1, 1 }) do
		local label = side < 0 and "West" or "East"
		local wingHeight = side < 0 and 33 or 28
		local wingZ = side < 0 and -30 or -24
		stone(castle, label .. "ManorWing", Vector3.new(24, wingHeight, 31), Vector3.new(side * 27, wingHeight / 2, wingZ), C.stone)
		stone(castle, label .. "WingFooting", Vector3.new(25.5, 1.5, 33), Vector3.new(side * 27, 0.75, wingZ), C.stoneMoss)
		stone(castle, label .. "WingCornice", Vector3.new(26, 1.8, 33), Vector3.new(side * 27, wingHeight + 0.7, wingZ), TRIM)
		roof(castle, label .. "ManorRoof", Vector3.new(side * 27, wingHeight + 1.5, wingZ), 28, 35, side < 0 and 18 or 22, side * 2)
		stone(castle, label .. "UndercroftWall", Vector3.new(3, 24, 66), Vector3.new(side * 13.5, 12, -38), C.stoneDark)
		stone(castle, label .. "HallCornice", Vector3.new(4.5, 1.5, 68), Vector3.new(side * 13.5, 24, -38), TRIM)
		for _, z in ipairs({ -13, -38, -64 }) do
			buttress(castle, string.format("%sOuterButtress_%d", label, z), Vector3.new(side * 40, 0, z), side < 0 and math.pi / 2 or -math.pi / 2)
		end
		window(castle, label .. "GroundWindow", Vector3.new(side * 27, 10.8, wingZ + 15.7), 0.95, GLOW)
		window(castle, label .. "UpperWindow", Vector3.new(side * 27, wingHeight - 6, wingZ + 15.7), 0.8, WINDOW_VIOLET)
		window(castle, label .. "SideWindow", Vector3.new(side * 39.2, 18, wingZ - 3), 1.1, GLOW, side * math.pi / 2)
	end

	stone(castle, "UpperNave", Vector3.new(26, 22, 66), Vector3.new(0, 35, -38), C.stone)
	stone(castle, "NaveFrontCornice", Vector3.new(29, 1.5, 3), Vector3.new(0, 46.6, -4.5), TRIM)
	stone(castle, "NaveRearCornice", Vector3.new(29, 1.5, 3), Vector3.new(0, 46.6, -71.5), TRIM)
	roof(castle, "HighNaveRoof", Vector3.new(0, 47.5, -38), 31, 68, 24, -2)
	roof(castle, "FrontGable", Vector3.new(0, 46.8, -8), 27, 16, 21, 1.6)
	roof(castle, "RearGable", Vector3.new(0, 46.8, -67), 25, 15, 19, -1.8)
	stone(castle, "RearHallLintel", Vector3.new(26, 3, 3), Vector3.new(0, 22.5, -72), C.stoneDark)
	tower(castle, "WestMourningBelfry", -29, -51, 19, 62, 22, true)
	tower(castle, "EastBrokenTower", 32, -42, 16, 41, 15, false)
	tower(castle, "RearReliquarySpire", 18, -64, 12, 42, 16, false)

	local front = doorway(castle, "CurseEntrance", Vector3.new(0, 0, -2))
	doorway(castle, "RearUndercroftEntrance", Vector3.new(0, 0, -73), math.pi)
	-- Flush floors preserve root clearance and the original procession offsets.
	stone(castle, "UndercroftFloor", Vector3.new(23, 0.3, 72), Vector3.new(0, 0.15, -36.5), C.stoneDark)
	stone(front, "Threshold", Vector3.new(17, 0.32, 4), Vector3.new(0, 0.16, -1.6), C.pathStone)
	for index = 0, 5 do
		P.part(castle, string.format("UnderhallFlagstone_%02d", index + 1), Vector3.new(6.6, 0.1, 6.7),
			CFrame.new(index % 2 == 0 and -5.1 or 4.3, 0.325, -9 - index * 9.8) * CFrame.Angles(0, math.rad(index % 2 == 0 and -5 or 7), 0),
			index % 2 == 0 and C.stoneMoss or C.pathStone, STONE, { canCollide = false })
	end

	local veil = P.part(front, "SpectralVeil", Vector3.new(16.5, 18.5, 0.1), CFrame.new(0, 9.6, -3.25),
		WINDOW_VIOLET, Enum.Material.SmoothPlastic, { transparency = 0.88, canCollide = false, castShadow = false })
	P.light(veil, WINDOW_VIOLET, 38, 1.5)
	for _, side in ipairs({ -1, 1 }) do
		P.beam(front, side < 0 and "WestPortalRune" or "EastPortalRune", Vector3.new(side * 8.6, 1, -0.6),
			Vector3.new(side * 8.6, 17.3, -0.6), 0.23, WINDOW_VIOLET, Enum.Material.Neon, { canCollide = false, castShadow = false })
		chain(front, side < 0 and "WestThresholdChain" or "EastThresholdChain", Vector3.new(side * 11.9, 17, -0.1), 10, side * 0.09)
		hangingLantern(front, side < 0 and "WestGateLantern" or "EastGateLantern", Vector3.new(side * 11.9, 11.6, 0.1))
		for index = 0, 1 do
			D.candle(front, string.format("ThresholdCandle_%d_%d", side, index), Vector3.new(side * (15 + index * 2.1), 0, -4.8 + index * 2), false)
		end
	end

	-- The high watching heart is the manor's original occult identity.
	local heart = P.model(castle, "OccultHeartWindow")
	local heartCenter = Vector3.new(0, 34, -3.84)
	for segment = 0, 7 do
		local first = math.rad(segment * 45 + 22.5)
		local second = math.rad((segment + 1) * 45 + 22.5)
		P.beam(heart, string.format("StoneRosette_%02d", segment + 1),
			heartCenter + Vector3.new(math.sin(first) * 7, math.cos(first) * 7, 0),
			heartCenter + Vector3.new(math.sin(second) * 7, math.cos(second) * 7, 0), 1.5, TRIM, STONE, { canCollide = false })
	end
	P.part(heart, "HeartGlass", Vector3.new(8, 8, 0.14), CFrame.new(heartCenter + Vector3.new(0, 0, -0.2)) * CFrame.Angles(0, 0, math.rad(45)),
		WINDOW_VIOLET, Enum.Material.Neon, { transparency = 0.22, canCollide = false, castShadow = false })
	P.part(heart, "WatchingPupil", Vector3.new(1.4, 7.2, 0.3), CFrame.new(heartCenter + Vector3.new(0, 0, 0.18)),
		C.iron, Enum.Material.Metal, { shape = Enum.PartType.Ball, canCollide = false })
	P.beam(heart, "HeartCrossbar", heartCenter + Vector3.new(-4.5, 0, 0.35), heartCenter + Vector3.new(4.5, 0, 0.35),
		0.3, C.iron, Enum.Material.Metal, { canCollide = false })
	window(castle, "RearSanctumWindow", Vector3.new(0, 34, -71.3), 1.25, GLOW, math.pi)

	guardian(castle, "WestSoulWarden", Vector3.new(-46, 0, -11), 0.22)
	guardian(castle, "EastSoulWarden", Vector3.new(46, 0, -11), -0.22)
	for _, side in ipairs({ -1, 1 }) do
		local limbRoot = Vector3.new(side * 42, 0.4, -31)
		local limbFork = Vector3.new(side * 40, 15, -34)
		P.beam(castle, side < 0 and "WestFoundationRoot" or "EastFoundationRoot", limbRoot, limbFork, 3, C.root, Enum.Material.Wood, { canCollide = false })
		P.beam(castle, side < 0 and "WestWallRoot" or "EastWallRoot", limbFork, Vector3.new(side * 31, 28, -31), 1.5, C.root, Enum.Material.Wood, { canCollide = false })
		P.beam(castle, side < 0 and "WestRootClaw" or "EastRootClaw", limbFork, limbFork + Vector3.new(side * 5, 6, -7), 0.8, C.wood, Enum.Material.Wood, { canCollide = false })
		D.pumpkin(castle, side < 0 and "WestAutumnOffering" or "EastAutumnOffering", Vector3.new(side * 46, 0, -3))
		D.rubble(castle, side < 0 and "WestBrokenCornice" or "EastBrokenCornice", Vector3.new(side * 44, 0, -19), side * 0.4, 1.5)
		for index = 0, 1 do
			P.part(castle, string.format("SuspendedGateFragment_%d_%d", side, index), Vector3.new(1.4, 2.8, 1.4),
				CFrame.new(side * (14 + index * 4), 25 + index * 4, -1) * CFrame.Angles(math.rad(12), 0, math.rad(side * 16)),
				C.stoneLight, STONE, { className = "WedgePart", canCollide = false })
		end
	end

	-- Expanded castle grounds preserve the original architecture and open
	-- undercroft. Side steps are not under the shared Curse motion corridor.
	local grounds=P.model(center,"CastleRitualGrounds")
	grounds:SetAttribute("VisualRegion","SourceOfAllCurses")
	for _,side in ipairs({-1,1}) do
		for step=0,3 do
			P.part(grounds,"ArrivalSideStep"..side.."_"..step,Vector3.new(13,0.16+step*0.13,3.8),
				CFrame.new(side*26,(0.16+step*0.13)/2,22-step*3.2),step%2==0 and C.stoneMoss or C.pathStone,STONE)
		end
		local wardAt=Vector3.new(side*56,0,25)
		stone(grounds,"RitualSocket"..side,Vector3.new(6,0.65,6),wardAt+Vector3.new(0,0.325,0),C.stoneDark)
		AssetKit.placeGrounded(grounds,"ArrivalMemorial"..side,"final_hero_grave",Vector3.new(5.8,9.2,2.5),
			CFrame.new(wardAt+Vector3.new(0,0.65,0))*CFrame.Angles(0,side*.25,0),C.stoneLight,STONE,{groundInset=0.04})
		D.lantern(grounds,"CourtGuide"..side,Vector3.new(side*30,0,13),6.5,side<0 and C.violet or C.cyan,false)
		for rune=0,2 do
			P.part(grounds,"BuriedCourtWard"..side.."_"..rune,Vector3.new(2.2,0.05,0.3),
				CFrame.new(side*(32+rune*5),0.065,30+rune*3)*CFrame.Angles(0,side*.4,0),
				C.violet,Enum.Material.Neon,{transparency=0.5,canCollide=false,canQuery=false,castShadow=false})
		end
	end
	for index,at in ipairs({Vector3.new(-58,0,-49),Vector3.new(57,0,-65),Vector3.new(27,0,-93)}) do
		local frame=CFrame.new(at)*CFrame.Angles(0,index*.5,0)
		AssetKit.placeGrounded(grounds,"OldGroundsMemorial"..index,"final_hero_grave",Vector3.new(4,6.5,2),frame,C.stoneMoss,STONE)
		D.candle(grounds,"GroundsMemorialVigil"..index,at+Vector3.new(3,0,2),true)
	end

	-- One restrained emitter uses a built-in Roblox texture; no uploaded VFX.
	local fogAttachment = Instance.new("Attachment")
	fogAttachment.Name = "PortalMistOrigin"
	fogAttachment.Position = Vector3.new(0, -5.5, 0)
	fogAttachment.Parent = veil
	local mist = Instance.new("ParticleEmitter")
	mist.Name = "SpectralThresholdMist"
	mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
	mist.Color = ColorSequence.new(WINDOW_VIOLET)
	mist.LightEmission = 0.2
	mist.Rate = 3
	mist.Lifetime = NumberRange.new(3, 4)
	mist.Speed = NumberRange.new(0.3, 0.7)
	mist.Drag = 1
	mist.SpreadAngle = Vector2.new(75, 75)
	mist.Rotation = NumberRange.new(0, 360)
	mist.RotSpeed = NumberRange.new(-8, 8)
	mist.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 7) })
	mist.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.93), NumberSequenceKeypoint.new(1, 1) })
	mist.Parent = fogAttachment

	-- Three environmental lights; windows/lanterns rely on emissive materials.
	for _, side in ipairs({ -1, 1 }) do
		local lightAnchor = P.part(castle, side < 0 and "WestArrivalLight" or "EastArrivalLight", Vector3.new(0.2, 0.2, 0.2),
			CFrame.new(side * 45, 5, -10), GLOW, Enum.Material.SmoothPlastic, { transparency = 1, canCollide = false, castShadow = false })
		P.light(lightAnchor, GLOW, 22, 0.7)
	end
	local spawnPoint = P.part(center, "CurseSpawnPoint", Vector3.new(3, 0.2, 3), CFrame.new(0, 2, 0),
		C.violet, Enum.Material.SmoothPlastic, { transparency = 1, canCollide = false, castShadow = false })
	spawnPoint:SetAttribute("Purpose", "FutureCurseSpawn")
	spawnPoint:SetAttribute("Entrance", "HollowCrownCastle.CurseEntrance")
	return center
end

return Mausoleum
