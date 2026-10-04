-- Decorative poses only. CursePresentation owns MeshPart.CFrame; the server
-- owns the separate gameplay anchor. No per-model connections or coroutines.
local Animation={}
local Profiles=require(game:GetService('ReplicatedStorage').Shared.CurseAnimationProfiles)
local sin,cos,pi=math.sin,math.cos,math.pi
local poses={}
local counts={tracked=0,posed=0,suspended=0,boneWrites=0}
local function pulse(t,period,center,width)
	local phase=t%period
	return math.max(0,1-math.abs(phase-center)/width)^2
end
local function pose(e,name,x,y,z,position)
	local bone=e.bones[name]
	if bone then
		bone.Transform=CFrame.new((position or Vector3.zero)*e.scale)*CFrame.Angles(x or 0,y or 0,z or 0)
		counts.boneWrites+=1
	end
end
local function hash(s)
	local h=5381
	for i=1,#s do h=(h*33+string.byte(s,i))%100003 end
	return h/100003*31
end
function poses.cursed_doll(e,t,g,idle)
	local stride=t*(4.7+g*.4)
	local left=sin(stride)*.30*g;local right=sin(stride+pi+.25)*.24*g
	local twitch=pulse(t,9.1,6.4,.24)
	pose(e,'Root',0,.035*sin(stride*.5)*g,.035*sin(stride)*g,Vector3.new(0,.04+.10*math.abs(sin(stride))*g,0))
	pose(e,'LegL',left,0,.025*g);pose(e,'LegR',right,0,-.025*g)
	pose(e,'FootL',-.18*math.max(0,sin(stride))*g,0,0)
	pose(e,'FootR',-.14*math.max(0,sin(stride+pi+.25))*g,0,0)
	pose(e,'Head',.035*sin(t*.8),.09*sin(t*.57)+twitch*.30,.17+.045*sin(t*.63)-twitch*.10)
	pose(e,'ArmL',-right*.7-.10*idle,0,.04+twitch*.15)
	pose(e,'ArmR',-left*.6-pulse(t,11,8,.8)*.23*idle,0,-.04)
	pose(e,'HandL',.07*sin(t*1.3),0,.07*sin(t*1.7));pose(e,'HandR',.09*sin(t*1.1),0,-.04)
	pose(e,'Dress',.035*sin(stride+.6)*g,0,.03*sin(t*1.2))
end
function poses.watching_eye(e,t,g,idle)
	local blink=pulse(t,5.7,4.15,.19)
	pose(e,'Gaze',.06*sin(t*.69),.14*sin(t*.43),.028*sin(t*.31),Vector3.new(0,.04+.06*sin(t*.8),0))
	pose(e,'Iris',.025*sin(t*1.1),.10*sin(t*.83),0,Vector3.new(.10*sin(t*.71),.055*sin(t*.97),0))
	pose(e,'LidUpper',pi*blink,0,0);pose(e,'LidLower',-pi*blink,0,0)
	for _,side in {'L','R'} do
		local sign=if side=='L' then 1 else -1
		local phase=if side=='L' then 0 else 1.8
		pose(e,'Arm'..side,.08*sin(t*1.35+phase)*g,0,sign*(.07+.07*sin(t*.6+phase)))
		pose(e,'Forearm'..side,.12*sin(t*.8+phase),.04*sign,sign*.055*sin(t*.9+phase))
		pose(e,'Hand'..side,.08*sin(t*1.1+phase),.09*sign*sin(t*.7),sign*.06)
		for i=0,3 do pose(e,'Finger'..side..i,.17+.14*sin(t*1.5+i*.6+phase),0,sign*.035*sin(t+i)) end
		pose(e,'Thumb'..side,.11*sin(t*1.2+phase),sign*.10,0)
	end
end
function poses.soul_chains(e,t,g,idle)
	local struggle=pulse(t,6.8,4.3,.65)
	pose(e,'Core',.065*sin(t*2.1)+struggle*.07,.08*sin(t*.85),struggle*.13,Vector3.new(.07*sin(t*1.7),.05+.08*struggle,0))
	for _,side in {'L','R'} do
		local sign=if side=='L' then 1 else -1
		pose(e,'Cuff'..side,0,sign*.02,sign*(.025+.04*struggle),Vector3.new(sign*.025*struggle,0,0))
		for i=0,5 do
			pose(e,'Chain'..side..i,.04*sin(t*1.6-i*.28),0,sign*(.035*sin(t*1.4-i*.3)+.025*struggle),Vector3.new(sign*.035*struggle,.022*sin(t*1.5-i*.3),0))
		end
	end
	for i=0,6 do pose(e,'CrownLink'..i,.03*sin(t*1.3-i*.27),0,.027*sin(t*1.5-i*.33),Vector3.new(0,.024*sin(t*1.5-i*.33),0)) end
	pose(e,'Hook',.06*sin(t*1.5),.06*sin(t*.8),.09*sin(t*1.2),Vector3.new(0,.03+g*.035,0))
end
function poses.plague_monarch(e,t,g,idle)
	local step=t*2.7
	pose(e,'Root',.018*sin(step)*g,.025*sin(step*.5)*g,.022*cos(step)*g,Vector3.new(0,.045+.07*math.abs(sin(step))*g,0))
	for i=0,3 do
		local phase=if i==0 or i==3 then 0 else pi
		pose(e,'Leg'..i,.22*sin(step+phase)*g,0,(if i%2==0 then 1 else -1)*.02)
		pose(e,'Shin'..i,.21*math.max(0,sin(step+phase))*g,0,0)
	end
	pose(e,'Mask',-.06+.022*sin(t*.6),.075*sin(t*.37),0)
	pose(e,'Breath',.012*sin(t*.8),0,.012*sin(t*.7),Vector3.new(0,.025*sin(t*.9),0))
	pose(e,'Crown',0,.015*sin(t*.42),.022*sin(t*.53))
end
function poses.the_void(e,t,g,idle)
	-- Held phases and unequal shard attraction preserve the broken empty rift.
	local hold=math.floor(t/4)*.7+math.clamp((t%4-.8)/2.4,0,1)*.7
	pose(e,'ArcL',.012*sin(hold*1.1),.017*sin(hold),.017*sin(hold*.7))
	pose(e,'ArcR',-.013*sin(hold*.9),-.014*sin(hold*.8),-.013*sin(hold*1.3+2))
	pose(e,'ArcBase',.018*sin(t*.29),0,.012*sin(t*.37))
	for i=0,4 do
		local bone=e.bones['Shard'..i]
		if bone then
			local toward=-bone.Position.Unit
			local pull=.045+.045*sin(hold*(.6+i*.09)+i*1.3)
			pose(e,'Shard'..i,.023*sin(hold+i),.04*sin(hold*.7+i*2),.036*sin(hold*.8+i),toward*pull)
		end
	end
end

-- Acting channels target weighted anatomy, rather than a common whole-mesh
-- sway. Held gestures, recoil, articulated strides and continuous mechanisms
-- deliberately use different timing curves.
local function channelAct(e,t,g,idle)
	for _,c in e.channels do
		local q=t*2*pi/c.period+c.phase
		local s=sin(q)
		local kind=c.kind
		local v=s;local shift=Vector3.zero
		if kind=='knee' then v=math.max(0,s)
		elseif kind=='step' then v=s
		elseif kind=='turn' then v=q%(2*pi)
		elseif kind=='tick' then v=math.floor(q*6)/6
		elseif kind=='ratchet' then v=math.floor((.5+.5*s)*7)/7
		elseif kind=='search' then v=.55*sin(q)+.30*sin(q*2.1)+pulse(t,c.period,c.period*.72,.4)*.35
		elseif kind=='listen' then v=(.5+.5*sin(q))^4-.2
		elseif kind=='lament' then v=sin(q)*.7;shift=Vector3.new(0,.04*math.max(0,s),0)
		elseif kind=='shoe' then v=s;shift=Vector3.new(0,.10*math.max(0,s),0)
		elseif kind=='puppet' then v=math.clamp(s*1.8,-1,1)*(.65+.35*sin(q*.3))
		elseif kind=='unfurl' then v=(.5+.5*s)^2
		elseif kind=='weigh' or kind=='counterweigh' then v=sin(q)*.65+sin(q*2)*.15
		elseif kind=='hold' or kind=='survey' or kind=='look' then
			local p=q/(2*pi)%1
			local smooth=math.clamp((p-.18)/.56,0,1)
			smooth=smooth*smooth*(3-2*smooth);v=sin(smooth*2*pi)
		elseif kind=='twitch' then v=pulse(t+c.phase,c.period,c.period*.74,.17)*sin(t*35)
		elseif kind=='heartbeat' then v=pulse(t,c.period,.16,.12)+.6*pulse(t,c.period,.44,.12)
		elseif kind=='creak' or kind=='fold' or kind=='reach' or kind=='bow' or kind=='peek' then v=(.5+.5*s)^3
		elseif kind=='pluck' or kind=='write' then v=sin(q*5)*(.5+.5*cos(q))^4
		elseif kind=='flutter' or kind=='flame' or kind=='ribbon' then v=.7*s+.3*sin(q*2.3+1)
		elseif kind=='struggle' then v=pulse(t+c.phase,c.period,c.period*.66,.65)*sin(q*9)
		elseif kind=='grip' or kind=='curl' then v=.5+.5*sin(q)
		elseif kind=='sniff' then v=pulse(t,c.period,c.period*.62,.5)*sin(q*3)
		elseif kind=='roll' then v=s;shift=Vector3.new(0,.04*math.abs(s),0)
		elseif kind=='hop' then v=math.max(0,s);shift=Vector3.new(0,.22*v,0)
		elseif kind=='drip' then shift=Vector3.new(0,-.12*(q/(2*pi)%1),0);v=0
		elseif kind=='emerge' then shift=Vector3.new(0,.07*(.5+.5*s),-.08*(.5+.5*s));v=s
		elseif kind=='coil' or kind=='squirm' then v=.7*s+.3*sin(q*1.7);shift=Vector3.new(.02*cos(q),.025*s,0)
		end
		local gain=(c.idle or 0)*idle+(c.travel or 0)*(1-idle)
		if kind=='step' or kind=='knee' then
			gain=g
			-- An unmoving funeral bier holds a tense stance, then flexes a
			-- single support. Its four carriers do not walk on the pedestal.
			if e.id=='the_last_funeral' and idle>0 then
				gain+=idle*.12*pulse(t+c.phase*2,11,8,.8)
			end
		end
		local a=c.amplitude*v*gain
		pose(e,c.bone,if c.axis=='x' then a else 0,if c.axis=='y' then a else 0,
			if c.axis=='z' then a else 0,shift*gain)
	end
end

function Animation.create(model,mesh)
	local bones={};local ordered={}
	local id=model:GetAttribute('CurseId')
	for _,x in mesh:GetDescendants() do
		if x:IsA('Bone') then
			local name=x.Name
			if id and string.sub(name,1,#id+2)==id..'__' then name=string.sub(name,#id+3) end
			bones[name]=x;table.insert(ordered,x)
		end
	end
	local entry={model=model,mesh=mesh,bones=bones,ordered=ordered,act=poses[id] or (Profiles[id] and channelAct),channels=Profiles[id],id=id,
		phase=hash(model:GetAttribute('CurseUid') or id or mesh.Name),scale=mesh.Size.Y/6,
		elapsed=0,travel=0,suspended=false,state=model:GetAttribute('CurseState')}
	counts.tracked+=1
	return entry
end
function Animation.remove(e)
	if not e then return end
	counts.tracked=math.max(0,counts.tracked-1)
	if e.suspended then counts.suspended=math.max(0,counts.suspended-1) end
	for _,bone in e.ordered do if bone.Parent then bone.Transform=CFrame.identity end end
	table.clear(e.bones);table.clear(e.ordered)
end
function Animation.update(e,now,dt,state,speed,camera)
	if not e or not e.act or #e.ordered==0 then return end
	e.travel+=(math.clamp(speed/6.5,0,1)-e.travel)*(1-math.exp(-math.min(dt,.2)/.12))
	local distance=if camera then (e.mesh.Position-camera.CFrame.Position).Magnitude else 0
	local onscreen=true
	if camera then local _,visible=camera:WorldToViewportPoint(e.mesh.Position);onscreen=visible end
	local suspended=distance>115 or (not onscreen and distance>50)
	if suspended then
		if not e.suspended then
			for _,bone in e.ordered do bone.Transform=CFrame.identity end
			e.suspended=true;counts.suspended+=1
		end
		return
	end
	if e.suspended then e.suspended=false;counts.suspended=math.max(0,counts.suspended-1) end
	e.elapsed+=dt
	local interval=if distance<32 then 0 elseif distance<75 then 1/20 else 1/6
	if e.elapsed<interval and e.state==state then return end
	e.elapsed=0;e.state=state
	local active=state=='PROCESSION' or state=='CARRYING' or state=='DELIVERING'
	local travel=if active then e.travel else 0
	e.act(e,(now+e.phase)%10000,travel,1-travel)
	-- A short lift/settle communicates state changes without moving the anchor.
	local epoch=e.model:GetAttribute('StateStartedAt')
	local root=e.bones.Root
	if root and typeof(epoch)=='number' then
		local age=now-epoch
		if age>=0 and age<.32 then
			local lift=sin(age/.32*pi)*.085*e.scale
			root.Transform=CFrame.new(0,lift,0)*root.Transform
		end
	end
	counts.posed+=1
end
function Animation.metrics() return table.clone(counts) end
return Animation
