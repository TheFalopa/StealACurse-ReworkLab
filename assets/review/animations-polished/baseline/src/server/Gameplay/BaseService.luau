local Players = game:GetService("Players")

local BaseService = {}

local CLAIM_DISTANCE = 13

local function findRequired(parent: Instance, name: string, className: string): Instance
	local child = parent:FindFirstChild(name)
	assert(child and child:IsA(className), string.format("%s needs %s (%s)", parent:GetFullName(), name, className))
	return child
end

local function sendNotice(player: Player, message: string)
	player:SetAttribute("HUDNotice", message)
	player:SetAttribute("HUDNoticeSerial", (player:GetAttribute("HUDNoticeSerial") or 0) + 1)
end

local function makeClaimMarker(base: Model, spawn: SpawnLocation, id: string)
	local marker = Instance.new("Part")
	marker.Name = "ClaimMarker"
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanTouch = false
	marker.CanQuery = false
	marker.CastShadow = false
	marker.Transparency = 1
	marker.Size = Vector3.new(1, 1, 1)
	-- The existing spawn faces the sanctuary; its -Z axis leads to the arch.
	marker.CFrame = spawn.CFrame * CFrame.new(0, 2.5, -9)
	marker.Parent = base

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ClaimSanctuary"
	prompt.ActionText = "Claim"
	prompt.ObjectText = "Sanctuary " .. string.sub(id, -2)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = marker

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ClaimStatus"
	billboard.Adornee = marker
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 75
	billboard.Size = UDim2.fromOffset(184, 58)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.7, 0)
	billboard.Parent = marker

	local backing = Instance.new("Frame")
	backing.Name = "Backing"
	backing.BackgroundColor3 = Color3.fromRGB(27, 23, 43)
	backing.BackgroundTransparency = 0.14
	backing.BorderSizePixel = 0
	backing.Size = UDim2.fromScale(1, 1)
	backing.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = backing

	local outline = Instance.new("UIStroke")
	outline.Name = "Outline"
	outline.Color = Color3.fromRGB(173, 115, 237)
	outline.Thickness = 1.5
	outline.Transparency = 0.12
	outline.Parent = backing

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "SANCTUARY " .. string.sub(id, -2)
	title.TextColor3 = Color3.fromRGB(223, 190, 255)
	title.TextSize = 13
	title.Size = UDim2.new(1, -16, 0, 20)
	title.Position = UDim2.fromOffset(8, 5)
	title.Parent = backing

	local state = Instance.new("TextLabel")
	state.Name = "State"
	state.BackgroundTransparency = 1
	state.Font = Enum.Font.GothamMedium
	state.Text = "UNCLAIMED"
	state.TextColor3 = Color3.fromRGB(161, 242, 245)
	state.TextScaled = true
	state.Size = UDim2.new(1, -16, 0, 21)
	state.Position = UDim2.fromOffset(8, 27)
	state.Parent = backing

	return marker, prompt, state, outline
end

function BaseService.start(map: Model)
	local sanctuaries = findRequired(map, "PlayerSanctuaries", "Model") :: Model
	local byId: { [string]: Model } = {}
	local slotsByBase: { [Model]: { BasePart } } = {}
	local spawnsByBase: { [Model]: SpawnLocation } = {}
	local promptsByBase: { [Model]: ProximityPrompt } = {}
	local labelsByBase: { [Model]: TextLabel } = {}
	local outlinesByBase: { [Model]: UIStroke } = {}
	local markersByBase: { [Model]: BasePart } = {}
	local baseOwners: { [Model]: Player } = {}
	local playerBases: { [Player]: Model } = {}
	local clearing: { [Model]: boolean } = {}
	local releaseCallbacks: { (Player, Model) -> () } = {}
	local claimCallbacks = {}

	for index = 1, 8 do
		local id = string.format("Base%02d", index)
		local base = findRequired(sanctuaries, id, "Model") :: Model
		local spawn = findRequired(base, "PlayerSpawn", "SpawnLocation") :: SpawnLocation
		findRequired(base, "FutureCurseDisplayArea", "BasePart")
		local slots: { BasePart } = {}
		for slotIndex = 1, 5 do
			slots[slotIndex] = findRequired(base, string.format("DisplayPlinth_%d", slotIndex), "BasePart") :: BasePart
			slots[slotIndex]:SetAttribute('PedestalId', 'floor1-slot'..slotIndex)
			slots[slotIndex]:SetAttribute('PedestalBaseId', id)
			slots[slotIndex]:SetAttribute('LegacySlotIndex',slotIndex)
		end
		local marker, prompt, state, outline = makeClaimMarker(base, spawn, id)
		base:SetAttribute("BaseId", id)
		base:SetAttribute("OwnerUserId", nil)
		base:SetAttribute("OwnerDisplayName", nil)
		byId[id] = base
		slotsByBase[base] = slots
		spawnsByBase[base] = spawn
		promptsByBase[base] = prompt
		labelsByBase[base] = state
		outlinesByBase[base] = outline
		markersByBase[base] = marker
	end

	local service = {}

	function service:getBaseForPlayer(player: Player): Model?
		return playerBases[player]
	end

	function service:getBaseById(baseId: string): Model?
		return byId[baseId]
	end

	function service:getBaseIdForPlayer(player: Player): string?
		local base = playerBases[player]
		return if base then base.Name else nil
	end

	function service:getSlots(base: Model): { BasePart }
		local slots = slotsByBase[base]
		assert(slots, "The model is not a registered sanctuary")
		return table.clone(slots)
	end

	function service:onReleased(callback: (Player, Model) -> ())
		table.insert(releaseCallbacks, callback)
	end
	function service:onClaimed(callback) table.insert(claimCallbacks,callback) end
	function service:getPedestals(base)
		assert(byId[base.Name]==base,'Unknown sanctuary')
		local found,duplicates={},{}
		for _,part in base:GetDescendants() do
			local id=part:GetAttribute('PedestalId')
			if part:IsA('BasePart') and typeof(id)=='string' and #id>0
				and (part:GetAttribute('PedestalBaseId')==base.Name or part:GetAttribute('PedestalBaseId')==nil) then
				if found[id] or duplicates[id] then
					warn('Duplicate pedestal identity: '..id);found[id]=nil;duplicates[id]=true
				else found[id]=part end
			end
		end
		return found
	end
	function service:getRecoveryFrame(base,size,index)
		local spawn=spawnsByBase[base]
		-- Six reachable, spaced recovery bays remain inside the sanctuary's
		-- front court. Excess inventory waits unplaced until a bay is freed.
		assert(index>=1 and index<=6,'Recovery bay out of bounds')
		local offset=Vector3.new(-15+((index-1)%3)*15,0,-3+math.floor((index-1)/3)*13)
		local position=spawn.CFrame:PointToWorldSpace(offset)
		local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances={base,map:FindFirstChild('Paths')}
		local hit=workspace:Raycast(position+Vector3.new(0,35,0),Vector3.new(0,-100,0),params)
		local y=if hit then hit.Position.Y else spawn.Position.Y+spawn.Size.Y*.5
		return CFrame.new(position.X,y+size.Y*.5+.18,position.Z)*spawn.CFrame.Rotation
	end

	local function releasePlayer(player: Player)
		local base = playerBases[player]
		if not base then
			return
		end
		-- Keep this base closed until any placed Curses have been removed.
		clearing[base] = true
		promptsByBase[base].Enabled = false
		baseOwners[base] = nil
		playerBases[player] = nil
		player:SetAttribute("ClaimedBaseId", nil)
		player.RespawnLocation = nil
		labelsByBase[base].Text = "CLEARING..."
		local cleanupSucceeded = true
		for _, callback in ipairs(releaseCallbacks) do
			local ok, err = pcall(callback, player, base)
			if not ok then
				cleanupSucceeded = false
				warn("Sanctuary release callback failed: " .. tostring(err))
			end
		end
		base:SetAttribute("OwnerUserId", nil)
		base:SetAttribute("OwnerDisplayName", nil)
		if not cleanupSucceeded then
			labelsByBase[base].Text = "UNAVAILABLE"
			return
		end
		clearing[base] = nil
		labelsByBase[base].Text = "UNCLAIMED"
		outlinesByBase[base].Color = Color3.fromRGB(173, 115, 237)
		promptsByBase[base].Enabled = true
	end

	local function tryClaim(player: Player, base: Model)
		-- Triggered has a distance check on Roblox's side, but all state and
		-- eligibility must still be checked on the server (including Enabled).
		if player.Parent ~= Players or clearing[base] or not promptsByBase[base].Enabled then
			return
		end
		if player:GetAttribute('ProfileStatus')~='READY' then
			sendNotice(player,'Your saved account is still loading.');return
		end
		if baseOwners[base] then
			sendNotice(player, "This sanctuary has already been claimed.")
			return
		end
		if playerBases[player] then
			sendNotice(player, "You already own a sanctuary.")
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not (root and root:IsA("BasePart") and humanoid and humanoid.Health > 0) then
			return
		end
		if (root.Position - markersByBase[base].Position).Magnitude > CLAIM_DISTANCE then
			return
		end

		-- No yielding between these writes: two simultaneous claims cannot both win.
		baseOwners[base] = player
		playerBases[player] = base
		promptsByBase[base].Enabled = false
		base:SetAttribute("OwnerUserId", player.UserId)
		base:SetAttribute("OwnerDisplayName", player.DisplayName)
		player:SetAttribute("ClaimedBaseId", base.Name)
		player.RespawnLocation = spawnsByBase[base]
		labelsByBase[base].Text = player.DisplayName .. "'S BASE"
		outlinesByBase[base].Color = Color3.fromRGB(109, 220, 233)
		sendNotice(player, "Sanctuary claimed! Bring Curses here to earn Souls.")
		for _,callback in claimCallbacks do callback(player,base) end
	end

	for base, prompt in pairs(promptsByBase) do
		prompt.Triggered:Connect(function(player: Player)
			tryClaim(player, base)
		end)
	end

	Players.PlayerRemoving:Connect(releasePlayer)
	return service
end

return BaseService
