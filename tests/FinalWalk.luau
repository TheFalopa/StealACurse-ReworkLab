-- Review-fixture ModuleScript. Its returned object is cached by require(),
-- so CommandBar does not need to share Script _G. No walk starts on import.
-- Client example: require(game.ReplicatedStorage.TestFinalWalk).walkTo("castle")
-- The original standalone FinalWalk.client.luau is preserved separately.
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local player = Players.LocalPlayer
assert(player, "FinalWalk must run on a real Play client")
-- ModuleScript caching preserves one walk/history object for this client.

local walk = { busy = false, history = {}, lastResult = nil, progress = nil }
local serial = 0
local activeToken = nil

local function coordinates(value: Vector3)
	return { value.X, value.Y, value.Z }
end
local function mapModel(): Model
	local map = workspace:FindFirstChild("StealACurseMap")
	assert(map and map:IsA("Model"), "Production map is missing")
	return map
end
local function resolve(target)
	if typeof(target) == "Vector3" then return target, "coordinate target" end
	if typeof(target) == "Instance" then
		if target:IsA("BasePart") then return target.Position, target:GetFullName() end
		if target:IsA("Model") then return target:GetPivot().Position, target:GetFullName() end
		error("Target instance must be a BasePart or Model")
	end
	assert(type(target) == "string", "Use a Vector3, BasePart, Model, castle, or Base01..Base08")
	local map = mapModel()
	if string.lower(target) == "castle" then
		local center = map:FindFirstChild("CentralMausoleum")
		local spawn = center and center:FindFirstChild("CurseSpawnPoint")
		assert(spawn and spawn:IsA("BasePart"), "CurseSpawnPoint is missing")
		return spawn.Position + Vector3.new(0, 1, 24), "castle court"
	end
	local id, location = string.match(target, "^(Base0[1-8]):?(%a*)$")
	assert(id, "Named targets are castle or Base01..Base08, optionally :entry or :claim")
	local sanctuaries = map:FindFirstChild("PlayerSanctuaries")
	local base = sanctuaries and sanctuaries:FindFirstChild(id)
	assert(base and base:IsA("Model"), id .. " is missing")
	local markerName = if location == "entry" then "PlayerSpawn" elseif location == "claim" then "ClaimMarker" else "FutureCurseDisplayArea"
	assert(location == "" or location == "entry" or location == "claim", "Only :entry and :claim target suffixes are supported")
	local marker = base:FindFirstChild(markerName)
	assert(marker and marker:IsA("BasePart"), id .. "." .. markerName .. " is missing")
	local rise = if location == "claim" then 0 elseif location == "entry" then 2.3 else 3
	return marker.Position + Vector3.new(0, rise, 0), id .. (location == "" and " display court" or " " .. location)
end
local function currentCharacter()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	assert(character and humanoid and root and root:IsA("BasePart") and humanoid.Health > 0, "A live normal character is required")
	assert(math.abs(humanoid.WalkSpeed - 16) < 0.01, "Expected normal WalkSpeed16; current value is " .. tostring(humanoid.WalkSpeed))
	return character, humanoid, root
end
local function horizontalDistance(first: Vector3, last: Vector3): number
	return Vector2.new(first.X - last.X, first.Z - last.Z).Magnitude
end

local function performLeg(token, target, label, legIndex: number, legCount: number)
	local destination, targetName = resolve(target)
	local character, humanoid, root = currentCharacter()
	local result = {
		label = label or targetName, target = targetName, reached = false, canceled = false,
		startPosition = coordinates(root.Position), destination = coordinates(destination),
		walkSpeed = humanoid.WalkSpeed, planningSeconds = 0, actualWalkingSeconds = 0,
		actualDistanceStuds = 0, pathLengthStuds = 0, jumpWaypoints = 0, actualJumps = 0,
		waypointArrivalToleranceStuds = 3, moveToFinishedArrivals = 0, toleranceArrivals = 0,
	}
	walk.progress = { runId = token.id, status = "planning", leg = legIndex, legs = legCount, target = targetName, elapsedSeconds = 0 }
	local planningStart = os.clock()
	local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 6 })
	path:ComputeAsync(root.Position, destination)
	result.planningSeconds = os.clock() - planningStart
	result.pathStatus = path.Status.Name
	if path.Status ~= Enum.PathStatus.Success then
		result.failure = "No navigable path: " .. result.pathStatus
		return result
	end
	local waypoints = path:GetWaypoints()
	for index, waypoint in ipairs(waypoints) do
		if waypoint.Action == Enum.PathWaypointAction.Jump then result.jumpWaypoints += 1 end
		if index > 1 then result.pathLengthStuds += (waypoint.Position - waypoints[index - 1].Position).Magnitude end
	end
	local stateConnection = humanoid.StateChanged:Connect(function(_, state)
		if state == Enum.HumanoidStateType.Jumping then result.actualJumps += 1 end
	end)
	local walkingStart = os.clock()
	local previousPosition = root.Position
	local function invalidCharacter()
		if token.canceled then return "Canceled by helper request" end
		if player.Character ~= character or not root.Parent or humanoid.Health <= 0 then return "Character died or changed during walk" end
		if math.abs(humanoid.WalkSpeed - 16) >= 0.01 then return "WalkSpeed changed during walk" end
		return nil
	end
	local function withinWaypointTolerance(position: Vector3): boolean
		-- Path waypoints describe the floor, while HumanoidRootPart sits above it.
		-- Do not mistake a nearby XZ coordinate on another floor for arrival.
		return horizontalDistance(root.Position, position) <= 3 and math.abs(root.Position.Y - position.Y) <= 5
	end
	local function waypointFailure(reason: string, index: number, position: Vector3, moveToFinished: boolean?)
		result.failedWaypoint = index
		result.failedWaypointPosition = coordinates(position)
		result.failedPosition = coordinates(root.Position)
		result.remainingWaypointHorizontalStuds = horizontalDistance(root.Position, position)
		result.remainingWaypointVerticalStuds = math.abs(root.Position.Y - position.Y)
		result.failedMoveToFinished = moveToFinished
		result.failure = string.format(
			"%s at waypoint %d; target=(%.2f, %.2f, %.2f), position=(%.2f, %.2f, %.2f), horizontal distance=%.2f studs, vertical distance=%.2f studs",
			reason, index, position.X, position.Y, position.Z, root.Position.X, root.Position.Y, root.Position.Z,
			result.remainingWaypointHorizontalStuds, result.remainingWaypointVerticalStuds
		)
	end
	for index, waypoint in ipairs(waypoints) do
		local invalid = invalidCharacter()
		if invalid then waypointFailure(invalid, index, waypoint.Position, nil); break end
		if not withinWaypointTolerance(waypoint.Position) then
			local moveToFinished = nil
			local moveToReached = false
			local moveConnection = humanoid.MoveToFinished:Connect(function(reached: boolean)
				moveToFinished = reached
				-- A prior MoveTo canceled by the next waypoint can also fire this
				-- signal. Keep a reported arrival bounded to the requested waypoint.
				if reached and withinWaypointTolerance(waypoint.Position) then moveToReached = true end
			end)
			if waypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
			humanoid:MoveTo(waypoint.Position)
			local deadline = os.clock() + 8.5
			repeat
				task.wait(0.1)
				result.actualDistanceStuds += (root.Position - previousPosition).Magnitude
				previousPosition = root.Position
				walk.progress = {
					runId = token.id, status = "walking", leg = legIndex, legs = legCount,
					target = targetName, waypoint = index, waypoints = #waypoints,
					waypointPosition = coordinates(waypoint.Position), waypointHorizontalStuds = horizontalDistance(root.Position, waypoint.Position),
					moveToFinished = moveToFinished,
					elapsedSeconds = os.clock() - walkingStart, position = coordinates(root.Position),
				}
				invalid = invalidCharacter()
			until invalid or moveToReached or withinWaypointTolerance(waypoint.Position) or os.clock() >= deadline
			moveConnection:Disconnect()
			if invalid then waypointFailure(invalid, index, waypoint.Position, moveToFinished); break end
			if not moveToReached and not withinWaypointTolerance(waypoint.Position) then
				waypointFailure("Movement blocked or timed out", index, waypoint.Position, moveToFinished)
				break
			end
			if moveToReached then result.moveToFinishedArrivals += 1 else result.toleranceArrivals += 1 end
		end
	end
	result.actualWalkingSeconds = os.clock() - walkingStart
	result.endPosition = coordinates(root.Position)
	result.remainingHorizontalStuds = horizontalDistance(root.Position, destination)
	result.reached = result.failure == nil and result.remainingHorizontalStuds <= 4 and math.abs(root.Position.Y - destination.Y) <= 5
	result.canceled = token.canceled
	if not result.reached and not result.failure then
		waypointFailure("Walk ended outside target tolerance", #waypoints, destination, nil)
	end
	stateConnection:Disconnect()
	return result
end

local function launch(targets, labels)
	if walk.busy then return { started = false, reason = "A walk is already active", runId = activeToken and activeToken.id } end
	assert(type(targets) == "table" and #targets > 0, "Provide at least one target")
	serial += 1
	local token = { id = serial, canceled = false }
	activeToken = token
	walk.busy = true
	walk.progress = { runId = token.id, status = "starting", legs = #targets }
	local launchStart = os.clock()
	task.spawn(function()
		local run = { runId = token.id, reached = true, canceled = false, legs = {}, elapsedSeconds = 0 }
		for index, target in ipairs(targets) do
			local ok, result = pcall(performLeg, token, target, labels and labels[index], index, #targets)
			if not ok then result = { reached = false, failure = tostring(result), canceled = token.canceled } end
			table.insert(run.legs, result)
			if not result.reached then
				run.reached = false
				run.failure = result.failure
				break
			end
		end
		run.elapsedSeconds = os.clock() - launchStart
		run.canceled = token.canceled
		walk.lastResult = run
		table.insert(walk.history, run)
		walk.busy = false
		walk.progress = { runId = token.id, status = if run.reached then "reached" elseif token.canceled then "canceled" else "failed", elapsedSeconds = run.elapsedSeconds }
		activeToken = nil
		print("FINAL_WALK_RESULT", game:GetService("HttpService"):JSONEncode(run))
	end)
	return { started = true, runId = token.id, legs = #targets }
end

function walk.walkTo(target, label)
	return launch({ target }, { label })
end
function walk.sequence(targets, labels)
	return launch(targets, labels)
end
function walk.cancel()
	if activeToken then activeToken.canceled = true end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and root and root:IsA("BasePart") then humanoid:MoveTo(root.Position) end
	return { canceled = activeToken ~= nil, runId = activeToken and activeToken.id }
end
function walk.summary()
	return { busy = walk.busy, progress = walk.progress, lastResult = walk.lastResult, completedRuns = #walk.history }
end

return walk
