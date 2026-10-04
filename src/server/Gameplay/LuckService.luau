-- The single effective Luck calculation for the shared Curse procession.
-- Sources: active Luck Potions (any player in the server) and Red Moon.
-- Published read-only to clients as ReplicatedStorage attributes:
--   ServerLuck (number multiplier, 1 = none), ServerLuckEndsAt (server time).
-- Never trusts the client; potions are profile items granted only by server
-- services (missions, Wheel of Fate).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Config = require(ReplicatedStorage.Shared.ProgressionConfig)

local Luck = {}
local potions = {} -- [userId] = expiresAt (server time)

local function redMoonActive(): boolean
	local state = ReplicatedStorage:FindFirstChild("RedMoonState")
	return state ~= nil and state:GetAttribute("Phase") == "ACTIVE"
end

function Luck.multiplier(): number
	local now = workspace:GetServerTimeNow()
	local bonus = 0
	for userId, expires in potions do
		if expires > now and Players:GetPlayerByUserId(userId) then bonus += Config.Luck.PotionBonus else potions[userId] = nil end
	end
	if redMoonActive() then bonus += Config.Luck.RedMoonBonus end
	return math.min(Config.Luck.MaxServerMultiplier, 1 + bonus)
end

local function publish()
	local latest = 0
	for _, expires in potions do latest = math.max(latest, expires) end
	ReplicatedStorage:SetAttribute("ServerLuck", Luck.multiplier())
	ReplicatedStorage:SetAttribute("ServerLuckEndsAt", latest)
end

-- Weighted weight for a definition rarity. Commons keep their base weight.
function Luck.weight(baseWeight: number, rarity: string): number
	if rarity == "COMMON" then return baseWeight end
	return baseWeight * Luck.multiplier()
end

-- Drink one potion from the player's profile inventory.
function Luck.drink(player: Player, profile): (boolean, string)
	profile.items = profile.items or {}
	local count = profile.items.luck_potion or 0
	if count < 1 then return false, "You have no Luck Potions." end
	local now = workspace:GetServerTimeNow()
	local current = math.max(now, potions[player.UserId] or 0)
	if current - now >= Config.Luck.MaxPotionStackSeconds then return false, "Your luck is already at its longest." end
	profile.items.luck_potion = count - 1
	potions[player.UserId] = math.min(now + Config.Luck.MaxPotionStackSeconds, current + Config.Luck.PotionSeconds)
	player:SetAttribute("LuckPotionEndsAt", potions[player.UserId])
	publish()
	return true, string.format("Luck Potion! Server Luck x%.1f", Luck.multiplier())
end

function Luck.start()
	Players.PlayerRemoving:Connect(function(p) potions[p.UserId] = nil publish() end)
	task.spawn(function()
		while true do
			publish()
			task.wait(1)
		end
	end)
	return Luck
end

return Luck
