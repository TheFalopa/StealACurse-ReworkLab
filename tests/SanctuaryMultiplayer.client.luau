-- Local Studio QA. Reads production models/poses; never writes mesh or bones.
-- The only local collision write is an explicitly labelled foreign-seal test.
local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local Run = game:GetService('RunService')
local Http = game:GetService('HttpService')
local Content = game:GetService('ContentProvider')
local Capture = game:GetService('CaptureService')
assert(Run:IsStudio(), 'Sanctuary multiplayer client is Studio QA only')
local player = Players.LocalPlayer
local control = RS:WaitForChild('SanctuaryMultiplayerControl', 120)
assert(control, 'Sanctuary multiplayer server fixture did not start')
local qaRequest = RS:WaitForChild('SanctuaryMultiplayerAction', 120)
local manage = RS:WaitForChild('CurseManagement', 120):WaitForChild('Request')
local restoration = RS:WaitForChild('SanctuaryRestoration', 120):WaitForChild('Request')
local Animation = require(script.Parent:WaitForChild('Client', 120):WaitForChild('CurseAnimation'))
local role, baseName = 'WAITING', nil
local focusUid, focusId, focusKind, baseFrame = nil, nil, 'CURSE', nil
local cameraEnabled, far, autoCapture, captureBusy = false, false, true, false
local deadline = os.clock() + 1200
local recordings, captures, observations = {}, {}, {}
local gui = Instance.new('ScreenGui')
gui.Name = 'SanctuaryMultiplayerControls'
gui.ResetOnSpawn, gui.DisplayOrder = false, 150
gui.Parent = player:WaitForChild('PlayerGui')
local label = Instance.new('TextLabel')
label.Name = 'Status'
label.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
label.BackgroundTransparency = .15
label.TextColor3 = Color3.new(1, 1, 1)
label.TextWrapped, label.TextSize, label.Font = true, 13, Enum.Font.Gotham
label.Size, label.Position = UDim2.new(1, -24, 0, 62), UDim2.new(0, 12, 1, -115)
label.Parent = gui
local function button(name, x, width, handler)
	local b = Instance.new('TextButton')
	b.Name, b.Text = name, name
	b.BackgroundColor3, b.TextColor3 = Color3.fromRGB(42, 37, 68), Color3.new(1, 1, 1)
	b.Font, b.TextSize = Enum.Font.GothamMedium, 12
	b.Size, b.Position = UDim2.fromOffset(width, 38), UDim2.new(0, x, 1, -48)
	b.Parent = gui
	b.Activated:Connect(handler)
	return b
end
local startButton = button('Start', 12, 75, function() if role == 'OWNER' then control:FireServer('start', true) end end)
local autoButton
local function startCapture(captureLabel)
	if captureBusy then
		player:SetAttribute('SanctuaryMPCaptureSkipped', 'Native capture already active: ' .. tostring(captureLabel))
		return
	end
	captureBusy = true
	local id, captureRole = captureLabel or focusId or 'waiting', role
	local startedAt = DateTime.now().UnixTimestampMillis
	player:SetAttribute('SanctuaryMPCaptureReady', false)
	player:SetAttribute('SanctuaryMPCaptureLabel', id)
	player:SetAttribute('SanctuaryMPCaptureStartedUnixMillis', startedAt)
	local ok, failure = pcall(function()
		Capture:StartVideoCaptureAsync(function(status, video)
			local row = {label = id, role = captureRole, player = player.Name, startedUnixMillis = startedAt,
				status = tostring(status), pixelApproval = 'PENDING_NATIVE_CLIP_REVIEW'}
			if video then
				-- Preserve VideoCapture lifetime so native Studio can save the clip.
				table.insert(recordings, video)
				row.seconds = video.TimeLength
				player:SetAttribute('SanctuaryMPCaptureReady', true)
				player:SetAttribute('SanctuaryMPCaptureSeconds', video.TimeLength)
				player:SetAttribute('SanctuaryMPCaptureCount', #recordings)
				print('SANCTUARY_MP_VIDEO', captureRole, id, startedAt, video.TimeLength)
			else
				player:SetAttribute('SanctuaryMPCaptureFailure', tostring(status))
				warn('SANCTUARY_MP_CAPTURE_FAILED', captureRole, id, tostring(status))
			end
			table.insert(captures, row)
			player:SetAttribute('SanctuaryMPCapturesJSON', Http:JSONEncode(captures))
			captureBusy = false
		end, {})
	end)
	if not ok then
		captureBusy = false
		player:SetAttribute('SanctuaryMPCaptureFailure', tostring(failure))
		warn('SANCTUARY_MP_CAPTURE_FAILED', captureRole, id, failure)
	end
end
button('Capture 30s', 95, 105, function() startCapture() end)
autoButton = button('Auto video: ON', 208, 120, function()
	autoCapture = not autoCapture
	autoButton.Text = if autoCapture then 'Auto video: ON' else 'Auto video: OFF'
end)
button('Near / Far', 336, 92, function() far = not far end)
button('Camera / Player', 436, 120, function()
	cameraEnabled = not cameraEnabled
	if not cameraEnabled then workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end
end)
local function target(uid, kind)
	local map = workspace:FindFirstChild('StealACurseMap')
	local folder = map and map:FindFirstChild(if kind == 'RELIC' then 'ContractRelics' else 'ActiveCurses')
	if folder then for _, item in folder:GetChildren() do
		if item:GetAttribute(if kind == 'RELIC' then 'RelicToken' else 'CurseUid') == uid then return item end
	end end
end
local function waitFor(predicate, seconds)
	local ends = os.clock() + seconds
	repeat
		local answer = predicate()
		if answer then return answer end
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
		p95 = frames[math.max(1, math.ceil(#frames * .95))] or 0, maximum = frames[#frames] or 0}
end
local function focus(args)
	focusUid, focusId, focusKind = args.uid, args.id, args.kind or 'CURSE'
	baseFrame, cameraEnabled = nil, true
end
local function observe(args)
	focus(args)
	local m
	if args.absent then
		assert(waitFor(function() return not target(args.uid, args.kind) end, 8), 'Removed model remained replicated')
	else
		m = waitFor(function()
			local candidate = target(args.uid, args.kind)
			if candidate and (args.kind ~= 'CURSE' or candidate:GetAttribute('CurseState') == args.state) then return candidate end
		end, 10)
		assert(m and m.PrimaryPart, 'Expected production instance/state did not replicate')
	end
	while workspace:GetServerTimeNow() < args.startAt do Run.RenderStepped:Wait() end
	local mesh = m and m:FindFirstChild('CurseMesh')
	local anchor = m and m:FindFirstChild('CurseAnchor')
	local visual = mesh or (m and m.PrimaryPart)
	local previousPosition, maxFrameTravel, maxAnchorGap, maxCarrierGap = nil, 0, 0, 0
	local frames, samples, changed, finalTransforms = {}, {}, {}, {}
	local startMetrics = Animation.metrics()
	local stopAt = workspace:GetServerTimeNow() + args.duration
	while workspace:GetServerTimeNow() < stopAt do
		local dt = Run.RenderStepped:Wait()
		table.insert(frames, dt)
		if visual and visual.Parent then
			if previousPosition then maxFrameTravel = math.max(maxFrameTravel, (visual.Position - previousPosition).Magnitude) end
			previousPosition = visual.Position
			if anchor then maxAnchorGap = math.max(maxAnchorGap, (visual.Position - anchor.Position).Magnitude) end
			local carrier = Players:GetPlayerByUserId(m:GetAttribute('CarrierUserId') or 0)
			local root = carrier and carrier.Character and carrier.Character:FindFirstChild('HumanoidRootPart')
			if root then maxCarrierGap = math.max(maxCarrierGap, (visual.Position - root.Position).Magnitude) end
			if mesh then for _, bone in mesh:GetDescendants() do if bone:IsA('Bone') then
				if samples[bone.Name] and samples[bone.Name] ~= bone.Transform then changed[bone.Name] = true end
				samples[bone.Name] = bone.Transform
			end end end
		end
	end
	local changedNames, boneCount, partCount = {}, 0, 0
	for name in changed do table.insert(changedNames, name) end
	table.sort(changedNames)
	local names = {}
	for name in samples do table.insert(names, name) end
	table.sort(names)
	for index, name in names do
		boneCount += 1
		if index <= 12 then
			local cf = samples[name]
			local x, y, z = cf:ToEulerAnglesXYZ()
			finalTransforms[name] = {x, y, z, cf.X, cf.Y, cf.Z}
		end
	end
	if m then for _, item in m:GetChildren() do if item:IsA('BasePart') then partCount += 1 end end end
	local assetStatus
	if mesh then pcall(function() assetStatus = tostring(Content:GetAssetFetchStatus(mesh.MeshId)) end) end
	local result = {role = role, userId = player.UserId, kind = args.kind, uid = args.uid,
		modelExists = target(args.uid, args.kind) ~= nil,
		state = if args.kind == 'CURSE' and m then m:GetAttribute('CurseState') else args.state,
		meshId = mesh and mesh.MeshId, textureId = mesh and mesh.TextureID, size = visual and list3(visual.Size),
		boneCount = boneCount, changedBones = changedNames, poseAtEnd = finalTransforms, partCount = partCount,
		ownerUserId = m and m:GetAttribute('OwnerUserId'), carrierUserId = m and m:GetAttribute('CarrierUserId'),
		pedestalId = m and m:GetAttribute('PedestalId'), stateRevision = m and m:GetAttribute('StateRevision'),
		relicHook = m and m:FindFirstChild('RelicSealHook', true) ~= nil,
		frames = frameStats(frames), maximumFrameTravelStuds = maxFrameTravel,
		maximumVisualAuthoritySeparationStuds = maxAnchorGap, maximumVisualCarrierSeparationStuds = maxCarrierGap,
		assetFetchStatus = assetStatus, metricsBefore = startMetrics, metricsAfter = Animation.metrics(),
		clientPosition = visual and list3(visual.Position),
		pixelApproval = 'BONE_TRANSFORMS_ARE_FACTS_NOT_GEOMETRY_APPROVAL_REVIEW_NATIVE_CLIP'}
	table.insert(observations, result)
	player:SetAttribute('SanctuaryMPObservationsJSON', Http:JSONEncode(observations))
	player:SetAttribute('SanctuaryMPLastUid', args.uid)
	return result
end
local function walk(args)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass('Humanoid')
	local root = character and character:FindFirstChild('HumanoidRootPart')
	assert(humanoid and root, 'No live QA walker character')
	local previous, distance, frames = root.Position, 0, {}
	local start = root.Position
	local barrier = args.barrier
	local originalCollision = barrier and barrier.CanCollide
	if barrier then barrier.CanCollide = false end
	local disabled = barrier and barrier.CanCollide == false
	local ok, result = pcall(function()
		humanoid:MoveTo(args.target)
		local stopAt = os.clock() + args.duration
		while os.clock() < stopAt do
			table.insert(frames, Run.RenderStepped:Wait())
			distance += (root.Position - previous).Magnitude
			previous = root.Position
		end
		humanoid:MoveTo(root.Position)
		return {distance = distance, start = list3(start), finish = list3(root.Position),
			localFinish = args.frame and list3(args.frame:PointToObjectSpace(root.Position)),
			localCollisionDisabled = disabled == true, frames = frameStats(frames),
			stage = args.stage, movementMethod = 'LOCAL_HUMANOID_MOVETO_REAL_CHARACTER'}
	end)
	if barrier and barrier.Parent then barrier.CanCollide = originalCollision end
	if not ok then error(result) end
	return result
end
control.OnClientEvent:Connect(function(nonce, action, args)
	if action == 'captureCase' then
		if args.kind ~= 'BASE' then focus(args) end
		player:SetAttribute('SanctuaryMPCurrentClipLabel', args.label)
		if autoCapture then
			if role == 'OBSERVER' then task.delay(1.0, function() startCapture(args.label) end)
			else startCapture(args.label) end
		end
		return
	elseif action == 'finish' then
		autoCapture, cameraEnabled = false, false
		autoButton.Text = 'Auto video: OFF'
		workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
		return
	end
	task.spawn(function()
		local ok, result = pcall(function()
			if action == 'role' then
				role, baseName = args.role, args.base
				startButton.Text = if role == 'OWNER' then 'Start' else 'Observer'
				startButton.Active = role == 'OWNER'
				player:SetAttribute('SanctuaryMPRole', role)
				return role
			elseif action == 'manage' then
				local answer = manage:InvokeServer(args.action, args.uid, args.pedestalId, args.token)
				task.wait(.18)
				return answer
			elseif action == 'sanctuary' then
				local answer = restoration:InvokeServer(args.action, args.value)
				task.wait(.18)
				return answer
			elseif action == 'purchase' then
				local answer = qaRequest:InvokeServer('purchase', args.uid)
				task.wait(.35)
				return answer
			elseif action == 'contract' then
				local answer = qaRequest:InvokeServer('contract_interact', args.nodeId)
				task.wait(.18)
				return answer
			elseif action == 'readyMesh' then
				focus(args)
				assert(waitFor(function()
					local m = target(args.uid, 'CURSE')
					return m and m:GetAttribute('PresentationReady') and m:FindFirstChild('CurseMesh')
				end, 16), 'Ordinary bounded preload/presentation readiness timed out')
				return true
			elseif action == 'focusBase' then
				baseFrame, cameraEnabled, focusUid, focusId = args.frame, true, nil, 'protective_seal'
				return true
			elseif action == 'observe' then return observe(args)
			elseif action == 'walk' then return walk(args)
			end
			error('Unknown QA client action: ' .. tostring(action))
		end)
		control:FireServer(nonce, ok, if ok then result else tostring(result))
	end)
end)
control:FireServer('ready', true)

-- One bounded QA camera/status connection. Production animation owns all poses.
local connection
connection = Run.RenderStepped:Connect(function()
	if os.clock() >= deadline or not gui.Parent then
		connection:Disconnect()
		if cameraEnabled then workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end
		return
	end
	local camera = workspace.CurrentCamera
	local m = focusUid and target(focusUid, focusKind)
	local visual = m and (m:FindFirstChild('CurseMesh') or m.PrimaryPart)
	if cameraEnabled and baseFrame then
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.lookAt(baseFrame:PointToWorldSpace(Vector3.new(19, 13, -64)),
			baseFrame:PointToWorldSpace(Vector3.new(0, 7, -31)))
		camera.FieldOfView = 58
	elseif cameraEnabled and visual then
		local distance = math.max(16, visual.Size.Y * 1.8) * (if far then 2.1 else 1)
		local focus = visual.Position
		local offset = visual.CFrame.LookVector * distance + visual.CFrame.RightVector * distance * .24
			+ Vector3.new(0, math.max(visual.Size.Y * .13, 1), 0)
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.lookAt(focus + offset, focus)
		camera.FieldOfView = 55
	end
	local metrics = Animation.metrics()
	label.Text = string.format('%s · %s · %s · %s | active %d / suspended %d | %s\n%s\n%s',
		player.Name, role, baseName or 'claim', focusId or 'native E claim', metrics.tracked, metrics.suspended,
		control:GetAttribute('Stage') or 'BOOT', control:GetAttribute('Message') or 'Waiting for exactly two clients',
		player:GetAttribute('SanctuaryMPCurrentClipLabel') or 'QA levels/resources explicitly seeded; pixels require native review')
end)
