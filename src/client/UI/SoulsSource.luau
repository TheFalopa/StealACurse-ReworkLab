-- The HUD's only binding to authoritative Souls data: the LocalPlayer
-- attributes written by the server SoulsService (Souls, SoulsPerSecond) and
-- ProfileStore (ProfileStatus). If gameplay moves the source, change only
-- this file. Read-only: the client never writes economy state.
local Players = game:GetService("Players")

local SoulsSource = {}
SoulsSource.BalanceAttribute = "Souls"
SoulsSource.RateAttribute = "SoulsPerSecond"

local function finite(value): number?
	if typeof(value) == "number" and value == value and math.abs(value) ~= math.huge then return value end
	return nil
end

function SoulsSource.balance(): number?
	return finite(Players.LocalPlayer:GetAttribute(SoulsSource.BalanceAttribute))
end

function SoulsSource.rate(): number?
	return finite(Players.LocalPlayer:GetAttribute(SoulsSource.RateAttribute))
end

-- "LOADING", "UNAVAILABLE" or nil (loaded / not reported).
function SoulsSource.status(): string?
	local status = Players.LocalPlayer:GetAttribute("ProfileStatus")
	return if typeof(status) == "string" then status else nil
end

function SoulsSource.onBalanceChanged(callback): RBXScriptConnection
	return Players.LocalPlayer:GetAttributeChangedSignal(SoulsSource.BalanceAttribute):Connect(callback)
end

function SoulsSource.onRateChanged(callback): RBXScriptConnection
	return Players.LocalPlayer:GetAttributeChangedSignal(SoulsSource.RateAttribute):Connect(callback)
end

function SoulsSource.onStatusChanged(callback): RBXScriptConnection
	return Players.LocalPlayer:GetAttributeChangedSignal("ProfileStatus"):Connect(callback)
end

return SoulsSource
