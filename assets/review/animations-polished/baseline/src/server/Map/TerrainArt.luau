local Config=require(script.Parent.Config)
local P=require(script.Parent.Primitives)
local D=require(script.Parent.Decorations)
local Layout=require(script.Parent.Layout)
local TerrainArt={}
local C=Config.Colors

-- Irregular family plots: each is authored as a cluster, with lanes reserved.
TerrainArt.Plots={
    {x=-53,z=170,h=3.0,angle=12,count=6}, {x=75,z=170,h=2.8,angle=-32,count=5},
    {x=198,z=62,h=4.0,angle=24,count=6}, {x=149,z=-123,h=3.2,angle=83,count=4},
    {x=-128,z=-181,h=4.0,angle=116,count=5}, {x=-211,z=15,h=3.5,angle=175,count=6},
    {x=-177,z=69,h=4.2,angle=168,count=4}, {x=254,z=145,h=2.8,angle=208,count=6},
    {x=-69,z=-195,h=4.0,angle=235,count=5}, {x=60,z=-192,h=3.2,angle=274,count=6},
    {x=-250,z=-117,h=4.4,angle=319,count=4}, {x=-246,z=130,h=3.2,angle=355,count=5},
    {x=-153,z=-71,h=2.7,angle=21,count=4}, {x=-95,z=-260,h=3.4,angle=147,count=4},
    {x=127,z=-255,h=3.1,angle=90,count=5}, {x=-107,z=253,h=3.8,angle=201,count=4},
    {x=128,z=160,h=2.8,angle=31,count=4}, {x=-95,z=153,h=3.0,angle=275,count=4},
    {x=-265,z=81,h=2.9,angle=317,count=4}, {x=239,z=-108,h=3.2,angle=51,count=4},
}

function TerrainArt.build(map: Model)
    local land=P.model(map,"CemeteryTerrain")
    for index,plot in ipairs(TerrainArt.Plots) do
        local at=Vector3.new(plot.x,0,plot.z)
        local angle=math.rad(plot.angle)
        -- Decorations sit on the raised plot, away from comfortable running lines.
        if not Layout.reserved(at,21) then
            plot.active=true
            P.part(land,string.format("BurialHill_%02d",index),Vector3.new(31,plot.h*2,29),
                CFrame.new(at+Vector3.new(0,-plot.h*0.22,0))*CFrame.Angles(0,angle,0),index%3==0 and C.groundPatch or C.soil,Enum.Material.Ground,{shape=Enum.PartType.Ball})
            P.part(land,string.format("RaisedBurialTerrace_%02d",index),Vector3.new(26,0.5,20),
                CFrame.new(at+Vector3.new(0,plot.h*0.78,0))*CFrame.Angles(0,angle,0),C.soil,Enum.Material.Ground)
            for shoulder=1,2 do
                P.part(land,string.format("BurialShoulder_%02d_%d",index,shoulder),Vector3.new(23,plot.h,17),
                    CFrame.new(at+Vector3.new(shoulder==1 and -9 or 9,-0.7,2)),C.groundPatch,Enum.Material.Ground,
                    {shape=Enum.PartType.Ball,canCollide=false})
            end
        else
            plot.active=false
        end
    end
    for index=1,Config.BaseCount do
        local site=Config.baseFrame(index)
        local height=Config.BaseSites[index].height
        P.part(land,string.format("SanctuaryLand_%02d",index),Vector3.new(85,(height+0.8)*2,91),
            CFrame.new(site.Position.X,0,site.Position.Z)*CFrame.Angles(0,math.rad(Config.BaseSites[index].degrees),0),
            index%2==0 and C.groundPatch or C.soil,Enum.Material.Ground,{shape=Enum.PartType.Ball})
    end
    -- Off-lane embankments frame approaches without surrounding each base.
    for index=0,25 do
        local angle=math.rad(index*137.5+11)
        local radius=152+index%5*39
        local at=D.polar(radius,angle)
        if not Layout.reserved(at,28) then
            P.part(land,string.format("RollingBank_%02d",index+1),Vector3.new(33,8+index%3*3,46),
                CFrame.new(at+Vector3.new(0,-2.5,0))*CFrame.Angles(0,angle,0),C.groundPatch,Enum.Material.Ground,{shape=Enum.PartType.Ball})
        end
    end
    return land
end
return TerrainArt
