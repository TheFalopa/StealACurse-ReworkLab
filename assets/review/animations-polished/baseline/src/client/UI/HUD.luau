local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Theme = require(script.Parent.Theme)
local CurrencyCard = require(script.Parent.CurrencyCard)
local Navigation = require(script.Parent.Navigation)
local ShopPanel = require(script.Parent.ShopPanel)
local ShellPanel = require(script.Parent.ShellPanel)
local C = Theme.colors
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
	local panels = {}
	local activePanel = ""
	local function selectPanel(name: string)
		if name == activePanel then name = "" end
		activePanel = name
		for key, panel in panels do panel.show(key == name) end
		gui:SetAttribute("ActivePanel", name)
	end
	local function closePanel() selectPanel("") end
	panels.SHOP = ShopPanel.create(gui, closePanel)
	panels.CURSES = ShellPanel.create(gui, "CURSES", closePanel)
	panels.SETTINGS = ShellPanel.create(gui, "SETTINGS", closePanel)
	local navigation = Navigation.create(gui, selectPanel)
	gui:SetAttribute("ActivePanel", "")

	local notice = Theme.make("Frame", {
		Name = "Notice", AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = C.ink, BackgroundTransparency = 1, BorderSizePixel = 0,
		Position = UDim2.new(1, -12, 0, 168), Size = UDim2.fromOffset(252, 58),
	}, gui)
	Theme.corner(notice, 10)
	local message = Theme.label(notice, "Message", "", UDim2.fromOffset(12, 5), UDim2.new(1, -24, 1, -10), 12, C.white, Enum.Font.GothamMedium)
	message.TextWrapped = true
	message.TextTransparency = 1
	message.TextYAlignment = Enum.TextYAlignment.Center
	local noticeGeneration = 0
	local connections = {}
	local function updateNotice()
		local text = player:GetAttribute("HUDNotice")
		if typeof(text) ~= "string" or text == "" then return end
		noticeGeneration += 1
		local generation = noticeGeneration
		message.Text = text
		TweenService:Create(notice, TweenInfo.new(0.12), { BackgroundTransparency = 0.08 }):Play()
		TweenService:Create(message, TweenInfo.new(0.12), { TextTransparency = 0 }):Play()
		task.delay(3.2, function()
			if generation ~= noticeGeneration or not notice.Parent then return end
			TweenService:Create(notice, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(message, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
		end)
	end
	local function fit()
		local safe = safeRoot.AbsoluteSize
		if safe.X < 1 or safe.Y < 1 then return end
		local compact = safe.X < 900 or safe.Y < 500
		local width = math.min(if compact then 198 else 252, math.max(1, safe.X - 24))
		currency.fit(compact, width)
		local navY = if compact then 90 else 102
		navigation.fit(compact, width, navY)
		notice.Position = UDim2.new(1, -12, 0, if compact then 148 else 168)
		notice.Size = UDim2.fromOffset(width, if compact then 68 else 58)
		message.TextSize = if compact then 11 else 12
		for _, panel in panels do panel.fit(safe) end
	end
	table.insert(connections, safeRoot:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit))
	table.insert(connections, player:GetAttributeChangedSignal("HUDNoticeSerial"):Connect(updateNotice))
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
