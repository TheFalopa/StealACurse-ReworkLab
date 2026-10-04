-- Partition coplanar road footprints instead of stacking visible road faces.
-- Original slabs remain invisible collision support with exactly their old size.
local Resolver = {}
local EPS = 1e-6

local function cross(a: Vector2,b: Vector2): number return a.X*b.Y-a.Y*b.X end
local function area(poly)
	local sum=0
	for i,p in poly do sum+=cross(p,poly[i%#poly+1]) end
	return math.abs(sum)*.5
end

local function split(poly,a,b)
	local inside,outside={},{}
	local edge=b-a
	for i,p in poly do
		local q=poly[i%#poly+1]
		local dp,dq=cross(edge,p-a),cross(edge,q-a)
		if dp>=-EPS then table.insert(inside,p) end
		if dp<=EPS then table.insert(outside,p) end
		if (dp>EPS and dq< -EPS) or (dp< -EPS and dq>EPS) then
			local hit=p:Lerp(q,dp/(dp-dq))
			table.insert(inside,hit) table.insert(outside,hit)
		end
	end
	return inside,outside
end

local function subtract(poly,cutter)
	local pieces={}
	local remaining=poly
	for i,a in cutter do
		if #remaining<3 then break end
		local inside,outside=split(remaining,a,cutter[i%#cutter+1])
		if #outside>=3 and area(outside)>.0001 then table.insert(pieces,outside) end
		remaining=inside
	end
	return pieces
end

local function rectangle(part)
	local poly={}
	local half=part.Size*.5
	for _,v in {Vector3.new(-half.X,0,-half.Z),Vector3.new(half.X,0,-half.Z),
		Vector3.new(half.X,0,half.Z),Vector3.new(-half.X,0,half.Z)} do
		local p=part.CFrame:PointToWorldSpace(v)
		table.insert(poly,Vector2.new(p.X,p.Z))
	end
	return poly
end

local function intersectionArea(poly,cutter)
	local remaining=poly
	for i,a in cutter do
		if #remaining<3 then return 0 end
		remaining=split(remaining,a,cutter[i%#cutter+1])
	end
	return if #remaining>=3 then area(remaining) else 0
end

local function wedge(parent,source,frame,size,name)
	if size.Y<.0001 or size.Z<.0001 then return end
	local p=Instance.new("WedgePart")
	p.Name=name
	p.Size=size
	p.CFrame=frame
	p.Color=source.Color
	p.Material=source.Material
	p.MaterialVariant=source.MaterialVariant
	p.Anchored=true
	p.CanCollide=false
	p.CanTouch=false
	p.CanQuery=false
	p.CastShadow=false
	p:SetAttribute("ResolvedRoadSurface",true)
	p:SetAttribute("SourceRoad",source.Name)
	p.Parent=parent
end

local function triangle(parent,source,a,b,c,index)
	local ab,ac,bc=b-a,c-a,c-b
	local abd,acd,bcd=ab:Dot(ab),ac:Dot(ac),bc:Dot(bc)
	if abd>acd and abd>bcd then c,a=a,c
	elseif acd>abd and acd>bcd then a,b=b,a end
	ab,ac,bc=b-a,c-a,c-b
	local normal=ac:Cross(ab)
	if normal.Magnitude<.00001 then return end
	local right=normal.Unit
	local back=bc.Unit
	local up=bc:Cross(right).Unit
	local height=math.abs(ab:Dot(up))
	local thickness=.025
	wedge(parent,source,CFrame.fromMatrix((a+b)*.5,right,up,back),
		Vector3.new(thickness,height,math.abs(ab:Dot(back))),string.format("%s_%03d_A",source.Name,index))
	wedge(parent,source,CFrame.fromMatrix((a+c)*.5,-right,up,-back),
		Vector3.new(thickness,height,math.abs(ac:Dot(back))),string.format("%s_%03d_B",source.Name,index))
end

function Resolver.apply(map: Model)
	local paths=map:FindFirstChild("Paths")
	if not paths then return end
	local roads={}
	for _,p in paths:GetDescendants() do
		if p:IsA("Part") and p.Shape==Enum.PartType.Block and p.Transparency<.5
			and p.CFrame.UpVector.Y>.9999 and p:GetAttribute("RoadSlab") then
			table.insert(roads,{part=p,poly=rectangle(p),top=p.Position.Y+p.Size.Y*.5})
		end
	end
	-- Wider roads own crossings. Stable order makes material patches reproducible.
	table.sort(roads,function(a,b)
		if math.abs(a.part.Size.X-b.part.Size.X)>.001 then return a.part.Size.X>b.part.Size.X end
		return a.part.Name<b.part.Name
	end)
	local group=Instance.new("Folder")
	group.Name="ResolvedPavement"
	group.Parent=paths
	local overlaps,changed,triangles=0,0,0
	for i,entry in roads do
		local pieces={entry.poly}
		for j=1,i-1 do
			local prior=roads[j]
			if math.abs(entry.top-prior.top)<.002 and intersectionArea(entry.poly,prior.poly)>.001 then
				overlaps+=1
				local nextPieces={}
				for _,poly in pieces do
					for _,piece in subtract(poly,prior.poly) do table.insert(nextPieces,piece) end
				end
				pieces=nextPieces
			end
		end
		local retained=0
		for _,poly in pieces do retained+=area(poly) end
		if area(entry.poly)-retained>.001 then
			changed+=1
			entry.part.Transparency=1
			entry.part.CastShadow=false
			entry.part:SetAttribute("RoadCollisionSupport",true)
			entry.part:SetAttribute("RetainedVisibleArea",retained)
			-- Put the broad wedge face exactly on the old slab top. Its thickness
			-- extends equally around that plane; 0.0125 stud is visually negligible.
			for _,poly in pieces do
				for k=2,#poly-1 do
					triangles+=1
					local function world(v) return Vector3.new(v.X,entry.top-.0125,v.Y) end
					triangle(group,entry.part,world(poly[1]),world(poly[k]),world(poly[k+1]),triangles)
				end
			end
		end
	end
	map:SetAttribute("RoadCoplanarPairsResolved",overlaps)
	map:SetAttribute("RoadSlabsPartitioned",changed)
	map:SetAttribute("RoadSurfaceTriangles",triangles)
	map:SetAttribute("RoadSurfaceParts",#group:GetChildren())
end

Resolver.intersectionArea=intersectionArea
Resolver.rectangle=rectangle
return Resolver
