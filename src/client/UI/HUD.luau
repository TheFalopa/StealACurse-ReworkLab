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
	local currency = CurrencyCard.create(gui)
	local activePanel = ""
	local shop, settings, navigation
	local function selectPanel(name: string)
		if name == "CURSES" then
			shop.show(false); settings.show(false)
			activePanel = ""
			gui:SetAttribute("ActivePanel", "")
			navigation.setActive("")
			require(script.Parent.SanctuaryPanel).start().open()
			return
		end
		if name == activePanel then name = "" end
		activePanel = name
		local storeTab = if name == "SHOP" then "Products" elseif name == "GAMEPASSES" then "Passes" else nil
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
	local fit
	SanctuaryBeacon.start(playerGui)
	local redMoon = RedMoonPresentation.start(gui, function() if fit then fit() end end)

	-- Every notice (server HUDNotice/HUDNoticeSerial and client Notify.push)
	-- shares one top-centre toast in its own layer, above open panels.
	-- Same inset mode as the HUD, so the HUD's fit offsets apply unchanged.
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
	local noticeGeneration = 0
	local connections = {}
	local function centerX0(safe: Vector2, free: number, below: boolean): number
		return if below then math.floor(safe.X / 2) else math.floor(free / 2)
	end
	local function showNotice(text: string, tone: string?)
		noticeGeneration += 1
		local generation = noticeGeneration
		local accent = TONES[tone or "info"] or TONES.info
		noticeStroke.Color = accent
		toneBar.BackgroundColor3 = accent
		toneBar.BackgroundTransparency = 0
		message.Text = text
		local x = notice:GetAttribute("CenterX") or 0
		local y = notice:GetAttribute("RestY") or 6
		notice.Position = UDim2.new(0, x, 0, y - 10)
		TweenService:Create(notice, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.08, Position = UDim2.new(0, x, 0, y),
		}):Play()
		Theme.tween(noticeStroke, 0.2, { Transparency = 0.3 })
		Theme.tween(message, 0.15, { TextTransparency = 0 })
		task.delay(3.4, function()
			if generation ~= noticeGeneration or not notice.Parent then return end
			Theme.tween(notice, 0.3, { BackgroundTransparency = 1 })
			Theme.tween(noticeStroke, 0.3, { Transparency = 1 })
			Theme.tween(message, 0.3, { TextTransparency = 1 })
			Theme.tween(toneBar, 0.3, { BackgroundTransparency = 1 })
		end)
	end
	local function updateNotice()
		local text = player:GetAttribute("HUDNotice")
		if typeof(text) ~= "string" or text == "" then return end
		showNotice(text, "info")
	end
	fit = function()
		local safe = safeRoot.AbsoluteSize
		if safe.X < 1 or safe.Y < 1 then return end
		local compact = safe.X < 900 or safe.Y < 500 or UserInputService.TouchEnabled
		local width = math.min(if compact then 212 else 232, math.max(1, safe.X - 28))
		local cardHeight = if compact then 54 else 78
		local navHeight = if compact then math.floor((width - 18) / 4) + 8 else 4 * 48 + 3 * 8
		-- Desktop: the stack sits on the right edge just above centre, below the
		-- player list. Phones: tight to the top-right under the Roblox top bar.
		local top = if compact then 8 else math.max(12, math.floor(safe.Y * 0.46 - (cardHeight + 10 + navHeight) / 2))
		currency.holder.Position = UDim2.new(1, -14, 0, top)
		currency.fit(compact, width, cardHeight)
		navigation.fit(compact, width, top + cardHeight + 10)
		-- Centre the toast in the space left of the HUD column so it never
		-- covers the Souls card on narrow screens.
		-- Portrait phones lack that space; the toast then sits under the stack.
		local free = safe.X - width - 28
		local below = free < 300
		local noticeWidth = if below then math.min(380, safe.X - 28) else math.min(420, free - 24)
		local centerX = centerX0(safe, free, below)
		-- The Red Moon indicator owns the top slot while the event is active.
		local eventSlot = redMoon.fit(centerX0(safe, free, below), if below then top + cardHeight + navHeight + 16 else 6, compact)
		local noticeY = (if below then top + cardHeight + navHeight + 20 else 6) + eventSlot
		notice.Size = UDim2.fromOffset(noticeWidth, if compact then 40 else 44)
		notice:SetAttribute("CenterX", centerX)
		notice:SetAttribute("RestY", noticeY)
		notice.Position = UDim2.new(0, centerX, 0, noticeY)
		message.TextSize = if compact then 12 else 14
		shop.fit(safe)
		settings.fit(safe)
	end
	table.insert(connections, safeRoot:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit))
	table.insert(connections, player:GetAttributeChangedSignal("HUDNoticeSerial"):Connect(updateNotice))
	table.insert(connections, Notify.pushed:Connect(showNotice))
	table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and activePanel ~= "" and (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB) then closePanel() end
	end))
	gui.Destroying:Connect(function()
		noticeGeneration += 1
		currency.destroy()
		for _, connection in connections do connection:Disconnect() end
	end)
	fit()
	return gui
end

return HUD
