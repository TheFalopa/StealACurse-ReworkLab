-- Studio-only final environment validator, excluded from default.project.json.
-- Run after production initialization in Play, or execute this source through
-- Studio MCP against its server datamodel. It never changes map/gameplay state.
local HttpService = game:GetService("HttpService")
local PathfindingService = game:GetService("PathfindingService")
local server = game:GetService("ServerScriptService"):FindFirstChild("Server")
assert(server and server:FindFirstChild("Map"), "Production Server.Map is missing")
local Config = require(server.Map.Config)
local map = workspace:FindFirstChild(Config.MapName)
assert(map and map:IsA("Model"), "Build the final map before validation")

local failures = {}
local warnings = {}
local report = {
	bases = {}, counts = {}, procession = {}, paths = {},
	method = "Map contracts; 1-stud procession sphere samples; Roblox navmesh paths. Mesh bounding boxes are candidates, not mesh triangle intersections. Path length /16 is an estimate, not an actual timed character walk.",
}
local function check(value, label)
	if not value then table.insert(failures, label) end
	return value
end
local function required(parent: Instance, name: string, className: string)
	local child = parent:FindFirstChild(name)
	if check(child and child:IsA(className), parent:GetFullName() .. " requires direct " .. name .. " (" .. className .. ")") then
		return child
	end
	return nil
end
local function environmentPart(item: Instance): boolean
	local active = map:FindFirstChild("ActiveCurses")
	return not active or not item:IsDescendantOf(active)
end

local counts = { baseParts = 0, meshParts = 0, uniqueMeshIds = 0, lights = 0, enabledLights = 0, emitters = 0, enabledEmitters = 0, colliders = 0, unanchoredEnvironment = 0 }
local meshIds = {}
local solidParts = {}
local visualMeshes = {}
for _, item in ipairs(map:GetDescendants()) do
	if environmentPart(item) then
		if item:IsA("BasePart") then
			counts.baseParts += 1
			if item.CanCollide then
				counts.colliders += 1
				table.insert(solidParts, item)
			end
			if not item.Anchored then counts.unanchoredEnvironment += 1 end
			if item:IsA("MeshPart") then
				counts.meshParts += 1
				meshIds[item.MeshId] = true
				table.insert(visualMeshes, item)
			end
		elseif item:IsA("Light") then
			counts.lights += 1
			if item.Enabled then counts.enabledLights += 1 end
		elseif item:IsA("ParticleEmitter") then
			counts.emitters += 1
			if item.Enabled then counts.enabledEmitters += 1 end
		end
	end
end
for _ in pairs(meshIds) do counts.uniqueMeshIds += 1 end
report.counts = counts
check(counts.unanchoredEnvironment == 0, "All environment parts must be anchored")

local ground = required(map, "Ground", "Model")
local collisionGround = ground and required(ground, "PlayableCollisionGround", "BasePart")
local boundary = required(map, "OuterBoundary", "Model")
local unsupportedBoundary = {}
if collisionGround and boundary then
	local supportParams = RaycastParams.new()
	supportParams.FilterType = Enum.RaycastFilterType.Include
	supportParams.FilterDescendantsInstances = { collisionGround }
	supportParams.RespectCanCollide = true
	for _, wall in ipairs(boundary:GetChildren()) do
		if wall:IsA("BasePart") and string.match(wall.Name, "^InvisibleBoundary_") then
			for _, direction in ipairs({ -1, 0, 1 }) do
				local at = wall.CFrame:PointToWorldSpace(Vector3.new(0, 30, direction * wall.Size.Z * 0.5))
				if not workspace:Raycast(at, Vector3.new(0, -100, 0), supportParams) then unsupportedBoundary[wall.Name] = true end
			end
		end
	end
end
report.unsupportedBoundary = {}
for name in pairs(unsupportedBoundary) do table.insert(report.unsupportedBoundary, name) end
table.sort(report.unsupportedBoundary)
check(next(unsupportedBoundary) == nil, "The complete invisible boundary must lie over solid ground so players cannot fall before reaching it")

local cemetery = required(map, "Cemetery", "Model")
local activePlots = 0
if cemetery then
	for _, child in ipairs(cemetery:GetChildren()) do
		if string.match(child.Name, "^FamilyPlot_%d+$") then activePlots += 1 end
	end
end
report.activeFamilyPlots = activePlots
check(activePlots == 12, "All twelve authored family plots must survive clearance filtering")
local landmarks = required(map, "HauntedLandmarks", "Model")
report.landmarks = {}
if landmarks then
	for _, name in ipairs({ "WidowsOak", "HollowSentinel", "ChainedTree", "MourningTree", "CollapsedChapel", "OldCemeteryGate", "ForgottenWarden", "SpectralRootGarden" }) do
		local present = landmarks:FindFirstChild(name) ~= nil
		report.landmarks[name] = present
		check(present, "Authored landmark was skipped: " .. name)
	end
end

local bases = required(map, "PlayerSanctuaries", "Model")
local byId = {}
if bases then
	check(#bases:GetChildren() == 8, "PlayerSanctuaries must contain exactly eight base models")
	for index = 1, 8 do
		local id = string.format("Base%02d", index)
		local base = required(bases, id, "Model")
		if base then
			byId[index] = base
			local spawn = required(base, "PlayerSpawn", "SpawnLocation")
			local area = required(base, "FutureCurseDisplayArea", "BasePart")
			local claim = required(base, "ClaimMarker", "BasePart")
			local slots = {}
			local baseReport = { id = id, slots = {}, claimReady = false }
			if spawn then
				check(spawn.Neutral and spawn.Enabled and spawn.Duration == 0, id .. " spawn settings must remain enabled and neutral")
				baseReport.spawn = { spawn.Position.X, spawn.Position.Y, spawn.Position.Z }
			end
			if claim and spawn then
				local expected = (spawn.CFrame * CFrame.new(0, 2.5, -9)).Position
				check((claim.Position - expected).Magnitude < 0.05, id .. " derived claim position changed")
				local prompt = required(claim, "ClaimSanctuary", "ProximityPrompt")
				baseReport.claimReady = prompt ~= nil
			end
			for slotIndex = 1, 5 do
				local plinth = required(base, "DisplayPlinth_" .. slotIndex, "BasePart")
				if plinth then
					table.insert(slots, plinth)
					check(plinth.Anchored and not plinth.CanCollide, id .. " slot " .. slotIndex .. " must be stable and nonblocking")
					if area then
						local relative = area.CFrame:PointToObjectSpace(plinth.Position)
						check(math.abs(relative.X) + plinth.Size.X * 0.5 <= area.Size.X * 0.5 + 0.05
							and math.abs(relative.Z) + plinth.Size.Z * 0.5 <= area.Size.Z * 0.5 + 0.05,
							id .. " slot " .. slotIndex .. " lies outside delivery display bounds")
					end
					table.insert(baseReport.slots, { index = slotIndex, position = { plinth.Position.X, plinth.Position.Y, plinth.Position.Z }, topY = plinth.Position.Y + plinth.Size.Y * 0.5 })
				end
			end
			for first = 1, #slots do
				for last = first + 1, #slots do
					check((slots[first].Position - slots[last].Position).Magnitude >= 9, id .. " neighboring slots must stay separated by at least nine studs")
				end
			end
			table.insert(report.bases, baseReport)
		end
	end
end

local function sphereTouchesBounds(part: BasePart, at: Vector3, radius: number): boolean
	local p = part.CFrame:PointToObjectSpace(at)
	local half = part.Size * 0.5
	local outside = Vector3.new(math.max(math.abs(p.X) - half.X, 0), math.max(math.abs(p.Y) - half.Y, 0), math.max(math.abs(p.Z) - half.Z, 0))
	return outside.Magnitude < radius
end
local function sortedKeys(set)
	local keys = {}
	for key in pairs(set) do table.insert(keys, key) end
	table.sort(keys)
	return keys
end
local center = required(map, "CentralMausoleum", "Model")
local spawn = center and required(center, "CurseSpawnPoint", "BasePart")
local ROUTE = {
	Vector2.new(0, 0), Vector2.new(0, 11), Vector2.new(0, 24),
	Vector2.new(-17, 24), Vector2.new(-32, 24), Vector2.new(-36, 34),
	Vector2.new(-20, 39), Vector2.new(0, 39), Vector2.new(20, 39),
	Vector2.new(36, 34), Vector2.new(32, 24), Vector2.new(17, 24), Vector2.new(0, 28),
}
if spawn then
	local collisions, meshCandidates, unsupported = {}, {}, {}
	local samples, length = 0, 0
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = { map }
	rayParams.RespectCanCollide = true
	for section = 1, #ROUTE - 1 do
		local first = spawn.Position + Vector3.new(ROUTE[section].X, 2.25, ROUTE[section].Y)
		local last = spawn.Position + Vector3.new(ROUTE[section + 1].X, 2.25, ROUTE[section + 1].Y)
		local distance = (last - first).Magnitude
		length += distance
		for sample = 0, math.ceil(distance) do
			local at = first:Lerp(last, sample / math.ceil(distance))
			samples += 1
			-- Radius3.5 conservatively covers the current six root meshes plus bob.
			for _, part in ipairs(solidParts) do
				if sphereTouchesBounds(part, at, 3.5) then collisions[part:GetFullName()] = true end
			end
			for _, mesh in ipairs(visualMeshes) do
				if mesh.Transparency < 0.95 and sphereTouchesBounds(mesh, at, 3.5) then meshCandidates[mesh:GetFullName()] = true end
			end
			local floorHit = workspace:Raycast(at, Vector3.new(0, -18, 0), rayParams)
			if not floorHit then unsupported[section] = true end
		end
	end
	report.procession = {
		lengthStuds = length, samples = samples, sphereRadiusStuds = 3.5,
		solidBoundingBoxCandidates = sortedKeys(collisions), visualMeshBoundingBoxCandidates = sortedKeys(meshCandidates),
		unsupportedSegments = sortedKeys(unsupported),
		boundsCaveat = "A hollow doorway or curved mesh may overlap a bounding box without intersecting its triangles. Inspect each reported mesh candidate in Studio; this cannot establish exact mesh triangle clearance.",
	}
	check(next(collisions) == nil, "The full procession sweep overlaps solid collision bounds; inspect reported candidates")
	check(next(unsupported) == nil, "Every procession segment needs walkable ground below for purchase access")
	if next(meshCandidates) then table.insert(warnings, "Inspect procession visual mesh bounding-box candidates; open arch candidates can be expected") end

	local function navigation(first: Vector3, last: Vector3, name: string)
		local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 6 })
		local ok, err = pcall(function() path:ComputeAsync(first, last) end)
		local item = { name = name, status = if ok then path.Status.Name else tostring(err), lengthStuds = 0, jumpWaypoints = 0 }
		if ok and path.Status == Enum.PathStatus.Success then
			local waypoints = path:GetWaypoints()
			for index, waypoint in ipairs(waypoints) do
				if waypoint.Action == Enum.PathWaypointAction.Jump then item.jumpWaypoints += 1 end
				if index > 1 then item.lengthStuds += (waypoint.Position - waypoints[index - 1].Position).Magnitude end
			end
			item.estimatedSecondsAt16 = item.lengthStuds / 16
		else
			table.insert(failures, "No navigable path: " .. name)
		end
		table.insert(report.paths, item)
		return item
	end
	local arrival = spawn.Position + Vector3.new(0, 1, 24)
	local minimum, maximum = math.huge, 0
	for index = 1, 8 do
		local base = byId[index]
		if base and base:FindFirstChild("FutureCurseDisplayArea") then
			local at = base.FutureCurseDisplayArea.Position + Vector3.new(0, 3, 0)
			local result = navigation(at, arrival, base.Name .. " to castle court")
			if result.lengthStuds > 0 then minimum = math.min(minimum, result.lengthStuds); maximum = math.max(maximum, result.lengthStuds) end
			local nextBase = byId[index % 8 + 1]
			if nextBase and nextBase:FindFirstChild("FutureCurseDisplayArea") then
				navigation(at, nextBase.FutureCurseDisplayArea.Position + Vector3.new(0, 3, 0), base.Name .. " to " .. nextBase.Name)
			end
		end
	end
	report.fairness = { shortestBaseCourtPath = if minimum < math.huge then minimum else 0, longestBaseCourtPath = maximum,
		longestToShortest = if minimum > 0 and minimum < math.huge then maximum / minimum else 0 }
	if report.fairness.longestToShortest > 1.45 then table.insert(warnings, "Longest base-to-court route exceeds shortest by45%; review fairness") end
end

report.failures = failures
report.warnings = warnings
print("FINAL_MAP_REPORT", HttpService:JSONEncode(report))
assert(#failures == 0, "FINAL_MAP_FAIL: " .. table.concat(failures, "; "))
print("FINAL_MAP_PASS", "All eight contracts, full solid procession sweep and navmesh routes passed; visual mesh candidates and actual timed gameplay require separate review")
