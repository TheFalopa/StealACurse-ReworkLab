local Theme = require(script.Parent.Theme)
local Icons = require(script.Parent.Icons)
local C, F = Theme.colors, Theme.fonts
local Navigation = {}

-- Every entry opens a real panel: SHOP and GAMEPASSES are two tabs of the
-- same preview store, CURSES is the sanctuary panel, SETTINGS its shell.
local ITEMS = {
	{ name = "SHOP", label = "Shop", short = "Shop", icon = "shop" },
	{ name = "CURSES", label = "Curses", short = "Curses", icon = "curses" },
	{ name = "GAMEPASSES", label = "Gamepasses", short = "Passes", icon = "gamepass" },
	{ name = "SETTINGS", label = "Settings", short = "Settings", icon = "settings" },
}

-- Plain controls on the warm-ink surface: icon + label, hairline stroke, no
-- stripes, chevrons or gradients. The open panel is marked by a bone stroke.
function Navigation.create(gui: ScreenGui, onSelect)
	local holder = Theme.make("Frame", {
		Name = "Navigation", BackgroundTransparency = 1, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 100),
		Size = UDim2.fromOffset(232, 220),
	}, gui)
	local buttons = {}
	for index, item in ITEMS do
		local button = Theme.make("TextButton", {
			Name = item.name, Text = "", AutoButtonColor = false, LayoutOrder = index,
			BackgroundColor3 = C.surface, BorderSizePixel = 0, Selectable = true,
			Size = UDim2.fromOffset(232, 48),
		}, holder)
		Theme.corner(button, Theme.radius.control)
		local stroke = Theme.stroke(button, C.hairline, 1, 0.25)
		local scale = Theme.make("UIScale", { Scale = 1 }, button)
		local icon = Icons.create(item.icon, button, UDim2.fromOffset(10, 7), UDim2.fromOffset(34, 34))
		local text = Theme.label(button, "Label", item.label, UDim2.fromOffset(54, 0), UDim2.new(1, -64, 1, 0), Theme.textSize.body, C.bone, F.heavy)
		-- Hover/press tint the fill only, so the active stroke survives.
		Theme.buttonFeedback(button, C.surface, C.surfaceHi, { scale = scale })
		button.Activated:Connect(function() onSelect(item.name) end)
		buttons[item.name] = { button = button, icon = icon, text = text, item = item, stroke = stroke }
	end
	local controller = { holder = holder, buttons = buttons }
	-- Wide: a vertical stack of labelled buttons. Compact (phones): one row of
	-- 48+ px icon tiles directly under the Souls card. `rect` comes from HudLayout.
	function controller.fit(compact: boolean, rect: { x: number, y: number, w: number, h: number })
		local width = rect.w
		holder.Position = UDim2.fromOffset(rect.x + width, rect.y)
		local gap = if compact then 6 else 8
		if compact then
			local tile = math.floor((width - gap * 3) / 4)
			holder.Size = UDim2.fromOffset(width, tile + 8)
			for index, item in ITEMS do
				local data = buttons[item.name]
				data.button.Position = UDim2.fromOffset((index - 1) * (tile + gap), 0)
				data.button.Size = UDim2.fromOffset(tile, tile + 8)
				data.icon.Position = UDim2.new(0.5, -15, 0, 5)
				data.icon.Size = UDim2.fromOffset(30, 30)
				data.text.Text = item.short
				data.text.Position = UDim2.new(0, 0, 1, -18)
				data.text.Size = UDim2.new(1, 0, 0, 14)
				data.text.TextSize = Theme.textSize.caption
				data.text.FontFace = F.bold
				data.text.TextXAlignment = Enum.TextXAlignment.Center
			end
		else
			holder.Size = UDim2.fromOffset(width, #ITEMS * (48 + gap) - gap)
			for index, item in ITEMS do
				local data = buttons[item.name]
				data.button.Position = UDim2.fromOffset(0, (index - 1) * (48 + gap))
				data.button.Size = UDim2.fromOffset(width, 48)
				data.icon.Position = UDim2.fromOffset(12, 7)
				data.icon.Size = UDim2.fromOffset(34, 34)
				data.text.Text = item.label
				data.text.Position = UDim2.fromOffset(56, 0)
				data.text.Size = UDim2.new(1, -66, 1, 0)
				data.text.TextSize = Theme.textSize.body
				data.text.FontFace = F.heavy
				data.text.TextXAlignment = Enum.TextXAlignment.Left
			end
		end
		return holder.Size.Y.Offset
	end
	function controller.setActive(name: string)
		for key, data in buttons do
			local on = key == name
			data.stroke.Color = if on then C.bone else C.hairline
			data.stroke.Transparency = if on then 0 else 0.25
			data.button:SetAttribute("Selected", on)
		end
	end
	return controller
end

return Navigation
