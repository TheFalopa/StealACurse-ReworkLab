-- Tool bar + Gravekeeper's Bench. Talks only to ToolsFoundation.Request
-- (snapshot/buy/equip/hold/use/trial); the server owns every rule.
--   Quick slots: bottom-centre, keys 1/2/3 (gamepad DPad), tap on touch.
--   Use: click / tap the USE button / R2. Bench: opened by the bench prompt or B.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")
local Run = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local C = require(RS.Shared.ToolCatalog)
local VisualAssets = require(RS.Shared.VisualAssets)
local Theme = require(script.Parent.UI.Theme)
local PanelFrame = require(script.Parent.UI.PanelFrame)
local Notify = require(script.Parent.UI.Notify)
local CO, F = Theme.colors, Theme.fonts

local ROLE_COLOR = {
	MELEE = CO.amber, ESCAPE = CO.soulGreen, THROW = Color3.fromRGB(255, 140, 90), TRICK = CO.violet,
	UTILITY = CO.cyan, DEFENSE = Color3.fromRGB(240, 226, 190), WARD = CO.cyan, PULL = CO.magenta,
}

local Input = {}
function Input.start()
	local player = Players.LocalPlayer
	local remote = RS:WaitForChild("ToolsFoundation")
	local request = remote:WaitForChild("Request")
	local gui = Theme.make("ScreenGui", {
		Name = "ToolsFoundationUI", ResetOnSpawn = false, DisplayOrder = 12,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, player:WaitForChild("PlayerGui"))
	local safe = Theme.make("Frame", { Name = "SafeArea", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, gui)

	local data, busy = nil, false

	-- Server answers go to the shared notice toast (UI.Notify).
	local function say(text: string, good: boolean?)
		Notify.push(text, if good == false then "bad" elseif good == true then "good" else "info")
	end

	---------------------------------------------------------------- bench
	local bench = PanelFrame.create(gui, "BenchOverlay", "BenchPanel", "Gravekeeper's Bench", "Equip up to three tools  ·  1 / 2 / 3 to hold", "tool_pack", CO.amber, function() end)
	local benchOpen = false
	local function showBench(v)
		benchOpen = v
		bench.show(v)
		local items = bench.panel:FindFirstChild("Items")
		if v and items then items.CanvasPosition = Vector2.zero end
		gui.DisplayOrder = if v then 36 else 12
	end
	bench.overlay.Backdrop.Activated:Connect(function() showBench(false) end)
	bench.panel.CloseButton.Activated:Connect(function() showBench(false) end)
	local grid = Theme.make("ScrollingFrame", {
		Name = "Items", Active = true, ClipsDescendants = true, BackgroundTransparency = 1, BorderSizePixel = 0,
		Position = UDim2.fromOffset(16, 84), Size = UDim2.new(1, -32, 1, -120), CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4, ScrollBarImageColor3 = CO.violet,
		ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 22,
	}, bench.panel)
	Theme.make("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingTop = UDim.new(0, 2) }, grid)
	local layout = Theme.make("UIGridLayout", { CellPadding = UDim2.fromOffset(10, 10), CellSize = UDim2.fromOffset(200, 150), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
	local cards = {}

	local function call(action, id, value)
		if busy then return nil end
		busy = true
		local ok, answer = pcall(function() return request:InvokeServer(action, id, value) end)
		busy = false
		if not ok or typeof(answer) ~= "table" then say("Could not reach the server. Try again.", false) return nil end
		if answer.data then Input.update(answer.data) end
		if answer.message and answer.message ~= "" and answer.message ~= "Used." then say(answer.message, answer.ok) end
		return answer
	end

	for index, id in C.Order do
		local d = C.Items[id]
		local accent = ROLE_COLOR[d.role] or CO.violet
		local card = Theme.make("Frame", { Name = id, LayoutOrder = index, BackgroundColor3 = CO.card, BorderSizePixel = 0, ZIndex = 23 }, grid)
		Theme.corner(card, 14)
		Theme.gradient(card, accent:Lerp(CO.card, 0.78), CO.ink)
		local stroke = Theme.stroke(card, accent, 1.2, 0.6)
		local icon = Theme.image(card, "Icon", VisualAssets.ToolIcons[id], UDim2.fromOffset(10, 10), UDim2.fromOffset(56, 56), { ZIndex = 24 })
		local role = Theme.label(card, "Role", d.role, UDim2.fromOffset(74, 12), UDim2.new(1, -84, 0, 14), 11, accent, F.heavy)
		role.ZIndex = 24
		local name = Theme.label(card, "Name", d.name, UDim2.fromOffset(74, 26), UDim2.new(1, -84, 0, 20), 15, CO.white, F.heavy)
		name.ZIndex = 24
		name.TextTruncate = Enum.TextTruncate.AtEnd
		local status = Theme.label(card, "Status", "", UDim2.fromOffset(74, 47), UDim2.new(1, -84, 0, 16), 12, CO.muted, F.bold)
		status.ZIndex = 24
		local blurb = Theme.label(card, "Blurb", d.blurb, UDim2.fromOffset(10, 72), UDim2.new(1, -20, 0, 30), 11, CO.muted, F.medium)
		blurb.TextWrapped = true
		blurb.TextYAlignment = Enum.TextYAlignment.Top
		blurb.ZIndex = 24
		local function button(name, x, w)
			local b = Theme.make("TextButton", {
				Name = name, Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(x, if x == 0 then 10 else 4, 1, -10), Size = UDim2.new(w, -14, 0, 36),
				BackgroundColor3 = CO.ink, BorderSizePixel = 0, FontFace = F.heavy, TextSize = 13, TextColor3 = CO.white,
				Selectable = true, ZIndex = 25,
			}, card)
			Theme.corner(b, 9)
			local s = Theme.stroke(b, accent, 1, 0.5)
			Theme.buttonFeedback(b, CO.ink, accent:Lerp(CO.ink, 0.6), { scale = Theme.make("UIScale", { Scale = 1 }, b), stroke = s, accent = accent })
			return b
		end
		local buy = button("Buy", 0, 0.5)
		local equip = button("Equip", 0.5, 0.5)
		buy.Activated:Connect(function() call("buy", id) end)
		equip.Activated:Connect(function()
			local v = data and data.items[id]
			call("equip", id, not (v and v.equipped))
		end)
		local trial
		if Run:IsStudio() and (id == "jailer_chain" or id == "double_mirror") then
			trial = Theme.make("TextButton", {
				Name = "Trial", Text = "TRY (STUDIO)", AutoButtonColor = true, AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(84, 20), BackgroundColor3 = CO.ink,
				FontFace = F.bold, TextSize = 10, TextColor3 = CO.subtle, ZIndex = 26,
			}, card)
			Theme.corner(trial, 6)
			trial.Activated:Connect(function() call("trial", id) end)
		end
		cards[id] = { card = card, status = status, buy = buy, equip = equip, stroke = stroke, icon = icon, accent = accent }
	end

	---------------------------------------------------------------- slots
	local bar = Theme.make("Frame", {
		Name = "ToolBar", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.fromOffset(3 * 76 + 2 * 8, 76), BackgroundTransparency = 1, ZIndex = 5,
	}, gui)
	local slots = {}
	for i = 1, 3 do
		local slot = Theme.make("TextButton", {
			Name = "ToolSlot" .. i, Text = "", AutoButtonColor = false, Selectable = true,
			Position = UDim2.fromOffset((i - 1) * 84, 0), Size = UDim2.fromOffset(76, 76),
			BackgroundColor3 = CO.panel, BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 5, ClipsDescendants = true,
		}, bar)
		Theme.corner(slot, 14)
		Theme.gradient(slot, Color3.fromRGB(46, 34, 76), Color3.fromRGB(16, 13, 30))
		local stroke = Theme.stroke(slot, CO.line, 1.5, 0.25)
		local scale = Theme.make("UIScale", { Scale = 1 }, slot)
		local icon = Theme.image(slot, "Icon", "", UDim2.fromScale(0.5, 0.45), UDim2.fromOffset(46, 46), { AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 6 })
		-- Cooldown: a dark curtain that drains downward, plus seconds.
		local curtain = Theme.make("Frame", {
			Name = "Cooldown", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0),
			BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 7,
		}, slot)
		local seconds = Theme.label(slot, "Seconds", "", UDim2.fromScale(0, 0.18), UDim2.new(1, 0, 0, 26), 20, CO.white, F.number)
		seconds.TextXAlignment = Enum.TextXAlignment.Center
		seconds.ZIndex = 8
		Theme.make("UIStroke", { Color = CO.ink, Thickness = 1.5 }, seconds)
		local key = Theme.label(slot, "Key", tostring(i), UDim2.fromOffset(6, 3), UDim2.fromOffset(16, 16), 13, CO.muted, F.heavy)
		key.ZIndex = 8
		local count = Theme.label(slot, "Count", "", UDim2.new(1, -6, 0, 3), UDim2.fromOffset(40, 16), 13, CO.amber, F.heavy)
		count.AnchorPoint = Vector2.new(1, 0)
		count.TextXAlignment = Enum.TextXAlignment.Right
		count.ZIndex = 8
		Theme.make("UIStroke", { Color = CO.ink, Thickness = 1.2 }, count)
		local caption = Theme.label(slot, "Caption", "", UDim2.new(0, 0, 1, -18), UDim2.new(1, 0, 0, 14), 10, CO.muted, F.heavy)
		caption.TextXAlignment = Enum.TextXAlignment.Center
		caption.ZIndex = 8
		slots[i] = { slot = slot, icon = icon, curtain = curtain, seconds = seconds, count = count, caption = caption, stroke = stroke, scale = scale, key = key }
	end
	local useButton = Theme.make("TextButton", {
		Name = "UseTool", Text = "USE", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -150, 1, -150), Size = UDim2.fromOffset(78, 78),
		BackgroundColor3 = CO.amber, BorderSizePixel = 0, FontFace = F.heavy, TextSize = 18, TextColor3 = CO.ink, Visible = false, ZIndex = 9,
	}, gui)
	Theme.corner(useButton, 39)
	Theme.stroke(useButton, CO.white, 2, 0.4)
	local benchButton = Theme.make("TextButton", {
		Name = "OpenBench", Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(0, -8, 1, 0), Size = UDim2.fromOffset(44, 44), BackgroundColor3 = CO.panel, BorderSizePixel = 0, ZIndex = 5,
	}, bar)
	Theme.corner(benchButton, 12)
	Theme.stroke(benchButton, CO.line, 1.2, 0.3)
	Theme.image(benchButton, "Icon", VisualAssets.Icons.tool_pack, UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(30, 30), { AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 6 })
	local benchKey = Theme.label(benchButton, "Key", "B", UDim2.fromOffset(4, 2), UDim2.fromOffset(12, 12), 10, CO.muted, F.heavy)
	benchKey.ZIndex = 7
	Theme.buttonFeedback(benchButton, CO.panel, CO.cardHi, {})
	benchButton.Activated:Connect(function() showBench(not benchOpen) if benchOpen then call("snapshot") end end)

	local held = nil
	local function heldId()
		local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
		return tool and tool:GetAttribute("ToolId")
	end

	function Input.update(s)
		if typeof(s) ~= "table" or typeof(s.items) ~= "table" then return end
		data = s
		for id, card in cards do
			local v = s.items[id]
			if v then
				local d = C.Items[id]
				local locked = (not v.owned) and d.level > 0
				card.status.Text = if v.owned and d.kind == "permanent" then "Owned"
					elseif d.kind == "consumable" then string.format("%d charges", v.charges)
					else (if d.level > 0 then "Sanctuary Lv " .. d.level else "Not owned")
				card.status.TextColor3 = if v.owned then CO.soulGreen else CO.muted
				local canBuy = not (d.kind == "permanent" and v.owned)
				card.buy.Text = if not canBuy then "OWNED" elseif d.price == 0 then "FREE"
					elseif v.pack > 1 then string.format("x%d · %s Souls", v.pack, tostring(d.price))
					else string.format("%s Souls", tostring(d.price))
				card.buy.Active = canBuy
				card.buy.TextColor3 = if canBuy then CO.white else CO.subtle
				card.equip.Text = if v.equipped then "UNEQUIP" else "EQUIP"
				card.equip.TextColor3 = if v.owned or v.charges > 0 then CO.white else CO.subtle
				card.stroke.Transparency = if v.equipped then 0 else 0.6
				card.icon.ImageTransparency = if locked then 0.55 else 0
			end
		end
	end

	local function hold(i)
		local id = data and data.equipped[i]
		if not id then showBench(true) call("snapshot") return end
		if heldId() == id then
			-- Second press puts it away, like the default backpack.
			local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if h then h:UnequipTools() end
			return
		end
		call("hold", id)
	end
	for i, s in slots do
		s.slot.Activated:Connect(function() hold(i) end)
		Theme.buttonFeedback(s.slot, CO.panel, CO.cardHi, { scale = s.scale })
		CAS:BindAction("ToolSlot" .. i, function(_, state)
			if state == Enum.UserInputState.Begin then hold(i) end
			return Enum.ContextActionResult.Sink
		end, false, ({ Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three })[i], ({ Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadUp, Enum.KeyCode.DPadRight })[i])
	end
	CAS:BindAction("ToolsBench", function(_, state)
		if state == Enum.UserInputState.Begin then showBench(not benchOpen) if benchOpen then call("snapshot") end end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.B)

	-- Disable the default hotbar: this bar replaces it (tools still live in the Backpack).
	pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)

	local function activate()
		local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local id = heldId()
		if not r or not id then return end
		local d = C.Items[id]
		local at
		if UIS.TouchEnabled and not UIS.MouseEnabled then
			-- Touch aims where the character faces (no cursor).
			at = r.Position + r.CFrame.LookVector * math.min(d.range or 6, 18)
		else
			at = player:GetMouse().Hit.Position
		end
		if d.range then
			local delta = at - r.Position
			if delta.Magnitude > d.range then at = r.Position + delta.Unit * d.range end
		elseif id ~= "shovel" then
			at = r.Position + r.CFrame.LookVector * 5 - Vector3.new(0, 2.8, 0)
		end
		call("use", id, at)
	end
	useButton.Activated:Connect(activate)
	local bound = setmetatable({}, { __mode = "k" })
	local function bind(v)
		if v:IsA("Tool") and v:GetAttribute("ToolId") and not bound[v] then
			bound[v] = true
			v.Activated:Connect(activate)
		end
	end
	local function char(c)
		c.ChildAdded:Connect(bind)
		for _, v in c:GetChildren() do bind(v) end
	end
	player.CharacterAdded:Connect(char)
	if player.Character then char(player.Character) end
	local backpack = player:WaitForChild("Backpack")
	backpack.ChildAdded:Connect(bind)
	for _, v in backpack:GetChildren() do bind(v) end
	remote:WaitForChild("Changed").OnClientEvent:Connect(function(s, open)
		Input.update(s)
		if open then showBench(true) end
	end)

	local function fit()
		local size = safe.AbsoluteSize
		if size.X < 1 then return end
		local touch = UIS.TouchEnabled and not UIS.MouseEnabled
		local slotSize = if size.Y < 420 then 60 else 76
		for i, s in slots do
			s.slot.Size = UDim2.fromOffset(slotSize, slotSize)
			s.slot.Position = UDim2.fromOffset((i - 1) * (slotSize + 8), 0)
			s.icon.Size = UDim2.fromOffset(slotSize * 0.6, slotSize * 0.6)
		end
		bar.Size = UDim2.fromOffset(3 * slotSize + 16, slotSize)
		-- Phones: keep the bar left of the jump button and clear of the thumbstick.
		bar.AnchorPoint = if touch then Vector2.new(0.5, 1) else Vector2.new(0.5, 1)
		bar.Position = if touch then UDim2.new(0.5, 0, 1, -8) else UDim2.new(0.5, 0, 1, -16)
		useButton.Position = if touch then UDim2.new(1, -130, 1, -(slotSize + 30)) else UDim2.new(1, -150, 1, -150)
		local width = select(1, bench.fit(size))
		local columns = math.max(1, math.floor((width - 40) / 210))
		layout.CellSize = UDim2.fromOffset(math.floor((width - 44 - (columns - 1) * 10) / columns), 150)
	end
	safe:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()

	local elapsed = 0
	Run.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.05 then return end
		elapsed = 0
		local now = workspace:GetServerTimeNow()
		local current = heldId()
		if current ~= held then held = current end
		local touch = UIS.TouchEnabled
		useButton.Visible = current ~= nil and not benchOpen and touch
		if data then
			for i, s in slots do
				local id = data.equipped[i]
				local v = id and data.items[id]
				local d = id and C.Items[id]
				if v then
					s.icon.Image = VisualAssets.ToolIcons[id] or ""
					local remaining = math.max(0, v.cooldownEnds - now)
					local frac = if remaining > 0 then remaining / math.max(d.cooldown, 0.1) else 0
					s.curtain.Size = UDim2.fromScale(1, math.clamp(frac, 0, 1))
					s.seconds.Text = if remaining > 0 then string.format(if remaining < 10 then "%.1f" else "%d", remaining) else ""
					s.count.Text = if d.kind == "consumable" then "x" .. v.charges else ""
					s.caption.Text = string.upper(d.role)
					local empty = d.kind == "consumable" and v.charges <= 0
					s.icon.ImageTransparency = if empty then 0.6 else 0
					local selected = current == id
					s.stroke.Color = if selected then CO.amber else CO.line
					s.stroke.Thickness = if selected then 2.5 else 1.5
					s.stroke.Transparency = if selected then 0 else 0.25
					if remaining <= 0 and s.wasCooling then
						-- Ready ping.
						s.scale.Scale = 1.08
						TweenService:Create(s.scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
					end
					s.wasCooling = remaining > 0
				else
					s.icon.Image = ""
					s.curtain.Size = UDim2.fromScale(1, 0)
					s.seconds.Text = ""
					s.count.Text = ""
					s.caption.Text = "EMPTY"
					s.stroke.Color = CO.line
					s.stroke.Thickness = 1.5
				end
			end
		end
		-- Theft prompts: only on other players' placed Curses.
		local map = workspace:FindFirstChild("StealACurseMap")
		local active = map and map:FindFirstChild("ActiveCurses")
		if active then
			for _, m in active:GetChildren() do
				local anchor = m.PrimaryPart
				local steal = anchor and anchor:FindFirstChild("StealCurse")
				if steal then
					steal.Enabled = m:GetAttribute("OwnerUserId") ~= nil and m:GetAttribute("OwnerUserId") ~= player.UserId
						and m:GetAttribute("CurseState") == "PLACED" and not m:GetAttribute("OperationLocked")
				end
			end
		end
	end)
	task.spawn(function() call("snapshot") end)
end
return Input
