-- Short, skippable camera moments built from reusable steps:
--   shot(fromCFrame, toCFrame, seconds) | focus(target, offset, seconds)
--   caption(text, seconds) | wait(seconds)
-- Always restores the player's camera and controls, including on skip,
-- death or character respawn. Never longer than ~8 s.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Theme = require(script.Parent.UI.Theme)
local C, F = Theme.colors, Theme.fonts

local Cinematics = {}
local playing = false

local function letterbox(gui)
	local bars = {}
	for i, anchor in { 0, 1 } do
		local bar = Theme.make("Frame", {
			Name = "Bar" .. i, AnchorPoint = Vector2.new(0, anchor), Position = UDim2.fromScale(0, anchor),
			Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 60,
		}, gui)
		bars[i] = bar
		Theme.tween(bar, 0.35, { Size = UDim2.new(1, 0, 0.09, 0) })
	end
	return bars
end

function Cinematics.play(steps, options)
	if playing then return false end
	local camera = workspace.CurrentCamera
	local player = Players.LocalPlayer
	if not camera then return false end
	playing = true
	local cancelled = false
	local gui = Theme.make("ScreenGui", { Name = "Cinematic", DisplayOrder = 80, IgnoreGuiInset = true, ResetOnSpawn = false }, player:WaitForChild("PlayerGui"))
	local bars = letterbox(gui)
	local caption = Theme.label(gui, "Caption", "", UDim2.new(0.5, 0, 0.8, 0), UDim2.fromOffset(700, 44), 30, Color3.fromRGB(255, 226, 170), F.display)
	caption.AnchorPoint = Vector2.new(0.5, 0.5)
	caption.TextXAlignment = Enum.TextXAlignment.Center
	caption.TextTransparency = 1
	caption.ZIndex = 61
	Theme.make("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 2, Transparency = 0.2 }, caption)
	local skip = Theme.make("TextButton", {
		Name = "Skip", Text = "SKIP  ›", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -18),
		Size = UDim2.fromOffset(96, 34), BackgroundColor3 = C.ink, BackgroundTransparency = 0.3, TextColor3 = C.muted,
		FontFace = F.heavy, TextSize = 14, ZIndex = 62,
	}, gui)
	Theme.corner(skip, 10)
	local savedType, savedSubject, savedFov = camera.CameraType, camera.CameraSubject, camera.FieldOfView
	-- Hide gameplay HUDs for the shot; restore exactly what was enabled.
	local hidden = {}
	for _, g in player.PlayerGui:GetChildren() do
		if g:IsA("ScreenGui") and g ~= gui and g.Enabled and g.Name ~= "Chat" and g.Name ~= "BubbleChat" then
			g.Enabled = false
			table.insert(hidden, g)
		end
	end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local controls
	pcall(function() controls = require(player.PlayerScripts:WaitForChild("PlayerModule", 2)):GetControls() end)
	if controls then controls:Disable() end
	camera.CameraType = Enum.CameraType.Scriptable
	local function cancel() cancelled = true end
	skip.Activated:Connect(cancel)
	local inputConn = UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then cancel() end
	end)
	local diedConn = humanoid and humanoid.Died:Connect(cancel)
	local charConn = player.CharacterAdded:Connect(cancel)

	local function hold(seconds)
		local t = 0
		while t < seconds and not cancelled do t += RunService.RenderStepped:Wait() end
	end
	for _, step in steps do
		if cancelled then break end
		if step.kind == "shot" then
			camera.CFrame = step.from
			local tween = TweenService:Create(camera, TweenInfo.new(step.seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = step.to })
			tween:Play()
			hold(step.seconds)
			tween:Cancel()
		elseif step.kind == "caption" then
			caption.Text = step.text
			Theme.tween(caption, 0.35, { TextTransparency = 0 })
			if step.seconds then task.delay(step.seconds, function() Theme.tween(caption, 0.4, { TextTransparency = 1 }) end) end
		elseif step.kind == "call" then
			pcall(step.fn)
		elseif step.kind == "wait" then
			hold(step.seconds)
		end
	end
	-- Restore smoothly from wherever the camera is.
	for _, bar in bars do Theme.tween(bar, 0.3, { Size = UDim2.new(1, 0, 0, 0) }) end
	Theme.tween(caption, 0.2, { TextTransparency = 1 })
	camera.CameraType = savedType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or savedType
	camera.CameraSubject = if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then player.Character:FindFirstChildOfClass("Humanoid") else savedSubject
	camera.FieldOfView = savedFov
	for _, g in hidden do if g.Parent then g.Enabled = true end end
	if controls then controls:Enable() end
	inputConn:Disconnect()
	if diedConn then diedConn:Disconnect() end
	charConn:Disconnect()
	task.delay(0.35, function() gui:Destroy() end)
	playing = false
	if options and options.onDone then task.spawn(options.onDone, cancelled) end
	return true
end

function Cinematics.isPlaying(): boolean return playing end

return Cinematics
