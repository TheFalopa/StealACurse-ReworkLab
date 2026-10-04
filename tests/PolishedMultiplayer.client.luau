-- QA only: observes the production model; never writes mesh/bone transforms.
local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local Run = game:GetService('RunService')
local Http = game:GetService('HttpService')
local Content = game:GetService('ContentProvider')
local Capture = game:GetService('CaptureService')
local player = Players.LocalPlayer
local control = RS:WaitForChild('PolishedMultiplayerControl', 120)
assert(control, 'Polished multiplayer server fixture did not start')
local request = RS:WaitForChild('CurseManagement', 120):WaitForChild('Request')
local Animation = require(script.Parent:WaitForChild('Client', 120):WaitForChild('CurseAnimation'))
local role, focusUid, focusId = 'WAITING', nil, nil
local autoCapture, captureBusy, cameraEnabled, far = false, false, false, false
local deadline = os.clock() + 720
local recordings, observations = {}, {}
local gui = Instance.new('ScreenGui')
gui.Name = 'PolishedMultiplayerControls'
gui.ResetOnSpawn = false
gui.DisplayOrder = 150
gui.Parent = player:WaitForChild('PlayerGui')
local label = Instance.new('TextLabel')
label.Name = 'Status'
label.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
label.BackgroundTransparency = .15
label.TextColor3 = Color3.new(1, 1, 1)
label.TextWrapped = true
label.TextSize = 13
label.Font = Enum.Font.Gotham
label.Size = UDim2.new(1, -24, 0, 50)
label.Position = UDim2.new(0, 12, 1, -104)
label.Parent = gui
local function button(name, x, width, handler)
	local b = Instance.new('TextButton')
	b.Name = name
	b.Text = name
	b.BackgroundColor3 = Color3.fromRGB(42, 37, 68)
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 12
	b.Size = UDim2.fromOffset(width, 38)
	b.Position = UDim2.new(0, x, 1, -48)
	b.Parent = gui
	b.Activated:Connect(handler)
	return b
end
local function startCapture()
	if captureBusy then return end
	captureBusy = true
	player:SetAttribute('PolishedMPCaptureReady', false)
	player:SetAttribute('PolishedMPCaptureId', focusId or 'waiting')
	local id, captureRole = focusId, role
	player:SetAttribute('PolishedMPCaptureStartedUnixMillis', DateTime.now().UnixTimestampMillis)
	local ok, failure = pcall(function()
		Capture:StartVideoCaptureAsync(function(status, video)
			if video then
				-- Preserve native VideoCapture lifetime; Studio owns the actual clip.
				table.insert(recordings, video)
				player:SetAttribute('PolishedMPCaptureReady', true)
				player:SetAttribute('PolishedMPCaptureSeconds', video.TimeLength)
				player:SetAttribute('PolishedMPCaptureCount', #recordings)
				print('POLISHED_MP_VIDEO', captureRole, id, video.TimeLength)
			else
				player:SetAttribute('PolishedMPCaptureFailure', tostring(status))
				warn('POLISHED_MP_CAPTURE_FAILURE', captureRole, tostring(status))
			end
			captureBusy = false
		end, {})
	end)
	if not ok then
		captureBusy = false
		player:SetAttribute('PolishedMPCaptureFailure', tostring(failure))
		warn('POLISHED_MP_CAPTURE_FAILURE', role, failure)
	end
end
local startButton = button('Start', 12, 80, function()
	if role == 'OWNER' then control:FireServer('start', true) end
end)
button('Capture 30s', 100, 105, startCapture)
local eachButton
eachButton = button('Each Curse: OFF', 213, 123, function()
	autoCapture = not autoCapture
	eachButton.Text = if autoCapture then 'Each Curse: ON' else 'Each Curse: OFF'
end)
button('Near / Far', 344, 95, function() far = not far end)
button('Camera / Player', 447, 125, function()
	cameraEnabled = not cameraEnabled
	if not cameraEnabled then workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end
end)
local function model(uid)
	local map = workspace:FindFirstChild('StealACurseMap')
	local active = map and map:FindFirstChild('ActiveCurses')
	if active then
		for _, item in active:GetChildren() do if item:GetAttribute('CurseUid') == uid then return item end end
	end
end
local function waitFor(predicate, seconds)
	local ends = os.clock() + seconds
	repeat
		local result = predicate()
		if result then return result end
		task.wait(.03)
	until os.clock() >= ends
	return nil
end
local function list3(v) return {v.X, v.Y, v.Z} end
local function frameStats(frames)
	table.sort(frames)
	local sum = 0
	for _, dt in frames do sum += dt end
	return {count = #frames, mean = sum / math.max(1, #frames),
		p95 = frames[math.max(1, math.ceil(#frames * .95))], maximum = frames[#frames]}
end
local function observe(args)
	focusUid, focusId, cameraEnabled = args.uid, args.id, true
	local m
	if args.absent then
		assert(waitFor(function() return not model(args.uid) end, 8), 'Sold model remained replicated')
	else
		m = waitFor(function()
			local candidate = model(args.uid)
			if candidate and candidate:GetAttribute('CurseState') == args.state then return candidate end
		end, 8)
		assert(m and m:FindFirstChild('CurseMesh'), 'Expected replicated model/state was not available')
	end
	while workspace:GetServerTimeNow() < args.startAt do Run.RenderStepped:Wait() end
	local mesh = m and m:FindFirstChild('CurseMesh')
	local anchor = m and m:FindFirstChild('CurseAnchor')
	local samples, changed, frames, capturedPoses = {}, {}, {}, {}
	local observedState, revision, previousPosition, maxFrameTravel, maxAnchorGap = args.state, nil, nil, 0, 0
	local startMetrics = Animation.metrics()
	local stopAt = workspace:GetServerTimeNow() + args.duration
	while workspace:GetServerTimeNow() < stopAt do
		local dt = Run.RenderStepped:Wait()
		table.insert(frames, dt)
		if m and m.Parent and mesh then
			observedState, revision = m:GetAttribute('CurseState'), m:GetAttribute('StateRevision')
			if previousPosition then maxFrameTravel = math.max(maxFrameTravel, (mesh.Position - previousPosition).Magnitude) end
			previousPosition = mesh.Position
			if anchor then maxAnchorGap = math.max(maxAnchorGap, (mesh.Position - anchor.Position).Magnitude) end
			for _, bone in mesh:GetDescendants() do
				if bone:IsA('Bone') then
					if samples[bone.Name] and samples[bone.Name] ~= bone.Transform then changed[bone.Name] = true end
					samples[bone.Name] = bone.Transform
				end
			end
		end
	end
	local names, boneCount = {}, 0
	for name in changed do table.insert(names, name) end
	table.sort(names)
	local sampleNames = {}
	for name in samples do table.insert(sampleNames, name) end
	table.sort(sampleNames)
	for index, name in sampleNames do
		local cf = samples[name]
		boneCount += 1
		if index <= 12 then
			local x, y, z = cf:ToEulerAnglesXYZ()
			local function short(n) return math.round(n * 10000) / 10000 end
			capturedPoses[name] = {short(x), short(y), short(z), short(cf.X), short(cf.Y), short(cf.Z)}
		end
	end
	local assetStatus
	if mesh then pcall(function() assetStatus = tostring(Content:GetAssetFetchStatus(mesh.MeshId)) end) end
	local result = {role = role, userId = player.UserId, uid = args.uid, state = observedState,
		modelExists = model(args.uid) ~= nil, meshId = mesh and mesh.MeshId,
		size = mesh and list3(mesh.Size), boneCount = boneCount, changedBones = names,
		ownerUserId = m and m:GetAttribute('OwnerUserId'), carrierUserId = m and m:GetAttribute('CarrierUserId'),
		pedestalId = m and m:GetAttribute('PedestalId'), stateRevision = revision,
		frames = frameStats(frames), maximumFrameTravelStuds = maxFrameTravel,
		maximumVisualAuthoritySeparationStuds = maxAnchorGap, poseAtEnd = capturedPoses,
		assetFetchStatus = assetStatus, metricsBefore = startMetrics, metricsAfter = Animation.metrics(),
		geometryApproval = 'NOT_PROVED_BY_BONE_TRANSFORMS_REVIEW_NATIVE_VIDEO'}
	table.insert(observations, result)
	player:SetAttribute('PolishedMPObservationsJSON', Http:JSONEncode(observations))
	player:SetAttribute('PolishedMPLastState', observedState)
	player:SetAttribute('PolishedMPLastUid', args.uid)
	return result
end
control.OnClientEvent:Connect(function(nonce, action, args)
	if action == 'captureCase' then
		focusUid, focusId, cameraEnabled = args.uid, args.id, true
		-- Distinct native start times let the coordinator map local files to roles.
		if autoCapture then
			if role == 'OBSERVER' then task.delay(1.2, startCapture) else startCapture() end
		end
		return
	elseif action == 'finish' then
		autoCapture = false
		eachButton.Text = 'Each Curse: OFF'
		return
	end
	task.spawn(function()
		local ok, result = pcall(function()
			if action == 'role' then
				role = args.role
				startButton.Text = if role == 'OWNER' then 'Start' else 'Observer'
				startButton.Active = role == 'OWNER'
				player:SetAttribute('PolishedMPRole', role)
				return role
			elseif action == 'prompt' then
				args.prompt:InputHoldBegin()
				task.wait(.15)
				if args.prompt.Parent then args.prompt:InputHoldEnd() end
				return true
			elseif action == 'focus' then
				focusUid, focusId, cameraEnabled = args.uid, args.id, true
				return true
			elseif action == 'readyMesh' then
				assert(waitFor(function()
					local m = model(args.uid)
					return m and m:GetAttribute('PresentationReady') and m:FindFirstChild('CurseMesh')
				end, 14), 'Ordinary mesh preload/presentation did not become ready')
				return true
			elseif action == 'manage' then
				local result = request:InvokeServer(args.action, args.uid, args.pedestalId, args.token)
				-- Production per-player throttling is .12 s; never race sequential legal actions.
				task.wait(.15)
				return result
			elseif action == 'observe' then
				return observe(args)
			elseif action == 'walk' then
				local character = player.Character
				local humanoid = character and character:FindFirstChildOfClass('Humanoid')
				local root = character and character:FindFirstChild('HumanoidRootPart')
				assert(humanoid and root, 'No live owner character')
				local start, distance, previous = root.Position, 0, root.Position
				local starts = os.clock()
				local targets = {start + Vector3.new(8, 0, 0), start + Vector3.new(8, 0, 5),
					start + Vector3.new(2, 0, 5)}
				local section = 0
				while os.clock() - starts < args.duration do
					local elapsed = os.clock() - starts
					local phase = if elapsed < args.duration * .27 then 1
						else if elapsed < args.duration * .5 then 2
						else if elapsed < args.duration * .64 then 3
						else if elapsed < args.duration * .9 then 4 else 5
					if phase ~= section then
						section = phase
						humanoid:MoveTo(if phase == 1 then targets[1] else if phase == 2 then targets[2]
							else if phase == 4 then targets[3] else root.Position)
					end
					distance += (root.Position - previous).Magnitude
					previous = root.Position
					Run.RenderStepped:Wait()
				end
				humanoid:MoveTo(root.Position)
				return {distance = distance, start = list3(start), finish = list3(root.Position)}
			end
			error('Unknown fixture action ' .. tostring(action))
		end)
		control:FireServer(nonce, ok, if ok then result else tostring(result))
	end)
end)
control:FireServer('ready', true)

-- One finite QA camera/HUD connection; the production animation owns every pose.
local connection
connection = Run.RenderStepped:Connect(function()
	if os.clock() >= deadline or not gui.Parent then
		connection:Disconnect()
		if cameraEnabled then workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end
		return
	end
	local m = focusUid and model(focusUid)
	local mesh = m and m:FindFirstChild('CurseMesh')
	if cameraEnabled and mesh then
		local distance = math.max(14, mesh.Size.Y * 1.8) * (if far then 2.1 else 1)
		local focus = mesh.Position
		local offset = mesh.CFrame.LookVector * distance + mesh.CFrame.RightVector * distance * .24
			+ Vector3.new(0, mesh.Size.Y * .13, 0)
		local camera = workspace.CurrentCamera
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.lookAt(focus + offset, focus)
		camera.FieldOfView = 55
	end
	local metrics = Animation.metrics()
	label.Text = string.format('%s · %s · %s | active %d / suspended %d | %s\n%s',
		player.Name, role, focusId or 'native claim', metrics.tracked, metrics.suspended,
		control:GetAttribute('Stage') or 'BOOT', control:GetAttribute('Message') or 'Waiting for two native clients')
end)
