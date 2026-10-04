local Config = require(script.Parent.Config)
local P = require(script.Parent.Primitives)
local D = require(script.Parent.Decorations)
local Grounding = require(script.Parent.Grounding)
local TerrainArt = require(script.Parent.TerrainArt)
local Layout = require(script.Parent.Layout)
local AssetKit = require(script.Parent.AssetKit)

local HalloweenArt = {}
local C = Config.Colors
local soft = {canCollide=false,canQuery=false,castShadow=false}
local DETAIL_BUDGET = 60
local detailCount = 0

local function floorAt(parent: Instance, at: Vector3): Vector3
	-- Each offering samples its own X/Z. Retaining a raised parent Y makes
	-- decorations float when their local offset leaves a rounded burial hill.
	return Grounding.position(parent,Vector3.new(at.X,0,at.Z))
end

-- Six radial strands and two broken polygon rings, authored as thin beams.
-- Webs are static outlines, not large alpha planes in front of the camera.
local function web(parent: Instance, name: string, frame: CFrame, radius: number)
	local group = P.model(parent,name)
	local chalk = Color3.fromRGB(151,167,188)
	for spoke=0,5 do
		local a=spoke*math.pi/3
		local tip=Vector3.new(math.cos(a),math.sin(a),0)*radius
		P.beam(group,"WebSpoke"..spoke,frame.Position,frame:PointToWorldSpace(tip),0.035,chalk,Enum.Material.SmoothPlastic,soft)
		for ring=1,2 do
			if not (ring==2 and spoke==4) then
				local b=a+math.pi/3
				local factor=ring==1 and 0.46 or 0.85
				P.beam(group,"WebRing"..ring.."_"..spoke,
					frame:PointToWorldSpace(tip*factor),
					frame:PointToWorldSpace(Vector3.new(math.cos(b),math.sin(b),0)*radius*factor),
					0.03,chalk,Enum.Material.SmoothPlastic,soft)
			end
		end
	end
	return group
end

local function sign(parent: Instance, frame: CFrame, title: string)
	local group=P.model(parent,"CrookedVigilSign")
	P.part(group,"RootedPost",Vector3.new(0.35,3.8,0.35),frame*CFrame.new(0,1.8,0),C.wood,Enum.Material.SmoothPlastic,soft)
	local board=P.part(group,"PaintedWood",Vector3.new(3.4,1.3,0.18),frame*CFrame.new(0,3,0)*CFrame.Angles(0,0,math.rad(-7)),
		Color3.fromRGB(74,55,78),Enum.Material.SmoothPlastic,soft)
	for _, direction in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
		local face=Instance.new("SurfaceGui")
		face.Name=direction==Enum.NormalId.Front and "HandLetteredSign" or "HandLetteredReverse"
		face.Face=direction
		face.CanvasSize=Vector2.new(300,110)
		face.LightInfluence=0.7
		face.MaxDistance=45
		face.Parent=board
		local label=Instance.new("TextLabel")
		label.Size=UDim2.fromScale(1,1)
		label.BackgroundTransparency=1
		label.Font=Enum.Font.GothamBold
		label.Text=title
		label.TextColor3=C.windowWarm
		label.TextSize=24
		label.Parent=face
	end
end

-- Three low closed mesh details tie offerings into the ground. They use
-- verified original leaf/root modules and introduce no new collision hulls.
local function understory(parent: Instance, frame: CFrame)
	if detailCount > DETAIL_BUDGET - 3 then return end
	for index=1,2 do
		local at=floorAt(parent,frame:PointToWorldSpace(Vector3.new(index==1 and -2.9 or 2.5,0,2.4)))
		local leaf=AssetKit.placeGrounded(parent,"GatheredVigilGrass"..index,"foliage_swept",Vector3.new(3.0,0.85,2.0),
			CFrame.new(at)*CFrame.Angles(0,index*.9,0),index==1 and C.foliageBlue or C.foliage,
			Enum.Material.SmoothPlastic,{collision="none",castShadow=false,groundInset=0.025})
		if leaf then detailCount+=1 end
	end
	local at=floorAt(parent,frame:PointToWorldSpace(Vector3.new(0.5,0,3.1)))
	local root=AssetKit.placeGrounded(parent,"BuriedOfferingRoot","root_serpent",Vector3.new(3.6,0.66,2.1),
		CFrame.new(at)*CFrame.Angles(0,0.5,0),C.root,Enum.Material.Wood,
		{collision="none",castShadow=false,groundInset=0.035})
	if root then
		root:SetAttribute("ArtMaterial","TwilightWood")
		detailCount+=1
	end
end

local function cluster(parent: Instance, name: string, location: Vector3, turn: number, style: number)
	local at=floorAt(parent,location)
	local group=P.model(parent,name)
	group:SetAttribute("DecorationCluster","HalloweenVigil")
	local frame=CFrame.new(at)*CFrame.Angles(0,turn,0)
	understory(group,frame)
	local offerings={{-1.5,0,1},{1.2,0.5,0.64},{0.1,2.1,0.46}}
	for index,v in ipairs(offerings) do
		D.pumpkin(group,"Offering"..index,floorAt(group,frame:PointToWorldSpace(Vector3.new(v[1],0,v[2]))),v[3],turn+math.pi,
			index==3 and style or index)
	end
	for index=1,2 do
		D.candle(group,"VigilCandle"..index,floorAt(group,frame:PointToWorldSpace(Vector3.new(-2.8+index*0.65,0,-1.4))),false)
	end
	if style==1 then
		local atSign=frame:PointToWorldSpace(Vector3.new(3.1,0,1.4))
		sign(group,CFrame.new(floorAt(group,atSign))*frame.Rotation,"KEEP THE VIGIL")
	elseif style==2 then
		-- Abstract non-graphic bone motif on the ground, never a gameplay obstacle.
		for index=1,2 do
			P.part(group,"WeatheredBone"..index,Vector3.new(1.45,0.16,0.18),
				frame*CFrame.new(3.1,0.1,-0.7)*CFrame.Angles(0,math.rad(index==1 and 32 or -36),0),
				C.moonStone,Enum.Material.SmoothPlastic,soft)
		end
	else
		local spirit=P.part(group,"StillSpirit",Vector3.new(0.75,1.15,0.65),frame*CFrame.new(3.1,2.1,0.6),
			Color3.fromRGB(139,187,198),Enum.Material.SmoothPlastic,{shape=Enum.PartType.Ball,canCollide=false,canQuery=false,castShadow=false})
		for _,x in ipairs({-0.13,0.13}) do
			P.part(group,"SpiritEye",Vector3.new(0.1,0.16,0.05),spirit.CFrame*CFrame.new(x,0.13,-0.32),
				C.stoneDark,Enum.Material.SmoothPlastic,soft)
		end
	end
	return group
end

function HalloweenArt.build(map: Model)
	local art=P.model(map,"HalloweenFocalClusters")
	detailCount=0
	local clusterCount=0
	for _,side in ipairs({-1,1}) do
		local at=side<0 and Vector3.new(-48,0,22) or Vector3.new(47,0,43)
		cluster(art,side<0 and "WestCastleVigil" or "EastCastleVigil",at,side*0.25,1)
		clusterCount+=1
		web(art,"PortalWeb"..side,CFrame.new(side*10.9,18.5,0.2),2.15)
	end
	-- The long procession has deliberate shoulder scenes rather than props
	-- randomly sprinkled through its full player/Curse interaction envelope.
	for section=4,#Layout.ProcessionPoints-1 do
		local first,last=Layout.ProcessionPoints[section],Layout.ProcessionPoints[section+1]
		local direction=(last-first).Unit
		local right=Vector3.new(direction.Z,0,-direction.X)
		local at=(first+last)/2+right*(section%2==0 and 19 or -19)
		if not Layout.reserved(at,5.5) then
			cluster(art,"ProcessionOffering"..section,at,math.atan2(direction.X,direction.Z),section%3+1)
			clusterCount+=1
			if section%3==0 then
				local support=CFrame.new(Grounding.position(art,at+right*5))*CFrame.Angles(0,section*0.4,0)
				AssetKit.placeGrounded(art,"RitualMemorial"..section,"final_hero_grave",Vector3.new(4.5,7,2),support,C.stoneMoss,Enum.Material.Slate,{groundInset=0.04})
			end
		end
	end
	-- Offerings sit beside the front corner, outside the 104x104 sanctuary
	-- shell (x 52), >=62 studs from approach lanes and >=33 from cross trails.
	for index=1,Config.BaseCount do
		local frame=Config.baseFrame(index)
		local side=index%2==0 and -1 or 1
		local corner=frame:PointToWorldSpace(Vector3.new(side*64,0,-26))
		-- Elevated frames sit at Y=height; the leaves below sample from the ground.
		local at=Vector3.new(corner.X,0,corner.Z)
		if not Layout.processionReserved(at,6) then
			cluster(art,"TerritoryOffering"..index,at,index*0.7,index%3+1)
			clusterCount+=1
			local ground=Grounding.position(art,at+Vector3.new(3,0,-3))
			for leaf=1,3 do
				P.part(art,"FallenAutumnLeaf"..index.."_"..leaf,Vector3.new(1.0,0.07,1.7),
					CFrame.new(ground+Vector3.new(leaf*.7,0.07,leaf%2))*CFrame.Angles(0,index+leaf,0),
				leaf==2 and C.autumn or C.pumpkin,Enum.Material.SmoothPlastic,
				{className="WedgePart",canCollide=false,canQuery=false,castShadow=false})
			end
		end
	end
	for index,plot in ipairs(TerrainArt.Plots) do
		if plot.active and index%2==0 then
			local frame=CFrame.new(plot.x,plot.h*0.78+0.25,plot.z)*CFrame.Angles(0,math.rad(plot.angle),0)
			cluster(art,"FamilyVigil"..index,frame:PointToWorldSpace(Vector3.new(8.8,0,-7.1)),math.rad(plot.angle),index%3+1)
			clusterCount+=1
			if index%4==0 then
				web(art,"CemeteryWeb"..index,frame*CFrame.new(-8.4,3.2,9.55),1.7)
			end
		end
	end
	for index,site in ipairs(Layout.LandmarkSites) do
		if index%2==0 then
			local at=Grounding.position(art,site.at)
			web(art,"WoodlandWeb"..index,CFrame.new(at+Vector3.new(2,11,2))*CFrame.Angles(0,site.angle,0),3.2)
			AssetKit.place(art,"HangingWoodlandChain"..index,"final_chain",Vector3.new(0.7,6.5,0.55),
				CFrame.new(at+Vector3.new(-2,12,1)),C.iron,Enum.Material.Metal,{collision="none"})
		end
	end
	map:SetAttribute("HalloweenClusterCount",clusterCount)
	map:SetAttribute("HalloweenUnderstoryMeshCount",detailCount)
	art:SetAttribute("UnderstoryMeshBudget",DETAIL_BUDGET)
	return art
end

return HalloweenArt
