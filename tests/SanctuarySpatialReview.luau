-- Studio-only, native Humanoid walking through the integrated architecture.
-- Root coordinates Studio/video. This module teleports only to its initial
-- start; every subsequent path and both placements require actual traversal.
return function(ctx)
	assert(game:GetService("RunService"):IsStudio(),"Local isolated spatial review only")
	local Catalog=require(game.ReplicatedStorage.Shared.CurseCatalog)
	local Presentation=require(game.ReplicatedStorage.Shared.CurseVisualPass2)
	local CarryGeometry=require(game.ReplicatedStorage.Shared.CurseCarryGeometry)
	local Visual=require(game.ServerScriptService.Server.Gameplay.CurseVisualService)
	local Architecture=require(game.ServerScriptService.Server.Map.RestorationArchitecture)
	local player,bases,curses,map=ctx.player,ctx.bases,ctx.curses,ctx.map
	local base=bases:getBaseForPlayer(player)
	assert(base and base:GetAttribute("RestorationLevel")==10,"Spatial review needs the fully restored owned sanctuary")
	local frame=Architecture.getFrame(base)
	local character=player.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	local root=character and character:FindFirstChild("HumanoidRootPart")
	assert(root and humanoid and humanoid.Health>0,"Spatial review needs a living avatar")
	local standing=humanoid.HipHeight+root.Size.Y*0.5
	if humanoid.RigType==Enum.HumanoidRigType.R6 then
		local leg=character:FindFirstChild("Left Leg")
		standing+=leg and leg.Size.Y or 2
	end
	local route,transitions,measurements={},{},{}
	local deaths,freefallTransitions,teleports,sequence=0,0,0,0
	local qaFolder
	local initialCharacter=character
	local started=os.clock()
	local function point(p)
		return { x=math.round(p.X*1000)/1000,y=math.round(p.Y*1000)/1000,z=math.round(p.Z*1000)/1000 }
	end
	local function check(ok,label,detail)
		ctx.record(ok==true,"SPATIAL / "..label,detail)
	end
	local function owned(uid)
		for _,item in curses:getOwned(player) do if item.uid==uid then return item end end
	end
	local function model(uid)
		for _,item in map.ActiveCurses:GetChildren() do if item:GetAttribute("CurseUid")==uid then return item end end
	end
	local function pedestal(id) return bases:getPedestals(base)[id] end
	local current
	for _,item in curses:getOwned(player) do
		if item.state=="UNPLACED" or (item.state=="PLACED" and string.sub(item.pedestalId or "",1,7)=="floor1-") then
			if ctx.spatialDefinitionId then
				if item.definitionId==ctx.spatialDefinitionId then current=item;break end
				continue
			end
			if item.definitionId=="grave_hopper" then current=item; break end
			if not current or item.definitionId=="cursed_doll" then current=item end
		end
	end
	assert(current,"No actual owned lower-floor or recoverable Curse available for walking")
	local initialState,initialPedestalId=current.state,current.pedestalId
	local uid,originalSlotId=current.uid,current.pedestalId or "floor1-slot2"
	local origin=pedestal(originalSlotId)
	assert(origin and model(uid) and model(uid).PrimaryPart,"Owned Curse has no valid manual destination/model")
	assert(initialState=="PLACED" or not origin:GetAttribute("OccupiedCurseUid"),"Recovery destination must be free before walking")
	assert(not player:GetAttribute("CarriedCurseUid") and not player:GetAttribute("CarriedRelicUid"),"Clear actual carry channel before spatial review")
	local originalRate=player:GetAttribute("SoulsPerSecond")
	local income=Catalog.Definitions[current.definitionId].baseSoulsPerSecond
	local expectedCarriedRate=originalRate-(if initialState=="PLACED" then income else 0)
	local expectedPlacedRate=expectedCarriedRate+income
	local originalCount=#curses:getOwned(player)
	local carryModel=model(uid)
	local sourceStart=frame:PointToObjectSpace(if initialState=="UNPLACED" then carryModel.PrimaryPart.Position else origin.Position)
	local destinationApproach=frame:PointToObjectSpace(origin.Position)
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances={base}
	params.RespectCanCollide=true
	local function supportBelow(position)
		-- A downward ray from just above the anchor bottom sees the actual ramp or
		-- floor below it. It excludes decorative/no-query meshes and other bases.
		local hit=workspace:Raycast(position+Vector3.new(0,4,0),Vector3.new(0,-18,0),params)
		return hit
	end
	local minCarryClearance,maxCarryOutside,minBodyPathError=math.huge,0,0
	local function sampleCarry()
		if curses:getState(uid)~="CARRYING" then return nil end
		local anchor=carryModel and carryModel.PrimaryPart
		if not anchor then return nil end
		local predicted=CarryGeometry.follow(root.CFrame,anchor.Size,map,base)
		local bottom=predicted.Position-Vector3.new(0,anchor.Size.Y*0.5,0)
		local hit=supportBelow(bottom)
		local clearance=if hit then bottom.Y-hit.Position.Y else nil
		local p=frame:PointToObjectSpace(predicted.Position)
		local right=frame:VectorToObjectSpace(predicted.RightVector)
		local look=frame:VectorToObjectSpace(predicted.LookVector)
		local halfX=math.abs(right.X)*anchor.Size.X*.5+math.abs(look.X)*anchor.Size.Z*.5
		local outside=math.max(0,math.abs(p.X)+halfX-51)
		if clearance then minCarryClearance=math.min(minCarryClearance,clearance) end
		maxCarryOutside=math.max(maxCarryOutside,outside)
		return { clearance=clearance and math.round(clearance*1000)/1000,
			floor=hit and hit.Instance.Name, outsideWall=math.round(outside*1000)/1000,
			position=point(p), authoritativePosition=point(frame:PointToObjectSpace(anchor.Position)),
			 source="production CurseCarryGeometry.follow at real avatar CFrame; no client bone-pose measurement" }
	end
	local function carryMeasurementSummary(completed)
		return {minimumFootClearance=if minCarryClearance<math.huge then math.round(minCarryClearance*1000)/1000 else nil,
			maximumOutsidePerimeter=math.round(maxCarryOutside*1000)/1000,minimumBodyPathError=math.round(minBodyPathError*1000)/1000,
			needsFloorClamp=minCarryClearance<-.25,needsLateralClamp=maxCarryOutside>.25,completed=completed,
			method="actual avatar transforms with production CurseCarryGeometry.follow and raycast support; not rendered bone bounds"}
	end
	local died=humanoid.Died:Connect(function() deaths+=1 end)
	local stateChanged=humanoid.StateChanged:Connect(function(_,state)
		if state==Enum.HumanoidStateType.Freefall then freefallTransitions+=1 end
		table.insert(transitions,{time=math.round((os.clock()-started)*100)/100,state=state.Name})
	end)
	local function walk(label,x,groundY,z)
		sequence+=1
		local goal=frame:PointToWorldSpace(Vector3.new(x,groundY+standing,z))
		local before=frame:PointToObjectSpace(root.Position)
		local delta=Vector3.new(x-before.X,0,z-before.Z)
		assert(delta.Magnitude<=80,"Review walking segment exceeds 80 studs")
		local beforeFloor=before.Y-standing
		local stepStarted=os.clock()
		local timeout=math.max(5,delta.Magnitude/math.max(humanoid.WalkSpeed,1)+4)
		local samples,minError,fallDepth,lastMove={},0,0,stepStarted
		local reached=false
		humanoid:MoveTo(goal)
		repeat
			task.wait(0.12)
			if player.Character~=initialCharacter or humanoid.Health<=0 then break end
			local p=frame:PointToObjectSpace(root.Position)
			local planar=Vector3.new(p.X-before.X,0,p.Z-before.Z)
			local alpha=if delta.Magnitude>0.1 then math.clamp(planar:Dot(delta)/delta:Dot(delta),0,1) else 1
			local expectedFloor=beforeFloor+(groundY-beforeFloor)*alpha
			local error=(p.Y-standing)-expectedFloor
			minError=math.min(minError,error); fallDepth=math.max(fallDepth,-error)
			minBodyPathError=math.min(minBodyPathError,error)
			if #samples<24 then
				table.insert(samples,{time=math.round((os.clock()-stepStarted)*100)/100,body=point(p),state=humanoid:GetState().Name,carry=sampleCarry()})
			else sampleCarry() end
			local horizontal=Vector3.new(p.X-x,0,p.Z-z).Magnitude
			if horizontal<=1.65 and math.abs(p.Y-(groundY+standing))<=1.5 then reached=true; break end
			if fallDepth>3.5 then break end
			-- MoveTo has an engine timeout. Refresh the same physical destination
			-- only after six seconds; never teleport or force character position.
			if os.clock()-lastMove>6 then humanoid:MoveTo(goal);lastMove=os.clock() end
		until os.clock()-stepStarted>timeout
		local p=frame:PointToObjectSpace(root.Position)
		local detail={segment=sequence,label=label,elapsed=math.round((os.clock()-stepStarted)*1000)/1000,
			distance=math.round(delta.Magnitude*1000)/1000,from=point(before),goal={x=x,y=groundY+standing,z=z},finish=point(p),
			reached=reached,fallDepth=math.round(fallDepth*1000)/1000,deaths=deaths,samples=samples,method="Humanoid.MoveTo; no teleport during this segment"}
		table.insert(route,detail)
		check(reached and fallDepth<=3.5 and deaths==0,"walk "..label,detail)
	end
	local function upStair(floor,side)
		local lower=1.15+(floor-1)*22
		for _,z in ipairs({-18,-8,2,12,22,24}) do
			walk("floor "..floor.."→"..(floor+1).." ramp at z="..z,side*42,lower+(z+20)*0.5,z)
		end
		walk("floor "..(floor+1).." upper landing",side*42,lower+22,30)
		walk("floor "..(floor+1).." landing turn into hall",side*29,lower+22,30)
	end
	local function downStair(floor,side)
		local lower=1.15+(floor-1)*22
		walk("floor "..(floor+1).." landing entry",side*42,lower+22,30)
		for _,z in ipairs({24,14,4,-6,-16,-19}) do
			walk("floor "..(floor+1).."→"..floor.." ramp at z="..z,side*42,lower+(z+20)*0.5,z)
		end
		-- Floor2's east stair has a side entrance at z=-19, half a stud above
		-- its hall; going past the end into its unsupported outer strip would fall.
		walk("floor "..floor.." lower turn into hall",side*29,lower,-19)
	end
	local result
	local ok,failure=xpcall(function()
		-- The one initial avatar setup follows the actual recovery model when
		-- resuming an interrupted carry. The Curse itself is never moved here.
		ctx.pose(frame*CFrame.new(sourceStart.X,1.15+standing+0.15,sourceStart.Z-8)*CFrame.Angles(0,math.pi,0))
		teleports+=1;task.wait(0.4)
		local picked=curses:action(player,"pickup",uid)
		check(picked.ok and curses:getState(uid)=="CARRYING" and origin:GetAttribute("OccupiedCurseUid")==nil,
			"real owned "..current.definitionId.." physically picked up",{uid=uid,initialState=initialState,initialPedestal=initialPedestalId,
				plannedFinalPedestal=originalSlotId,sourceLocal=point(sourceStart),message=picked.message})
		check(player:GetAttribute("SoulsPerSecond")==expectedCarriedRate,"carried instance contributes no income",{
			initialState=initialState,initialRate=originalRate,expectedRate=expectedCarriedRate,actualRate=player:GetAttribute("SoulsPerSecond")})
		walk("lower collection or recovery to clear central aisle",0,1.15,sourceStart.Z-8)
		walk("lower central aisle toward entrance",0,1.15,-23)
		walk("lower court to west stair",-30,1.15,-23)
		walk("west stair foot",-42,0.8,-22)
		upStair(1,-1)
		walk("second-floor central aisle",0,23.15,30)
		walk("second-floor rear gallery",0,23.15,54)
		walk("second-floor central corridor",0,23.15,-19)
		walk("second-floor east stair approach",29,23.15,-19)
		walk("second-floor east stair side entry",42,23.65,-19)
		upStair(2,1)
		walk("third-floor central aisle",0,45.15,30)
		walk("third-floor rear gallery",0,45.15,54)
		walk("third-floor return toward first display row",0,45.15,-23)
		walk("third-floor empty pedestal approach",-23,45.15,-23)
		local destination=pedestal("floor3-slot1")
		check(destination and not destination:GetAttribute("OccupiedCurseUid"),"real upper-floor destination is free")
		local placed=curses:action(player,"place",uid,"floor3-slot1")
		check(placed.ok and owned(uid).pedestalId=="floor3-slot1" and curses:getState(uid)=="PLACED"
			and player:GetAttribute("SoulsPerSecond")==expectedPlacedRate,"real walked third-floor placement resumes one income",placed.message)
		task.wait(1)
		local again=curses:action(player,"pickup",uid)
		check(again.ok and curses:getState(uid)=="CARRYING" and not destination:GetAttribute("OccupiedCurseUid"),"upper-floor pickup for actual return walk",again.message)
		walk("third-floor pedestal to central aisle",0,45.15,-23)
		walk("third-floor central return corridor",0,45.15,30)
		walk("third-floor hall to landing turn",29,45.15,30)
		downStair(2,1)
		walk("second-floor lower landing to center",0,23.15,-19)
		walk("second-floor central return corridor",0,23.15,30)
		walk("second-floor center to west upper landing",-29,23.15,30)
		downStair(1,-1)
		walk("lower stair turn to center",0,1.15,-23)
		walk("planned final pedestal approach",destinationApproach.X,1.15,destinationApproach.Z-8)
		local restored=curses:action(player,"place",uid,originalSlotId)
		check(restored.ok and owned(uid).pedestalId==originalSlotId and curses:getState(uid)=="PLACED"
			and #curses:getOwned(player)==originalCount and player:GetAttribute("SoulsPerSecond")==expectedPlacedRate,
			"owned inventory preserved through physical return and manual placement",restored.message)
		walk("front aisle camera position",0,1.15,-23)
		humanoid:MoveTo(root.Position)
		check(teleports==1 and deaths==0,"complete ascent and descent use one initial setup teleport only",{teleports=teleports,deaths=deaths,freefallTransitions=freefallTransitions,segments=#route})

		-- These are measurements, not client-visible animation approval. A
		-- negative value explicitly reports the production target below support.
		local carrySummary=carryMeasurementSummary(true)
		check(not carrySummary.needsFloorClamp and not carrySummary.needsLateralClamp,"carry-floor and enclosure clearances",carrySummary)
		table.insert(measurements,carrySummary)

		local kit=game.ServerStorage.CurseMeshKit
		local largest,maxHeight=nil,0
		for _,id in ipairs(Catalog.enabledSpawnIds()) do
			local definition=Catalog.Definitions[id];local native=kit:FindFirstChild(definition.visualKey)
			if native then
				local size=native.Size*Presentation.scale(id,native.Size)
				if size.Y>maxHeight then largest=id;maxHeight=size.Y end
			end
		end
		local qaPedestal=pedestal("floor3-slot9")
		if largest and qaPedestal and not qaPedestal:GetAttribute("OccupiedCurseUid") then
			local previous=map:FindFirstChild("SpatialReviewVisuals");if previous then previous:Destroy() end
			qaFolder=Instance.new("Folder");qaFolder.Name="SpatialReviewVisuals";qaFolder.Parent=map
			local display,prompt=Visual.create(Catalog.Definitions[largest],qaFolder)
			display.Name="QA_NON_OWNED_CLEARANCE_"..largest;display:SetAttribute("QANonOwned",true)
			prompt.Enabled=false
			local size=display.PrimaryPart.Size
			local top=qaPedestal.Position+qaPedestal.CFrame.UpVector*(qaPedestal.Size.Y*0.5)
			Visual.move(display,CFrame.new(top+Vector3.new(0,size.Y*0.5+0.12,0))*qaPedestal.CFrame.Rotation,true)
			Visual.setState(display,Catalog.Definitions[largest],"PLACED")
			local ceiling=workspace:Raycast(top+Vector3.new(0,.2,0),Vector3.new(0,80,0),params)
			local clearance=ceiling and ceiling.Position.Y-(top.Y+size.Y+.12)
			local qa={definitionId=largest,meshId=display.CurseMesh.MeshId,size=point(size),pedestalId="floor3-slot9",
				ceiling=ceiling and ceiling.Instance.Name,staticTopClearance=clearance and math.round(clearance*1000)/1000,
				owned=false,income=0,folder=qaFolder.Name,note="Native production presentation only, no CurseService record; root must visually inspect animation and remove QA folder after capture"}
			check(not ceiling or clearance>=2,"largest native height fits empty third-floor showcase",qa)
			table.insert(measurements,qa)
		end
		local cameraPosition=frame:PointToWorldSpace(Vector3.new(0,12,-51))
		local cameraTarget=frame:PointToWorldSpace(Vector3.new(0,18,12))
		result={method="actual Humanoid.MoveTo on owned avatar; one initial teleport; real CurseService pickup/place; no progress/capacity provisioning",
			uid=uid,definitionId=current.definitionId,initialState=initialState,initialPedestalId=initialPedestalId,
			originalPedestalId=initialPedestalId,plannedFinalPedestalId=originalSlotId,upperPedestalId="floor3-slot1",initialSourceLocal=point(sourceStart),
			elapsed=math.round((os.clock()-started)*1000)/1000,teleports=teleports,deaths=deaths,freefallTransitions=freefallTransitions,
			segments=route,stateTransitions=transitions,measurements=measurements,finalAvatarLocal=point(frame:PointToObjectSpace(root.Position)),
			frontCamera={position=point(cameraPosition),target=point(cameraTarget)},qaVisualFolder=qaFolder and qaFolder.Name,
			remaining="root native camera review, mobile control navigation and animated client pose/rail clearance; refresh saved profile expectation after real movement/actions"}
	end,debug.traceback)
	died:Disconnect();stateChanged:Disconnect()
	if root and root.Parent then humanoid:MoveTo(root.Position) end
	if not ok then
		if qaFolder then qaFolder:Destroy() end
		-- Preserve negative support/perimeter observations even if traversal
		-- aborts. This is a diagnostic record, not a successful walk assertion.
		local partial=carryMeasurementSummary(false)
		partial.finishedSegments=#route
		partial.finalAvatarLocal=point(frame:PointToObjectSpace(root.Position))
		partial.curseState=curses:getState(uid)
		check(true,"interrupted walk clearance observations; traversal remains failed",partial)
		-- Actual owned inventory is left in its actual current gameplay state. This
		-- fixture never returns a carried Curse by teleporting after a failed walk.
		error(failure)
	end
	return result
end
