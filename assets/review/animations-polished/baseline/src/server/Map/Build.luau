local Config = require(script.Parent.Config)
local World = require(script.Parent.World)
local TerrainArt = require(script.Parent.TerrainArt)
local Mausoleum = require(script.Parent.Mausoleum)
local Cemetery = require(script.Parent.Cemetery)
local Landmarks = require(script.Parent.Landmarks)
local PlayerShrine = require(script.Parent.PlayerShrine)
local SurfaceArt = require(script.Parent.SurfaceArt)
local HalloweenArt = require(script.Parent.HalloweenArt)
local WorldPolish = require(script.Parent.WorldPolish)
local Grounding = require(script.Parent.Grounding)
local Materials = require(script.Parent.Materials)
local RoadSurfaceResolver = require(script.Parent.RoadSurfaceResolver)

local Build = {}

function Build.build()
	local existing = workspace:FindFirstChild(Config.MapName)
	if existing then
		assert(existing:GetAttribute("Generator") == "StealACurseMapBuilder", "The map name is already used by an object this builder did not create")
	end

	-- Assemble off-Workspace so clients receive a complete map in one replication step.
	local map = Instance.new("Model")
	map.Name = Config.MapName
	map:SetAttribute("Generator", "StealACurseMapBuilder")
	World.ground(map)
	World.paths(map)
	TerrainArt.build(map)
	Grounding.refresh(map)
	Mausoleum.build(map)
	Cemetery.build(map)
	Landmarks.build(map)
	PlayerShrine.build(map)
	Grounding.refresh(map)
	World.boundary(map)
	HalloweenArt.build(map)
	WorldPolish.build(map)
	SurfaceArt.build(map)
	Materials.apply(map)
	RoadSurfaceResolver.apply(map)
	map:SetAttribute("EnvironmentVersion", "HollowCrownWorldExpansion")
	map:SetAttribute("PlayableWidth", Config.PlayableWidth)
	map:SetAttribute("PlayableDepth", Config.PlayableDepth)
	-- Keep the V1 elevation: it prevents z-fighting with Studio's template Baseplate.
	map:PivotTo(map:GetPivot() + Vector3.new(0, Config.MapElevation, 0))
	if existing then
		existing:Destroy()
	end
	map.Parent = workspace
	return map
end

return Build
