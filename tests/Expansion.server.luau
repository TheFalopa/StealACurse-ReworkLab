-- Read-only expansion observer. The fixture uses production initialization and
-- natural random spawning. No service calls, credits, teleports, button inputs
-- or forced states are used here. Keep Play running until EXPANSION_DONE.
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local server = game:GetService("ServerScriptService"):WaitForChild("Server", 30)
assert(server and server:FindFirstChild("Map"), "EXPANSION_FAIL: production map modules missing")
local MapConfig = require(server.Map.Config)
local Layout = require(server.Map.Layout)
local GameplayConfig = require(server.Gameplay.Config)
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CurseCatalog"))
local map = workspace:WaitForChild(MapConfig.MapName, 30)
assert(map and map:IsA("Model"), "EXPANSION_FAIL: map did not build")
local active = map:WaitForChild("ActiveCurses", 15)
local route = map:WaitForChild("CurseProcessionRoute", 15)
local center = map:WaitForChild("CentralMausoleum", 10)
local spawn = center and center:WaitForChild("CurseSpawnPoint", 10)
assert(active and route and spawn and spawn:IsA("BasePart"), "EXPANSION_FAIL: procession lifecycle missing")

local failures, warnings = {}, {}
local failedLabels = {}
local report = {
	method = "Read-only natural procession observed for 110 seconds. Conservative root bounding spheres versus simple solid hull bounds; not exact mesh triangle clearance. Tests cannot establish physical walking, visual quality or device FPS.",
	phase = "initializing", failures = failures, warnings = warnings,
	counts = { baseParts = 0, meshParts = 0, lights = 0, emitters = 0, collisionHulls = 0 },
	catalog = { total = 0, expansion = 0, firstWave = 0, availableFirstWaveTemplates = 0, rarities = {}, statuses = {}, imports = {}, pendingImports = {} },
	procession = { points = #Layout.ProcessionPoints, lengthStuds = 0, routeArtSegments = 0, routeArtLengthStuds = 0,
		maximumSimultaneous = 0, observedModels = 0, naturalUnsoldExits = 0, purchasedModels = 0,
		castleEmergences = 0, samples = 0, solidBoundsCandidates = {}, visualTreeBoundsCandidates = {},
		minimumX = math.huge, maximumX = -math.huge, minimumZ = math.huge, maximumZ = -math.huge },
}
local function check(value: boolean, label: string): boolean
	if not value and not failedLabels[label] then failedLabels[label] = true; table.insert(failures, label) end
	return value
end
local function sortedKeys(values)
	local keys = {}
	for key in pairs(values) do table.insert(keys, key) end
	table.sort(keys)
	return keys
end
local function minimumY(part: BasePart): number
	local frame, half = part.CFrame, part.Size * 0.5
	return frame.Position.Y - math.abs(frame.RightVector.Y) * half.X - math.abs(frame.UpVector.Y) * half.Y - math.abs(frame.LookVector.Y) * half.Z
end
local function maximumY(part: BasePart): number
	return part.Position.Y * 2 - minimumY(part)
end
local function sphereTouchesBounds(part: BasePart, at: Vector3, radius: number): boolean
	local p = part.CFrame:PointToObjectSpace(at)
	local half = part.Size * 0.5
	local outside = Vector3.new(math.max(math.abs(p.X) - half.X, 0), math.max(math.abs(p.Y) - half.Y, 0), math.max(math.abs(p.Z) - half.Z, 0))
	return outside.Magnitude < radius
end
local function nearRoute(part: BasePart): boolean
	local radius = part.Size.Magnitude * 0.5 + 4
	local at = part.Position - Vector3.new(spawn.Position.X, MapConfig.MapElevation, spawn.Position.Z)
	for section = 1, #Layout.ProcessionPoints - 1 do
		if Layout.segmentDistance(at, Layout.ProcessionPoints[section], Layout.ProcessionPoints[section + 1]) <= radius then return true end
	end
	return false
end

check(MapConfig.BaseCount == 8 and #MapConfig.BaseSites == 8, "Exactly eight sanctuaries remain authored")
check(MapConfig.PlayableWidth >= 800 and MapConfig.PlayableDepth >= 780, "Playable footprint is substantially expanded from 620 x 610")
check(map:GetAttribute("PlayableWidth") == MapConfig.PlayableWidth and map:GetAttribute("PlayableDepth") == MapConfig.PlayableDepth, "Footprint attributes match construction config")
local bases = map:FindFirstChild("PlayerSanctuaries")
check(bases ~= nil and #bases:GetChildren() == 8, "Exactly eight physical sanctuary models exist")
local slotCount = 0
if bases then
	for index = 1, 8 do
		local base = bases:FindFirstChild(string.format("Base%02d", index))
		if check(base ~= nil, "Base contract exists: " .. index) then
			for slot = 1, 5 do
				local plinth = base:FindFirstChild("DisplayPlinth_" .. slot)
				if check(plinth ~= nil and plinth:IsA("BasePart"), "Physical display slot exists: " .. base.Name .. " / " .. slot) then slotCount += 1 end
			end
		end
	end
end
check(slotCount == 40, "Eight sanctuaries retain forty physical slots")
report.slotCount = slotCount
report.footprint = { width = MapConfig.PlayableWidth, depth = MapConfig.PlayableDepth, areaRatioToPrevious = MapConfig.PlayableWidth * MapConfig.PlayableDepth / (620 * 610) }

-- Three additional Mythics appear on the attached sheet 10, although the prose
-- only lists the first three. They are real concepts, not duplicates/omissions.
local expectedRarities = { COMMON = 15, RARE = 14, LEGENDARY = 10, MYTHIC = 6, SECRET = 5 }
local order = Catalog.AllOrder or {}
local expansionOrder = Catalog.ExpansionOrder or {}
check(#order == 56 and #expansionOrder == 50, "Catalog contains six originals plus all fifty unique reference concepts")
local uniqueIds = {}
for _, id in order do
	check(not uniqueIds[id], "No duplicate catalog ID: " .. id)
	uniqueIds[id] = true
	local definition = Catalog.Definitions[id]
	if check(definition ~= nil and definition.id == id, "Data-driven definition matches ID: " .. id) then
		report.catalog.total += 1
		check(Catalog.Rarities[definition.rarity] ~= nil and typeof(definition.displayName) == "string" and definition.displayName ~= "", "Definition has readable name and rarity: " .. id)
		check(typeof(definition.price) == "number" and definition.price >= 0 and typeof(definition.baseSoulsPerSecond) == "number" and definition.baseSoulsPerSecond >= 0, "Central development economy values exist: " .. id)
		check(typeof(definition.visualKey) == "string" and typeof(definition.futureEffectId) == "string", "Definition retains future visual/effect keys: " .. id)
	end
end
for _, id in expansionOrder do
	local definition = Catalog.Definitions[id]
	if definition then
		report.catalog.expansion += 1
		report.catalog.rarities[definition.rarity] = (report.catalog.rarities[definition.rarity] or 0) + 1
		local status = definition.implementationStatus or "UNTRACKED"
		report.catalog.statuses[status] = (report.catalog.statuses[status] or 0) + 1
		check(typeof(definition.sourceReference) == "string" and definition.sourceReference ~= "", "Expansion definition identifies its concept source: " .. id)
		check(definition.enabled == false and definition.spawnWeight == 0, "Unvalidated expansion is not randomly enabled: " .. id)
	end
end
for rarity, expected in expectedRarities do check(report.catalog.rarities[rarity] == expected, "Expansion reference rarity count: " .. rarity) end
local firstWave = Catalog.FirstWaveOrder or {
	"candle_wisp", "grave_hopper", "grave_key", "ink_imp", "ashen_book",
	"marrow_dice", "grave_compass", "hollow_violin", "raven_quill",
	"night_harp", "thorn_cathedral", "judgement_scales", "cathedral_heart", "hollow_throne", "nameless_door",
}
report.catalog.firstWave = #firstWave
check(#firstWave == 15, "Representative production wave tracks fifteen original models")
local kit = ServerStorage:FindFirstChild("CurseMeshKit")
check(kit ~= nil, "Verified Curse template kit remains available")
if kit then
	for _, id in Catalog.Order do
		local definition = Catalog.Definitions[id]
		local template = definition and kit:FindFirstChild(definition.visualKey)
		check(template ~= nil and template:IsA("MeshPart") and string.match(template.MeshId, "^rbxassetid://[1-9]%d*$") ~= nil, "Original live mesh template retained: " .. id)
	end
	for _, id in firstWave do
		local definition = Catalog.Definitions[id]
		local template = definition and kit:FindFirstChild(definition.visualKey)
		if template and template:IsA("MeshPart") then
			report.catalog.availableFirstWaveTemplates += 1
			check(string.match(template.MeshId, "^rbxassetid://[1-9]%d*$") ~= nil, "Available expansion template has a real ID-shaped value: " .. id)
			check(template.Size.Magnitude < 7 and math.min(template.Size.X, template.Size.Y, template.Size.Z) > 0, "Imported template has game-scale dimensions: " .. id)
			check(template.MeshSize.Magnitude > 0 and (template.Size - template.MeshSize).Magnitude < 0.02, "Imported template preserves MeshSize: " .. id)
			table.insert(report.catalog.imports, { id = id, meshId = template.MeshId, size = { template.Size.X, template.Size.Y, template.Size.Z }, status = definition.implementationStatus })
		else
			table.insert(report.catalog.pendingImports, id)
			check(not definition or (definition.implementationStatus ~= "IMPORTED" and definition.implementationStatus ~= "VALIDATED"), "Catalog must not claim a nonexistent imported template: " .. id)
		end
	end
end
if #report.catalog.pendingImports > 0 then table.insert(warnings, "Blender/FBX production and verified Roblox imports are separate: " .. #report.catalog.pendingImports .. " first-wave templates are not available in this build") end

local worldPoints = {}
for _, point in Layout.ProcessionPoints do table.insert(worldPoints, spawn.Position + Vector3.new(point.X, 2.25, point.Z)) end
check(#worldPoints == 16, "Castle-centered procession has sixteen shared authored points")
for index = 1, #worldPoints - 1 do report.procession.lengthStuds += (worldPoints[index + 1] - worldPoints[index]).Magnitude end
check(report.procession.lengthStuds >= 630 and report.procession.lengthStuds < 660, "Expanded route uses more castle grounds (approximately 636.7 studs)")
for _, line in route:GetChildren() do
	if line:IsA("BasePart") and string.match(line.Name, "^SpectralTrail_") then
		report.procession.routeArtSegments += 1
		report.procession.routeArtLengthStuds += line.Size.Z
	end
end
check(report.procession.routeArtSegments == #worldPoints - 1 and math.abs(report.procession.routeArtLengthStuds - report.procession.lengthStuds) < 0.1, "Visible route segments share the gameplay path, not the previous short loop")
check(route:GetAttribute("PointCount") == #worldPoints and route:GetAttribute("ClearanceHalfWidth") == Layout.ProcessionHalfWidth,
	"Route point/clearance metadata matches the shared layout")
local recordedLength = route:GetAttribute("RouteLengthStuds")
local mapLength = map:GetAttribute("ProcessionRouteLengthStuds")
check(typeof(recordedLength) == "number" and math.abs(recordedLength - report.procession.lengthStuds) < 0.1
	and typeof(mapLength) == "number" and math.abs(mapLength - report.procession.lengthStuds) < 0.1, "Gameplay route-length metadata matches the authored path")
check(GameplayConfig.MaxProcessionCurses <= 6 and GameplayConfig.MaxProcessionCurses >= 3, "Natural procession concurrency remains bounded")
local solids, trees = {}, {}
for _, item in map:GetDescendants() do
	if item:IsDescendantOf(active) then continue end
	if item:IsA("BasePart") then
		report.counts.baseParts += 1
		if item:GetAttribute("EnvironmentCollisionHull") == true then report.counts.collisionHulls += 1 end
		if item:IsA("MeshPart") then
			report.counts.meshParts += 1
			local source = tostring(item:GetAttribute("SourceTemplate") or "")
			if (string.find(source, "tree", 1, true) or string.find(source, "foliage", 1, true)) and nearRoute(item) then table.insert(trees, item) end
		end
		-- Do not flag intentional support floors or the broad outer boundary as
		-- walls. Tall terrain and real nearby architecture/trunk hulls remain.
		local floor = maximumY(item) <= MapConfig.MapElevation + 0.65 or (item.Size.Y < 0.5 and item.CFrame.UpVector.Y > 0.9)
		local broadBoundary = item.Name == "PlayableCollisionGround" or string.match(item.Name, "^InvisibleBoundary_") ~= nil
		if item.CanCollide and not floor and not broadBoundary and nearRoute(item) then table.insert(solids, item) end
	elseif item:IsA("Light") and item.Enabled then report.counts.lights += 1
	elseif item:IsA("ParticleEmitter") and item.Enabled then report.counts.emitters += 1 end
end
report.procession.solidCandidateCount = #solids
local solidHits, treeHits, unsupported = {}, {}, {}
local floorParams = RaycastParams.new()
floorParams.FilterType = Enum.RaycastFilterType.Include
floorParams.FilterDescendantsInstances = { map }
floorParams.RespectCanCollide = true
for section = 1, #worldPoints - 1 do
	local first, last = worldPoints[section], worldPoints[section + 1]
	local steps = math.ceil((last - first).Magnitude / 2)
	for sample = 0, steps do
		local at = first:Lerp(last, sample / steps)
		for _, solid in solids do if sphereTouchesBounds(solid, at, 3.5) then solidHits[solid:GetFullName()] = true end end
		if not workspace:Raycast(at, Vector3.new(0, -18, 0), floorParams) then unsupported[section] = true end
	end
end
check(next(solidHits) == nil, "Shared procession sweep is clear of nearby solid bounds")
check(next(unsupported) == nil, "Procession segments have purchase-access ground below")
report.procession.unsupportedSegments = sortedKeys(unsupported)
report.phase = "observing"
_G.ExpansionReport = report
print("EXPANSION_READY", HttpService:JSONEncode({ footprint = report.footprint, catalog = report.catalog, processionPoints = #worldPoints, routeLength = report.procession.lengthStuds, counts = report.counts, initialFailures = failures }))

local records, connections = {}, {}
local function track(model: Instance)
	if not model:IsA("Model") or not model.PrimaryPart or records[model] then return end
	local root = model.PrimaryPart
	local record = { state = model:GetAttribute("CurseState"), position = root.Position, firstAt = os.clock(), definitionId = model:GetAttribute("DefinitionId") }
	records[model] = record
	report.procession.observedModels += 1
	if record.state == "PROCESSION" and (record.position - worldPoints[1]).Magnitude < 5 then report.procession.castleEmergences += 1 end
	local definition = Catalog.Definitions[record.definitionId]
	check(definition ~= nil and definition.enabled ~= false, "Only enabled definitions naturally spawn: " .. tostring(record.definitionId))
	local info = model:FindFirstChild("CurseInfo")
	local infoPanel = info and info:FindFirstChild("Panel")
	for _, name in { "InfoName", "InfoRarity", "InfoIncome", "InfoPrice" } do
		check(infoPanel ~= nil and infoPanel:FindFirstChild(name) ~= nil, "Procession model retains readable label field: " .. name)
	end
	check(root:FindFirstChild("BuyCurse") ~= nil and not root.CanCollide, "Natural model remains purchasable and noncolliding")
	table.insert(connections, model:GetAttributeChangedSignal("CurseState"):Connect(function()
		local state = model:GetAttribute("CurseState")
		if record.state == "PROCESSION" and state ~= "PROCESSION" then report.procession.purchasedModels += 1 end
		record.state = state
	end))
end
for _, model in active:GetChildren() do track(model) end
table.insert(connections, active.ChildAdded:Connect(function(model) task.defer(function() track(model) end) end))
table.insert(connections, active.ChildRemoved:Connect(function(model)
	local record = records[model]
	if record and record.state == "PROCESSION" then
		local distance = (record.position - worldPoints[#worldPoints]).Magnitude
		check(distance <= 8, "An unsold model exits at the actual route endpoint, not early: " .. tostring(record.definitionId))
		if distance <= 8 then report.procession.naturalUnsoldExits += 1 end
	end
end))
local start = os.clock()
local nextProgress = 20
while os.clock() - start < 110 and map.Parent == workspace do
	task.wait(0.2)
	local simultaneous = 0
	for model, record in records do
		local root = model.Parent == active and model.PrimaryPart
		if root and record.state == "PROCESSION" then
			simultaneous += 1
			record.position = root.Position
			local at, radius = root.Position, root.Size.Magnitude * 0.5 + 0.23
			report.procession.samples += 1
			report.procession.minimumX = math.min(report.procession.minimumX, at.X)
			report.procession.maximumX = math.max(report.procession.maximumX, at.X)
			report.procession.minimumZ = math.min(report.procession.minimumZ, at.Z)
			report.procession.maximumZ = math.max(report.procession.maximumZ, at.Z)
			for _, solid in solids do if solid.Parent and sphereTouchesBounds(solid, at, radius) then solidHits[solid:GetFullName()] = true end end
			for _, tree in trees do if tree.Parent and sphereTouchesBounds(tree, at, radius) then treeHits[tree:GetFullName()] = true end end
		end
	end
	report.procession.maximumSimultaneous = math.max(report.procession.maximumSimultaneous, simultaneous)
	check(simultaneous <= GameplayConfig.MaxProcessionCurses and simultaneous <= 6, "Natural procession does not exceed its concurrency cap")
	if os.clock() - start >= nextProgress then
		print("EXPANSION_OBSERVING", math.floor(os.clock() - start), "seconds; peak", report.procession.maximumSimultaneous, "models; unsold exits", report.procession.naturalUnsoldExits)
		nextProgress += 20
	end
end
for _, connection in connections do connection:Disconnect() end
report.procession.solidBoundsCandidates = sortedKeys(solidHits)
report.procession.visualTreeBoundsCandidates = sortedKeys(treeHits)
check(report.procession.maximumSimultaneous >= 3 and report.procession.observedModels >= 6, "Several natural models coexist with adequate route use")
check(report.procession.castleEmergences >= 1, "Models naturally emerge at the castle spawn")
check(report.procession.naturalUnsoldExits >= 1, "At least one natural unsold model completes and exits the long route")
check(report.procession.minimumX < -75 and report.procession.minimumZ < -95 and report.procession.maximumX > 145 and report.procession.maximumZ > 95, "Observed natural models use front, side/back grounds and final haunted lane")
check(next(solidHits) == nil, "No observed natural model sphere overlaps a nearby solid hull")
if next(treeHits) then table.insert(warnings, "Tree mesh bounding boxes are visual candidates, not triangle intersections; inspect the named canopy/trunk meshes in Play") end
if report.counts.baseParts > 6000 then table.insert(warnings, "Expanded environment exceeds 6000 BaseParts; real-device profiling is still required") end
if report.procession.observedModels == 0 then
	report.procession.minimumX, report.procession.maximumX, report.procession.minimumZ, report.procession.maximumZ = 0, 0, 0, 0
end
report.observedSeconds = os.clock() - start
report.phase = if #failures == 0 then "passed" else "failed"
print("EXPANSION_REPORT", HttpService:JSONEncode(report))
assert(#failures == 0, "EXPANSION_FAIL: " .. table.concat(failures, "; "))
print("EXPANSION_DONE", "Shared expanded route, natural emergence/coexistence/unsold exit, eight bases and controlled catalog rollout observed. Imports, visual quality, actual travel and responsive input remain separately documented.")
