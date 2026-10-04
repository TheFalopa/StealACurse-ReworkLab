local Config = require(script.Parent.Config)
local Layout = {}

-- One contract for server motion, paving and decoration exclusion. Coordinates
-- are local world X/Z before Build applies the existing MapElevation.
Layout.ProcessionPoints = {
	Vector3.new(0,0,0), Vector3.new(0,0,16), Vector3.new(0,0,34),
	Vector3.new(-25,0,61), Vector3.new(-60,0,58), Vector3.new(-83,0,31),
	Vector3.new(-87,0,-25), Vector3.new(-75,0,-82), Vector3.new(-42,0,-105),
	Vector3.new(15,0,-113), Vector3.new(64,0,-96), Vector3.new(91,0,-54),
	Vector3.new(107,0,2), Vector3.new(130,0,35), Vector3.new(144,0,79),
	Vector3.new(160,0,112),
}
Layout.ProcessionHalfWidth = 9

-- Irregular inner connections, an open undercroft shortcut and neighbor lanes.
Layout.CrossTrails = {
	{ Vector3.new(0,0,85), Vector3.new(58,0,106), Vector3.new(131,0,96) },
	{ Vector3.new(131,0,96), Vector3.new(150,0,45), Vector3.new(124,0,-1) },
	{ Vector3.new(124,0,-1), Vector3.new(133,0,-72), Vector3.new(84,0,-118) },
	{ Vector3.new(84,0,-118), Vector3.new(45,0,-142), Vector3.new(0,0,-128) },
	{ Vector3.new(0,0,-128), Vector3.new(-46,0,-140), Vector3.new(-87,0,-111) },
	{ Vector3.new(-87,0,-111), Vector3.new(-123,0,-65), Vector3.new(-104,0,-20) },
	{ Vector3.new(-104,0,-20), Vector3.new(-127,0,44), Vector3.new(-103,0,86) },
	{ Vector3.new(-103,0,86), Vector3.new(-53,0,112), Vector3.new(0,0,85) },
	{ Vector3.new(0,0,85), Vector3.new(0,0,34) },
	{ Vector3.new(0,0,-128), Vector3.new(0,0,-73) },
	{ Vector3.new(131,0,96), Vector3.new(130,0,35) },
}
for index = 1, Config.BaseCount do
	local nextIndex = index % Config.BaseCount + 1
	local first = Config.baseFrame(index):PointToWorldSpace(Vector3.new(0,0,-45))
	local last = Config.baseFrame(nextIndex):PointToWorldSpace(Vector3.new(0,0,-45))
	local middle = (first+last)/2
	middle += Vector3.new(index%2==0 and 7 or -9,0,index%3==0 and 8 or -5)
	table.insert(Layout.CrossTrails,{Vector3.new(first.X,0,first.Z),Vector3.new(middle.X,0,middle.Z),Vector3.new(last.X,0,last.Z)})
end

Layout.LandmarkSites = {
	{ name="WidowsOak", at=Vector3.new(-181,0,116), radius=22, angle=0.3, scale=1.25 },
	{ name="HollowSentinel", at=Vector3.new(87,0,-205), radius=22, angle=2.6, scale=1.2 },
	{ name="ChainedTree", at=Vector3.new(257,0,89), radius=21, angle=1.1, scale=1.05 },
	{ name="MourningTree", at=Vector3.new(-191,0,-102), radius=22, angle=3.9, scale=1.15 },
}
Layout.ChapelSite = Vector3.new(-118,0,-291)
Layout.GateSite = Vector3.new(102,0,253)
Layout.MemorialSite = Vector3.new(181,0,-46)
Layout.CrystalSite = Vector3.new(-275,0,110)
Layout.CryptSites = {
	{ at=Vector3.new(-80,0,-301), angle=0.2 },
	{ at=Vector3.new(-155,0,251), angle=-0.4 },
	{ at=Vector3.new(173,0,264), angle=1.6 },
	{ at=Vector3.new(317,0,-119), angle=2.8 },
}

function Layout.segmentDistance(at: Vector3, first: Vector3, last: Vector3): number
	local a, b = Vector3.new(first.X,0,first.Z), Vector3.new(last.X,0,last.Z)
	local point = Vector3.new(at.X,0,at.Z)
	local delta = b-a
	if delta:Dot(delta)<0.0001 then return (point-a).Magnitude end
	local t = math.clamp((point-a):Dot(delta)/delta:Dot(delta),0,1)
	return (point-(a+delta*t)).Magnitude
end

function Layout.processionReserved(at: Vector3, radius: number): boolean
	for section=1,#Layout.ProcessionPoints-1 do
		if Layout.segmentDistance(at,Layout.ProcessionPoints[section],Layout.ProcessionPoints[section+1])<Layout.ProcessionHalfWidth+radius then return true end
	end
	return false
end

function Layout.reserved(at: Vector3, radius: number): boolean
	if at.X > -58-radius and at.X < 58+radius and at.Z > -86-radius and at.Z < 9+radius then return true end
	if Layout.processionReserved(at,radius) then return true end
	for index=1,Config.BaseCount do
		local p=Config.baseFrame(index):PointToObjectSpace(at)
		if math.abs(p.X)<39+radius and math.abs(p.Z)<42+radius then return true end
		local points=Config.approachPoints(index)
		for section=1,#points-1 do
			if Layout.segmentDistance(at,points[section],points[section+1])<11+radius then return true end
		end
	end
	for _,points in ipairs(Layout.CrossTrails) do
		for section=1,#points-1 do
			if Layout.segmentDistance(at,points[section],points[section+1])<7+radius then return true end
		end
	end
	return false
end

return Layout
