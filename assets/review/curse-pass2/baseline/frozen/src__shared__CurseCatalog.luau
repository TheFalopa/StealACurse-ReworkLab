-- Shared display data. Gameplay decisions are made only by the server.
local Catalog = {}
local ReworkAssets = require(script.Parent.CurseExpansionAssets)

Catalog.Rarities = {
	COMMON = { label = "COMMON", color = Color3.fromRGB(200, 192, 220), glow = Color3.fromRGB(164, 117, 226) },
	RARE = { label = "RARE", color = Color3.fromRGB(113, 225, 238), glow = Color3.fromRGB(73, 168, 227) },
	LEGENDARY = { label = "LEGENDARY", color = Color3.fromRGB(255, 201, 100), glow = Color3.fromRGB(255, 153, 76) },
	MYTHIC = { label = "MYTHIC", color = Color3.fromRGB(235, 127, 245), glow = Color3.fromRGB(204, 84, 236) },
	SECRET = { label = "SECRET", color = Color3.fromRGB(245, 221, 255), glow = Color3.fromRGB(145, 73, 255) },
}

-- Development weights deliberately keep high rarities testable. These are not
-- intended as final production odds. Price and income are per physical Curse.
Catalog.Definitions = {
	cursed_doll = {
		id = "cursed_doll", displayName = "Cursed Doll", rarity = "COMMON",
		price = 100, baseSoulsPerSecond = 3, spawnWeight = 40,
		visualKey = "cursed_doll", modelColor = Color3.fromRGB(186, 164, 192),
		futureEffectId = "DOLL_WHISPER",
	},
	haunted_mirror = {
		id = "haunted_mirror", displayName = "Haunted Mirror", rarity = "RARE",
		price = 450, baseSoulsPerSecond = 10, spawnWeight = 18,
		visualKey = "haunted_mirror", modelColor = Color3.fromRGB(117, 145, 176),
		futureEffectId = "REVERSED",
	},
	crying_mask = {
		id = "crying_mask", displayName = "Crying Mask", rarity = "RARE",
		price = 650, baseSoulsPerSecond = 14, spawnWeight = 16,
		visualKey = "crying_mask", modelColor = Color3.fromRGB(193, 203, 213),
		futureEffectId = "BLINDNESS",
	},
	watching_eye = {
		id = "watching_eye", displayName = "Watching Eye", rarity = "LEGENDARY",
		price = 2500, baseSoulsPerSecond = 45, spawnWeight = 12,
		visualKey = "watching_eye", modelColor = Color3.fromRGB(118, 104, 158),
		futureEffectId = "WATCHED",
	},
	soul_chains = {
		id = "soul_chains", displayName = "Soul Chains", rarity = "MYTHIC",
		price = 10000, baseSoulsPerSecond = 150, spawnWeight = 9,
		visualKey = "soul_chains", modelColor = Color3.fromRGB(92, 107, 139),
		futureEffectId = "HEAVY",
	},
	the_void = {
		id = "the_void", displayName = "The Void", rarity = "SECRET",
		price = 50000, baseSoulsPerSecond = 750, spawnWeight = 5,
		visualKey = "the_void", modelColor = Color3.fromRGB(52, 39, 79),
		futureEffectId = "VOID_DISTORTION",
	},
}

Catalog.Order = {
	"cursed_doll", "haunted_mirror", "crying_mask",
	"watching_eye", "soul_chains", "the_void",
}

-- All 56 identities share the same gameplay. Current-source evidence controls
-- which expansion entries can join the procession.
Catalog.AllOrder = table.clone(Catalog.Order)
Catalog.ExpansionOrder = {}
Catalog.FirstWaveOrder = {
	"candle_wisp", "grave_hopper", "grave_key", "ink_imp", "ashen_book",
	"marrow_dice", "grave_compass", "hollow_violin", "raven_quill",
	"night_harp", "thorn_cathedral", "judgement_scales",
	"cathedral_heart", "hollow_throne", "nameless_door",
}
Catalog.ExpansionManifest = {}

local referenceFiles = {
	"rework-01-common.png",
	"rework-02-common.png",
	"rework-03-common.png",
	"rework-04-rare.png",
	"rework-05-rare.png",
	"rework-06-rare.png",
	"rework-07-legendary.png",
	"rework-08-legendary.png",
	"rework-09-mythic.png",
	"rework-10-mythic.png",
	"rework-11-secret.png",
	"rework-12-secret.png",
}

-- Exact current design name, rarity and reviewed rework sheet; older expansion
-- sheets remain historical references and never override these designs.
local concepts = {
	{ "candle_wisp", "Candle Wisp", "COMMON", 1 },
	{ "grave_hopper", "Grave Hopper", "COMMON", 1 },
	{ "grave_key", "Grave Key", "COMMON", 1 },
	{ "mourning_ribbon", "Mourning Ribbon", "COMMON", 1 },
	{ "wilted_sprout", "Wilted Sprout", "COMMON", 1 },
	{ "ink_imp", "Ink Imp", "COMMON", 2 },
	{ "lost_locket", "Lost Locket", "COMMON", 2 },
	{ "ashen_book", "Ashen Book", "COMMON", 2 },
	{ "lantern_lurker", "Lantern Lurker", "COMMON", 2 },
	{ "hourglass_hound", "Hourglass Hound", "COMMON", 2 },
	{ "nail_beetle", "Nail Beetle", "COMMON", 3 },
	{ "pale_guest", "Pale Guest", "COMMON", 3 },
	{ "cold_teacup", "Cold Teacup", "COMMON", 3 },
	{ "coin_crawler", "Coin Crawler", "COMMON", 3 },
	{ "umbrella_wraith", "Umbrella Wraith", "COMMON", 3 },
	{ "marrow_dice", "Marrow Dice", "RARE", 4 },
	{ "veil_mourner", "Veil Mourner", "RARE", 4 },
	{ "grave_compass", "Grave Compass", "RARE", 4 },
	{ "hollow_violin", "Hollow Violin", "RARE", 4 },
	{ "chime_triplets", "Chime Triplets", "RARE", 4 },
	{ "thimble_spider", "Thimble Spider", "RARE", 5 },
	{ "music_box_dancer", "Music Box Dancer", "RARE", 5 },
	{ "raven_quill", "Raven Quill", "RARE", 5 },
	{ "sorrow_chalice", "Sorrow Chalice", "RARE", 5 },
	{ "pale_gramophone", "Pale Gramophone", "RARE", 5 },
	{ "thorn_reliquary", "Thorn Reliquary", "RARE", 6 },
	{ "anchor_crab", "Anchor Crab", "RARE", 6 },
	{ "sundial_sentinel", "Sundial Sentinel", "RARE", 6 },
	{ "sleepwalker_shoes", "Sleepwalker Shoes", "RARE", 6 },
	{ "night_harp", "Night Harp", "LEGENDARY", 7 },
	{ "thorn_cathedral", "Thorn Cathedral", "LEGENDARY", 7 },
	{ "phantom_marionette", "Phantom Marionette", "LEGENDARY", 7 },
	{ "blood_moon_rose", "Blood Moon Rose", "LEGENDARY", 7 },
	{ "judgement_scales", "Judgement Scales", "LEGENDARY", 7 },
	{ "clockwork_raven", "Clockwork Raven", "LEGENDARY", 8 },
	{ "eclipse_stag", "Eclipse Stag", "LEGENDARY", 8 },
	{ "endless_library", "Endless Library", "LEGENDARY", 8 },
	{ "sunken_crown", "Sunken Crown", "LEGENDARY", 8 },
	{ "silent_choir", "Silent Choir", "LEGENDARY", 8 },
	{ "cathedral_heart", "Cathedral Heart", "MYTHIC", 9 },
	{ "plague_monarch", "Plague Monarch", "MYTHIC", 9 },
	{ "hollow_throne", "Hollow Throne", "MYTHIC", 9 },
	{ "worldroot", "Worldroot", "MYTHIC", 10 },
	{ "the_undertow", "The Undertow", "MYTHIC", 10 },
	{ "the_last_funeral", "The Last Funeral", "MYTHIC", 10 },
	{ "nameless_door", "Nameless Door", "SECRET", 11 },
	{ "crown_of_silence", "Crown of Silence", "SECRET", 11 },
	{ "the_first_grave", "The First Grave", "SECRET", 11 },
	{ "the_unwritten", "The Unwritten", "SECRET", 12 },
	{ "the_last_star", "The Last Star", "SECRET", 12 },
}

-- All labeled concepts in the supplied sheets are represented: the prose list
-- omits three sheet10 Mythics. Those three are distinct planned entries too.
local economy = {
	COMMON = { price = 80, priceStep = 15, income = 2, incomeStep = 0.25 },
	RARE = { price = 400, priceStep = 100, income = 10, incomeStep = 2 },
	LEGENDARY = { price = 2200, priceStep = 650, income = 40, incomeStep = 10 },
	MYTHIC = { price = 12500, priceStep = 6000, income = 180, incomeStep = 70 },
	SECRET = { price = 60000, priceStep = 20000, income = 850, incomeStep = 250 },
}
local rarityIndex = {}
for _, concept in concepts do
	local id, name, rarity, reference = concept[1], concept[2], concept[3], concept[4]
	assert(not Catalog.Definitions[id], "Duplicate Curse concept: " .. id)
	local index = rarityIndex[rarity] or 0
	rarityIndex[rarity] = index + 1
	local values = economy[rarity]
	local asset = ReworkAssets[id]
	assert(asset and asset.sourceReference == referenceFiles[reference], "Current reference mapping missing: " .. id)
	local weights = { COMMON = 4, RARE = 2, LEGENDARY = 1, MYTHIC = 0.4, SECRET = 0.1 }
	local definition = {
		id = id, displayName = name, rarity = rarity, visualKey = id,
		price = values.price + index * values.priceStep,
		baseSoulsPerSecond = values.income + index * values.incomeStep,
		spawnWeight = if asset.enabled then weights[rarity] else 0, enabled = asset.enabled, futureEffectId = "FUTURE_" .. string.upper(id),
		modelColor = Color3.new(1, 1, 1), isExpansion = true,
		originalVertexColors = asset.originalVertexColors,
		productionWave = if asset.meshId ~= "" then 2 else 0,
		implementationStatus = asset.status,
		fbxSha256 = asset.fbxSha256,
		meshId = asset.meshId,
		sourceReference = referenceFiles[reference],
		vfxProfile = asset.vfxProfile,
		vfxHook = asset.vfxHook,
		vfxHooks = asset.vfxHooks,
		vfxGlow = Catalog.Rarities[rarity].glow,
	}
	Catalog.Definitions[id] = definition
	Catalog.ExpansionManifest[id] = {
		id = id, displayName = name, rarity = rarity, visualKey = id,
		sourceReference = definition.sourceReference,
		status = definition.implementationStatus, enabled = definition.enabled,
		productionWave = definition.productionWave,
	}
	table.insert(Catalog.ExpansionOrder, id)
	table.insert(Catalog.AllOrder, id)
end

function Catalog.enabledSpawnIds(): { string }
	local ids = {}
	for _, id in Catalog.AllOrder do
		local definition = Catalog.Definitions[id]
		if definition.enabled ~= false and definition.spawnWeight > 0 then
			table.insert(ids, id)
		end
	end
	return ids
end

return Catalog
