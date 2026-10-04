-- TEST-ONLY manual visual showcase. Requiring this module creates nothing.
-- Server CommandBar during Play, after the review fixture has initialized:
-- local center, ids, bounds = require(game.ServerScriptService.TestCurseGallery).create()
-- Mapping belongs only to the generated review fixture, never default.project.json.
-- This is presentation QA, not natural spawning or gameplay validation.
local Gallery = {}

type Bounds = { min: Vector3, max: Vector3 }

local function vectorText(value: Vector3): string
	return string.format("(%.3f, %.3f, %.3f)", value.X, value.Y, value.Z)
end

function Gallery.create(): (Vector3, { string }, Bounds)
	local RunService = game:GetService("RunService")
	assert(RunService:IsRunning() and RunService:IsServer(), "CURSE_GALLERY: call create() from the server during Play")
	local ServerScriptService = game:GetService("ServerScriptService")
	local ServerStorage = game:GetService("ServerStorage")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local server = ServerScriptService:FindFirstChild("Server")
	local gameplay = server and server:FindFirstChild("Gameplay")
	assert(gameplay and gameplay:FindFirstChild("CurseVisualService"), "CURSE_GALLERY: production visual module is missing")
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	assert(shared and shared:FindFirstChild("CurseCatalog"), "CURSE_GALLERY: shared catalog is missing")
	local Catalog = require(shared.CurseCatalog)
	local Visual = require(gameplay.CurseVisualService)
	local kit = ServerStorage:FindFirstChild("CurseMeshKit")
	assert(kit and #Catalog.FirstWaveOrder == 15, "CURSE_GALLERY: expected fifteen first-wave templates")
	assert(not workspace:FindFirstChild("ExpansionReviewGallery"), "CURSE_GALLERY: showcase already exists; reuse it or remove only that test folder manually")

	-- Preflight the whole wave before constructing anything. No enabling catalog
	-- entries, purchase/service calls, globals, remotes or live lifecycle hooks.
	for _, id in Catalog.FirstWaveOrder do
		local definition = Catalog.Definitions[id]
		assert(definition and definition.isExpansion and definition.productionWave == 1, "CURSE_GALLERY: invalid first-wave definition " .. id)
		assert(definition.implementationStatus == "IMPORTED" or definition.implementationStatus == "VALIDATED", "CURSE_GALLERY: actual import required for " .. id)
		local template = kit:FindFirstChild(definition.visualKey)
		assert(template and template:IsA("MeshPart") and string.match(template.MeshId, "^rbxassetid://[1-9]%d*$"), "CURSE_GALLERY: imported MeshPart missing for " .. id)
		assert(template.Size.Magnitude < 7 and math.min(template.Size.X, template.Size.Y, template.Size.Z) > 0, "CURSE_GALLERY: invalid mesh bounds for " .. id)
		assert(template.MeshSize.Magnitude > 0 and (template.Size - template.MeshSize).Magnitude < 0.02, "CURSE_GALLERY: Size/MeshSize mismatch for " .. id)
	end

	local folder = Instance.new("Folder")
	folder.Name = "ExpansionReviewGallery"
	folder:SetAttribute("TestReviewOnly", true)
	folder:SetAttribute("PresentationOnly", true)
	folder:SetAttribute("GameplayValidated", false)
	folder:SetAttribute("ModelCount", 15)

	local base = Vector3.new(500, 1, 0)
	local floor = Instance.new("Part")
	floor.Name = "ReviewFloor"
	floor.Size = Vector3.new(60, 0.35, 40)
	floor.Position = base - Vector3.new(0, floor.Size.Y * 0.5, 0)
	floor.Material = Enum.Material.Slate
	floor.Color = Color3.fromRGB(41, 31, 57)
	floor.Anchored = true
	floor.CanCollide = false
	floor.CanTouch = false
	floor.CanQuery = false
	floor.CastShadow = false
	floor.Parent = folder

	local ids = {}
	local bounds: Bounds = {
		min = Vector3.new(math.huge, math.huge, math.huge),
		max = Vector3.new(-math.huge, -math.huge, -math.huge),
	}
	for index, id in Catalog.FirstWaveOrder do
		local definition = Catalog.Definitions[id]
		local model, prompt = Visual.create(definition, folder)
		local root = model.PrimaryPart
		assert(root and root:IsA("MeshPart"), "CURSE_GALLERY: visual root missing for " .. id)
		prompt.Enabled = false
		model:SetAttribute("CurseState", "REVIEW_ONLY")
		model:SetAttribute("DefinitionId", id)
		model:SetAttribute("TestReviewOnly", true)
		model:SetAttribute("ImplementationStage", definition.implementationStatus)
		model:SetAttribute("GameplayEnabled", false)

		local column = (index - 1) % 5
		local row = math.floor((index - 1) / 5)
		local at = base + Vector3.new((column - 2) * 10, root.Size.Y * 0.5 + 0.15, (row - 1) * 10)
		model:PivotTo(CFrame.new(at))
		local info = model:FindFirstChild("CurseInfo")
		if info and info:IsA("BillboardGui") then
			info.MaxDistance = 65
			local panel = info:FindFirstChild("Panel")
			local stage = panel and panel:FindFirstChild("InfoPrice")
			if stage and stage:IsA("TextLabel") then
				stage.Text = definition.implementationStatus .. " / REVIEW ONLY"
				stage.TextSize = 11
			end
		end

		-- Bounds describe the actual mesh/glint presentation, not label UI or
		-- the floor. Every showcase model has the unchanged front-facing pose.
		local frame, size = model:GetBoundingBox()
		local low, high = frame.Position - size * 0.5, frame.Position + size * 0.5
		bounds.min = Vector3.new(math.min(bounds.min.X, low.X), math.min(bounds.min.Y, low.Y), math.min(bounds.min.Z, low.Z))
		bounds.max = Vector3.new(math.max(bounds.max.X, high.X), math.max(bounds.max.Y, high.Y), math.max(bounds.max.Z, high.Z))
		table.insert(ids, id)
		print("CURSE_GALLERY_ITEM", id, root.MeshId, "size=" .. vectorText(root.Size), "stage=" .. definition.implementationStatus, "presentationOnly=true")
	end

	local center = (bounds.min + bounds.max) * 0.5
	folder:SetAttribute("ReviewCenter", center)
	folder:SetAttribute("ReviewBoundsMin", bounds.min)
	folder:SetAttribute("ReviewBoundsMax", bounds.max)
	-- This folder is deliberately a direct Workspace child, not map content
	-- or ActiveCurses. It cannot be picked up by the production income/route pool.
	folder.Parent = workspace
	print("CURSE_GALLERY_READY", "models=" .. #ids, "center=" .. vectorText(center), "min=" .. vectorText(bounds.min), "max=" .. vectorText(bounds.max), "presentationOnly=true; gameplayValidated=false")
	return center, ids, bounds
end

return Gallery
