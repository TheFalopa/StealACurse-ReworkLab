-- One decorative pose writer. Presentation alone moves the visible mesh;
-- the server alone owns the gameplay anchor, price, ownership and placement.
local Animation = {}
local counts = {tracked=0,posed=0,suspended=0,boneWrites=0,missingActs=0}
local function smooth(v)
	v=math.clamp(v,0,1)
	return v*v*(3-2*v)
end
local function pulse(t,period,center,width)
	return math.max(0,1-math.abs(t%period-center)/width)^2
end
local function pose(e,name,x,y,z,position)
	if e.bones[name] then
		-- Native CFrame angles must remain small even with epoch-based clocks.
		-- Otherwise float conversion can freeze continuously turning mechanisms.
		local tau=math.pi*2
		e.targets[name]=CFrame.new((position or Vector3.zero)*e.scale)*CFrame.Angles((x or 0)%tau,(y or 0)%tau,(z or 0)%tau)
	end
end
local function gait(e,options)
	return e.distance/(math.max(.1,options.stride or 2.5)*e.scale)*math.pi*2+(options.phase or 0),e.travel
end
local H={pose=pose,pulse=pulse,smooth=smooth,gait=gait}
local acts={}
for _,module in {script.Parent.CurseActsCore,script.Parent.CurseActsObjects,script.Parent.CurseActsCreatures,script.Parent.CurseActsEntities} do
	for id,act in require(module)(H) do
		assert(not acts[id], 'Two animation acts own '..id)
		acts[id]=act
	end
end
local function hash(s)
	local h=5381
	for i=1,#s do h=(h*33+string.byte(s,i))%100003 end
	return h/100003*31
end
local function beginBlend(e,now,duration)
	table.clear(e.from)
	for name,bone in e.bones do e.from[name]=bone.Transform end
	e.blendAt,e.blendDuration=now,duration
end
function Animation.create(model,mesh)
	local id=model:GetAttribute('CurseId')
	local bones,ordered,rest={},{},{}
	for _,bone in mesh:GetDescendants() do
		if bone:IsA('Bone') then
			local name=bone.Name
			if id and string.sub(name,1,#id+2)==id..'__' then name=string.sub(name,#id+3) end
			bones[name]=bone;rest[name]=bone.CFrame;table.insert(ordered,bone)
		end
	end
	local now=workspace:GetServerTimeNow()
	local e={model=model,mesh=mesh,id=id,bones=bones,ordered=ordered,rest=rest,
		act=acts[id],phase=hash(model:GetAttribute('CurseUid') or id or mesh.Name),
		scale=mesh.Size.Y/6,distance=0,speed=0,travel=0,elapsed=0,
		state=model:GetAttribute('CurseState'),stateAt=now,stateAge=0,
		targets={},from={},blendAt=now,blendDuration=.25,suspended=false}
	beginBlend(e,now,.25)
	counts.tracked+=1
	if not e.act then counts.missingActs+=1;warn('Missing Curse act:',id) end
	return e
end
function Animation.remove(e)
	if not e then return end
	counts.tracked=math.max(0,counts.tracked-1)
	if not e.act then counts.missingActs=math.max(0,counts.missingActs-1) end
	if e.suspended then counts.suspended=math.max(0,counts.suspended-1) end
	for _,bone in e.ordered do if bone.Parent then bone.Transform=CFrame.identity end end
	table.clear(e.bones);table.clear(e.ordered);table.clear(e.targets);table.clear(e.from)
end
function Animation.update(e,now,dt,state,speed,camera)
	if not e or not e.act or #e.ordered==0 then return end
	local active=state=='PROCESSION' or state=='CARRYING' or state=='DELIVERING'
	local step=math.min(dt,.2)
	-- Speed is measured from the rendered path, excluding intentional teleports.
	-- Integrate it even while culled, so the gait resumes at the current phase.
	e.distance+=if active then speed*dt else 0
	e.speed+=(speed-e.speed)*(1-math.exp(-step/.08))
	e.travel+=((if active then math.clamp(e.speed/5,0,1) else 0)-e.travel)*(1-math.exp(-step/.12))
	if e.state~=state then
		beginBlend(e,now,.18)
		e.state,e.stateAt=state,now
	end
	e.stateAge=math.max(0,now-e.stateAt)
	local distance=if camera then (e.mesh.Position-camera.CFrame.Position).Magnitude else 0
	local onscreen=true
	if camera then local _,visible=camera:WorldToViewportPoint(e.mesh.Position);onscreen=visible end
	local suspended=distance>115 or (not onscreen and distance>50)
	if suspended then
		if not e.suspended then e.suspended=true;counts.suspended+=1 end
		-- Freeze the distant pose rather than snap the geometry back to bind pose.
		return
	end
	if e.suspended then
		e.suspended=false;counts.suspended=math.max(0,counts.suspended-1)
		beginBlend(e,now,.22)
	end
	e.elapsed+=dt
	local interval=if distance<32 then 0 elseif distance<75 then 1/20 else 1/8
	if e.elapsed<interval then return end
	e.elapsed=0
	table.clear(e.targets)
	e.act(e,now+e.phase,e.travel,1-e.travel)
	-- Small pickup/settle accent applies only to decorative Root, never prompts.
	local root=e.targets.Root or CFrame.identity
	if e.stateAge<.36 and (state=='CARRYING' or state=='PLACED' or state=='UNPLACED') then
		local lift=math.sin(e.stateAge/.36*math.pi)*.10*e.scale
		e.targets.Root=CFrame.new(0,lift,0)*root
	end
	local blend=smooth((now-e.blendAt)/e.blendDuration)
	for name,bone in e.bones do
		local target=e.targets[name] or CFrame.identity
		if blend<1 then target=(e.from[name] or CFrame.identity):Lerp(target,blend) end
		bone.Transform=target
		counts.boneWrites+=1
	end
	counts.posed+=1
end
function Animation.metrics() return table.clone(counts) end
return Animation
