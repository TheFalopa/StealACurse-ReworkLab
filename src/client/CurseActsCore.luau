-- Acting for the five showcase anatomies. Poses remain decorative and do not
-- write the mesh, the gameplay anchor, or VFX. Gaits follow travelled distance.
return function(H)
	local pose,pulse,smooth,gait=H.pose,H.pulse,H.smooth,H.gait
	local sin,cos,pi=math.sin,math.cos,math.pi
	local acts={}
	local monarchFeet={Vector3.new(1.58394,-2.76950,-.53251),Vector3.new(-1.58394,-2.76950,-.51711),
		Vector3.new(1.41466,-2.76950,.74591),Vector3.new(-1.36630,-2.76950,.74591)}
	local function align(a,b)
		local axis=a.Unit:Cross(b.Unit)
		local dot=math.clamp(a.Unit:Dot(b.Unit),-1,1)
		if axis.Magnitude<.00001 then return CFrame.identity end
		return CFrame.fromAxisAngle(axis.Unit,math.acos(dot))
	end
	local function monarchPlant(e,q,g,body)
		for i,marker in monarchFeet do
			local index=i-1
			local upper=e.rest['Leg'..index];local lower=e.rest['Shin'..index]
			local phase=if index==0 or index==3 then 0 else .5
			local f=(q/(2*pi)+phase)%1
			local z,lift
			if f<.70 then z=2.15*.70*(f/.70-.5);lift=0
			else local s=(f-.70)/.30;z=2.15*.70*(.5-smooth(s));lift=.22*sin(pi*s)^2 end
			local foot=marker*e.scale
			local target=body:PointToObjectSpace(foot+Vector3.new(0,lift*g,z*g)*e.scale
				+Vector3.new(0,0,(upper.Z-foot.Z)*.23*g))
			local wanted=upper:PointToObjectSpace(target)
			local a=lower.Position
			local b=lower:PointToObjectSpace(upper:PointToObjectSpace(foot))
			local l1,l2=a.Magnitude,b.Magnitude
			local d=math.clamp(wanted.Magnitude,math.abs(l1-l2)+.00001,l1+l2-.00001)
			local direction=wanted.Unit
			local plane=(a-direction*a:Dot(direction)).Unit
			local along=(l1*l1-l2*l2+d*d)/(2*d)
			local knee=direction*along+plane*math.sqrt(math.max(0,l1*l1-along*along))
			local first=align(a,knee)
			local nextLower=first:VectorToObjectSpace(direction*d-knee)
			local second=align(b,lower.Rotation:VectorToObjectSpace(nextLower))
			pose(e,'Leg'..index,first:ToEulerAnglesXYZ())
			pose(e,'Shin'..index,second:ToEulerAnglesXYZ())
		end
	end
	function acts.cursed_doll(e,t,g,idle)
		local q=gait(e,{stride=2.15})
		-- A planted, slightly late right foot gives her an unequal limping step.
		local l=sin(q);local r=sin(q+pi+.23)
		local liftL=math.max(0,l);local liftR=math.max(0,r)
		local twitch=pulse(t,8.8,5.9,.36)
		local beckon=pulse(t,12.3,8.4,1.15)*idle
		pose(e,'Root',0,.055*sin(q*.5)*g,.035*(l-r)*g,
			Vector3.new(0,.028+.065*(liftL+liftR)*g,0))
		pose(e,'LegL',.50*l*g,0,.012*g,Vector3.new(0,.07*liftL*g,0))
		pose(e,'LegR',.44*r*g,0,-.012*g,Vector3.new(0,.045*liftR*g,0))
		pose(e,'FootL',-.35*liftL*g,0,0)
		pose(e,'FootR',-.30*liftR*g,0,0)
		pose(e,'Head',-.035+.065*sin(t*.61),.17*sin(t*.34)+.34*twitch,
			.20+.045*sin(t*.46)-.14*twitch)
		pose(e,'ArmL',-.38*r*g-.20*idle-.42*beckon,0,.055+.12*beckon)
		pose(e,'ArmR',-.38*l*g-.08*idle,0,-.055-.09*twitch)
		pose(e,'HandL',.12*sin(t*1.1)+.22*beckon,.05*beckon,.08*sin(t*.7))
		pose(e,'HandR',.09*sin(t*.9),0,-.05-.10*twitch)
		pose(e,'Dress',-.025*(l+r)*g,0,.035*sin(q+.7)*g)
	end
	function acts.watching_eye(e,t,g,idle)
		-- The lid meshes are hemispheres sharing the eye centre; fold them across
		-- the pupil rather than translate the eye or rotate the entire silhouette.
		local blink=pulse(t,4.9,3.75,.26)
		local doubleBlink=pulse(t,13.1,9.1,.18)
		blink=math.max(blink,doubleBlink)
		local scan=sin(t*.47)*.55+.22*sin(t*1.11)
		local reach=pulse(t,7.8,5.1,1.3)
		pose(e,'Root',0,0,.018*sin(t*.39),Vector3.new(0,.075+.035*sin(t*.84),0))
		pose(e,'Gaze',.055*sin(t*.63),.16*scan,.035*sin(t*.5))
		pose(e,'Iris',.02*sin(t*.8),.06*scan,0,Vector3.new(.18*scan,.085*sin(t*.67),0))
		pose(e,'LidUpper',pi*blink,0,0);pose(e,'LidLower',-pi*blink,0,0)
		for _,side in {'L','R'} do
			local sign=if side=='L' then 1 else -1
			local lag=if side=='L' then 0 else .8
			local gesture=if side=='L' then reach else pulse(t,7.8,5.9,1.3)
			pose(e,'Arm'..side,-.12*g-.18*gesture,0,sign*(.055+.09*sin(t*.68+lag)))
			pose(e,'Forearm'..side,-.22*gesture,.04*sign,sign*(.06+.08*sin(t*.53+lag)))
			pose(e,'Hand'..side,.16*gesture+.07*sin(t*.9+lag),sign*.09*scan,sign*.055)
			for i=0,3 do
				local curl=.13+.33*gesture+.13*sin(t*1.32-i*.43+lag)
				pose(e,'Finger'..side..i,curl,0,sign*.025*sin(t*.8+i))
			end
			pose(e,'Thumb'..side,.12+.24*gesture,sign*.12,.03*sign)
		end
	end
	function acts.soul_chains(e,t,g,idle)
		-- Tension pulls the soul first; each independent weighted link reacts
		-- later, then the cuffs brace. Unequal delays make the chains readable.
		local struggle=pulse(t,6.4,3.9,.9)
		local recoil=pulse(t,6.4,4.85,.55)
		pose(e,'Root',0,.015*sin(t*.6),.018*sin(t*.9),Vector3.new(0,.06+.04*sin(t*.73),0))
		pose(e,'Core',-.22*struggle+.10*recoil,.18*sin(t*.59),.23*struggle,
			Vector3.new(.16*sin(t*2.9)*struggle,.21*struggle-.065*recoil,-.10*struggle))
		for _,side in {'L','R'} do
			local sign=if side=='L' then 1 else -1
			local lag=if side=='L' then 0 else .13
			pose(e,'Cuff'..side,.03*struggle,sign*.055,sign*.045*struggle)
			for i=0,5 do
				local pull=pulse(t-i*.085-lag,6.4,3.9,.9)
				local wave=sin(t*1.75-i*.5+lag)*(.022+.018*g)
				pose(e,'Chain'..side..i,wave,0,sign*(wave+.045*pull),
					Vector3.new(-sign*.04*pull,.018*sin(t*2-i*.47),-.03*pull))
			end
		end
		for i=0,6 do
			pose(e,'CrownLink'..i,.035*sin(t*1.1-i*.4),0,.028*sin(t*1.35-i*.43),
				Vector3.new(0,.022*sin(t*1.35-i*.43),0))
		end
		pose(e,'Hook',.22*sin(t*1.1),.12*sin(t*.56),.16*sin(t*.85))
	end
	function acts.plague_monarch(e,t,g,idle)
		local q=gait(e,{stride=2.15})
		local position=Vector3.new(0,-.23*g-.02*(1+sin(t*.8))*idle,0)
		local pitch,yaw,roll=.009*sin(q)*g,.012*sin(q*.5)*g,.01*cos(q)*g
		pose(e,'Root',pitch,yaw,roll,position)
		local body=CFrame.new(position*e.scale)*CFrame.Angles(pitch,yaw,roll)
		-- Four measured contacts, a long load-bearing stance and a brief recovery.
		-- Distal rotations keep feet on the ground while the heavy body advances.
		monarchPlant(e,q,g,body)
		local survey=pulse(t,10.8,7.1,1.8)*idle
		pose(e,'Mask',-.10+.045*sin(t*.51),.16*sin(t*.31)+.12*survey,.025*sin(t*.41))
		pose(e,'Breath',.025*sin(t*.85),0,.015*sin(t*.8),Vector3.new(0,.04*sin(t*.85),0))
		pose(e,'Crown',0,-.035*sin(t*.31),.035*sin(t*.48))
	end
	function acts.the_void(e,t,g,idle)
		-- Hold, draw inward, and release. Avoid a continuous generic orb spin.
		local phase=t%8.4
		local pull=smooth((phase-1.5)/2.4)*(1-smooth((phase-5.8)/1.6))
		local drift=.5*sin(t*.19)+.3*sin(t*.31)
		pose(e,'Root',0,.012*drift,0,Vector3.new(0,.035+.022*sin(t*.26),0))
		pose(e,'ArcL',.025*drift,.055*pull,.025*pull,Vector3.new(-.035*pull,.018*pull,.04*pull))
		pose(e,'ArcR',-.03*drift,-.052*pull,-.022*pull,Vector3.new(.035*pull,-.018*pull,-.03*pull))
		pose(e,'ArcBase',.035*sin(t*.22),.016*pull,.015*drift)
		for i=0,4 do
			local rest=e.rest['Shard'..i]
			if rest then
				local direction=if rest.Position.Magnitude>.01 then -rest.Position.Unit else Vector3.yAxis
				local draw=.09+.12*pull+.035*sin(t*(.24+i*.03)+i*1.3)
				pose(e,'Shard'..i,.09*sin(t*.23+i),.11*sin(t*.18+i*1.7),.08*drift,
					direction*draw+Vector3.new(0,.025*sin(t*.37+i),.04*sin(t*.29+i)))
			end
		end
	end
	return acts
end
