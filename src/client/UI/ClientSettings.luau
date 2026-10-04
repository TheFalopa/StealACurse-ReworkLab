-- Local, presentation-only preferences (this session, this client).
-- They never touch profiles, economy or gameplay rules.
local ClientSettings = {}

local OPTIONS = {
	vfxQuality = { "High", "Reduced" },
	sanctuaryMarker = { "On", "Off" },
	announcements = { "Full", "Minimal" },
}
local values = { vfxQuality = "High", sanctuaryMarker = "On", announcements = "Full" }
local changed = Instance.new("BindableEvent")

ClientSettings.Options = OPTIONS
ClientSettings.Changed = changed.Event -- (key: string, value: string)

function ClientSettings.get(key: string): string
	return values[key]
end

function ClientSettings.set(key: string, value: string)
	if not OPTIONS[key] or not table.find(OPTIONS[key], value) or values[key] == value then return end
	values[key] = value
	changed:Fire(key, value)
end

return ClientSettings
