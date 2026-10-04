-- Mortimer's dialog card, the compact task tracker and the Luck chip.
-- Renders ProgressionService state; every action goes through Progression.Request.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VisualAssets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VisualAssets"))
local Config = require(ReplicatedStorage.Shared.ProgressionConfig)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Theme = require(script.Parent.Theme)
local Notify = require(script.Parent.Notify)
local C, F = Theme.colors, Theme.fonts

local Dialog = {}

local function rewardChips(parent, rewards, size)
	for _, c in parent:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end
	local list = {}
	if rewards.souls then table.insert(list, { VisualAssets.Icons.soul, NumberFormat.compact(rewards.souls) }) end
	for id, n in rewards.items or {} do table.insert(list, { VisualAssets.Icons[Config.Items[id] and Config.Items[id].icon or "potion"], "x" .. n .. " " .. (Config.Items[id] and Config.Items[id].name or id) }) end
	for id, n in rewards.tools or {} do table.insert(list, { VisualAssets.ToolIcons[id] or VisualAssets.Icons.tool_pack, "x" .. n }) end
	if rewards.spins then table.insert(list, { VisualAssets.Icons.gamepass, rewards.spins .. " Wheel spin" }) end
	for i, r in list do
		local chip = Theme.make("Frame", {
			Name = "Reward" .. i, LayoutOrder = i, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, size),
			BackgroundColor3 = C.ink, BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 33,
		}, parent)
		Theme.corner(chip, 8)
		Theme.stroke(chip, C.line, 1, 0.4)
		Theme.make("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 10) }, chip)
		Theme.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6) }, chip)
		local icon = Theme.image(chip, "Icon", r[1], UDim2.new(), UDim2.fromOffset(size - 6, size - 6), { ZIndex = 34 })
		icon.LayoutOrder = 1
		local text = Theme.label(chip, "Text", r[2], UDim2.new(), UDim2.fromOffset(0, size), 14, C.white, F.heavy)
		text.AutomaticSize = Enum.AutomaticSize.X
		text.LayoutOrder = 2
		text.ZIndex = 34
	end
end

function Dialog.start(gui: ScreenGui, request: RemoteFunction, onState)
	local player = Players.LocalPlayer
	local state = nil

	---------------------------------------------------------------- card
	local card = Theme.make("Frame", {
		Name = "MortimerDialog", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -110),
		Size = UDim2.fromOffset(620, 230), BackgroundColor3 = C.panel, BorderSizePixel = 0, Visible = false, ZIndex = 30,
	}, gui)
	Theme.corner(card, 18)
	Theme.gradient(card, Color3.fromRGB(52, 38, 78), Color3.fromRGB(14, 11, 26))
	Theme.stroke(card, C.amber:Lerp(C.line, 0.5), 2, 0.15)
	local scale = Theme.make("UIScale", { Scale = 1 }, card)
	-- Portrait: a live ViewportFrame of Mortimer's head.
	local portrait = Theme.make("ViewportFrame", {
		Name = "Portrait", Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(110, 130),
		BackgroundColor3 = C.ink, BackgroundTransparency = 0.1, Ambient = Color3.fromRGB(150, 140, 170),
		LightColor = Color3.fromRGB(200, 255, 240), ZIndex = 31,
	}, card)
	Theme.corner(portrait, 14)
	Theme.stroke(portrait, C.amber, 1.5, 0.35)
	local name = Theme.label(card, "Name", string.upper(Config.NpcName), UDim2.fromOffset(138, 12), UDim2.new(1, -200, 0, 30), 28, Color3.fromRGB(255, 226, 170), F.display)
	name.ZIndex = 31
	local title = Theme.label(card, "Title", Config.NpcTitle, UDim2.fromOffset(139, 40), UDim2.new(1, -200, 0, 16), 13, C.muted, F.bold)
	title.ZIndex = 31
	local line = Theme.label(card, "Line", "", UDim2.fromOffset(139, 60), UDim2.new(1, -160, 0, 40), 15, C.white, F.medium)
	line.TextWrapped = true
	line.TextYAlignment = Enum.TextYAlignment.Top
	line.ZIndex = 31
	local missionTitle = Theme.label(card, "MissionTitle", "", UDim2.fromOffset(139, 102), UDim2.new(1, -160, 0, 22), 18, C.amber, F.heavy)
	missionTitle.ZIndex = 31
	local objective = Theme.label(card, "Objective", "", UDim2.fromOffset(139, 126), UDim2.new(1, -250, 0, 18), 14, C.muted, F.bold)
	objective.ZIndex = 31
	local count = Theme.label(card, "Count", "", UDim2.new(1, -110, 0, 126), UDim2.fromOffset(96, 18), 14, C.white, F.heavy)
	count.TextXAlignment = Enum.TextXAlignment.Right
	count.ZIndex = 31
	local barBack = Theme.make("Frame", { Name = "Progress", Position = UDim2.fromOffset(139, 148), Size = UDim2.new(1, -153, 0, 8), BackgroundColor3 = C.ink, BorderSizePixel = 0, ZIndex = 31 }, card)
	Theme.corner(barBack, 4)
	local barFill = Theme.make("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.soulGreen, BorderSizePixel = 0, ZIndex = 32 }, barBack)
	Theme.corner(barFill, 4)
	local rewardsRow = Theme.make("Frame", { Name = "Rewards", Position = UDim2.fromOffset(14, 172), Size = UDim2.new(1, -220, 0, 44), BackgroundTransparency = 1, ZIndex = 32 }, card)
	Theme.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, rewardsRow)
	local rewardsLabel = Theme.label(card, "RewardsLabel", "REWARD", UDim2.fromOffset(16, 160), UDim2.fromOffset(80, 12), 10, C.subtle, F.heavy)
	rewardsLabel.ZIndex = 31
	local action = Theme.make("TextButton", {
		Name = "Action", Text = "ACCEPT", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -14, 1, -14), Size = UDim2.fromOffset(180, 48), BackgroundColor3 = C.amber,
		FontFace = F.heavy, TextSize = 18, TextColor3 = C.ink, BorderSizePixel = 0, Selectable = true, ZIndex = 33,
	}, card)
	Theme.corner(action, 12)
	local actionStroke = Theme.stroke(action, C.white, 1.5, 0.5)
	Theme.buttonFeedback(action, C.amber, Color3.fromRGB(255, 214, 140), { scale = Theme.make("UIScale", { Scale = 1 }, action), stroke = actionStroke, accent = C.white })
	local close = Theme.make("TextButton", {
		Name = "Close", Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.fromOffset(40, 40), BackgroundColor3 = C.card, BorderSizePixel = 0, ZIndex = 33,
	}, card)
	Theme.corner(close, 10)
	for i, angle in { 45, -45 } do
		local bar = Theme.make("Frame", { Name = "X" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(18, 3), Rotation = angle, BackgroundColor3 = C.white, BorderSizePixel = 0, ZIndex = 34 }, close)
		Theme.corner(bar, 2)
	end
	local mode = "mission"
	local function show(v)
		-- Above the sanctuary launcher (DisplayOrder 30) while open.
		gui.DisplayOrder = if v then 36 else 12
		if v and not card.Visible then
			card.Visible = true
			scale.Scale = 0.92
			Theme.tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
		elseif not v then
			card.Visible = false
		end
	end
	close.Activated:Connect(function() show(false) end)

	-- Portrait camera: clone Mortimer's visible parts once.
	task.spawn(function()
		local map = workspace:WaitForChild("StealACurseMap", 60)
		local npc = map and map:WaitForChild("MortimerTheGravekeeper", 30)
		local model = npc and npc:FindFirstChild("Mortimer")
		if not model then return end
		local copy = model:Clone()
		for _, d in copy:GetDescendants() do if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ProximityPrompt") or d:IsA("PointLight") then d:Destroy() end end
		copy.Parent = portrait
		local head = copy:FindFirstChild("Head")
		local cam = Instance.new("Camera")
		cam.FieldOfView = 26
		if head then cam.CFrame = CFrame.lookAt((head.CFrame * CFrame.new(0.4, 0.3, -6)).Position, head.Position + Vector3.new(0, 0.2, 0)) end
		cam.Parent = portrait
		portrait.CurrentCamera = cam
	end)

	local function render()
		local s = state
		if not s then return end
		local m = if mode == "event" then s.event else s.mission
		if not m then
			line.Text = "Rest a while, keeper. I will have new work for you soon."
			missionTitle.Text = "All tasks done"
			objective.Text = ""
			count.Text = ""
			barFill.Size = UDim2.fromScale(1, 1)
			rewardChips(rewardsRow, {}, 32)
			action.Text = "CLOSE"
			return
		end
		line.Text = "“" .. m.line .. "”"
		missionTitle.Text = if mode == "event" then "EVENT · " .. m.title else string.format("%s  ·  %d/%d", m.title, m.index, m.total)
		objective.Text = m.objective
		count.Text = string.format("%s / %s", NumberFormat.compact(m.progress), NumberFormat.compact(m.target))
		Theme.tween(barFill, 0.3, { Size = UDim2.fromScale(math.clamp(m.progress / math.max(m.target, 1), 0, 1), 1) })
		rewardChips(rewardsRow, m.rewards, 32)
		local accepted = mode == "event" or m.accepted
		action.Text = if m.complete then "CLAIM" elseif accepted then "ON IT" else "ACCEPT"
		action.BackgroundColor3 = if m.complete then C.soulGreen elseif accepted then C.card else C.amber
		action.TextColor3 = if accepted and not m.complete then C.muted else C.ink
	end

	local function call(a, v)
		local ok, answer = pcall(function() return request:InvokeServer(a, v) end)
		if not ok or typeof(answer) ~= "table" then return nil end
		if answer.state then state = answer.state render() if onState then onState(state) end end
		return answer
	end
	action.Activated:Connect(function()
		local m = state and (if mode == "event" then state.event else state.mission)
		if not m then show(false) return end
		if m.complete then
			local answer = call("claim", if mode == "event" then "event" else nil)
			if answer and answer.ok then
				Dialog.celebrate(answer.message)
				show(false)
			end
		elseif mode == "mission" and not m.accepted then
			call("accept")
			show(false)
		else
			show(false)
		end
	end)

	---------------------------------------------------------------- tracker
	local tracker = Theme.make("Frame", {
		Name = "TaskTracker", Position = UDim2.fromOffset(14, 64), Size = UDim2.fromOffset(250, 62),
		BackgroundColor3 = C.panel, BackgroundTransparency = 0.12, BorderSizePixel = 0, Visible = false, ZIndex = 8,
	}, gui)
	Theme.corner(tracker, 12)
	Theme.stroke(tracker, C.line, 1.2, 0.3)
	local tIcon = Theme.image(tracker, "Icon", VisualAssets.Icons.curses, UDim2.fromOffset(8, 10), UDim2.fromOffset(40, 40), { ZIndex = 9 })
	local tTitle = Theme.label(tracker, "Title", "", UDim2.fromOffset(56, 6), UDim2.new(1, -64, 0, 18), 14, C.amber, F.heavy)
	tTitle.ZIndex = 9
	tTitle.TextTruncate = Enum.TextTruncate.AtEnd
	local tObjective = Theme.label(tracker, "Objective", "", UDim2.fromOffset(56, 24), UDim2.new(1, -64, 0, 16), 12, C.muted, F.bold)
	tObjective.ZIndex = 9
	tObjective.TextTruncate = Enum.TextTruncate.AtEnd
	local tBar = Theme.make("Frame", { Position = UDim2.fromOffset(56, 46), Size = UDim2.new(1, -66, 0, 6), BackgroundColor3 = C.ink, BorderSizePixel = 0, ZIndex = 9 }, tracker)
	Theme.corner(tBar, 3)
	local tFill = Theme.make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.soulGreen, BorderSizePixel = 0, ZIndex = 10 }, tBar)
	Theme.corner(tFill, 3)
	local trackerPulse = Theme.make("UIScale", { Scale = 1 }, tracker)

	-- Luck chip: potions in inventory + current server luck.
	local luck = Theme.make("Frame", {
		Name = "LuckChip", Position = UDim2.fromOffset(14, 132), Size = UDim2.fromOffset(250, 44),
		BackgroundColor3 = C.panel, BackgroundTransparency = 0.12, BorderSizePixel = 0, Visible = false, ZIndex = 8,
	}, gui)
	Theme.corner(luck, 12)
	local luckStroke = Theme.stroke(luck, C.soulGreen, 1.2, 0.5)
	Theme.image(luck, "Icon", VisualAssets.Icons.potion, UDim2.fromOffset(6, 4), UDim2.fromOffset(36, 36), { ZIndex = 9 })
	local luckText = Theme.label(luck, "Text", "", UDim2.fromOffset(46, 4), UDim2.new(1, -140, 0, 18), 14, C.white, F.heavy)
	luckText.ZIndex = 9
	local luckSub = Theme.label(luck, "Sub", "", UDim2.fromOffset(46, 22), UDim2.new(1, -140, 0, 16), 12, C.soulGreen, F.bold)
	luckSub.ZIndex = 9
	local drink = Theme.make("TextButton", {
		Name = "Drink", Text = "DRINK", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.fromOffset(84, 34), BackgroundColor3 = C.soulGreen, TextColor3 = C.ink, FontFace = F.heavy, TextSize = 14, BorderSizePixel = 0, ZIndex = 10,
	}, luck)
	Theme.corner(drink, 9)
	Theme.buttonFeedback(drink, C.soulGreen, Color3.fromRGB(190, 255, 220), { scale = Theme.make("UIScale", { Scale = 1 }, drink) })
	drink.Activated:Connect(function()
		local answer = call("drink", "luck_potion")
		if answer then Dialog.toast(answer.message, answer.ok) end
	end)

	---------------------------------------------------------------- toast / celebration
	function Dialog.toast(text, good)
		Notify.push(text, if good == false then "bad" elseif good == true then "good" else "info")
	end
	local burst = Theme.label(gui, "Celebration", "TASK COMPLETE", UDim2.fromScale(0.5, 0.32), UDim2.fromOffset(600, 60), 46, Color3.fromRGB(255, 226, 170), F.display)
	burst.AnchorPoint = Vector2.new(0.5, 0.5)
	burst.TextXAlignment = Enum.TextXAlignment.Center
	burst.Visible = false
	burst.ZIndex = 45
	Theme.make("UIStroke", { Color = Color3.fromRGB(30, 14, 4), Thickness = 2.5 }, burst)
	local burstScale = Theme.make("UIScale", { Scale = 1 }, burst)
	local burstGlow = Theme.image(gui, "CelebrationGlow", VisualAssets.Textures.glow_soft, UDim2.fromScale(0.5, 0.32), UDim2.fromOffset(520, 220), {
		AnchorPoint = Vector2.new(0.5, 0.5), ImageColor3 = C.amber, ImageTransparency = 1, ZIndex = 44,
	})
	function Dialog.celebrate(message)
		burst.Visible = true
		burst.TextTransparency = 0
		burstScale.Scale = 1.4
		Theme.tween(burstScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
		burstGlow.ImageTransparency = 0.2
		Theme.tween(burstGlow, 1.2, { ImageTransparency = 1 })
		Dialog.toast(message, true)
		task.delay(1.8, function()
			Theme.tween(burst, 0.4, { TextTransparency = 1 })
			task.delay(0.45, function() burst.Visible = false end)
		end)
	end

	---------------------------------------------------------------- state
	local lastProgress = nil
	function Dialog.setState(s)
		state = s
		local m = s.mission
		local e = s.event
		local shown = (m and m.accepted) and m or e
		tracker.Visible = shown ~= nil
		if shown then
			tTitle.Text = (if shown == e then "EVENT · " else "") .. shown.title .. (if shown.complete then "  ✓" else "")
			tObjective.Text = if shown.complete then "Return to Mortimer to claim" else string.format("%s  %s/%s", shown.objective, NumberFormat.compact(shown.progress), NumberFormat.compact(shown.target))
			tFill.Size = UDim2.fromScale(math.clamp(shown.progress / math.max(shown.target, 1), 0, 1), 1)
			tFill.BackgroundColor3 = if shown.complete then C.amber else C.soulGreen
			if lastProgress and shown.progress > lastProgress then
				trackerPulse.Scale = 1.05
				Theme.tween(trackerPulse, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
			end
			lastProgress = shown.progress
		end
		local potions = s.items and s.items.luck_potion or 0
		local mult = s.luck and s.luck.multiplier or 1
		luck.Visible = potions > 0 or mult > 1.001
		luckText.Text = if potions > 0 then string.format("Luck Potion x%d", potions) else "Server Luck"
		drink.Visible = potions > 0
		luckStroke.Transparency = if mult > 1.001 then 0 else 0.5
		if card.Visible then render() end
	end
	RunService.Heartbeat:Connect(function()
		if not luck.Visible or not state then return end
		local mult = ReplicatedStorage:GetAttribute("ServerLuck") or 1
		local ends = ReplicatedStorage:GetAttribute("ServerLuckEndsAt") or 0
		local left = math.max(0, ends - workspace:GetServerTimeNow())
		luckSub.Text = if mult > 1.001 then string.format("Server Luck x%.1f  %d:%02d", mult, left // 60, left % 60) else "Drink to boost rare spawns"
	end)

	function Dialog.open(s, which)
		if s then state = s end
		mode = which or (if state and state.event and state.event.complete then "event" else "mission")
		render()
		show(true)
	end
	function Dialog.isOpen() return card.Visible end

	local function fit()
		local size = gui.AbsoluteSize
		local narrow = size.X < 700 or size.Y < 420
		card.Size = UDim2.fromOffset(math.min(620, size.X - 24), 230)
		portrait.Visible = not narrow
		local x = if narrow then 16 else 139
		for _, l in { name, title, line, missionTitle, objective } do l.Position = UDim2.fromOffset(x, l.Position.Y.Offset) end
		barBack.Position = UDim2.fromOffset(x, 148)
		barBack.Size = UDim2.new(1, -(x + 14), 0, 8)
		local touch = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
		card.Position = UDim2.new(0.5, 0, 1, if touch then -96 else -110)
		tracker.Position = UDim2.fromOffset(14, if size.Y < 420 then 52 else 64)
		luck.Position = UDim2.fromOffset(14, tracker.Position.Y.Offset + 68)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()
	return Dialog
end

return Dialog
