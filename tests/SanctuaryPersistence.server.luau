-- Local native QA only. A genuine schema-1 legacy shape is seeded exactly once
-- in an isolated plugin namespace; existing durable profiles are never replaced.
-- Reopen/replay this same file to exercise migration of a physically carried
-- contract and manual Curse recovery after assignment to a different base.
local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local Storage = game:GetService('ServerStorage')
local Http = game:GetService('HttpService')
local Run = game:GetService('RunService')
assert(Run:IsStudio(), 'Persistence fixture is local Studio QA only')
local evidence = Instance.new('Folder')
evidence.Name = 'SanctuaryPersistenceReview'
evidence.Parent = RS
local rows = {}
local player, statusLabel
local DOLL_UID, GRAVE_UID = 'qa-legacy-sanctuary-doll', 'qa-legacy-sanctuary-grave'
local function jsonAttribute(name, value) evidence:SetAttribute(name, Http:JSONEncode(value)) end
local function status(stage, message)
	evidence:SetAttribute('Stage', stage)
	evidence:SetAttribute('Message', message)
	if statusLabel then statusLabel.Text = stage .. ' · ' .. message end
	print('SANCTUARY_PERSISTENCE_STAGE', stage, message)
end
local function check(ok, label, detail)
	local passed = not not ok
	table.insert(rows, {ok = passed, label = label, detail = detail,
		serverTime = workspace:GetServerTimeNow()})
	jsonAttribute('ResultsJSON', rows)
	assert(passed, label .. ': ' .. tostring(detail))
	print('SANCTUARY_PERSISTENCE_PASS', label)
end
local function await(fn, seconds)
	local ends = os.clock() + seconds
	repeat if fn() then return true end; task.wait(.05) until os.clock() >= ends
	return false
end
local function savedCurse(profile, uid)
	for _, curse in profile.curses do if curse.uid == uid then return curse end end
end

task.spawn(function()
	local ok, failure = xpcall(function()
		status('BOOT', 'Local plugin migration/reload QA; use this same file and namespace for both Plays.')
		local map = require(script.Map.Build).build()
		check(await(function() return #Players:GetPlayers() == 1 end, 90), 'exactly one actual native Studio player')
		player = Players:GetPlayers()[1]
		local gui = Instance.new('ScreenGui')
		gui.Name, gui.ResetOnSpawn, gui.DisplayOrder = 'SanctuaryPersistenceStatus', false, 155
		gui.Parent = player:WaitForChild('PlayerGui')
		statusLabel = Instance.new('TextLabel')
		statusLabel.Name, statusLabel.TextWrapped, statusLabel.TextSize = 'Status', true, 14
		statusLabel.Font = Enum.Font.Gotham
		statusLabel.BackgroundColor3, statusLabel.TextColor3 = Color3.fromRGB(20, 24, 36), Color3.new(1, 1, 1)
		statusLabel.BackgroundTransparency = .12
		statusLabel.Size, statusLabel.Position = UDim2.new(1, -24, 0, 70), UDim2.new(0, 12, 1, -86)
		statusLabel.Parent = gui
		local bridge = Storage:WaitForChild('LocalProfileBridge', 20)
		check(bridge and typeof(bridge:GetAttribute('Namespace')) == 'string'
			and bridge:GetAttribute('Namespace'):match('^qa%-sanctuary%-persistence%-') ~= nil,
			'explicit isolated QA namespace; normal playable accounts cannot be seeded')
		evidence:SetAttribute('Namespace', bridge:GetAttribute('Namespace'))
		check(await(function() return bridge:GetAttribute('Ready') and bridge:FindFirstChild('Seed') and bridge:FindFirstChild('Journal') end, 20),
			'installed local plugin bridge ready before ProfileStore starts')
		check(bridge:GetAttribute('Provider') == 'PluginSettings', 'actual installed plugin persistence provider')
		local stored = Http:JSONDecode(bridge.Seed.Value)
		check(typeof(stored) == 'table', 'readable local seed; malformed data is preserved on failure')
		local key = 'u' .. tostring(player.UserId)
		local before = stored[key]
		local seeded = false
		if before == nil then
			-- These are the actual old profile fields: no sanctuary/new progress data.
			-- This is explicit QA setup, not ownership earned by a real player.
			before = {schema = 1, souls = 1234, revision = 1,
				savedAt = workspace:GetServerTimeNow(), session = Http:GenerateGUID(false),
				curses = {
					{uid = DOLL_UID, definitionId = 'cursed_doll', state = 'PLACED', pedestalId = 'floor1-slot1', revision = 0},
					{uid = GRAVE_UID, definitionId = 'grave_hopper', state = 'UNPLACED', revision = 0},
				}}
			local journal = bridge.Journal:FindFirstChild(key)
			if not journal then journal = Instance.new('StringValue'); journal.Name = key; journal.Parent = bridge.Journal end
			journal.Value = Http:JSONEncode(before)
			check(await(function() return (journal:GetAttribute('SavedRevision') or -1) >= before.revision end, 8),
				'legacy QA seed durably read back by installed plugin', journal:GetAttribute('SaveError'))
			check(not journal:GetAttribute('SaveError'), 'legacy seed has no plugin save error')
			stored[key] = before
			-- Play's plugin refreshes Seed only on the next Edit/Play lifecycle.
			-- Supply its acknowledged journal value before the real loader starts.
			bridge.Seed.Value = Http:JSONEncode(stored)
			seeded = true
			jsonAttribute('LegacySeedJSON', {kind = 'EXPLICIT_QA_LEGACY_PROFILE_NOT_PLAYER_ACHIEVEMENT',
				profile = before, revisionAcknowledged = journal:GetAttribute('SavedRevision')})
		else
			jsonAttribute('ExistingSeedJSON', before)
			check(typeof(before) == 'table' and before.schema == 1 and typeof(before.curses) == 'table'
				and #before.curses == 2 and savedCurse(before, DOLL_UID) and savedCurse(before, GRAVE_UID),
				'existing isolated profile recognized and retained without replacement')
		end
		local oldShape = before.sanctuary == nil
		local wasPending = before.sanctuary and before.sanctuary.contract ~= nil
		local completed = before.sanctuary and before.sanctuary.milestones.contracts == 1
			and before.sanctuary.fragments == 4 and before.sanctuary.contract == nil
		local originalSouls = before.souls
		local originalToken = wasPending and before.sanctuary.contract.token
		check(oldShape or wasPending or completed or (before.sanctuary and before.sanctuary.level == 0
			and before.sanctuary.milestones.contracts == 0), 'known fixture checkpoint; unknown valid data is not reset')

		-- Same production boot order as release, after the acknowledged legacy seed.
		local profiles = require(script.Gameplay.ProfileStore).start()
		local souls = require(script.Gameplay.SoulsService).start(profiles)
		local bases = require(script.Gameplay.BaseService).start(map)
		local sanctuary = require(script.Gameplay.SanctuaryService).start(map, bases, souls, profiles)
		local carry = require(script.Gameplay.CarryService).start(map)
		local curses = require(script.Gameplay.CurseService).start(map, bases, souls, profiles)
		local contracts = require(script.Gameplay.ContractService).start(map, bases, profiles, souls, carry,
			function(p) sanctuary:changed(p) end, function(p, page) sanctuary:open(p, page) end)
		local rituals = require(script.Gameplay.RitualService).start(map, bases, profiles, curses, carry, souls,
			function(p) sanctuary:changed(p) end)
		sanctuary:attach(curses, contracts, rituals)
		require(script.Gameplay.CurseProcessionService).start(map, curses)
		local Catalog = require(RS.Shared.CurseCatalog)
		local Progression = require(RS.Shared.SanctuaryProgression)
		check(await(function() return player:GetAttribute('ProfileStatus') == 'READY'
			and player.Character and player.Character:FindFirstChild('HumanoidRootPart') end, 40), 'actual old/checkpoint profile loaded by production ProfileStore')
		local p = profiles:get(player)
		check(p.souls == originalSouls and #p.curses == 2, 'loader preserves exact stored Souls and owned count before claim', p.souls)
		check(p.sanctuary.level == 0 and p.sanctuary.style == 'CRYPT'
			and p.sanctuary.discoveries.cursed_doll and p.sanctuary.discoveries.grave_hopper
			and Progression.discoveryCount(p.sanctuary) == 2, 'legacy placed and recoverable owned species grandfathered once')
		check(savedCurse(p, DOLL_UID).definitionId == 'cursed_doll'
			and savedCurse(p, GRAVE_UID).definitionId == 'grave_hopper', 'stable owned UIDs and species retained through migration')
		if oldShape then check(player:GetAttribute('ProfileMigrationStatus') == 'UPGRADED', 'old shape marked as actual migration') end
		jsonAttribute('LoadedJSON', p)
		local base = bases:getBaseById(if wasPending or completed then 'Base04' else 'Base03')
		local function pose(frame)
			player.Character:PivotTo(frame)
			player.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
			task.wait(.25)
		end
		local function near(marker)
			check(marker and marker.Parent, 'real reachable QA target exists')
			pose(marker.CFrame * CFrame.new(0, 1, -3))
		end
		local function model(uid)
			for _, m in map.ActiveCurses:GetChildren() do if m:GetAttribute('CurseUid') == uid then return m end end
		end
		local function acknowledgedSnapshot(attribute)
			profiles:commit(player)
			local value = bridge.Journal:FindFirstChild(key)
			local raw, revision = value.Value, p.revision
			check(profiles:flush(player, false), 'actual local journal flush acknowledged: ' .. attribute)
			check((value:GetAttribute('SavedRevision') or -1) >= revision and not value:GetAttribute('SaveError'),
				'plugin acknowledges exact requested revision: ' .. attribute, revision)
			evidence:SetAttribute(attribute, raw)
			evidence:SetAttribute(attribute .. 'Revision', revision)
			return Http:JSONDecode(raw)
		end
		if wasPending then
			check(p.sanctuary.contract.id == 'lost_seal' and p.sanctuary.contract.token == originalToken
				and p.sanctuary.contract.phase == 'RECOVERABLE' and p.sanctuary.contract.step == 0,
				'pending contract reload becomes physically recoverable with same token and reset target')
			check(p.sanctuary.fragments == 0 and p.sanctuary.milestones.contracts == 0
				and not carry:get(player) and not player:GetAttribute('CarriedRelicUid'), 'reload grants no reward or invisible carried relic')
			check(savedCurse(p, GRAVE_UID).state == 'UNPLACED' and not savedCurse(p, GRAVE_UID).pedestalId
				and (player:GetAttribute('SoulsPerSecond') or 0) == 0, 'saved unplaced Curse remains unplaced; no production before native claim')
		end
		near(base.ClaimMarker)
		status('WAIT_NATIVE_CLAIM', 'Presiona E para reclamar ' .. base.Name .. '. La arquitectura se restaura desde el perfil guardado.')
		check(await(function() return bases:getBaseForPlayer(player) == base end, 180), 'native E claim: ' .. base.Name)
		local slots = bases:getPedestals(base)
		check(#bases:getSlots(base) == 5 and base:GetAttribute('RestorationLevel') == 0, 'legacy default restoration retains five actual pedestals')
		check(slots['floor1-slot1']:GetAttribute('OccupiedCurseUid') == DOLL_UID
			and model(DOLL_UID) and curses:getState(DOLL_UID) == 'PLACED', 'legacy logical slot restores same real Doll UID on current assigned base')
		check(model(DOLL_UID).CurseMesh.MeshId == Catalog.Definitions.cursed_doll.meshId
			and model(GRAVE_UID).CurseMesh.MeshId == Catalog.Definitions.grave_hopper.meshId, 'real current native assets used for both restored species')
		if wasPending then
			check(base.Name == 'Base04' and not bases:getBaseById('Base03'):GetAttribute('OwnerUserId')
				and not bases:getPedestals(bases:getBaseById('Base03'))['floor1-slot1']:GetAttribute('OccupiedCurseUid'),
				'different base assignment retains logical placement; old location is not occupied')
			check(curses:getState(GRAVE_UID) == 'UNPLACED' and not slots['floor1-slot2']:GetAttribute('OccupiedCurseUid')
				and player:GetAttribute('SoulsPerSecond') == Catalog.Definitions.cursed_doll.baseSoulsPerSecond,
				'after claim, recoverable Grave stays unplaced and earns nothing; only placed Doll produces')
		end
		local function advance()
			local requested = false
			local prompt = Instance.new('ProximityPrompt')
			prompt.Name, prompt.ActionText, prompt.ObjectText = 'PersistenceContinueQA', 'Continuar prueba', 'Migración / recarga QA'
			prompt.KeyboardKeyCode, prompt.MaxActivationDistance, prompt.HoldDuration = Enum.KeyCode.F, 10, 0
			prompt.RequiresLineOfSight = false
			prompt.Parent = base.ClaimMarker
			local link = prompt.Triggered:Connect(function(sender)
				local root = sender.Character and sender.Character:FindFirstChild('HumanoidRootPart')
				if sender == player and root and (root.Position - base.ClaimMarker.Position).Magnitude <= 13 then requested = true end
			end)
			near(base.ClaimMarker)
			status('WAIT_NATIVE_ADVANCE', 'Migración comprobada. Presiona F en este punto para continuar la prueba de recuperación.')
			local continued = await(function() return requested end, 180)
			link:Disconnect(); prompt:Destroy()
			check(continued, 'native F checkpoint advance')
		end
		if completed then
			check(#p.curses == 2 and p.sanctuary.contract == nil and p.sanctuary.fragments == 4
				and p.sanctuary.milestones.contracts == 1, 'completed durable fixture reload does not restart or repay activity')
			check(savedCurse(p, GRAVE_UID).state == 'PLACED' and savedCurse(p, GRAVE_UID).pedestalId == 'floor1-slot3',
				'completed manually recovered Grave retains destination identity')
			acknowledgedSnapshot('FinalJournalJSON')
			status('COMPLETED_RELOAD_PASS', 'Entrega y colección final recargadas sin repetir recompensas. No hay más acciones automáticas.')
			return
		end
		advance()
		if not wasPending then
			status('LEGACY_MANUAL_RECOVERY', 'Colocación real de la Curse recuperable; después se deja sin colocar mediante muerte real.')
			if curses:getState(GRAVE_UID) == 'UNPLACED' then
				near(model(GRAVE_UID).PrimaryPart)
				check(curses:action(player, 'pickup', GRAVE_UID).ok, 'old recoverable Grave requires legitimate manual pickup')
				near(slots['floor1-slot2'])
				check(curses:action(player, 'place', GRAVE_UID, 'floor1-slot2').ok, 'old recoverable Grave first legitimate placement')
			end
			check(curses:getState(GRAVE_UID) == 'PLACED' and #p.curses == 2
				and Progression.discoveryCount(p.sanctuary) == 2, 'manual placement preserves UID/count and does not inflate grandfathered discoveries')
			check(player:GetAttribute('SoulsPerSecond') == Catalog.Definitions.cursed_doll.baseSoulsPerSecond
				+ Catalog.Definitions.grave_hopper.baseSoulsPerSecond, 'real placed Grave resumes its ordinary income once')
			near(model(GRAVE_UID).PrimaryPart)
			check(curses:action(player, 'pickup', GRAVE_UID).ok, 'real pickup frees Grave pedestal before death')
			local oldCharacter = player.Character
			oldCharacter:FindFirstChildOfClass('Humanoid').Health = 0
			check(await(function()
				local c = player.Character
				local h = c and c:FindFirstChildOfClass('Humanoid')
				return c and c ~= oldCharacter and h and h.Health > 0 and c:FindFirstChild('HumanoidRootPart')
			end, 25), 'actual carried-Curse death and respawn; no mocked reset')
			check(curses:getState(GRAVE_UID) == 'UNPLACED' and not savedCurse(p, GRAVE_UID).pedestalId
				and not slots['floor1-slot2']:GetAttribute('OccupiedCurseUid')
				and player:GetAttribute('SoulsPerSecond') == Catalog.Definitions.cursed_doll.baseSoulsPerSecond,
				'actual death leaves recoverable unplaced Curse without automatic return or income')
			near(contracts:getNode(player, 'gravekeeper_board'))
			local accepted, reason = contracts:accept(player, 'lost_seal')
			check(accepted, 'ordinary recovery contract accepted after Curse load cleared', reason)
			near(contracts:getNode(player, 'cemetery_gate'))
			local picked, why = contracts:interact(player, 'cemetery_gate')
			check(picked and carry:get(player) and p.sanctuary.contract.phase == 'CARRYING'
				and p.sanctuary.contract.step == 1, 'ordinary physical relic picked; no reward before delivery', why)
			check(p.sanctuary.fragments == 0 and p.sanctuary.milestones.contracts == 0
				and #p.curses == 2 and savedCurse(p, GRAVE_UID).state == 'UNPLACED', 'pending snapshot has no payout and unchanged owned UIDs')
			local pending = acknowledgedSnapshot('PendingJournalJSON')
			check(pending.sanctuary.contract.phase == 'CARRYING' and pending.sanctuary.contract.step == 1
				and savedCurse(pending, GRAVE_UID).state == 'UNPLACED' and pending.sanctuary.fragments == 0,
				'exact acknowledged checkpoint contains pending physical relic and unplaced Grave')
			jsonAttribute('SummaryJSON', {status = 'PENDING_SAVED', seededOldShape = seeded, loadedOldShape = oldShape,
				oldSouls = originalSouls, exactAcknowledgedPendingSouls = pending.souls,
				pendingToken = pending.sanctuary.contract.token, stableUids = {DOLL_UID, GRAVE_UID},
				nextRunBase = 'Base04', persistence = 'INSTALLED_LOCAL_PLUGIN_READBACK_ONLY_NOT_ONLINE_DATASTORE',
				scope = 'QA setup positions teleport to validated real markers; production pickup/placement/carry/death/save handlers. No mesh/bone/VFX writes.'})
			status('PENDING_SAVED', 'Detén Play y vuelve a abrir este mismo archivo. La siguiente prueba reclamará Base04; la reliquia sigue pendiente, sin recompensa.')
			return
		end

		status('RELOAD_MANUAL_RECOVERY', 'Recuperación manual de reliquia pendiente; entrega válida al nuevo altar y colocación manual de la Curse.')
		near(contracts:getNode(player, 'cemetery_gate'))
		local picked, reason = contracts:interact(player, 'cemetery_gate')
		check(picked and carry:get(player) and carry:get(player).token == originalToken
			and p.sanctuary.contract.phase == 'CARRYING', 'manual relic recovery after reload preserves pending token', reason)
		near(model(GRAVE_UID).PrimaryPart)
		check(not curses:action(player, 'pickup', GRAVE_UID).ok and curses:getState(GRAVE_UID) == 'UNPLACED',
			'reloaded relic excludes simultaneous own Curse carry without placing it automatically')
		near(bases:getBaseById('Base03').RestorationAltar)
		check(not contracts:interact(player, 'sanctuary_altar') and p.sanctuary.fragments == 0,
			'old base altar cannot remotely complete new base delivery')
		near(base.RestorationAltar)
		local delivered, message = contracts:interact(player, 'sanctuary_altar')
		check(delivered and p.sanctuary.fragments == 4 and p.sanctuary.milestones.contracts == 1,
			'new assigned base receives one ordinary physical delivery reward', message)
		check(not contracts:interact(player, 'sanctuary_altar') and p.sanctuary.fragments == 4
			and p.sanctuary.milestones.contracts == 1, 'duplicate delivery after reload cannot pay again')
		check(not carry:get(player) and not player:GetAttribute('CarriedRelicUid') and p.sanctuary.contract == nil,
			'completed pending contract clears actual relic and carry state')
		near(model(GRAVE_UID).PrimaryPart)
		check(curses:action(player, 'pickup', GRAVE_UID).ok, 'unplaced Grave manually recovered after relic delivery')
		near(slots['floor1-slot3'])
		check(curses:action(player, 'place', GRAVE_UID, 'floor1-slot3').ok, 'manual new destination resumes Grave ordinary production')
		check(#p.curses == 2 and savedCurse(p, DOLL_UID).pedestalId == 'floor1-slot1'
			and savedCurse(p, GRAVE_UID).pedestalId == 'floor1-slot3'
			and Progression.discoveryCount(p.sanctuary) == 2, 'UID count, logical Doll position and unique discoveries remain unchanged')
		local final = acknowledgedSnapshot('FinalJournalJSON')
		jsonAttribute('SummaryJSON', {status = 'RELOAD_PASS', sourceStoredSouls = originalSouls,
			finalJournalSouls = final.souls, sameTokenRecovered = originalToken,
			oldBase = 'Base03', newBase = 'Base04', stableUids = {DOLL_UID, GRAVE_UID},
			fragments = 4, contractsCompleted = 1, discoveries = 2,
			persistence = 'INSTALLED_LOCAL_PLUGIN_READBACK_ONLY_NOT_ONLINE_DATASTORE',
			scope = 'First-run legacy migration, real carried-Curse death, exact pending journal, new runtime reload, different native claim, manual physical relic and Curse recovery. Setup positions teleported; no walking/online claims.'})
		status('RELOAD_PASS', 'Migración, recarga en Base04 y recuperación manual comprobadas. Dos Curses originales conservadas; una sola recompensa de 4 fragmentos.')
	end, debug.traceback)
	if not ok then
		status('FAILED', tostring(failure))
		evidence:SetAttribute('Failure', tostring(failure))
		warn('SANCTUARY_PERSISTENCE_FAILED', failure)
	end
end)
