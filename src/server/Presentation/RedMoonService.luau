-- Red Moon event state (server-authoritative schedule, presentation-facing).
--
-- Publishes ReplicatedStorage.RedMoonState (Folder) attributes:
--   Phase: "OFF" | "WARNING" | "ACTIVE"
--   StartsAt / EndsAt: unix seconds (UTC) of the current or next window
--   Source: "Schedule" | "Debug"
--   MutationWeightMultiplier: Config value while ACTIVE, otherwise 1
-- Clients animate all transitions locally from these values.
--
-- Gameplay integration (codex/gameplay), no mutation system exists yet:
--   local RedMoon = require(ServerScriptService.Server.Presentation.RedMoonService)
--   RedMoon.isActive(), RedMoon.getMutationWeightMultiplier(), RedMoon.Changed
--
-- Studio-only debug (server command bar during Play):
--   game.ReplicatedStorage.RedMoonState:SetAttribute("DebugOverride", "ON")       -- full warning->active->end run
--   game.ReplicatedStorage.RedMoonState:SetAttribute("DebugOverride", "OFF")      -- force off
--   game.ReplicatedStorage.RedMoonState:SetAttribute("DebugOverride", "SCHEDULE") -- back to the real schedule
-- Ignored outside Studio, and clients cannot write server attributes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RedMoonConfig"))

local RedMoonService = {}
local changed = Instance.new("BindableEvent")
RedMoonService.Changed = changed.Event -- (phase: string)

local state: Folder? = nil
local phase = "OFF"
local started = false

local DAY = 86400

local function utcStamp(year: number, month: number, day: number, hour: number): number
	return DateTime.fromUniversalTime(year, month, day, hour).UnixTimestamp
end

-- Day-of-month of the nth Sunday (n >= 1) of a month (UTC calendar math).
local function nthSunday(year: number, month: number, n: number): number
	local wday = os.date("!*t", utcStamp(year, month, 1, 12)).wday -- 1 = Sunday
	return 1 + (8 - wday) % 7 + (n - 1) * 7
end

-- US Pacific: PDT (UTC-7) from the 2nd Sunday of March 02:00 PST (10:00 UTC)
-- to the 1st Sunday of November 02:00 PDT (09:00 UTC); otherwise PST (UTC-8).
-- Independent of the host's own time zone.
local function pacificOffsetHours(utc: number): number
	local year = os.date("!*t", utc).year
	local dstStart = utcStamp(year, 3, nthSunday(year, 3, 2), 10)
	local dstEnd = utcStamp(year, 11, nthSunday(year, 11, 1), 9)
	return if utc >= dstStart and utc < dstEnd then -7 else -8
end
RedMoonService.pacificOffsetHours = pacificOffsetHours

-- UTC start of the scheduled window for the Pacific calendar day containing `utc`.
local function windowStartForDay(utc: number): number
	local offset = pacificOffsetHours(utc) * 3600
	local localNow = utc + offset
	local localMidnight = localNow - localNow % DAY
	return localMidnight + (Config.StartHour * 3600 + Config.StartMinute * 60) - offset
end

-- Current-or-next scheduled window {start, finish} relative to `utc`.
local function scheduledWindow(utc: number): (number, number)
	for dayShift = -1, 1 do
		local start = windowStartForDay(utc + dayShift * DAY)
		local finish = start + Config.DurationSeconds
		if utc < finish and utc >= start - Config.WarningSeconds then return start, finish end
		if start - Config.WarningSeconds > utc then return start, finish end
	end
	local start = windowStartForDay(utc + DAY)
	return start, start + Config.DurationSeconds
end
RedMoonService.scheduledWindow = scheduledWindow

local debugWindow: { start: number, finish: number }? = nil
local debugForcedOff = false

local function publish(nextPhase: string, startsAt: number, endsAt: number, source: string)
	if not state then return end
	state:SetAttribute("StartsAt", startsAt)
	state:SetAttribute("EndsAt", endsAt)
	state:SetAttribute("Source", source)
	state:SetAttribute("MutationWeightMultiplier", if nextPhase == "ACTIVE" then Config.MutationWeightMultiplier else 1)
	if nextPhase ~= phase then
		phase = nextPhase
		state:SetAttribute("Phase", phase)
		changed:Fire(phase)
	end
end

local function evaluate()
	local now = os.time()
	if debugForcedOff then
		publish("OFF", 0, 0, "Debug")
		return
	end
	local start, finish, source
	if debugWindow then
		start, finish, source = debugWindow.start, debugWindow.finish, "Debug"
		if now >= finish then debugWindow = nil end
	end
	if not start then
		start, finish = scheduledWindow(now)
		source = "Schedule"
	end
	local nextPhase = if now >= start and now < finish then "ACTIVE"
		elseif now >= start - Config.WarningSeconds and now < start then "WARNING"
		else "OFF"
	publish(nextPhase, start, finish, source)
end

function RedMoonService.isActive(): boolean
	return phase == "ACTIVE"
end

function RedMoonService.getPhase(): string
	return phase
end

function RedMoonService.getMutationWeightMultiplier(): number
	return if phase == "ACTIVE" then Config.MutationWeightMultiplier else 1
end

function RedMoonService.start()
	if started then return RedMoonService end
	started = true
	state = Instance.new("Folder")
	state.Name = "RedMoonState"
	state:SetAttribute("Phase", "OFF")
	state.Parent = ReplicatedStorage
	if RunService:IsStudio() then
		state:GetAttributeChangedSignal("DebugOverride"):Connect(function()
			local value = state:GetAttribute("DebugOverride")
			local now = os.time()
			if value == "ON" then
				debugForcedOff = false
				debugWindow = { start = now + Config.WarningSeconds, finish = now + Config.WarningSeconds + Config.DebugDurationSeconds }
			elseif value == "OFF" then
				debugWindow, debugForcedOff = nil, true
			else
				debugWindow, debugForcedOff = nil, false
			end
			evaluate()
		end)
	end
	evaluate()
	task.spawn(function()
		while true do
			task.wait(1)
			evaluate()
		end
	end)
	return RedMoonService
end

return RedMoonService
