-- All map dimensions are studs. The center of the mausoleum is the world origin.
local Config = {}

Config.MapName = "StealACurseMap"
-- Studio's original Baseplate can remain at Y=0 after Rojo sync.
-- Keep the entire generated map above it to prevent coplanar surfaces.
Config.MapElevation = 1
Config.BaseCount = 8
Config.BaseRadius = 300
Config.OuterFenceRadius = 406
Config.PlayableWidth = 860
Config.PlayableDepth = 860

-- Gameplay stays evenly distributed, but the sanctuaries do not draw a
-- perfect eight-point ring in overhead views. Each route uses this same site.
Config.BaseSites = {
	{ x = 15, z = 286, height = 0, territory = "South Vigil" },
	{ x = 218, z = 224, height = 1, territory = "Autumn Court" },
	{ x = 299, z = 38, height = 0, territory = "Lantern Wood" },
	{ x = 207, z = -216, height = 2, territory = "Ashen Rise" },
	{ x = -12, z = -299, height = 1, territory = "North Reliquary" },
	{ x = -221, z = -218, height = 0, territory = "Chapel Watch" },
	{ x = -295, z = -18, height = 2, territory = "Widow's Grove" },
	{ x = -212, z = 227, height = 1, territory = "Old Family Court" },
}
for _, site in ipairs(Config.BaseSites) do
	-- Preserve radius/degrees for the existing terrain and placement consumers.
	site.radius = math.sqrt(site.x * site.x + site.z * site.z)
	site.degrees = math.deg(math.atan2(site.x, site.z))
end

Config.ApproachAnchors = {
	{ Vector3.new(0, 0, 85), Vector3.new(24, 0, 157), Vector3.new(14, 0, 229) },
	{ Vector3.new(131, 0, 96), Vector3.new(171, 0, 145), Vector3.new(196, 0, 185) },
	{ Vector3.new(124, 0, -1), Vector3.new(202, 0, 17), Vector3.new(256, 0, 28) },
	{ Vector3.new(84, 0, -118), Vector3.new(132, 0, -163), Vector3.new(169, 0, -190) },
	{ Vector3.new(0, 0, -128), Vector3.new(-17, 0, -194), Vector3.new(-12, 0, -253) },
	{ Vector3.new(-87, 0, -111), Vector3.new(-151, 0, -154), Vector3.new(-190, 0, -187) },
	{ Vector3.new(-104, 0, -20), Vector3.new(-180, 0, -20), Vector3.new(-251, 0, -18) },
	{ Vector3.new(-103, 0, 86), Vector3.new(-148, 0, 149), Vector3.new(-185, 0, 199) },
}

function Config.baseSite(index: number): (number, number)
	local site = Config.BaseSites[index]
	assert(site, "Missing base site")
	return site.radius, math.rad(site.degrees)
end

function Config.baseFrame(index: number): CFrame
	local radius, angle = Config.baseSite(index)
	local height = Config.BaseSites[index].height
	local position = Vector3.new(math.sin(angle) * radius, height, math.cos(angle) * radius)
	return CFrame.lookAt(position, Vector3.new(0, height, 0))
end

-- Composed approach lanes; all decoration reserves their full running width.
function Config.approachPoints(index: number): { Vector3 }
	local radius, angle = Config.baseSite(index)
	local forward = Vector3.new(math.sin(angle), 0, math.cos(angle))
	local anchors = Config.ApproachAnchors[index]
	return {
		anchors[1], anchors[2], anchors[3],
		forward * (radius - 43),
		forward * (radius - 31),
	}
end

function Config.boundaryRadius(angle: number): number
	return Config.OuterFenceRadius + math.sin(angle * 3 + 0.6) * 10 + math.cos(angle * 5) * 6
end

Config.Colors = {
	ground = Color3.fromRGB(70, 76, 101),
	groundPatch = Color3.fromRGB(81, 84, 108),
	path = Color3.fromRGB(101, 88, 119),
	pathStone = Color3.fromRGB(139, 130, 153),
	stone = Color3.fromRGB(98, 103, 128),
	stoneLight = Color3.fromRGB(145, 143, 166),
	stoneDark = Color3.fromRGB(58, 63, 89),
	stoneMoss = Color3.fromRGB(69, 80, 95),
	stoneWarm = Color3.fromRGB(111, 98, 117),
	roof = Color3.fromRGB(43, 43, 73),
	iron = Color3.fromRGB(37, 39, 57),
	wood = Color3.fromRGB(61, 47, 63),
	deadLeaf = Color3.fromRGB(53, 71, 78),
	foliage = Color3.fromRGB(42, 83, 91),
	foliageBlue = Color3.fromRGB(54, 69, 103),
	root = Color3.fromRGB(63, 47, 70),
	violet = Color3.fromRGB(160, 91, 255),
	violetBright = Color3.fromRGB(205, 143, 255),
	cyan = Color3.fromRGB(94, 229, 241),
	green = Color3.fromRGB(123, 218, 141),
	candle = Color3.fromRGB(255, 181, 96),
	pumpkin = Color3.fromRGB(207, 104, 43),
	autumn = Color3.fromRGB(134, 63, 69),
	windowWarm = Color3.fromRGB(255, 202, 136),
	soil = Color3.fromRGB(71, 55, 75),
	moonStone = Color3.fromRGB(164, 162, 186),
}

return Config
