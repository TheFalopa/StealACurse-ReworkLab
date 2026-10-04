local Config=require(script.Parent.Config)
local P=require(script.Parent.Primitives)
local D=require(script.Parent.Decorations)
local AssetKit=require(script.Parent.AssetKit)
local TerrainArt=require(script.Parent.TerrainArt)
local Layout=require(script.Parent.Layout)
local Grounding=require(script.Parent.Grounding)
local Cemetery={}
local C=Config.Colors

local function inComposedClearing(at: Vector3): boolean
    for _,plot in ipairs(TerrainArt.Plots) do
        if plot.active and (at-Vector3.new(plot.x,0,plot.z)).Magnitude<26 then return true end
    end
    for _,site in ipairs(Layout.LandmarkSites) do
        if (at-site.at).Magnitude<site.radius then return true end
    end
    for _,site in ipairs(Layout.CryptSites) do
        if (at-site.at).Magnitude<22 then return true end
    end
    for _,site in ipairs({{Layout.ChapelSite,28},{Layout.GateSite,22},{Layout.MemorialSite,17},{Layout.CrystalSite,22}}) do
        if (at-site[1]).Magnitude<site[2] then return true end
    end
    return false
end

local function fence(parent: Instance, name: string, frame: CFrame, width: number)
    if not AssetKit.placeGrounded(parent,name,"final_iron_fence",Vector3.new(width,6,1),frame,C.iron,Enum.Material.Metal,{groundInset=0.05}) then
        D.brokenFence(parent,name,frame.Position,math.atan2(frame.LookVector.X,frame.LookVector.Z))
    end
end

local function familyPlot(parent: Instance, index: number, plot)
    local model=P.model(parent,string.format("FamilyPlot_%02d",index))
    model:SetAttribute("VisualRegion",plot.x<0 and "OldFamilyGraveyard" or "BrokenMemorialGardens")
    local h=plot.h*0.78+0.25
    local frame=CFrame.new(plot.x,h,plot.z)*CFrame.Angles(0,math.rad(plot.angle),0)
    for grave=1,plot.count do
        local x=(grave%2==1 and -5.5 or 5.5)
        local z=-5+math.floor((grave-1)/2)*5.2
        local graveAt=frame:PointToWorldSpace(Vector3.new(x,0,z))
        D.tombstone(model,string.format("Ancestor_%02d",grave),graveAt,(index*7+grave*11)%17-8,(index+grave)%3+1)
        -- Slabs follow the same inward-facing frame as the actual headstones,
        -- not the plot's unrelated rotation. Seat their underside in the court.
        local facing=CFrame.lookAt(graveAt,Vector3.new(0,graveAt.Y,0))
        P.part(model,string.format("GraveSlab_%02d",grave),Vector3.new(3.5,0.15,4.2),facing*CFrame.new(0,0.055,-1.3),C.stoneMoss,Enum.Material.Slate,{canCollide=false})
    end
    if index%3==0 then
        AssetKit.placeGrounded(model,"FamilyMemorial","final_hero_grave",Vector3.new(6,9.5,2.6),frame*CFrame.new(0,0,5.5),C.stoneLight,Enum.Material.Slate,{groundInset=0.04})
    end
    fence(model,"RearRailing",frame*CFrame.new(0,0,9),18)
    if index%2==0 then fence(model,"BrokenSideRailing",frame*CFrame.new(-12,0,0)*CFrame.Angles(0,math.pi/2,0),12) end
    D.candle(model,"Vigil",frame:PointToWorldSpace(Vector3.new(0,0,-7)),index%3==0)
    D.candle(model,"CornerVigil",frame:PointToWorldSpace(Vector3.new(9.1,0,7.4)),false)
    if index%2==1 then
        D.pumpkin(model,"AutumnMemorial",frame:PointToWorldSpace(Vector3.new(-9,0,6.8)))
    end
    D.rubble(model,"CollapsedCorner",frame:PointToWorldSpace(Vector3.new(10,0,6)),math.rad(plot.angle),1.5)
end

local function oldCrypt(parent: Instance, name: string, at: Vector3, angle: number)
    at=Grounding.position(parent,at)
    local model=P.model(parent,name)
    local frame=CFrame.new(at)*CFrame.Angles(0,angle,0)
    local function part(n: string,size: Vector3,p: Vector3,color: Color3)
        return P.part(model,n,size,frame*CFrame.new(p),color,Enum.Material.Slate)
    end
    part("Foundation",Vector3.new(18,0.6,17),Vector3.new(0,0.3,0),C.stoneDark)
    part("RearWall",Vector3.new(16,12,2),Vector3.new(0,6.6,6.5),C.stone)
    for _,side in ipairs({-1,1}) do
        part("SideWall"..side,Vector3.new(2,12,13),Vector3.new(side*7,6.6,0),C.stone)
        AssetKit.placeGrounded(model,"Buttress"..side,"final_buttress",Vector3.new(2.5,11,4),frame*CFrame.new(side*8.5,0,1),C.stoneMoss,Enum.Material.Slate)
    end
    AssetKit.placeGrounded(model,"PointedEntry","final_gothic_doorway",Vector3.new(16,16,2.4),frame*CFrame.new(0,0.6,-6.5),C.stoneLight,Enum.Material.Slate,{groundInset=0.04})
    AssetKit.placeGrounded(model,"CrookedRoof","final_crooked_roof",Vector3.new(20,12,19),frame*CFrame.new(0,12.6,0),C.roof,Enum.Material.Slate,{groundInset=0.08})
    local rune=part("DoorWard",Vector3.new(0.4,2.2,0.13),Vector3.new(0,4,5.35),C.violet)
    rune.Material=Enum.Material.Neon
    rune.CanCollide=false
    D.pumpkin(model,"ForgottenOffering",frame:PointToWorldSpace(Vector3.new(-10,0,-8)))
end

function Cemetery.build(map: Model)
    local cemetery=P.model(map,"Cemetery")
    for index,plot in ipairs(TerrainArt.Plots) do
        if plot.active then familyPlot(cemetery,index,plot) end
    end
    local woodland=P.model(map,"HauntedWoodland")
    -- Deterministic candidates cover the larger world, but a hard population
    -- cap avoids multiplying hundreds of cosmetic leaf/branch objects.
    local treeCount=0
    local families={"haunted","dead","autumn","sparse","broken","haunted","stump"}
    for index=0,229 do
        if treeCount>=128 then break end
        local angle=math.rad(index*137.508+17)
        local radius=94+(index*37)%263
        local at=D.polar(radius,angle)
        local scale=0.86+index%5*0.14
        if not Layout.reserved(at,13*scale) and not inComposedClearing(at) then
            treeCount+=1
            local family=families[index%#families+1]
            -- Eastern/Northern pockets are predominantly bare; South/West
            -- autumn clumps frame graveyards without hiding the castle crown.
            if at.X>175 and at.Z<40 and family=="haunted" then family="dead" end
            D.treeFamily(woodland,string.format("ForestTree_%03d",index+1),at,angle+index*0.31,family,scale)
            if index%6==0 then
                AssetKit.placeGrounded(woodland,string.format("AncientRoot_%02d",index+1),"root_serpent",Vector3.new(15,4.5,9),
                    CFrame.new(Grounding.position(woodland,at+Vector3.new(4,0,1)))*CFrame.Angles(0,angle,0),C.root,Enum.Material.Wood,{groundInset=0.22})
            end
        end
    end
    map:SetAttribute("PlayableForestTreeCount",treeCount)
    for index,site in ipairs(Layout.CryptSites) do
        if not Layout.reserved(site.at,15) then oldCrypt(cemetery,string.format("ForgottenCrypt_%02d",index),site.at,site.angle) end
    end
    for index=0,25 do
        local angle=math.rad(index*111+32)
        local at=D.polar(118+(index*29)%210,angle)
        if not Layout.reserved(at,4) then
            D.rubble(woodland,string.format("BuriedMonument_%02d",index+1),at,angle,1.8+index%3*0.5)
            if index%4==0 then D.pumpkin(woodland,string.format("RuinOffering_%02d",index+1),at+Vector3.new(5,0,2)) end
        end
    end
    return cemetery
end
return Cemetery
