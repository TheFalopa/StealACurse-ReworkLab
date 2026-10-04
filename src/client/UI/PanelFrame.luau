local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Theme = require(script.Parent.Theme)
local Icons = require(script.Parent.Icons)
local C, F = Theme.colors, Theme.fonts
local PanelFrame = {}

-- Shared modal chrome, relative to the core/device-safe ScreenGui bounds.
-- On touch devices the panel stays clear of the thumbstick and jump button,
-- and the dim layer does not capture input, so movement keeps working.
function PanelFrame.create(gui: ScreenGui, overlayName: string, panelName: string, title: string, subtitle: string, iconKind: string, accent: Color3, onClose)
	local overlay = Theme.make("Frame", {
		Name = overlayName, Visible = false, BackgroundTransparency = 1,
		BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 20,
	}, gui)
	local dim = Theme.make("Frame", {
		Name = "Dim", BackgroundColor3 = C.ink, BackgroundTransparency = 1,
		BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Active = false, ZIndex = 20,
	}, overlay)
	local backdrop = Theme.make("TextButton", {
		Name = "Backdrop", Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
		BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
		Active = true, Modal = true, Selectable = false, ZIndex = 20,
	}, overlay)
	backdrop.Activated:Connect(onClose)
	local panel = Theme.make("Frame", {
		Name = panelName, AnchorPoint = Vector2.new(0.5, 0.5), Active = true,
		BackgroundColor3 = C.panel, BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(880, 600), ZIndex = 21,
	}, overlay)
	Theme.corner(panel, 18)
	Theme.gradient(panel, C.panelTop, C.ink)
	Theme.stroke(panel, accent:Lerp(C.line, 0.45), 2, 0.1)
	local panelScale = Theme.make("UIScale", { Scale = 1 }, panel)
	local header = Theme.make("Frame", {
		Name = "Header", BackgroundColor3 = accent, BackgroundTransparency = 0.86,
		BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 72), ZIndex = 21,
	}, panel)
	Theme.corner(header, 18)
	Theme.make("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.7, 0.85), NumberSequenceKeypoint.new(1, 1) }),
	}, header)
	local crest = Icons.create(iconKind, panel, UDim2.fromOffset(18, 12), UDim2.fromOffset(48, 48), accent)
	crest.ZIndex = 22
	local heading = Theme.label(panel, "Heading", title, UDim2.fromOffset(76, 12), UDim2.new(1, -140, 0, 32), 30, C.white, F.display)
	heading.ZIndex = 22
	heading.TextTruncate = Enum.TextTruncate.AtEnd
	local subheading = Theme.label(panel, "Subtitle", subtitle, UDim2.fromOffset(77, 44), UDim2.new(1, -140, 0, 16), 13, C.muted, F.bold)
	subheading.ZIndex = 22
	subheading.TextTruncate = Enum.TextTruncate.AtEnd
	local close = Theme.make("TextButton", {
		Name = "CloseButton", Text = "", AutoButtonColor = false,
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14),
		Size = UDim2.fromOffset(44, 44), BackgroundColor3 = C.card,
		BorderSizePixel = 0, Selectable = true, ZIndex = 23,
	}, panel)
	Theme.corner(close, 12)
	local closeStroke = Theme.stroke(close, C.line, 1.4, 0.2)
	local closeScale = Theme.make("UIScale", { Scale = 1 }, close)
	for index, angle in { 45, -45 } do
		local bar = Theme.make("Frame", {
			Name = "CloseStroke" .. index, AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = C.white, BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(20, 3), Rotation = angle, ZIndex = 24,
		}, close)
		Theme.corner(bar, 2)
	end
	Theme.buttonFeedback(close, C.card, Color3.fromRGB(120, 40, 70), { scale = closeScale, stroke = closeStroke, accent = Color3.fromRGB(255, 120, 150) })
	close.Activated:Connect(onClose)
	local footer = Theme.label(panel, "Footer", "", UDim2.new(0, 20, 1, -32), UDim2.new(1, -40, 0, 22), 12, C.subtle, F.medium)
	footer.TextWrapped = true
	footer.ZIndex = 22

	local controller = { overlay = overlay, panel = panel, footer = footer, compact = false, heading = heading }
	function controller.fit(safeSize: Vector2)
		local touch = UserInputService.TouchEnabled
		local landscape = safeSize.X > safeSize.Y
		local short = safeSize.Y < 430
		local maxWidth, maxHeight, centerY = 900, 620, 0.5
		if touch and landscape then
			-- Leave both lower corners (thumbstick / jump) uncovered.
			maxWidth = safeSize.X - 2 * math.min(150, safeSize.X * 0.17)
		elseif touch then
			maxHeight = safeSize.Y - 230
			centerY = (maxHeight / 2 + 12) / safeSize.Y
		end
		local width = math.max(1, math.min(maxWidth, safeSize.X - 24))
		local height = math.max(1, math.min(maxHeight, safeSize.Y - 24))
		controller.compact = short
		panel.Size = UDim2.fromOffset(width, height)
		panel.Position = UDim2.fromScale(0.5, centerY)
		backdrop.Visible = not touch
		local narrow = width < 500
		header.Size = UDim2.new(1, 0, 0, if short then 56 else 72)
		local crestSize = if short then 34 else (if narrow then 40 else 48)
		crest.Position = UDim2.fromOffset(14, if short then 11 else 12)
		crest.Size = UDim2.fromOffset(crestSize, crestSize)
		heading.Position = UDim2.fromOffset(crestSize + 24, if short then 10 else 12)
		heading.Size = UDim2.new(1, -(crestSize + 90), 0, if short then 28 else 32)
		heading.TextSize = if short or narrow then 24 else 30
		-- On short phone landscape the subtitle row is reclaimed for content.
		subheading.Visible = not short
		subheading.Position = UDim2.fromOffset(crestSize + 25, 44)
		subheading.Size = UDim2.new(1, -(crestSize + 90), 0, 16)
		close.Position = UDim2.new(1, -12, 0, if short then 6 else 14)
		footer.TextSize = if narrow then 11 else 12
		return width, height, short
	end
	local showGeneration = 0
	function controller.show(visible: boolean)
		showGeneration += 1
		local generation = showGeneration
		if visible then
			overlay.Visible = true
			panelScale.Scale = 0.94
			dim.BackgroundTransparency = 1
			TweenService:Create(panelScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			Theme.tween(dim, 0.2, { BackgroundTransparency = if UserInputService.TouchEnabled then 0.6 else 0.4 })
		elseif overlay.Visible then
			Theme.tween(panelScale, 0.1, { Scale = 0.96 })
			Theme.tween(dim, 0.1, { BackgroundTransparency = 1 })
			task.delay(0.1, function()
				if generation == showGeneration then overlay.Visible = false end
			end)
		end
	end
	return controller
end

return PanelFrame
