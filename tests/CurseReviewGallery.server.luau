-- Optional presentation fixture only. Production initialization and the real
-- weighted procession keep running. These five Visual.create clones have no
-- CurseService record, owner, delivery, earnings or active purchase prompt.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CurseCatalog"))
local server = ServerScriptService:WaitForChild("Server")
local Visual = require(server:WaitForChild("Gameplay"):WaitForChild("CurseVisualService"))
local map = workspace:WaitForChild("StealACurseMap", 40)
local active = map:WaitForChild("ActiveCurses", 30)
local kit = ServerStorage:WaitForChild("CurseMeshKit")
local configuration = HttpService:JSONDecode(ReplicatedStorage.CurseReviewGalleryConfig.Value)
local ids = { "candle_wisp", "pale_gramophone", "thorn_cathedral", "cathedral_heart", "the_last_star" }
local function vector(value) return { value.X, value.Y, value.Z } end
local function frame(value) return { value:GetComponents() } end
local metadata = { schemaVersion = 1, presentationOnly = true, gameplayValidatedByGallery = false,
	productionInitializationUnchanged = true, naturalWeightedProcessionUnchanged = true,
	ownedDisplaysAdded = 0, incomeCreatedByGallery = 0, builtAtUtc = configuration.builtAtUtc,
	sourceFingerprints = configuration.sourceFingerprints, displays = {}, catalog = {}, templates = {},
	labelScope = "PROCESSION display labels with inactive BuyCurse; no private CurseService record or owner",
	cameraScope = "Manual client Scriptable camera only; no character move or avatar modification" }
local output = Instance.new("StringValue")
output.Name = "CurseReviewGalleryMetadata"; output.Parent = ReplicatedStorage
local supports = Instance.new("Folder")
supports.Name = "CurseReviewGallerySupports"; supports:SetAttribute("PresentationOnly", true)
supports.Parent = workspace
local ray = RaycastParams.new()
ray.FilterType = Enum.RaycastFilterType.Include
ray.FilterDescendantsInstances = { map:WaitForChild("Ground"), map:WaitForChild("CemeteryTerrain"), map:WaitForChild("Paths") }
ray.RespectCanCollide = true

-- Capture actual loaded metadata, including the six original definitions.
assert(#Catalog.AllOrder == 56 and #Catalog.ExpansionOrder == 50, "Gallery requires all56 actual loaded definitions")
for _, id in Catalog.AllOrder do
	local definition = Catalog.Definitions[id]
	local template = kit:FindFirstChild(definition.visualKey)
	assert(template and template:IsA("MeshPart") and template.MeshId ~= "", "Actual gallery template missing: " .. id)
	table.insert(metadata.catalog, { id = id, displayName = definition.displayName, rarity = definition.rarity,
		enabled = definition.enabled ~= false, spawnWeight = definition.spawnWeight,
		implementationStatus = definition.implementationStatus or "ORIGINAL",
		meshId = template.MeshId, fbxSha256 = definition.fbxSha256 or "",
		price = definition.price, income = definition.baseSoulsPerSecond,
		futureEffectId = definition.futureEffectId, isExpansion = definition.isExpansion == true })
	if definition.isExpansion then
		table.insert(metadata.templates, { id = id, templateMeshId = template.MeshId,
			size = vector(template.Size), meshSize = vector(template.MeshSize),
			definitionMeshId = definition.meshId, fbxSha256 = definition.fbxSha256 })
	end
end
metadata.catalogCount = #metadata.catalog; metadata.templateCount = #metadata.templates
metadata.enabledSpawnIds = Catalog.enabledSpawnIds()
metadata.enabledSpawnCount = #metadata.enabledSpawnIds

for index, id in ids do
	local definition = Catalog.Definitions[id]
	assert(definition and definition.isExpansion and definition.originalVertexColors,
		"Gallery requires original painted current-source import: " .. id)
	assert(definition.implementationStatus == "IMPORTED" or definition.implementationStatus == "VALIDATED",
		"Gallery needs actual recorded import: " .. id)
	local at = Vector3.new((index-3)*12, 0, 78)
	local hit = workspace:Raycast(at + Vector3.new(0, 150, 0), Vector3.new(0, -300, 0), ray)
	assert(hit and hit.Instance:IsA("BasePart"), "Gallery requires actual world support at " .. id)
	local platform = Instance.new("Part")
	platform.Name = "ReviewPlatform_" .. id; platform.Size = Vector3.new(8, .5, 8)
	platform.CFrame = CFrame.new(at.X, hit.Position.Y+.25, at.Z)
	platform.Anchored = true; platform.CanCollide = false; platform.CanTouch = false; platform.CanQuery = false
	platform.CastShadow = false; platform.Material = Enum.Material.Slate
	platform.Color = Color3.fromRGB(61, 52, 73); platform:SetAttribute("PresentationOnly", true)
	platform.Parent = supports
	local model, prompt = Visual.create(definition, active)
	model.Name = "ReviewGallery_" .. id
	model:SetAttribute("PresentationOnly", true); model:SetAttribute("TestReviewOnly", true)
	model:SetAttribute("GalleryId", id); model:SetAttribute("GameplayRecordCreated", false)
	Visual.setState(model, definition, "PROCESSION"); prompt.Enabled = false
	local root = model.PrimaryPart
	assert(root.MeshId == definition.meshId and root.Color == Color3.new(1, 1, 1)
		and root.Material == Enum.Material.SmoothPlastic and (root.Size-root.MeshSize).Magnitude < .02,
		"Gallery must preserve actual original painted mesh: " .. id)
	model:PivotTo(CFrame.new(at.X, hit.Position.Y+.5+root.Size.Y*.5+.18, at.Z) * CFrame.Angles(0, math.pi, 0))
	local target = root.Position + Vector3.new(0, .5, 0)
	local radius, angle = math.sqrt(11*11-2.2*2.2), math.rad(15)
	local cameraPosition = target + root.CFrame:VectorToWorldSpace(Vector3.new(radius*math.sin(angle), 2.2, -radius*math.cos(angle)))
	local cameraFrame = CFrame.lookAt(cameraPosition, target)
	table.insert(metadata.displays, { id = id, displayName = definition.displayName, rarity = definition.rarity,
		modelPath = model:GetFullName(), meshId = root.MeshId, fbxSha256 = model:GetAttribute("FbxSha256"),
		size = vector(root.Size), meshSize = vector(root.MeshSize), material = root.Material.Name,
		color = { root.Color.R, root.Color.G, root.Color.B }, rootPosition = vector(root.Position), rootCFrame = frame(root.CFrame),
		cameraPosition = vector(cameraPosition), cameraTarget = vector(target), cameraCFrame = frame(cameraFrame),
		cameraDistanceStuds = (cameraPosition-target).Magnitude, frontAngleDegrees = 15,
		supportY = hit.Position.Y, supportPart = hit.Instance:GetFullName(), promptEnabled = prompt.Enabled,
		presentationOnly = true, ownershipRecordCreated = false, state = model:GetAttribute("CurseState") })
end
metadata.displayCount = #metadata.displays
metadata.phase = "ready"
output.Value = HttpService:JSONEncode(metadata)
output:SetAttribute("Phase", "ready"); output:SetAttribute("PresentationOnly", true)
output:SetAttribute("DisplayCount", 5); output:SetAttribute("CatalogCount", 56)
output:SetAttribute("TemplateCount", 50); output:SetAttribute("EnabledSpawnCount", metadata.enabledSpawnCount)
print("CURSE_REVIEW_GALLERY_READY", "five original painted displays; actual loaded catalog", metadata.catalogCount,
	"enabled weighted definitions", metadata.enabledSpawnCount, "no ownership/income/purchase records")
