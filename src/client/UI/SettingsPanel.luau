local Theme = require(script.Parent.Theme)
local PanelFrame = require(script.Parent.PanelFrame)
local ClientSettings = require(script.Parent.ClientSettings)
local C, F = Theme.colors, Theme.fonts
local SettingsPanel = {}

local ROWS = {
	{ key = "vfxQuality", title = "Curse effects", detail = "Reduced lowers particle counts and nearby lights." },
	{ key = "sanctuaryMarker", title = "Sanctuary marker", detail = "Shows the way to your own sanctuary from afar." },
	{ key = "announcements", title = "Event announcements", detail = "Minimal keeps only the small event indicator." },
}

-- Presentation preferences only (ClientSettings); nothing here is saved to a
-- profile or affects gameplay.
function SettingsPanel.create(gui: ScreenGui, onClose)
	local chrome = PanelFrame.create(gui, "SettingsOverlay", "SettingsPanel", "Settings", "Display preferences  ·  this device", "settings", C.violet, onClose)
	local list = Theme.make("ScrollingFrame", {
		Name = "Content", Active = true, ClipsDescendants = true, BackgroundTransparency = 1, BorderSizePixel = 0,
		Position = UDim2.fromOffset(20, 92), Size = UDim2.new(1, -40, 1, -130),
		CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4, ScrollBarImageColor3 = C.violet, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 22,
	}, chrome.panel)
	Theme.make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	Theme.make("UIPadding", { PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8) }, list)
	local refreshers = {}
	for order, row in ROWS do
		local frame = Theme.make("Frame", {
			Name = row.key, LayoutOrder = order, BackgroundColor3 = C.card, BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 74), ZIndex = 23,
		}, list)
		Theme.corner(frame, 12)
		Theme.stroke(frame, C.line, 1, 0.45)
		local title = Theme.label(frame, "Title", row.title, UDim2.fromOffset(16, 12), UDim2.new(1, -230, 0, 22), 17, C.white, F.heavy)
		title.ZIndex = 24
		local detail = Theme.label(frame, "Detail", row.detail, UDim2.fromOffset(16, 36), UDim2.new(1, -230, 0, 30), 12, C.muted, F.medium)
		detail.TextWrapped = true
		detail.TextYAlignment = Enum.TextYAlignment.Top
		detail.ZIndex = 24
		local options = ClientSettings.Options[row.key]
		local toggle = Theme.make("Frame", {
			Name = "Toggle", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(200, 44), BackgroundColor3 = C.ink, BorderSizePixel = 0, ZIndex = 24,
		}, frame)
		Theme.corner(toggle, 10)
		Theme.stroke(toggle, C.line, 1, 0.5)
		local buttons = {}
		for index, option in options do
			local button = Theme.make("TextButton", {
				Name = option, Text = string.upper(option), AutoButtonColor = false,
				Position = UDim2.new((index - 1) / #options, 3, 0, 3), Size = UDim2.new(1 / #options, -6, 1, -6),
				BackgroundColor3 = C.cardHi, BackgroundTransparency = 1, BorderSizePixel = 0,
				FontFace = F.heavy, TextSize = 13, TextColor3 = C.subtle, Selectable = true, ZIndex = 25,
			}, toggle)
			Theme.corner(button, 8)
			button.Activated:Connect(function() ClientSettings.set(row.key, option) end)
			buttons[option] = button
		end
		refreshers[row.key] = function()
			local current = ClientSettings.get(row.key)
			for option, button in buttons do
				local on = option == current
				Theme.tween(button, 0.12, { BackgroundTransparency = if on then 0 else 1, TextColor3 = if on then C.white else C.subtle })
			end
		end
		refreshers[row.key]()
		frame:SetAttribute("NarrowLayout", false)
	end
	ClientSettings.Changed:Connect(function(key) if refreshers[key] then refreshers[key]() end end)
	chrome.footer.Text = "Preferences apply to this device only."
	return {
		overlay = chrome.overlay,
		show = chrome.show,
		fit = function(safeSize: Vector2)
			local width, _, short = chrome.fit(safeSize)
			local y = if short then 62 else 92
			list.Position = UDim2.fromOffset(20, y)
			list.Size = UDim2.new(1, -40, 1, -y - 38)
			local narrow = width < 520
			for _, row in ROWS do
				local frame = list[row.key]
				frame.Size = UDim2.new(1, 0, 0, if narrow then 124 else 74)
				frame.Title.Size = UDim2.new(1, if narrow then -32 else -230, 0, 22)
				frame.Detail.Size = UDim2.new(1, if narrow then -32 else -230, 0, 30)
				frame.Toggle.AnchorPoint = if narrow then Vector2.new(0, 1) else Vector2.new(1, 0.5)
				frame.Toggle.Position = if narrow then UDim2.new(0, 14, 1, -10) else UDim2.new(1, -14, 0.5, 0)
				frame.Toggle.Size = UDim2.fromOffset(if narrow then width - 68 else 200, if narrow then 40 else 44)
			end
		end,
	}
end

return SettingsPanel
