-- Pure rules over authenticated server profiles. This module grants no client authority.
local Config = require(script.Parent.SanctuaryConfig)
local Progression = {}
local nodes = {}
for _, id in Config.NodeOrder do nodes[id] = true end

local function finite(value)
	return typeof(value) == "number" and value == value and value > -math.huge and value < math.huge
end
local function integer(value, maximum, fallback)
	if not finite(value) or value < 0 or value > maximum or value ~= math.floor(value) then return fallback end
	return value
end
local function shortString(value, maximum)
	return typeof(value) == "string" and #value > 0 and #value <= maximum and not value:find("%c")
end
local function same(a, b)
	if typeof(a) ~= typeof(b) then return false end
	if typeof(a) ~= "table" then return a == b end
	for key, value in a do if not same(value, b[key]) then return false end end
	for key in b do if a[key] == nil then return false end end
	return true
end
local function copy(value)
	if typeof(value) ~= "table" then return value end
	local result = {}
	for key, item in value do result[key] = copy(item) end
	return result
end
local function progress(profile)
	assert(typeof(profile) == "table" and typeof(profile.sanctuary) == "table", "Load and migrate the server profile first")
	return profile.sanctuary
end

function Progression.newProgress()
	local milestones = {}
	for _, id in Config.MilestoneOrder do milestones[id] = 0 end
	return {
		schema = Config.Schema, level = 0, style = "CRYPT", fragments = 0,
		discoveries = {}, milestones = milestones, rituals = {}, contract = nil, featuredUid = nil,
	}
end

-- Normalize new fields without replacing schema-1 Souls, inventory or revision.
-- A future schema fails closed so this version cannot overwrite an account it does not understand.
function Progression.migrate(profile)
	assert(typeof(profile) == "table" and profile.schema == 1 and typeof(profile.curses) == "table", "Invalid base profile")
	local previous = profile.sanctuary
	if typeof(previous) == "table" and finite(previous.schema) and previous.schema > Config.Schema then
		error("Newer sanctuary profile schema; preserved without replacement")
	end
	local notes = {}
	local normalized = Progression.newProgress()
	local legacy = previous == nil
	local saved = if typeof(previous) == "table" then previous else {}
	normalized.level = integer(saved.level, Config.MaximumLevel, 0)
	normalized.fragments = integer(saved.fragments, Config.MaximumFragments, 0)
	if Config.Styles[saved.style] then normalized.style = saved.style end
	if typeof(saved.discoveries) == "table" then
		for id, discovered in saved.discoveries do
			if Config.SpeciesTags[id] and discovered == true then normalized.discoveries[id] = true end
		end
	end
	if typeof(saved.milestones) == "table" then
		for _, id in Config.MilestoneOrder do normalized.milestones[id] = integer(saved.milestones[id], Config.MaximumMilestone, 0) end
	end
	if typeof(saved.rituals) == "table" then
		for id, completed in saved.rituals do if Config.Rituals[id] and completed == true then normalized.rituals[id] = true end end
	end
	if legacy then
		-- V1 inventory is server-authenticated ownership. It has no first-placement history;
		-- both PLACED and recoverable UNPLACED entries are grandfathered exactly once.
		for _, curse in profile.curses do
			if Config.SpeciesTags[curse.definitionId] and (curse.state == "PLACED" or curse.state == "UNPLACED") then
				normalized.discoveries[curse.definitionId] = true
			end
		end
		table.insert(notes, "Legacy owned species registered once; Souls and inventory unchanged.")
	elseif typeof(previous) ~= "table" then
		table.insert(notes, "Malformed sanctuary fields replaced with safe defaults; base account preserved.")
	end
	if shortString(saved.featuredUid, 80) then
		for _, curse in profile.curses do
			if curse.uid == saved.featuredUid and curse.state == "PLACED" then normalized.featuredUid = saved.featuredUid; break end
		end
	end
	local contract = saved.contract
	if typeof(contract) == "table" then
		local definition = Config.Contracts[contract.id]
		local step = if definition then integer(contract.step, #definition.nodes, nil) else nil
		local allowedPhase = contract.phase == "ACTIVE" or contract.phase == "CARRYING" or contract.phase == "RECOVERABLE"
		if definition and definition.minLevel <= normalized.level and step ~= nil and allowedPhase
			and shortString(contract.token, Config.MaximumContractTokenLength) then
			normalized.contract = {
				id = definition.id, step = step, phase = if definition.kind == "SEAL" then "ACTIVE" else if contract.phase == "CARRYING" then "RECOVERABLE" else contract.phase,
				token = contract.token, startedAt = if finite(contract.startedAt) and contract.startedAt >= 0 and contract.startedAt <= 1e12 then contract.startedAt else 0,
			}
			if typeof(contract.carryState) == "table" and nodes[contract.carryState.nodeId] then
				normalized.contract.carryState = { nodeId = contract.carryState.nodeId }
			end
			if definition.kind ~= "SEAL" and normalized.contract.phase == "RECOVERABLE" then
				-- The runtime recovers a physical relic at a reachable activity node; never an automatic delivery.
				normalized.contract.step = 0
				normalized.contract.carryState = { nodeId = definition.nodes[1] }
				table.insert(notes, "Carried contract relic requires physical recovery after reload.")
			end
		else table.insert(notes, "Invalid active contract discarded without reward; inventory and earned fragments preserved.") end
	end
	local changed = not same(previous, normalized)
	profile.sanctuary = normalized
	return normalized, changed, notes
end

function Progression.snapshot(value)
	return copy(value)
end

function Progression.hasTag(id, tag)
	for _, value in Config.SpeciesTags[id] or {} do if value == tag then return true end end
	return false
end

function Progression.discoveryCount(value)
	local count = 0
	for id, discovered in value.discoveries do if Config.SpeciesTags[id] and discovered == true then count += 1 end end
	return count
end

-- Called only from the server's successful legitimate placement hook, never a remote discovery action.
function Progression.discover(profile, id)
	local value = progress(profile)
	if not Config.SpeciesTags[id] or value.discoveries[id] then return false end
	value.discoveries[id] = true
	return true
end

function Progression.setProgress(value, id)
	local definition = Config.CollectionSets[id]
	assert(definition, "Unknown collection set")
	local found, missing = {}, {}
	for species in Config.SpeciesTags do
		if Progression.hasTag(species, definition.tag) then
			table.insert(if value.discoveries[species] then found else missing, species)
		end
	end
	table.sort(found); table.sort(missing)
	return { id = id, title = definition.title, current = #found, target = definition.required, complete = #found >= definition.required, found = found, missing = missing }
end

function Progression.setReports(profile)
	local value = progress(profile)
	local result = {}
	for _, id in Config.CollectionSetOrder do table.insert(result, Progression.setProgress(value, id)) end
	return result
end

local function requirement(list, id, kind, label, current, target, extra)
	local item = { id = id, kind = kind, label = label, current = current, target = target, complete = current >= target }
	if extra then for key, value in extra do item[key] = value end end
	table.insert(list, item)
end

function Progression.evaluate(profile, nextLevel)
	local value = progress(profile)
	local target = nextLevel or value.level + 1
	local definition = Config.Levels[target]
	local list = {}
	if not definition or target ~= value.level + 1 then
		return { eligible = false, nextLevel = target, requirements = list, reason = if value.level >= Config.MaximumLevel then "Your sanctuary is fully restored." else "Restore the previous level first." }
	end
	requirement(list, "souls", "SOULS", "Souls", if finite(profile.souls) then profile.souls else 0, definition.souls)
	requirement(list, "fragments", "FRAGMENTS", "Seal fragments", value.fragments, definition.fragments)
	requirement(list, "discoveries", "DISCOVERIES", "Species discovered", Progression.discoveryCount(value), definition.discoveries)
	if definition.contracts then requirement(list, "contracts", "MILESTONE", Config.MilestoneLabels.contracts, value.milestones.contracts, definition.contracts) end
	for _, id in Config.MilestoneOrder do
		local required = definition.milestones and definition.milestones[id]
		if required then requirement(list, id, "MILESTONE", Config.MilestoneLabels[id], value.milestones[id], required) end
	end
	for _, id in definition.sets or {} do
		local set = Progression.setProgress(value, id)
		requirement(list, id, "SET", set.title, set.current, set.target, { missing = set.missing, found = set.found })
	end
	if definition.anySets then
		local complete, alternatives = 0, {}
		for _, id in definition.anySets.ids do
			local set = Progression.setProgress(value, id); table.insert(alternatives, set)
			if set.complete then complete += 1 end
		end
		requirement(list, "anySets", "SET_OPTIONS", "Different sets completed", complete, definition.anySets.count, { alternatives = alternatives })
	end
	for _, id in definition.rituals or {} do
		requirement(list, id, "RITUAL", Config.Rituals[id].title, if value.rituals[id] then 1 else 0, 1)
	end
	local eligible = true
	for _, item in list do if not item.complete then eligible = false; break end end
	return { eligible = eligible, nextLevel = target, title = definition.title, capacity = definition.capacity, benefit = definition.benefit, requirements = list }
end

-- No yields: repeated confirmations for the old level cannot debit twice.
-- The owning service reserves/build-validates architecture and commits the profile.
function Progression.tryUpgrade(profile, nextLevel)
	local report = Progression.evaluate(profile, nextLevel)
	if not report.eligible then return false, report end
	local value = progress(profile)
	local definition = Config.Levels[report.nextLevel]
	profile.souls -= definition.souls
	value.fragments -= definition.fragments
	value.level = definition.level
	return true, report
end

function Progression.ownedPlacedSpecies(profile)
	local seen, result = {}, {}
	for _, curse in profile.curses do
		if curse.state == "PLACED" and Config.SpeciesTags[curse.definitionId] and not seen[curse.definitionId] then
			seen[curse.definitionId] = true; table.insert(result, curse.definitionId)
		end
	end
	table.sort(result)
	return result
end

function Progression.ritualEligibility(profile, id)
	local definition = Config.Rituals[id]
	if not definition then return { eligible = false, reason = "Unknown ritual.", requirements = {} } end
	local value = progress(profile)
	local owned = Progression.ownedPlacedSpecies(profile)
	local list = {}
	requirement(list, "level", "LEVEL", "Sanctuary level", value.level, definition.minimumLevel)
	requirement(list, "species", "OWNED_SPECIES", "Different owned species placed", #owned, definition.speciesRequired)
	if definition.majorRelicsRequired then requirement(list, "majorRelics", "MILESTONE", Config.MilestoneLabels.majorRelics, value.milestones.majorRelics, definition.majorRelicsRequired) end
	local eligible = true
	for _, item in list do if not item.complete then eligible = false end end
	return { eligible = eligible, completed = value.rituals[id] == true, id = id, title = definition.title, requirements = list, availableSpecies = owned }
end

function Progression.completeRitual(profile, id)
	local report = Progression.ritualEligibility(profile, id)
	if not report.eligible or report.completed then return false end
	-- Server ritual service must already have validated the complete ordered physical sequence.
	progress(profile).rituals[id] = true
	return true
end

function Progression.recordSealActivation(profile)
	local value = progress(profile)
	value.milestones.sealActivations = math.min(Config.MaximumMilestone, value.milestones.sealActivations + 1)
	return true
end

function Progression.awardContract(profile, id, token)
	local value = progress(profile)
	local active = value.contract
	local definition = Config.Contracts[id]
	-- The service advances step only after a valid nearby interaction/delivery.
	if not definition or not active or active.id ~= id or active.token ~= token
		or (active.phase ~= "ACTIVE" and active.phase ~= "CARRYING") or active.step ~= #definition.nodes then return false, 0 end
	if value.fragments + definition.rewardFragments > Config.MaximumFragments then return false, 0 end
	value.contract = nil
	value.fragments += definition.rewardFragments
	for _, milestone in { "contracts", if definition.kind == "SEAL" then "sealing" else string.lower(definition.kind) } do
		value.milestones[milestone] = math.min(Config.MaximumMilestone, value.milestones[milestone] + 1)
	end
	if definition.majorRelic then value.milestones.majorRelics = math.min(Config.MaximumMilestone, value.milestones.majorRelics + 1) end
	return true, definition.rewardFragments
end

function Progression.selectStyle(profile, id)
	if not Config.Styles[id] then return false end
	progress(profile).style = id
	return true
end

function Progression.selectFeatured(profile, uid)
	local value = progress(profile)
	if uid == nil then value.featuredUid = nil; return true end
	for _, curse in profile.curses do
		if curse.uid == uid and curse.state == "PLACED" then value.featuredUid = uid; return true end
	end
	return false
end

function Progression.capacity(level)
	return Config.Levels[level] and Config.Levels[level].capacity or Config.Levels[0].capacity
end

return Progression
