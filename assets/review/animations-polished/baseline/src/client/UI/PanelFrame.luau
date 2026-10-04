local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent.Theme)
local Icons = require(script.Parent.Icons)
local C = Theme.colors
local PanelFrame = {}

-- Shared modal chrome, relative to the core/device-safe ScreenGui bounds.
function PanelFrame.create(gui: ScreenGui, overlayName: string, panelName: string, title: string, subtitle: string, iconKind: string, accent: Color3, onClose)
	local overlay = Theme.make("Frame", {
		Name = overlayName, Visible = false, BackgroundTransparency = 1,
		BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 20,
	}, gui)
	local backdrop = Theme.make("TextButton", {
		Name = "Backdrop", Text = "", AutoButtonColor = false,
		BackgroundColor3 = C.ink, BackgroundTransparency = 0.28,
		BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
		Active = true, Modal = true, Selectable = false, ZIndex = 20,
	}, overlay)
	backdrop.Activated:Connect(onClose)
	local panel = Theme.make("Frame", {
		Name = panelName, AnchorPoint = Vector2.new(0.5, 0.5), Active = true,
		BackgroundColor3 = C.panel, BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(900, 600), ZIndex = 21,
	}, overlay)
	Theme.corner(panel, 16)
	Theme.gradient(panel, C.panelTop, C.panel)
	Theme.stroke(panel, accent, 1.5, 0.2)
	local panelScale = Theme.make("UIScale", { Scale = 1 }, panel)
	local crest = Icons.create(iconKind, panel, UDim2.fromOffset(19, 15), UDim2.fromOffset(45, 45), accent)
	crest.ZIndex = 22
	local heading = Theme.label(panel, "Heading", title, UDim2.fromOffset(75, 17), UDim2.new(1, -138, 0, 25), 23, C.white, Enum.Font.GothamBlack)
	heading.ZIndex = 22
	local subheading = Theme.label(panel, "Subtitle", subtitle, UDim2.fromOffset(76, 45), UDim2.new(1, -102, 0, 17), 11, C.muted)
	subheading.ZIndex = 22
	subheading.TextTruncate = Enum.TextTruncate.AtEnd
	local close = Theme.make("TextButton", {
		Name = "CloseButton", Text = "", AutoButtonColor = false,
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14),
		Size = UDim2.fromOffset(44, 44), BackgroundColor3 = C.ink,
		BorderSizePixel = 0, Selectable = true, ZIndex = 23,
	}, panel)
	Theme.corner(close, 10)
	Theme.stroke(close, C.line, 1, 0.3)
	for index, angle in { 45, -45 } do
		Theme.make("Frame", {
			Name = "CloseStroke" .. index, BackgroundColor3 = C.white, BorderSizePixel = 0,
			Position = UDim2.fromOffset(12, 20), Size = UDim2.fromOffset(20, 3), Rotation = angle, ZIndex = 24,
		}, close)
	end
	Theme.buttonFeedback(close, C.ink, C.card)
	close.Activated:Connect(onClose)
	local footer = Theme.label(panel, "Footer", "", UDim2.new(0, 20, 1, -35), UDim2.new(1, -40, 0, 25), 11, C.muted)
	footer.TextWrapped = true
	footer.ZIndex = 22

	local controller = { overlay = overlay, panel = panel, footer = footer, compact = false }
	function controller.fit(safeSize: Vector2)
		local short = safeSize.Y < 430
		local width = math.max(1, math.min(940, safeSize.X - 24))
		local height = math.max(1, math.min(620, safeSize.Y - 24))
		controller.compact = short
		panel.Size = UDim2.fromOffset(width, height)
		heading.Position = UDim2.fromOffset(if short then 60 else (if width < 500 then 64 else 75), if short then 12 else 17)
		heading.TextSize = if width < 500 then 18 else (if short then 20 else 23)
		heading.Size = UDim2.new(1, -(if short then 124 else (if width < 500 then 129 else 138)), 0, 25)
		crest.Position = UDim2.fromOffset(16, if short then 11 else 15)
		local crestSize = if short then 32 else (if width < 500 then 36 else 45)
		crest.Size = UDim2.fromOffset(crestSize, crestSize)
		-- On short phone landscape, retain the heading/close target and reclaim
		-- the redundant subtitle row for real, readable store content.
		subheading.Visible = not short
		subheading.Position = UDim2.fromOffset(20, if short then 45 else 67)
		subheading.Size = UDim2.new(1, -40, 0, 17)
		footer.TextSize = if width < 500 then 10 else 11
		return width, height, short
	end
	function controller.show(visible: boolean)
		overlay.Visible = visible
		if visible then
			panelScale.Scale = 0.985
			TweenService:Create(panelScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		end
	end
	return controller
end

return PanelFrame
