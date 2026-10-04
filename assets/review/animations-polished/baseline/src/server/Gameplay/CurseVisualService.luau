local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Catalog = require(ReplicatedStorage.Shared.CurseCatalog)
local Presentation = require(ReplicatedStorage.Shared.CurseVisualPass2)

local Visual = {}

local function label(parent: Instance, name: string, y: number, height: number, font: Enum.Font, size: number, color: Color3): TextLabel
	local text = Instance.new("TextLabel")
	text.Name = name
	text.BackgroundTransparency = 1
	text.Position = UDim2.fromOffset(8, y)
	text.Size = UDim2.new(1, -16, 0, height)
	text.Font = font
	text.TextSize = size
	text.TextColor3 = color
	text.TextStrokeColor3 = Color3.fromRGB(20, 12, 34)
	text.TextStrokeTransparency = 0.4
	text.TextXAlignment = Enum.TextXAlignment.Center
	text.TextTruncate = Enum.TextTruncate.AtEnd
	text.Parent = parent
	return text
end

local function accent(parent: Model, name: string, size: Vector3, offset: Vector3, color: Color3, shape: Enum.PartType?): Part
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.CFrame = CFrame.new(offset)
	item.Color = color
	item.Material = Enum.Material.Neon
	item.Shape = shape or Enum.PartType.Block
	item.Anchored = true
	item.CanCollide = false
	item.CanTouch = false
	item.CanQuery = false
	item.CastShadow = false
	item.Transparency = 0.12
	item.Parent = parent
	return item
end

local function addIdentityAccents(model: Model, definition, root: MeshPart)
	if definition.visualPass2 then
		local hook = Instance.new("Attachment")
		hook.Name = "CurseVFXHook"
		hook.Position = definition.vfxHook
		hook:SetAttribute("VFXProfile", definition.vfxProfile)
		hook.Parent = root
		for name, point in definition.vfxHooks or {} do
			local detail = Instance.new("Attachment")
			detail.Name = "VFX_" .. name
			detail.Position = point
			detail.Parent = root
		end
		return
	end
	local size = root.Size
	local rarity = Catalog.Rarities[definition.rarity]
	local front = -size.Z * 0.5 - 0.055
	if definition.id == "cursed_doll" then
		accent(model, "UnevenSpectralEye", Vector3.new(0.24, 0.25, 0.1), Vector3.new(size.X * 0.19, size.Y * 0.13, front), rarity.glow, Enum.PartType.Ball)
	elseif definition.id == "haunted_mirror" then
		local sheen = accent(model, "MirrorSheen", Vector3.new(size.X * 0.55, size.Y * 0.52, 0.08), Vector3.new(0, size.Y * 0.04, front), rarity.glow)
		sheen.Transparency = 0.52
	elseif definition.id == "crying_mask" then
		for _, side in ipairs({ -1, 1 }) do
			accent(model, side < 0 and "LeftSpectralTear" or "RightSpectralTear", Vector3.new(0.12, size.Y * 0.37, 0.09), Vector3.new(side * size.X * 0.2, -size.Y * 0.17, front), rarity.glow)
		end
	elseif definition.id == "watching_eye" then
		accent(model, "WatchfulPupil", Vector3.new(0.65, 0.65, 0.12), Vector3.new(0, 0, front), rarity.glow, Enum.PartType.Ball)
	elseif definition.id == "soul_chains" then
		-- The original mesh contains a solid ward/core at its center. Place the
		-- glow on the front surface so that it is not buried inside that mesh.
		accent(model, "BoundSoul", Vector3.new(0.65, 0.65, 0.65), Vector3.new(0, 0, front), rarity.glow, Enum.PartType.Ball)
	elseif definition.id == "the_void" then
		accent(model, "ImpossibleCore", Vector3.new(1.05, 1.05, 1.05), Vector3.new(0, 0, front), rarity.glow, Enum.PartType.Ball)
		local light = Instance.new("PointLight")
		light.Name = "VoidGlow"
		light.Color = rarity.glow
		light.Range = 10
		light.Brightness = 0.55
		light.Shadows = false
		light.Parent = root
	elseif definition.isExpansion then
		-- Origin-relative focal point authored with the actual reworked FBX.
		-- Presentation is client-local and shares one distance-limited update.
		local hook = Instance.new("Attachment")
		hook.Name = "CurseVFXHook"
		hook.Position = definition.vfxHook
		hook:SetAttribute("VFXProfile", definition.vfxProfile)
		hook.Parent = root
		for name, point in definition.vfxHooks or {} do
			local detail = Instance.new("Attachment")
			detail.Name = "VFX_" .. name
			detail.Position = point
			detail.Parent = root
		end
	end
end

function Visual.create(definition, parent: Instance): (Model, ProximityPrompt)
	local kit = ServerStorage:FindFirstChild("CurseMeshKit")
	assert(kit, "ServerStorage.CurseMeshKit is missing; verified original Curse templates are required")
	local template = kit:FindFirstChild(definition.visualKey)
	assert(template and template:IsA("MeshPart"), "Missing verified Curse MeshPart template: " .. definition.visualKey)
	assert(template.MeshId ~= "", "Curse MeshPart has no imported MeshId: " .. definition.visualKey)
	assert(template.Size.X <= 11.01 and template.Size.Y <= 13.01 and template.Size.Z <= 6.01,
		"Curse authored bounds exceed the reviewed presentation space: " .. definition.visualKey)
	if definition.isExpansion or definition.visualPass2 then
		assert(template.MeshId == definition.meshId, "Template does not match current-source import: " .. definition.visualKey)
		assert(definition.implementationStatus == "IMPORTED" or definition.implementationStatus == "VALIDATED",
			"Expansion Curse requires an actual verified Studio import: " .. definition.visualKey)
		assert(definition.originalVertexColors, "Expansion Curse needs reviewed original material colors: " .. definition.visualKey)
		-- InitialSize is Rojo's serialized field, not a public runtime member.
		assert(template.MeshSize.Magnitude > 0 and (template.Size - template.MeshSize).Magnitude < 0.02,
			"Expansion template Size and imported MeshSize must match: " .. definition.visualKey)
	end

	local model = Instance.new("Model")
	model.Name = definition.displayName
	model:SetAttribute("CurseState", "PROCESSION")
	model:SetAttribute("CurseId", definition.id)
	if definition.isExpansion or definition.visualPass2 then model:SetAttribute("FbxSha256", definition.fbxSha256) end
	local root = template:Clone()
	root.Name = "CurseMesh"
	root.CFrame = CFrame.new()
	-- Preserve the original six's native tint. New imported meshes carry their
	-- authored color gradients in the mesh; white avoids multiplying them away.
	root.Color = if definition.originalVertexColors then Color3.new(1, 1, 1) else definition.modelColor
	local scale = Presentation.scale(definition.id, template.Size)
	root.Size = template.Size * scale
	model:SetAttribute("PresentationScale", scale)
	model:SetAttribute("VFXGeometryScale", definition.vfxGeometryScale or 1)
	root.Material = Enum.Material.SmoothPlastic
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.CastShadow = false
	root.Parent = model
	-- The server moves only this invisible authority anchor. The mesh transform
	-- is written by one client presentation controller, never by server PivotTo.
	local anchor = Instance.new("Part")
	anchor.Name = "CurseAnchor"
	anchor.Size = root.Size
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.CastShadow = false
	anchor.Parent = model
	model.PrimaryPart = anchor
	root.Transparency = 1
	model:SetAttribute("MotionFormat", 1)
	model:SetAttribute("MotionRevision", 0)
	addIdentityAccents(model, definition, root)
	for _, item in root:GetChildren() do
		if item:IsA("Attachment") then item.Position *= scale end
	end

	local rarity = Catalog.Rarities[definition.rarity]
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "CurseInfo"
	billboard.Adornee = root
	billboard.Size = UDim2.fromOffset(152, 66)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, root.Size.Y * 0.5 + 2.2, 0)
	billboard.MaxDistance = 48
	billboard.AlwaysOnTop = false
	billboard.Parent = model
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundColor3 = Color3.fromRGB(28, 19, 45)
	panel.BackgroundTransparency = 0.13
	panel.BorderSizePixel = 0
	panel.Parent = billboard
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = rarity.glow
	stroke.Thickness = 1
	stroke.Transparency = 0.14
	stroke.Parent = panel

	local nameLabel = label(panel, "InfoName", 2, 20, Enum.Font.GothamBold, 14, Color3.fromRGB(255, 246, 255))
	nameLabel.Text = string.upper(definition.displayName)
	nameLabel.TextScaled = true
	local nameSize = Instance.new("UITextSizeConstraint")
	nameSize.MinTextSize = 10
	nameSize.MaxTextSize = 14
	nameSize.Parent = nameLabel
	label(panel, "InfoRarity", 22, 12, Enum.Font.GothamBold, 9, rarity.color).Text = rarity.label
	label(panel, "InfoIncome", 34, 14, Enum.Font.GothamMedium, 11, Color3.fromRGB(158, 246, 226)).Text = "+" .. NumberFormat.compact(definition.baseSoulsPerSecond) .. " Souls/s"
	local priceLabel = label(panel, "InfoPrice", 48, 14, Enum.Font.GothamBold, 11, Color3.fromRGB(255, 222, 151))
	priceLabel.Text = NumberFormat.compact(definition.price) .. " Souls"
	priceLabel.TextTruncate = Enum.TextTruncate.None

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyCurse"
	prompt.ActionText = "Buy for " .. NumberFormat.compact(definition.price) .. " Souls"
	prompt.ObjectText = definition.displayName
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.UIOffset = Vector2.new(0, 100)
	prompt.RequiresLineOfSight = false
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	prompt.Parent = anchor

	model.Parent = parent
	if definition.isExpansion or definition.visualPass2 then CollectionService:AddTag(model, "ExpansionCurseVFX") end
	return model, prompt
end

function Visual.move(model: Model, frame: CFrame, intentional: boolean?)
	local anchor = model.PrimaryPart
	if anchor then anchor.CFrame = frame end
	if intentional then
		model:SetAttribute("MotionRevision", (model:GetAttribute("MotionRevision") or 0) + 1)
	end
end

function Visual.setState(model: Model, definition, state: string)
	model:SetAttribute("CurseState", state)
	local billboard = model:FindFirstChild("CurseInfo")
	local panel = billboard and billboard:FindFirstChild("Panel")
	local price = panel and panel:FindFirstChild("InfoPrice")
	local prompt = model.PrimaryPart and model.PrimaryPart:FindFirstChild("BuyCurse")
	if price and price:IsA("TextLabel") then
		-- The purchase toast already explains delivery. Keep all four product
		-- fields readable on the compact tag in every ownership state.
		price.Text = NumberFormat.compact(definition.price) .. " Souls"
		price.TextSize = 11
		price.TextTruncate = Enum.TextTruncate.None
	end
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Enabled = state == "PROCESSION"
	end
end

function Visual.pulse(parent: Instance, position: Vector3, color: Color3)
	local orb = Instance.new("Part")
	orb.Name = "CursePulse"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(0.7, 0.7, 0.7)
	orb.CFrame = CFrame.new(position)
	orb.Color = color
	orb.Material = Enum.Material.Neon
	orb.Transparency = 0.45
	orb.Anchored = true
	orb.CanCollide = false
	orb.CanTouch = false
	orb.CanQuery = false
	orb.CastShadow = false
	orb.Parent = parent
	TweenService:Create(orb, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(5.5, 5.5, 5.5),
		Transparency = 1,
	}):Play()
	task.delay(0.7, function()
		orb:Destroy()
	end)
end

return Visual
