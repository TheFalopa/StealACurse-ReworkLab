-- Sanctuary panel (restore / grimoire / contracts / style) in the shared UI
-- language. Presentation only: every action is the same SanctuaryRestoration
-- request as before; prompt enabling and the activity target are unchanged.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UserInput = game:GetService("UserInputService")
local Theme = require(script.Parent.Theme)
local PanelFrame = require(script.Parent.PanelFrame)
local HudLayout = require(script.Parent.HudLayout)
local Config = require(RS.Shared.SanctuaryConfig)
local Rules = require(RS.Shared.SanctuaryProgression)
local Catalog = require(RS.Shared.CurseCatalog)
local NumberFormat = require(RS.Shared.NumberFormat)
local VisualAssets = require(RS.Shared.VisualAssets)
local C, F = Theme.colors, Theme.fonts

local Panel = {}
local instance

local PAGES = {
	{ id = "UPGRADE", label = "RESTORE", title = "Restoration" },
	{ id = "GRIMOIRE", label = "GRIMOIRE", title = "Grimoire" },
	{ id = "CONTRACTS", label = "CONTRACTS", title = "Gravekeeper's Contracts" },
	{ id = "STYLE", label = "STYLE", title = "Style & Display" },
}

function Panel.start()
	if instance and instance.gui.Parent then return instance end
	local player = Players.LocalPlayer
	local remote = RS:WaitForChild("SanctuaryRestoration")
	local request = remote:WaitForChild("Request")
	local gui = Theme.make("ScreenGui", { Name = "SanctuaryRestorationUI", ResetOnSpawn = false, ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets, DisplayOrder = 30, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, player:WaitForChild("PlayerGui"))

	-- Launcher: a pill bottom-right on desktop, a 48 px icon beside the tool
	-- bar on touch (HudLayout places it).
	local launch = Theme.make("TextButton", {
		Name = "OpenSanctuary", Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -16),
		Size = UDim2.fromOffset(210, 44), BackgroundColor3 = C.panel, BorderSizePixel = 0,
	}, gui)
	Theme.corner(launch, 12)
	Theme.gradient(launch, Color3.fromRGB(46, 34, 76), Color3.fromRGB(16, 13, 30))
	local launchStroke = Theme.stroke(launch, C.line, 1.4, 0.2)
	local launchIcon = Theme.image(launch, "Icon", VisualAssets.Icons.sanctuary, UDim2.fromOffset(6, 5), UDim2.fromOffset(34, 34))
	local launchText = Theme.label(launch, "Label", "SANCTUARY", UDim2.fromOffset(44, 0), UDim2.new(1, -52, 1, 0), 15, C.white, F.heavy)
	-- Touch: seal fragments as a badge on the icon.
	local launchBadge = Theme.label(launch, "Fragments", "", UDim2.new(1, -2, 0, 2), UDim2.fromOffset(0, 16), 12, C.white, F.heavy)
	launchBadge.AnchorPoint = Vector2.new(1, 0)
	launchBadge.AutomaticSize = Enum.AutomaticSize.X
	launchBadge.BackgroundColor3 = C.ink
	launchBadge.BackgroundTransparency = 0.1
	launchBadge.Visible = false
	launchBadge.ZIndex = 3
	Theme.corner(launchBadge, 6)
	Theme.make("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, launchBadge)
	Theme.buttonFeedback(launch, C.panel, C.cardHi, { scale = Theme.make("UIScale", { Scale = 1 }, launch), stroke = launchStroke, accent = C.cyan })

	-- Activity objective (contracts / rituals): the HUD objective slot, which it
	-- takes over from Mortimer's task tracker while active.
	local objective = Theme.label(gui, "ActivityObjective", "", UDim2.fromScale(0.5, 1), UDim2.fromOffset(520, 56), 14, C.white, F.bold)
	objective.AnchorPoint = Vector2.new(0.5, 1)
	objective.Position = UDim2.new(0.5, 0, 1, -110)
	objective.TextXAlignment = Enum.TextXAlignment.Center
	objective.TextWrapped = true
	objective.BackgroundColor3 = C.ink
	objective.BackgroundTransparency = 0.15
	objective.Visible = false
	Theme.corner(objective, 12)
	Theme.stroke(objective, C.cyan, 1.2, 0.4)
	local targetBillboard = Theme.make("BillboardGui", { Name = "ActivityTarget", Size = UDim2.fromOffset(170, 42), StudsOffsetWorldSpace = Vector3.new(0, 5, 0), AlwaysOnTop = true, LightInfluence = 0, MaxDistance = 700, Enabled = false }, gui)
	local targetLabel = Theme.make("TextLabel", { Name = "Destination", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.ink, BackgroundTransparency = 0.2, TextColor3 = C.cyan, TextSize = 13, TextWrapped = true, FontFace = F.heavy, BorderSizePixel = 0 }, targetBillboard)
	Theme.corner(targetLabel, 8)

	-- Modal chrome shared with the store/settings.
	local chrome = PanelFrame.create(gui, "Shade", "Panel", "Your Sanctuary", "", "sanctuary", C.cyan, function() end)
	local shade, panel = chrome.overlay, chrome.panel
	local function setOpen(v)
		chrome.show(v)
	end
	panel.CloseButton.Activated:Connect(function() setOpen(false) end)
	shade.Backdrop.Activated:Connect(function() setOpen(false) end)
	local resource = panel:FindFirstChild("Subtitle")
	local tabBar = Theme.make("Frame", { Name = "Tabs", BackgroundColor3 = C.ink, BackgroundTransparency = 0.2, BorderSizePixel = 0, Position = UDim2.fromOffset(14, 84), Size = UDim2.new(1, -28, 0, 40), ZIndex = 22 }, panel)
	Theme.corner(tabBar, 12)
	Theme.stroke(tabBar, C.line, 1, 0.5)
	local selector = Theme.make("Frame", { Name = "Selector", BackgroundColor3 = C.cardHi, BorderSizePixel = 0, Position = UDim2.fromOffset(4, 4), Size = UDim2.new(0.25, -6, 1, -8), ZIndex = 22 }, tabBar)
	Theme.corner(selector, 9)
	Theme.stroke(selector, C.cyan, 1.2, 0.2)
	local content = Theme.make("ScrollingFrame", {
		Name = "Content", Active = true, Position = UDim2.fromOffset(14, 134), Size = UDim2.new(1, -28, 1, -180), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = C.violet, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 22,
	}, panel)
	Theme.make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, content)
	Theme.make("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10) }, content)
	local feedback = chrome.footer

	local data, page, busy = nil, "UPGRADE", false
	local render
	local sealLabel, moneyRequirement
	local index = 0
	local function clear()
		for _, child in content:GetChildren() do if child:IsA("GuiObject") then child:Destroy() end end
		content.CanvasPosition = Vector2.zero
	end
	local function heading(text, color)
		index += 1
		local l = Theme.label(content, "H" .. index, text, UDim2.new(), UDim2.new(1, -5, 0, 24), 16, color or C.white, F.heavy)
		l.LayoutOrder = index
		l.ZIndex = 23
		return l
	end
	local function paragraph(text, color, height)
		index += 1
		local label = Theme.label(content, "Text" .. index, text, UDim2.new(), UDim2.new(1, -5, 0, 0), 13, color or C.muted, F.medium)
		label.LayoutOrder = index
		label.TextWrapped = true
		label.AutomaticSize = Enum.AutomaticSize.Y
		Theme.make("UIPadding", { PaddingBottom = UDim.new(0, if (height or 40) > 30 then 4 else 0) }, label)
		label.TextYAlignment = Enum.TextYAlignment.Top
		label.ZIndex = 23
		return label
	end
	-- Requirement row: label + value + small bar.
	local function requirement(text, current, target, complete)
		index += 1
		local row = Theme.make("Frame", { Name = "Req" .. index, LayoutOrder = index, Size = UDim2.new(1, -5, 0, 34), BackgroundColor3 = C.card, BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 23 }, content)
		Theme.corner(row, 8)
		local l = Theme.label(row, "Label", (complete and "✓  " or "") .. text, UDim2.fromOffset(10, 3), UDim2.new(1, -120, 0, 18), 13, complete and C.soulGreen or C.white, F.bold)
		l.ZIndex = 24
		local v = Theme.label(row, "Value", NumberFormat.compact(math.floor(current)) .. " / " .. NumberFormat.compact(target), UDim2.new(1, -110, 0, 3), UDim2.fromOffset(100, 18), 13, C.muted, F.heavy)
		v.TextXAlignment = Enum.TextXAlignment.Right
		v.ZIndex = 24
		local back = Theme.make("Frame", { Position = UDim2.new(0, 10, 1, -9), Size = UDim2.new(1, -20, 0, 4), BackgroundColor3 = C.ink, BorderSizePixel = 0, ZIndex = 24 }, row)
		Theme.corner(back, 2)
		local fill = Theme.make("Frame", { Size = UDim2.fromScale(math.clamp(current / math.max(target, 1), 0, 1), 1), BackgroundColor3 = complete and C.soulGreen or C.cyan, BorderSizePixel = 0, ZIndex = 25 }, back)
		Theme.corner(fill, 2)
		return { row = row, label = l, value = v, fill = fill }
	end
	local function action(name, text, callback, primary)
		index += 1
		local accent = if primary then C.amber else C.line
		local button = Theme.make("TextButton", {
			Name = name, Text = text, LayoutOrder = index, Size = UDim2.new(1, -5, 0, 44), AutoButtonColor = false,
			BackgroundColor3 = if primary then C.amber else C.card, TextColor3 = if primary then C.ink else C.white,
			TextSize = 14, FontFace = F.heavy, BorderSizePixel = 0, ZIndex = 23,
		}, content)
		Theme.corner(button, 10)
		local stroke = Theme.stroke(button, accent, 1.2, if primary then 0.4 else 0.5)
		Theme.buttonFeedback(button, button.BackgroundColor3, button.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.12), { scale = Theme.make("UIScale", { Scale = 1 }, button), stroke = stroke, accent = C.white })
		button.Activated:Connect(function() if not busy then callback() end end)
		return button
	end

	local objectiveWanted = false
	local function applyObjective(layout)
		objective.Visible = objectiveWanted and (layout == nil or layout.objectiveOwner == "sanctuary")
		if not layout then return end
		HudLayout.place(objective, layout.objective)
		objective.TextSize = if layout.objective.w < 300 then 13 else 14
	end
	local function updateObjective()
		local contract = data and data.contract
		local ritual = data and data.ritual
		objectiveWanted = contract ~= nil or ritual ~= nil
		local priority = HudLayout.ObjectivePriority
		HudLayout.claimObjective("sanctuary", if ritual then priority.ritual elseif contract then priority.contract else nil)
		applyObjective(HudLayout.current())
		if ritual then
			objective.Text = ritual.title .. "  ·  " .. ritual.step .. "/" .. ritual.total .. "\nActivate altar mark " .. tostring(ritual.nextMark) .. "."
		elseif contract then
			objective.Text = contract.title .. "  ·  " .. contract.step .. "/" .. contract.total .. "\n"
				.. (if contract.carrying then "Carry " .. (player:GetAttribute("CarriedRelicName") or "the relic") .. " to " else "Go to ")
				.. tostring(contract.targetName) .. "  ·  +" .. contract.reward .. " ◇"
		end
	end
	local function resources()
		local souls = player:GetAttribute("Souls") or (data and data.souls) or 0
		local fragments = player:GetAttribute("SealFragments") or 0
		launchText.Text = string.format("SANCTUARY  ·  %d ◇", fragments)
		launchBadge.Text = string.format("%d ◇", fragments)
		if resource then
			resource.Text = string.format("Level %d  ·  %d pedestals  ·  %s Souls  ·  %d seal fragments", data and data.progress.level or 0, data and data.capacity or 5, NumberFormat.compact(math.floor(souls)), fragments)
		end
		if moneyRequirement and moneyRequirement.row.Parent then
			local met = souls >= moneyRequirement.target
			moneyRequirement.value.Text = NumberFormat.compact(math.floor(souls)) .. " / " .. NumberFormat.compact(moneyRequirement.target)
			moneyRequirement.fill.Size = UDim2.fromScale(math.clamp(souls / math.max(moneyRequirement.target, 1), 0, 1), 1)
			moneyRequirement.fill.BackgroundColor3 = if met then C.soulGreen else C.cyan
		end
	end
	local function call(actionId, value)
		if busy then return end
		busy = true
		feedback.Text = ""
		local ok, answer = pcall(function() return request:InvokeServer(actionId, value) end)
		busy = false
		if not ok or typeof(answer) ~= "table" then feedback.Text = "Could not complete that. Try again." return end
		feedback.Text = answer.message or ""
		if answer.data and answer.data.progress then data = answer.data render() end
	end
	local function currentProfile() return { souls = player:GetAttribute("Souls") or data.souls, curses = data.owned, sanctuary = data.progress } end
	local function showRequirements(rows)
		for _, row in rows do
			local r = requirement(row.label, row.current, row.target, row.complete)
			if row.kind == "SOULS" then moneyRequirement = { row = r.row, value = r.value, fill = r.fill, target = row.target } end
			if row.missing and not row.complete then
				local names = {}
				for i, id in row.missing do if i > 8 then break end table.insert(names, Catalog.Definitions[id].displayName) end
				paragraph("Options: " .. table.concat(names, ", "), C.subtle, 36)
			end
		end
	end

	render = function()
		clear()
		sealLabel, moneyRequirement, index = nil, nil, 0
		resources()
		updateObjective()
		for i, p in PAGES do
			local tab = tabBar:FindFirstChild(p.id)
			if tab then tab.TextColor3 = if p.id == page then C.white else C.subtle end
			if p.id == page then
				Theme.tween(selector, 0.18, { Position = UDim2.new((i - 1) / #PAGES, if i == 1 then 4 else 2, 0, 4) })
				chrome.heading.Text = p.title
			end
		end
		if not data then paragraph("Your account is loading.") return end
		if not data.baseId then paragraph("Claim a sanctuary to restore it. Discoveries and materials are kept.", C.amber) end
		local p = currentProfile()
		local progress = data.progress
		if page == "UPGRADE" then
			local nextStage = Config.Levels[progress.level + 1]
			if nextStage then
				heading(string.format("Level %d  ·  %s", nextStage.level, nextStage.title), C.amber)
				paragraph(nextStage.benefit, C.muted, 36)
				showRequirements(Rules.evaluate(p).requirements)
				action("Upgrade", string.format("RESTORE  ·  %s SOULS + %d ◇", NumberFormat.compact(nextStage.souls), nextStage.fragments), function() call("upgrade", tostring(progress.level)) end, true)
			else
				heading("Dominion complete: 30 pedestals.", C.soulGreen)
			end
			heading("Rituals", C.white)
			paragraph("Temporary showcases of your own Curses. Nothing is consumed.", C.muted, 22)
			if data.ritual then action("CancelRitual", "LEAVE RITUAL", function() call("ritual_cancel") end) end
			for _, id in Config.RitualOrder do
				local d = Config.Rituals[id]
				if not progress.rituals[id] and progress.level >= d.minimumLevel then
					heading(d.title, C.violet)
					paragraph(d.description, nil, 36)
					showRequirements(Rules.ritualEligibility(p, id).requirements)
					action("Ritual_" .. id, "BEGIN " .. string.upper(d.title), function()
						call("ritual_begin", id)
						if data and data.ritual then setOpen(false) end
					end)
				end
			end
			if progress.level >= Config.Protection.minimumLevel then
				local now = workspace:GetServerTimeNow()
				local seal = data.seal
				sealLabel = paragraph(if now < seal.endsAt then "Entrance sealed: " .. math.ceil(seal.endsAt - now) .. " s."
					elseif now < seal.availableAt then "Seal recharging: " .. math.ceil(seal.availableAt - now) .. " s."
					else "Seal ready. Only the owner can pass while it holds.", C.cyan, 24)
				action("Protect", "ACTIVATE TEMPORARY SEAL", function() call("seal") end)
			end
		elseif page == "GRIMOIRE" then
			heading(Rules.discoveryCount(progress) .. " / 56 species discovered", C.cyan)
			paragraph("Placing a species you own records it forever.", C.muted, 22)
			for _, id in Config.CollectionSetOrder do
				local set = Rules.setProgress(progress, id)
				requirement(set.title, set.current, set.target, set.complete)
				if not set.complete then
					local names = {}
					for i, species in set.missing do if i > 6 then break end table.insert(names, Catalog.Definitions[species].displayName) end
					paragraph("Complete with: " .. table.concat(names, ", "), C.subtle, 36)
				end
			end
			heading("Species", C.white)
			for _, id in Catalog.AllOrder do
				local d = Catalog.Definitions[id]
				local found = progress.discoveries[id]
				local rarity = Catalog.Rarities[d.rarity]
				paragraph((found and "✓  " or "·  ") .. d.displayName .. "  ·  " .. rarity.label, if found then rarity.color else C.subtle, 20)
			end
		elseif page == "CONTRACTS" then
			paragraph("Pick one at Mortimer's board. One contract at a time; materials are earned by playing.", C.muted, 36)
			if data.contract then
				local c = data.contract
				heading(c.title .. "  ·  " .. c.step .. " / " .. c.total, C.amber)
				paragraph(c.description .. "  Target: " .. tostring(c.targetName), nil, 44)
				action("RestartContract", "RESTART ACTIVITY", function() call("contract_restart") end)
				action("AbandonContract", "ABANDON  ·  KEEP MATERIALS", function() call("contract_abandon") end)
			else
				for _, id in Config.ContractOrder do
					local d = Config.Contracts[id]
					if progress.level >= d.minLevel then
						heading(d.title .. "  ·  +" .. d.rewardFragments .. " ◇", C.cyan)
						paragraph(d.description, nil, 34)
						action("Accept_" .. id, "TAKE CONTRACT", function() call("contract_accept", id) end)
					end
				end
			end
		else
			paragraph("Same capacity and protection. Changing style keeps your Curses on their pedestals.", nil, 36)
			for _, id in Config.StyleOrder do
				local d = Config.Styles[id]
				action("Style_" .. id, (progress.style == id and "✓  " or "") .. string.upper(d.title), function() call("style", id) end, progress.style == id)
			end
			heading("Featured display", C.white)
			paragraph("Highlights one real pedestal. It never copies the Curse or multiplies income.", C.muted, 36)
			action("ClearFeatured", "CLEAR FEATURED DISPLAY", function() call("featured", "") end)
			for _, r in data.owned do
				if r.state == "PLACED" then
					local floor, slot = r.pedestalId:match("^floor(%d+)-slot(%d+)$")
					local place = if floor then "Floor " .. floor .. " · pedestal " .. slot else "Pedestal"
					action("Feature_" .. r.uid, (progress.featuredUid == r.uid and "✓  " or "") .. Catalog.Definitions[r.definitionId].displayName .. "  ·  " .. place, function() call("featured", r.uid) end)
				end
			end
		end
	end

	local function show(target, snapshot)
		if snapshot then data = snapshot end
		page = target or "UPGRADE"
		setOpen(true)
		feedback.Text = ""
		if not data then call("snapshot") else render() end
	end
	for i, p in PAGES do
		local b = Theme.make("TextButton", {
			Name = p.id, Text = p.label, AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.fromScale((i - 1) / #PAGES, 0),
			Size = UDim2.fromScale(1 / #PAGES, 1), TextColor3 = C.subtle, TextSize = 13, FontFace = F.heavy, ZIndex = 23,
		}, tabBar)
		b.Activated:Connect(function() page = p.id feedback.Text = "" render() end)
	end
	launch.Activated:Connect(function() show("UPGRADE") call("snapshot") end)
	remote.Open.OnClientEvent:Connect(show)
	remote:WaitForChild("Changed").OnClientEvent:Connect(function(snapshot)
		data = snapshot
		resources()
		updateObjective()
		if shade.Visible then render() end
	end)
	player:GetAttributeChangedSignal("Souls"):Connect(resources)
	player:GetAttributeChangedSignal("SealFragments"):Connect(resources)
	UserInput.InputBegan:Connect(function(input, processed) if not processed and input.KeyCode == Enum.KeyCode.Escape then setOpen(false) end end)
	local safe = Theme.make("Frame", { Name = "SafeArea", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, gui)
	local function fit()
		local available = safe.AbsoluteSize
		if available.X <= 0 or available.Y <= 0 then return end
		local _, _, short = chrome.fit(available)
		tabBar.Position = UDim2.fromOffset(14, if short then 56 else 84)
		content.Position = UDim2.fromOffset(14, if short then 102 else 134)
		content.Size = UDim2.new(1, -28, 1, -(if short then 136 else 168))
		for _, p in PAGES do local t = tabBar:FindFirstChild(p.id) if t then t.TextSize = if available.X < 520 then 11 else 13 end end
	end
	safe:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()
	-- Launcher and objective positions come from HudLayout.
	local layoutConnection = HudLayout.observe(function(layout)
		local r = layout.launcher
		HudLayout.place(launch, r)
		launchText.Visible = not layout.touch
		launchBadge.Visible = layout.touch
		launchIcon.Position = if layout.touch then UDim2.fromOffset(math.floor((r.w - 34) / 2), math.floor((r.h - 34) / 2)) else UDim2.fromOffset(6, 5)
		applyObjective(layout)
	end)
	gui.Destroying:Connect(function()
		layoutConnection:Disconnect()
		HudLayout.claimObjective("sanctuary", nil)
	end)
	resources()
	task.spawn(function()
		while gui.Parent do
			task.wait(0.3)
			if sealLabel and sealLabel.Parent and data then
				local now = workspace:GetServerTimeNow()
				local seal = data.seal
				sealLabel.Text = if now < seal.endsAt then "Entrance sealed: " .. math.ceil(seal.endsAt - now) .. " s."
					elseif now < seal.availableAt then "Seal recharging: " .. math.ceil(seal.availableAt - now) .. " s."
					else "Seal ready. Only the owner can pass while it holds."
			end
			local contract = data and data.contract
			local ritual = data and data.ritual
			local map = workspace:FindFirstChild("StealACurseMap")
			local destination
			if map then
				local sites = map:FindFirstChild("RestorationActivities")
				if sites then
					for _, node in sites:GetChildren() do
						local marker = node:FindFirstChild("Interaction")
						local prompt = marker and marker:FindFirstChild("ContractInteraction")
						if prompt then prompt.Enabled = node.Name == "gravekeeper_board" or (contract and contract.targetNodeId == node.Name) or false end
						if contract and contract.targetNodeId == node.Name then destination = marker end
					end
				end
				local bases = map:FindFirstChild("PlayerSanctuaries")
				if bases then
					for _, base in bases:GetChildren() do
						local own = base:GetAttribute("OwnerUserId") == player.UserId
						if own then
							if ritual then destination = base:FindFirstChild("RitualMark_" .. tostring(ritual.nextMark), true)
							elseif contract and contract.targetNodeId == "sanctuary_altar" then destination = base:FindFirstChild("RestorationAltar", true) end
						end
						for _, part in base:GetDescendants() do
							if part:IsA("ProximityPrompt") and part.Name == "RestorationPrompt" then
								local isMark = part.Parent.Name:match("^RitualMark_(%d)$")
								part.Enabled = own and (not isMark or (ritual and ritual.nextMark == tonumber(isMark))) or false
							end
						end
					end
				end
			end
			targetBillboard.Enabled = destination ~= nil
			targetBillboard.Adornee = destination
			if destination then
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				local distance = root and math.floor((root.Position - destination.Position).Magnitude) or 0
				targetLabel.Text = (if ritual then "Mark " .. tostring(ritual.nextMark) else contract.targetName) .. "\n" .. distance .. " studs"
			end
		end
	end)
	task.spawn(function()
		while player:GetAttribute("ProfileStatus") ~= "READY" and gui.Parent do task.wait(0.2) end
		if gui.Parent then call("snapshot") end
	end)
	instance = { open = function() show("GRIMOIRE") call("snapshot") end, gui = gui }
	return instance
end

return Panel
