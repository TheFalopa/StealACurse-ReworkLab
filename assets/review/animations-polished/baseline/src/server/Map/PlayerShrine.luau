local Config = require(script.Parent.Config)
local P = require(script.Parent.Primitives)
local D = require(script.Parent.Decorations)
local AssetKit = require(script.Parent.AssetKit)

local PlayerShrine = {}
local C = Config.Colors
local STONE = Enum.Material.Slate
local FLOOR_TOP = 0.8
local COURT_TOP = 1.15
local PLINTH_TOP = 3.4
local SLOT_POSITIONS = {
	Vector3.new(-13, 0, 3), Vector3.new(13, 0, 3),
	Vector3.new(-13, 0, 16), Vector3.new(13, 0, 16),
	Vector3.new(0, 0, 23),
}

local function piece(parent: Instance, frame: CFrame, name: string, size: Vector3, x: number, y: number, z: number, color: Color3, material: Enum.Material?, options: { [string]: any }?)
	return P.part(parent, name, size, frame * CFrame.new(x, y, z), color, material or STONE, options)
end

local function fence(parent: Instance, frame: CFrame, name: string, x: number, z: number, length: number, rotation: number)
	local support = frame * CFrame.new(x, FLOOR_TOP, z) * CFrame.Angles(0, rotation, 0)
	local placement = support * CFrame.new(0, 2.9, 0)
	if AssetKit.placeGrounded(parent, name, "final_iron_fence", Vector3.new(length, 5.8, 0.75), support, C.iron, Enum.Material.Metal) then
		return
	end
	local native = P.model(parent, name)
	for _, side in ipairs({ -1, 1 }) do
		P.part(native, side < 0 and "LeftPost" or "RightPost", Vector3.new(0.55, 5.8, 0.55),
			placement * CFrame.new(side * (length / 2 - 0.3), 0, 0), C.iron, Enum.Material.Metal)
	end
	for rail = 1, 2 do
		P.part(native, "Rail" .. rail, Vector3.new(length, 0.25, 0.3),
			placement * CFrame.new(0, rail == 1 and -1.4 or 1.1, 0), C.iron, Enum.Material.Metal, { canCollide = false })
	end
	for bar = -2, 2 do
		P.part(native, "Spear" .. bar, Vector3.new(0.19, 5.2, 0.19),
			placement * CFrame.new(bar * length / 6, 0, 0), C.iron, Enum.Material.Metal, { canCollide = false })
	end
	P.part(native, "RailingCollision", Vector3.new(length * 0.96, 4.64, 0.24),
		placement * CFrame.new(0, -0.58, 0), C.iron, Enum.Material.Metal, { transparency = 1, castShadow = false })
end

local function pumpkin(parent: Instance, frame: CFrame, name: string, x: number, z: number, scale: number)
	local size = Vector3.new(3.5, 3.2, 3.5) * scale
	if AssetKit.placeGrounded(parent, name, "final_pumpkin", size,
		frame * CFrame.new(x, FLOOR_TOP, z) * CFrame.Angles(0, x * 0.06, 0), C.pumpkin, Enum.Material.SmoothPlastic) then
		return
	end
	D.pumpkin(parent, name, frame:PointToWorldSpace(Vector3.new(x, FLOOR_TOP, z)))
end

local function lantern(parent: Instance, frame: CFrame, name: string, x: number, z: number, lit: boolean)
	local fixture = P.model(parent, name)
	local outside = x < 0 and -1 or 1
	local postX = x + outside * 1.25
	piece(fixture, frame, "PostSocket", Vector3.new(1.4, 0.24, 1.4), postX, FLOOR_TOP + 0.12, z, C.stoneDark, STONE, { canCollide = false })
	piece(fixture, frame, "CrookedPost", Vector3.new(0.5, 9, 0.5), postX, FLOOR_TOP + 4.5, z, C.iron, Enum.Material.Metal, { canCollide = false })
	P.beam(fixture, "HangingArm", frame:PointToWorldSpace(Vector3.new(postX, 9.8, z)),
		frame:PointToWorldSpace(Vector3.new(x, 9.8, z)), 0.25, C.iron, Enum.Material.Metal, { canCollide = false })
	piece(fixture, frame, "BasketSuspension", Vector3.new(0.12, 0.35, 0.12), x, 9.65, z, C.iron, Enum.Material.Metal, { canCollide = false })
	if not AssetKit.place(fixture, "HangingBasket", "final_lantern", Vector3.new(2.4, 3.2, 2.4),
		frame * CFrame.new(x, 8.05, z), C.iron, Enum.Material.Metal) then
		piece(fixture, frame, "Basket", Vector3.new(1.8, 2.4, 1.8), x, 8.05, z, C.iron, Enum.Material.Metal, { canCollide = false })
		piece(fixture, frame, "Hood", Vector3.new(2.5, 0.4, 2.5), x, 9.45, z, C.roof, STONE, { canCollide = false })
	end
	local glow = piece(fixture, frame, "GhostFlame", Vector3.new(0.8, 1.4, 0.8), x, 8.05, z, C.cyan, Enum.Material.Neon, { canCollide = false, castShadow = false })
	if lit then
		P.light(glow, C.cyan, 23, 0.7)
	end
end

local function gateway(parent: Instance, frame: CFrame)
	local gate = P.model(parent, "SanctuaryGateway")
	if not AssetKit.placeGrounded(gate, "GothicThreshold", "final_gothic_doorway", Vector3.new(30, 19.5, 4.6),
		frame * CFrame.new(0, FLOOR_TOP, -31), C.stoneLight, STONE, { groundInset = 0.06 }) then
		for _, side in ipairs({ -1, 1 }) do
			piece(gate, frame, side < 0 and "WestPier" or "EastPier", Vector3.new(3.5, 12, 3.5), side * 13.2, 6.8, -31, C.stoneLight, STONE)
			P.beam(gate, side < 0 and "WestPointedArch" or "EastPointedArch",
				frame:PointToWorldSpace(Vector3.new(side * 13.2, 12.8, -31)),
				frame:PointToWorldSpace(Vector3.new(0, 19.3, -31)), 2.2, C.stoneLight, STONE, { canCollide = false })
		end
	end
	for _, side in ipairs({ -1, 1 }) do
		piece(gate, frame, "GateFoot" .. side, Vector3.new(5.4, 1, 5.2), side * 12.45, 1.23, -31, C.stoneDark)
		-- The doorway's proud feet define its whole depth bounds. Its upright
		-- shell front is only0.287 of that depth away, not the outer foot edge.
		piece(gate, frame, "Rune" .. side, Vector3.new(0.32, 2.6, 0.16), side * 12.45, 6.9, -32.40, C.violet, Enum.Material.Neon, { canCollide = false, castShadow = false })
		piece(gate, frame, "WeatheredPierBand" .. side, Vector3.new(4.8, 0.24, 4.8), side * 12.45, 3.7, -31, C.stoneMoss, STONE, { canCollide = false })
	end
end

local function collectionCourt(shrine: Model, frame: CFrame)
	local court = P.model(shrine, "CollectionCourt")
	-- One simple support floor; the visible terrace has clipped corners and worn
	-- edges. The 0.35-stud rise needs no jumping and keeps all five slots level.
	piece(court, frame, "TerraceCollision", Vector3.new(47, COURT_TOP - FLOOR_TOP, 35), 0, (COURT_TOP + FLOOR_TOP) / 2, 12.5, C.stoneDark, STONE, { transparency = 1, castShadow = false })
	piece(court, frame, "CourtStone", Vector3.new(46, 0.12, 26), 0, COURT_TOP - 0.06, 12.5, C.stoneDark, STONE, { canCollide = false })
	for _, endSign in ipairs({ -1, 1 }) do
		piece(court, frame, "TerraceEnd" .. endSign, Vector3.new(38, 0.12, 4.2), 0, COURT_TOP - 0.06, 12.5 + endSign * 15.1, C.stoneDark, STONE, { canCollide = false })
		for _, side in ipairs({ -1, 1 }) do
			P.part(court, "Chamfer" .. side .. "_" .. endSign, Vector3.new(7, 0.12, 5),
				frame * CFrame.new(side * 20.1, COURT_TOP - 0.06, 12.5 + endSign * 13.4) * CFrame.Angles(0, math.rad(side * endSign * 32), 0),
				C.stoneDark, STONE, { canCollide = false })
		end
	end
	piece(court, frame, "ApproachStep", Vector3.new(42, 0.18, 3.5), 0, FLOOR_TOP + 0.09, -6.75, C.stoneMoss)
	piece(court, frame, "UpperStep", Vector3.new(42, 0.13, 2.5), 0, FLOOR_TOP + 0.245, -4.8, C.stone)
	for _, side in ipairs({ -1, 1 }) do
		piece(court, frame, "CourtEdge" .. side, Vector3.new(0.38, 0.08, 26), side * 22, COURT_TOP + 0.04, 12.5, C.stoneLight, STONE, { canCollide = false })
	end
	-- The center aisle stays open, including between the rear hero slot and exit.
	for index = 0, 3 do
		piece(court, frame, "AisleStone" .. index, Vector3.new(6.8, 0.045, 3.8), index % 2 == 0 and -0.35 or 0.25, COURT_TOP + 0.03, -1 + index * 5.5, C.stoneMoss, STONE, { canCollide = false })
	end
	for slot, location in ipairs(SLOT_POSITIONS) do
		local ornament = P.model(court, "PedestalArtwork" .. slot)
		local pedestalColor = slot == 5 and C.stoneLight or C.stone
		-- The old 2.5-stud artwork bottom was at 0.9, inside the 1.15 court.
		-- Fit the authored dais BETWEEN the court and unchanged gameplay top.
		if not AssetKit.placeGrounded(ornament, "CollectionPedestal", "final_collection_pedestal", Vector3.new(6, PLINTH_TOP - COURT_TOP, 6),
			frame * CFrame.new(location.X, COURT_TOP, location.Z), pedestalColor, STONE, { groundInset = 0 }) then
			piece(ornament, frame, "PedestalFoot", Vector3.new(6.2, 0.45, 6.2), location.X, 1.35, location.Z, C.stoneDark, STONE)
			piece(ornament, frame, "PedestalStem", Vector3.new(4.7, 1.5, 4.7), location.X, 2.1, location.Z, pedestalColor, STONE)
			piece(ornament, frame, "PedestalCrown", Vector3.new(5.8, 0.55, 5.8), location.X, PLINTH_TOP - 0.275, location.Z, C.stoneLight, STONE)
		end
		for _, side in ipairs({ -1, 1 }) do
			piece(ornament, frame, "CrownWear" .. side, Vector3.new(0.65, 0.025, 0.25), location.X + side * 1.75, PLINTH_TOP + 0.018, location.Z + 1.4,
				C.stoneLight, Enum.Material.SmoothPlastic, { canCollide = false, castShadow = false })
		end
		piece(ornament, frame, "SoulInlay", Vector3.new(2.2, 0.04, 0.27), location.X, PLINTH_TOP + 0.025, location.Z - 1.9,
			slot == 5 and C.violetBright or C.cyan, Enum.Material.Neon, { canCollide = false, castShadow = false })
		-- Keep each functional slot a direct BasePart child. Gameplay positions the
		-- Curse against this exact horizontal top; native inset hulls handle feet.
		local plinth = piece(shrine, frame, "DisplayPlinth_" .. slot, Vector3.new(5.6, 0.3, 5.6), location.X, PLINTH_TOP - 0.15, location.Z,
			pedestalColor, STONE, { transparency = 1, canCollide = false, castShadow = false })
		plinth:SetAttribute("SlotIndex", slot)
	end
end

local function buildOne(parent: Instance, index: number)
	local frame = Config.baseFrame(index)
	local shrine = P.model(parent, string.format("Base%02d", index))
	shrine:SetAttribute("BaseIndex", index)
	shrine:SetAttribute("TerritoryWidth", 60)
	shrine:SetAttribute("TerritoryDepth", 66)
	shrine:SetAttribute("TerritoryName", Config.BaseSites[index].territory)
	piece(shrine, frame, "SanctuaryFloor", Vector3.new(60, FLOOR_TOP, 66), 0, FLOOR_TOP / 2, 0, C.ground, Enum.Material.Ground, { transparency = 1, castShadow = false })
	piece(shrine, frame, "SanctuarySoil", Vector3.new(60, 0.13, 66), 0, FLOOR_TOP - 0.02, 0, C.soil, Enum.Material.Ground, { shape = Enum.PartType.Ball, canCollide = false, castShadow = false })
	-- Broad secondary openings preserve chase routes. Their shallow native ramps
	-- use simple collision rather than the decorative fence meshes.
	for _, side in ipairs({ -1, 1 }) do
		P.part(shrine, "SideApproach" .. side, Vector3.new(12, 0.45, 18),
			frame * CFrame.new(side * 31, 0.25, -8) * CFrame.Angles(0, 0, -side * math.atan(0.65 / 12)),
			C.ground, Enum.Material.Ground, { transparency = 1, castShadow = false })
		for section, location in ipairs({ { z = -24, length = 12 }, { z = 8, length = 10 }, { z = 26, length = 8 } }) do
			local height = 2.1 + (index + section) % 3 * 0.45
			piece(shrine, frame, "BoundaryWall" .. side .. "_" .. section, Vector3.new(1.8, height, location.length), side * 29, FLOOR_TOP + height / 2, location.z, section == 2 and C.stoneMoss or C.stoneDark)
			if section ~= 2 then
				fence(shrine, frame, "BoundaryFence" .. side .. "_" .. section, side * 29, location.z, location.length, math.pi / 2)
			end
		end
		piece(shrine, frame, "RearWall" .. side, Vector3.new(16, 2.8, 1.8), side * 21, FLOOR_TOP + 1.4, 32, C.stoneMoss)
		fence(shrine, frame, "RearFence" .. side, side * 21, 32, 15.5, 0)
		piece(shrine, frame, "FrontRuin" .. side, Vector3.new(10.5, 3.7, 2.6), side * 23.8, FLOOR_TOP + 1.85, -31, C.stoneDark)
		piece(shrine, frame, "FrontRuinCap" .. side, Vector3.new(10.7, 0.22, 2.85), side * 23.8, FLOOR_TOP + 3.77, -31,
			C.stoneMoss, STONE, { canCollide = false })
		for marker = 0, 1 do
			piece(shrine, frame, "TerritoryWard" .. side .. "_" .. marker, Vector3.new(0.18, 0.1, 1.9), side * 27.9, FLOOR_TOP + 0.065, -4 + marker * 21,
				index % 3 == 0 and C.violetBright or C.cyan, Enum.Material.Neon, { canCollide = false, castShadow = false })
		end
	end
	gateway(shrine, frame)
	collectionCourt(shrine, frame)
	for stone = 0, 3 do
		piece(shrine, frame, "EntryFlag" .. stone, Vector3.new(6.4 + stone % 2, 0.09, 4), stone % 2 == 0 and -2.7 or 2.8, FLOOR_TOP + 0.045, -28 + stone * 4.8,
			stone == 2 and C.stoneMoss or C.pathStone, STONE, { canCollide = false })
	end
	local claimArt = P.model(shrine, "ClaimShrineArtwork")
	piece(claimArt, frame, "RuneSocket", Vector3.new(3.8, 0.55, 3.8), -6.8, FLOOR_TOP + 0.275, -27, C.stoneDark, STONE, { canCollide = false })
	local tabletHeight = (math.cos(math.rad(8)) * 3.4 + math.sin(math.rad(8)) * 1.9) / 2
	local tabletFrame = frame * CFrame.new(-6.8, FLOOR_TOP + 0.55 + tabletHeight - 0.08, -27) * CFrame.Angles(0, 0, math.rad(-8))
	P.part(claimArt, "ClaimTablet", Vector3.new(1.9, 3.4, 0.95), tabletFrame, C.stoneLight, STONE, { canCollide = false })
	P.part(claimArt, "ClaimRune", Vector3.new(0.4, 1.35, 0.1), tabletFrame * CFrame.new(0, 0.25, -0.53), C.cyan, Enum.Material.Neon, { canCollide = false, castShadow = false })
	-- The claim marker remains service-owned at (0, -27). Thin inlays lead to it
	-- without filling the broad entry aisle with a new altar or collision.
	piece(claimArt, frame, "ClaimApproachInlay", Vector3.new(5.1, 0.035, 0.22), -3.3, FLOOR_TOP + 0.035, -27,
		C.stoneLight, Enum.Material.SmoothPlastic, { canCollide = false, castShadow = false })
	D.candle(claimArt, "ClaimVigil", frame:PointToWorldSpace(Vector3.new(-9.2, FLOOR_TOP, -27.6)), false)
	lantern(shrine, frame, "WestEntryLantern", -17.5, -28.5, true)
	lantern(shrine, frame, "EastEntryLantern", 17.5, -28.5, false)
	-- Each territory has the same court and exits, with varied peripheral history.
	local treeSide = index % 2 == 0 and -1 or 1
	local _, worldAngle = frame:ToOrientation()
	local family=({"sparse","autumn","dead","broken","haunted","sparse","dead","autumn"})[index]
	D.treeFamily(shrine, "TerritorySentinel", frame:PointToWorldSpace(Vector3.new(treeSide * 26, FLOOR_TOP, 24)),
		worldAngle + index * 0.47, family, 0.78 + index % 3 * 0.045)
	for grave = 1, 2 + index % 2 do
		local side = -treeSide
		D.tombstone(shrine, "FamilyGrave" .. grave, frame:PointToWorldSpace(Vector3.new(side * (23 + grave % 2 * 2), FLOOR_TOP, 15 + grave * 4.3)),
			(index * 3 + grave * 4) % 13 - 6, (index + grave) % 3 + 1)
	end
	AssetKit.placeGrounded(shrine, "WeatheredRoot", "root_serpent", Vector3.new(9.2, 2.8, 5.1),
		frame * CFrame.new(treeSide * 25, FLOOR_TOP, 29) * CFrame.Angles(0, index * 0.37, 0), C.root, Enum.Material.Wood, { groundInset = 0.16 })
	pumpkin(shrine, frame, "GatePumpkin", treeSide * 20.3, -25.6, 0.9)
	pumpkin(shrine, frame, "SmallGatePumpkin", treeSide * 23.2, -27.7, 0.6)
	if index % 2 == 0 then
		pumpkin(shrine, frame, "GravePumpkin", -treeSide * 24, 29.8, 0.7)
	end
	D.candle(shrine, "AncestorVigil", frame:PointToWorldSpace(Vector3.new(-treeSide * 24, FLOOR_TOP, 21.5)), index % 3 == 0)
	-- Stable direct markers preserve every server and client dependency. The
	-- service derives its claim prompt nine studs ahead of this spawn, at z=-27.
	local area = piece(shrine, frame, "FutureCurseDisplayArea", Vector3.new(42, 0.2, 34), 0, COURT_TOP + 0.1, 13,
		C.violet, Enum.Material.SmoothPlastic, { transparency = 1, canCollide = false, castShadow = false })
	area:SetAttribute("Purpose", "FutureDisplaySlots")
	local spawn = piece(shrine, frame, "PlayerSpawn", Vector3.new(6, 1, 6), 0, 1.4, -18, C.cyan, Enum.Material.SmoothPlastic,
		{ className = "SpawnLocation", transparency = 1, canCollide = false, castShadow = false }) :: SpawnLocation
	spawn.Neutral = true
	spawn.Enabled = true
	spawn.Duration = 0
	spawn:SetAttribute("Purpose", "UnclaimedBaseSpawn")
	for _, side in ipairs({ -1, 1 }) do
		piece(shrine, frame, "SpawnRune" .. side, Vector3.new(0.4, 0.05, 2.6), side * 4.3, FLOOR_TOP + 0.055, -18,
			C.cyan, Enum.Material.Neon, { canCollide = false, castShadow = false })
	end
	return shrine
end

function PlayerShrine.build(map: Model)
	local sanctuaries = P.model(map, "PlayerSanctuaries")
	for index = 1, Config.BaseCount do
		buildOne(sanctuaries, index)
	end
	return sanctuaries
end

return PlayerShrine
