-- Isolated Studio fixture. Production service source, route, movement, purchase,
-- delivery, income, speed and cadence remain unchanged. Offer selection differs.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Catalog = require(ReplicatedStorage.Shared.CurseCatalog)
local Profiles = require(ReplicatedStorage.Shared.CurseVFXProfiles)
local Layout = require(script.Map.Layout)
local Config = require(script.Gameplay.Config)
local fixture = HttpService:JSONDecode(ReplicatedStorage.CurseReworkFixtureConfig.Value)
local control = Instance.new("RemoteEvent")
control.Name = "CurseReworkTestControl"
control.Parent = ReplicatedStorage
local ready, responses, serial = {}, {}, 0
control.OnServerEvent:Connect(function(player, nonce, ok, result)
	if nonce == "ready" then ready[player] = true else responses[nonce] = { player, ok, result } end
end)
local map = require(script.Map.Build).build()
local souls = require(script.Gameplay.SoulsService).start()
local bases = require(script.Gameplay.BaseService).start(map)
local curses = require(script.Gameplay.CurseService).start(map, bases, souls)
bases:onReleased(function(player, base) curses:clearForUser(player, base) end)
local report = { phase = "starting", requestedPhase = fixture.phase, builtAtUtc = fixture.builtAtUtc,
	assets = {}, failures = {}, route = {}, purchase = {}, productionServicesUnchanged = true,
	sourceFingerprints = fixture.sourceFingerprints,
	proofScope = "Immutable built-source fingerprints; recheck changed presentation sources before reusing VFX/gameplay evidence" }
_G.CurseReworkReport = report
local observedReport = Instance.new("StringValue")
observedReport.Name = "CurseReworkObservedReport"
observedReport.Parent = ReplicatedStorage
local reportGeneration = 0
local function publish()
	local payload = HttpService:JSONEncode(report)
	reportGeneration += 1
	observedReport:SetAttribute("Publishing", true)
	local parts = {}
	if #payload > 90000 then
		local first = 1
		while first <= #payload do
			local last = math.min(first + 89999, #payload)
			-- Keep every replicated StringValue valid UTF-8, even when a
			-- translated display label falls across a chunk boundary.
			while last < #payload do
				local nextByte = string.byte(payload, last+1)
				if nextByte < 128 or nextByte > 191 then break end
				last -= 1
			end
			table.insert(parts, string.sub(payload, first, last)); first = last + 1
		end
	end
	local partCount = #parts
	for index = 1, partCount do
		local name = string.format("Chunk%03d", index)
		local chunk = observedReport:FindFirstChild(name)
		if not chunk then chunk = Instance.new("StringValue"); chunk.Name = name; chunk.Parent = observedReport end
		chunk.Value = parts[index]
		chunk:SetAttribute("Generation", reportGeneration)
	end
	for _, chunk in observedReport:GetChildren() do
		local index = tonumber(string.match(chunk.Name, "^Chunk(%d+)$"))
		if index and index > partCount then chunk:Destroy() end
	end
	observedReport.Value = if partCount == 0 then payload else HttpService:JSONEncode({
		transport = "StringValueChunksV1", generation = reportGeneration, partCount = partCount,
		totalByteCount = #payload, phase = report.phase, requestedPhase = fixture.phase })
	observedReport:SetAttribute("Phase", report.phase)
	observedReport:SetAttribute("RequestedPhase", fixture.phase)
	observedReport:SetAttribute("CurrentReviewId", report.currentReviewId or "")
	observedReport:SetAttribute("CurrentReviewState", report.currentReviewState or "")
	observedReport:SetAttribute("RouteCompleted", report.route.completed or 0)
	observedReport:SetAttribute("PurchaseCompleted", report.purchase.completed or 0)
	observedReport:SetAttribute("ImportedCount", report.currentImportedCount or 0)
	observedReport:SetAttribute("PartCount", partCount)
	observedReport:SetAttribute("TotalByteCount", #payload)
	observedReport:SetAttribute("Generation", reportGeneration)
	observedReport:SetAttribute("Publishing", false)
end
publish()
local byId, ids, buildEvidence = {}, {}, {}
for _, proof in fixture.imports do buildEvidence[proof.id] = proof end
local function vector(value: Vector3)
	return { value.X, value.Y, value.Z }
end
local function check(value, label)
	if not value then table.insert(report.failures, label); error(label, 2) end
end
local function await(predicate, timeout)
	local deadline = os.clock() + (timeout or 8)
	repeat if predicate() then return true end; task.wait(0.08) until os.clock() >= deadline
	return false
end
local function request(player, action, target, timeout)
	serial += 1
	local nonce = tostring(serial)
	control:FireClient(player, nonce, action, target)
	check(await(function() return responses[nonce] ~= nil end, timeout or 12), "Client action timeout: " .. action)
	local response = responses[nonce]; responses[nonce] = nil
	check(response[1] == player and response[2], "Client " .. action .. ": " .. tostring(response[3]))
	return response[3]
end
local function modelFor(uid)
	for _, model in map.ActiveCurses:GetChildren() do
		if model:IsA("Model") and model:GetAttribute("CurseUid") == uid then return model end
	end
end
local function teleport(player, position)
	player.Character:PivotTo(CFrame.new(position))
	player.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
	task.wait(0.35)
end
local function validateModel(model, definition)
	check(model ~= nil and model.PrimaryPart ~= nil, "Runtime root missing: " .. definition.id)
	local root = model.PrimaryPart
	check(root:IsA("MeshPart") and root.Name == "CurseMesh", "Runtime must retain one semantic MeshPart root: " .. definition.id)
	check(root.MeshId == definition.meshId, "Runtime mesh differs from current import: " .. definition.id)
	check(root.Size.Magnitude < 7 and math.min(root.Size.X, root.Size.Y, root.Size.Z) > 0, "Authored clearance bounds: " .. definition.id)
	check((root.Size - root.MeshSize).Magnitude < 0.02, "Runtime preserves actual imported MeshSize: " .. definition.id)
	check(root.Color == Color3.new(1, 1, 1) and root.Material == Enum.Material.SmoothPlastic, "Painted material must retain white multiplier: " .. definition.id)
	check(root.Anchored and not root.CanCollide and not root.CanTouch, "Runtime root collision contract: " .. definition.id)
	check(model:GetAttribute("FbxSha256") == definition.fbxSha256, "Runtime FBX provenance: " .. definition.id)
	local label = model:FindFirstChild("CurseInfo")
	check(label and label:IsA("BillboardGui") and label.Adornee == root, "Root label attachment: " .. definition.id)
	check(label.StudsOffsetWorldSpace.Y > root.Size.Y * 0.5, "Label clears the imported upper bounds: " .. definition.id)
	for _, field in { "InfoName", "InfoRarity", "InfoPrice", "InfoIncome" } do
		check(label.Panel:FindFirstChild(field) ~= nil, "Label field missing: " .. definition.id .. "/" .. field)
	end
	check(root:FindFirstChild("BuyCurse") ~= nil and root:FindFirstChild("CurseVFXHook") ~= nil, "Native prompt/VFX hooks: " .. definition.id)
	return { size = vector(root.Size), meshSize = vector(root.MeshSize), meshId = root.MeshId,
		material = root.Material.Name, color = { root.Color.R, root.Color.G, root.Color.B },
		labelOffset = vector(label.StudsOffsetWorldSpace), fbxSha256 = model:GetAttribute("FbxSha256") }
end

local function observeWorldPolish()
	local art = map:FindFirstChild("HauntedWorldPolish")
	check(art and art:IsA("Model"), "Production HauntedWorldPolish model is missing")
	local observed = { attributes = art:GetAttributes(), parts = 0, meshParts = 0, lights = 0,
		collidingParts = 0, collisionHulls = 0, groundedMeshes = 0, groundingAttributesMissing = 0,
		maximumGroundingBoundError = 0, sourceTemplates = {}, grounding = {},
		method = "Actual scoped Instances and production AssetKit GroundedPlacement/SupportY/GroundInset attributes; no replacement floor sampler" }
	local elevation = require(script.Map.Config).MapElevation
	for _, item in art:GetDescendants() do
		if item:IsA("BasePart") then
			observed.parts += 1
			if item.CanCollide then observed.collidingParts += 1 end
			if string.find(item.Name, "CollisionHull", 1, true) then observed.collisionHulls += 1 end
			if item:IsA("MeshPart") then
				observed.meshParts += 1
				local template = item:GetAttribute("SourceTemplate") or "unattributed"
				observed.sourceTemplates[template] = (observed.sourceTemplates[template] or 0) + 1
				if item:GetAttribute("GroundedPlacement") then
					observed.groundedMeshes += 1
					local support, inset = item:GetAttribute("SupportY"), item:GetAttribute("GroundInset")
					if typeof(support) ~= "number" or typeof(inset) ~= "number" then
						observed.groundingAttributesMissing += 1
					else
						local bottom = math.huge
						for _, x in { -1, 1 } do for _, y in { -1, 1 } do for _, z in { -1, 1 } do
							local point = item.CFrame:PointToWorldSpace(Vector3.new(item.Size.X*x, item.Size.Y*y, item.Size.Z*z) * .5)
							bottom = math.min(bottom, point.Y)
						end end end
						local error = math.abs(bottom - (support + elevation - inset))
						observed.maximumGroundingBoundError = math.max(observed.maximumGroundingBoundError, error)
						table.insert(observed.grounding, { path = item:GetFullName(), sourceTemplate = template,
							supportYBeforeMapElevation = support, groundInset = inset, actualBottomY = bottom, boundError = error })
					end
				end
			end
		elseif item:IsA("Light") then observed.lights += 1 end
	end
	observed.missingTemplates = art:GetAttribute("MissingVerifiedTemplateCount")
	check(observed.parts <= 214 and observed.parts == art:GetAttribute("BasePartCount"), "Production world polish exceeds or misreports its 214-part scope")
	check(observed.meshParts == art:GetAttribute("MeshPartCount"), "Production world polish mesh count differs from actual Instances")
	check(observed.lights <= 2 and observed.lights == art:GetAttribute("AddedLightCount"), "Production world polish exceeds or misreports two added lights")
	check(observed.missingTemplates == 0, "Production world polish has missing verified templates")
	check(observed.collidingParts == 0 and observed.collisionHulls == 0, "Production world polish introduces a collider")
	check(observed.groundedMeshes > 0 and observed.groundingAttributesMissing == 0 and observed.maximumGroundingBoundError < .003,
		"Production grounded world polish differs from its authored support attributes")
	observed.status = "PASS"; report.worldPolish = observed
	publish()
	print("CURSE_REWORK_WORLD", HttpService:JSONEncode(observed))
end

local function validateCatalogMetadata()
	local metadata, metadataIds = {}, {}
	local kit = game:GetService("ServerStorage").CurseMeshKit
	for _, id in Catalog.AllOrder do
		local definition = Catalog.Definitions[id]
		check(not metadataIds[id] and definition.id == id and #definition.displayName > 0, "56-roster runtime identity: " .. id)
		check(Catalog.Rarities[definition.rarity] ~= nil and definition.price > 0 and definition.baseSoulsPerSecond > 0
			and typeof(definition.futureEffectId) == "string" and #definition.futureEffectId > 0,
			"56-roster runtime rarity/economy/effect metadata: " .. id)
		local template = kit:FindFirstChild(definition.visualKey)
		check(template and template:IsA("MeshPart") and template.MeshId ~= "" and template.Size.Magnitude < 7,
			"56-roster real runtime mesh template: " .. id)
		metadataIds[id] = true
		table.insert(metadata, { id = id, displayName = definition.displayName, rarity = definition.rarity,
			price = definition.price, income = definition.baseSoulsPerSecond, visualKey = definition.visualKey,
			meshId = template.MeshId, futureEffectId = definition.futureEffectId,
			fbxSha256 = definition.fbxSha256, isExpansion = definition.isExpansion == true })
	end
	local actualDefinitions = 0; for _ in Catalog.Definitions do actualDefinitions += 1 end
	check(#metadata == 56 and actualDefinitions == 56 and #Catalog.Order == 6 and #Catalog.ExpansionOrder == 50,
		"Fixture must retain all 56 exact metadata identities")
	report.catalogMetadata = { total = #metadata, original = #Catalog.Order, expansion = #Catalog.ExpansionOrder, entries = metadata }
	publish()
	return metadata
end

local function routePhase(player)
	report.phase = "route"
	local spawnPoint = map.CentralMausoleum.CurseSpawnPoint.Position
	local points, lengths, total = {}, {}, 0
	for _, point in Layout.ProcessionPoints do table.insert(points, Vector3.new(point.X, spawnPoint.Y + 2.25, point.Z)) end
	for index = 1, #points - 1 do
		lengths[index] = (points[index + 1] - points[index]).Magnitude
		total += lengths[index]
	end
	check(Config.ProcessionSpeedStudsPerSecond == 6.5 and Config.MaxProcessionCurses == 6, "Production route speed and concurrency must remain unchanged")
	report.route = { lengthStuds = total, speedStudsPerSecond = Config.ProcessionSpeedStudsPerSecond,
		maxConcurrency = Config.MaxProcessionCurses, completed = 0, maximumActive = 0, segments = #lengths,
		cadenceSeconds = Config.ProcessionCadenceSeconds, firstDelaySeconds = Config.FirstProcessionDelaySeconds,
		selection = "Deterministic current imported definitions; production service chooses cadence/movement/exit" }
	report.route.points = {}
	for _, point in points do table.insert(report.route.points, vector(point)) end
	report.route.authoredMapWaypoints = map:GetAttribute("AuthoredProcessionWaypoints")
	report.route.authoredMapLengthStuds = map:GetAttribute("AuthoredProcessionLength")
	publish()
	-- Project observed production frames onto the authored polyline. This records
	-- distance/coverage and never computes or applies a replacement route frame.
	local function observe(position)
		local traveled, best, along, section = 0, math.huge, 0, 1
		for index, length in lengths do
			local a, b = points[index], points[index + 1]
			local flat = Vector3.new(position.X, a.Y, position.Z)
			local delta = b - a; local alpha = math.clamp((flat - a):Dot(delta) / (length * length), 0, 1)
			local gap = (flat - a:Lerp(b, alpha)).Magnitude
			if gap < best then best, along, section = gap, traveled + alpha * length, index end
			traveled += length
		end
		return along, section, best
	end
	local queueIndex, records, extras = 1, {}, {}
	local proxy = {}
	function proxy:spawn(_chosen, frame)
		local id = ids[queueIndex] or ids[1]
		local uid = curses:spawn(id, frame)
		if queueIndex <= #ids then
			local row = byId[id]
			row.runtime = validateModel(modelFor(uid), Catalog.Definitions[id])
			row.route = { uid = uid, startedAt = os.clock(), samples = 0, distanceStuds = 0,
				maximumLateralError = 0, coveredSegments = {}, spawn = vector(frame.Position) }
			records[uid] = row
			queueIndex += 1
			publish()
		else
			-- Extra offers are genuine production records, excluded from target
			-- evidence and cleaned up when the final target has naturally exited.
			extras[uid] = true
		end
		return uid
	end
	function proxy:getState(uid) return curses:getState(uid) end
	function proxy:moveProcession(uid, frame)
		local moved = curses:moveProcession(uid, frame)
		local row = records[uid]
		if row and moved then
			local progress, section, lateral = observe(frame.Position)
			row.route.samples += 1
			row.route.distanceStuds = progress
			row.route.lastPosition = vector(frame.Position)
			row.route.coveredSegments[tostring(section)] = true
			row.route.maximumLateralError = math.max(row.route.maximumLateralError, lateral)
		end
		return moved
	end
	function proxy:despawnUnsold(uid)
		local row = records[uid]
		if row then
			local trace = row.route
			trace.elapsedSeconds = os.clock() - trace.startedAt
			trace.expectedSeconds = total / Config.ProcessionSpeedStudsPerSecond
			local model = modelFor(uid)
			local at = model and model.PrimaryPart.Position or Vector3.zero
			trace.endDistance = (Vector3.new(at.X, points[#points].Y, at.Z) - points[#points]).Magnitude
			trace.preExitState = curses:getState(uid)
			local coverage = 0; for _ in trace.coveredSegments do coverage += 1 end
			trace.coveredSegmentCount = coverage
			curses:despawnUnsold(uid)
			trace.postExitStateAbsent = curses:getState(uid) == nil and modelFor(uid) == nil
			trace.status = if trace.preExitState == "PROCESSION" and trace.postExitStateAbsent
				and trace.samples > 50 and coverage == #lengths and trace.maximumLateralError < 0.03
				and trace.endDistance < 3 and trace.distanceStuds >= total - 3
				and math.abs(trace.elapsedSeconds - trace.expectedSeconds) < 6 then "PASS" else "FAIL"
			report.route.completed += 1
			if trace.status ~= "PASS" then table.insert(report.failures, "Production route failed: " .. row.id) end
			publish()
			print("CURSE_REWORK_ROUTE", HttpService:JSONEncode({ id = row.id, fbxSha256 = row.fbxSha256, meshId = row.meshId, route = trace }))
		else curses:despawnUnsold(uid) end
	end
	-- Selection is deterministic, while all production timing/spacing remains
	-- unchanged. Prior cadence-accelerated snapshots remain separately recorded.
	local started = require(script.Gameplay.CurseProcessionService).start(map, proxy)
	check(math.abs(started.routeLength - total) < 0.001, "Production route agrees with observed authored lengths")
	local deadline = os.clock() + math.ceil(#ids / Config.MaxProcessionCurses) * (total / Config.ProcessionSpeedStudsPerSecond + 8) + 30
	local nextLog = os.clock() + 20
	while report.route.completed < #ids and os.clock() < deadline do
		task.wait(0.2)
		local active = 0
		for _, model in map.ActiveCurses:GetChildren() do if model:IsA("Model") and model:GetAttribute("CurseState") == "PROCESSION" then active += 1 end end
		report.route.maximumActive = math.max(report.route.maximumActive, active)
		check(active <= 6, "Production route exceeds six simultaneous offers")
		if os.clock() >= nextLog then
			print("CURSE_REWORK_ROUTING", report.route.completed, "of", #ids, "finished; active", active)
			nextLog = os.clock() + 20
		end
	end
	-- Both production route loops stop on map.Parent != workspace. Restore the
	-- same map after they have stopped so purchase tests reuse the same services.
	-- The spawn loop sleeps for the real ten-second cadence, so the map must
	-- remain detached for an entire cadence. Hold only the fixture player's root
	-- during this map pause to avoid a fall through temporarily detached floors.
	local characterRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local wasAnchored = characterRoot and characterRoot.Anchored
	if characterRoot then characterRoot.Anchored = true end
	report.route.cleanupMapPauseSeconds = Config.ProcessionCadenceSeconds + Config.ProcessionStepSeconds + .25
	map.Parent = nil; task.wait(report.route.cleanupMapPauseSeconds); map.Parent = workspace
	if characterRoot and characterRoot.Parent then characterRoot.Anchored = wasAnchored end
	for uid in extras do curses:despawnUnsold(uid) end
	check(report.route.completed == #ids, "Not every current imported Curse naturally finished the route")
	check(#report.failures == 0, "At least one recorded production route failed")
end

local function purchasePhase(player)
	local purchaseIds, selected = {}, {}
	if fixture.purchaseIds and #fixture.purchaseIds > 0 then
		for _, id in fixture.purchaseIds do
			check(byId[id] ~= nil and not selected[id], "Purchase subset must contain unique current imported IDs: " .. tostring(id))
			selected[id] = true; table.insert(purchaseIds, id)
		end
	else purchaseIds = table.clone(ids) end
	report.phase = "purchase"
	report.purchase.requestedIds = purchaseIds
	report.purchase.requestedCount = #purchaseIds
	publish()
	local base = bases:getBaseById("Base07")
	teleport(player, base.ClaimMarker.Position + Vector3.new(0, 2, 0))
	local claimInput = request(player, "prompt", base.ClaimMarker.ClaimSanctuary)
	check(await(function() return bases:getBaseForPlayer(player) == base end), "Real client sanctuary claim did not complete")
	report.purchase.claimedBase = base.Name; report.purchase.claimInput = claimInput; report.purchase.completed = 0
	local credit = 1000; for _, id in purchaseIds do credit += Catalog.Definitions[id].price end
	souls:credit(player, credit)
	local spawnY = map.CentralMausoleum.CurseSpawnPoint.Position.Y
	local offerPosition = Vector3.new(0, spawnY + 2.25, 32)
	local production, group = 0, 0
	for index, id in purchaseIds do
		if (index - 1) % 5 == 0 then
			curses:clearForUser(player, base); production = 0; group += 1
			check(player:GetAttribute("SoulsPerSecond") == 0, "Five-slot cleanup did not reset income")
		end
		local definition = Catalog.Definitions[id]; local row = byId[id]
		teleport(player, Vector3.new(0, spawnY + 0.5, 36))
		local uid = curses:spawn(id, CFrame.new(offerPosition)); task.wait(0.35)
		local model = modelFor(uid); row.runtime = validateModel(model, definition)
		local balance, previousRate, purchaseAt = souls:getBalance(player), production, os.clock()
		local purchaseInput = request(player, "prompt", model.PrimaryPart.BuyCurse)
		check(await(function() return curses:getState(uid) == "DELIVERING" end), "Real prompt purchase did not transition: " .. id)
		local purchaseElapsed = os.clock() - purchaseAt
		local spendError = souls:getBalance(player) - balance + definition.price - previousRate * purchaseElapsed
		check(math.abs(spendError) < previousRate * (Config.SoulsTickSeconds + 0.15) + 0.05,
			"Purchase did not deduct its authoritative price after elapsed income: " .. id)
		check(player:GetAttribute("SoulsPerSecond") == previousRate, "Delivery earns income before placement: " .. id)
		local firstPosition = model.PrimaryPart.Position
		teleport(player, Vector3.new(0, spawnY + 0.5, 50)); task.wait(0.8)
		local secondPosition = model.PrimaryPart.Position
		check(curses:getState(uid) == "DELIVERING" and (secondPosition - firstPosition).Magnitude > 5, "Outside-base follow movement missing: " .. id)
		check((secondPosition - player.Character.HumanoidRootPart.Position).Magnitude < 9, "Curse failed to follow its carrier: " .. id)
		local deliveryVfx = request(player, "inspect", { model = model, state = "DELIVERING" })
		teleport(player, base.FutureCurseDisplayArea.Position + Vector3.new(0, 3, 0))
		check(await(function() return curses:getState(uid) == "PLACED" end), "Return did not naturally deliver: " .. id)
		production += definition.baseSoulsPerSecond
		check(player:GetAttribute("SoulsPerSecond") == production, "Summed production differs after placement: " .. id)
		local slot = (index - 1) % 5 + 1; local plinth = bases:getSlots(base)[slot]
		local root = model.PrimaryPart
		local expected = plinth.CFrame * CFrame.new(0, plinth.Size.Y * 0.5 + root.Size.Y * 0.5 + 0.18, 0)
		check((root.Position - expected.Position).Magnitude < 0.05, "Curse differs from its physical pedestal placement: " .. id)
		teleport(player, plinth.Position + plinth.CFrame.LookVector * 3 + Vector3.new(0, 3, 0))
		local holdSeconds = 0
		if table.find(fixture.reviewIds or {}, id) then holdSeconds = fixture.reviewHoldSeconds or 0 end
		if holdSeconds > 0 then
			report.currentReviewId = id; report.currentReviewState = "PLACED"
			publish()
			print("CURSE_REWORK_REVIEW_BEGIN", id, holdSeconds, "seconds; actual front camera and production VFX")
		end
		local placedVfx = request(player, "inspect", { model = model, state = "PLACED", holdSeconds = holdSeconds }, math.max(12, holdSeconds + 15))
		if holdSeconds > 0 then
			print("CURSE_REWORK_REVIEW_END", id)
			report.currentReviewId = nil; report.currentReviewState = nil
			publish()
		end
		local incomeBefore, incomeAt = souls:getBalance(player), os.clock()
		task.wait(1.15)
		local earned, elapsed = souls:getBalance(player) - incomeBefore, os.clock() - incomeAt
		check(earned >= production * (elapsed - Config.SoulsTickSeconds - 0.12), "Elapsed-time income did not accumulate: " .. id)
		row.purchase = { status = "PASS", uid = uid, group = group, slot = slot, state = curses:getState(uid),
			price = definition.price, purchaseSpendError = spendError, production = production, incomeEarned = earned, incomeObservedSeconds = elapsed,
			followDistance = (secondPosition - firstPosition).Magnitude, pedestalError = (root.Position - expected.Position).Magnitude,
			deliveryClient = deliveryVfx, placedClient = placedVfx, promptInput = purchaseInput, usedActualClientPrompt = true }
		row.vfxChecked = true; row.gameplayChecked = true
		report.purchase.completed += 1
		publish()
		print("CURSE_REWORK_PURCHASE", HttpService:JSONEncode({ id = id, fbxSha256 = row.fbxSha256, meshId = row.meshId, purchase = row.purchase }))
	end
	check(report.purchase.completed == report.purchase.requestedCount, "Requested purchase subset did not complete")
end

local function stressPhase(player)
	report.phase = "stress"
	publish()
	check(#ids >= 40, "46-active stress requires at least 40 distinct current imported Curse models")
	local base = bases:getBaseForPlayer(player)
	if base then curses:clearForUser(player, base) end
	check(player:GetAttribute("SoulsPerSecond") == 0, "Stress must start with zero owned income")
	local balance = souls:getBalance(player)
	local metadata = report.catalogMetadata.entries
	local folder = Instance.new("Folder")
	folder.Name = "CurseReworkStressPresentationOnly"; folder.Parent = map
	local center = Vector3.new(0, map.CentralMausoleum.CurseSpawnPoint.Position.Y + 1, 62)
	local models, presentationModels, offerUids = {}, {}, {}
	local Visual = require(script.Gameplay.CurseVisualService)
	local function cleanup()
		folder:Destroy()
		for _, model in presentationModels do model:Destroy() end
		for _, uid in offerUids do curses:despawnUnsold(uid) end
	end
	local ok, result = pcall(function()
		for index = 1, 40 do
			local id = ids[index]; local definition = Catalog.Definitions[id]
			local pedestal = Instance.new("Part")
			pedestal.Name = string.format("StressPedestal_%02d", index)
			pedestal.Size = Vector3.new(5, 0.65, 5)
			pedestal.CFrame = CFrame.new(center + Vector3.new(((index-1)%8-3.5)*8, 0, (math.floor((index-1)/8)-2)*8))
			pedestal.Color = Color3.fromRGB(54, 47, 64); pedestal.Material = Enum.Material.Slate
			pedestal.Anchored = true; pedestal.CanCollide = false; pedestal.CanTouch = false; pedestal.CanQuery = false
			pedestal.Parent = folder
			-- Keep the real client nearest-pedestal label policy active. These
			-- visual models have no logical record in CurseService's private store.
			local model = Visual.create(definition, map.ActiveCurses)
			table.insert(presentationModels, model)
			model:SetAttribute("DefinitionId", id); model:SetAttribute("StressPresentationOnly", true)
			-- This state controls the visual label/prompt. No CurseService record,
			-- owner, occupied slot, delivery or earnings is created for these forty.
			Visual.setState(model, definition, "PLACED")
			model:PivotTo(pedestal.CFrame * CFrame.new(0, pedestal.Size.Y*.5 + model.PrimaryPart.Size.Y*.5 + .18, 0))
			validateModel(model, definition)
			table.insert(models, model)
		end
		for index = 1, 6 do
			local id = ids[40 + index] or ids[index]
			local uid = curses:spawn(id, CFrame.new(center + Vector3.new((index-3.5)*7, 3, 24)))
			table.insert(offerUids, uid); table.insert(models, modelFor(uid))
		end
		check(#models == 46 and #offerUids == 6, "Stress needs forty visual displays and six actual production offers")
		report.stress = { presentationOnlyDisplays = 40, actualProductionOffers = 6, totalNativeVfxModels = 46,
			ownedDisplaysAdded = 0, earnedIncomeFromPresentation = 0, metadata = metadata, metadataCount = #metadata,
			labelPolicy = "Unchanged production nearest placed label; visual display models have no logical Curse record" }
		publish()
		print("CURSE_REWORK_STRESS_READY", HttpService:JSONEncode({ models = 46, presentationOnly = 40, actualOffers = 6, expectMobile = fixture.expectMobile }))
		return request(player, "stress", { models = models, center = center, expectMobile = fixture.expectMobile }, 55)
	end)
	cleanup(); task.wait(0.8)
	local cleanupOk, cleanupResult = pcall(function() return request(player, "stressCleanup", nil) end)
	if report.stress then
		report.stress.client = if ok then result else { error = tostring(result) }
		report.stress.cleanup = if cleanupOk then cleanupResult else { error = tostring(cleanupResult) }
	end
	check(ok, "Native VFX stress failed: " .. tostring(result))
	check(cleanupOk, "Native VFX stress cleanup failed: " .. tostring(cleanupResult))
	check(player:GetAttribute("SoulsPerSecond") == 0 and souls:getBalance(player) == balance,
		"Visual-only stress displays must never create ownership or earned income")
	report.stress.status = "PASS"
	publish()
	print("CURSE_REWORK_STRESS", HttpService:JSONEncode(report.stress))
end

task.spawn(function()
	local ok, err = pcall(function()
		for _, id in Catalog.ExpansionOrder do
			local definition = Catalog.Definitions[id]
			if definition.implementationStatus == "IMPORTED" or definition.implementationStatus == "VALIDATED" then
				local proof = buildEvidence[id]
				check(proof ~= nil and proof.fbxSha256 == definition.fbxSha256 and proof.meshId == definition.meshId,
					"Runtime catalog does not match actual build-time FBX/import proof: " .. id)
				check(definition.originalVertexColors and Profiles.Definitions[id] ~= nil, "Verified surface/VFX profile absent: " .. id)
				local row = { id = id, fbxSha256 = proof.fbxSha256, meshId = proof.meshId, export = proof.export,
					sourceReference = proof.sourceReference, triangles = proof.triangles,
					implementationStatus = definition.implementationStatus, rarity = definition.rarity }
				table.insert(ids, id); table.insert(report.assets, row); byId[id] = row
			end
		end
		check(#ids == fixture.expectedImportedCount and #ids > 0, "Current imported runtime roster differs from fixture build snapshot")
		report.currentImportedCount = #ids; report.testedIds = ids
		publish()
		observeWorldPolish()
		validateCatalogMetadata()
		check(await(function() return #Players:GetPlayers() > 0 end, 60), "Real player did not join")
		local player = Players:GetPlayers()[1]
		check(await(function() return ready[player] and player.Character and player.Character:FindFirstChild("HumanoidRootPart") end, 60), "Real fixture client not ready")
		print("CURSE_REWORK_READY", HttpService:JSONEncode({ phase = fixture.phase, importedCount = #ids, testedIds = ids }))
		if fixture.phase == "All" or fixture.phase == "Route" then routePhase(player) end
		if fixture.phase == "All" or fixture.phase == "Purchase" or fixture.phase == "PurchaseAndStress" then purchasePhase(player) end
		if fixture.phase == "All" or fixture.phase == "Stress" or fixture.phase == "PurchaseAndStress" then stressPhase(player) end
		report.phase = "passed"
		for _, row in report.assets do row.status = "PASS" end
		publish()
		print("CURSE_REWORK_REPORT", HttpService:JSONEncode(report))
		print("CURSE_REWORK_DONE", fixture.phase, #ids, "current-source imported Curses passed their requested production tests")
	end)
	if not ok then
		report.phase = "failed"; report.error = tostring(err)
		publish()
		print("CURSE_REWORK_REPORT", HttpService:JSONEncode(report))
		warn("CURSE_REWORK_FAIL", err)
	end
end)
