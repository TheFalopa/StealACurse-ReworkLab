-- Studio-only integration fixture, not part of the delivered experience.
-- Calls production handlers from physically valid server positions. ctx.near/pose
-- teleport for rule coverage; they do not prove walking, touch UI or network latency.
return function(ctx)
	assert(game:GetService("RunService"):IsStudio(), "Local isolated review only")
	local Config = require(game.ReplicatedStorage.Shared.SanctuaryConfig)
	local Rules = require(game.ReplicatedStorage.Shared.SanctuaryProgression)
	local Catalog = require(game.ReplicatedStorage.Shared.CurseCatalog)
	local GameplayConfig = require(game.ServerScriptService.Server.Gameplay.Config)
	local player, profiles, bases, curses = ctx.player, ctx.profiles, ctx.bases, ctx.curses
	local contracts, rituals, sanctuary, map, souls, carry = ctx.contracts, ctx.rituals, ctx.sanctuary, ctx.map, ctx.souls, ctx.carry
	local record, await = ctx.record, ctx.await
	local p = profiles:get(player)
	local base = bases:getBaseForPlayer(player)
	local function check(ok, label, detail) record(ok == true, "FULL / " .. label, detail) end
	local function near(marker)
		assert(marker and marker.Parent, "Review target missing")
		ctx.near(marker)
	end
	local function model(uid)
		for _, item in map.ActiveCurses:GetChildren() do if item:GetAttribute("CurseUid") == uid then return item end end
		return nil
	end
	local function owned(uid)
		for _, item in curses:getOwned(player) do if item.uid == uid then return item end end
		return nil
	end
	local function inventory()
		local result = {}
		for _, item in curses:getOwned(player) do table.insert(result, item.uid .. ":" .. item.state .. ":" .. tostring(item.pedestalId)) end
		table.sort(result); return table.concat(result, "|")
	end
	local function pedestal(id) return bases:getPedestals(base)[id] end
	local function atAltar() near(base.RestorationAltar) end
	local function characterRoot() return player.Character and player.Character:FindFirstChild("HumanoidRootPart") end
	local function killAndRecover(label, reset)
		local previous = player.Character
		if reset then player:LoadCharacter() else previous:FindFirstChildOfClass("Humanoid").Health = 0 end
		check(await(function()
			local character = player.Character; local h = character and character:FindFirstChildOfClass("Humanoid")
			return character ~= previous and h and h.Health > 0 and characterRoot() ~= nil
		end, 25), label .. " creates a fresh living character", { method = if reset then "Player.LoadCharacter" else "Humanoid.Health=0" })
	end
	local function accept(id)
		near(contracts:getNode(player, "gravekeeper_board"))
		local ok, message = contracts:accept(player, id)
		check(ok, "accept " .. id, message)
		return p.sanctuary.contract.token
	end
	local function interact(id)
		near(contracts:getNode(player, id))
		return contracts:interact(player, id)
	end
	local function completeContract(id, label)
		local definition = Config.Contracts[id]
		local beforeFragments, beforeContracts = p.sanctuary.fragments, p.sanctuary.milestones.contracts
		local counter = if definition.kind == "SEAL" then "sealing" else string.lower(definition.kind)
		local beforeType, beforeMajor, beforeMarks = p.sanctuary.milestones[counter], p.sanctuary.milestones.majorRelics, p.sanctuary.milestones.sealActivations
		local token = accept(id)
		check(not contracts:accept(player, id) and p.sanctuary.contract.token == token, "duplicate accept preserves active token / " .. label)
		near(contracts:getNode(player, definition.nodes[1]))
		check(not contracts:interact(player, definition.nodes[#definition.nodes]), "out of order node cannot advance / " .. label)
		check(p.sanctuary.contract.step == 0 and p.sanctuary.fragments == beforeFragments, "out of order node grants no resources / " .. label)
		local target = contracts:getNode(player, definition.nodes[1])
		ctx.pose(target.CFrame * CFrame.new(30, 3, 0))
		check(not contracts:interact(player, definition.nodes[1]) and p.sanctuary.contract.step == 0, "distant interaction rejected / " .. label)
		for step, nodeId in definition.nodes do
			local ok, message = interact(nodeId); check(ok, "physical node " .. step .. " / " .. label, message)
			if step < #definition.nodes then
				local activeStep, fragments = p.sanctuary.contract.step, p.sanctuary.fragments
				check(not contracts:interact(player, nodeId) and p.sanctuary.contract.step == activeStep and p.sanctuary.fragments == fragments, "repeated node cannot advance / " .. label)
			end
		end
		check(p.sanctuary.contract == nil and carry:get(player) == nil and p.sanctuary.fragments == beforeFragments + definition.rewardFragments,
			"one exact reward / " .. label, { token = token, before = beforeFragments, after = p.sanctuary.fragments, reward = definition.rewardFragments })
		check(p.sanctuary.milestones.contracts == beforeContracts + 1 and p.sanctuary.milestones[counter] == beforeType + 1
			and p.sanctuary.milestones.majorRelics == beforeMajor + (if definition.majorRelic then 1 else 0)
			and p.sanctuary.milestones.sealActivations == beforeMarks + (if definition.kind == "SEAL" then #definition.nodes else 0), "correct real activity milestones / " .. label)
		check(not contracts:interact(player, definition.nodes[#definition.nodes]) and not Rules.awardContract(p, id, token)
			and p.sanctuary.fragments == beforeFragments + definition.rewardFragments, "repeat delivery and stale token do not repay / " .. label)
	end
	local function buyAndPlace(id, slotId)
		local root = characterRoot()
		local uid = curses:spawn(id, root.CFrame * CFrame.new(0, 3.5, -4))
		local instance = model(uid); near(instance.PrimaryPart); task.wait(.35)
		local before = p.souls
		check(curses:purchase(player, uid) and p.souls == before - Catalog.Definitions[id].price, "real purchase " .. id, { uid = uid, catalogPrice = Catalog.Definitions[id].price })
		near(pedestal(slotId)); local answer = curses:action(player, "place", uid, slotId)
		check(answer.ok and owned(uid).state == "PLACED" and owned(uid).pedestalId == slotId, "manual placement " .. id, answer.message)
		return uid
	end

	check(p and base and p.sanctuary.level == 1 and p.sanctuary.rituals.first_vigil, "starts after actual first-flow/reload", { level = p and p.sanctuary.level })
	local originalDoll
	for _, item in curses:getOwned(player) do if item.definitionId == "cursed_doll" and item.state == "PLACED" then originalDoll = item.uid; break end end
	check(originalDoll ~= nil and #curses:getOwned(player) == 1, "original legitimate Doll retained")
	local originalSlotId = owned(originalDoll).pedestalId
	local originalSlot = pedestal(originalSlotId)
	local originalModel = model(originalDoll)
	local initialLevelOne = Rules.snapshot(p.sanctuary)
	check(not sanctuary:action(player, "upgrade", "0").ok and p.sanctuary.level == 1, "old level-zero confirmation cannot buy again")

	-- Actual recovery/death/restart paths before any progress-requirement seeding.
	local fragmentsBeforeDeath = p.sanctuary.fragments
	local deathToken = accept("lost_seal")
	check(interact("cemetery_gate") and carry:get(player) ~= nil, "relic collected before actual death")
	near(originalModel.PrimaryPart)
	check(not curses:action(player, "pickup", originalDoll).ok and owned(originalDoll).state == "PLACED", "carried relic blocks own Curse pickup")
	local unsold = curses:spawn("candle_wisp", characterRoot().CFrame * CFrame.new(0, 3.5, -4))
	near(model(unsold).PrimaryPart)
	check(not curses:purchase(player, unsold), "carried relic blocks new Curse purchase")
	curses:despawnUnsold(unsold)
	killAndRecover("relic death", false)
	check(carry:get(player) == nil and p.sanctuary.contract and p.sanctuary.contract.phase == "RECOVERABLE"
		and p.sanctuary.contract.step == 0 and p.sanctuary.contract.token == deathToken and p.sanctuary.fragments == fragmentsBeforeDeath,
		"death leaves relic recoverable without auto delivery/payment")
	check(owned(originalDoll).state == "PLACED" and owned(originalDoll).pedestalId == originalSlotId, "relic death does not relocate any Curse")
	check(interact("cemetery_gate") and carry:get(player) ~= nil, "manual relic recovery after death")
	check(interact("sanctuary_altar") and p.sanctuary.fragments == fragmentsBeforeDeath + 4, "recovered relic delivered once")

	local restartFragments = p.sanctuary.fragments
	accept("lost_seal"); check(interact("cemetery_gate"), "relic collected before restart")
	check(contracts:restart(player) and carry:get(player) == nil and p.sanctuary.contract.step == 0 and p.sanctuary.fragments == restartFragments,
		"restart releases only relic without paying or consuming materials")
	check(owned(originalDoll).pedestalId == originalSlotId, "contract restart leaves original Curse pedestal untouched")
	check(interact("cemetery_gate") and interact("sanctuary_altar") and p.sanctuary.fragments == restartFragments + 4, "restarted activity requires manual pickup and delivery")
	local abandonFragments = p.sanctuary.fragments
	accept("chapel_lantern"); check(interact("gravekeeper_board"), "lantern collected before abandon")
	check(contracts:abandon(player) and carry:get(player) == nil and p.sanctuary.contract == nil and p.sanctuary.fragments == abandonFragments,
		"abandon retains all already earned fragments")
	accept("well_relic")
	local vanished = contracts:getNode(player, "old_well"); vanished:Destroy()
	check(contracts:restart(player), "controlled restart repairs vanished target")
	local repaired = contracts:getNode(player, "old_well")
	check(repaired and repaired ~= vanished and repaired.Parent ~= nil, "missing target recreated as reachable marker")
	check(interact("old_well") and interact("sanctuary_altar"), "repaired target supports actual pickup/delivery")
	local siteCounts = {}; for _, site in map.RestorationActivities:GetChildren() do siteCounts[site.Name] = (siteCounts[site.Name] or 0) + 1 end
	local unique = true; for _, count in siteCounts do if count ~= 1 then unique = false end end
	check(unique, "site repair creates no duplicate installations", siteCounts)

	-- Explicit QA provisioning, not rewards earned by a player. Level, owned
	-- Curses, rituals and relic milestones are NOT granted here.
	local beforeSeedSouls, beforeSeedFragments = p.souls, p.sanctuary.fragments
	p.souls = 1000000; p.sanctuary.fragments = 1000; souls:refresh(player); profiles:commit(player)
	check(true, "QA_SEED resources for broad service coverage", { kind = "fixture provisioning, not gameplay reward", beforeSouls = beforeSeedSouls, afterSouls = p.souls, beforeFragments = beforeSeedFragments, afterFragments = p.sanctuary.fragments })
	local species = { "grave_hopper", "nail_beetle", "coin_crawler", "wilted_sprout", "cold_teacup" }
	local ownedUids = { originalDoll }
	for index, id in species do
		local discoveryBefore = Rules.discoveryCount(p.sanctuary)
		local uid = buyAndPlace(id, "floor1-slot" .. (index + 1)); table.insert(ownedUids, uid)
		check(p.sanctuary.discoveries[id] and Rules.discoveryCount(p.sanctuary) == discoveryBefore + 1, "real new species discovered once / " .. id)
	end
	local discoveryBeforeSeed = Rules.discoveryCount(p.sanctuary)
	for _, id in Catalog.enabledSpawnIds() do
		local rarity = Catalog.Definitions[id].rarity
		if rarity == "COMMON" or rarity == "RARE" then p.sanctuary.discoveries[id] = true end
	end
	profiles:commit(player)
	check(Rules.discoveryCount(p.sanctuary) == 32, "QA_SEED collection requirements only", { kind = "32 Common/Rare discoveries seeded, not player achievements", before = discoveryBeforeSeed, after = 32, realOwnedSpecies = #ownedUids })

	local reviewedContracts = {}
	local function availableContracts()
		for _, id in Config.ContractOrder do
			if not reviewedContracts[id] and Config.Contracts[id].minLevel <= p.sanctuary.level then
				completeContract(id, "variant " .. id); reviewedContracts[id] = true
			end
		end
	end
	local function ritual(id, exerciseRetry)
		atAltar(); local beforeInventory, beforeRate, beforeFragments = inventory(), player:GetAttribute("SoulsPerSecond"), p.sanctuary.fragments
		local ok, message = rituals:begin(player, id); check(ok, "begin actual owned-species ritual " .. id, message)
		local session = rituals:snapshot(player)
		local folder = map.RestorationRitualEchoes:FindFirstChild("Ritual_" .. player.UserId)
		check(session and folder and #folder:GetChildren() == Config.Rituals[id].speciesRequired and inventory() == beforeInventory
			and player:GetAttribute("SoulsPerSecond") == beforeRate, "ritual echoes have no owned instances or added income / " .. id)
		if exerciseRetry then
			local wrong = if Config.Rituals[id].sequence[1] == 3 then 2 else 3
			near(base.RitualMarkers["RitualMark_" .. wrong]); check(not rituals:activate(player, wrong) and rituals:snapshot(player).step == 0, "wrong ritual mark permits safe retry")
			check(rituals:cancel(player) and rituals:snapshot(player) == nil and folder.Parent == nil
				and inventory() == beforeInventory and p.sanctuary.fragments == beforeFragments, "ritual exit cleans echoes and preserves resources/ownership")
			atAltar(); check(rituals:begin(player, id), "ritual can begin again after exit")
		end
		for index, mark in Config.Rituals[id].sequence do
			near(base.RitualMarkers["RitualMark_" .. mark]); task.wait(.3)
			local activated, reason = rituals:activate(player, mark); check(activated, "ordered ritual mark " .. index .. " / " .. id, reason)
		end
		check(p.sanctuary.rituals[id] and rituals:snapshot(player) == nil and inventory() == beforeInventory
			and player:GetAttribute("SoulsPerSecond") == beforeRate and p.sanctuary.fragments == beforeFragments, "ritual completes once without consuming or duplicating / " .. id)
		check(not rituals:activate(player, Config.Rituals[id].sequence[#Config.Rituals[id].sequence]) and not rituals:begin(player, id), "completed ritual cannot replay / " .. id)
	end
	local ritualAtLevel = { [3] = "collection_vigil", [6] = "relic_consecration", [8] = "grand_seal", [9] = "dominion" }
	local upgradeReceipts = { { level = 1, source = "root first-flow actual purchase/contract/ritual", capacity = 6 } }
	for nextLevel = 2, 10 do
		availableContracts()
		if nextLevel == 6 then completeContract("cemetery_marks", "additional real sequence for protective seal") end
		local ritualId = ritualAtLevel[p.sanctuary.level]
		if ritualId then ritual(ritualId, ritualId == "collection_vigil") end
		local definition = Config.Levels[nextLevel]
		if definition.contracts and p.sanctuary.milestones.contracts < definition.contracts then
			local previous = p.sanctuary.milestones.contracts
			p.sanctuary.milestones.contracts = definition.contracts; profiles:commit(player)
			check(true, "QA_SEED late contract count requirement", { kind = "counter seeded to avoid repetitive grind, not player completion", level = nextLevel, before = previous, after = definition.contracts })
		end
		if definition.milestones and definition.milestones.sealActivations and p.sanctuary.milestones.sealActivations < definition.milestones.sealActivations then
			while p.sanctuary.milestones.sealActivations < definition.milestones.sealActivations do completeContract("cemetery_marks", "additional real marks for consecration") end
		end
		atAltar()
		local fragments = p.sanctuary.fragments; p.sanctuary.fragments = 0
		local soulsBeforeFailure = p.souls; local denied = sanctuary:action(player, "upgrade", tostring(nextLevel - 1))
		check(not denied.ok and p.souls == soulsBeforeFailure and p.sanctuary.level == nextLevel - 1, "missing fragments cannot charge stage " .. nextLevel)
		p.sanctuary.fragments = fragments
		local balance = p.souls; p.souls = 0
		denied = sanctuary:action(player, "upgrade", tostring(nextLevel - 1))
		check(not denied.ok and p.sanctuary.fragments == fragments and p.sanctuary.level == nextLevel - 1, "missing Souls cannot charge stage " .. nextLevel)
		p.souls = balance; souls:refresh(player)
		ctx.pose(base.RestorationAltar.CFrame * CFrame.new(30, 2, 0))
		balance = p.souls; denied = sanctuary:action(player, "upgrade", tostring(nextLevel - 1))
		check(not denied.ok and p.souls == balance and p.sanctuary.fragments == fragments, "distant upgrade denied stage " .. nextLevel)
		atAltar(); local beforeSouls, beforeFragments, beforeInventory = p.souls, p.sanctuary.fragments, inventory()
		local granted = sanctuary:action(player, "upgrade", tostring(nextLevel - 1))
		check(granted.ok and p.sanctuary.level == nextLevel and p.souls == beforeSouls - definition.souls
			and p.sanctuary.fragments == beforeFragments - definition.fragments, "exact atomic stage cost " .. nextLevel, granted.message)
		check(#bases:getSlots(base) == definition.capacity and base:GetAttribute("RestorationLevel") == nextLevel
			and pedestal(originalSlotId) == originalSlot and inventory() == beforeInventory and model(originalDoll) == originalModel,
			"stage adds empty stable pedestals without moving collection " .. nextLevel, { capacity = #bases:getSlots(base) })
		local afterSouls, afterFragments = p.souls, p.sanctuary.fragments
		check(not sanctuary:action(player, "upgrade", tostring(nextLevel - 1)).ok and p.souls == afterSouls and p.sanctuary.fragments == afterFragments,
			"stale duplicate stage confirmation cannot charge " .. nextLevel)
		table.insert(upgradeReceipts, { level = nextLevel, souls = definition.souls, fragments = definition.fragments, capacity = definition.capacity, source = "actual service action with QA provisioned requirements explicitly recorded" })
	end
	availableContracts()
	local variantCount = 0; for _ in reviewedContracts do variantCount += 1 end
	check(variantCount == #Config.ContractOrder, "all 12 actual contract variants covered", { count = variantCount })

	local stableMarkers = bases:getPedestals(base)
	check(#bases:getSlots(base) == 30 and pedestal("floor2-slot10") ~= nil and pedestal("floor3-slot10") ~= nil, "all three floors expose 30 logical pedestals")
	atAltar(); local featured = sanctuary:action(player, "featured", originalDoll)
	check(featured.ok and p.sanctuary.featuredUid == originalDoll and base:GetAttribute("FeaturedPedestalId") == originalSlotId, "featured display points to original real instance")
	local sealStartedAt = workspace:GetServerTimeNow(); local sealed = sanctuary:action(player, "seal")
	local sealedState = sanctuary:snapshot(player).seal
	local barrier = base.SealBarrier
	check(sealed.ok and barrier.CanCollide and sealedState.endsAt >= sealStartedAt + Config.Protection.consagratedDuration
		and sealedState.availableAt == sealedState.endsAt + Config.Protection.vulnerabilitySeconds,
		"consagrated protection has configured closure and vulnerability times", sealedState)
	local access = barrier:FindFirstChild("OwnerSealAccess")
	check(access and #access:GetChildren() > 0, "server owner access constraints exist during closure")
	check(not sanctuary:action(player, "seal").ok and sanctuary:snapshot(player).seal.availableAt == sealedState.availableAt,
		"repeated seal activation cannot extend or chain closure")
	for _, style in Config.StyleOrder do
		local beforeInventory, beforeRate = inventory(), player:GetAttribute("SoulsPerSecond")
		local changed = sanctuary:action(player, "style", style); local afterMarkers = bases:getPedestals(base); local stable = true
		for id, marker in stableMarkers do if afterMarkers[id] ~= marker then stable = false end end
		check(changed.ok and p.sanctuary.style == style and stable and #bases:getSlots(base) == 30
			and inventory() == beforeInventory and player:GetAttribute("SoulsPerSecond") == beforeRate and model(originalDoll) == originalModel,
			"style preserves all identities and production / " .. style)
		check(base:GetAttribute("FeaturedPedestalId") == originalSlotId and originalSlot:GetAttribute("FeaturedPedestal") == true, "featured pedestal survives style / " .. style)
		check(base.SealBarrier == barrier and base.SealBarrier.CanCollide and barrier:FindFirstChild("OwnerSealAccess") == access,
			"style preserves active server barrier and owner access / " .. style)
	end
	check(sanctuary:action(player, "featured", "").ok and p.sanctuary.featuredUid == nil and base:GetAttribute("FeaturedPedestalId") == nil, "featured display can be cleared without changing collection")

	local beforeRate = player:GetAttribute("SoulsPerSecond")
	near(originalModel.PrimaryPart); check(curses:action(player, "pickup", originalDoll).ok, "own Curse physically picked for floor relocation")
	check(player:GetAttribute("CarriedCurseUid") == originalDoll and originalSlot:GetAttribute("OccupiedCurseUid") == nil
		and player:GetAttribute("SoulsPerSecond") == beforeRate - Catalog.Definitions.cursed_doll.baseSoulsPerSecond, "pickup frees original pedestal and stops that income once")
	near(pedestal("floor1-slot2")); local occupiedAnswer = curses:action(player, "place", originalDoll, "floor1-slot2")
	check(not occupiedAnswer.ok and owned(originalDoll).state == "CARRYING", "occupied pedestal cannot steal or duplicate a slot", occupiedAnswer.message)
	local contractToken = accept("chapel_lantern")
	local noRelic = contracts:interact(player, "gravekeeper_board")
	check(not noRelic and carry:get(player) == nil and p.sanctuary.contract.step == 0 and player:GetAttribute("CarriedCurseUid") == originalDoll,
		"carried Curse blocks simultaneous contract relic pickup", { contractToken = contractToken })
	killAndRecover("carried Curse death", false)
	check(owned(originalDoll).state == "UNPLACED" and owned(originalDoll).pedestalId == nil and originalSlot:GetAttribute("OccupiedCurseUid") == nil
		and player:GetAttribute("CarriedCurseUid") == nil and player:GetAttribute("SoulsPerSecond") == beforeRate - Catalog.Definitions.cursed_doll.baseSoulsPerSecond,
		"death keeps Curse unplaced without returning or earning")
	check(await(function() local item = model(originalDoll); return item and item.PrimaryPart and item.Parent end, 8), "death recovery produces a reachable manual pickup")
	near(model(originalDoll).PrimaryPart); check(curses:action(player, "pickup", originalDoll).ok, "Curse manually recovered after death")
	near(pedestal("floor2-slot10")); local secondFloor = curses:action(player, "place", originalDoll, "floor2-slot10")
	check(secondFloor.ok and owned(originalDoll).pedestalId == "floor2-slot10" and player:GetAttribute("SoulsPerSecond") == beforeRate,
		"manual second-floor placement resumes one real production instance", secondFloor.message)
	near(model(originalDoll).PrimaryPart); check(curses:action(player, "pickup", originalDoll).ok, "second-floor Curse picked for reset test")
	killAndRecover("carried Curse reset", true)
	check(owned(originalDoll).state == "UNPLACED" and owned(originalDoll).pedestalId == nil and originalSlot:GetAttribute("OccupiedCurseUid") == nil
		and pedestal("floor2-slot10"):GetAttribute("OccupiedCurseUid") == nil
		and player:GetAttribute("CarriedCurseUid") == nil and player:GetAttribute("SoulsPerSecond") == beforeRate - Catalog.Definitions.cursed_doll.baseSoulsPerSecond,
		"reset keeps Curse recoverable and never returns it to old pedestal")
	local savedDoll; for _, item in p.curses do if item.uid == originalDoll then savedDoll = item end end
	check(savedDoll and savedDoll.state == "UNPLACED" and savedDoll.pedestalId == nil, "reset persists unplaced ownership")
	check(profiles:flush(player, false), "unplaced reset snapshot durably acknowledged before manual recovery")
	check(await(function() local item = model(originalDoll); return item and item.PrimaryPart and item.Parent end, 8), "recoverable Curse has reachable runtime representation")
	near(model(originalDoll).PrimaryPart); check(curses:action(player, "pickup", originalDoll).ok, "manual Curse recovery required after reset")
	near(pedestal("floor3-slot10")); local upstairs = curses:action(player, "place", originalDoll, "floor3-slot10")
	check(upstairs.ok and owned(originalDoll).pedestalId == "floor3-slot10" and player:GetAttribute("SoulsPerSecond") == beforeRate, "manual third-floor placement resumes exactly one income", upstairs.message)
	check(not curses:action(player, "place", originalDoll, "floor3-slot9").ok and player:GetAttribute("SoulsPerSecond") == beforeRate, "repeat placement cannot duplicate income")
	check(interact("gravekeeper_board") and carry:get(player) ~= nil, "relic pickup succeeds after Curse placement")
	check(interact("chapel_steps") and carry:get(player) == nil, "shared carry channel clears after delivery")

	local duplicateDiscoveryCount = Rules.discoveryCount(p.sanctuary)
	local duplicate = buyAndPlace("cursed_doll", "floor1-slot7")
	check(Rules.discoveryCount(p.sanctuary) == duplicateDiscoveryCount, "duplicate species does not inflate Grimorio")
	near(model(duplicate).PrimaryPart); local quote = curses:action(player, "quote", duplicate)
	local expectedSale = math.floor(Catalog.Definitions.cursed_doll.price * GameplayConfig.SellFraction)
	check(quote.ok and quote.data.sale == expectedSale and GameplayConfig.SellFraction == .5, "sale quote is exact catalog half")
	local balanceBeforeSale, rateBeforeSale = p.souls, player:GetAttribute("SoulsPerSecond")
	local sold = curses:action(player, "sell", duplicate, nil, quote.data.token)
	check(sold.ok and p.souls == balanceBeforeSale + expectedSale and owned(duplicate) == nil and model(duplicate) == nil
		and pedestal("floor1-slot7"):GetAttribute("OccupiedCurseUid") == nil
		and player:GetAttribute("SoulsPerSecond") == rateBeforeSale - Catalog.Definitions.cursed_doll.baseSoulsPerSecond, "sale removes one instance frees pedestal and updates income", sold.message)
	local afterSale = p.souls
	check(not curses:action(player, "sell", duplicate, nil, quote.data.token).ok and p.souls == afterSale
		and owned(originalDoll).state == "PLACED" and p.sanctuary.discoveries.cursed_doll, "repeated sale cannot pay again or remove other duplicate")
	atAltar(); check(sanctuary:action(player, "featured", originalDoll).ok, "final featured selection follows relocated actual Curse")
	check(base:GetAttribute("FeaturedPedestalId") == "floor3-slot10", "featured highlight uses current logical floor slot")

	profiles:commit(player); check(profiles:flush(player, false), "final isolated local profile write acknowledged")
	local expected = {
		souls = p.souls, savedAt = p.savedAt,
		level = p.sanctuary.level, style = p.sanctuary.style, fragments = p.sanctuary.fragments,
		discoveries = Rules.snapshot(p.sanctuary.discoveries), rituals = Rules.snapshot(p.sanctuary.rituals),
		milestones = Rules.snapshot(p.sanctuary.milestones), featuredUid = p.sanctuary.featuredUid,
		curses = Rules.snapshot(p.curses), revision = p.revision,
	}
	check(p.sanctuary.level == 10 and p.sanctuary.contract == nil and #p.curses == 6 and owned(originalDoll).pedestalId == "floor3-slot10",
		"functional final checkpoint remains owned placed and ready for root reload", { owned = #p.curses, level = 10, featuredSlot = "floor3-slot10" })
	return { expectedProfile = expected, upgradeReceipts = upgradeReceipts, reviewedContracts = reviewedContracts, originalDollUid = originalDoll,
		initialLevelOne = initialLevelOne, scope = "Production server rules with teleported validated positions; QA seeded resources/collection and any late contract-count deficits are explicit. Native visuals, two clients, walking, network transport and mobile remain separate root checks." }
end
