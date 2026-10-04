local Config = require(script.Parent.Config)
local P = require(script.Parent.Primitives)
local D = require(script.Parent.Decorations)
local AssetKit = require(script.Parent.AssetKit)
local Layout = require(script.Parent.Layout)
local World = {}
local C = Config.Colors

local function road(parent: Instance, name: string, first: Vector3, last: Vector3, width: number, height: number?)
    local middle = (first+last)/2
    local slab = P.part(parent,name,Vector3.new(width,0.16,(last-first).Magnitude+0.8),
        CFrame.lookAt(middle+Vector3.new(0,height or 0.12,0),last+Vector3.new(0,height or 0.12,0)),C.path,Enum.Material.Ground)
    slab:SetAttribute("RoadSlab",true)
    return slab
end

function World.ground(map: Model)
    local ground=P.model(map,"Ground")
    P.part(ground,"PlayableCollisionGround",Vector3.new(Config.PlayableWidth,8,Config.PlayableDepth),CFrame.new(0,-4,0),C.ground,Enum.Material.Ground,{transparency=1,castShadow=false})
    -- A single visual floor shares the support height and has a distant edge.
    -- Hidden collision support must not outline a rectangular platform in fog.
    -- Roblox clamps individual parts to 2048 studs; nine reused flat tiles keep
    -- the visual horizon distant without increasing accessible gameplay area.
    for x=-1,1 do
        for z=-1,1 do
            local name=if x==0 and z==0 then "FogCoveredWorldContinuation" else string.format("FarGround_%d_%d",x,z)
            local tile=P.part(ground,name,Vector3.new(2048,1,2048),CFrame.new(x*2048,-0.5,z*2048),C.ground,Enum.Material.SmoothPlastic,{canCollide=false,castShadow=false})
            tile:SetAttribute("ArtMaterial","DuskySoil")
        end
    end
    for index=0,49 do
        local angle=math.rad(index*47+8)
        local at=D.polar(82+(index*39)%269,angle,0.027)
        P.part(ground,string.format("BuriedEarth_%02d",index+1),Vector3.new(24+index%4*8,0.05,22+index%5*6),
            CFrame.new(at)*CFrame.Angles(0,angle*0.6,0),index%3==0 and C.soil or C.groundPatch,Enum.Material.Ground,
            {shape=Enum.PartType.Ball,canCollide=false,castShadow=false})
    end
end

function World.paths(map: Model)
    local paths=P.model(map,"Paths")
    for index=1,Config.BaseCount do
        local points=Config.approachPoints(index)
        for section=1,#points-2 do
            road(paths,string.format("SanctuaryLane_%02d_%d",index,section),points[section],points[section+1],20)
            local direction=(points[section+1]-points[section]).Unit
            local right=Vector3.new(direction.Z,0,-direction.X)
            for flag=1,3 do
                local at=points[section]:Lerp(points[section+1],flag/4)+right*(flag%2==0 and 3 or -3)
                P.part(paths,string.format("BuriedPaver_%02d_%d_%d",index,section,flag),Vector3.new(5.5,0.06,7),
                    CFrame.lookAt(at+Vector3.new(0,0.23,0),at+direction+Vector3.new(0,0.23,0))*CFrame.Angles(0,math.rad(flag*5-8),0),
                    flag==2 and C.stoneMoss or C.pathStone,Enum.Material.Slate,{canCollide=false})
            end
        end
        local h=Config.BaseSites[index].height
        road(paths,string.format("SanctuaryRamp_%02d",index),points[#points-1]+Vector3.new(0,0.2,0),points[#points]+Vector3.new(0,h+0.8,0),22,0)
    end
    for index,points in ipairs(Layout.CrossTrails) do
        for section=1,#points-1 do
            road(paths,string.format("CemeterySpine_%02d_%d",index,section),points[section],points[section+1],index<=11 and 14 or 12)
        end
    end
    road(paths,"FrontCourtApproach",Vector3.new(0,0,9),Vector3.new(0,0,85),24)
    road(paths,"RearHallApproach",Vector3.new(0,0,-72),Vector3.new(0,0,-128),22)
    P.part(paths,"BrokenRitualCourt",Vector3.new(65,0.22,46),CFrame.new(0,0.11,33),C.stoneDark,Enum.Material.Slate,
        {shape=Enum.PartType.Ball,castShadow=false})
    local ceremony=P.model(paths,"CursedProcessionRoad")
    ceremony:SetAttribute("AuthoredRoute","HollowCrownIrregularProcession")
    local points=Layout.ProcessionPoints
    local routeLength=0
    for section=1,#points-1 do
        local first,last=points[section],points[section+1]
        local length=(last-first).Magnitude
        routeLength+=length
        local strip=road(ceremony,string.format("CeremonialStone_%02d",section),first,last,14,0.34)
        strip.Material=Enum.Material.Cobblestone
        strip:SetAttribute("ProcessionPaving",true)
        -- Sparse buried slabs and asymmetrical cracks make an old ritual road,
        -- not an uninterrupted fluorescent conveyor belt.
        local direction=(last-first).Unit
        local right=Vector3.new(direction.Z,0,-direction.X)
        for slab=1,math.max(1,math.floor(length/16)) do
            local at=first:Lerp(last,slab/(math.max(1,math.floor(length/16))+1))+right*(slab%2==0 and 2.4 or -2.1)
            P.part(ceremony,string.format("ProcessionPaver_%02d_%02d",section,slab),Vector3.new(5.8,0.06,5.2),
                CFrame.lookAt(at+Vector3.new(0,0.45,0),at+direction+Vector3.new(0,0.45,0))*CFrame.Angles(0,math.rad(slab%3*6-6),0),
                slab%3==0 and C.stoneMoss or C.pathStone,Enum.Material.Slate,{canCollide=false,canQuery=false})
        end
        if section%2==0 then
            local middle=(first+last)/2
            P.part(ceremony,string.format("FaintRitualInlay_%02d",section),Vector3.new(0.13,0.04,(last-first).Magnitude*0.6),
                CFrame.lookAt(middle+Vector3.new(0,0.44,0),last+Vector3.new(0,0.44,0)),C.violet,Enum.Material.Neon,
                {transparency=0.55,canCollide=false,castShadow=false})
        end
    end
    map:SetAttribute("AuthoredProcessionLength",routeLength)
    map:SetAttribute("AuthoredProcessionWaypoints",#points)
    for section=3,#points-1 do
        local first,last=points[section],points[section+1]
        local direction=(last-first).Unit
        local right=Vector3.new(direction.Z,0,-direction.X)
        for _,side in ipairs({-1,1}) do
            local at=(first+last)/2+right*(side*13)
            if not Layout.processionReserved(at,1) then
                D.candle(ceremony,string.format("ProcessionVigil_%02d_%d",section,side),at,section%3~=0)
            end
        end
        if section%3==0 then
            local at=(first+last)/2+right*16
            if not Layout.processionReserved(at,2) then
                D.lantern(ceremony,"SpectralGuide"..section,at,5.5,section%2==0 and C.cyan or C.violet,false)
            end
        end
    end
end

function World.boundary(map: Model)
    local edge=P.model(map,"OuterBoundary")
    local background=P.model(map,"DistantHauntedWorld")
    for index=0,47 do
        local a,b=math.rad(index*7.5),math.rad((index+1)*7.5)
        local first,last=D.polar(Config.boundaryRadius(a),a),D.polar(Config.boundaryRadius(b),b)
        local middle=(first+last)/2
        P.part(edge,string.format("InvisibleBoundary_%02d",index+1),Vector3.new(3,30,(last-first).Magnitude+3),
            CFrame.lookAt(middle+Vector3.new(0,15,0),last+Vector3.new(0,15,0)),C.stoneDark,Enum.Material.SmoothPlastic,
            {transparency=1,castShadow=false})
        local size=Vector3.new(34+index%4*6,18+index%5*5,27)
        local at=D.polar(Config.boundaryRadius(a)+11,a)
        local frame=CFrame.new(at+Vector3.new(0,size.Y*0.28,0))*CFrame.Angles(0,a+0.5,0)
        if index%6<4 then
            -- Already behind the segmented blocking boundary. Do not spend
            -- extra hulls on scenery the player can never reach.
            if not AssetKit.place(edge,string.format("RaggedEscarpment_%02d",index+1),"final_cliff_cluster",size,frame,index%3==0 and C.stoneMoss or C.stoneDark,Enum.Material.Slate,{collision="none"}) then
                AssetKit.place(edge,string.format("RaggedEscarpment_%02d",index+1),"rock_crag",size,frame,C.stoneDark,Enum.Material.Slate,{collision="none"})
            end
        end
        if index%3~=1 then
            D.deadTree(background,string.format("OuterForest_%02d",index+1),D.polar(Config.boundaryRadius(a)+30+index%3*13,a+0.04),a,index%4+1,1.6+index%3*0.35)
            local collider=background:FindFirstChild(string.format("OuterForest_%02d",index+1)):FindFirstChild("TrunkCollision")
            if collider and collider:IsA("BasePart") then collider.CanCollide=false end
        end
    end
    for index=0,19 do
        local angle=math.rad(index*18+9)
        local at=D.polar(Config.OuterFenceRadius+78+index%3*27,angle)
        local size=Vector3.new(42+index%3*15,64+index%4*19,35+index%4*11)
        AssetKit.place(background,string.format("FarCliff_%02d",index+1),"rock_crag",size,
            CFrame.new(at+Vector3.new(0,size.Y*0.3-6,0))*CFrame.Angles(0,angle,0),C.stoneDark,Enum.Material.Slate,{castShadow=false,collision="none"})
        local treeSize=Vector3.new(50,70+index%3*16,38)
        AssetKit.place(background,string.format("GiantHorizonTree_%02d",index+1),"final_giant_tree",treeSize,
            CFrame.new(D.polar(Config.OuterFenceRadius+52+index%4*15,angle+0.12)+Vector3.new(0,treeSize.Y/2,0))*CFrame.Angles(0,angle+index,0),
            C.wood,Enum.Material.Wood,{castShadow=false,collision="none"})
    end
    for index,site in ipairs({Vector3.new(441,0,-175),Vector3.new(-453,0,-84),Vector3.new(102,0,459)}) do
        local ruin=P.model(background,string.format("LostBelfry_%02d",index))
        D.slab(ruin,"Tower",Vector3.new(15,47,15),site+Vector3.new(0,23,0),C.stoneDark,Enum.Material.Slate,{canCollide=false,castShadow=false})
        AssetKit.place(ruin,"BrokenRoof","final_crooked_roof",Vector3.new(21,18,20),CFrame.new(site+Vector3.new(0,55,0)),C.roof,Enum.Material.Slate,{castShadow=false})
    end
end

return World
