-- Real production architecture calls against disposable off-Workspace bases.
-- These are structural/property checks, not avatar movement or visual approval.
return function(t)
	local A = require(game.ServerScriptService.Server.Map.RestorationArchitecture)
	local C = require(game.ReplicatedStorage.Shared.SanctuaryConfig)
	local Catalog = require(game.ReplicatedStorage.Shared.CurseCatalog)
	local Presentation = require(game.ReplicatedStorage.Shared.CurseVisualPass2)
	local e = t.expect
	local expected = { [0] = 5, 6, 8, 10, 14, 18, 18, 22, 26, 26, 30 }
	local rows = { -15, 3, 21, 39, 57 }
	local function near(actual, value, epsilon)
		e.truthy(math.abs(actual-value) <= (epsilon or 0.0001))
	end
	local function count(dictionary)
		local n=0; for _ in pairs(dictionary) do n+=1 end; return n
	end
	local function makePart(parent,name,size,cf,class)
		local item=Instance.new(class or "Part")
		item.Name=name; item.Size=size; item.CFrame=cf; item.Anchored=true
		item.CanCollide=false; item.CanTouch=false; item.Transparency=1
		item:SetAttribute("RestorationArchitecture",true)
		item.Parent=parent; return item
	end
	local function fixture()
		local container=Instance.new("Folder"); container.Name="DisposableArchitectureSpec"
		local base=Instance.new("Model"); base.Name="BaseSpec"; base.Parent=container
		local frame=CFrame.new(123,7,-81)*CFrame.Angles(0,0.83,0)
		makePart(base,"PlayerSpawn",Vector3.new(6,1,6),frame*CFrame.new(0,1.4,-18),"SpawnLocation")
		makePart(base,"SanctuaryFloor",Vector3.new(104,0.8,104),frame*CFrame.new(0,0.4,16))
		makePart(base,"FutureCurseDisplayArea",Vector3.new(66,0.2,98),frame*CFrame.new(0,1.25,17))
		makePart(base,"RestorationAltar",Vector3.one,frame*CFrame.new(-10,3,-27))
		makePart(base,"SealBarrier",Vector3.new(24,21,0.8),frame*CFrame.new(0,11.65,-34))
		local ritual=Instance.new("Folder"); ritual.Name="RitualMarkers"; ritual.Parent=base
		for i,p in ipairs({Vector3.new(-7.5,1.25,-8),Vector3.new(7.5,1.25,-8),Vector3.new(0,1.25,13)}) do
			makePart(ritual,"RitualMark_"..i,Vector3.new(3.8,0.2,3.8),frame*CFrame.new(p))
		end
		local recovery=Instance.new("Folder"); recovery.Name="RecoveryBays"; recovery.Parent=base
		for i=1,6 do
			makePart(recovery,"RecoveryBay_"..i,Vector3.new(1,0.1,1),frame*CFrame.new(i%2==1 and -8 or 8,1.15,-15+math.floor((i-1)/2)*20))
		end
		local markers={}
		for floor=1,3 do
			for slot=1,10 do
				local id=string.format("floor%d-slot%d",floor,slot)
				local name=if floor==1 and slot<=5 then "DisplayPlinth_"..slot else string.format("DisplayPlinth_floor%d_slot%d",floor,slot)
				local marker=makePart(base,name,Vector3.new(5.6,2.25,5.6),
					frame*CFrame.new(slot%2==1 and -23 or 23,2.275+(floor-1)*22,rows[math.ceil(slot/2)]))
				marker:SetAttribute("LogicalPedestalId",id); marker:SetAttribute("PedestalBaseId",base.Name)
				marker:SetAttribute("FloorIndex",floor); marker:SetAttribute("SlotIndex",slot)
				if floor==1 and slot<=5 then marker:SetAttribute("LegacySlotIndex",slot) end
				markers[id]=marker
			end
		end
		return container,base,frame,markers
	end
	local function withBase(callback)
		local container,base,frame,markers=fixture()
		local ok,err=pcall(callback,base,frame,markers,container)
		container:Destroy()
		if not ok then error(err) end
	end
	local function physicalCounts(base)
		local parts,lights=0,0
		for _,item in ipairs(base:GetDescendants()) do
			if item:IsA("BasePart") then parts+=1 end
			if item:IsA("PointLight") then lights+=1 end
		end
		return parts,lights
	end
	local function localBounds(frame,item)
		local cf=frame:ToObjectSpace(item.CFrame); local half=item.Size*0.5
		local x=math.abs(cf.RightVector.X)*half.X+math.abs(cf.UpVector.X)*half.Y+math.abs(cf.LookVector.X)*half.Z
		local z=math.abs(cf.RightVector.Z)*half.X+math.abs(cf.UpVector.Z)*half.Y+math.abs(cf.LookVector.Z)*half.Z
		return cf.Position.X-x,cf.Position.X+x,cf.Position.Z-z,cf.Position.Z+z
	end

	t.test("all eleven levels and three styles expose exactly their configured capacity",function()
		withBase(function(base,_,markers)
			for level=0,10 do
				for _,style in ipairs(C.StyleOrder) do
					local view=A.apply(base,level,style,nil)
					e.equal(count(view.pedestals),expected[level]); e.equal(expected[level],C.Levels[level].capacity)
					e.equal(base:GetAttribute("SanctuaryCapacity"),expected[level]); e.equal(base:GetAttribute("SanctuaryStyle"),style)
					local active=0
					for id,marker in pairs(markers) do
						if marker:GetAttribute("PedestalActive") then
							active+=1; e.equal(marker:GetAttribute("PedestalId"),id); e.equal(view.pedestals[id],marker)
							e.truthy(marker.CanCollide); e.truthy(marker.CanQuery)
						else
							e.equal(marker:GetAttribute("PedestalId"),nil); e.falsy(marker.CanCollide); e.falsy(marker.CanQuery)
						end
					end
					e.equal(active,expected[level])
				end
			end
		end)
	end)
	t.test("pedestal Instances CFrames IDs and original five names persist through all rebuilds",function()
		withBase(function(base,_,markers)
			local frames={}; for id,marker in pairs(markers) do frames[id]=marker.CFrame end
			for level=0,10 do
				for _,style in ipairs(C.StyleOrder) do
					A.apply(base,level,style,nil)
					for id,marker in pairs(markers) do
						e.equal(marker.Parent,base); e.equal(marker.CFrame,frames[id]); e.equal(marker:GetAttribute("LogicalPedestalId"),id)
					end
					for slot=1,5 do
						e.equal(base:FindFirstChild("DisplayPlinth_"..slot),markers["floor1-slot"..slot])
						e.equal(markers["floor1-slot"..slot]:GetAttribute("LegacySlotIndex"),slot)
					end
				end
			end
		end)
	end)
	t.test("occupied pedestal and service-owned prompts survive upgrades and style changes",function()
		withBase(function(base,_,markers)
			A.apply(base,5,"CRYPT",nil)
			local marker=markers["floor2-slot8"]
			marker:SetAttribute("OccupiedCurseUid","still-owned"); marker:SetAttribute("PedestalOwnerUserId",12345)
			local prompt=Instance.new("ProximityPrompt"); prompt.Name="PlaceOwnCurse"; prompt.Parent=marker
			for level=5,10 do
				for _,style in ipairs(C.StyleOrder) do
					A.apply(base,level,style,"floor2-slot8")
						e.equal(marker:GetAttribute("OccupiedCurseUid"),"still-owned"); e.equal(marker:GetAttribute("PedestalOwnerUserId"),12345)
						e.equal(prompt.Parent,marker); e.truthy(marker:GetAttribute("FeaturedPedestal"))
				end
			end
		end)
	end)
	t.test("occupied deactivation rejects before replacing architecture or changing slot state",function()
		withBase(function(base,_,markers)
			A.apply(base,10,"FOREST",nil); markers["floor3-slot10"]:SetAttribute("OccupiedCurseUid","owned")
			local previous=base.RestorationDecor; local revision=base:GetAttribute("ArchitectureRevision")
			e.throws(function() A.apply(base,0,"CRYPT",nil) end)
			e.equal(base.RestorationDecor,previous); e.equal(base:GetAttribute("ArchitectureRevision"),revision)
			e.equal(base:GetAttribute("SanctuaryCapacity"),30); e.equal(markers["floor3-slot10"]:GetAttribute("PedestalId"),"floor3-slot10")
			e.equal(markers["floor3-slot10"]:GetAttribute("OccupiedCurseUid"),"owned")
		end)
	end)
	t.test("invalid levels styles and incomplete marker inventory leave prior architecture intact",function()
		withBase(function(base,_,markers)
			A.apply(base,0,"CRYPT",nil); local previous=base.RestorationDecor; local revision=base:GetAttribute("ArchitectureRevision")
			for _,call in ipairs({function() A.apply(base,11,"CRYPT",nil) end,function() A.apply(base,0,"UNKNOWN",nil) end}) do
				e.throws(call); e.equal(base.RestorationDecor,previous); e.equal(base:GetAttribute("ArchitectureRevision"),revision)
			end
			markers["floor1-slot1"]:Destroy()
			e.throws(function() A.apply(base,0,"CRYPT",nil) end); e.equal(base.RestorationDecor,previous)
		end)
	end)
	t.test("seal barrier collision state and owner constraints survive every style rebuild",function()
		withBase(function(base,_,_,container)
			A.apply(base,6,"CRYPT",nil)
			local gate=base.SealBarrier; gate.CanCollide=true; gate.Transparency=0.45
			local ownerPart=makePart(container,"OwnerPart",Vector3.one,CFrame.new())
			local constraint=Instance.new("NoCollisionConstraint"); constraint.Part0=gate; constraint.Part1=ownerPart; constraint.Parent=gate
			for _,style in ipairs(C.StyleOrder) do
				A.apply(base,9,style,nil)
				e.equal(base.SealBarrier,gate); e.truthy(gate.CanCollide); near(gate.Transparency,0.45)
				e.equal(constraint.Parent,gate); e.equal(constraint.Part0,gate); e.equal(constraint.Part1,ownerPart)
			end
		end)
	end)
	t.test("feature selection marks one real pedestal without cloning a Curse or changing transforms",function()
		withBase(function(base,_,markers)
			A.apply(base,10,"CRYPT",nil)
			local curse=Instance.new("Model"); curse.Name="ExistingOwnedCurse"; curse:SetAttribute("CurseUid","single-real-instance"); curse.Parent=base
			local original=markers["floor3-slot10"].CFrame
			for _,style in ipairs(C.StyleOrder) do
				A.apply(base,10,style,"floor3-slot10"); local featured=0; local real=0
				for _,marker in pairs(markers) do if marker:GetAttribute("FeaturedPedestal") then featured+=1 end end
				for _,item in ipairs(base:GetDescendants()) do if item:GetAttribute("CurseUid")=="single-real-instance" then real+=1 end end
				e.equal(featured,1); e.equal(real,1); e.equal(curse.Parent,base); e.equal(markers["floor3-slot10"].CFrame,original)
			end
			A.apply(base,0,"CRYPT","floor3-slot10"); e.equal(base:GetAttribute("FeaturedPedestalId"),nil)
		end)
	end)
	t.test("real world frame follows translated spawn rather than stale original elevation",function()
		withBase(function(base,frame,markers)
			A.apply(base,0,"CRYPT",nil)
			local offset=Vector3.new(-31,4,16)
			for _,item in ipairs(base:GetDescendants()) do if item:IsA("BasePart") then item.CFrame+=offset end end
			local view=A.apply(base,4,"OBSERVATORY",nil)
			near((view.frame.Position-(frame.Position+offset)).Magnitude,0)
			near((base:GetAttribute("SanctuaryFrame").Position-view.frame.Position).Magnitude,0)
			local point=view.frame:PointToObjectSpace(markers["floor2-slot1"].Position)
			near(point.X,-23); near(point.Y+markers["floor2-slot1"].Size.Y/2,25.4); near(point.Z,-15)
		end)
	end)
	t.test("floor surfaces and pedestal tops give substantial clearance for actual current native templates",function()
		withBase(function(base,frame,markers)
			A.apply(base,10,"CRYPT",nil)
			local kit=game.ServerStorage:FindFirstChild("CurseMeshKit"); e.truthy(kit)
			local maxSize=Vector3.zero
			for _,id in ipairs(Catalog.enabledSpawnIds()) do
				local definition=Catalog.Definitions[id]; local mesh=kit:FindFirstChild(definition.visualKey)
				e.truthy(mesh and mesh:IsA("MeshPart")); local size=mesh.Size*Presentation.scale(id,mesh.Size)
				maxSize=Vector3.new(math.max(maxSize.X,size.X),math.max(maxSize.Y,size.Y),math.max(maxSize.Z,size.Z))
			end
			for floor=1,3 do
				local slab=base.RestorationDecor:FindFirstChild(floor==1 and "TerraceCollision" or "GalleryFloor_"..floor)
				e.truthy(slab.CanCollide); local p=frame:PointToObjectSpace(slab.Position)
				near(p.Y+slab.Size.Y/2,1.15+(floor-1)*22)
				for slot=1,10 do
					local marker=markers[string.format("floor%d-slot%d",floor,slot)]
					local top=frame:PointToObjectSpace(marker.Position).Y+marker.Size.Y/2
					near(top,3.4+(floor-1)*22)
					if floor<3 then
						local nextFloor=base.RestorationDecor:FindFirstChild("GalleryFloor_"..(floor+1))
						local underside=frame:PointToObjectSpace(nextFloor.Position).Y-nextFloor.Size.Y/2
						e.truthy(underside-top>=maxSize.Y+2)
					end
				end
			end
			e.truthy(18>=maxSize.X+2); e.truthy(24>=maxSize.X+4); e.truthy(18>=maxSize.Z+6)
		end)
	end)
	t.test("stairs use one simple continuous collision plane with matching landing and no tread collision",function()
		withBase(function(base,frame)
			A.apply(base,7,"FOREST",nil)
			for floor=1,2 do
				local ramp=base.RestorationDecor:FindFirstChild("WideStairCollision_"..floor)
				local landing=base.RestorationDecor:FindFirstChild("StairUpperLanding_"..floor)
				e.truthy(ramp.CanCollide); e.truthy(landing.CanCollide); near(ramp.Size.X,18)
				e.equal(ramp.Transparency,1)
				local cf=frame:ToObjectSpace(ramp.CFrame); local half=ramp.Size.Z/2
				local first=cf:PointToWorldSpace(Vector3.new(0,ramp.Size.Y/2,-half))
				local last=cf:PointToWorldSpace(Vector3.new(0,ramp.Size.Y/2,half))
				near(first.Y,1.15+(floor-1)*22); near(first.Z,-20)
				near(last.Y,1.15+floor*22); near(last.Z,24)
				near(math.deg(math.acos(cf.UpVector.Y)),math.deg(math.atan(0.5)))
				near(frame:PointToObjectSpace(landing.Position).Y+landing.Size.Y/2,last.Y)
				for tread=1,24 do
					local step=base.RestorationDecor:FindFirstChild("StairTread_"..floor.."_"..tread)
					e.falsy(step.CanCollide); e.falsy(step.CanQuery)
					near(step.Size.Y,22/24);e.truthy(step.Size.Z<44/24)
				end
			end
		end)
	end)
	t.test("every advanced style stays within horizontal territory and the bounded part/light budget",function()
		withBase(function(base,frame)
			for _,style in ipairs(C.StyleOrder) do
				A.apply(base,10,style,"floor3-slot10")
				local parts,lights=physicalCounts(base); e.truthy(parts<=600); e.equal(lights,8)
				e.equal(base:GetAttribute("ArchitecturePartBudget"),600)
				e.equal(base:GetAttribute("ArchitecturePartCount"),parts)
				for _,item in ipairs(base:GetDescendants()) do
					if item:IsA("BasePart") and item.Transparency<1 then
						local minX,maxX,minZ,maxZ=localBounds(frame,item)
						e.truthy(minX>=-53.5 and maxX<=53.5); e.truthy(minZ>=-36.1 and maxZ<=69.5)
					end
				end
			end
		end)
	end)
	t.test("staged floors genuinely expand and second and third stairs appear at the proper milestones",function()
		withBase(function(base)
			local sizes={}
			for level=0,10 do
				A.apply(base,level,"CRYPT",nil)
				local decor=base.RestorationDecor
				e.equal(decor:FindFirstChild("GalleryFloor_2")~=nil,level>=4)
				e.equal(decor:FindFirstChild("GalleryFloor_3")~=nil,level>=7)
				e.equal(decor:FindFirstChild("WideStairCollision_1")~=nil,level>=4)
				e.equal(decor:FindFirstChild("WideStairCollision_2")~=nil,level>=7)
				if level==4 or level==5 or level==10 then sizes[level]=decor.GalleryFloor_2.Size.Z end
			end
			e.truthy(sizes[5]>sizes[4]); e.truthy(sizes[10]>sizes[5])
		end)
	end)
	t.test("gallery floors close against walls while retaining only guarded incoming stair openings",function()
		withBase(function(base,frame)
			for level=0,10 do
				A.apply(base,level,"CRYPT",nil)
				for floor=1,base:GetAttribute("SanctuaryFloors") do
					local decor=base.RestorationDecor
					local function supported(x,z)
						for _,p in decor:GetChildren() do
							if p:IsA("BasePart") and p.CanCollide and (p:GetAttribute("SanctuaryFloorIndex")==floor or p.Name=="StairUpperLanding_"..(floor-1)) then
								local at=frame:PointToObjectSpace(p.Position)
								if math.abs(x-at.X)<p.Size.X/2-.02 and math.abs(z-at.Z)<p.Size.Z/2-.02 then return true end
							end
						end
						return false
					end
					for _,side in {-1,1} do
						for _,z in {-28,50,64} do e.truthy(supported(side*42,z)) end
					end
					if floor>1 then
						local incoming=if floor==2 then -1 else 1
						e.falsy(supported(incoming*42,0))
						e.truthy(supported(-incoming*42,0))
						local glass=decor:FindFirstChild("StairOpeningGlass_"..floor)
						e.truthy(glass and glass.CanCollide and glass.Transparency<=.4)
					end
					e.falsy(decor:FindFirstChild("GalleryRearRail_"..floor))
				end
			end
		end)
	end)
	if game.ServerStorage:FindFirstChild('ArchitectureBefore') then
		t.test('shell reconstruction preserves circulation colliders at all levels and styles',function()
			local before=require(game.ServerStorage.ArchitectureBefore.RestorationArchitecture)
			withBase(function(base,_,_,container)
				local original=base:Clone();original.Parent=container
				local function colliders(model)
					local out={}
					for _,p in model:GetDescendants() do
						if p:IsA('BasePart') and p.CanCollide and not p.Name:find('Closure') and not p.Name:find('Apron') and not p.Name:find('Opening') and (p.Name:find('Floor') or p.Name:find('Terrace') or p.Name:find('Stair') or p.Name:find('Altar') or p.Name:find('Plinth') or p.Name:find('EntrancePier')) then
							e.falsy(out[p.Name]);out[p.Name]={size=p.Size,frame=p.CFrame,query=p.CanQuery}
						end
					end
					return out
				end
				for level=0,10 do
					for _,style in C.StyleOrder do
						before.apply(original,level,style,nil);A.apply(base,level,style,nil)
						local old,new=colliders(original),colliders(base)
						e.equal(count(old),count(new))
						for name,p in old do
							e.truthy(new[name]);e.equal(new[name].size,p.size);e.equal(new[name].frame,p.frame);e.equal(new[name].query,p.query)
						end
					end
				end
			end)
		end)
	end
end
