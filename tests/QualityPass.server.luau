-- Read-only Studio validator, excluded from default.project.json. The
-- -QualityPass fixture keeps the real production entrypoint/procession. This
-- checks authored bounding/support contracts, not exact triangles or a physical
-- character walk. Root-level manual Studio review remains required.
local HttpService = game:GetService("HttpService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local server = game:GetService("ServerScriptService"):WaitForChild("Server", 30)
assert(server and server:FindFirstChild("Map"), "Production Server.Map is missing")
local Config = require(server.Map.Config)
local Layout = require(server.Map.Layout)
local map = workspace:WaitForChild(Config.MapName, 30)
assert(map and map:IsA("Model"), "Production map did not finish building")
local bases = map:WaitForChild("PlayerSanctuaries", 10)
assert(bases and bases:IsA("Model"), "PlayerSanctuaries is missing")
local firstBase = bases:WaitForChild("Base01", 10)
assert(firstBase and firstBase:WaitForChild("ClaimMarker", 10), "Production BaseService did not initialize")
task.wait(0.5)

local failures, warnings = {}, {}
local report = {
	method = "Read-only runtime contracts and bounding-box support/hull checks. Eight navmesh paths are not physical walks. Hanging props are excluded from grounding. Triangle gaps, hull snagging and appearance need player-height review.",
	counts = { baseParts = 0, meshParts = 0, collisionHulls = 0, colliders = 0, lights = 0, emitters = 0, groundedMeshes = 0, blockingMeshes = 0, softMeshes = 0, nonBlockingMeshes = 0 },
	bases = {}, paths = {}, grounding = {},
	footprint = { width = Config.PlayableWidth, depth = Config.PlayableDepth, boundaryRadius = Config.OuterFenceRadius },
	layout = { baseSites = #Config.BaseSites, processionPoints = #Layout.ProcessionPoints, processionLengthStuds = 0, minimumBaseCenterSeparation = math.huge },
}
local function check(value: boolean, label: string)
	if not value then table.insert(failures, label) end
	return value
end
local function required(parent: Instance, name: string, className: string): Instance?
	local child = parent:FindFirstChild(name)
	if check(child ~= nil and child:IsA(className), parent:GetFullName() .. " requires direct " .. name .. " (" .. className .. ")") then
		return child
	end
	return nil
end
local function environment(item: Instance): boolean
	local active = map:FindFirstChild("ActiveCurses")
	return active == nil or not item:IsDescendantOf(active)
end
local function minimumY(part: BasePart): number
	local frame, half = part.CFrame, part.Size * 0.5
	return frame.Position.Y - math.abs(frame.RightVector.Y) * half.X
		- math.abs(frame.UpVector.Y) * half.Y - math.abs(frame.LookVector.Y) * half.Z
end
local function withinMeshBounds(mesh: MeshPart, hull: BasePart): boolean
	-- Small tolerance permits a simple narrow hull to support the visible shell.
	-- This does not prove per-triangle fit: in particular, doorways must use jambs.
	local half = mesh.Size * 0.5 + Vector3.new(0.4, 0.4, 0.4)
	for _, x in ipairs({ -1, 1 }) do
		for _, y in ipairs({ -1, 1 }) do
			for _, z in ipairs({ -1, 1 }) do
				local point = hull.CFrame:PointToWorldSpace(hull.Size * Vector3.new(x, y, z) * 0.5)
				local p = mesh.CFrame:PointToObjectSpace(point)
				if math.abs(p.X) > half.X or math.abs(p.Y) > half.Y or math.abs(p.Z) > half.Z then return false end
			end
		end
	end
	return true
end
local counts = report.counts
local uniqueIds = {}
for _, item in ipairs(map:GetDescendants()) do
	if not environment(item) then continue end
	if item:IsA("BasePart") then
		counts.baseParts += 1
		check(item.Anchored, "Unanchored environment: " .. item:GetFullName())
		if item.CanCollide then counts.colliders += 1 end
		if item:GetAttribute("EnvironmentCollisionHull") == true then
			counts.collisionHulls += 1
			check(item:IsA("Part") or item:IsA("WedgePart"), "Hull must use simple native geometry: " .. item:GetFullName())
			check(item.Transparency == 1 and not item.CastShadow and item.CanCollide and item.CanQuery and not item.CanTouch,
				"Collision hull visibility/collision flags: " .. item:GetFullName())
		end
		if item:IsA("MeshPart") then
			counts.meshParts += 1
			uniqueIds[item.MeshId] = true
			check(string.match(item.MeshId, "^rbxassetid://[1-9]%d*$") ~= nil, "MeshId missing/invalid: " .. item:GetFullName())
			check(not item.CanCollide, "Environment meshes must use simple separate hulls: " .. item:GetFullName())
			check(math.max(item.Size.X, item.Size.Y, item.Size.Z) <= 200, "Abnormally giant environment mesh: " .. item:GetFullName())
			local category = item:GetAttribute("CollisionCategory")
			check(category == "Blocking" or category == "Soft" or category == "NonBlocking", "Mesh collision category missing: " .. item:GetFullName())
			if category == "Blocking" then counts.blockingMeshes += 1
			elseif category == "Soft" then counts.softMeshes += 1
			elseif category == "NonBlocking" then counts.nonBlockingMeshes += 1 end
			local folder = item:FindFirstChild("CollisionHulls")
			local hullCount = 0
			if folder then
				check(folder:IsA("Folder"), "CollisionHulls must be a Folder: " .. item:GetFullName())
				for _, hull in ipairs(folder:GetChildren()) do
					if hull:IsA("BasePart") then
						hullCount += 1
						check(hull:GetAttribute("EnvironmentCollisionHull") == true
							and hull:GetAttribute("CollisionSource") == item:GetAttribute("SourceTemplate"),
							"Hull source metadata mismatch: " .. hull:GetFullName())
						check(withinMeshBounds(item, hull), "Hull exceeds mesh bounds: " .. hull:GetFullName())
					end
				end
			end
			check(item:GetAttribute("CollisionHullCount") == hullCount, "Hull count metadata mismatch: " .. item:GetFullName())
			if category == "Blocking" then check(hullCount > 0, "Blocking mesh has no collision hull: " .. item:GetFullName()) end
			if category == "NonBlocking" then check(hullCount == 0, "Nonblocking mesh unexpectedly blocks: " .. item:GetFullName()) end
			if item:GetAttribute("GroundedPlacement") == true then
				counts.groundedMeshes += 1
				local supportY = item:GetAttribute("SupportY")
				local inset = item:GetAttribute("GroundInset")
				if check(typeof(supportY) == "number" and typeof(inset) == "number", "Ground support metadata missing: " .. item:GetFullName()) then
					-- Metadata is authored before Build's one-stud global translation.
					local expected = supportY + Config.MapElevation - inset
					local actual = minimumY(item)
					check(math.abs(actual - expected) <= 0.06, "Grounded world bounds mismatch: " .. item:GetFullName())
					table.insert(report.grounding, { name = item:GetFullName(), bottomY = actual, expectedY = expected, inset = inset })
				end
			end
		end
	elseif item:IsA("Light") then
		if item.Enabled then counts.lights += 1 end
	elseif item:IsA("ParticleEmitter") then
		if item.Enabled then counts.emitters += 1 end
	end
end
counts.uniqueMeshIds = 0
for _ in pairs(uniqueIds) do counts.uniqueMeshIds += 1 end
check(counts.groundedMeshes > 0, "No grounded-placement contracts were recorded")
check(counts.blockingMeshes > 0 and counts.collisionHulls > 0, "No deliberately classified blocking mesh hulls were built")
if counts.baseParts > 6000 then table.insert(warnings, "Environment exceeds 6000 BaseParts; profile modest mobile hardware") end
if counts.lights > 24 then table.insert(warnings, "Enabled environmental lights exceed 24; review mobile lighting budget") end
if counts.emitters > 4 then table.insert(warnings, "Enabled emitters exceed 4; review particle/transparency budget") end

check(#bases:GetChildren() == 8 and Config.BaseCount == 8 and #Config.BaseSites == 8, "Exactly eight authored sanctuaries must remain")
for first = 1, #Config.BaseSites do
	local site = Config.BaseSites[first]
	local frame = Config.baseFrame(first)
	if site.x and site.z then
		check(math.abs(frame.Position.X - site.x) < 0.01 and math.abs(frame.Position.Z - site.z) < 0.01,
			"Expanded base site coordinates and legacy frame agree: " .. first)
	end
	for last = first + 1, #Config.BaseSites do
		local delta = frame.Position - Config.baseFrame(last).Position
		local distance = Vector2.new(delta.X, delta.Z).Magnitude
		report.layout.minimumBaseCenterSeparation = math.min(report.layout.minimumBaseCenterSeparation, distance)
		check(distance >= 150, "Sanctuary territories must not stack or touch: " .. first .. " / " .. last)
	end
end
for section = 1, #Layout.ProcessionPoints - 1 do
	report.layout.processionLengthStuds += (Layout.ProcessionPoints[section + 1] - Layout.ProcessionPoints[section]).Magnitude
end
local center = required(map, "CentralMausoleum", "Model")
local curseSpawn = center and required(center, "CurseSpawnPoint", "BasePart")
local floorParams = RaycastParams.new()
floorParams.FilterType = Enum.RaycastFilterType.Include
floorParams.FilterDescendantsInstances = { map }
floorParams.RespectCanCollide = true
for index = 1, 8 do
	local id = string.format("Base%02d", index)
	local base = required(bases, id, "Model")
	if not base then continue end
	local spawn = required(base, "PlayerSpawn", "SpawnLocation")
	local area = required(base, "FutureCurseDisplayArea", "BasePart")
	local marker = required(base, "ClaimMarker", "BasePart")
	local baseResult = { id = id, slots = 0, spawnSupported = false, claimSupported = false, territory = Config.BaseSites[index].territory }
	if spawn then
		check(spawn.Neutral and spawn.Enabled and spawn.Duration == 0, id .. " spawn contract")
		baseResult.spawnSupported = workspace:Raycast(spawn.Position + Vector3.new(0, 4, 0), Vector3.new(0, -10, 0), floorParams) ~= nil
		check(baseResult.spawnSupported, id .. " spawn must have solid floor below")
	end
	if marker then
		local prompt = required(marker, "ClaimSanctuary", "ProximityPrompt")
		check(prompt ~= nil, id .. " claim prompt remains accessible by instance")
		baseResult.claimSupported = workspace:Raycast(marker.Position + Vector3.new(0, 3, 0), Vector3.new(0, -12, 0), floorParams) ~= nil
		check(baseResult.claimSupported, id .. " claim marker must have solid floor below")
	end
	local slots = {}
	for slotIndex = 1, 5 do
		local slot = required(base, "DisplayPlinth_" .. slotIndex, "BasePart")
		if slot then
			baseResult.slots += 1
			table.insert(slots, slot)
			check(slot.Anchored and not slot.CanCollide and slot:GetAttribute("SlotIndex") == slotIndex, id .. " stable direct pedestal contract " .. slotIndex)
			if area then
				local p = area.CFrame:PointToObjectSpace(slot.Position)
				check(math.abs(p.X) + slot.Size.X * 0.5 <= area.Size.X * 0.5 + 0.05
					and math.abs(p.Z) + slot.Size.Z * 0.5 <= area.Size.Z * 0.5 + 0.05, id .. " pedestal within delivery bounds " .. slotIndex)
			end
		end
	end
	for first = 1, #slots do
		for last = first + 1, #slots do check((slots[first].Position - slots[last].Position).Magnitude >= 9, id .. " distinct pedestal spacing") end
	end
	table.insert(report.bases, baseResult)
	if area and curseSpawn then
		local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 6 })
		local ok, err = pcall(function()
			local court = Layout.ProcessionPoints[math.min(3, #Layout.ProcessionPoints)]
			local arrival = curseSpawn.Position + Vector3.new(court.X, 1, court.Z)
			path:ComputeAsync(area.Position + Vector3.new(0, 3, 0), arrival)
		end)
		local pathResult = { base = id, status = if ok then path.Status.Name else tostring(err) }
		check(ok and path.Status == Enum.PathStatus.Success, id .. " route to castle/procession must remain navigable")
		table.insert(report.paths, pathResult)
	end
end

report.failures, report.warnings = failures, warnings
_G.QualityPassReport = report
local reportJson = HttpService:JSONEncode(report)
local observedReport = Instance.new("StringValue")
observedReport.Name = "QualityPassObservedReport"
observedReport:SetAttribute("Publishing", true)
local generation, partCount, partLimit = 1, 0, 90000
if #reportJson <= partLimit then
	observedReport.Value = reportJson
else
	local cursor = 1
	while cursor <= #reportJson do
		local last = math.min(cursor + partLimit - 1, #reportJson)
		-- Keep each stored string valid UTF-8 if a boundary falls inside a codepoint.
		while last < #reportJson do
			local nextByte = string.byte(reportJson, last + 1)
			if not nextByte or nextByte < 128 or nextByte >= 192 then break end
			last -= 1
		end
		partCount += 1
		local part = Instance.new("StringValue")
		part.Name = string.format("Chunk%03d", partCount)
		part.Value = string.sub(reportJson, cursor, last)
		part:SetAttribute("Generation", generation)
		part.Parent = observedReport
		cursor = last + 1
	end
	observedReport.Value = HttpService:JSONEncode({
		transport = "StringValueChunksV1", generation = generation,
		partCount = partCount, totalByteCount = #reportJson,
		phase = if #failures == 0 then "complete" else "failed", requestedPhase = "QualityPass",
	})
end
observedReport:SetAttribute("Completed", true)
observedReport:SetAttribute("FailureCount", #failures)
observedReport:SetAttribute("WarningCount", #warnings)
observedReport:SetAttribute("ReportByteCount", #reportJson)
observedReport:SetAttribute("TotalByteCount", #reportJson)
observedReport:SetAttribute("PartCount", partCount)
observedReport:SetAttribute("Generation", generation)
observedReport:SetAttribute("Publishing", false)
observedReport.Parent = ReplicatedStorage
print("QUALITY_WORLD_REPORT", reportJson)
assert(#failures == 0, "QUALITY_WORLD_FAIL: " .. table.concat(failures, "; "))
print("QUALITY_WORLD_PASS", "Grounded bounds, simple classified hulls, eight sanctuary contracts, forty slots and eight castle navmesh paths. Player-height seating and physical hull/camera review remain separate.")
