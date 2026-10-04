-- The same carry geometry on server and client. This only computes a visual
-- target; ownership, interaction distance and placement remain server rules.
local Motion = require(script.Parent.CurseMotionMath)
local Geometry = {}
local rayCache = setmetatable({}, {__mode="k"})

local function rayParams(map,base)
	local key=base or map
	local decor=base and base:FindFirstChild("RestorationDecor")
	local entry=rayCache[key]
	if not entry or entry.map~=map or entry.decor~=decor then
		local params=RaycastParams.new()
		params.FilterType=Enum.RaycastFilterType.Include
		local surfaces={}
		for _,name in ipairs({"Ground","Paths","CemeteryTerrain"}) do
			local ground=map:FindFirstChild(name);if ground then table.insert(surfaces,ground) end
		end
		if base then
			for _,part in base:GetDescendants() do
				if part:IsA("BasePart") and (part:GetAttribute("SupportSurface")
					or part:GetAttribute("SanctuaryFloorIndex") or part:GetAttribute("StairFloorFrom")
					or string.sub(part.Name,1,18)=="StairUpperLanding_"
					or part.Name=="AltarBody"
					or part:GetAttribute("LogicalPedestalId")) then table.insert(surfaces,part) end
			end
		end
		-- The low altar/plinth obstacles keep the payload clear when approached;
		-- gate, walls and rails are never treated as support or climbed visually.
		params.FilterDescendantsInstances=surfaces
		params.RespectCanCollide=true
		entry={params=params,map=map,decor=decor}
		rayCache[key]=entry
	end
	return entry.params
end

function Geometry.follow(frame: CFrame,size: Vector3,map: Instance?,base: Instance?): CFrame
	local target=Motion.follow(frame,size)
	local spawn=base and base:FindFirstChild("PlayerSpawn")
	if spawn and spawn:IsA("BasePart") then
		-- Derive the current translated frame from the same stable marker used by
		-- architecture. A saved base assignment never defines world coordinates.
		local baseFrame=spawn.CFrame*CFrame.new(0,-1.4,18)
		local avatar=baseFrame:PointToObjectSpace(frame.Position)
		if math.abs(avatar.X)<=52 and avatar.Z>=-36 and avatar.Z<=68 then
			local right=baseFrame:VectorToObjectSpace(target.RightVector)
			local look=baseFrame:VectorToObjectSpace(target.LookVector)
			local halfX=math.abs(right.X)*size.X*.5+math.abs(look.X)*size.Z*.5
			local halfZ=math.abs(right.Z)*size.X*.5+math.abs(look.Z)*size.Z*.5
			local p=baseFrame:PointToObjectSpace(target.Position)
			local x=math.clamp(p.X,-49.65+halfX,49.65-halfX)
			local z=math.min(p.Z,66.3-halfZ)
			-- A wide payload stays in the ramp corridor while its avatar is on the
			-- incline. Its footprint cannot raycast the next gallery through the
			-- side of the stairs and jump onto that floor before the upper landing.
			for floor=1,(base:GetAttribute("SanctuaryFloors") or 1)-1 do
				local side=if floor==1 then -1 else 1
				local height=1.15+(floor-1)*22+(avatar.Z+20)*.5
				if avatar.X*side>=33 and avatar.X*side<=51 and avatar.Z>=-20 and avatar.Z<=24
					and avatar.Y>=height and avatar.Y<=height+7 then
					x=side*math.clamp(x*side,33.5+halfX,49.65-halfX)
				end
			end
			-- Keep the visible payload between the real entrance piers while its
			-- owner passes the doorway. On stair approaches it stays inside walls.
			local crossesEntrance=z-halfZ<-32.5 and z+halfZ>-35.5
			if (avatar.Z<-23 or crossesEntrance) and math.abs(avatar.X)<12 then
				x=math.clamp(x,-11.6+halfX,11.6-halfX)
			elseif avatar.Z>-30 then
				z=math.max(z,-32.1+halfZ)
			end
			target=CFrame.new(baseFrame:PointToWorldSpace(Vector3.new(x,p.Y,z)))*target.Rotation
		end
	end
	if map and map.Parent then
		local params=rayParams(map,base)
		local support=frame.Position.Y-2.3
		-- Origins follow the avatar's floor, not the Curse's head. The ramp
		-- corridor constraint above excludes premature support on the next floor.
		-- Five bounded rays only for a carried model; no per-Curse worker/network.
		for _,offset in ipairs({Vector3.zero,
			Vector3.new(-size.X*.5,0,-size.Z*.5),Vector3.new(size.X*.5,0,-size.Z*.5),
			Vector3.new(-size.X*.5,0,size.Z*.5),Vector3.new(size.X*.5,0,size.Z*.5)}) do
			local p=target:PointToWorldSpace(offset)
			local hit=workspace:Raycast(Vector3.new(p.X,frame.Position.Y+5,p.Z),Vector3.new(0,-24,0),params)
			if hit then
				local y=hit.Position.Y
				-- Visible treads step above their continuous collision ramp. Keep
				-- animated feet clear without making the avatar climb each riser.
				if hit.Instance:GetAttribute("StairFloorFrom") then y+=.5 end
				support=math.max(support,y)
			end
		end
		local y=support+size.Y*.5+.12
		target=CFrame.new(target.Position.X,y,target.Position.Z)*target.Rotation
	end
	return target
end

return Geometry
