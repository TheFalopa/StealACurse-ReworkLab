local P = require(script.Parent.Primitives)

local SurfaceArt = {}
local INK = Color3.fromRGB(44, 47, 68)
local CHALK = Color3.fromRGB(157, 153, 174)
local MOSS = Color3.fromRGB(73, 99, 104)
local options = { canCollide = false, canQuery = false, castShadow = false }
local artCount = 0
-- Shared painted textures now provide the broad surface detail. Keep native
-- marks for focal cracks/wear instead of increasing part count with map area.
local ART_BUDGET = 640

local function mark(parent: Instance, name: string, size: Vector3, frame: CFrame, color: Color3)
	if artCount >= ART_BUDGET then return nil end
	artCount += 1
	local item = P.part(parent, name, size, frame, color, Enum.Material.SmoothPlastic, options)
	item:SetAttribute("SurfaceTreatment", true)
	return item
end

-- Large, deliberate painterly marks: no noisy PBR, image IDs or per-frame code.
local function wallFace(group: Model, part: BasePart, side: number)
	local w, h, d = part.Size.X, part.Size.Y, part.Size.Z
	local face = part.CFrame * CFrame.new(0, 0, side * (d/2 + 0.024))
	local courses = math.clamp(math.floor(h/7), 1, 4)
	for row = 1, courses do
		local y = -h/2 + h * row/(courses+1)
		mark(group, "PaintedMortar", Vector3.new(w*0.94, 0.065, 0.035), face*CFrame.new(0,y,0), part.Color:Lerp(INK,0.42))
		local x = (row%2==0 and -0.18 or 0.17)*w
		mark(group, "StaggeredJoint", Vector3.new(0.055,h/(courses+1)*0.78,0.035),
			face*CFrame.new(x,y-h/(courses+1)*0.4,0), part.Color:Lerp(INK,0.3))
	end
	mark(group, "LowFrequencyPaint", Vector3.new(w*0.23,math.min(h*0.17,2.4),0.024),
		face*CFrame.new(w*0.27,-h*0.27,0.024),part.Color:Lerp(MOSS,0.18))
	mark(group, "SoftEdgeWear", Vector3.new(math.min(3,w*0.4),0.10,0.04),
		face*CFrame.new(-w*0.25,h*0.43,0.025)*CFrame.Angles(0,0,math.rad(-4)),part.Color:Lerp(CHALK,0.35))
end

local function slabArt(group: Model, part: BasePart, seed: number)
	local w, h, d = part.Size.X, part.Size.Y, part.Size.Z
	local top = part.CFrame * CFrame.new(0,h/2+0.021,0)
	mark(group,"PaintedStoneWash",Vector3.new(w*0.27,0.02,d*0.32),
		top*CFrame.new(w*0.18,0,-d*0.12)*CFrame.Angles(0,math.rad(seed%3*7-7),0),part.Color:Lerp(MOSS,0.14))
	mark(group,"CarvedHairline",Vector3.new(w*0.28,0.023,0.055),
		top*CFrame.new(-w*0.19,0.008,d*0.16)*CFrame.Angles(0,math.rad(-18),0),part.Color:Lerp(INK,0.38))
	mark(group,"BrokenCrack",Vector3.new(w*0.13,0.024,0.06),
		top*CFrame.new(-w*0.04,0.008,d*0.12)*CFrame.Angles(0,math.rad(23),0),part.Color:Lerp(INK,0.38))
end

function SurfaceArt.build(map: Model)
	local art = P.model(map,"HandPaintedSurfaceArt")
	artCount = 0
	local originals = map:GetDescendants()
	local paletteCount, wallCount, slabCount = 0, 0, 0
	for _, item in ipairs(originals) do
		if item:IsA("BasePart") and item.Transparency < 0.5 and not item:GetAttribute('RestorationArchitecture') then
			local material = item.Material
			if material == Enum.Material.Slate or material == Enum.Material.Cobblestone then
				paletteCount += 1
				item.Material = Enum.Material.SmoothPlastic
				local accent = paletteCount%4==0 and CHALK or (paletteCount%4==1 and MOSS or INK)
				item.Color = item.Color:Lerp(accent,0.065)
				item:SetAttribute("ArtMaterial", "HollowStone")
			elseif material == Enum.Material.Wood then
				item.Material = Enum.Material.SmoothPlastic
				item.Color = item.Color:Lerp(Color3.fromRGB(78,59,91),0.12)
				item:SetAttribute("ArtMaterial", "TwilightWood")
			elseif material == Enum.Material.Ground and item.Size.X < 150 then
				item.Material = Enum.Material.SmoothPlastic
				item:SetAttribute("ArtMaterial", "DuskySoil")
			end
			local name = item.Name
			local wall = string.find(name,"ManorWing") or name=="MassiveShaft"
				or name=="UpperNave" or string.find(name,"UndercroftWall")
				or string.find(name,"BoundaryWall") or string.find(name,"RearWall")
				or string.find(name,"FrontRuin") or name=="RearWall"
			if wall and item:IsA("Part") and item.Shape==Enum.PartType.Block and item.Size.Y > 2 then
				wallCount += 1
				wallFace(art,item,1)
				if item.Size.Z < 4 then wallFace(art,item,-1) end
			elseif (string.find(name,"EntryFlag") or string.find(name,"AisleStone")
				or string.find(name,"GraveSlab") or string.find(name,"BuriedPaver")
				or name=="ClaimTablet" or string.find(name,"UnderhallFlagstone")) and item:IsA("Part") then
				slabCount += 1
				if item.Size.Y < 0.4 and (slabCount%2==0 or string.find(name,"EntryFlag")) then slabArt(art,item,slabCount) end
			end
			if item:IsA("MeshPart") and item:GetAttribute("SourceTemplate")=="final_collection_pedestal" then
				-- A spare octagonal seal uses top-face geometry, not a tiled texture.
				local f=item.CFrame*CFrame.new(0,item.Size.Y/2+0.035,0)
				for side=0,3 do
					mark(art,"PedestalEdgeWear",Vector3.new(2.8,0.035,0.10),
						f*CFrame.Angles(0,math.rad(side*90),0)*CFrame.new(0,0,2.25),item.Color:Lerp(CHALK,0.27))
				end
			end
		end
	end
	map:SetAttribute("PaintedStoneSurfaces",paletteCount)
	map:SetAttribute("SurfaceArtParts",#art:GetChildren())
	return art
end

return SurfaceArt
