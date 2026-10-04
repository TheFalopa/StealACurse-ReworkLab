-- QA only. Exactly two native Studio clients; production ownership and poses.
-- Explicit level/resource seeds before native claims. No mesh/bone/VFX override.
local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local Http = game:GetService('HttpService')
local Run = game:GetService('RunService')
assert(Run:IsStudio(), 'Sanctuary multiplayer fixture is local Studio QA only')
local control = Instance.new('RemoteEvent')
control.Name = 'SanctuaryMultiplayerControl'
control.Parent = RS
local qaRequest = Instance.new('RemoteFunction')
qaRequest.Name = 'SanctuaryMultiplayerAction'
qaRequest.Parent = RS
local ready, answers, pending = {}, {}, {}
local owner, observer, map, profiles, souls, bases, sanctuary, carry, curses, contracts
local startRequested, sequence = false, 0
local checks, observations, positions, seeds = {}, {}, {}, {}
local started = os.clock()

local function publish(name, value)
	control:SetAttribute(name, Http:JSONEncode(value))
end
local function await(predicate, seconds)
	local deadline = os.clock() + seconds
	repeat
		if predicate() then return true end
		task.wait(.05)
	until os.clock() >= deadline
	return false
end
local function status(stage, message)
	control:SetAttribute('Stage', stage)
	control:SetAttribute('Message', message)
	if map then map:SetAttribute('SanctuaryMPStatus', stage) end
	print('SANCTUARY_MP_STAGE', stage, message)
end
local function check(ok, label, detail)
	table.insert(checks, {ok = ok == true, label = label, detail = detail,
		serverTime = workspace:GetServerTimeNow()})
	publish('ChecksJSON', checks)
	assert(ok, label .. ': ' .. tostring(detail))
	print('SANCTUARY_MP_PASS', label)
end
local function rootOf(player)
	return player.Character and player.Character:FindFirstChild('HumanoidRootPart')
end
local function list3(v) return {v.X, v.Y, v.Z} end
local function activeModel(uid)
	for _, model in map.ActiveCurses:GetChildren() do
		if model:GetAttribute('CurseUid') == uid then return model end
	end
end
local function pose(player, frame)
	assert(rootOf(player), 'Live player character required')
	player.Character:PivotTo(frame)
	rootOf(player).AssemblyLinearVelocity = Vector3.zero
	rootOf(player).AssemblyAngularVelocity = Vector3.zero
	task.wait(.25)
end
local function near(player, marker)
	assert(marker and marker.Parent, 'Real production marker required')
	pose(player, marker.CFrame * CFrame.new(0, 1, -3))
end
local function dispatch(player, action, args)
	sequence += 1
	local nonce = tostring(sequence)
	local key = tostring(player.UserId) .. ':' .. nonce
	pending[key] = true
	control:FireClient(player, nonce, action, args)
	return key
end
local function receive(key, action, seconds)
	assert(await(function() return answers[key] end, seconds or 20), 'Client timeout: ' .. action)
	local answer = answers[key]
	answers[key], pending[key] = nil, nil
	assert(answer.ok, action .. ': ' .. tostring(answer.value))
	return answer.value
end
local function client(player, action, args, seconds)
	return receive(dispatch(player, action, args), action, seconds)
end
control.OnServerEvent:Connect(function(player, nonce, ok, value)
	if nonce == 'ready' then ready[player] = true
	elseif nonce == 'start' then if player == owner then startRequested = true end
	elseif typeof(nonce) == 'string' and typeof(ok) == 'boolean' then
		local key = tostring(player.UserId) .. ':' .. nonce
		if pending[key] then answers[key] = {ok = ok, value = value} end
	end
end)
-- Purchase and contract interaction are prompt-only in production. This local
-- QA RPC calls exactly those ordinary server handlers with their distance,
-- ownership and carry validations. Management/restoration use their real RFs.
qaRequest.OnServerInvoke = function(player, action, id)
	if not curses or (player ~= owner and player ~= observer) then return {ok = false, message = 'QA not ready'} end
	if typeof(id) ~= 'string' or #id > 80 then return {ok = false, message = 'Invalid QA argument'} end
	if action == 'purchase' then return {ok = curses:purchase(player, id)}
	elseif action == 'contract_interact' then
		local ok, message = contracts:interact(player, id)
		return {ok = ok, message = message}
	end
	return {ok = false, message = 'Unknown QA action'}
end

task.spawn(function()
	local ok, failure = xpcall(function()
		status('BOOT', 'Start native Test with exactly 2 Players. The release project contains no QA code.')
		map = require(script.Map.Build).build()
		profiles = require(script.Gameplay.ProfileStore).start()
		souls = require(script.Gameplay.SoulsService).start(profiles)
		bases = require(script.Gameplay.BaseService).start(map)
		sanctuary = require(script.Gameplay.SanctuaryService).start(map, bases, souls, profiles)
		carry = require(script.Gameplay.CarryService).start(map)
		curses = require(script.Gameplay.CurseService).start(map, bases, souls, profiles)
		contracts = require(script.Gameplay.ContractService).start(map, bases, profiles, souls, carry,
			function(p) sanctuary:changed(p) end, function(p, page) sanctuary:open(p, page) end)
		local rituals = require(script.Gameplay.RitualService).start(map, bases, profiles, curses, carry, souls,
			function(p) sanctuary:changed(p) end)
		sanctuary:attach(curses, contracts, rituals)
		require(script.Gameplay.CurseProcessionService).start(map, curses)
		local Catalog = require(RS.Shared.CurseCatalog)
		local Motion = require(RS.Shared.CurseMotionMath)
		local Config = require(script.Gameplay.Config)
		local Restoration = require(RS.Shared.SanctuaryConfig)
		local Progression = require(RS.Shared.SanctuaryProgression)
		check(await(function()
			local list = Players:GetPlayers()
			if #list ~= 2 then return false end
			for _, p in list do
				if not ready[p] or p:GetAttribute('ProfileStatus') ~= 'READY' or not rootOf(p) then return false end
			end
			return true
		end, 120), 'two actual native clients, loaded profiles and characters')
		local list = Players:GetPlayers()
		table.sort(list, function(a, b) return a.Name < b.Name end)
		owner, observer = list[1], list[2]
		control:SetAttribute('OwnerUserId', owner.UserId)
		control:SetAttribute('ObserverUserId', observer.UserId)
		local ownBase, otherBase = bases:getBaseById('Base03'), bases:getBaseById('Base04')
		local assignments = {{player = owner, base = ownBase, level = 10}, {player = observer, base = otherBase, level = 2}}
		for _, a in assignments do
			local p = profiles:get(a.player)
			check(p and p.sanctuary.level == 0 and #p.curses == 0 and not bases:getBaseForPlayer(a.player),
				'fresh isolated account before QA seed: ' .. a.player.Name)
			local before = Progression.snapshot(p.sanctuary)
			p.sanctuary.level, p.sanctuary.style, p.sanctuary.fragments = a.level, 'CRYPT', 1000
			p.souls = 1000000
			souls:refresh(a.player)
			profiles:commit(a.player)
			sanctuary:changed(a.player)
			table.insert(seeds, {player = a.player.Name, userId = a.player.UserId, before = before,
				level = a.level, souls = p.souls, fragments = p.sanctuary.fragments,
				discoveriesSeeded = false, cursesSeeded = false, kind = 'EXPLICIT_QA_LEVEL_AND_RESOURCES_NOT_GAMEPLAY_PROGRESSION'})
			publish('SeedsJSON', seeds)
			client(a.player, 'role', {role = if a.player == owner then 'OWNER' else 'OBSERVER', base = a.base.Name})
			near(a.player, a.base.ClaimMarker)
		end
		status('WAIT_NATIVE_CLAIMS', 'Player1: E on Sanctuary 03; Player2: E on Sanctuary 04. Both arm native videos. Player1 clicks Start after both claims.')
		check(await(function()
			return bases:getBaseForPlayer(owner) == ownBase and bases:getBaseForPlayer(observer) == otherBase and startRequested
		end, 180), 'both native E claims and explicit owner Start')
		check(ownBase:GetAttribute('RestorationLevel') == 10 and #bases:getSlots(ownBase) == 30
			and otherBase:GetAttribute('RestorationLevel') == 2 and #bases:getSlots(otherBase) == 8,
			'different seeded stages construct correctly on actual claims')
		local ownFrame, otherFrame = ownBase:GetAttribute('SanctuaryFrame'), otherBase:GetAttribute('SanctuaryFrame')
		local ownSlots, otherSlots = bases:getPedestals(ownBase), bases:getPedestals(otherBase)
		check(ownSlots['floor1-slot1'] ~= otherSlots['floor1-slot1']
			and ownSlots['floor3-slot10']:GetAttribute('PedestalBaseId') == ownBase.Name,
			'stable logical IDs are independently scoped to each owner/base')
		local ownedSeeds = {}
		local function acquire(player, base, id, slotId)
			local frame = base:GetAttribute('SanctuaryFrame')
			pose(player, frame * CFrame.new(0, 4, 4))
			local uid = curses:spawn(id, rootOf(player).CFrame * CFrame.new(0, 0, -4))
			near(player, activeModel(uid).PrimaryPart)
			task.wait(.35)
			check(client(player, 'purchase', {uid = uid}).ok, id .. ' production purchase: ' .. player.Name)
			near(player, bases:getPedestals(base)[slotId])
			check(client(player, 'manage', {action = 'place', uid = uid, pedestalId = slotId}).ok,
				id .. ' legitimate production placement: ' .. player.Name)
			check(profiles:get(player).sanctuary.discoveries[id] and curses:getState(uid) == 'PLACED',
				id .. ' discovery comes from actual placement, not QA inventory data')
			return uid
		end
		status('ACQUIRE_REAL_COLLECTIONS', 'Buying and physically placing 3 production Curses per account; no invented inventory records.')
		for index, id in {'grave_hopper', 'nail_beetle', 'coin_crawler'} do
			table.insert(ownedSeeds, {player = owner, id = id, uid = acquire(owner, ownBase, id, 'floor1-slot' .. index)})
		end
		for index, id in {'cursed_doll', 'haunted_mirror', 'crying_mask'} do
			table.insert(ownedSeeds, {player = observer, id = id, uid = acquire(observer, otherBase, id, 'floor1-slot' .. index)})
		end
		local seedModels = {}
		for _, item in ownedSeeds do seedModels[item.uid] = activeModel(item.uid) end
		local protectedUid, observerUid = ownedSeeds[1].uid, ownedSeeds[4].uid

		-- Actual ordinary RF requests by the foreign client, not server impersonation.
		status('OWNERSHIP_RULES', 'Foreign management and placement requests use the normal production remote functions.')
		near(observer, activeModel(protectedUid).PrimaryPart)
		for _, action in {'pickup', 'quote', 'sell', 'place'} do
			check(not client(observer, 'manage', {action = action, uid = protectedUid,
				pedestalId = 'floor1-slot4', token = 'foreign-token'}).ok, 'observer denied owner Curse action: ' .. action)
		end
		check(curses:getState(protectedUid) == 'PLACED' and ownSlots['floor1-slot1']:GetAttribute('OccupiedCurseUid') == protectedUid,
			'foreign requests preserve the exact owner instance and pedestal')
		check(not client(observer, 'sanctuary', {action = 'seal', value = ownBase.Name}).ok
			and (ownBase:GetAttribute('SealEndsAt') or 0) == 0, 'observer cannot activate owner protection; own level 2 remains locked')
		near(observer, activeModel(observerUid).PrimaryPart)
		check(client(observer, 'manage', {action = 'pickup', uid = observerUid}).ok, 'observer legitimately carries own Curse')
		near(observer, ownSlots['floor1-slot4'])
		check(not client(observer, 'manage', {action = 'place', uid = observerUid, pedestalId = 'floor1-slot4'}).ok
			and not ownSlots['floor1-slot4']:GetAttribute('OccupiedCurseUid'), 'same logical slot ID cannot place onto a foreign sanctuary')
		near(observer, otherSlots['floor1-slot4'])
		check(client(observer, 'manage', {action = 'place', uid = observerUid, pedestalId = 'floor1-slot4'}).ok,
			'observer manual placement on own free destination resumes correctly')

		local function pairedObservation(args)
			args.startAt = workspace:GetServerTimeNow() + .3
			local a, b = dispatch(owner, 'observe', args), dispatch(observer, 'observe', args)
			local one, two = receive(a, args.stage, args.duration + 20), receive(b, args.stage, args.duration + 20)
			for _, view in {one, two} do
				check(view.uid == args.uid and view.kind == args.kind, args.stage .. ' shared identity on ' .. view.role)
				if args.absent then check(not view.modelExists, args.stage .. ' removal on ' .. view.role)
				elseif args.kind == 'CURSE' then
					check(view.meshId == Catalog.Definitions[args.id].meshId and view.boneCount > 0
						and view.state == args.state, args.stage .. ' real imported rig/state on ' .. view.role)
					check(view.ownerUserId == (if args.state == 'PROCESSION' then nil else owner.UserId),
						args.stage .. ' shared authoritative owner on ' .. view.role)
					if args.state == 'CARRYING' then check(view.carrierUserId == owner.UserId, args.stage .. ' shared carrier on ' .. view.role) end
				else
					check(view.carrierUserId == owner.UserId and view.partCount == 4 and view.relicHook,
						args.stage .. ' ordinary visible relic and preserved anchor on ' .. view.role)
				end
			end
			table.insert(observations, {stage = args.stage, id = args.id, uid = args.uid, kind = args.kind,
				owner = one, observer = two, serverTime = workspace:GetServerTimeNow(),
				serverPosition = if args.kind == 'CURSE' and activeModel(args.uid) then list3(activeModel(args.uid).PrimaryPart.Position)
					else if carry:get(owner) then list3(carry:get(owner).model.PrimaryPart.Position) else nil,
				pixelApproval = 'PENDING_NATIVE_CLIP_REVIEW_BY_COORDINATOR'})
			publish('ObservationsJSON', observations)
		end
		local function walk(player, frame, targetLocal, duration, label, disableBarrier)
			local samples = {}
			local sampling = true
			local key = dispatch(player, 'walk', {target = frame:PointToWorldSpace(targetLocal), duration = duration,
				barrier = disableBarrier, frame = frame, stage = label})
			task.spawn(function()
				while sampling and map.Parent do
					local root = rootOf(player)
					if root then table.insert(samples, {t = workspace:GetServerTimeNow(), world = list3(root.Position),
						localPosition = list3(frame:PointToObjectSpace(root.Position))}) end
					task.wait(.05)
				end
			end)
			return key, function()
				local answer = receive(key, label, duration + 15)
				sampling = false
				table.insert(positions, {player = player.Name, role = if player == owner then 'OWNER' else 'OBSERVER',
					stage = label, serverSamples = samples, client = answer})
				publish('PositionsJSON', positions)
				return answer, frame:PointToObjectSpace(rootOf(player).Position)
			end
		end
		local function capture(label, uid, id, kind)
			control:SetAttribute('LastCaseStartedAt', workspace:GetServerTimeNow())
			control:FireAllClients('capture', 'captureCase', {uid = uid, id = id, kind = kind or 'CURSE', label = label})
		end

		-- Protection uses real elapsed server time; no shortened duration or fake clock.
		status('SEAL_OWNER_ACCESS', 'Real 40-second closure, real 60-second vulnerability; native avatar movement through the entrance.')
		near(owner, ownBase.RestorationAltar)
		check(client(owner, 'sanctuary', {action = 'seal'}).ok, 'owner activates actual level 10 seal')
		local seal = sanctuary:snapshot(owner).seal
		local barrier = ownBase.SealBarrier
		check(barrier.CanCollide and barrier:FindFirstChild('OwnerSealAccess') ~= nil
			and math.abs(seal.availableAt - seal.endsAt - 60) < .001, 'server barrier and owner exemptions; 60-second vulnerability begins after closure')
		check(seal.endsAt - workspace:GetServerTimeNow() > 39, 'actual 40-second duration has not been replaced with a QA shortcut')
		capture('PROTECTION_40S_AND_ACCESS', nil, 'protective_seal', 'BASE')
		client(owner, 'focusBase', {frame = ownFrame})
		client(observer, 'focusBase', {frame = ownFrame})
		pose(owner, ownFrame * CFrame.new(0, 4, -44))
		local _, ownerWalk = walk(owner, ownFrame, Vector3.new(0, 4, -23), 2.6, 'OWNER_ENTERS_CLOSED_GATE')
		local walked, ownerPoint = ownerWalk()
		check(walked.distance > 8 and ownerPoint.Z > -30, 'owner physically enters closed entrance without being trapped', ownerPoint.Z)
		local _, ownerExit = walk(owner, ownFrame, Vector3.new(0, 4, -44), 2.6, 'OWNER_EXITS_CLOSED_GATE')
		local exited, exitPoint = ownerExit()
		check(exited.distance > 8 and exitPoint.Z < -37, 'owner physically exits while the same seal remains active', exitPoint.Z)
		pose(observer, ownFrame * CFrame.new(0, 4, -44))
		local _, foreignWalk = walk(observer, ownFrame, Vector3.new(0, 4, -23), 2.6, 'FOREIGN_NORMAL_GATE_APPROACH')
		local foreign, foreignPoint = foreignWalk()
		check(foreign.distance > 1 and foreignPoint.Z <= -36 and barrier.CanCollide,
			'foreign physical approach cannot remain in closed territory', foreignPoint.Z)
		pose(observer, ownFrame * CFrame.new(0, 4, -44))
		local noticeSerial = observer:GetAttribute('HUDNoticeSerial') or 0
		local _, bypassWalk = walk(observer, ownFrame, Vector3.new(0, 4, -23), 3.2, 'FOREIGN_LOCAL_COLLISION_DISABLED', barrier)
		local bypass, bypassPoint = bypassWalk()
		check(bypass.localCollisionDisabled == true and barrier.CanCollide and bypassPoint.Z <= -36
			and (observer:GetAttribute('HUDNoticeSerial') or 0) > noticeSerial,
			'local CanCollide=false attempt is expelled by server boundary guard', bypassPoint.Z)
		near(owner, ownBase.RestorationAltar)
		check(not client(owner, 'sanctuary', {action = 'seal'}).ok
			and sanctuary:snapshot(owner).seal.availableAt == seal.availableAt, 'repeated activation cannot extend active closure')
		local observerDecor = otherBase.RestorationDecor
		local beforeIncome = owner:GetAttribute('SoulsPerSecond')
		for _, style in Restoration.StyleOrder do
			check(client(owner, 'sanctuary', {action = 'style', value = style}).ok, 'real owner style switch: ' .. style)
			local current = bases:getPedestals(ownBase)
			for id, marker in ownSlots do check(current[id] == marker, style .. ' stable owner pedestal ' .. id) end
			for _, item in ownedSeeds do check(activeModel(item.uid) == seedModels[item.uid], style .. ' same real owned instance ' .. item.id .. ' / ' .. item.player.Name) end
			check(otherBase.RestorationDecor == observerDecor and otherBase:GetAttribute('SanctuaryStyle') == 'CRYPT'
				and #bases:getSlots(otherBase) == 8, style .. ' observer base remains intact at level 2')
			check(ownBase.SealBarrier == barrier and barrier.CanCollide
				and owner:GetAttribute('SoulsPerSecond') == beforeIncome, style .. ' active seal and production survive decorative rebuild')
		end
		status('WAIT_REAL_SEAL_EXPIRY', 'Waiting for actual duration; no server-time override.')
		check(await(function() return not barrier.CanCollide end, math.max(1, seal.endsAt - workspace:GetServerTimeNow() + 3)),
			'actual seal expires and removes physical closure')
		local expiredAt = workspace:GetServerTimeNow()
		check(expiredAt >= seal.endsAt and expiredAt - seal.endsAt < 1.5
			and not barrier:FindFirstChild('OwnerSealAccess'), 'closure expires on server schedule and owner collision links are cleaned', expiredAt - seal.endsAt)
		near(owner, ownBase.RestorationAltar)
		check(not client(owner, 'sanctuary', {action = 'seal'}).ok, 'cannot reactivate immediately after expiry')
		pose(observer, ownFrame * CFrame.new(0, 4, -44))
		local _, vulnerableWalk = walk(observer, ownFrame, Vector3.new(0, 4, -23), 2.6, 'FOREIGN_ENTERS_DURING_VULNERABILITY')
		local vulnerable, vulnerablePoint = vulnerableWalk()
		check(vulnerable.distance > 8 and vulnerablePoint.Z > -30, 'foreign client physically enters during vulnerability window', vulnerablePoint.Z)
		pose(observer, otherFrame * CFrame.new(0, 4, 4))
		status('WAIT_REAL_VULNERABILITY', 'Waiting remaining 60-second recovery window; repeated requests cannot shorten it.')
		check(await(function() return workspace:GetServerTimeNow() >= seal.availableAt - 1.2 end, 65), 'real 60-second vulnerability approaches completion')
		near(owner, ownBase.RestorationAltar)
		if workspace:GetServerTimeNow() < seal.availableAt then
			check(not client(owner, 'sanctuary', {action = 'seal'}).ok, 'reactivation still denied just before recovery deadline')
		end
		check(await(function() return workspace:GetServerTimeNow() >= seal.availableAt end, 3), 'actual recovery deadline elapsed')
		check(client(owner, 'sanctuary', {action = 'seal'}).ok, 'reactivation works only after full vulnerability period')

		status('SHARED_RELIC_CARRY', 'Real contract relic follows owner on both clients; reward only after validated delivery.')
		near(owner, contracts:getNode(owner, 'gravekeeper_board'))
		check(client(owner, 'sanctuary', {action = 'contract_accept', value = 'lost_seal'}).ok, 'real client accepts ordinary recovery contract')
		near(owner, contracts:getNode(owner, 'cemetery_gate'))
		check(client(owner, 'contract', {nodeId = 'cemetery_gate'}).ok, 'ordinary contract handler picks up physical relic')
		local token = carry:get(owner).token
		local oldFragments = profiles:get(owner).sanctuary.fragments
		capture('SHARED_CONTRACT_RELIC', token, 'contract_relic', 'RELIC')
		pose(owner, ownFrame * CFrame.new(0, 4, 4))
		near(owner, activeModel(protectedUid).PrimaryPart)
		check(not client(owner, 'manage', {action = 'pickup', uid = protectedUid}).ok,
			'relic carrier cannot simultaneously pick up own Curse')
		check(not client(observer, 'contract', {nodeId = 'sanctuary_altar'}).ok,
			'observer cannot deliver owner relic through own contract context')
		pose(owner, ownFrame * CFrame.new(0, 4, 4))
		local _, relicWalk = walk(owner, ownFrame, Vector3.new(8, 4, 25), 3.4, 'RELIC_SHARED_WALK')
		pairedObservation({kind = 'RELIC', uid = token, id = 'contract_relic', stage = 'RELIC_CARRYING', duration = 3.4})
		check(relicWalk().distance > 3, 'relic presentation observed while owner actually walks')
		near(owner, ownBase.RestorationAltar)
		check(client(owner, 'contract', {nodeId = 'sanctuary_altar'}).ok
			and profiles:get(owner).sanctuary.fragments == oldFragments + 4, 'valid physical contract delivery rewards once')
		check(not client(owner, 'contract', {nodeId = 'sanctuary_altar'}).ok
			and profiles:get(owner).sanctuary.fragments == oldFragments + 4, 'duplicate ordinary client delivery cannot reward twice')
		pairedObservation({kind = 'RELIC', uid = token, id = 'contract_relic', stage = 'RELIC_REMOVED', duration = 1, absent = true})
		check(not carry:get(owner) and not owner:GetAttribute('CarriedRelicUid'), 'delivery cleans shared carry state and runtime model')
		-- Avoid overlapping native CaptureService clips: each recording lasts 30 s.
		local captureEnd = control:GetAttribute('LastCaseStartedAt')
		if captureEnd then task.wait(math.max(0, captureEnd + 32.5 - workspace:GetServerTimeNow())) else task.wait(24) end

		local route = map.CurseProcessionRoute
		local points, lengths = {}, {}
		for i = 1, route:GetAttribute('PointCount') do points[i] = route[string.format('Point_%02d', i)].Value end
		for i = 1, #points - 1 do lengths[i] = (points[i + 1] - points[i]).Magnitude end
		-- The other original actors already have valid native single-client clips.
		-- Six representative cases avoid repeating that existing evidence.
		local caseIds = {'cursed_doll', 'watching_eye', 'soul_chains', 'grave_hopper', 'nail_beetle', 'coin_crawler'}
		for index, id in caseIds do
			control:SetAttribute('CaseIndex', index)
			control:SetAttribute('FocusId', id)
			local uid = curses:spawn(id, Motion.route(points, lengths, 0))
			control:SetAttribute('FocusUid', uid)
			local epoch = workspace:GetServerTimeNow()
			curses:setProcessionMotion(uid, epoch, Config.ProcessionSpeedStudsPerSecond, index)
			local routeActive = true
			task.spawn(function()
				local endAt = os.clock() + 40
				while routeActive and os.clock() < endAt and curses:getState(uid) == 'PROCESSION' do
					curses:moveProcession(uid, Motion.route(points, lengths,
						(workspace:GetServerTimeNow() - epoch) * Config.ProcessionSpeedStudsPerSecond))
					task.wait(Config.ProcessionStepSeconds)
				end
			end)
			local a, b = dispatch(owner, 'readyMesh', {uid = uid, id = id}), dispatch(observer, 'readyMesh', {uid = uid, id = id})
			receive(a, id .. ' owner ordinary mesh readiness', 20)
			receive(b, id .. ' observer ordinary mesh readiness', 20)
			local caseStart = workspace:GetServerTimeNow()
			control:SetAttribute('LastCaseStartedAt', caseStart)
			capture(string.format('CASE_%02d_%s', index, id), uid, id)
			status('CURSE_ROUTE', index .. '/' .. #caseIds .. ' ' .. id .. ' · both clients see the same production instance; inspect native pixels.')
			pairedObservation({kind = 'CURSE', uid = uid, id = id, state = 'PROCESSION', stage = id .. '/PROCESSION', duration = 4.2})
			routeActive = false
			near(owner, activeModel(uid).PrimaryPart)
			check(client(owner, 'purchase', {uid = uid}).ok, id .. ' actual nearby client purchase')
			status('CURSE_CARRY', id .. ' · normal carried follow and anatomy; walking/turning/stopping on both clients.')
			pose(owner, ownFrame * CFrame.new(0, 4, 4))
			local _, carriedWalk = walk(owner, ownFrame, Vector3.new(8, 4, 27), 4.2, id .. '/CARRY_WALK')
			pairedObservation({kind = 'CURSE', uid = uid, id = id, state = 'CARRYING', stage = id .. '/CARRYING', duration = 4.2})
			check(carriedWalk().distance > 3, id .. ' avatar actually walks while carried')
			near(owner, ownSlots['floor1-slot4'])
			check(client(owner, 'manage', {action = 'place', uid = uid, pedestalId = 'floor1-slot4'}).ok, id .. ' normal client placement')
			status('CURSE_PLACED', id .. ' · actual income-producing pedestal instance, not a gallery copy.')
			pairedObservation({kind = 'CURSE', uid = uid, id = id, state = 'PLACED', stage = id .. '/PLACED', duration = 5.2})
			check(client(owner, 'manage', {action = 'pickup', uid = uid}).ok, id .. ' normal client pickup for manual relocation')
			pose(owner, ownFrame * CFrame.new(0, 4, 4))
			local _, relocationWalk = walk(owner, ownFrame, Vector3.new(-7, 4, 23), 3.2, id .. '/RELOCATION_WALK')
			pairedObservation({kind = 'CURSE', uid = uid, id = id, state = 'CARRYING', stage = id .. '/RELOCATION', duration = 3.2})
			check(relocationWalk().distance > 3, id .. ' relocated load physically accompanies moving owner')
			near(owner, ownSlots['floor2-slot1'])
			check(client(owner, 'manage', {action = 'place', uid = uid, pedestalId = 'floor2-slot1'}).ok, id .. ' logical upper-floor manual placement')
			pairedObservation({kind = 'CURSE', uid = uid, id = id, state = 'PLACED', stage = id .. '/UPPER_FLOOR', duration = 4.5})
			near(owner, activeModel(uid).PrimaryPart)
			local quote = client(owner, 'manage', {action = 'quote', uid = uid})
			check(quote.ok and quote.data.sale == math.floor(Catalog.Definitions[id].price * .5), id .. ' real 50% quote')
			check(client(owner, 'manage', {action = 'sell', uid = uid, token = quote.data.token}).ok, id .. ' real client sale cleans review instance')
			check(not client(owner, 'manage', {action = 'sell', uid = uid, token = quote.data.token}).ok, id .. ' stale sale cannot pay again')
			pairedObservation({kind = 'CURSE', uid = uid, id = id, state = 'SOLD', stage = id .. '/REMOVED', duration = 1, absent = true})
			check(not ownSlots['floor1-slot4']:GetAttribute('OccupiedCurseUid') and not ownSlots['floor2-slot1']:GetAttribute('OccupiedCurseUid'),
				id .. ' temporary review pedestal occupancy cleaned')
			task.wait(math.max(0, caseStart + 32.5 - workspace:GetServerTimeNow()))
		end
		for _, item in ownedSeeds do check(activeModel(item.uid) == seedModels[item.uid] and curses:getState(item.uid) == 'PLACED',
			'original real collection remains intact: ' .. item.id .. '/' .. item.player.Name) end
		for _, player in {owner, observer} do check(profiles:flush(player, false), 'actual isolated profile journal acknowledged: ' .. player.Name) end
		publish('SummaryJSON', {status = 'PASS', assertions = #checks, cases = caseIds,
			elapsedSeconds = os.clock() - started, owner = owner.Name, observer = observer.Name,
			ownerLevel = 10, observerLevel = 2, seedDisclosure = seeds,
			pixelApproval = 'PENDING_NATIVE_CLIP_REVIEW', physicalPhone = 'NOT_TESTED', robbery = 'NOT_ASSERTED',
			scope = 'Two actual native clients; real RF management/restoration, QA RPC forwarding prompt-only purchase/contract handlers. Setup positions teleported; labelled walking sections use Humanoid movement. No mesh/bone/VFX writes.'})
		control:SetAttribute('GeometryReview', 'PENDING_COORDINATOR_NATIVE_PIXEL_REVIEW')
		status('PASS', 'Two-client server rules and observations passed. Native clips still need geometry review; QA seeds are disclosed separately.')
		control:FireAllClients('done', 'finish', {})
	end, debug.traceback)
	if not ok then
		status('FAILED', tostring(failure))
		control:SetAttribute('Failure', tostring(failure))
		warn('SANCTUARY_MP_FAILED', failure)
		control:FireAllClients('failed', 'finish', {})
	end
end)
