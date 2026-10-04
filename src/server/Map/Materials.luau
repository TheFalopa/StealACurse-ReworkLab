local MaterialService = game:GetService("MaterialService")

local Materials = {}

-- ColorMaps are verified in the Rojo project/import records at build time.
-- MaterialVariant.ColorMap is PluginSecurity: production scripts must not read
-- it. Missing variants leave the established painted native palette intact.
local PALETTE = {
	HollowStone = { variant = "HollowStonePainted", material = Enum.Material.Slate },
	TwilightWood = { variant = "TwilightWoodPainted", material = Enum.Material.Wood },
	DuskySoil = { variant = "DuskySoilPainted", material = Enum.Material.Ground },
}

function Materials.apply(map: Model)
	local count, missing = 0, 0
	for _, part in ipairs(map:GetDescendants()) do
		if not part:IsA("BasePart") or part.Transparency >= 0.5
			or part:GetAttribute("SurfaceTreatment") or part:GetAttribute("EnvironmentCollisionHull") then
			continue
		end
		local category = part:GetAttribute("ArtMaterial")
		-- SurfaceArt intentionally leaves the broad ground support as Ground.
		if not category and part.Material == Enum.Material.Ground then category = "DuskySoil" end
		local spec = category and PALETTE[category]
		if not spec then continue end
		local variant = MaterialService:FindFirstChild(spec.variant)
		if not variant or not variant:IsA("MaterialVariant") then
			missing += 1
			continue
		end
		-- Keep the existing movement friction when changing visual base material.
		local physical = part.CurrentPhysicalProperties
		part.Material = spec.material
		part.MaterialVariant = spec.variant
		part.CustomPhysicalProperties = physical
		part:SetAttribute("PaintedTextureVariant", spec.variant)
		count += 1
	end
	map:SetAttribute("PaintedTextureSurfaces", count)
	map:SetAttribute("PendingTextureSurfaces", missing)
end

return Materials
