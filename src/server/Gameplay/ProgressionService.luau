-- Missions (Mortimer the Gravekeeper), consumable items and the Wheel of Fate.
-- Server-authoritative: progress is computed from existing state (profile
-- curses/sanctuary, SoulsPerSecond, ClaimedBaseId, Red Moon); rewards are
-- granted only here. Profile fields (all optional, migrated with defaults):
--   items   = { luck_potion = n }
--   missions= { index = 1, accepted = bool, eventClaimed = { [startsAt] = true } }
--   wheel   = { lastFreeDay = n, bonusSpins = n }
--   seen    = { [cinematicId] = true }
-- Remote: ReplicatedStorage.Progression.Request(action, value) -> {ok,message,state?,...}
--         ReplicatedStorage.Progression.Changed (state)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Catalog = require(ReplicatedStorage.Shared.CurseCatalog)
local Config = require(ReplicatedStorage.Shared.ProgressionConfig)
local ToolInventory = require(ReplicatedStorage.Shared.ToolInventory)
local Luck = require(script.Parent.LuckService)

local Progression = {}

local RARITY_RANK = { COMMON = 1, RARE = 2, LEGENDARY = 3, MYTHIC = 4, SECRET = 5 }
local DAY = 86400

local function today(): number
	return math.floor(workspace:GetServerTimeNow() / DAY)
end

function Progression.start(map, profiles, souls, tools, bases)
	local folder = Instance.new("Folder")
	folder.Name = "Progression"
	folder.Parent = ReplicatedStorage
	local request = Instance.new("RemoteFunction")
	request.Name = "Request"
	request.Parent = folder
	local changed = Instance.new("RemoteEvent")
	changed.Name = "Changed"
	changed.Parent = folder
	local cinematic = Instance.new("RemoteEvent")
	cinematic.Name = "Cinematic"
	cinematic.Parent = folder

	local service = { npcPosition = nil, wheelPosition = nil }
	local spam, redMoonSeconds = {}, {}
	local random = Random.new()

	local function migrate(p)
		local dirty = false
		if typeof(p.items) ~= "table" then p.items = {} dirty = true end
		if typeof(p.missions) ~= "table" then p.missions = { index = 1, accepted = false, eventClaimed = {} } dirty = true end
		if typeof(p.missions.eventClaimed) ~= "table" then p.missions.eventClaimed = {} dirty = true end
		if typeof(p.wheel) ~= "table" then p.wheel = { lastFreeDay = -1, bonusSpins = 0 } dirty = true end
		if typeof(p.seen) ~= "table" then p.seen = {} dirty = true end
		return dirty
	end

	local function rootOf(player)
		local c = player.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		local r = c and c:FindFirstChild("HumanoidRootPart")
		return if player:GetAttribute("ProfileStatus") == "READY" and h and h.Health > 0 then r else nil
	end
	local function near(player, position, distance)
		local r = rootOf(player)
		return r ~= nil and position ~= nil and (r.Position - position).Magnitude <= distance
	end

	---------------------------------------------------------------- progress
	local function progressFor(player, p, mission): number
		local kind = mission.kind
		if kind == "claim_and_place" then
			if not player:GetAttribute("ClaimedBaseId") then return 0 end
			for _, c in p.curses do if c.state == "PLACED" then return 1 end end
			return 0
		elseif kind == "souls_rate" then
			return math.floor(player:GetAttribute("SoulsPerSecond") or 0)
		elseif kind == "sanctuary_level" then
			return p.sanctuary and p.sanctuary.level or 0
		elseif kind == "unique_curses" then
			local seen, n = {}, 0
			for _, c in p.curses do if not seen[c.definitionId] then seen[c.definitionId] = true n += 1 end end
			return n
		elseif kind == "rarity_owned" then
			local need = RARITY_RANK[mission.rarity] or 3
			for _, c in p.curses do
				local d = Catalog.Definitions[c.definitionId]
				if d and (RARITY_RANK[d.rarity] or 0) >= need then return 1 end
			end
			return 0
		elseif kind == "red_moon" then
			return math.floor(redMoonSeconds[player] or 0)
		end
		return 0
	end

	local function currentMission(p)
		return Config.Missions[p.missions.index]
	end
	local function redMoonWindow(): number?
		local state = ReplicatedStorage:FindFirstChild("RedMoonState")
		if state and state:GetAttribute("Phase") == "ACTIVE" then return state:GetAttribute("StartsAt") end
		return nil
	end

	function service:state(player)
		local p = profiles:get(player)
		if not p then return nil end
		migrate(p)
		local mission = currentMission(p)
		local out = {
			npc = { name = Config.NpcName, title = Config.NpcTitle },
			items = table.clone(p.items),
			wheel = {
				freeAvailable = p.wheel.lastFreeDay < today(), bonusSpins = p.wheel.bonusSpins,
				nextFreeAt = (today() + 1) * DAY, paidEnabled = Config.Wheel.PaidSpinsEnabled,
			},
			luck = { multiplier = Luck.multiplier(), potionEndsAt = player:GetAttribute("LuckPotionEndsAt") or 0 },
			seen = table.clone(p.seen),
		}
		if mission then
			local progress = progressFor(player, p, mission)
			out.mission = {
				index = p.missions.index, total = #Config.Missions, id = mission.id, title = mission.title, line = mission.line,
				objective = mission.objective, target = mission.target, progress = math.min(progress, mission.target),
				accepted = p.missions.accepted, complete = p.missions.accepted and progress >= mission.target, rewards = mission.rewards,
			}
		end
		local window = redMoonWindow()
		if window and not p.missions.eventClaimed[tostring(window)] then
			local e = Config.EventMission
			local progress = progressFor(player, p, e)
			out.event = { id = e.id, title = e.title, line = e.line, objective = e.objective, target = e.target,
				progress = math.min(progress, e.target), complete = progress >= e.target, rewards = e.rewards }
		end
		return out
	end

	local function publish(player)
		local s = service:state(player)
		if not s then return end
		changed:FireClient(player, s)
		local m = s.mission
		player:SetAttribute("MissionTitle", m and m.title or nil)
		player:SetAttribute("MissionObjective", m and m.objective or nil)
		player:SetAttribute("MissionProgress", m and m.progress or nil)
		player:SetAttribute("MissionTarget", m and m.target or nil)
		player:SetAttribute("MissionState", if not m then "DONE" elseif not m.accepted then "OFFER" elseif m.complete then "COMPLETE" else "ACTIVE")
	end
	service.publish = publish

	---------------------------------------------------------------- rewards
	local function grant(player, p, rewards)
		local parts = {}
		if rewards.souls then souls:credit(player, rewards.souls) table.insert(parts, "+" .. rewards.souls .. " Souls") end
		for id, n in rewards.items or {} do
			p.items[id] = (p.items[id] or 0) + n
			table.insert(parts, "+" .. n .. " " .. (Config.Items[id] and Config.Items[id].name or id))
		end
		for id, n in rewards.tools or {} do
			if ToolInventory.grant(p.tools, id, n) then table.insert(parts, "+" .. n .. " tool charges") end
		end
		if rewards.spins then p.wheel.bonusSpins += rewards.spins table.insert(parts, "+" .. rewards.spins .. " Wheel spin") end
		if tools then tools:publish(player) end
		return table.concat(parts, "  ")
	end

	---------------------------------------------------------------- actions
	local function answer(ok, message, extra)
		local a = extra or {}
		a.ok, a.message = ok, message
		return a
	end

	function service:action(player, action, value)
		local p = profiles:get(player)
		if not p or not rootOf(player) then return answer(false, "Wait for your character to load.") end
		migrate(p)
		if action == "state" then return answer(true, "", { state = service:state(player) }) end
		if action == "accept" then
			if not near(player, service.npcPosition, 14) then return answer(false, "Talk to Mortimer first.") end
			local mission = currentMission(p)
			if not mission then return answer(false, "No new tasks right now.") end
			if p.missions.accepted then return answer(true, "") end
			p.missions.accepted = true
			profiles:commit(player)
			publish(player)
			return answer(true, "New task: " .. mission.title)
		elseif action == "claim" then
			if not near(player, service.npcPosition, 14) then return answer(false, "Return to Mortimer to claim.") end
			if value == "event" then
				local window = redMoonWindow()
				local e = Config.EventMission
				if not window or p.missions.eventClaimed[tostring(window)] then return answer(false, "Nothing to claim.") end
				if progressFor(player, p, e) < e.target then return answer(false, "Not finished yet.") end
				p.missions.eventClaimed[tostring(window)] = true
				local text = grant(player, p, e.rewards)
				profiles:commit(player)
				publish(player)
				return answer(true, "Task complete!  " .. text, { rewards = e.rewards })
			end
			local mission = currentMission(p)
			if not mission or not p.missions.accepted then return answer(false, "Nothing to claim.") end
			if progressFor(player, p, mission) < mission.target then return answer(false, "Not finished yet.") end
			-- Advance first: a duplicate request can never claim twice.
			p.missions.index += 1
			p.missions.accepted = false
			local text = grant(player, p, mission.rewards)
			local cine = mission.cinematic
			local play = cine and not p.seen[cine]
			if play then p.seen[cine] = true end
			profiles:commit(player)
			publish(player)
			if play then cinematic:FireClient(player, cine) end
			return answer(true, "Task complete!  " .. text, { rewards = mission.rewards, cinematic = if play then cine else nil })
		elseif action == "drink" then
			if value ~= "luck_potion" then return answer(false, "Unknown item.") end
			local ok, message = Luck.drink(player, p)
			if ok then profiles:commit(player) publish(player) end
			return answer(ok, message)
		elseif action == "spin" then
			if not near(player, service.wheelPosition, 16) then return answer(false, "Step up to the Wheel of Fate.") end
			local free = p.wheel.lastFreeDay < today()
			if not free and p.wheel.bonusSpins < 1 then return answer(false, "No spins left. Your free spin returns tomorrow.") end
			if free then p.wheel.lastFreeDay = today() else p.wheel.bonusSpins -= 1 end
			-- Outcome decided here, with the published weights; the client only
			-- animates toward it.
			local total = Config.wheelTotalWeight()
			local roll = random:NextNumber(0, total)
			local index = #Config.Wheel.Sectors
			for i, s in Config.Wheel.Sectors do roll -= s.weight if roll <= 0 then index = i break end end
			local sector = Config.Wheel.Sectors[index]
			local result = ""
			if sector.grant == "souls" then souls:credit(player, sector.amount) result = "+" .. sector.amount .. " Souls"
			elseif sector.grant == "luck_potion" then p.items.luck_potion = (p.items.luck_potion or 0) + sector.amount result = "+1 Luck Potion"
			elseif sector.grant == "tool" then ToolInventory.grant(p.tools, sector.tool, sector.amount) if tools then tools:publish(player) end result = "+" .. sector.amount .. " Impact Urns"
			elseif sector.grant == "spin" then p.wheel.bonusSpins += sector.amount result = "Spin again!"
			elseif sector.grant == "prank" then
				-- Harmless, short, never costs progress.
				if sector.prank == "heavy_feet" and tools and tools.status then
					tools.status:add(player, "wheel_heavy", { slow = 0.8, duration = 15 })
				end
				player:SetAttribute("WheelPrank", sector.prank)
				player:SetAttribute("WheelPrankUntil", workspace:GetServerTimeNow() + Config.Wheel.SpinSeconds + 15)
				result = if sector.prank == "laugh" then "The spirits laughed at you." else "Heavy feet for 15 seconds."
			end
			profiles:commit(player)
			task.delay(Config.Wheel.SpinSeconds, function() if player.Parent then publish(player) end end)
			return answer(true, result, { index = index, sector = sector.id, spinSeconds = Config.Wheel.SpinSeconds, state = service:state(player) })
		elseif action == "seen" then
			if typeof(value) == "string" and #value < 40 then p.seen[value] = true profiles:commit(player) end
			return answer(true, "")
		end
		return answer(false, "Action not available.")
	end

	request.OnServerInvoke = function(player, action, value)
		if typeof(action) ~= "string" or #action > 16 or (value ~= nil and (typeof(value) ~= "string" or #value > 40)) then
			return answer(false, "Invalid request.")
		end
		local now = os.clock()
		if now - (spam[player] or -1e6) < 0.25 then return answer(false, "One moment.") end
		spam[player] = now
		return service:action(player, action, value)
	end

	profiles:onLoaded(function(player, p)
		if migrate(p) then profiles:commit(player) end
		task.defer(publish, player)
	end)
	Players.PlayerRemoving:Connect(function(player) spam[player] = nil redMoonSeconds[player] = nil end)

	-- One light loop: progress attributes + Red Moon presence.
	task.spawn(function()
		while map.Parent do
			task.wait(1)
			local moon = redMoonWindow() ~= nil
			for _, player in Players:GetPlayers() do
				if profiles:get(player) then
					if moon then redMoonSeconds[player] = (redMoonSeconds[player] or 0) + 1 end
					publish(player)
				end
			end
		end
	end)

	---------------------------------------------------------------- Studio QA
	if RunService:IsStudio() then
		-- Studio-only QA (server command bar during Play; ignored in live games):
		--   game.ReplicatedStorage.Progression:SetAttribute("Debug", "reset_daily")
		--   ... "spins 5" | "potion 2" | "mission 3" | "reset_missions"
		-- Result is written to the "DebugResult" attribute.
		folder:GetAttributeChangedSignal("Debug"):Connect(function()
			local text = folder:GetAttribute("Debug")
			if typeof(text) ~= "string" or text == "" then return end
			local command, arg = string.match(text, "^(%S+)%s*(%S*)")
			folder:SetAttribute("DebugResult", Progression.debug(command, arg))
			folder:SetAttribute("Debug", "")
		end)
		Progression.debug = function(command, arg)
			local player = Players:GetPlayers()[1]
			local p = player and profiles:get(player)
			if not p then return "no profile" end
			migrate(p)
			if command == "reset_daily" then p.wheel.lastFreeDay = -1
			elseif command == "spins" then p.wheel.bonusSpins += tonumber(arg) or 5
			elseif command == "potion" then p.items.luck_potion = (p.items.luck_potion or 0) + (tonumber(arg) or 1)
			elseif command == "mission" then p.missions.index = math.clamp(tonumber(arg) or 1, 1, #Config.Missions + 1) p.missions.accepted = false
			elseif command == "reset_missions" then p.missions = { index = 1, accepted = false, eventClaimed = {} } p.seen = {}
			else return "commands: reset_daily | spins n | potion n | mission n | reset_missions" end
			profiles:commit(player)
			publish(player)
			return "ok"
		end
	end
	return service
end

return Progression
