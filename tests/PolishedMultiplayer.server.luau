-- QA only. Two real Studio clients share ordinary production Curse instances.
-- No ownership/pose overrides, fictitious mesh IDs, or geometry approval claims.
local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local Http = game:GetService('HttpService')
local Run = game:GetService('RunService')
assert(Run:IsStudio(), 'Polished multiplayer fixture must remain local to Studio')
local control = Instance.new('RemoteEvent')
control.Name = 'PolishedMultiplayerControl'
control.Parent = RS
local ready, answers, startRequested = {}, {}, {}
local owner, observer, map
local sequence = 0
control.OnServerEvent:Connect(function(player, nonce, ok, value)
	if nonce == 'ready' then
		ready[player] = true
	elseif nonce == 'start' then
		if player == owner then startRequested[player] = true end
	elseif typeof(nonce) == 'string' and typeof(ok) == 'boolean' then
		answers[tostring(player.UserId) .. ':' .. nonce] = {ok = ok, value = value}
	end
end)
local function await(predicate, seconds)
	local deadline = os.clock() + seconds
	repeat
		if predicate() then return true end
		task.wait(.05)
	until os.clock() >= deadline
	return false
end
local function setStatus(stage, message)
	control:SetAttribute('Stage', stage)
	control:SetAttribute('Message', message)
	if map then map:SetAttribute('PolishedMPStatus', stage) end
	print('POLISHED_MP_STAGE', stage, message)
end
local function check(condition, label)
	assert(condition, label)
	print('POLISHED_MP_PASS', label)
end
local function dispatch(player, action, args)
	sequence += 1
	local nonce = tostring(sequence)
	control:FireClient(player, nonce, action, args)
	return tostring(player.UserId) .. ':' .. nonce
end
local function receive(key, action, seconds)
	assert(await(function() return answers[key] end, seconds or 15), 'Client timeout: ' .. action)
	local answer = answers[key]
	answers[key] = nil
	assert(answer.ok, action .. ': ' .. tostring(answer.value))
	return answer.value
end
local function client(player, action, args, seconds)
	return receive(dispatch(player, action, args), action, seconds)
end
local function pose(player, frame)
	player.Character:PivotTo(frame)
	local root = player.Character.HumanoidRootPart
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	task.wait(.18)
end
local function activeModel(uid)
	for _, model in map.ActiveCurses:GetChildren() do
		if model:GetAttribute('CurseUid') == uid then return model end
	end
end

task.spawn(function()
	local ok, failure = xpcall(function()
		setStatus('BOOT', 'Native Test: start exactly two clients. No command-bar initialization is needed.')
		map = require(script.Map.Build).build()
		local profiles = require(script.Gameplay.ProfileStore).start()
		local souls = require(script.Gameplay.SoulsService).start(profiles)
		local bases = require(script.Gameplay.BaseService).start(map)
		local curses = require(script.Gameplay.CurseService).start(map, bases, souls, profiles)
		require(script.Gameplay.CurseProcessionService).start(map, curses)
		local Catalog = require(RS.Shared.CurseCatalog)
		local Motion = require(RS.Shared.CurseMotionMath)
		local Config = require(script.Gameplay.Config)
		check(await(function()
			local list = Players:GetPlayers()
			if #list ~= 2 then return false end
			for _, p in list do
				if not ready[p] or p:GetAttribute('ProfileStatus') ~= 'READY'
					or not p.Character or not p.Character:FindFirstChild('HumanoidRootPart') then return false end
			end
			return true
		end, 120), 'two actual clients, profiles and characters ready')
		local list = Players:GetPlayers()
		table.sort(list, function(a, b) return a.Name < b.Name end)
		owner, observer = list[1], list[2]
		control:SetAttribute('OwnerUserId', owner.UserId)
		control:SetAttribute('ObserverUserId', observer.UserId)
		for _, p in list do client(p, 'role', {role = if p == owner then 'OWNER' else 'OBSERVER'}) end
		local base = bases:getBaseById('Base03')
		pose(owner, CFrame.new(base.ClaimMarker.Position - Vector3.new(0, 2, 0)))
		pose(observer, CFrame.new(base.ClaimMarker.Position + Vector3.new(6, -2, 2)))
		-- InputHold is a real prompt attempt, not Triggered:Fire or a fake claim.
		client(owner, 'prompt', {prompt = base.ClaimMarker.ClaimSanctuary})
		setStatus('WAITING_CLAIM_START', owner.Name .. ': press E to claim Sanctuary 03, arm captures on both clients, then click Start. Waiting up to 120 s.')
		check(await(function() return bases:getBaseForPlayer(owner) == base and startRequested[owner] end, 120), 'native owner claim and explicit fixture Start')
		check(base:GetAttribute('OwnerUserId') == owner.UserId and not bases:getBaseForPlayer(observer), 'ownership belongs only to the actual claimant')
		souls:credit(owner, 10000000)
		profiles:commit(owner)
		local slots = bases:getPedestals(base)
		local first, second = slots['floor1-slot1'], slots['floor1-slot2']
		check(first and second, 'pedestals found by production identity and ownership')
		local points, lengths = {}, {}
		local route = map.CurseProcessionRoute
		for i = 1, route:GetAttribute('PointCount') do points[i] = route[string.format('Point_%02d', i)].Value end
		for i = 1, #points - 1 do lengths[i] = (points[i + 1] - points[i]).Magnitude end
		local rows = {}
		local function observe(uid, id, state, stage, seconds, absent)
			control:SetAttribute('FocusUid', uid)
			control:SetAttribute('FocusId', id)
			setStatus(stage, id .. ' · ' .. state .. ' · both clients observing one authoritative instance')
			local args = {uid = uid, id = id, state = state, stage = stage,
				duration = seconds, startAt = workspace:GetServerTimeNow() + .35, absent = absent}
			local a = dispatch(owner, 'observe', args)
			local b = dispatch(observer, 'observe', args)
			local ownerView = receive(a, stage, seconds + 15)
			local observerView = receive(b, stage, seconds + 15)
			for _, view in {ownerView, observerView} do
				check(view.uid == uid and view.state == state, stage .. ' replicated identity and state on ' .. view.role)
				if not absent then
					check(view.meshId == Catalog.Definitions[id].meshId and view.boneCount > 0, stage .. ' real imported mesh and rig on ' .. view.role)
					check(view.ownerUserId == (if state == 'PROCESSION' then nil else owner.UserId), stage .. ' replicated owner on ' .. view.role)
					if state == 'CARRYING' then check(view.carrierUserId == owner.UserId, stage .. ' same carrier on ' .. view.role) end
				else check(not view.modelExists, stage .. ' instance removed on ' .. view.role) end
			end
			local row = {id = id, uid = uid, stage = stage, state = state,
				serverTime = workspace:GetServerTimeNow(), owner = ownerView, observer = observerView,
				geometryApproval = 'REQUIRES_NATIVE_VIDEO_REVIEW'}
			table.insert(rows, row)
			control:SetAttribute('ObservationsJSON', Http:JSONEncode(rows))
			map:SetAttribute('PolishedMPObservationsJSON', Http:JSONEncode(rows))
			print('POLISHED_MP_ROW', Http:JSONEncode(row))
		end
		local function walkAndObserve(uid, id, stage, seconds)
			local start = owner.Character.HumanoidRootPart.Position
			local walk = dispatch(owner, 'walk', {duration = seconds})
			observe(uid, id, 'CARRYING', stage, seconds)
			local result = receive(walk, 'walk', 10)
			check(result.distance > 2 and (owner.Character.HumanoidRootPart.Position - start).Magnitude > 1,
				stage .. ' real avatar walked, turned and stopped')
		end
		for index, id in {'cursed_doll', 'watching_eye', 'soul_chains', 'plague_monarch', 'the_void'} do
			local d = Catalog.Definitions[id]
			control:SetAttribute('CaseIndex', index)
			local uid = curses:spawn(id, Motion.route(points, lengths, 0))
			local epoch = workspace:GetServerTimeNow()
			curses:setProcessionMotion(uid, epoch, Config.ProcessionSpeedStudsPerSecond, index)
			local routeActive = true
			-- Controlled instance, same server cadence, Motion math and epoch contract
			-- as the ordinary procession. Background production also remains active.
			task.spawn(function()
				while routeActive and curses:getState(uid) == 'PROCESSION' do
					local distance = (workspace:GetServerTimeNow() - epoch) * Config.ProcessionSpeedStudsPerSecond
					curses:moveProcession(uid, Motion.route(points, lengths, distance))
					task.wait(Config.ProcessionStepSeconds)
				end
			end)
			client(owner, 'focus', {uid = uid, id = id})
			client(observer, 'focus', {uid = uid, id = id})
			-- Wait for the ordinary client bounded preload and presentation readiness.
			local a = dispatch(owner, 'readyMesh', {uid = uid})
			local b = dispatch(observer, 'readyMesh', {uid = uid})
			receive(a, 'owner native mesh readiness', 16)
			receive(b, 'observer native mesh readiness', 16)
			local caseStarted = os.clock()
			control:FireAllClients('case', 'captureCase', {uid = uid, id = id, index = index})
			observe(uid, id, 'PROCESSION', 'ROUTE', 4.4)
			routeActive = false
			local m = activeModel(uid)
			check(m and curses:getState(uid) == 'PROCESSION', id .. ' live production instance on route')
			pose(owner, CFrame.new(m.PrimaryPart.Position + Vector3.new(0, 3.5 - m.PrimaryPart.Size.Y / 2, 5)))
			local beforeBuy = souls:getBalance(owner)
			check(curses:purchase(owner, uid), id .. ' production purchase validates actual nearby owner')
			check(souls:getBalance(owner) == beforeBuy - d.price and owner:GetAttribute('SoulsPerSecond') == 0,
				id .. ' charged once, no carried production')
			walkAndObserve(uid, id, 'PURCHASE_CARRY', 5.2)
			pose(owner, CFrame.new(first.Position + Vector3.new(0, 3.5, 4)))
			check(client(owner, 'manage', {action = 'place', uid = uid, pedestalId = 'floor1-slot1'}).ok, id .. ' real client nearby placement')
			check(first:GetAttribute('OccupiedCurseUid') == uid and owner:GetAttribute('SoulsPerSecond') == d.baseSoulsPerSecond,
				id .. ' placed pedestal occupied and income resumed once')
			observe(uid, id, 'PLACED', 'PEDESTAL_IDLE', 6.6)
			-- The observer sends a real request and is rejected by normal ownership rules.
			check(not client(observer, 'manage', {action = 'pickup', uid = uid}).ok, id .. ' observer cannot pick up owner instance')
			check(client(owner, 'manage', {action = 'pickup', uid = uid}).ok, id .. ' physical pickup through real management request')
			check(not first:GetAttribute('OccupiedCurseUid') and owner:GetAttribute('SoulsPerSecond') == 0,
				id .. ' source pedestal freed, carried income paused')
			walkAndObserve(uid, id, 'RELOCATION_CARRY', 4)
			pose(owner, CFrame.new(second.Position + Vector3.new(0, 3.5, 4)))
			check(client(owner, 'manage', {action = 'place', uid = uid, pedestalId = 'floor1-slot2'}).ok, id .. ' manual nearby relocation request')
			check(second:GetAttribute('OccupiedCurseUid') == uid and owner:GetAttribute('SoulsPerSecond') == d.baseSoulsPerSecond,
				id .. ' destination occupied and income resumed once')
			observe(uid, id, 'PLACED', 'RELOCATED_IDLE', 6.6)
			local quote = client(owner, 'manage', {action = 'quote', uid = uid})
			check(quote.ok and quote.data.sale == math.floor(d.price * Config.SellFraction), id .. ' exact catalog sale quote')
			local beforeSell = souls:getBalance(owner)
			check(client(owner, 'manage', {action = 'sell', uid = uid, token = quote.data.token}).ok, id .. ' real client confirmed sale')
			-- Income can tick between requests while placed; the RF also has a .15 s
			-- settling wait. A duplicate quote/token must never pay a second time.
			local saleDelta = souls:getBalance(owner) - beforeSell
			check(saleDelta >= quote.data.sale and saleDelta <= quote.data.sale + d.baseSoulsPerSecond,
				id .. ' one sale payment plus only elapsed production')
			check(not second:GetAttribute('OccupiedCurseUid') and not activeModel(uid) and owner:GetAttribute('SoulsPerSecond') == 0,
				id .. ' sale clears runtime, pedestal and income')
			local paidBalance = souls:getBalance(owner)
			check(not client(owner, 'manage', {action = 'sell', uid = uid, token = quote.data.token}).ok
				and souls:getBalance(owner) == paidBalance, id .. ' repeated confirmed sale does not pay twice')
			observe(uid, id, 'SOLD', 'CLEANUP', 2, true)
			if os.clock() - caseStarted < 32.5 then task.wait(32.5 - (os.clock() - caseStarted)) end
		end
		control:SetAttribute('GeometryReview', 'PENDING_HUMAN_NATIVE_VIDEO_REVIEW')
		setStatus('PASS', 'Five real owner/observer lifecycles passed. Native video is still required to approve visible deformation; no robbery or persistence scenario asserted.')
		for _, p in {owner, observer} do
			p:SetAttribute('PolishedMPAssertions', 'PASS')
			control:FireClient(p, 'done', 'finish', {})
		end
	end, debug.traceback)
	if not ok then
		setStatus('BLOCKED', tostring(failure))
		control:SetAttribute('Failure', tostring(failure))
		if map then map:SetAttribute('PolishedMPFailure', tostring(failure)) end
		warn('POLISHED_MP_BLOCKED', failure)
	end
end)
