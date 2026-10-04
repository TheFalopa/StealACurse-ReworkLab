-- Isolated Studio fixture, excluded from default.project.json. Use the generated
-- -AllBases place: this replaces production initialization rather than running
-- beside it. One actual client triggers real claim/purchase ProximityPrompts.
-- Setup teleports and Souls credit are deliberate test aids, not normal play.
-- Exactly eight fresh Map/BaseService/CurseService contexts are tested in turn.
-- One SoulsService owns income for the whole run. Completed contexts have their
-- Curse records cleared before destruction. Production services do not expose a
-- shutdown method, so at most seven empty updater/event contexts remain until
-- Play stops; no production source is changed to add fixture lifecycle hooks.
-- This is not an eight-client simultaneous ownership or contention test.
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Catalog = require(game.ReplicatedStorage.Shared.CurseCatalog)
local MapBuilder = require(script.Map.Build)
local SoulsService = require(script.Gameplay.SoulsService)
local BaseService = require(script.Gameplay.BaseService)
local CurseService = require(script.Gameplay.CurseService)

local control = Instance.new("RemoteEvent")
control.Name = "SliceTestControl"
control.Parent = game.ReplicatedStorage
local ready, responses = {}, {}
control.OnServerEvent:Connect(function(player, nonce, ok, result)
	if nonce == "ready" then ready[player] = true else responses[nonce] = { player, ok, result } end
end)
-- Build once before waiting for the client so its initial character has ground
-- and real SpawnLocations instead of falling through an empty fixture place.
local initialMap = MapBuilder.build()
local souls = SoulsService.start()
local serial = 0
local summary = {
	status = "waiting for client", bases = {}, contextsCreated = 0, interactiveClaims = 0,
	interactivePurchases = 0, verifiedPlacements = 0, definitionsCovered = {},
	method = "One real client, eight sequential freshly recreated map/base/curse contexts, one SoulsService. Real client prompts. Setup teleports and test credit. Empty old service callbacks/updaters remain bounded until Play stops. Not an eight-client simultaneous test.",
}
_G.AllBasesReport = summary

local function check(value, label)
	assert(value, label)
	print("ALL_BASES_PASS", label)
end
local function await(predicate, timeout)
	local deadline = os.clock() + (timeout or 8)
	repeat
		if predicate() then return true end
		task.wait(0.1)
	until os.clock() >= deadline
	return false
end
local function request(player: Player, target: ProximityPrompt)
	serial += 1
	local nonce = tostring(serial)
	control:FireClient(player, nonce, "prompt", target)
	assert(await(function() return responses[nonce] ~= nil end, 12), "Client prompt action timed out")
	local response = responses[nonce]
	responses[nonce] = nil
	assert(response[1] == player and response[2], response[3])
	-- A client acknowledgment only confirms input. Every caller separately waits
	-- for the authoritative production service transition and verifies its state.
	task.wait(0.4)
end
local function teleport(player: Player, position: Vector3)
	assert(player.Character and player.Character:FindFirstChild("HumanoidRootPart"), "Live character required for setup")
	player.Character:PivotTo(CFrame.new(position))
	player.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
	task.wait(0.6)
end
local function modelFor(map: Model, uid: string): Model?
	for _, child in ipairs(map.ActiveCurses:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("CurseUid") == uid then return child end
	end
	return nil
end

task.spawn(function()
	local ok, err = pcall(function()
		check(await(function() return #Players:GetPlayers() >= 1 end, 30), "real player joined")
		local player = Players:GetPlayers()[1]
		check(await(function()
			return ready[player] and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				and player.Character:FindFirstChildOfClass("Humanoid") and player.Character:FindFirstChildOfClass("Humanoid").Health > 0
		end, 45), "real client ready")
		local previous = nil
		for baseIndex = 1, 8 do
			local id = string.format("Base%02d", baseIndex)
			summary.status = "testing " .. id
			if previous then
				previous.curses:clearForUser(player, previous.base)
				for _, uid in ipairs(previous.uids) do assert(previous.curses:getState(uid) == nil, "Previous context retained a Curse record") end
				assert(player:GetAttribute("SoulsPerSecond") == 0, "Previous context retained production")
				previous.map:Destroy()
			end
			local map = if baseIndex == 1 then initialMap else MapBuilder.build()
			local bases = BaseService.start(map)
			local curses = CurseService.start(map, bases, souls)
			bases:onReleased(function(releasedPlayer, releasedBase) curses:clearForUser(releasedPlayer, releasedBase) end)
			summary.contextsCreated += 1
			local base = bases:getBaseById(id)
			assert(base and base.Parent, "Fresh context needs " .. id)
			local uids = {}
			previous = { map = map, base = base, curses = curses, uids = uids }
			-- Rebuilding intentionally resets BaseService logical state. Old owned
			-- models are destroyed; this is not relinquishing a base in normal play.
			teleport(player, base.ClaimMarker.Position)
			request(player, base.ClaimMarker.ClaimSanctuary)
			check(await(function() return bases:getBaseForPlayer(player) == base end), id .. " real prompt claimed sanctuary")
			check(base:GetAttribute("OwnerUserId") == player.UserId
				and player:GetAttribute("ClaimedBaseId") == id
				and player.RespawnLocation == base.PlayerSpawn
				and not base.ClaimMarker.ClaimSanctuary.Enabled, id .. " ownership and respawn authoritative")
			summary.interactiveClaims += 1
			souls:credit(player, 1000000)
			local baseResult = { id = id, claimed = true, slots = {}, soulsPerSecond = 0 }
			table.insert(summary.bases, baseResult)
			local expectedRate = 0
			local occupied = {}
			for slot = 1, 5 do
				local definitionId = Catalog.Order[(baseIndex + slot - 2) % #Catalog.Order + 1]
				local definition = Catalog.Definitions[definitionId]
				teleport(player, Vector3.new(0, 4, 36))
				local uid = curses:spawn(definitionId, CFrame.new(0, 5.3, 32))
				table.insert(uids, uid)
				local model = modelFor(map, uid)
				assert(model and model.PrimaryPart, "Actual Curse model must exist")
				local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
				assert(prompt, "Actual Curse model must have purchase prompt")
				task.wait(0.3)
				request(player, prompt)
				check(await(function() return curses:getState(uid) == "DELIVERING" end), id .. " slot " .. slot .. " real prompt purchased " .. definitionId)
				assert(player:GetAttribute("SoulsPerSecond") == expectedRate, "Carried Curse produced income before placement")
				summary.interactivePurchases += 1
				teleport(player, base.FutureCurseDisplayArea.Position + Vector3.new(0, 3, 0))
				check(await(function() return curses:getState(uid) == "PLACED" end), id .. " slot " .. slot .. " production delivery placed")
				model = modelFor(map, uid)
				assert(model and model.PrimaryPart and model:GetAttribute("CurseState") == "PLACED", "Placed runtime model must match state")
				local plinth = base:FindFirstChild("DisplayPlinth_" .. slot)
				assert(plinth and plinth:IsA("BasePart"), "Direct display slot missing")
				local rise = plinth.Size.Y * 0.5 + model.PrimaryPart.Size.Y * 0.5 + 0.18
				local expectedFrame = plinth.CFrame * CFrame.new(0, rise, 0) * CFrame.Angles(0, math.rad((slot - 1) * 15), 0)
				assert((model.PrimaryPart.Position - expectedFrame.Position).Magnitude < 0.15, "Curse is not above the expected physical pedestal")
				local nearest, minimum = nil, math.huge
				for candidate, candidatePlinth in ipairs(bases:getSlots(base)) do
					local distance = (model.PrimaryPart.Position - candidatePlinth.Position).Magnitude
					if distance < minimum then nearest, minimum = candidate, distance end
				end
				assert(nearest == slot and not occupied[nearest], "Physical slot duplicated or misassigned")
				occupied[nearest] = true
				expectedRate += definition.baseSoulsPerSecond
				check(player:GetAttribute("SoulsPerSecond") == expectedRate, id .. " slot " .. slot .. " verified distinct pedestal and summed income")
				assert(not model.PrimaryPart.BuyCurse.Enabled, "Placed Curse purchase prompt must be disabled")
				summary.definitionsCovered[definitionId] = true
				summary.verifiedPlacements += 1
				baseResult.soulsPerSecond = expectedRate
				table.insert(baseResult.slots, { slot = slot, definitionId = definitionId, uid = uid, physicalPedestal = nearest, position = { model.PrimaryPart.Position.X, model.PrimaryPart.Position.Y, model.PrimaryPart.Position.Z } })
			end
			check(#baseResult.slots == 5 and #map.ActiveCurses:GetChildren() >= 5, id .. " all five placements verified")
			print("ALL_BASES_CONTEXT_DONE", id, expectedRate)
		end
		for _, definitionId in ipairs(Catalog.Order) do check(summary.definitionsCovered[definitionId], "six-Curse compatibility " .. definitionId) end
		check(summary.contextsCreated == 8 and summary.interactiveClaims == 8 and summary.interactivePurchases == 40 and summary.verifiedPlacements == 40,
			"eight sequential real claims and forty real purchases/deliveries verified")
		summary.status = "passed"
		print("ALL_BASES_REPORT", HttpService:JSONEncode(summary))
		print("ALL_BASES_DONE", "Eight recreated service contexts; eight real claims; forty placements; all six definitions. Last Base08 context retained for inspection. Setup teleports/credit used; not a simultaneous eight-client test.")
	end)
	if not ok then
		summary.status = "failed"
		summary.failure = tostring(err)
		print("ALL_BASES_REPORT", HttpService:JSONEncode(summary))
		warn("ALL_BASES_FAIL", err)
	end
end)
