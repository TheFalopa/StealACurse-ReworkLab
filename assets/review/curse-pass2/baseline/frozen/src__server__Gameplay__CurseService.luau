local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.CurseCatalog)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Config = require(script.Parent.Config)
local Visual = require(script.Parent.CurseVisualService)

local CurseService = {}

function CurseService.start(map: Model, bases, souls)
	assert(map.Parent == workspace, "Gameplay requires the completed Workspace map")
	local center = map:FindFirstChild("CentralMausoleum")
	assert(center and center:IsA("Model"), "Map needs CentralMausoleum")
	local spawn = center:FindFirstChild("CurseSpawnPoint")
	assert(spawn and spawn:IsA("BasePart"), "CentralMausoleum needs CurseSpawnPoint")

	local folder = Instance.new("Folder")
	folder.Name = "ActiveCurses"
	folder.Parent = map

	-- `records` is logical state only and can later be serialized. Runtime Roblox
	-- Instances and motion data remain separate and never belong in persistence.
	local records = {}
	local runtimeByUid = {}
	local deliveryByUserId = {}
	local occupancyByBaseId = {}
	local lastPurchaseAttemptByUserId = {}
	local service = {}

	local function definitionFor(record)
		return Catalog.Definitions[record.definitionId]
	end

	local function destroyRecord(uid: string)
		local runtime = runtimeByUid[uid]
		if runtime then
			if runtime.promptConnection then
				runtime.promptConnection:Disconnect()
			end
			if runtime.model then
				runtime.model:Destroy()
			end
		end
		runtimeByUid[uid] = nil
		records[uid] = nil
	end

	local function recalculateProduction(player: Player)
		local total = 0
		for _, record in pairs(records) do
			if record.state == "PLACED" and record.ownerUserId == player.UserId then
				total += definitionFor(record).baseSoulsPerSecond
			end
		end
		souls:setProduction(player, total)
	end

	local function firstFreeSlot(baseId: string): number?
		local occupied = occupancyByBaseId[baseId]
		if not occupied then
			return 1
		end
		for index = 1, 5 do
			if occupied[index] == nil then
				return index
			end
		end
		return nil
	end

	local function moveToPlinth(record, model: Model, base: Model)
		local slots = bases:getSlots(base)
		local plinth = slots[record.slotId]
		local root = model.PrimaryPart
		if not base.Parent or not plinth or not plinth:IsA("BasePart")
			or not plinth:IsDescendantOf(base) or not root or root.Parent ~= model then
			return false
		end
		local rise = plinth.Size.Y * 0.5 + root.Size.Y * 0.5 + 0.18
		model:PivotTo(plinth.CFrame * CFrame.new(0, rise, 0) * CFrame.Angles(0, math.rad((record.slotId - 1) * 15), 0))
		return true
	end

	local function cancelDelivery(player: Player, reason: string)
		local uid = deliveryByUserId[player.UserId]
		if not uid then
			return
		end
		local record = records[uid]
		deliveryByUserId[player.UserId] = nil
		if record and record.state == "DELIVERING" then
			local price = definitionFor(record).price
			destroyRecord(uid)
			souls:credit(player, price)
			souls:notify(player, reason .. " " .. NumberFormat.compact(price) .. " Souls refunded.")
		end
	end

	local function purchase(player: Player, uid: string)
		local now = os.clock()
		local last = lastPurchaseAttemptByUserId[player.UserId] or -math.huge
		if now - last < Config.PurchaseAttemptCooldownSeconds then
			return
		end
		lastPurchaseAttemptByUserId[player.UserId] = now
		local record = records[uid]
		if not record or record.state ~= "PROCESSION" then
			souls:notify(player, "That Curse is no longer available.")
			return
		end
		local runtime = runtimeByUid[uid]
		if player.Parent ~= Players or not runtime or not runtime.model or not runtime.model.Parent then
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not (root and root:IsA("BasePart") and humanoid and humanoid.Health > 0) then
			return
		end
		local curseRoot = runtime.model.PrimaryPart
		if not curseRoot or (root.Position - curseRoot.Position).Magnitude > Config.MaxPurchaseDistanceStuds then
			return
		end
		local base = bases:getBaseForPlayer(player)
		if not base then
			souls:notify(player, "Claim a sanctuary before buying a Curse.")
			return
		end
		if deliveryByUserId[player.UserId] then
			souls:notify(player, "Deliver your current Curse first.")
			return
		end
		local baseId = bases:getBaseIdForPlayer(player)
		if not baseId or not firstFreeSlot(baseId) then
			souls:notify(player, "Your sanctuary has no free display slot.")
			return
		end
		local definition = definitionFor(record)
		if souls:getBalance(player) + 0.0001 < definition.price then
			souls:notify(player, "Not enough Souls for " .. definition.displayName .. ".")
			return
		end

		-- Reservation, spend, and state transition contain no yield points. Another
		-- Triggered event cannot buy the same UID once RESERVED is written.
		record.state = "RESERVED"
		runtime.prompt.Enabled = false
		if not souls:trySpend(player, definition.price) then
			record.state = "PROCESSION"
			runtime.prompt.Enabled = true
			return
		end
		record.ownerUserId = player.UserId
		record.carrierUserId = player.UserId
		record.baseId = baseId
		record.state = "DELIVERING"
		deliveryByUserId[player.UserId] = uid
		Visual.setState(runtime.model, definition, "DELIVERING")
		souls:notify(player, definition.displayName .. " purchased. Return to your sanctuary!")
	end

	function service:spawn(definitionId: string, frame: CFrame): string
		local definition = Catalog.Definitions[definitionId]
		assert(definition, "Unknown Curse definition: " .. tostring(definitionId))
		local uid = game:GetService("HttpService"):GenerateGUID(false)
		local model, prompt = Visual.create(definition, folder)
		model:SetAttribute("CurseUid", uid)
		model:SetAttribute("DefinitionId", definitionId)
		model:PivotTo(frame)
		Visual.pulse(folder, frame.Position, Catalog.Rarities[definition.rarity].glow)
		local record = {
			uid = uid, definitionId = definitionId, state = "PROCESSION",
			ownerUserId = nil, carrierUserId = nil, baseId = nil, slotId = nil,
		}
		records[uid] = record
		runtimeByUid[uid] = {
			model = model,
			prompt = prompt,
			promptConnection = prompt.Triggered:Connect(function(player)
				purchase(player, uid)
			end),
		}
		return uid
	end

	function service:getState(uid: string): string?
		local record = records[uid]
		return if record then record.state else nil
	end

	function service:moveProcession(uid: string, frame: CFrame): boolean
		local record = records[uid]
		local runtime = runtimeByUid[uid]
		if not record or record.state ~= "PROCESSION" then
			return false
		end
		if not runtime or not runtime.model or not runtime.model.Parent
			or not runtime.model.PrimaryPart or runtime.model.PrimaryPart.Parent ~= runtime.model then
			destroyRecord(uid)
			return false
		end
		runtime.model:PivotTo(frame)
		return true
	end

	function service:despawnUnsold(uid: string)
		local record = records[uid]
		if record and record.state == "PROCESSION" then
			destroyRecord(uid)
		end
	end

	function service:clearForUser(player: Player, base: Model)
		-- Called by BaseService while the vacated sanctuary is closed to claims.
		cancelDelivery(player, "Delivery cancelled on disconnect.")
		lastPurchaseAttemptByUserId[player.UserId] = nil
		local remove = {}
		for uid, record in pairs(records) do
			if record.ownerUserId == player.UserId then
				table.insert(remove, uid)
			end
		end
		for _, uid in ipairs(remove) do
			destroyRecord(uid)
		end
		occupancyByBaseId[base.Name] = nil
		souls:setProduction(player, 0)
	end

	local function deliver(player: Player, record, base: Model)
		local slotId = firstFreeSlot(record.baseId)
		if not slotId then
			cancelDelivery(player, "Delivery could not be placed.")
			return
		end
		local uid = record.uid
		local runtime = runtimeByUid[uid]
		if not runtime or not runtime.model or not runtime.model.Parent
			or not runtime.model.PrimaryPart or runtime.model.PrimaryPart.Parent ~= runtime.model then
			cancelDelivery(player, "The Curse vanished during delivery.")
			return
		end
		record.slotId = slotId
		-- Validate/move before committing ownership of a slot or production.
		if not moveToPlinth(record, runtime.model, base) then
			cancelDelivery(player, "Your display pedestal became unavailable.")
			return
		end
		record.carrierUserId = nil
		record.state = "PLACED"
		deliveryByUserId[player.UserId] = nil
		occupancyByBaseId[record.baseId] = occupancyByBaseId[record.baseId] or {}
		occupancyByBaseId[record.baseId][slotId] = uid
		Visual.setState(runtime.model, definitionFor(record), "PLACED")
		Visual.pulse(folder, runtime.model:GetPivot().Position, Catalog.Rarities[definitionFor(record).rarity].glow)
		recalculateProduction(player)
		souls:notify(player, definitionFor(record).displayName .. " placed! +" .. NumberFormat.compact(definitionFor(record).baseSoulsPerSecond) .. " Souls/s")
	end

	local function insideDisplayArea(area: BasePart, position: Vector3): boolean
		local localPoint = area.CFrame:PointToObjectSpace(position)
		return math.abs(localPoint.X) <= area.Size.X * 0.5
			and math.abs(localPoint.Z) <= area.Size.Z * 0.5
			and math.abs(localPoint.Y) <= 12
	end

	local function updateDeliveries()
		local now = os.clock()
		for userId, uid in pairs(deliveryByUserId) do
			local player = Players:GetPlayerByUserId(userId)
			local record = records[uid]
			if not player or not record or record.state ~= "DELIVERING" then
				deliveryByUserId[userId] = nil
			elseif bases:getBaseIdForPlayer(player) ~= record.baseId then
				cancelDelivery(player, "Your sanctuary became unavailable.")
			else
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				local runtime = runtimeByUid[uid]
				if not (root and root:IsA("BasePart") and humanoid and humanoid.Health > 0) then
					cancelDelivery(player, "Delivery cancelled after death/reset.")
				elseif not runtime or not runtime.model or not runtime.model.Parent
					or not runtime.model.PrimaryPart or runtime.model.PrimaryPart.Parent ~= runtime.model then
					cancelDelivery(player, "The Curse vanished during delivery.")
				else
					local base = bases:getBaseForPlayer(player)
					if not base or not base.Parent or base:GetAttribute("OwnerUserId") ~= userId then
						cancelDelivery(player, "Your sanctuary became unavailable.")
					else
						local area = base:FindFirstChild("FutureCurseDisplayArea")
						if not area or not area:IsA("BasePart") then
							cancelDelivery(player, "Your display area became unavailable.")
						elseif insideDisplayArea(area, root.Position) then
							deliver(player, record, base)
						else
							local target = root.Position - root.CFrame.LookVector * 4 + root.CFrame.RightVector * 3.1
								+ Vector3.new(0, 2.7 + math.sin(now * 2.5) * 0.22, 0)
							local targetFrame = CFrame.new(target) * CFrame.Angles(0, now * 0.6, 0)
							local current = runtime.model:GetPivot()
							runtime.model:PivotTo(current:Lerp(targetFrame, 0.42))
						end
					end
				end
			end
		end
	end

	local function refundPlaced(uid: string, record, player: Player?)
		local occupied = occupancyByBaseId[record.baseId]
		if occupied then occupied[record.slotId] = nil end
		local price = definitionFor(record).price
		destroyRecord(uid)
		if player then
			souls:credit(player, price)
			recalculateProduction(player)
			souls:notify(player, "A displayed Curse became unavailable; its price was refunded.")
		end
	end

	local function reconcilePlacedModels()
		for uid, record in pairs(records) do
			if record.state == "PLACED" then
				local runtime = runtimeByUid[uid]
				local base = bases:getBaseById(record.baseId)
				local player = Players:GetPlayerByUserId(record.ownerUserId)
				local plinth = base and bases:getSlots(base)[record.slotId]
				if not base or not base.Parent or not player
					or base:GetAttribute("OwnerUserId") ~= record.ownerUserId
					or not plinth or not plinth:IsDescendantOf(base) then
					refundPlaced(uid, record, player)
				elseif not runtime or not runtime.model or not runtime.model.Parent
					or not runtime.model.PrimaryPart or runtime.model.PrimaryPart.Parent ~= runtime.model then
					local definition = definitionFor(record)
					local ok, modelOrError, prompt = pcall(Visual.create, definition, folder)
					if ok then
						local model = modelOrError
						if runtime and runtime.promptConnection then runtime.promptConnection:Disconnect() end
						if runtime and runtime.model then runtime.model:Destroy() end
						model:SetAttribute("CurseUid", uid)
						model:SetAttribute("DefinitionId", record.definitionId)
						runtimeByUid[uid] = { model = model, prompt = prompt }
						if moveToPlinth(record, model, base) then
							Visual.setState(model, definition, "PLACED")
						else
							refundPlaced(uid, record, player)
						end
					else
						warn("Could not restore placed Curse: " .. tostring(modelOrError))
						refundPlaced(uid, record, player)
					end
				end
			end
		end
	end

	local function trackPlayer(player: Player)
		player.CharacterRemoving:Connect(function()
			cancelDelivery(player, "Delivery cancelled after death/reset.")
		end)
	end
	Players.PlayerAdded:Connect(trackPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		trackPlayer(player)
	end

	task.spawn(function()
		local nextReconcile = os.clock() + 3
		while true do
			task.wait(Config.DeliveryStepSeconds)
			updateDeliveries()
			if os.clock() >= nextReconcile then
				nextReconcile = os.clock() + 3
				reconcilePlacedModels()
			end
		end
	end)

	return service
end

return CurseService
