-- Mount as a ModuleScript under the existing UnitTest.Cases folder for the shared runner.
return function(t)
	local P = require(game.ReplicatedStorage.Shared.SanctuaryProgression)
	local C = require(game.ReplicatedStorage.Shared.SanctuaryConfig)
	local Catalog = require(game.ReplicatedStorage.Shared.CurseCatalog)
	local e = t.expect
	local function account()
		return { schema = 1, souls = 500, curses = {}, revision = 8, sanctuary = P.newProgress() }
	end
	local function own(p, id, state)
		table.insert(p.curses, { uid = "test-" .. tostring(#p.curses + 1), definitionId = id, state = state or "PLACED", pedestalId = "P01", revision = 3 })
	end
	local function ready(p)
		p.souls = 10000000; p.sanctuary.fragments = 10000
		for _, id in Catalog.enabledSpawnIds() do P.discover(p, id) end
		for _, id in C.RitualOrder do p.sanctuary.rituals[id] = true end
		for _, id in C.MilestoneOrder do p.sanctuary.milestones[id] = 100 end
	end
	t.test("all 56 enabled identities have themes without unknown identities", function()
		local seen, count = {}, 0
		for _, id in Catalog.enabledSpawnIds() do e.truthy(C.SpeciesTags[id]); seen[id] = true end
		for id in C.SpeciesTags do e.truthy(seen[id]); count += 1 end
		e.equal(count, 56)
	end)
	t.test("all eleven capacities match requested progression", function()
		for level, expected in { [0] = 5, 6, 8, 10, 14, 18, 18, 22, 26, 26, 30 } do e.equal(P.capacity(level), expected) end
	end)
	t.test("legacy migration keeps Souls inventory revisions and logical slots", function()
		local p = account(); p.sanctuary = nil; own(p, "cursed_doll"); own(p, "haunted_mirror", "UNPLACED")
		local inventory = p.curses
		local value, changed = P.migrate(p)
		e.truthy(changed); e.equal(p.souls, 500); e.equal(p.revision, 8); e.equal(p.curses, inventory)
		e.equal(p.curses[1].uid, "test-1"); e.equal(p.curses[1].pedestalId, "P01"); e.equal(p.curses[1].revision, 3)
		e.truthy(value.discoveries.cursed_doll); e.truthy(value.discoveries.haunted_mirror)
	end)
	t.test("fresh unplaced purchases do not discover on reload", function()
		local p = account(); own(p, "cursed_doll", "UNPLACED"); P.migrate(p)
		e.equal(P.discoveryCount(p.sanctuary), 0)
	end)
	t.test("migration becomes idempotent after first legacy upgrade", function()
		local p = account(); p.sanctuary = nil; own(p, "cursed_doll"); P.migrate(p)
		local _, changed = P.migrate(p); e.falsy(changed)
	end)
	t.test("sold species remain discovered", function()
		local p = account(); P.discover(p, "cursed_doll"); P.migrate(p)
		e.equal(#p.curses, 0); e.truthy(p.sanctuary.discoveries.cursed_doll)
	end)
	t.test("duplicate species cannot inflate discoveries or themed sets", function()
		local p = account(); e.truthy(P.discover(p, "cursed_doll")); e.falsy(P.discover(p, "cursed_doll"))
		e.equal(P.discoveryCount(p.sanctuary), 1); e.equal(P.setProgress(p.sanctuary, "haunted_house").current, 1)
	end)
	t.test("unknown logical identities grant no discovery", function()
		local p = account(); e.falsy(P.discover(p, "fake_secret")); e.equal(P.discoveryCount(p.sanctuary), 0)
	end)
	t.test("corrupt sanctuary numerics never reset valid base inventory", function()
		local p = account(); own(p, "cursed_doll"); p.sanctuary.level = math.huge; p.sanctuary.fragments = 0 / 0
		p.sanctuary.milestones.contracts = -9; p.sanctuary.discoveries.fake_secret = true; p.sanctuary.discoveries.cursed_doll = "true"
		local inventory = p.curses; P.migrate(p)
		e.equal(p.sanctuary.level, 0); e.equal(p.sanctuary.fragments, 0); e.equal(p.sanctuary.milestones.contracts, 0)
		e.equal(p.souls, 500); e.equal(p.curses, inventory); e.equal(P.discoveryCount(p.sanctuary), 0)
	end)
	t.test("newer sanctuary schema is preserved by failure instead of overwrite", function()
		local p = account(); p.sanctuary.schema = 2; local previous = p.sanctuary
		e.throws(function() P.migrate(p) end); e.equal(p.sanctuary, previous); e.equal(p.souls, 500)
	end)
	t.test("saved carried relic becomes recoverable without reward", function()
		local p = account(); p.sanctuary.contract = { id = "lost_seal", token = "real-token", step = 1, phase = "CARRYING", startedAt = 100 }
		P.migrate(p); e.equal(p.sanctuary.contract.phase, "RECOVERABLE"); e.equal(p.sanctuary.contract.step, 0)
		e.equal(p.sanctuary.contract.carryState.nodeId, "cemetery_gate"); e.equal(p.sanctuary.fragments, 0)
	end)
	t.test("contract step zero is valid and invalid contracts never reward", function()
		local p = account(); p.sanctuary.fragments = 17
		p.sanctuary.contract = { id = "lost_seal", token = "token", step = 0, phase = "ACTIVE" }; P.migrate(p)
		e.equal(p.sanctuary.contract.step, 0)
		p.sanctuary.contract.step = 99; P.migrate(p); e.equal(p.sanctuary.contract, nil); e.equal(p.sanctuary.fragments, 17)
	end)
	t.test("snapshot changes cannot mutate authoritative progress", function()
		local p = account(); P.discover(p, "cursed_doll"); local view = P.snapshot(p.sanctuary)
		view.discoveries.cursed_doll = nil; view.milestones.contracts = 100
		e.truthy(p.sanctuary.discoveries.cursed_doll); e.equal(p.sanctuary.milestones.contracts, 0)
	end)
	t.test("missing first ritual prevents upgrade without spending", function()
		local p = account(); P.discover(p, "cursed_doll"); e.falsy(P.tryUpgrade(p, 1))
		e.equal(p.souls, 500); e.equal(p.sanctuary.level, 0)
	end)
	t.test("first upgrade and repeated stale confirmation debit once", function()
		local p = account(); P.discover(p, "cursed_doll"); p.sanctuary.rituals.first_vigil = true
		e.truthy(P.tryUpgrade(p, 1)); e.equal(p.souls, 350); e.equal(p.sanctuary.level, 1)
		e.falsy(P.tryUpgrade(p, 1)); e.equal(p.souls, 350); e.equal(p.sanctuary.fragments, 0)
	end)
	t.test("cannot skip a level even with all requirements", function()
		local p = account(); ready(p); e.falsy(P.tryUpgrade(p, 10)); e.equal(p.sanctuary.level, 0); e.equal(p.souls, 10000000)
	end)
	t.test("all ten upgrades consume resources but preserve every owned instance", function()
		local p = account(); own(p, "cursed_doll"); ready(p); local inventory = p.curses
		local expectedSouls, expectedFragments = p.souls, p.sanctuary.fragments
		for level = 1, 10 do
			e.truthy(P.tryUpgrade(p, level)); expectedSouls -= C.Levels[level].souls; expectedFragments -= C.Levels[level].fragments
			e.equal(p.souls, expectedSouls); e.equal(p.sanctuary.fragments, expectedFragments); e.equal(p.curses, inventory)
		end
		e.equal(p.sanctuary.level, 10); e.equal(#p.curses, 1); e.falsy(P.evaluate(p).eligible)
	end)
	t.test("essential collection and set requirements are achievable with Common and Rare only", function()
		local p = account(); ready(p); p.sanctuary.discoveries = {}
		for _, id in Catalog.enabledSpawnIds() do
			local rarity = Catalog.Definitions[id].rarity
			if rarity == "COMMON" or rarity == "RARE" then P.discover(p, id) end
		end
		for level = 1, 10 do e.truthy(P.evaluate(p, level).eligible); e.truthy(P.tryUpgrade(p, level)) end
	end)
	t.test("contract reward requires final physical step and matching token", function()
		local p = account(); p.sanctuary.contract = { id = "lost_seal", token = "a", step = 1, phase = "CARRYING" }
		e.falsy(P.awardContract(p, "lost_seal", "a")); p.sanctuary.contract.step = 2
		e.falsy(P.awardContract(p, "lost_seal", "b")); e.falsy(P.awardContract(p, "well_relic", "a"))
		e.equal(p.sanctuary.fragments, 0); e.equal(p.sanctuary.milestones.contracts, 0)
	end)
	t.test("completed delivery rewards exactly once", function()
		local p = account(); p.sanctuary.contract = { id = "lost_seal", token = "a", step = 2, phase = "CARRYING" }
		local ok, reward = P.awardContract(p, "lost_seal", "a")
		e.truthy(ok); e.equal(reward, 4); e.equal(p.sanctuary.fragments, 4); e.equal(p.sanctuary.milestones.recovery, 1)
		e.falsy(P.awardContract(p, "lost_seal", "a")); e.equal(p.sanctuary.fragments, 4); e.equal(p.sanctuary.milestones.contracts, 1)
	end)
	t.test("recoverable relic cannot reward automatically on reconnect", function()
		local p = account(); p.sanctuary.contract = { id = "lost_seal", token = "a", step = 2, phase = "RECOVERABLE" }
		e.falsy(P.awardContract(p, "lost_seal", "a")); e.equal(p.sanctuary.fragments, 0)
	end)
	t.test("major relic milestone belongs to valid completed contract only", function()
		local p = account(); p.sanctuary.level = 6
		p.sanctuary.contract = { id = "greater_relic", token = "a", step = 2, phase = "CARRYING" }
		e.truthy(P.awardContract(p, "greater_relic", "a")); e.equal(p.sanctuary.milestones.majorRelics, 1)
		e.equal(p.sanctuary.milestones.recovery, 1); e.equal(p.sanctuary.fragments, 14)
	end)
	t.test("ritual uses placed owned distinct species not discovery history or duplicates", function()
		local p = account(); p.sanctuary.level = 3; P.discover(p, "haunted_mirror")
		own(p, "cursed_doll"); own(p, "cursed_doll"); own(p, "haunted_mirror", "UNPLACED")
		e.falsy(P.ritualEligibility(p, "collection_vigil").eligible)
		own(p, "grave_hopper"); own(p, "cold_teacup")
		e.truthy(P.ritualEligibility(p, "collection_vigil").eligible)
	end)
	t.test("ritual completion preserves ownership and can only mark once", function()
		local p = account(); own(p, "cursed_doll"); local inventory = p.curses
		e.truthy(P.completeRitual(p, "first_vigil")); e.falsy(P.completeRitual(p, "first_vigil"))
		e.equal(p.curses, inventory); e.equal(p.souls, 500); e.equal(p.sanctuary.fragments, 0)
	end)
	t.test("styles and featured instance never create an extra Curse", function()
		local p = account(); own(p, "cursed_doll"); own(p, "haunted_mirror", "UNPLACED")
		e.truthy(P.selectStyle(p, "FOREST")); e.falsy(P.selectStyle(p, "PAID_STYLE"))
		e.truthy(P.selectFeatured(p, "test-1")); e.falsy(P.selectFeatured(p, "test-2")); e.falsy(P.selectFeatured(p, "foreign"))
		P.migrate(p); e.equal(p.sanctuary.style, "FOREST"); e.equal(p.sanctuary.featuredUid, "test-1"); e.equal(#p.curses, 2)
	end)
	t.test("invalid featured references normalize without touching inventory", function()
		local p = account(); own(p, "cursed_doll", "UNPLACED"); p.sanctuary.featuredUid = "test-1"
		P.migrate(p); e.equal(p.sanctuary.featuredUid, nil); e.equal(#p.curses, 1)
	end)
	t.test("mark counters stay finite at their supported cap", function()
		local p = account(); p.sanctuary.milestones.sealActivations = C.MaximumMilestone
		e.truthy(P.recordSealActivation(p)); e.equal(p.sanctuary.milestones.sealActivations, C.MaximumMilestone)
	end)
	t.test("every contract variant grants its configured reward and correct milestone once", function()
		for _, id in C.ContractOrder do
			local p = account(); local definition = C.Contracts[id]; p.sanctuary.level = definition.minLevel
			p.sanctuary.contract = { id = id, token = "variant-token", step = #definition.nodes, phase = if definition.kind == "SEAL" then "ACTIVE" else "CARRYING" }
			local ok, reward = P.awardContract(p, id, "variant-token")
			e.truthy(ok); e.equal(reward, definition.rewardFragments); e.equal(p.sanctuary.fragments, reward)
			local milestone = if definition.kind == "SEAL" then "sealing" else string.lower(definition.kind)
			e.equal(p.sanctuary.milestones[milestone], 1); e.equal(p.sanctuary.milestones.contracts, 1)
			e.equal(p.sanctuary.milestones.majorRelics, if definition.majorRelic then 1 else 0)
			e.falsy(P.awardContract(p, id, "variant-token")); e.equal(p.sanctuary.fragments, reward)
		end
	end)
	t.test("seal contract preserves ordered node progress across reload without awarding", function()
		local p = account(); p.sanctuary.fragments = 9; p.sanctuary.milestones.sealActivations = 2
		p.sanctuary.contract = { id = "cemetery_marks", token = "seal-token", step = 2, phase = "ACTIVE", startedAt = 100 }
		P.migrate(p); e.equal(p.sanctuary.contract.step, 2); e.equal(p.sanctuary.contract.phase, "ACTIVE")
		e.equal(p.sanctuary.fragments, 9); e.equal(p.sanctuary.milestones.contracts, 0); e.equal(p.sanctuary.milestones.sealActivations, 2)
	end)
	t.test("relic recovery reload is idempotent and preserves manual Curse relocation state", function()
		local p = account(); own(p, "cursed_doll", "UNPLACED")
		p.sanctuary.contract = { id = "lost_seal", token = "carry-token", step = 1, phase = "CARRYING", startedAt = 100 }
		P.migrate(p); local _, changed = P.migrate(p)
		e.falsy(changed); e.equal(p.sanctuary.contract.token, "carry-token"); e.equal(p.sanctuary.contract.step, 0)
		e.equal(p.curses[1].state, "UNPLACED"); e.equal(p.sanctuary.fragments, 0); e.equal(P.discoveryCount(p.sanctuary), 0)
	end)
	t.test("fragment overflow rejects an award without consuming token or changing counters", function()
		local p = account(); p.sanctuary.fragments = C.MaximumFragments - 1
		p.sanctuary.contract = { id = "lost_seal", token = "cap-token", step = 2, phase = "CARRYING" }
		local active = p.sanctuary.contract; e.falsy(P.awardContract(p, "lost_seal", "cap-token"))
		e.equal(p.sanctuary.fragments, C.MaximumFragments - 1); e.equal(p.sanctuary.contract, active); e.equal(p.sanctuary.milestones.contracts, 0)
	end)
	t.test("insufficient fragments and Souls each prevent all upgrade debits", function()
		local p = account(); ready(p); p.sanctuary.level = 1; p.sanctuary.fragments = C.Levels[2].fragments - 1
		local souls = p.souls; e.falsy(P.tryUpgrade(p, 2)); e.equal(p.souls, souls); e.equal(p.sanctuary.level, 1)
		p.sanctuary.fragments = C.Levels[2].fragments; p.souls = C.Levels[2].souls - 1
		e.falsy(P.tryUpgrade(p, 2)); e.equal(p.souls, C.Levels[2].souls - 1); e.equal(p.sanctuary.fragments, C.Levels[2].fragments)
	end)
	t.test("first Common purchase ritual and restoration remain attainable from 500 Souls", function()
		local p = account(); p.souls -= Catalog.Definitions.cursed_doll.price; own(p, "cursed_doll")
		e.truthy(P.discover(p, "cursed_doll")); e.truthy(P.completeRitual(p, "first_vigil")); e.truthy(P.tryUpgrade(p, 1))
		e.equal(p.souls, 500 - Catalog.Definitions.cursed_doll.price - C.Levels[1].souls); e.truthy(p.souls > 0)
		e.equal(#p.curses, 1); e.equal(p.sanctuary.level, 1); e.equal(p.sanctuary.fragments, 0)
	end)
end
