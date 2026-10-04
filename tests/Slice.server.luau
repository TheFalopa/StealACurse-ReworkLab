-- Studio-only fixture. Uses production services unchanged; never included in game.
local Players = game:GetService("Players")
local Catalog = require(game.ReplicatedStorage.Shared.CurseCatalog)
local control = Instance.new("RemoteEvent")
control.Name = "SliceTestControl"
control.Parent = game.ReplicatedStorage
local ready, responses = {}, {}
control.OnServerEvent:Connect(function(player, nonce, ok, result)
	if nonce == "ready" then ready[player] = true else responses[nonce] = { player, ok, result } end
end)
local map = require(script.Map.Build).build()
local souls = require(script.Gameplay.SoulsService).start()
local bases = require(script.Gameplay.BaseService).start(map)
local curses = require(script.Gameplay.CurseService).start(map, bases, souls)
bases:onReleased(function(player, base) curses:clearForUser(player, base) end)
local serial = 0
local function check(value, label)
	assert(value, label)
	print("SLICE_PASS", label)
end
local function await(predicate, timeout)
	local deadline = os.clock() + (timeout or 6)
	repeat if predicate() then return true end; task.wait(0.1) until os.clock() >= deadline
	return false
end
local function request(player, action, target, timeout)
	serial += 1
	local nonce = tostring(serial)
	control:FireClient(player, nonce, action, target)
	assert(await(function() return responses[nonce] ~= nil end, timeout or 10), "Client action timed out: " .. action)
	local response = responses[nonce]
	responses[nonce] = nil
	assert(response[1] == player and response[2], response[3])
	task.wait(0.4)
end
local function teleport(player, position)
	player.Character:PivotTo(CFrame.new(position))
	player.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
	task.wait(0.6)
end
local function modelFor(uid)
	for _, child in ipairs(map.ActiveCurses:GetChildren()) do
		if child:GetAttribute("CurseUid") == uid then return child end
	end
end
local function offer(id)
	local uid = curses:spawn(id, CFrame.new(0, 5.3, 32))
	task.wait(0.3)
	return uid, modelFor(uid):FindFirstChildWhichIsA("ProximityPrompt", true)
end
local function buy(player, id)
	teleport(player, Vector3.new(0, 4, 36))
	local uid, prompt = offer(id)
	request(player, "prompt", prompt)
	return uid
end
local function place(player, uid, base)
	teleport(player, base.FutureCurseDisplayArea.Position + Vector3.new(0, 3, 0))
	check(await(function() return curses:getState(uid) == "PLACED" end), "placed " .. uid)
end
task.spawn(function()
	local ok, err = pcall(function()
		check(await(function() return #Players:GetPlayers() >= 1 end, 30), "player joined")
		local p = Players:GetPlayers()[1]
		check(await(function() return ready[p] and p.Character and p.Character:FindFirstChild("HumanoidRootPart") end, 30), "client ready")
		local uid = buy(p, "cursed_doll")
		check(curses:getState(uid) == "PROCESSION" and souls:getBalance(p) == 500, "no-base purchase rejected")
		curses:despawnUnsold(uid)
		local base = bases:getBaseById("Base07")
		teleport(p, base.ClaimMarker.Position)
		request(p, "prompt", base.ClaimMarker.ClaimSanctuary)
		check(bases:getBaseForPlayer(p) == base and p.RespawnLocation == base.PlayerSpawn, "claim and respawn target")
		uid = buy(p, "the_void")
		check(curses:getState(uid) == "PROCESSION" and souls:getBalance(p) == 500, "insufficient Souls rejected")
		curses:despawnUnsold(uid)
		uid = buy(p, "cursed_doll")
		check(curses:getState(uid) == "DELIVERING" and souls:getBalance(p) == 400, "purchase authoritative 500 to 400")
		task.wait(1)
		check(p:GetAttribute("SoulsPerSecond") == 0 and souls:getBalance(p) == 400, "no income before placement")
		local other, prompt = offer("cursed_doll")
		request(p, "prompt", prompt)
		check(curses:getState(other) == "PROCESSION" and souls:getBalance(p) == 400, "one delivery at a time")
		curses:despawnUnsold(other)
		request(p, "walk", base.FutureCurseDisplayArea.Position, 120)
		check(curses:getState(uid) == "PLACED", "physical return walk delivers")
		check((modelFor(uid).PrimaryPart.Position - base.DisplayPlinth_1.Position).Magnitude < 5, "physical first pedestal")
		check(p:GetAttribute("SoulsPerSecond") == 3, "first rate 3")
		local balance = souls:getBalance(p)
		task.wait(2)
		check(souls:getBalance(p) > balance + 5, "elapsed-time income accumulates")
		-- Isolated transitions use teleports; the first return above physically walks.
		souls:credit(p, 100000)
		for _, id in ipairs({ "haunted_mirror", "crying_mask", "watching_eye", "soul_chains" }) do
			place(p, buy(p, id), base)
		end
		check(p:GetAttribute("SoulsPerSecond") == 222, "five rates sum to 222")
		request(p, "labels")
		check(true, "client HUD 222 and only nearest pedestal label visible")
		local occupied = {}
		for _, m in ipairs(map.ActiveCurses:GetChildren()) do
			if m:IsA("Model") then
				local closest, distance
				for i, plinth in ipairs(bases:getSlots(base)) do
					local d = (m.PrimaryPart.Position - plinth.Position).Magnitude
					if not distance or d < distance then closest, distance = i, d end
				end
				check(not occupied[closest] and distance < 5, "unique pedestal " .. closest)
				occupied[closest] = true
			end
		end
		uid = buy(p, "the_void")
		check(curses:getState(uid) == "PROCESSION", "full base rejected")
		curses:despawnUnsold(uid)
		-- Broken display geometry must not stop the global delivery updater.
		local removedPlinth = base.DisplayPlinth_5
		removedPlinth.Parent = nil
		check(await(function() return p:GetAttribute("SoulsPerSecond") == 72 end), "lost placed pedestal removes its production")
		uid = buy(p, "the_void")
		teleport(p, base.FutureCurseDisplayArea.Position + Vector3.new(0, 3, 0))
		check(await(function() return curses:getState(uid) == nil end), "missing delivery pedestal refunds safely")
		local area = base.FutureCurseDisplayArea
		uid = buy(p, "the_void")
		local before = souls:getBalance(p)
		area.Parent = nil
		check(await(function() return curses:getState(uid) == nil end), "missing display area cancels safely")
		check(souls:getBalance(p) >= before + 50000, "missing area price refunded")
		area.Parent = base
		uid = buy(p, "the_void")
		before = souls:getBalance(p)
		p.Character:FindFirstChildOfClass("Humanoid").Health = 0
		check(await(function() return curses:getState(uid) == nil end), "death cancels delivery after geometry tests")
		check(souls:getBalance(p) >= before + 50000, "death refund")
		check(await(function() return p.Character and p.Character:FindFirstChildOfClass("Humanoid").Health > 0 end, 15), "respawn alive")
		check(bases:getBaseForPlayer(p) == base and p:GetAttribute("SoulsPerSecond") == 72, "claim and placed income survive respawn")
		-- Recreate a destroyed placed mesh without duplicating slot or rate.
		for _, m in ipairs(map.ActiveCurses:GetChildren()) do
			if m:IsA("Model") then uid = m:GetAttribute("CurseUid"); m:Destroy(); break end
		end
		check(await(function() return modelFor(uid) ~= nil end), "destroyed placed model restored")
		check(p:GetAttribute("SoulsPerSecond") == 72, "restoration does not duplicate income")
		removedPlinth.Parent = base
		place(p, buy(p, "the_void"), base)
		check(p:GetAttribute("SoulsPerSecond") == 822, "Void placed and rate summed to 822")
		-- Keep all six models available for visual inspection, not gameplay rewards.
		for i, id in ipairs(Catalog.Order) do
			local displayUid = curses:spawn(id, CFrame.new((i - 3.5) * 7, 5, 32))
			local root = modelFor(displayUid).PrimaryPart
			check(root.Size.Magnitude < 7 and not root.CanCollide, "scale and noncollision " .. id)
			if id == "soul_chains" or id == "the_void" then
				local accent = modelFor(displayUid):FindFirstChild(if id == "the_void" then "ImpossibleCore" else "BoundSoul")
				check(root.CFrame:PointToObjectSpace(accent.Position).Z < -root.Size.Z / 2, "front glow not buried " .. id)
			end
		end
		print("SLICE_DONE", "single-client suite passed; multiplayer requires two actual clients")
	end)
	if not ok then warn("SLICE_FAIL", err) end
end)
