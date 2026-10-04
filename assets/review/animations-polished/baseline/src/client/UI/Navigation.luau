local Theme = require(script.Parent.Theme)
local Icons = require(script.Parent.Icons)
local C = Theme.colors
local Navigation = {}

function Navigation.create(gui: ScreenGui, onSelect)
	local holder = Theme.make("Frame", {
		Name = "Navigation", BackgroundTransparency = 1, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 102),
		Size = UDim2.fromOffset(252, 56),
	}, gui)
	local buttons = {}
	for index, data in { { "SHOP", "shop", C.amber }, { "CURSES", "curses", C.violet }, { "SETTINGS", "settings", C.cyan } } do
		local button = Theme.make("TextButton", {
			Name = data[1], Text = "", AutoButtonColor = false,
			BackgroundColor3 = C.panel, BorderSizePixel = 0,
			Position = UDim2.new((index - 1) / 3, if index == 1 then 0 else 3, 0, 0),
			Size = UDim2.new(1 / 3, -4, 1, 0), Selectable = true,
		}, holder)
		Theme.corner(button, 9)
		Theme.stroke(button, C.line, 1, 0.4)
		local icon = Icons.create(data[2], button, UDim2.new(0.5, -13, 0, 4), UDim2.fromOffset(26, 26), data[3])
		local text = Theme.label(button, "Label", data[1], UDim2.new(0, 0, 1, -21), UDim2.new(1, 0, 0, 17), 9, C.white, Enum.Font.GothamBold)
		text.TextXAlignment = Enum.TextXAlignment.Center
		Theme.buttonFeedback(button, C.panel, C.panelTop)
		button.Activated:Connect(function() onSelect(data[1]) end)
		table.insert(buttons, { icon = icon, text = text })
	end
	return {
		holder = holder,
		fit = function(compact: boolean, width: number, y: number)
			holder.Position = UDim2.new(1, -12, 0, y)
			holder.Size = UDim2.fromOffset(width, if compact then 50 else 56)
			for _, data in buttons do
				data.icon.Position = UDim2.new(0.5, if compact then -12 else -13, 0, 3)
				data.icon.Size = UDim2.fromOffset(if compact then 24 else 26, if compact then 24 else 26)
				data.text.TextSize = 9
			end
		end,
	}
end

return Navigation
