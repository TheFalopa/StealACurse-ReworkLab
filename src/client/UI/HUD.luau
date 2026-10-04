local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Theme = require(script.Parent.Theme)
local CurrencyCard = require(script.Parent.CurrencyCard)
local Navigation = require(script.Parent.Navigation)
local ShopPanel = require(script.Parent.ShopPanel)
local SettingsPanel = require(script.Parent.SettingsPanel)
local SanctuaryBeacon = require(script.Parent.SanctuaryBeacon)
local RedMoonPresentation = require(script.Parent.RedMoonPresentation)
local Notify = require(script.Parent.Notify)
local HudLayout = require(script.Parent.HudLayout)
local C, F = Theme.colors, Theme.fonts
local HUD = {}

function HUD.start()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local previous = playerGui:FindFirstChild("StealACurseHUD")
	if previous then previous:Destroy() end
	local gui = Theme.make("ScreenGui", {
		Name = "StealACurseHUD", DisplayOrder = 10, ResetOnSpawn = false,
		IgnoreGuiInset = false, ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ClipToDeviceSafeArea = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, playerGui)
	-- Measure actual inset content bounds instead of raw camera resolution.
	local safeRoot = Theme.make("Frame", {
		Name = "SafeArea", Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, BorderSizePixel = 0,
	}, gui)
	-- One layout authority for every HUD module (see HudLayout).
	HudLayout.start(safeRoot)
	local currency = CurrencyCard.create(gui)
	local activePanel = ""
	local shop, settings, navigation
	-- Dock contract: CURSES (shown as Grimoire) opens the sanctuary panel, SHOP
	-- toggles the preview store on its Passes tab, SETTINGS its shell.
	local function selectPanel(name: string)
		if name == "CURSES" then
			shop.show(false); settings.show(false)
			activePanel = ""
			gui:SetAttribute("ActivePanel", "")
			gui.DisplayOrder = 10
			navigation.setActive("")
			require(script.Parent.SanctuaryPanel).start().open()
			return
		end
		if name == activePanel then name = "" end
		activePanel = name
		local storeTab = if name == "SHOP" then "Passes" else nil
		if storeTab then shop.selectTab(storeTab) end
		shop.show(storeTab ~= nil)
		settings.show(name == "SETTINGS")
		navigation.setActive(name)
		gui:SetAttribute("ActivePanel", name)
		-- While a HUD modal is open it must sit above the sanctuary launcher
		-- (DisplayOrder 30); otherwise the HUD stays beneath sanctuary panels.
		gui.DisplayOrder = if name ~= "" then 35 else 10
	end
	local function closePanel() selectPanel("") end
	shop = ShopPanel.create(gui, closePanel)
	settings = SettingsPanel.create(gui, closePanel)
	navigation = Navigation.create(gui, selectPanel)
	gui:SetAttribute("ActivePanel", "")
	SanctuaryBeacon.start(playerGui)
	-- The Red Moon chip heads the top lane while the event is active.
	local redMoon = RedMoonPresentation.start(gui, function(visible: boolean) HudLayout.setVisible("eventChip", visible) end)

	-- Every notice (server HUDNotice/HUDNoticeSerial and client Notify.push)
	-- shares one top-centre toast in its own layer, above open panels.
	-- Same inset mode as the HUD, so HudLayout's safe-area rects apply unchanged.
	local noticeGui = playerGui:FindFirstChild("Notifications")
	if noticeGui then noticeGui:Destroy() end
	noticeGui = Theme.make("ScreenGui", {
		Name = "Notifications", DisplayOrder = 50, ResetOnSpawn = false,
		IgnoreGuiInset = false, ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ClipToDeviceSafeArea = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, playerGui)
	gui.Destroying:Connect(function() noticeGui:Destroy() end)
	local notice = Theme.make("Frame", {
		Name = "Notice", AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = C.ink, BackgroundTransparency = 1, BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(380, 44), ZIndex = 30,
	}, noticeGui)
	Theme.corner(notice, 12)
	local noticeStroke = Theme.stroke(notice, C.violet, 1.2, 1)
	local toneBar = Theme.make("Frame", {
		Name = "Tone", BackgroundColor3 = C.violet, BackgroundTransparency = 1, BorderSizePixel = 0,
		Position = UDim2.new(0, 8, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 4, 1, -16), ZIndex = 31,
	}, notice)
	Theme.corner(toneBar, 2)
	local message = Theme.label(notice, "Message", "", UDim2.fromOffset(18, 0), UDim2.new(1, -32, 1, 0), 14, C.white, F.bold)
	message.TextWrapped = true
	message.TextTransparency = 1
	message.TextXAlignment = Enum.TextXAlignment.Center
	message.ZIndex = 31
	local TONES = { info = C.violet, good = C.soulGreen, bad = Color3.fromRGB(255, 120, 130) }
	local connections = {}

	-- Toast queue: at most 3 waiting, identical text is dropped, 'bad' notices
	-- jump ahead of the rest, and while others wait each toast still gets
	-- MIN_SECONDS on screen (HOLD_SECONDS when it is the last one).
	local MAX_QUEUE, MIN_SECONDS, HOLD_SECONDS = 3, 1.2, 3.4
	local queue: { { text: string, tone: string } } = {}
	local currentNotice: { text: string, tone: string, shownAt: number }? = nil
	local noticeGeneration = 0
	local function render(text: string, tone: string)
		local accent = TONES[tone] or TONES.info
		noticeStroke.Color = accent
		toneBar.BackgroundColor3 = accent
		-- Tweened (not set) so it replaces a fade-out still in flight.
		Theme.tween(toneBar, 0.1, { BackgroundTransparency = 0 })
		message.Text = text
		local x = notice:GetAttribute("CenterX") or 0
		local y = notice:GetAttribute("RestY") or 6
		notice.Position = UDim2.new(0, x, 0, y - 10)
		TweenService:Create(notice, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.08, Position = UDim2.new(0, x, 0, y),
		}):Play()
		Theme.tween(noticeStroke, 0.2, { Transparency = 0.3 })
		Theme.tween(message, 0.15, { TextTransparency = 0 })
	end
	local function hideNotice()
		Theme.tween(notice, 0.3, { BackgroundTransparency = 1 })
		Theme.tween(noticeStroke, 0.3, { Transparency = 1 })
		Theme.tween(message, 0.3, { TextTransparency = 1 })
		Theme.tween(toneBar, 0.3, { BackgroundTransparency = 1 })
	end
	local advance
	local function schedule()
		noticeGeneration += 1
		local generation = noticeGeneration
		local shown = currentNotice
		if not shown then return end
		local due = (if #queue > 0 then MIN_SECONDS else HOLD_SECONDS) - (os.clock() - shown.shownAt)
		task.delay(math.max(0, due), function()
			if generation ~= noticeGeneration or not notice.Parent then return end
			advance()
		end)
	end
	advance = function()
		local nextItem = table.remove(queue, 1)
		if nextItem then
			currentNotice = { text = nextItem.text, tone = nextItem.tone, shownAt = os.clock() }
			render(nextItem.text, nextItem.tone)
		else
			currentNotice = nil
			hideNotice()
		end
		schedule()
	end
	local function showNotice(text: string, tone: string?)
		local kind = if tone and TONES[tone] then tone else "info"
		if currentNotice and currentNotice.text == text then return end
		for _, waiting in queue do if waiting.text == text then return end end
		local item = { text = text, tone = kind }
		if kind == "bad" then
			local at = 1
			while queue[at] and queue[at].tone == "bad" do at += 1 end
			table.insert(queue, at, item)
		else
			table.insert(queue, item)
		end
		if #queue > MAX_QUEUE then
			-- Drop the oldest non-urgent notice first.
			local drop = #queue
			for index, waiting in queue do
				if waiting.tone ~= "bad" then
					drop = index
					break
				end
			end
			table.remove(queue, drop)
		end
		if currentNotice then schedule() else advance() end
	end
	local function updateNotice()
		local text = player:GetAttribute("HUDNotice")
		if typeof(text) ~= "string" or text == "" then return end
		showNotice(text, "info")
	end

	-- Positions come from HudLayout; this only applies them.
	local function applyLayout(layout)
		local compact = layout.compact
		local souls = layout.souls
		currency.holder.Position = UDim2.fromOffset(souls.x + souls.w, souls.y)
		currency.fit(compact, souls.w, souls.h)
		navigation.fit(layout.nav, layout.navEntries)
		local toast = layout.toast
		local centerX = toast.x + math.floor(toast.w / 2)
		notice.Size = UDim2.fromOffset(toast.w, toast.h)
		notice:SetAttribute("CenterX", centerX)
		notice:SetAttribute("RestY", toast.y)
		notice.Position = UDim2.new(0, centerX, 0, toast.y)
		message.TextSize = if compact then 12 else 14
		redMoon.fit(layout.eventChip, compact)
	end
	local function fitPanels()
		local safe = safeRoot.AbsoluteSize
		if safe.X < 1 or safe.Y < 1 then return end
		shop.fit(safe)
		settings.fit(safe)
	end
	table.insert(connections, HudLayout.observe(applyLayout))
	table.insert(connections, safeRoot:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitPanels))
	table.insert(connections, player:GetAttributeChangedSignal("HUDNoticeSerial"):Connect(updateNotice))
	table.insert(connections, Notify.pushed:Connect(showNotice))
	table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and activePanel ~= "" and (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB) then closePanel() end
	end))
	gui.Destroying:Connect(function()
		noticeGeneration += 1
		table.clear(queue)
		currency.destroy()
		for _, connection in connections do connection:Disconnect() end
	end)
	fitPanels()
	return gui
end

return HUD
