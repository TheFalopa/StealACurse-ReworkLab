-- Construction-time support sampling. The map is assembled off Workspace,
-- so Workspace:Raycast cannot see its floors yet. No runtime/per-frame scan.
local Grounding = {}
local supportCache = setmetatable({}, { __mode = "k" })

local function mapFor(parent: Instance): Instance
	local current = parent
	while current.Parent do current = current.Parent end
	return current
end

-- Rebuild only at explicit construction stages, never per frame. Weak map
-- keys let a replaced environment and its support list be collected.
function Grounding.refresh(map: Instance)
	local supports = {}
	for _, groupName in ipairs({ "Ground", "CemeteryTerrain", "Paths", "PlayerSanctuaries" }) do
		local group = map:FindFirstChild(groupName)
		if group then
			for _, item in ipairs(group:GetDescendants()) do
				local isFloor = item.Name == "SanctuaryFloor" or item.Name == "TerraceCollision"
					or string.find(item.Name,"SideApproach") ~= nil
					or (groupName ~= "PlayerSanctuaries" and (groupName ~= "Paths" or (item:IsA("BasePart") and item.Size.Y <= 0.5)))
				if isFloor and item:IsA("Part") and item.CanCollide then
					table.insert(supports,item)
				end
			end
		end
	end
	supportCache[map] = supports
end

function Grounding.position(parent: Instance, at: Vector3): Vector3
	local map = mapFor(parent)
	if not supportCache[map] then Grounding.refresh(map) end
	local top = at.Y
	for _, item in ipairs(supportCache[map]) do
		local half = item.Size * 0.5
		local height
		if item.Shape == Enum.PartType.Ball then
			-- Authored terrain ellipsoids are yaw-only; solve their upper cap.
			local p=item.CFrame:PointToObjectSpace(Vector3.new(at.X,item.Position.Y,at.Z))
			local radius=(p.X/half.X)^2+(p.Z/half.Z)^2
			if radius<=1 then height=item.Position.Y+half.Y*math.sqrt(1-radius) end
		elseif item.CFrame.UpVector.Y>0.8 then
			local n=item.CFrame.UpVector
			local face=item.Position+n*half.Y
			local y=face.Y-(n.X*(at.X-face.X)+n.Z*(at.Z-face.Z))/n.Y
			-- Test the actual plane hit in local coordinates, not a sample at
			-- the part center's height; the latter shrank sloping ramp bounds.
			local hit=item.CFrame:PointToObjectSpace(Vector3.new(at.X,y,at.Z))
			if math.abs(hit.X)<=half.X and math.abs(hit.Z)<=half.Z then height=y end
		end
		if height then top=math.max(top,height) end
	end
	return Vector3.new(at.X, top, at.Z)
end

return Grounding
