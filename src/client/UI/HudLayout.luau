-- HUD layout authority. One pure compute() turns the safe-area size, the
-- platform and the reserved Roblox zones (chat, thumbstick, jump) into named
-- rects; the runtime half measures those inputs and tells the HUD modules when
-- the frame changes. Rects are plain { x, y, w, h } tables in safe-area pixels:
-- every HUD ScreenGui uses CoreUISafeInsets, so one rect means the same spot in
-- each of them. The pure half touches no Roblox global at load time, so
-- tools/hud_layout_check.luau can require and verify it under Lune.
--
--   right column : Souls card, nav, Luck pill (persistent economy)
--   top lane     : event chip, one objective chip, toast (transient), centred
--                  between the chat zone and the right column
--   bottom       : tool bar (ToolsInput), USE, touch SANCTUARY launcher and,
--                  when the lane is too narrow, the objective chip
local HudLayout = {}

export type Rect = { x: number, y: number, w: number, h: number }

local EDGE, GAP, LANE_TOP, LANE_GAP = 14, 8, 6, 6
local EVENT_W, EVENT_H = 218, 40
local OBJECTIVE_H, OBJECTIVE_MAX, OBJECTIVE_BOTTOM_MAX, OBJECTIVE_MIN = 56, 400, 360, 220
-- Lanes narrower than this (landscape phones) move the objective chip above the
-- tool bar; the event chip and the toast stay in the lane and shrink.
local OBJECTIVE_LANE_MIN = 300
-- The event chip and toast never shrink below this; a narrower span (only if
-- the measured chat window is unusually wide) lets them reach into its edge.
local LANE_FLOOR = 150
local LAUNCHER_TOUCH = 48

-- Higher wins: a ritual hides a contract, a contract hides Mortimer's task.
HudLayout.ObjectivePriority = { ritual = 3, contract = 2, mission = 1, event = 1 }
HudLayout.Widgets = { "souls", "nav", "luck", "eventChip", "objective", "toast", "launcher", "useButton" }
HudLayout.Interactive = { nav = true, luck = true, launcher = true, useButton = true }
HudLayout.Lane = { eventChip = true, objective = true, toast = true }

local function rect(x: number, y: number, w: number, h: number): Rect
	return { x = math.floor(x), y = math.floor(y), w = math.floor(w), h = math.floor(h) }
end
HudLayout.rect = rect

function HudLayout.intersects(a: Rect?, b: Rect?): boolean
	if not a or not b then return false end
	return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end

function HudLayout.inside(r: Rect, width: number, height: number): boolean
	return r.x >= 0 and r.y >= 0 and r.x + r.w <= width and r.y + r.h <= height
end

local function union(a: Rect, b: Rect): Rect
	local x, y = math.min(a.x, b.x), math.min(a.y, b.y)
	return rect(x, y, math.max(a.x + a.w, b.x + b.w) - x, math.max(a.y + a.h, b.y + b.h) - y)
end

-- Measured rects can reach outside the safe area (topbar, notch); keep the part inside.
local function clip(r: Rect?, width: number, height: number): Rect?
	if not r then return nil end
	local x, y = math.max(0, r.x), math.max(0, r.y)
	local w, h = math.min(width, r.x + r.w) - x, math.min(height, r.y + r.h) - y
	if w <= 0 or h <= 0 then return nil end
	return rect(x, y, w, h)
end

-- Conservative stand-in for the Roblox chat window (top-left on every
-- platform; taller on phones, where it opens over half the height). The
-- runtime unions it with ChatWindowConfiguration's measured rect, so the
-- reserved zone is never smaller than this. Calibrate in Studio.
function HudLayout.chatFallback(width: number, height: number, touch: boolean?): Rect
	local h = if touch then math.min(math.floor(height * 0.5), 300) else math.min(math.floor(height * 0.45), 260)
	return rect(0, 0, math.min(math.floor(width * 0.4), 420), h)
end

-- PlayerModule TouchJump placement, used until the real JumpButton is measured.
function HudLayout.jumpFallback(width: number, height: number): Rect
	local small = math.min(width, height) <= 500
	local size = if small then 70 else 120
	return rect(width - (size * 1.5 - 10), height - (if small then size + 20 else size * 1.75), size, size)
end

-- Where the resting thumbstick and most thumb starts land (left 40%, bottom
-- third). The full DynamicThumbstick frame reaches higher; keep interactive
-- widgets out of at least this part.
function HudLayout.thumbstickZone(width: number, height: number): Rect
	local h = math.floor(height / 3)
	return rect(0, height - h, math.floor(width * 0.4), h)
end

-- Mirrors ToolsInput.fit until ToolsInput publishes the real bar.
function HudLayout.toolBarFallback(width: number, height: number, touch: boolean): (Rect, Rect)
	local slot = if height < 420 then 60 else 76
	local barWidth = 3 * slot + 16
	local bar = rect(math.floor((width - barWidth) / 2), height - (if touch then 8 else 16) - slot, barWidth, slot)
	return bar, rect(bar.x - 8 - 44, bar.y + bar.h - 44, 44, 44)
end

function HudLayout.objectiveOwner(claims: { [string]: number }): string?
	local owner, best = nil, -math.huge
	for source, priority in claims do
		if priority > best or (priority == best and owner and source < owner) then owner, best = source, priority end
	end
	return owner
end

-- input: { width, height, touch, visible?, chat?, jump?, toolBar?, bench?, objectiveOwner? }
-- Returns nil until the safe area has a size.
function HudLayout.compute(input)
	local W, H = math.floor(input.width or 0), math.floor(input.height or 0)
	if W < 1 or H < 1 then return nil end
	local touch = input.touch == true
	local seen = input.visible or {}
	local visible = {
		souls = true, nav = true, launcher = seen.launcher ~= false, useButton = seen.useButton ~= false,
		luck = seen.luck == true, eventChip = seen.eventChip == true, objective = seen.objective == true,
		toast = seen.toast ~= false,
	}
	local compact = touch or W < 900 or H < 500
	local layout: any = { width = W, height = H, touch = touch, compact = compact, landscape = W >= H, visible = visible, objectiveOwner = input.objectiveOwner, unresolved = {} }

	-- Reserved zones.
	local chat = HudLayout.chatFallback(W, H, touch)
	local measuredChat = clip(input.chat, W, H)
	if measuredChat then chat = union(chat, measuredChat) end
	local jump = clip(input.jump, W, H) or (if touch then HudLayout.jumpFallback(W, H) else nil)
	local thumbstick = if touch then HudLayout.thumbstickZone(W, H) else nil
	layout.zones = { chat = chat, jump = jump, thumbstick = thumbstick }

	-- Right column: Souls card, nav, then the Luck pill. Its space is reserved
	-- even while the pill is hidden so the column never jumps.
	local colW = math.min(if compact then 212 else 232, math.max(1, W - 2 * EDGE))
	local soulsH = if compact then 54 else 78
	local tile = math.floor((colW - 18) / 4)
	local navH = if compact then tile + 8 else 4 * 48 + 3 * 8
	local luckH = if touch then 52 else 44
	local stackH = soulsH + 10 + navH + GAP + luckH
	-- Desktop: just above centre, below the player list. Phones: under the topbar.
	local top = if compact then 8 else math.max(12, math.floor(H * 0.46 - stackH / 2))
	local colX = W - EDGE - colW
	layout.souls = rect(colX, top, colW, soulsH)
	layout.nav = rect(colX, top + soulsH + 10, colW, navH)
	layout.navTile = if compact then { w = tile, h = tile + 8 } else { w = colW, h = 48 }
	layout.luck = rect(colX, top + soulsH + 10 + navH + GAP, colW, luckH)
	local luck = layout.luck
	layout.drink = if touch then rect(luck.x + luck.w - 4 - 64, luck.y + 4, 64, 44) else rect(luck.x + luck.w - 6 - 72, luck.y + 5, 72, 34)

	-- Bottom cluster. The tool bar is owned by ToolsInput; it is an obstacle here.
	local fallbackBar, fallbackBench = HudLayout.toolBarFallback(W, H, touch)
	local bar = input.toolBar or fallbackBar
	local bench = input.bench or fallbackBench
	layout.toolBar, layout.bench = bar, bench

	local placed = { layout.souls, layout.nav, layout.luck, bar, bench }
	local function free(r: Rect, interactive: boolean): boolean
		if not HudLayout.inside(r, W, H) or HudLayout.intersects(r, chat) or HudLayout.intersects(r, jump) then return false end
		if interactive and HudLayout.intersects(r, thumbstick) then return false end
		for _, other in placed do if HudLayout.intersects(r, other) then return false end end
		return true
	end
	local function pick(name: string, candidates: { Rect }): Rect
		for _, candidate in candidates do
			if free(candidate, true) then
				table.insert(placed, candidate)
				return candidate
			end
		end
		table.insert(layout.unresolved, name)
		table.insert(placed, candidates[1])
		return candidates[1]
	end
	local useSize = if touch and math.min(W, H) <= 500 then 64 else 78
	local function placeUse(): Rect
		if jump then
			return pick("useButton", {
				rect(jump.x - GAP - useSize, jump.y + jump.h - useSize, useSize, useSize), -- left of jump
				rect(jump.x + (jump.w - useSize) / 2, jump.y - GAP - useSize, useSize, useSize), -- above jump
				rect(jump.x - GAP - useSize, jump.y - GAP - useSize, useSize, useSize),
			})
		end
		local launcher = layout.launcher
		return pick("useButton", {
			rect(W - 150 - useSize, H - 150 - useSize, useSize, useSize),
			rect(W - 12 - useSize, (if launcher then launcher.y else H) - GAP - useSize, useSize, useSize),
		})
	end
	if touch then
		-- Thumb reach first: USE beside the jump button, then the launcher
		-- right of tool slot 3.
		layout.useButton = placeUse()
		local use, s = layout.useButton, LAUNCHER_TOUCH
		layout.launcher = pick("launcher", {
			rect(bar.x + bar.w + GAP, bar.y + bar.h - s, s, s),
			rect(bar.x + bar.w - s, bar.y - GAP - s, s, s),
			rect(use.x - GAP - s, use.y + use.h - s, s, s),
			rect(use.x + (use.w - s) / 2, use.y - GAP - s, s, s),
		})
	else
		local launcherW = math.min(210, math.floor(W * 0.42))
		layout.launcher = pick("launcher", { rect(W - 12 - launcherW, H - 16 - 44, launcherW, 44) })
		layout.useButton = placeUse()
	end

	-- Top-centre lane.
	local laneL, laneR, laneY
	if W >= H then
		laneL, laneR, laneY = chat.x + chat.w + GAP, colX - GAP, LANE_TOP
		if laneR - laneL < LANE_FLOOR then laneL = math.max(EDGE, laneR - LANE_FLOOR) end
	else
		-- Portrait: below both the chat zone and the right column.
		laneL, laneR = EDGE, W - EDGE
		laneY = math.max(chat.y + chat.h, luck.y + luck.h) + GAP
	end
	local laneW = laneR - laneL
	local cx = laneL + math.floor(laneW / 2)
	layout.lane = rect(laneL, laneY, laneW, 0)
	local function centred(width: number, y: number, height: number): Rect
		return rect(cx - math.floor(width / 2), y, width, height)
	end
	local y = laneY
	layout.eventChip = centred(math.min(EVENT_W, laneW), y, EVENT_H)
	if visible.eventChip then y += EVENT_H + LANE_GAP end

	-- Objective: in the lane when it is wide enough, else centred directly above
	-- the tool bar, as wide as the band between USE/launcher/jump allows.
	local function bottomObjective(): Rect?
		local center = bar.x + math.floor(bar.w / 2)
		local obstacles = { chat, jump, layout.useButton, layout.launcher, layout.souls, layout.nav, layout.luck, bar, bench }
		-- Never climb into the lane's event chip + tallest toast.
		local ceiling = laneY + EVENT_H + LANE_GAP + 52 + GAP
		for step = 0, 2 do
			local by = bar.y - GAP - OBJECTIVE_H - step * (OBJECTIVE_H + GAP)
			local half = math.min(math.floor(OBJECTIVE_BOTTOM_MAX / 2), center - EDGE, W - EDGE - center)
			for _, o in obstacles do
				if o and o.y < by + OBJECTIVE_H and by < o.y + o.h then
					if o.x >= center then half = math.min(half, o.x - GAP - center)
					elseif o.x + o.w <= center then half = math.min(half, center - (o.x + o.w) - GAP)
					else half = -1 end
				end
			end
			if by >= ceiling and half * 2 >= OBJECTIVE_MIN then return rect(center - half, by, half * 2, OBJECTIVE_H) end
		end
		return nil
	end
	local objective = if laneW < OBJECTIVE_LANE_MIN then bottomObjective() else nil
	if objective then
		layout.objectivePlacement = "bottom"
	else
		layout.objectivePlacement = "lane"
		objective = centred(math.min(OBJECTIVE_MAX, laneW), y, OBJECTIVE_H)
		if visible.objective then y += OBJECTIVE_H + LANE_GAP end
	end
	layout.objective = objective

	local toastW = math.min(if compact then 380 else 420, laneW)
	-- Narrow toasts wrap to three lines rather than truncating.
	layout.toast = centred(toastW, y, if toastW < 260 then 52 elseif compact then 40 else 44)
	return layout
end

---------------------------------------------------------------- runtime
-- Everything below runs only in the Roblox client.

local listeners = {}
local visibleState = { launcher = true, useButton = true, toast = true }
local claims: { [string]: number } = {}
local published: { toolBar: Rect?, bench: Rect? } = {}
local current = nil
local signature = nil
local runtime = nil
local busy, pending = false, false

local function signatureOf(layout): string
	local parts = { layout.objectivePlacement, layout.objectiveOwner or "", tostring(layout.touch), tostring(layout.compact) }
	for _, name in { "souls", "nav", "luck", "drink", "eventChip", "objective", "toast", "launcher", "useButton" } do
		local r = layout[name]
		table.insert(parts, string.format("%d,%d,%d,%d", r.x, r.y, r.w, r.h))
	end
	for _, name in HudLayout.Widgets do table.insert(parts, if layout.visible[name] then "1" else "0") end
	return table.concat(parts, "|")
end

local function measure()
	local run = runtime
	local root = run.safeRoot
	local size, origin = root.AbsoluteSize, root.AbsolutePosition
	if size.X < 1 or size.Y < 1 then return nil end
	-- Absolute GUI space -> this safe area's space.
	local function toSafe(position: Vector2, extent: Vector2): Rect
		return rect(position.X - origin.X, position.Y - origin.Y, extent.X, extent.Y)
	end
	local touch = run.input.TouchEnabled and not run.input.MouseEnabled
	local chat, jump = nil, nil
	local window = run.chatWindow
	if window then
		pcall(function()
			if window.Enabled and window.AbsoluteSize.X > 0 and window.AbsoluteSize.Y > 0 then chat = toSafe(window.AbsolutePosition, window.AbsoluteSize) end
		end)
	end
	local button = run.jumpButton
	if button and button.Parent and button.AbsoluteSize.X > 0 and (touch or button.Visible) then
		jump = toSafe(button.AbsolutePosition, button.AbsoluteSize)
	end
	local visible = table.clone(visibleState)
	local owner = HudLayout.objectiveOwner(claims)
	visible.objective = owner ~= nil
	return {
		width = size.X, height = size.Y, touch = touch, visible = visible, chat = chat, jump = jump,
		toolBar = published.toolBar, bench = published.bench, objectiveOwner = owner,
	}
end

-- Recompute and notify only when a rect, a visibility or the objective owner
-- actually changed. Re-entrant calls (a listener declaring visibility) fold
-- into one more pass.
local function refresh()
	if not runtime then return end
	if busy then
		pending = true
		return
	end
	busy = true
	repeat
		pending = false
		-- A failed pass keeps the previous frame instead of locking `busy`.
		local ok, layout = pcall(function()
			local input = runtime and measure()
			return input and HudLayout.compute(input)
		end)
		if not ok then
			warn("[HudLayout] " .. tostring(layout))
			layout = nil
		end
		if layout then
			local key = signatureOf(layout)
			if key ~= signature then
				signature, current = key, layout
				for _, listener in table.clone(listeners) do task.spawn(listener, layout) end
			end
		end
	until not pending
	busy = false
end

HudLayout.Changed = {}
function HudLayout.Changed:Connect(callback)
	local handle = { Connected = true }
	table.insert(listeners, callback)
	function handle.Disconnect()
		handle.Connected = false
		local index = table.find(listeners, callback)
		if index then table.remove(listeners, index) end
	end
	return handle
end

-- Connect and, if a layout already exists, apply it right away.
function HudLayout.observe(callback)
	local handle = HudLayout.Changed:Connect(callback)
	if current then task.spawn(callback, current) end
	return handle
end

function HudLayout.current() return current end

-- eventChip / luck / toast / launcher / useButton.
function HudLayout.setVisible(name: string, value: boolean)
	if visibleState[name] == value then return end
	visibleState[name] = value
	refresh()
end

-- source: "mission" | "sanctuary"; priority nil releases the claim.
function HudLayout.claimObjective(source: string, priority: number?)
	if claims[source] == priority then return end
	if priority then claims[source] = priority else claims[source] = nil end
	refresh()
end

-- ToolsInput publishes the bar it actually placed (safe-area pixels).
function HudLayout.setToolBar(bar: Rect, bench: Rect)
	local old = published.toolBar
	if old and old.x == bar.x and old.y == bar.y and old.w == bar.w and old.h == bar.h then return end
	published.toolBar, published.bench = bar, bench
	refresh()
end

-- Applies a rect with a top-left anchor.
function HudLayout.place(object: GuiObject, r: Rect)
	object.AnchorPoint = Vector2.zero
	object.Position = UDim2.fromOffset(r.x, r.y)
	object.Size = UDim2.fromOffset(r.w, r.h)
end

function HudLayout.stop()
	local run = runtime
	if not run then return end
	runtime = nil
	for _, connection in run.connections do connection:Disconnect() end
	for _, connection in run.jumpConnections do connection:Disconnect() end
end

-- safeRoot: a full-size Frame in a CoreUISafeInsets ScreenGui (HUD's SafeArea).
-- Event-driven only: safe-area, chat-window and jump-button property signals.
function HudLayout.start(safeRoot: GuiObject)
	HudLayout.stop()
	local Players = game:GetService("Players")
	local TextChatService = game:GetService("TextChatService")
	local run = {
		safeRoot = safeRoot, input = game:GetService("UserInputService"),
		connections = {}, jumpConnections = {}, chatWindow = nil, jumpButton = nil,
	}
	runtime = run
	signature = nil
	local function on(signal: RBXScriptSignal, callback)
		table.insert(run.connections, signal:Connect(callback))
	end
	on(safeRoot:GetPropertyChangedSignal("AbsoluteSize"), refresh)
	on(safeRoot:GetPropertyChangedSignal("AbsolutePosition"), refresh)
	on(safeRoot.Destroying, function() if runtime == run then HudLayout.stop() end end)

	-- TextChatService window (absent or idle under legacy chat: fallback only).
	-- Its Absolute* is taken to share GuiObject absolute space (Studio to
	-- confirm); if it were full-screen space the rect would land one topbar
	-- lower and the union with the top-left fallback would still cover it.
	pcall(function()
		local window = TextChatService.ChatWindowConfiguration
		if not window then return end
		run.chatWindow = window
		for _, property in { "AbsolutePosition", "AbsoluteSize", "Enabled" } do
			on(window:GetPropertyChangedSignal(property), refresh)
		end
	end)

	-- PlayerGui.TouchGui.TouchControlFrame.JumpButton; the PlayerModule may
	-- create, rebuild or remove it at any time.
	local function setJumpButton(button: GuiObject?)
		if runtime ~= run or run.jumpButton == button then return end
		for _, connection in run.jumpConnections do connection:Disconnect() end
		table.clear(run.jumpConnections)
		run.jumpButton = button
		if button then
			for _, property in { "AbsolutePosition", "AbsoluteSize", "Visible" } do
				table.insert(run.jumpConnections, button:GetPropertyChangedSignal(property):Connect(refresh))
			end
		end
		refresh()
	end
	local function isJump(object: Instance): boolean
		return object.Name == "JumpButton" and object:IsA("GuiObject") and object.Parent ~= nil and object.Parent.Name == "TouchControlFrame"
	end
	local function watchTouchGui(touchGui: Instance)
		for _, object in touchGui:GetDescendants() do
			if isJump(object) then
				setJumpButton(object :: GuiObject)
				break
			end
		end
		on(touchGui.DescendantAdded, function(object) if isJump(object) then setJumpButton(object :: GuiObject) end end)
		on(touchGui.DescendantRemoving, function(object) if object == run.jumpButton then setJumpButton(nil) end end)
	end
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if playerGui then
		local touchGui = playerGui:FindFirstChild("TouchGui")
		if touchGui then watchTouchGui(touchGui) end
		on(playerGui.ChildAdded, function(child) if child.Name == "TouchGui" then watchTouchGui(child) end end)
	end
	refresh()
end

return HudLayout
