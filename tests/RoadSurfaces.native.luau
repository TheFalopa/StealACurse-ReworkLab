-- Read-only validation of the actual generated Roblox faces and collision slabs.
local paths=workspace.StealACurseMap.Paths
local function signed(poly)
	local a=0
	for i,p in poly do local q=poly[i%#poly+1];a+=p.X*q.Y-q.X*p.Y end
	return a*.5
end
local function normalize(poly)
	if signed(poly)<0 then local a={};for i=#poly,1,-1 do table.insert(a,poly[i]) end;return a end
	return poly
end
local function cross(a,b) return a.X*b.Y-a.Y*b.X end
local function clip(subject,cutter)
	for i,a in cutter do
		local b=cutter[i%#cutter+1];local nextPoly={}
		for j,p in subject do
			local q=subject[j%#subject+1];local d=cross(b-a,p-a);local e=cross(b-a,q-a)
			if d>=0 then table.insert(nextPoly,p) end
			if (d>0 and e<0) or (d<0 and e>0) then table.insert(nextPoly,p:Lerp(q,d/(d-e))) end
		end
		subject=nextPoly;if #subject<3 then return 0 end
	end
	return math.abs(signed(subject))
end
local function contains(poly,p)
	for i,a in poly do if cross(poly[i%#poly+1]-a,p-a)<-.001 then return false end end
	return true
end
local faces,slabs={},{}
local summary={surfaces=0,slabs=0,overlapPairs=0,maxOverlapArea=0,holes=0,coverageSamples=0,supportFailures=0,unpainted=0,maxPlaneError=0}
for _,p in paths:GetDescendants() do
	if p:IsA('BasePart') and (p:GetAttribute('RoadSlab') or p:GetAttribute('ResolvedRoadSurface')) then
		local h=p.Size*.5;local points={};local top
		if p:IsA('WedgePart') then
			local x=if p.CFrame.RightVector.Y>0 then h.X else -h.X
			for _,v in {Vector3.new(x,-h.Y,-h.Z),Vector3.new(x,-h.Y,h.Z),Vector3.new(x,h.Y,h.Z)} do
				local q=p.CFrame:PointToWorldSpace(v);top=q.Y;table.insert(points,Vector2.new(q.X,q.Z))
			end
			summary.surfaces+=1
		else
			for _,v in {Vector3.new(-h.X,h.Y,-h.Z),Vector3.new(h.X,h.Y,-h.Z),Vector3.new(h.X,h.Y,h.Z),Vector3.new(-h.X,h.Y,h.Z)} do
				local q=p.CFrame:PointToWorldSpace(v);top=q.Y;table.insert(points,Vector2.new(q.X,q.Z))
			end
			table.insert(slabs,{part=p,poly=normalize(points),top=top});summary.slabs+=1
			if not p.CanCollide then summary.supportFailures+=1 end
		end
		if p.Transparency<.5 then
			if p.MaterialVariant=='' then summary.unpainted+=1 end
			table.insert(faces,{name=p.Name,poly=normalize(points),top=top})
		end
	end
end
local examples={}
for i,a in faces do
	for j=i+1,#faces do
		local b=faces[j]
		if math.abs(a.top-b.top)<.002 then
			local overlap=clip(a.poly,b.poly)
			summary.maxOverlapArea=math.max(summary.maxOverlapArea,overlap)
			if overlap>.01 then summary.overlapPairs+=1;if #examples<6 then table.insert(examples,{a.name,b.name,overlap}) end end
		end
	end
end
for _,s in slabs do
	for ix=1,7 do for iz=1,7 do
		local point=s.poly[1]+(s.poly[2]-s.poly[1])*(ix/8)+(s.poly[4]-s.poly[1])*(iz/8)
		summary.coverageSamples+=1;local covered=false
		for _,face in faces do if math.abs(face.top-s.top)<.002 and contains(face.poly,point) then covered=true;break end end
		if not covered then summary.holes+=1 end
	end end
end
summary.examples=examples
return summary
