-- One notification surface for the whole client. Server notices still arrive
-- through HUDNotice/HUDNoticeSerial; client systems (tools, Mortimer, Wheel)
-- push here, and HUD renders both as the same top toast.
--   tone: "info" (default) | "good" | "bad"
local Notify = {}
local event = Instance.new("BindableEvent")

Notify.pushed = event.Event

function Notify.push(text: string?, tone: string?)
	if typeof(text) ~= "string" or text == "" then return end
	event:Fire(text, tone or "info")
end

return Notify
