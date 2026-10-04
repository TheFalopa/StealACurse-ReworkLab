-- Two actual Studio clients; no fabricated Players or server Triggered events.
local Players = game:GetService("Players")
local control = Instance.new("RemoteEvent")
control.Name = "SliceTestControl"
control.Parent = game.ReplicatedStorage
local ready, responses = {}, {}
control.OnServerEvent:Connect(function(player, nonce, ok, result)
	if nonce == "ready" then ready[player] = true else responses[tostring(player.UserId) .. nonce] = { ok, result } end
end)
local map = require(script.Map.Build).build()
local souls = require(script.Gameplay.SoulsService).start()
local bases = require(script.Gameplay.BaseService).start(map)
local curses = require(script.Gameplay.CurseService).start(map, bases, souls)
bases:onReleased(function(player, base) curses:clearForUser(player, base) end)
local serial = 0
local function check(value, label) assert(value, label); print("MULTI_PASS", label) end
local function await(predicate, timeout)
	local deadline = os.clock() + (timeout or 6)
	repeat if predicate() then return true end; task.wait(0.1) until os.clock() >= deadline
	return false
end
local function pose(player, position)
	player.Character:PivotTo(CFrame.new(position))
	player.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
end
local function inputs(players, prompt, race)
	serial += 1
	local nonce = tostring(serial)
	local when = workspace:GetServerTimeNow() + 1.5
	for _, p in ipairs(players) do control:FireClient(p, nonce, if race then "race" else "prompt", if race then { prompt = prompt, when = when } else prompt) end
	for _, p in ipairs(players) do
		local key = tostring(p.UserId) .. nonce
		assert(await(function() return responses[key] ~= nil end, 10), "Input timeout")
		assert(responses[key][1], responses[key][2])
		responses[key] = nil
	end
	task.wait(0.5)
end
task.spawn(function()
	local ok, err = pcall(function()
		check(await(function()
			local ps = Players:GetPlayers()
			return #ps == 2 and ready[ps[1]] and ready[ps[2]] and ps[1].Character and ps[2].Character
		end, 90), "two clients ready")
		local ps = Players:GetPlayers()
		local base = bases:getBaseById("Base01")
		for i, p in ipairs(ps) do pose(p, base.ClaimMarker.Position + Vector3.new((i * 2 - 3) * 2, 0, 0)) end
		task.wait(0.8)
		inputs(ps, base.ClaimMarker.ClaimSanctuary, true)
		local winners = {}
		for _, p in ipairs(ps) do if bases:getBaseForPlayer(p) == base then table.insert(winners, p) end end
		check(#winners == 1, "same-base race has exactly one winner")
		local winner = winners[1]
		local loser = if ps[1] == winner then ps[2] else ps[1]
		local second = bases:getBaseById("Base02")
		pose(loser, second.ClaimMarker.Position)
		task.wait(0.8)
		inputs({ loser }, second.ClaimMarker.ClaimSanctuary, false)
		check(bases:getBaseForPlayer(loser) == second, "loser can claim another base")
		pose(winner, Vector3.new(-2, 4, 36)); pose(loser, Vector3.new(2, 4, 36))
		task.wait(0.8)
		local uid = curses:spawn("cursed_doll", CFrame.new(0, 5, 32))
		local model
		for _, m in ipairs(map.ActiveCurses:GetChildren()) do if m:GetAttribute("CurseUid") == uid then model = m end end
		task.wait(0.4)
		inputs(ps, model.PrimaryPart.BuyCurse, true)
		check(curses:getState(uid) == "DELIVERING", "same-Curse race purchases once")
		check(souls:getBalance(winner) + souls:getBalance(loser) == 900, "race charges exactly one price")
		local buyer = if souls:getBalance(winner) == 400 then winner else loser
		local buyerBase = bases:getBaseForPlayer(buyer)
		buyer:Kick("Local fixture: verify disconnect cleanup")
		check(await(function() return buyerBase:GetAttribute("OwnerUserId") == nil end), "disconnect releases base")
		check(curses:getState(uid) == nil and buyerBase.ClaimMarker.ClaimSanctuary.Enabled, "disconnect clears delivery and reopens claim")
		local survivor = if buyer == winner then loser else winner
		-- A player with another base must still be denied a second claim.
		pose(survivor, buyerBase.ClaimMarker.Position); task.wait(0.8)
		inputs({ survivor }, buyerBase.ClaimMarker.ClaimSanctuary, false)
		check(buyerBase:GetAttribute("OwnerUserId") == nil, "one sanctuary per player enforced")
		print("MULTI_DONE", "all two-client assertions passed")
	end)
	if not ok then warn("MULTI_FAIL", err) end
end)
