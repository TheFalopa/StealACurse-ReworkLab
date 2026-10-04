local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.CurseCatalog)
local Config = require(script.Parent.Config)
local Layout = require(script.Parent.Parent.Map.Layout)
local Motion = require(ReplicatedStorage.Shared.CurseMotionMath)

local Procession = {}

local function routePoint(points: { Vector3 }, lengths: { number }, distance: number): (Vector3, Vector3)
	local traveled = 0
	for index, length in ipairs(lengths) do
		if distance < traveled + length then
			local alpha = math.clamp((distance - traveled) / length, 0, 1)
			return points[index]:Lerp(points[index + 1], alpha), points[index + 1]
		end
		traveled += length
	end
	return points[#points], points[#points] + Vector3.new(0, 0, 1)
end

local function makeRouteArt(map: Model, points: { Vector3 }, spawnPosition: Vector3)
	local routeArt = Instance.new("Folder")
	routeArt.Name = "CurseProcessionRoute"
	routeArt.Parent = map
	routeArt:SetAttribute("PointCount", #points)
	routeArt:SetAttribute("ClearanceHalfWidth", Layout.ProcessionHalfWidth)
	for index, point in points do
		local value = Instance.new("Vector3Value")
		value.Name = string.format("Point_%02d", index)
		value.Value = point
		value.Parent = routeArt
	end
	-- Clear the painted paver tops by 0.06 studs: no coplanar shimmer.
	local routeY = spawnPosition.Y - 1.50
	for index = 1, #points - 1 do
		local from = Vector3.new(points[index].X, routeY, points[index].Z)
		local to = Vector3.new(points[index + 1].X, routeY, points[index + 1].Z)
		local line = Instance.new("Part")
		line.Name = string.format("SpectralTrail_%02d", index)
		line.Size = Vector3.new(0.24, 0.08, (to - from).Magnitude)
		line.CFrame = CFrame.lookAt((from + to) * 0.5, to)
		line.Color = Color3.fromRGB(153, 94, 240)
		line.Material = Enum.Material.Neon
		line.Transparency = 0.56
		line.Anchored = true
		line.CanCollide = false
		line.CanTouch = false
		line.CanQuery = false
		line.CastShadow = false
		line.Parent = routeArt
	end
	local endPoint = points[#points]
	local exit = Instance.new("Part")
	exit.Name = "VeilExit"
	exit.Shape = Enum.PartType.Ball
	exit.Size = Vector3.new(3.4, 3.4, 3.4)
	exit.CFrame = CFrame.new(endPoint)
	exit.Color = Color3.fromRGB(130, 71, 202)
	exit.Material = Enum.Material.Neon
	exit.Transparency = 0.35
	exit.Anchored = true
	exit.CanCollide = false
	exit.CanTouch = false
	exit.CanQuery = false
	exit.CastShadow = false
	exit.Parent = routeArt
end

local testIds = Catalog.enabledSpawnIds()
local testIndex = 0
local Luck = require(script.Parent.LuckService)
local Shares = require(ReplicatedStorage.Shared.ProgressionConfig).SpawnRarityShare

-- "weighted" (default): rarity-weighted spawns through the one Luck
-- calculation. "cycle": every enabled Curse in turn (QA of the full roster).
local function chooseDefinition(random: Random): string
	assert(#testIds > 0, "No hay Curses habilitadas")
	if Config.ProcessionSelection == "cycle" then
		testIndex = testIndex % #testIds + 1
		return testIds[testIndex]
	end
	-- 1) rarity tier by share x Luck (Commons unaffected), 2) Curse in tier.
	local byTier = {}
	for _, id in testIds do
		local d = Catalog.Definitions[id]
		byTier[d.rarity] = byTier[d.rarity] or {}
		table.insert(byTier[d.rarity], id)
	end
	local total, tiers = 0, {}
	for rarity, list in byTier do
		local w = Luck.weight(Shares[rarity] or 0, rarity)
		if w > 0 then table.insert(tiers, { rarity = rarity, weight = w, list = list }) total += w end
	end
	if total <= 0 then return testIds[random:NextInteger(1, #testIds)] end
	local roll = random:NextNumber(0, total)
	local chosen = tiers[#tiers]
	for _, t in tiers do roll -= t.weight if roll <= 0 then chosen = t break end end
	local sum = 0
	for _, id in chosen.list do sum += math.max(Catalog.Definitions[id].spawnWeight, 0.001) end
	local pick = random:NextNumber(0, sum)
	for _, id in chosen.list do
		pick -= math.max(Catalog.Definitions[id].spawnWeight, 0.001)
		if pick <= 0 then return id end
	end
	return chosen.list[#chosen.list]
end

function Procession.start(map: Model, curses)
	local center = map:FindFirstChild("CentralMausoleum")
	assert(center and center:IsA("Model"), "Procession needs CentralMausoleum")
	local spawn = center:FindFirstChild("CurseSpawnPoint")
	assert(spawn and spawn:IsA("BasePart"), "Procession needs CurseSpawnPoint")
	local centerPosition = spawn.Position
	local points = {}
	-- Geometry clearance, road dressing and movement share one authored route.
	assert(#Layout.ProcessionPoints >= 2, "Procession requires at least two route points")
	for _, point in ipairs(Layout.ProcessionPoints) do
		table.insert(points, Vector3.new(point.X, centerPosition.Y + 2.25, point.Z))
	end
	local segmentLengths = {}
	local routeLength = 0
	for index = 1, #points - 1 do
		local length = (points[index + 1] - points[index]).Magnitude
		assert(length > 0.01, "Procession route contains a zero-length segment")
		table.insert(segmentLengths, length)
		routeLength += length
	end
	makeRouteArt(map, points, centerPosition)
	map:SetAttribute("ProcessionRouteLengthStuds", routeLength)
	map.CurseProcessionRoute:SetAttribute("RouteLengthStuds", routeLength)

	local active = {}
	local random = Random.new()
	local function spawnOne()
		local count = 0
		for _ in pairs(active) do
			count += 1
		end
		if count >= Config.MaxProcessionCurses then
			return
		end
		local definitionId = chooseDefinition(random)
		local startPosition, nextPosition = routePoint(points, segmentLengths, 0)
		local uid = curses:spawn(definitionId, CFrame.lookAt(startPosition, nextPosition))
		local epoch, phase = workspace:GetServerTimeNow(), random:NextNumber(0, math.pi * 2)
		active[uid] = { distance = 0, epoch = epoch, phase = phase }
		curses:setProcessionMotion(uid, epoch, Config.ProcessionSpeedStudsPerSecond, phase)
	end

	task.spawn(function()
		task.wait(Config.FirstProcessionDelaySeconds)
		while map.Parent == workspace do
			spawnOne()
			task.wait(Config.ProcessionCadenceSeconds)
		end
	end)

	task.spawn(function()
		local last = os.clock()
		while map.Parent == workspace do
			task.wait(Config.ProcessionStepSeconds)
			local now = os.clock()
			local elapsed = math.max(0, now - last)
			last = now
			for uid, motion in pairs(active) do
				if curses:getState(uid) ~= "PROCESSION" then
					active[uid] = nil
				else
					motion.distance = Config.ProcessionSpeedStudsPerSecond * math.max(0, workspace:GetServerTimeNow() - motion.epoch)
					if motion.distance >= routeLength then
						curses:despawnUnsold(uid)
						active[uid] = nil
					else
						local frame = Motion.route(points, segmentLengths, motion.distance)
						if not curses:moveProcession(uid, frame) then
							active[uid] = nil
						end
					end
				end
			end
		end
	end)

	return { routeLength = routeLength }
end

return Procession
