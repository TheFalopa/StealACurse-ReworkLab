-- Haunted premium palette and shared UI helpers. Icons are original uploaded
-- images (see Shared.VisualAssets); every other surface is native UI.
local TweenService = game:GetService("TweenService")

local Theme = {}
Theme.colors = {
	ink = Color3.fromRGB(11, 10, 22),
	panel = Color3.fromRGB(20, 18, 36),
	panelTop = Color3.fromRGB(38, 29, 62),
	card = Color3.fromRGB(29, 25, 50),
	cardHi = Color3.fromRGB(44, 35, 74),
	line = Color3.fromRGB(88, 72, 134),
	violet = Color3.fromRGB(156, 118, 236),
	deepViolet = Color3.fromRGB(66, 38, 122),
	cyan = Color3.fromRGB(112, 240, 226),
	soulGreen = Color3.fromRGB(142, 255, 196),
	magenta = Color3.fromRGB(214, 98, 180),
	amber = Color3.fromRGB(246, 190, 102),
	white = Color3.fromRGB(247, 244, 255),
	muted = Color3.fromRGB(186, 182, 212),
	subtle = Color3.fromRGB(128, 124, 162),
	-- Role names introduced by the Phase 1 HUD sample. The owner kept the
	-- violet-ink palette, so each role maps onto that family: surface sits
	-- between panel and card, the rest alias the tokens above.
	surface = Color3.fromRGB(24, 20, 42),
	surfaceHi = Color3.fromRGB(44, 35, 74),
	hairline = Color3.fromRGB(88, 72, 134),
	bone = Color3.fromRGB(247, 244, 255),
	boneMuted = Color3.fromRGB(186, 182, 212),
}
-- Two radii: panels and controls.
Theme.radius = { panel = 12, control = 10 }
-- Type scale; 12 is the smallest caption.
Theme.textSize = { caption = 12, body = 14, heading = 18, hero = 30 }

local family = "rbxasset://fonts/families/BuilderSans.json"
Theme.fonts = {
	number = Font.new(family, Enum.FontWeight.Heavy),
	heavy = Font.new(family, Enum.FontWeight.ExtraBold),
	bold = Font.new(family, Enum.FontWeight.Bold),
	medium = Font.new(family, Enum.FontWeight.Medium),
	-- Gothic display face only for panel titles, never for numbers or body copy.
	display = Font.new("rbxasset://fonts/families/GrenzeGotisch.json", Enum.FontWeight.Bold),
}

function Theme.make(className: string, properties, parent: Instance): any
	local object = Instance.new(className)
	for property, value in properties do
		object[property] = value
	end
	object.Parent = parent
	return object
end

function Theme.corner(parent: Instance, radius: number)
	return Theme.make("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

function Theme.stroke(parent: Instance, color: Color3?, thickness: number?, transparency: number?)
	return Theme.make("UIStroke", {
		Color = color or Theme.colors.line,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

-- UIGradient multiplies BackgroundColor3, so the surface is reset to white and
-- the gradient supplies the real colours. Pass `tint = true` to keep the
-- background colour and use the gradient as a shading multiplier instead.
function Theme.gradient(parent: Instance, top: Color3, bottom: Color3, tint: boolean?)
	if not tint and parent:IsA("GuiObject") then parent.BackgroundColor3 = Color3.new(1, 1, 1) end
	return Theme.make("UIGradient", {
		Color = ColorSequence.new(top, bottom), Rotation = 90,
	}, parent)
end

-- `font` accepts either a Font (FontFace) or a legacy Enum.Font.
function Theme.label(parent: Instance, name: string, text: string, position: UDim2, size: UDim2, textSize: number, color: Color3?, font: any?)
	local label = Theme.make("TextLabel", {
		Name = name, Text = text, Position = position, Size = size,
		BackgroundTransparency = 1, BorderSizePixel = 0,
		TextColor3 = color or Theme.colors.white,
		TextSize = textSize, TextXAlignment = Enum.TextXAlignment.Left,
	}, parent)
	if typeof(font) == "EnumItem" then label.Font = font else label.FontFace = font or Theme.fonts.medium end
	return label
end

function Theme.image(parent: Instance, name: string, image: string, position: UDim2, size: UDim2, properties: { [string]: any }?)
	local item = Theme.make("ImageLabel", {
		Name = name, Image = image, Position = position, Size = size,
		BackgroundTransparency = 1, BorderSizePixel = 0, ScaleType = Enum.ScaleType.Fit,
	}, parent)
	for key, value in properties or {} do item[key] = value end
	return item
end

local function tween(object: Instance, seconds: number, goals, style: Enum.EasingStyle?)
	local t = TweenService:Create(object, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goals)
	t:Play()
	return t
end
Theme.tween = tween

-- Activated supports mouse, touch and selected gamepad controls. Hover is only
-- supplementary feedback; no interaction depends on a mouse being present.
function Theme.buttonFeedback(button: GuiButton, base: Color3, highlight: Color3, options: { scale: UIScale?, stroke: UIStroke?, accent: Color3? }?)
	local scale = options and options.scale
	local stroke = options and options.stroke
	local accent = options and options.accent
	local baseStroke = stroke and stroke.Color
	local baseStrokeT = stroke and stroke.Transparency
	local hovered, pressed = false, false
	local function refresh()
		tween(button, 0.12, { BackgroundColor3 = if hovered or pressed then highlight else base })
		if stroke then
			tween(stroke, 0.12, {
				Color = if (hovered or pressed) and accent then accent else baseStroke,
				Transparency = if hovered or pressed then 0 else baseStrokeT,
			})
		end
		if scale then
			tween(scale, if pressed then 0.06 else 0.14, { Scale = if pressed then 0.95 else (if hovered then 1.03 else 1) },
				if pressed then Enum.EasingStyle.Quad else Enum.EasingStyle.Back)
		end
	end
	button.MouseEnter:Connect(function() hovered = true refresh() end)
	button.MouseLeave:Connect(function() hovered = false pressed = false refresh() end)
	button.SelectionGained:Connect(function() hovered = true refresh() end)
	button.SelectionLost:Connect(function() hovered = false refresh() end)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			pressed = true refresh()
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			pressed = false
			if input.UserInputType == Enum.UserInputType.Touch then hovered = false end
			refresh()
		end
	end)
end

return Theme
