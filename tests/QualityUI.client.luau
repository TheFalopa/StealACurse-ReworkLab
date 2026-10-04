-- Read-only UI observer, only in the generated -QualityPass fixture. It never
-- changes balances, attributes, buttons, panel visibility or viewport presets.
-- Open/close/tabs/touch are exercised by the person controlling Studio; output
-- markers only describe states this observer actually saw.
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local NumberFormat = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("NumberFormat"))
local Catalog = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("CurseCatalog"))
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("StealACurseHUD", 30)
assert(gui and gui:IsA("ScreenGui"), "QUALITY_UI_FAIL: production HUD missing")
task.wait(1)

local failures = {}
local function check(value: boolean, label: string)
	if not value then table.insert(failures, label) end
	return value
end
local function required(parent: Instance, name: string, className: string): Instance?
	local child = parent:FindFirstChild(name)
	if check(child ~= nil and child:IsA(className), parent:GetFullName() .. " requires " .. name .. " (" .. className .. ")") then return child end
	return nil
end
local holder = required(gui, "SoulsHUD", "Frame")
local card = holder and required(holder, "Card", "Frame")
local amount = card and required(card, "Amount", "TextLabel")
local rate = card and required(card, "SoulsPerSecond", "TextLabel")
local animated = required(gui, "AnimatedSouls", "NumberValue")
local navigation = required(gui, "Navigation", "Frame")
local overlay = required(gui, "ShopOverlay", "Frame")
local panel = overlay and required(overlay, "ShopPanel", "Frame")
local close = panel and required(panel, "CloseButton", "TextButton")
local sections = {}
for _, name in { "Passes", "Products" } do
	local tab = panel and required(panel, name .. "Tab", "TextButton")
	local page = panel and required(panel, name .. "Page", "ScrollingFrame")
	if tab and page then table.insert(sections, { name = name, tab = tab, page = page }) end
end
-- CURSES now opens the sanctuary panel; the old roster overlay is optional.
local cursesOverlay = gui:FindFirstChild("CursesOverlay")
local cursesPanel = cursesOverlay and cursesOverlay:FindFirstChild("CursesPanel")
local roster = cursesPanel and cursesPanel:FindFirstChild("Content")
local settingsOverlay = required(gui, "SettingsOverlay", "Frame")
local settingsPanel = settingsOverlay and required(settingsOverlay, "SettingsPanel", "Frame")
local buttons = {}
if navigation then
	for _, name in ipairs({ "SHOP", "CURSES", "GAMEPASSES", "SETTINGS" }) do
		local button = required(navigation, name, "TextButton")
		if button then table.insert(buttons, button) end
	end
end
local ctas, prices = 0, 0
local previewButtons = {}
if panel then
	for _, object in ipairs(panel:GetDescendants()) do
		if object.Name == "ComingSoonButton" and object:IsA("TextButton") then
			ctas += 1
			table.insert(previewButtons, object)
			check(string.find(string.upper(object.Text), "COMING SOON", 1, true) ~= nil, "Store CTA must say Coming Soon: " .. object:GetFullName())
		elseif object.Name == "Price" and object:IsA("TextLabel") then
			prices += 1
			check(object.Text == "TBD", "Mockup price must be TBD, not invented Robux: " .. object:GetFullName())
		end
		for attribute in pairs(object:GetAttributes()) do
			check(not string.match(string.lower(attribute), "productid") and not string.match(string.lower(attribute), "gamepassid"),
				"Mockup must not contain purchase IDs: " .. object:GetFullName())
		end
	end
end
check(ctas >= 10 and prices == ctas, "Every shop mock card must have one TBD price and a Coming Soon CTA")
check(gui.ResetOnSpawn == false and gui.IgnoreGuiInset == false, "HUD must survive respawn and respect Roblox GUI inset")
if holder then check(holder.AnchorPoint == Vector2.new(1, 0), "Currency HUD must anchor upper-right") end
for _, section in sections do
	check(section.page.ClipsDescendants and section.page.Active and section.page.ScrollingEnabled, "All shop sections must support native scrolling")
end
if roster then
	local orderList = Catalog.AllOrder or Catalog.Order
	local count, activeCount = 0, 0
	for _, id in orderList do
		local row = required(roster, id, "Frame")
		if row then
			count += 1
			check(row:GetAttribute("CurseId") == id, "Roster row ID matches definition: " .. id)
			local enabled = Catalog.Definitions[id].enabled ~= false
			check(row:GetAttribute("RolloutEnabled") == enabled, "Roster truthfully distinguishes disabled concepts: " .. id)
			if enabled then activeCount += 1 end
			local status = required(row, "ImplementationStatus", "TextLabel")
			if status then check(string.find(status.Text, if enabled then "LIVE" else "Not spawning", 1, true) ~= nil, "Roster status is not fake ownership: " .. id) end
		end
	end
	check(count == #orderList and cursesPanel:GetAttribute("RosterCount") == count, "Read-only roster exposes the complete manifest")
	check(cursesPanel:GetAttribute("LiveRosterCount") == activeCount, "Live roster count matches controlled rollout")
end
if animated and amount then check(amount.Text == NumberFormat.compact(animated.Value), "Initial animated Souls text must match number value") end
-- The card shows "+N/s", or a short hint while income is zero.
local function expectedRate(value): string
	return if value > 0 then "+" .. NumberFormat.compact(value) .. "/s" else "Place a Curse to earn"
end
if rate then
	local value = player:GetAttribute("SoulsPerSecond")
	check(typeof(value) == "number" and rate.Text == expectedRate(value), "Initial rate text must match replicated server rate")
end
assert(#failures == 0, "QUALITY_UI_FAIL: " .. table.concat(failures, "; "))

local camera = workspace.CurrentCamera
local readyDeadline = os.clock() + 15
repeat
	camera = workspace.CurrentCamera
	if camera and camera.ViewportSize.X > 100 and camera.ViewportSize.Y > 100 then break end
	task.wait(0.1)
until os.clock() > readyDeadline
assert(camera and camera.ViewportSize.X > 100 and camera.ViewportSize.Y > 100, "QUALITY_UI_FAIL: camera viewport never initialized")
task.wait(0.3)
local function insideViewport(object: GuiObject, label: string, viewport: Vector2)
	local at, size = object.AbsolutePosition, object.AbsoluteSize
	check(size.X > 0 and size.Y > 0, label .. " has nonzero size")
	check(at.X >= -1 and at.Y >= -1 and at.X + size.X <= viewport.X + 1 and at.Y + size.Y <= viewport.Y + 1,
		label .. " must remain inside viewport")
end
local function reportGeometry(reason: string, shopVisible: boolean)
	table.clear(failures)
	camera = workspace.CurrentCamera
	if not camera or camera.ViewportSize.X <= 100 or camera.ViewportSize.Y <= 100 then return end
	local viewport = camera.ViewportSize
	insideViewport(card, "Currency card", viewport)
	insideViewport(navigation, "Navigation", viewport)
	for _, button in ipairs(buttons) do
		insideViewport(button, button.Name, viewport)
		check(button.AbsoluteSize.X >= 44 and button.AbsoluteSize.Y >= 44, "Navigation has a real touch target: " .. button.Name)
	end
	check(card.AbsolutePosition.X + card.AbsoluteSize.X >= viewport.X * 0.65
		and card.AbsolutePosition.Y < viewport.Y * 0.25, "Currency card stays at upper-right, away from center")
	if shopVisible then
		insideViewport(panel, "Shop panel", viewport)
		insideViewport(close, "Shop close button", viewport)
		check(close.AbsoluteSize.X >= 44 and close.AbsoluteSize.Y >= 44, "Shop close has a real touch target")
		local page = nil
		local visiblePages = 0
		for _, section in sections do
			insideViewport(section.tab, section.name .. " tab", viewport)
			check(section.tab.TextFits, "Section label fits: " .. section.name)
			if section.page.Visible then visiblePages += 1; page = section.page end
		end
		check(visiblePages == 1 and page ~= nil, "Exactly one store page is visible")
		if not page then return end
		check(page.ScrollingEnabled and page.Active and page.AbsoluteSize.Y > 0, "Selected store page supports scrolling")
		local grid = page:FindFirstChildWhichIsA("UIGridLayout")
		if grid and gui.AbsoluteSize.Y < 430 and gui.AbsoluteSize.Y >= 290 then
			check(grid.CellSize.Y.Offset + 2 <= page.AbsoluteSize.Y, "Landscape page can show one full card")
		end
		for _, object in ipairs(page:GetDescendants()) do
			if object:IsA("TextLabel") and (object.Name == "Title" or object.Name == "Benefit" or object.Name == "Price") then
				check(object.TextFits, "Card text fits its label: " .. object:GetFullName())
			elseif object.Name == "ComingSoonButton" and object:IsA("TextButton") then
				check(object.AbsoluteSize.X >= 100 and object.AbsoluteSize.Y >= 44, "Preview CTA keeps a real touch target: " .. object:GetFullName())
			end
		end
	end
	for _, shell in { cursesPanel, settingsPanel } do
		if shell and shell.Parent.Visible then
			insideViewport(shell, shell.Name, viewport)
			local shellClose = shell:FindFirstChild("CloseButton")
			if shellClose then insideViewport(shellClose, shell.Name .. " close", viewport) end
			local content = shell:FindFirstChild("Content")
			if content then
				for _, object in content:GetDescendants() do
					if object:IsA("TextLabel") then check(object.TextFits, "Shell row text fits: " .. object:GetFullName()) end
				end
			end
		end
	end
	print("QUALITY_UI_REPORT", HttpService:JSONEncode({ reason = reason, viewport = { viewport.X, viewport.Y }, shopVisible = shopVisible,
		cardPosition = { card.AbsolutePosition.X, card.AbsolutePosition.Y }, cardSize = { card.AbsoluteSize.X, card.AbsoluteSize.Y },
		mockCards = ctas, failures = failures, method = "Read-only bounds/text observer, not proof of touch input or real-device FPS. Purchase exclusion is verified by the separate static audit." }))
	assert(#failures == 0, "QUALITY_UI_FAIL: " .. table.concat(failures, "; "))
	print(if shopVisible then "QUALITY_SHOP_OPEN_PASS" else "QUALITY_UI_PASS", reason, viewport.X, viewport.Y)
end
reportGeometry("initial", overlay.Visible)

-- These observers record native events only. They never set CanvasPosition,
-- activate a button, change tabs, issue a purchase or alter a player value.
panel:GetAttributeChangedSignal("SelectedTab"):Connect(function()
	task.delay(0.4, function()
		if not overlay.Visible then return end
		reportGeometry("tab changed", true)
		print("QUALITY_SHOP_TAB_OBSERVED", panel:GetAttribute("SelectedTab"))
	end)
end)
for _, section in sections do
	local page = section.page
	local lastPosition = page.CanvasPosition
	local pending = false
	page:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if pending then return end
		pending = true
		local previous = lastPosition
		task.delay(0.2, function()
			pending = false
			local position = page.CanvasPosition
			lastPosition = position
			if overlay.Visible and page.Visible and math.abs(position.Y - previous.Y) > 1 then
				print("QUALITY_SCROLL_OBSERVED", section.name, previous.Y, position.Y, "Native canvas moved; document the actual input separately")
			end
		end)
	end)
end
for _, button in previewButtons do
	button.Activated:Connect(function()
		task.defer(function()
			assert(string.find(panel.Footer.Text, "Coming soon", 1, true) ~= nil, "QUALITY_UI_FAIL: preview CTA must acknowledge Coming soon")
			print("QUALITY_PREVIEW_CTA_OBSERVED", button.Parent.Name, player:GetAttribute("Souls"), "Actual Activated event; purchase exclusion is a static check")
		end)
	end)
end
for _, shell in { cursesOverlay, settingsOverlay } do
	shell:GetPropertyChangedSignal("Visible"):Connect(function()
		task.delay(0.4, function()
			reportGeometry("shell visibility changed", overlay.Visible)
			print("QUALITY_SHELL_VISIBILITY_OBSERVED", shell.Name, shell.Visible)
		end)
	end)
end

local sawShopOpen = overlay.Visible
overlay:GetPropertyChangedSignal("Visible"):Connect(function()
	local visible = overlay.Visible
	task.delay(0.4, function()
		if overlay.Visible ~= visible then return end
		reportGeometry("shop visibility changed", visible)
		if visible then
			sawShopOpen = true
		elseif sawShopOpen then
			print("QUALITY_SHOP_CLOSE_OBSERVED", "Actual overlay changed from open to closed; input source must be documented separately")
		end
	end)
end)
if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		task.delay(0.4, function() reportGeometry("viewport resized", overlay.Visible) end)
	end)
end
player:GetAttributeChangedSignal("SoulsPerSecond"):Connect(function()
	task.delay(0.35, function()
		local value = player:GetAttribute("SoulsPerSecond")
		assert(typeof(value) == "number" and rate.Text == expectedRate(value), "QUALITY_UI_FAIL: updated rate text mismatch")
		print("QUALITY_UI_RATE_PASS", value)
	end)
end)
animated:GetPropertyChangedSignal("Value"):Connect(function()
	task.defer(function()
		assert(amount.Text == NumberFormat.compact(animated.Value), "QUALITY_UI_FAIL: animated amount text mismatch")
	end)
end)
