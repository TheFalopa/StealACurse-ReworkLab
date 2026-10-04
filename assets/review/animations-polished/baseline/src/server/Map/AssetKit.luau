local ServerStorage = game:GetService("ServerStorage")

local AssetKit = {}

-- Inscribed, normalized boxes approximate the solid part of each authored
-- module. Never use the whole doorway/tree bounds: that would fill openings or
-- turn decorative branches into invisible walls. These are built once only.
local COLLISION_PROFILES = {
	final_gothic_doorway = {
		{ size = Vector3.new(0.16, 0.60, 0.73), offset = Vector3.new(-0.415, -0.20, 0) },
		{ size = Vector3.new(0.16, 0.60, 0.73), offset = Vector3.new(0.415, -0.20, 0) },
	},
	final_buttress = {
		{ size = Vector3.new(0.94, 0.22, 0.85), offset = Vector3.new(0, -0.39, 0) },
		{ size = Vector3.new(0.66, 0.52, 0.43), offset = Vector3.new(0, -0.06, 0.12) },
		{ size = Vector3.new(0.37, 0.25, 0.38), offset = Vector3.new(0, 0.375, 0.12) },
	},
	final_iron_fence = {
		-- A thin continuous panel stops players between bars, below spear tips.
		{ size = Vector3.new(0.96, 0.80, 0.32), offset = Vector3.new(0, -0.10, 0) },
	},
	final_collection_pedestal = {
		{ size = Vector3.new(0.78, 0.18, 0.78), offset = Vector3.new(0, -0.41, 0) },
		{ size = Vector3.new(0.62, 0.60, 0.62), offset = Vector3.new(0, -0.02, 0) },
		{ size = Vector3.new(0.78, 0.18, 0.78), offset = Vector3.new(0, 0.41, 0) },
	},
	final_hero_grave = {
		{ size = Vector3.new(0.90, 0.10, 0.86), offset = Vector3.new(0, -0.45, 0) },
		{ size = Vector3.new(0.66, 0.64, 0.45), offset = Vector3.new(0, -0.08, 0) },
	},
	stone_warden = {
		{ size = Vector3.new(0.66, 0.64, 0.65), offset = Vector3.new(0, -0.18, 0) },
	},
	final_giant_tree = {
		-- Only the low central trunk; the roots/branches are intentionally soft.
		{ size = Vector3.new(0.13, 0.15, 0.17), offset = Vector3.new(0.014, -0.425, 0.015) },
	},
	final_cliff_cluster = {
		{ size = Vector3.new(0.30, 0.45, 0.43), offset = Vector3.new(-0.28, -0.275, 0.05) },
		{ size = Vector3.new(0.40, 0.67, 0.50), offset = Vector3.new(0, -0.165, 0) },
		{ size = Vector3.new(0.26, 0.36, 0.43), offset = Vector3.new(0.31, -0.32, 0.05) },
	},
}

local SOFT_TEMPLATES = {
	final_pumpkin = true, root_serpent = true, rock_crag = true,
	grave_arched = true, grave_spire = true, grave_broken = true,
	tree_widow = true, tree_claw = true, tree_sundered = true,
	foliage_crescent = true, foliage_tattered = true, foliage_swept = true,
}

local function multiply(a: Vector3, b: Vector3): Vector3
	return Vector3.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end

local function addCollision(mesh: MeshPart, templateName: string, settings: { [string]: any })
	local profile = COLLISION_PROFILES[templateName]
	if templateName == "rock_crag" and mesh.Size.Y >= 3 and math.min(mesh.Size.X, mesh.Size.Z) >= 4 then
		profile = { { size = Vector3.new(0.63, 0.60, 0.60), offset = Vector3.new(0, -0.20, 0) } }
	end
	if settings.collision == "none" or settings.canCollide == false then
		profile = nil
	end
	mesh:SetAttribute("CollisionCategory", if profile then "Blocking" else (if SOFT_TEMPLATES[templateName] then "Soft" else "NonBlocking"))
	mesh:SetAttribute("CollisionHullCount", if profile then #profile else 0)
	if not profile then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "CollisionHulls"
	folder.Parent = mesh
	for index, descriptor in ipairs(profile) do
		local hull = Instance.new("Part")
		hull.Name = string.format("CollisionHull_%02d", index)
		hull.Size = multiply(mesh.Size, descriptor.size)
		hull.CFrame = mesh.CFrame * CFrame.new(multiply(mesh.Size, descriptor.offset))
		hull.Anchored = true
		hull.CanCollide = true
		hull.CanQuery = true
		hull.CanTouch = false
		hull.Transparency = 1
		hull.CastShadow = false
		hull.TopSurface = Enum.SurfaceType.Smooth
		hull.BottomSurface = Enum.SurfaceType.Smooth
		hull:SetAttribute("EnvironmentCollisionHull", true)
		hull:SetAttribute("CollisionSource", templateName)
		hull:SetAttribute("CollisionCategory", "Blocking")
		hull.Parent = folder
	end
end

-- Templates are imported MeshParts stored by Rojo under ServerStorage.MapMeshKit.
-- No ID is guessed here: until a verified template exists, callers can build
-- a small native fallback rather than produce an invisible or broken map.
function AssetKit.place(
	parent: Instance,
	name: string,
	templateName: string,
	size: Vector3,
	frame: CFrame,
	color: Color3,
	material: Enum.Material,
	options: { [string]: any }?
): MeshPart?
	local folder = ServerStorage:FindFirstChild("MapMeshKit")
	local template = folder and folder:FindFirstChild(templateName)
	if not template or not template:IsA("MeshPart") then
		return nil
	end
	local settings = options or {}
	local mesh = template:Clone()
	mesh.Name = name
	mesh.Size = size
	mesh.CFrame = frame
	mesh.Color = color
	mesh.Material = material
	mesh.Anchored = true
	-- Decorative source triangles never participate in exact mesh collision.
	mesh.CanCollide = false
	mesh.CanQuery = false
	mesh.CanTouch = false
	mesh.CastShadow = settings.castShadow ~= false
	mesh.Transparency = settings.transparency or 0
	mesh:SetAttribute("SourceTemplate", templateName)
	mesh:SetAttribute("SourceTemplateID", mesh.MeshId)
	addCollision(mesh, templateName, settings)
	mesh.Parent = parent
	return mesh
end

-- supportFrame contains a surface reference and desired rotation, not the
-- center of the mesh. Use the rotated bounding-box height even for tilted
-- rubble; lifting by Size.Y/2 alone leaves tilted feet hovering/buried.
-- SupportY is authored world space BEFORE Build applies MapElevation.
function AssetKit.placeGrounded(
	parent: Instance,
	name: string,
	templateName: string,
	size: Vector3,
	supportFrame: CFrame,
	color: Color3,
	material: Enum.Material,
	options: { [string]: any }?
): MeshPart?
	local settings = options or {}
	local inset = math.clamp(settings.groundInset or 0.06, 0, math.min(size.Y * 0.25, 0.65))
	local halfHeight = (math.abs(supportFrame.RightVector.Y) * size.X
		+ math.abs(supportFrame.UpVector.Y) * size.Y
		+ math.abs(supportFrame.LookVector.Y) * size.Z) / 2
	local mesh = AssetKit.place(parent, name, templateName, size,
		supportFrame + Vector3.new(0, halfHeight - inset, 0), color, material, settings)
	if mesh then
		mesh:SetAttribute("GroundedPlacement", true)
		mesh:SetAttribute("SupportY", supportFrame.Position.Y)
		mesh:SetAttribute("GroundInset", inset)
	end
	return mesh
end

return AssetKit
