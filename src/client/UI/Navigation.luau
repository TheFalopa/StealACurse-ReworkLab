local Theme = require(script.Parent.Theme)
local Glyphs = require(script.Parent.Glyphs)
local C, F = Theme.colors, Theme.fonts
local Navigation = {}

-- The names are HUD.selectPanel's contract: CURSES opens the sanctuary panel
-- (shown as the Grimoire), SHOP the preview store (Passes tab first; its tabs
-- still reach Products), SETTINGS the settings shell.
local ITEMS = {
	{ name = "CURSES", label = "Grimoire", glyph = "grimoire" },
	{ name = "SHOP", label = "Shop", glyph = "shop" },
	{ name = "SETTINGS", label = "Settings", glyph = "settings" },
}

-- Entry anatomy inside the 56 px dock: glyph, caption, then the active
-- underline. The hover/press tint is inset so it never meets the dock edge.
local GLYPH_Y, LABEL_Y, LABEL_H, UNDERLINE_Y = 8, 32, 14, 48
local TINT_INSET, DIVIDER_H = 4, 28
local REST, ACTIVE = C.muted, C.white

-- One quiet capsule under the Souls card: the card's family (panel fill with
-- a soft top-lit shade, line stroke, bevel) at a lower volume. No stripes,
-- chevrons or idle motion; state is colour plus a violet underline.
function Navigation.create(gui: ScreenGui, onSelect)
	local holder = Theme.make("Frame", {
		Name = "Navigation", BackgroundColor3 = C.panel, BorderSizePixel = 0,
		-- Top-right until the first HudLayout frame arrives.
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 100), Size = UDim2.fromOffset(232, 56),
	}, gui)
	Theme.corner(holder, Theme.radius.panel)
	Theme.gradient(holder, Color3.new(1, 1, 1), Color3.fromRGB(176, 172, 200), true)
	Theme.stroke(holder, C.line, 1, 0.4)
	Theme.make("Frame", {
		Name = "Bevel", BackgroundColor3 = C.white, BackgroundTransparency = 0.94, BorderSizePixel = 0,
		Position = UDim2.fromOffset(12, 1), Size = UDim2.new(1, -24, 0, 1),
	}, holder)
	local dividers = {}
	for index = 1, #ITEMS - 1 do
		dividers[index] = Theme.make("Frame", {
			Name = "Divider" .. index, BackgroundColor3 = C.line, BackgroundTransparency = 0.6, BorderSizePixel = 0,
			Size = UDim2.fromOffset(1, DIVIDER_H), ZIndex = 3,
		}, holder)
	end

	local buttons = {}
	for index, item in ITEMS do
		local button = Theme.make("TextButton", {
			Name = item.name, Text = "", AutoButtonColor = false, LayoutOrder = index,
			BackgroundTransparency = 1, BorderSizePixel = 0, Selectable = true,
			-- Centre anchor so the press scale shrinks toward the middle.
			AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(76, 56), ZIndex = 2,
		}, holder)
		local scale = Theme.make("UIScale", { Scale = 1 }, button)
		local tint = Theme.make("Frame", {
			Name = "Tint", BackgroundColor3 = C.cardHi, BackgroundTransparency = 1, BorderSizePixel = 0,
			Position = UDim2.fromOffset(TINT_INSET, TINT_INSET), Size = UDim2.new(1, -2 * TINT_INSET, 1, -2 * TINT_INSET), ZIndex = 1,
		}, button)
		Theme.corner(tint, Theme.radius.panel - TINT_INSET)
		local glyph, paint = Glyphs.create(item.glyph, button, UDim2.new(0.5, -Glyphs.box / 2, 0, GLYPH_Y), UDim2.fromOffset(Glyphs.box, Glyphs.box), REST)
		glyph.ZIndex = 2
		local text = Theme.label(button, "Label", item.label, UDim2.fromOffset(0, LABEL_Y), UDim2.new(1, 0, 0, LABEL_H), Theme.textSize.caption, REST, F.bold)
		text.TextXAlignment = Enum.TextXAlignment.Center
		text.ZIndex = 2
		local underline = Theme.make("Frame", {
			Name = "Underline", AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = C.violet, BorderSizePixel = 0,
			Position = UDim2.new(0.5, 0, 0, UNDERLINE_Y), Size = UDim2.fromOffset(16, 2), Visible = false, ZIndex = 2,
		}, button)
		Theme.corner(underline, 1)
		-- As wide as the word, kept even so it stays on whole pixels. TextBounds
		-- follows the press UIScale, so only the resting size is used.
		local function sizeUnderline()
			if scale.Scale ~= 1 then return end
			local width = math.max(12, math.floor(text.TextBounds.X))
			underline.Size = UDim2.fromOffset(width - width % 2, 2)
		end
		text:GetPropertyChangedSignal("TextBounds"):Connect(sizeUnderline)
		sizeUnderline()

		-- Hover, gamepad selection and press share one soft inner tint; press
		-- also scales the entry to 0.96. Activated serves mouse, touch, keys
		-- and gamepad alike, so no action depends on hover.
		local hovered, pressed, selected = false, false, false
		local function refresh()
			local lit = hovered or pressed or selected
			Theme.tween(tint, 0.12, { BackgroundTransparency = if lit then 0.55 else 1 })
			Theme.tween(scale, if pressed then 0.06 else 0.12, { Scale = if pressed then 0.96 else 1 })
		end
		local function isPress(input: InputObject): boolean
			return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
		end
		button.MouseEnter:Connect(function()
			hovered = true
			refresh()
		end)
		button.MouseLeave:Connect(function()
			hovered, pressed = false, false
			refresh()
		end)
		button.SelectionGained:Connect(function()
			selected = true
			refresh()
		end)
		button.SelectionLost:Connect(function()
			selected = false
			refresh()
		end)
		button.InputBegan:Connect(function(input)
			if not isPress(input) then return end
			pressed = true
			refresh()
		end)
		button.InputEnded:Connect(function(input)
			if not isPress(input) then return end
			pressed = false
			-- Touch has no hover to fall back to.
			if input.UserInputType == Enum.UserInputType.Touch then hovered = false end
			refresh()
		end)
		button.Activated:Connect(function() onSelect(item.name) end)
		buttons[item.name] = { button = button, glyph = glyph, paint = paint, text = text, underline = underline }
	end

	local controller = { holder = holder, buttons = buttons }
	-- `rect` and `entries` (absolute safe-area rects) come from HudLayout.
	function controller.fit(rect: { x: number, y: number, w: number, h: number }, entries: { { x: number, y: number, w: number, h: number } }?)
		holder.AnchorPoint = Vector2.zero
		holder.Position = UDim2.fromOffset(rect.x, rect.y)
		holder.Size = UDim2.fromOffset(rect.w, rect.h)
		local slots = entries
		if not slots or #slots ~= #ITEMS then
			-- Defensive fallback: equal even-width entries across the dock.
			local width = math.floor(rect.w / #ITEMS)
			width -= width % 2
			local x0 = rect.x + math.floor((rect.w - #ITEMS * width) / 2)
			slots = {}
			for index = 1, #ITEMS do slots[index] = { x = x0 + (index - 1) * width, y = rect.y, w = width, h = rect.h } end
		end
		for index, item in ITEMS do
			local slot = slots[index]
			local button = buttons[item.name].button
			button.Position = UDim2.fromOffset(slot.x - rect.x + math.floor(slot.w / 2), slot.y - rect.y + math.floor(slot.h / 2))
			button.Size = UDim2.fromOffset(slot.w, slot.h)
		end
		for index, divider in dividers do
			divider.Position = UDim2.fromOffset(slots[index + 1].x - rect.x, math.floor((rect.h - DIVIDER_H) / 2))
		end
	end
	function controller.setActive(name: string)
		for key, data in buttons do
			local on = key == name
			local color = if on then ACTIVE else REST
			data.paint(color, 0.12)
			Theme.tween(data.text, 0.12, { TextColor3 = color })
			data.underline.Visible = on
			data.button:SetAttribute("Selected", on)
		end
	end
	return controller
end

return Navigation
