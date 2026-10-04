local Config=require(script.Parent.Config)
local P=require(script.Parent.Primitives)
local D=require(script.Parent.Decorations)
local AssetKit=require(script.Parent.AssetKit)
local Layout=require(script.Parent.Layout)
local Grounding=require(script.Parent.Grounding)
local Landmarks={}
local C=Config.Colors

local function heroTree(parent: Instance,name: string,at: Vector3,angle: number,scale: number)
    local model=P.model(parent,name)
    at=Grounding.position(parent,at)
    local size=Vector3.new(40,52,30)*scale
    if not AssetKit.placeGrounded(model,"AncientSilhouette","final_giant_tree",size,CFrame.new(at)*CFrame.Angles(0,angle,0),C.wood,Enum.Material.Wood,{groundInset=0.22}) then
        D.deadTree(model,"AncientSilhouette",at,angle,1,2.2*scale)
    end
end

local function chapel(parent: Instance,at: Vector3)
    local model=P.model(parent,"CollapsedChapel")
    at=Grounding.position(parent,at)
    local frame=CFrame.new(at)*CFrame.Angles(0,-0.4,0)
    P.part(model,"SunkenNave",Vector3.new(25,0.6,31),frame*CFrame.new(0,0.3,0),C.stoneDark,Enum.Material.Slate)
    for _,side in ipairs({-1,1}) do
        for bay=0,2 do
            P.part(model,"BrokenWall"..side..bay,Vector3.new(2.5,8+bay%2*4,7),frame*CFrame.new(side*12.5,4+bay%2*2,-10+bay*10),C.stoneMoss,Enum.Material.Slate)
            AssetKit.placeGrounded(model,"ChapelButtress"..side..bay,"final_buttress",Vector3.new(3,14,5),frame*CFrame.new(side*15,0,-10+bay*10)*CFrame.Angles(0,side*math.pi/2,0),C.stone,Enum.Material.Slate)
        end
    end
    AssetKit.placeGrounded(model,"SurvivingChapelArch","final_gothic_doorway",Vector3.new(25,29,3),frame*CFrame.new(0,0.6,-15),C.stoneLight,Enum.Material.Slate)
    AssetKit.placeGrounded(model,"FallenRoseWindow","final_gothic_window",Vector3.new(9,17,1.5),frame*CFrame.new(5,0.6,10)*CFrame.Angles(math.pi/2,0,0.3),C.stoneLight,Enum.Material.Slate,{groundInset=0.08})
    for i=0,3 do D.rubble(model,"FallenVault"..i,frame:PointToWorldSpace(Vector3.new(-7+i*5,0,4+i%2*4)),i,2.3) end
    D.lantern(model,"LastVigil",frame:PointToWorldSpace(Vector3.new(-9,0,-18)),6,C.candle,true)
end

function Landmarks.build(map: Model)
    local landmarks=P.model(map,"HauntedLandmarks")
    local sites=Layout.LandmarkSites
    for _,site in ipairs(sites) do
        if not Layout.reserved(site.at,8) then
            heroTree(landmarks,site.name,site.at,site.angle,site.scale)
            if site.name=="WidowsOak" or site.name=="ChainedTree" then
                D.foliage(landmarks,site.name.."Canopy",site.at,site.angle,site.scale*1.5,
                    site.name=="ChainedTree" and "autumn" or "haunted",42,site.scale)
            end
        end
    end
    local chapelAt=Layout.ChapelSite
    if not Layout.reserved(chapelAt,21) then chapel(landmarks,chapelAt) end
    local gateAt=Layout.GateSite
    if not Layout.reserved(gateAt,16) then
        AssetKit.placeGrounded(landmarks,"OldCemeteryGate","final_gothic_doorway",Vector3.new(27,32,4),CFrame.new(Grounding.position(landmarks,gateAt))*CFrame.Angles(0,-0.6,0),C.stoneLight,Enum.Material.Slate)
        D.lantern(landmarks,"GateWatch",gateAt+Vector3.new(-17,0,3),7,C.candle,false)
    end
    local memorialAt=Layout.MemorialSite
    if not Layout.reserved(memorialAt,7) then
        AssetKit.placeGrounded(landmarks,"ForgottenWarden","stone_warden",Vector3.new(10,24,7),CFrame.new(Grounding.position(landmarks,memorialAt))*CFrame.Angles(0,-0.8,0),C.stoneLight,Enum.Material.Slate)
        D.rubble(landmarks,"BrokenWardenStair",memorialAt+Vector3.new(5,0,5),1,2)
    end
    local crystalAt=Layout.CrystalSite
    if not Layout.reserved(crystalAt,14) then
        local field=P.model(landmarks,"SpectralRootGarden")
        for index=0,4 do
            local at=Grounding.position(field,crystalAt+Vector3.new(math.sin(index*2.4)*8,0,math.cos(index*2.4)*8))
            local size=Vector3.new(1.8,4+index%3,1.8)
            local halfHeight=(math.cos(0.2)*size.Y+math.sin(0.2)*size.X)/2
            local crystal=P.part(field,"WardCrystal"..index,size,CFrame.new(at+Vector3.new(0,halfHeight-0.16,0))*CFrame.Angles(0,index,0.2),index==0 and C.green or C.cyan,Enum.Material.Neon,
                {className="WedgePart",canCollide=false,castShadow=false})
            if index==0 then P.light(crystal,C.cyan,18,0.6) end
        end
        AssetKit.placeGrounded(field,"EmbracingRoot","root_serpent",Vector3.new(22,5,13),CFrame.new(Grounding.position(field,crystalAt)),C.root,Enum.Material.Wood,{groundInset=0.25})
    end
    return landmarks
end
return Landmarks
