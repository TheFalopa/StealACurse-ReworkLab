-- Original native-UI palette. No uploaded images or third-party icon packs.
local TweenService = game:GetService("TweenService")

local Theme = {}
Theme.colors = {
	ink = Color3.fromRGB(15, 19, 34),
	panel = Color3.fromRGB(24, 28, 47),
	panelTop = Color3.fromRGB(43, 39, 65),
	card = Color3.fromRGB(34, 37, 59),
	line = Color3.fromRGB(111, 99, 150),
	violet = Color3.fromRGB(173, 144, 221),
	cyan = Color3.fromRGB(136, 235, 224),
	amber = Color3.fromRGB(244, 184, 105),
	white = Color3.fromRGB(247, 245, 255),
	muted = Color3.fromRGB(186, 190, 211),
	subtle = Color3.fromRGB(134, 141, 169),
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

function Theme.gradient(parent: Instance, top: Color3, bottom: Color3)
	return Theme.make("UIGradient", {
		Color = ColorSequence.new(top, bottom), Rotation = 90,
	}, parent)
end

function Theme.label(parent: Instance, name: string, text: string, position: UDim2, size: UDim2, textSize: number, color: Color3?, font: Enum.Font?)
	return Theme.make("TextLabel", {
		Name = name, Text = text, Position = position, Size = size,
		BackgroundTransparency = 1, BorderSizePixel = 0,
		Font = font or Enum.Font.GothamMedium,
		TextColor3 = color or Theme.colors.white,
		TextSize = textSize, TextXAlignment = Enum.TextXAlignment.Left,
	}, parent)
end

-- Activated supports mouse, touch and selected gamepad controls. Hover is only
-- supplementary feedback; no interaction depends on a mouse being present.
function Theme.buttonFeedback(button: TextButton, base: Color3, highlight: Color3)
	local currentTween: Tween? = nil
	local function tint(color: Color3)
		if currentTween then currentTween:Cancel() end
		currentTween = TweenService:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = color })
		currentTween:Play()
	end
	button.MouseEnter:Connect(function() tint(highlight) end)
	button.MouseLeave:Connect(function() tint(base) end)
	button.SelectionGained:Connect(function() tint(highlight) end)
	button.SelectionLost:Connect(function() tint(base) end)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			tint(highlight)
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			tint(base)
		end
	end)
end

return Theme
