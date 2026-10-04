local Theme = require(script.Parent.Theme)
local Icons = require(script.Parent.Icons)
local C, F = Theme.colors, Theme.fonts
local Navigation = {}

-- Every entry opens a real panel: SHOP and GAMEPASSES are two tabs of the
-- same preview store, CURSES is the sanctuary panel, SETTINGS its shell.
local ITEMS = {
	{ name = "SHOP", label = "Shop", short = "SHOP", icon = "shop", accent = C.amber },
	{ name = "CURSES", label = "Curses", short = "CURSES", icon = "curses", accent = C.violet },
	{ name = "GAMEPASSES", label = "Gamepasses", short = "PASSES", icon = "gamepass", accent = C.magenta },
	{ name = "SETTINGS", label = "Settings", short = "SETTINGS", icon = "settings", accent = C.muted },
}

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
			BackgroundColor3 = C.panel, BorderSizePixel = 0, Selectable = true,
			Size = UDim2.fromOffset(232, 48),
		}, holder)
		Theme.corner(button, 12)
		Theme.gradient(button, Color3.new(1, 1, 1), Color3.fromRGB(150, 146, 178), true)
		local stroke = Theme.stroke(button, C.line, 1.2, 0.35)
		local scale = Theme.make("UIScale", { Scale = 1 }, button)
		local stripe = Theme.make("Frame", {
			Name = "Accent", BackgroundColor3 = item.accent, BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 12), Size = UDim2.fromOffset(3, 24),
		}, button)
		Theme.corner(stripe, 2)
		local icon = Icons.create(item.icon, button, UDim2.fromOffset(10, 7), UDim2.fromOffset(34, 34))
		local text = Theme.label(button, "Label", item.label, UDim2.fromOffset(54, 0), UDim2.new(1, -64, 1, 0), 17, C.white, F.heavy)
		local chevron = Theme.label(button, "Chevron", "›", UDim2.new(1, -26, 0, 0), UDim2.new(0, 16, 1, -2), 24, C.subtle, F.heavy)
		chevron.TextXAlignment = Enum.TextXAlignment.Center
		Theme.buttonFeedback(button, C.panel, C.cardHi, { scale = scale, stroke = stroke, accent = item.accent })
		button.MouseEnter:Connect(function() Theme.tween(chevron, 0.12, { Position = UDim2.new(1, -22, 0, 0), TextColor3 = item.accent }) end)
		button.MouseLeave:Connect(function() Theme.tween(chevron, 0.15, { Position = UDim2.new(1, -26, 0, 0), TextColor3 = C.subtle }) end)
		button.Activated:Connect(function() onSelect(item.name) end)
		buttons[item.name] = { button = button, icon = icon, text = text, stripe = stripe, item = item, stroke = stroke, chevron = chevron }
	end
	local controller = { holder = holder, buttons = buttons }
	-- Wide: a vertical stack of labelled buttons. Compact (phones): one row of
	-- 48+ px icon tiles directly under the Souls card, clear of the jump button.
	function controller.fit(compact: boolean, width: number, y: number)
		holder.Position = UDim2.new(1, -14, 0, y)
		local gap = if compact then 6 else 8
		if compact then
			local tile = math.floor((width - gap * 3) / 4)
			holder.Size = UDim2.fromOffset(width, tile + 8)
			for index, item in ITEMS do
				local data = buttons[item.name]
				data.button.Position = UDim2.fromOffset((index - 1) * (tile + gap), 0)
				data.button.Size = UDim2.fromOffset(tile, tile + 8)
				data.icon.Position = UDim2.new(0.5, -15, 0, 6)
				data.icon.Size = UDim2.fromOffset(30, 30)
				data.text.Text = item.short
				data.text.Position = UDim2.new(0, 0, 1, -17)
				data.text.Size = UDim2.new(1, 0, 0, 13)
				data.text.TextSize = 10
				data.text.TextXAlignment = Enum.TextXAlignment.Center
				data.stripe.Position = UDim2.new(0.5, -10, 1, -3)
				data.stripe.Size = UDim2.fromOffset(20, 3)
				data.chevron.Visible = false
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
				data.text.TextSize = 17
				data.text.TextXAlignment = Enum.TextXAlignment.Left
				data.stripe.Position = UDim2.fromOffset(0, 12)
				data.stripe.Size = UDim2.fromOffset(3, 24)
				data.chevron.Visible = true
			end
		end
		return holder.Size.Y.Offset
	end
	function controller.setActive(name: string)
		for key, data in buttons do
			local on = key == name
			data.stroke.Color = if on then data.item.accent else C.line
			data.stroke.Transparency = if on then 0 else 0.35
			data.button:SetAttribute("Selected", on)
			Theme.tween(data.stripe, 0.15, { BackgroundTransparency = if on or name == "" then 0 else 0.5 })
		end
	end
	return controller
end

return Navigation
