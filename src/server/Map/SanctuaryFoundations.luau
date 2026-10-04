-- Elevated sanctuaries (BaseSites height 1-2) rest on a terrain ellipsoid that
-- is smaller than their 104x104 floor, so the floor perimeter hovered 1-2 studs
-- above the ground. A dark stone foundation closes that slit. It is a map-level
-- model outside every Base (sanctuary bounds and specs are unchanged). Parts
-- start with SurfaceArt's stone output (SmoothPlastic + HollowStone), which
-- Materials turns into the painted variant; SurfaceArt skips them, so its
-- tint sequence for existing stone is unchanged. Visual only: the floor, ramp
-- and humanoid step-up already carry movement.
local Config = require(script.Parent.Config)
local P = require(script.Parent.Primitives)

local SanctuaryFoundations = {}
local C = Config.Colors
-- Base-local SanctuaryFloor edges (RestorationArchitecture: x -52..52, z -36..68).
-- Local y=0 is the floor underside; the surrounding ground is at y=-height.
local EDGE_X, FRONT_Z, BACK_Z = 52, -36, 68
-- The wall sits 0.12 under the floor lip (the slab reads as its cap) and a
-- low footing steps 0.45 proud of it (the batter). Both go 0.3 into the soil.
local REVEAL, WALL, PROUD, FOOTING, BURY = 0.12, 1, 0.45, 0.45, 0.3
-- Front runs stop beside the 22-wide SanctuaryRamp (|x| <= 11); the footing
-- returns 0.2 past the wall end so their end faces are not coplanar.
local RAMP_CLEAR, RETURN = 11.5, 0.2
local options = { canCollide = false, canQuery = false }

function SanctuaryFoundations.build(map: Model)
	local group = P.model(map, "SanctuaryFoundations")
	local count = 0
	for index, site in ipairs(Config.BaseSites) do
		local height = site.height
		if height <= 0 then continue end
		local frame = Config.baseFrame(index)
		local base = P.model(group, string.format("Foundation%02d", index))
		base:SetAttribute("BaseIndex", index)
		local bottom, footTop = -height - BURY, -height + FOOTING
		-- Boxes are given by base-local extents. Pieces butt rather than
		-- overlap at visible faces, so no coplanar faces fight.
		local function block(name: string, x0: number, x1: number, y0: number, y1: number, z0: number, z1: number, color: Color3)
			local item = P.part(base, name, Vector3.new(x1 - x0, y1 - y0, z1 - z0),
				frame * CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), color, Enum.Material.SmoothPlastic, options)
			item:SetAttribute("ArtMaterial", "HollowStone")
			count += 1
		end
		local wallOut, footOut = EDGE_X - REVEAL, EDGE_X + PROUD
		local wallIn, footIn = wallOut - WALL, wallOut - 0.5
		local wallFront, wallBack = FRONT_Z + REVEAL, BACK_Z - REVEAL
		for _, side in ipairs({ -1, 1 }) do
			local label = side < 0 and "Left" or "Right"
			local function mirrored(name: string, a: number, b: number, y0: number, y1: number, z0: number, z1: number, color: Color3)
				if side < 0 then a, b = -b, -a end
				block(name, a, b, y0, y1, z0, z1, color)
			end
			mirrored("FoundationWall_" .. label, wallIn, wallOut, bottom, 0, wallFront, wallBack, C.stoneDark)
			mirrored("FoundationFooting_" .. label, footIn, footOut, bottom, footTop, FRONT_Z - PROUD, BACK_Z + PROUD, C.stoneMoss)
			mirrored("FoundationWall_Front" .. label, RAMP_CLEAR, wallIn, bottom, 0, wallFront, wallFront + WALL, C.stoneDark)
			mirrored("FoundationFooting_Front" .. label, RAMP_CLEAR - RETURN, footIn, bottom, footTop, FRONT_Z - PROUD, wallFront + 0.5, C.stoneMoss)
		end
		block("FoundationWall_Back", -wallIn, wallIn, bottom, 0, wallBack - WALL, wallBack, C.stoneDark)
		block("FoundationFooting_Back", -footIn, footIn, bottom, footTop, wallBack - 0.5, BACK_Z + PROUD, C.stoneMoss)
	end
	group:SetAttribute("FoundationPartCount", count)
	return group
end

return SanctuaryFoundations
