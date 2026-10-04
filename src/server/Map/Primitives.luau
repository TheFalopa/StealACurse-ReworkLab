local Primitives = {}

function Primitives.model(parent: Instance, name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

function Primitives.folder(parent: Instance, name: string): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

function Primitives.part(
	parent: Instance,
	name: string,
	size: Vector3,
	frame: CFrame,
	color: Color3,
	material: Enum.Material,
	options: { [string]: any }?
): BasePart
	local settings = options or {}
	local item = Instance.new(settings.className or "Part") :: BasePart
	item.Name = name
	item.Size = size
	item.CFrame = frame
	item.Color = color
	item.Material = material
	item.Anchored = true
	item.CanCollide = settings.canCollide ~= false
	item.CanQuery = settings.canQuery ~= false
	item.CanTouch = false
	item.CastShadow = settings.castShadow ~= false
	item.Transparency = settings.transparency or 0
	if item:IsA("Part") then
		item.Shape = settings.shape or Enum.PartType.Block
	end
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Parent = parent
	return item
end

-- A rectangular beam whose long axis connects two world-space points.
function Primitives.beam(
	parent: Instance,
	name: string,
	from: Vector3,
	to: Vector3,
	width: number,
	color: Color3,
	material: Enum.Material,
	options: { [string]: any }?
): BasePart
	local length = (to - from).Magnitude
	local middle = (from + to) / 2
	return Primitives.part(parent, name, Vector3.new(width, width, length), CFrame.lookAt(middle, to), color, material, options)
end

function Primitives.light(parent: Instance, color: Color3, range: number, brightness: number)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Shadows = false
	light.Parent = parent
	return light
end

return Primitives
