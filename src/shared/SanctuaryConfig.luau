-- Shared presentation/configuration only. Server services validate every action.
local Config = {}
Config.Schema = 1
Config.MaximumLevel = 10
Config.MaximumFragments = 1000000
Config.MaximumMilestone = 1000000
Config.MaximumContractTokenLength = 80
Config.StyleOrder = { "CRYPT", "FOREST", "OBSERVATORY" }
Config.Styles = {
	CRYPT = { id = "CRYPT", title = "Crypt", description = "Pale stone, dark iron and candles." },
	FOREST = { id = "FOREST", title = "Cursed Forest", description = "Roots, timber and lanterns." },
	OBSERVATORY = { id = "OBSERVATORY", title = "Observatory", description = "Dark stone and astral symbols." },
}
Config.NodeOrder = { "gravekeeper_board", "cemetery_gate", "old_well", "forest_shrine", "chapel_steps", "observatory_stone", "castle_courtyard", "sanctuary_altar" }
Config.NodeLabels = {
	gravekeeper_board = "Gravekeeper's Board", cemetery_gate = "Cemetery Gate",
	old_well = "Old Well", forest_shrine = "Forest Shrine", chapel_steps = "Chapel Steps",
	observatory_stone = "Astral Stone", castle_courtyard = "Castle Courtyard", sanctuary_altar = "Your altar",
}
Config.ThemeOrder = { "creature", "enchanted", "relic", "spirit", "nature", "music", "time", "burial" }
Config.Themes = {
	creature = "Creatures", enchanted = "Enchanted Objects", relic = "Relics", spirit = "Entities",
	nature = "Cursed Nature", music = "Forgotten Music", time = "Time & Clockwork", burial = "Funeral Memory",
}
-- All 56 logical catalog identities. Tags can overlap; one species counts once per set.
Config.SpeciesTags = {
	cursed_doll = { "enchanted", "creature" }, haunted_mirror = { "enchanted", "spirit" },
	crying_mask = { "enchanted", "spirit" }, watching_eye = { "creature", "spirit" },
	soul_chains = { "relic", "spirit", "burial" }, the_void = { "spirit" },
	candle_wisp = { "enchanted", "spirit", "burial" }, grave_hopper = { "creature", "burial", "nature" },
	grave_key = { "enchanted", "relic", "burial" }, mourning_ribbon = { "enchanted", "burial" },
	wilted_sprout = { "creature", "nature" }, ink_imp = { "creature", "enchanted" },
	lost_locket = { "enchanted", "relic" }, ashen_book = { "enchanted", "relic" },
	lantern_lurker = { "creature", "enchanted", "burial" }, hourglass_hound = { "creature", "time" },
	nail_beetle = { "creature", "nature" }, pale_guest = { "spirit", "burial" },
	cold_teacup = { "enchanted" }, coin_crawler = { "creature", "enchanted" },
	umbrella_wraith = { "enchanted", "spirit" }, marrow_dice = { "enchanted", "creature" },
	veil_mourner = { "spirit", "burial" }, grave_compass = { "relic", "time", "burial" },
	hollow_violin = { "enchanted", "music" }, chime_triplets = { "enchanted", "music" },
	thimble_spider = { "creature", "enchanted" }, music_box_dancer = { "enchanted", "music", "time" },
	raven_quill = { "enchanted", "nature" }, sorrow_chalice = { "relic", "burial" },
	pale_gramophone = { "enchanted", "music" }, thorn_reliquary = { "relic", "nature" },
	anchor_crab = { "creature", "relic", "nature" }, sundial_sentinel = { "creature", "time", "relic" },
	sleepwalker_shoes = { "enchanted", "creature" }, night_harp = { "enchanted", "music" },
	thorn_cathedral = { "creature", "relic", "nature" }, phantom_marionette = { "enchanted", "creature", "spirit" },
	blood_moon_rose = { "creature", "nature" }, judgement_scales = { "relic" },
	clockwork_raven = { "creature", "time", "nature" }, eclipse_stag = { "creature", "nature", "spirit" },
	endless_library = { "enchanted", "relic" }, sunken_crown = { "relic" },
	silent_choir = { "spirit", "music", "burial" }, cathedral_heart = { "creature", "relic" },
	plague_monarch = { "creature", "nature" }, hollow_throne = { "relic", "spirit" },
	worldroot = { "creature", "nature", "spirit" }, the_undertow = { "spirit", "relic" },
	the_last_funeral = { "creature", "relic", "burial" }, nameless_door = { "enchanted", "spirit" },
	crown_of_silence = { "relic", "spirit" }, the_first_grave = { "relic", "burial", "spirit" },
	the_unwritten = { "enchanted", "spirit" }, the_last_star = { "spirit", "relic" },
}
Config.CollectionSetOrder = { "first_companions", "haunted_house", "grave_keepers", "living_grove", "forgotten_music", "clockwork_court" }
Config.CollectionSets = {
	first_companions = { id = "first_companions", title = "Restless Companions", tag = "creature", required = 3 },
	haunted_house = { id = "haunted_house", title = "Haunted House", tag = "enchanted", required = 3 },
	grave_keepers = { id = "grave_keepers", title = "Keepers of Memory", tag = "burial", required = 3 },
	living_grove = { id = "living_grove", title = "Living Grove", tag = "nature", required = 3 },
	forgotten_music = { id = "forgotten_music", title = "Lost Melodies", tag = "music", required = 2 },
	clockwork_court = { id = "clockwork_court", title = "Ownerless Clocks", tag = "time", required = 2 },
}
Config.ContractOrder = {
	"lost_seal", "well_relic", "forest_relic", "chapel_lantern", "forest_lantern", "astral_lantern",
	"cemetery_marks", "forest_marks", "astral_marks", "greater_relic", "ancient_relic", "grand_marks",
}
Config.Contracts = {
	lost_seal = { id = "lost_seal", title = "A Lost Piece", kind = "RECOVERY", minLevel = 0, rewardFragments = 4, nodes = { "cemetery_gate", "sanctuary_altar" }, description = "Recover a piece of the seal and bring it to your altar." },
	well_relic = { id = "well_relic", title = "Memory of the Well", kind = "RECOVERY", minLevel = 1, rewardFragments = 5, nodes = { "old_well", "sanctuary_altar" }, description = "Take the reliquary from the well and deliver it to your altar." },
	forest_relic = { id = "forest_relic", title = "Root of Memory", kind = "RECOVERY", minLevel = 3, rewardFragments = 8, nodes = { "forest_shrine", "sanctuary_altar" }, description = "Return the forest's memory to your altar." },
	chapel_lantern = { id = "chapel_lantern", title = "Light for the Chapel", kind = "TRANSPORT", minLevel = 0, rewardFragments = 4, nodes = { "gravekeeper_board", "chapel_steps" }, description = "Carry the Gravekeeper's lantern to the chapel." },
	forest_lantern = { id = "forest_lantern", title = "Lantern Among Roots", kind = "TRANSPORT", minLevel = 2, rewardFragments = 7, nodes = { "gravekeeper_board", "forest_shrine" }, description = "Light the forest shrine with a ritual lantern." },
	astral_lantern = { id = "astral_lantern", title = "Starlight", kind = "TRANSPORT", minLevel = 5, rewardFragments = 11, nodes = { "gravekeeper_board", "observatory_stone" }, description = "Carry the astral lantern to the observatory stone." },
	cemetery_marks = { id = "cemetery_marks", title = "Three Graveyard Marks", kind = "SEAL", minLevel = 0, rewardFragments = 5, nodes = { "cemetery_gate", "old_well", "castle_courtyard" }, description = "Activate the three marks in order." },
	forest_marks = { id = "forest_marks", title = "The Sealed Path", kind = "SEAL", minLevel = 3, rewardFragments = 9, nodes = { "old_well", "forest_shrine", "chapel_steps" }, description = "Follow the marks from the well to the chapel." },
	astral_marks = { id = "astral_marks", title = "Earthbound Constellation", kind = "SEAL", minLevel = 6, rewardFragments = 12, nodes = { "chapel_steps", "observatory_stone", "castle_courtyard" }, description = "Join the constellation's three marks in order." },
	greater_relic = { id = "greater_relic", title = "The Greater Relic", kind = "RECOVERY", minLevel = 6, rewardFragments = 14, majorRelic = true, nodes = { "observatory_stone", "sanctuary_altar" }, description = "Recover a greater relic and carry it to your altar." },
	ancient_relic = { id = "ancient_relic", title = "Memory of the Castle", kind = "RECOVERY", minLevel = 8, rewardFragments = 14, majorRelic = true, nodes = { "castle_courtyard", "sanctuary_altar" }, description = "Carry the castle's ancient memory to your altar." },
	grand_marks = { id = "grand_marks", title = "The Full Circle", kind = "SEAL", minLevel = 8, rewardFragments = 14, nodes = { "forest_shrine", "castle_courtyard", "observatory_stone" }, description = "Complete the circle of forest, castle and observatory." },
}
Config.RitualOrder = { "first_vigil", "collection_vigil", "relic_consecration", "grand_seal", "dominion" }
Config.Rituals = {
	first_vigil = { id = "first_vigil", title = "First Vigil", minimumLevel = 0, speciesRequired = 1, sequence = { 1, 2 }, description = "Present one placed species of your own and activate two altar marks." },
	collection_vigil = { id = "collection_vigil", title = "Collection Vigil", minimumLevel = 3, speciesRequired = 3, sequence = { 1, 3, 2 }, description = "Present three different species from your collection and follow the marks." },
	relic_consecration = { id = "relic_consecration", title = "Relic Consecration", minimumLevel = 6, speciesRequired = 4, sequence = { 2, 1, 3, 2 }, majorRelicsRequired = 1, description = "Deliver a greater relic first, present four species and consecrate their marks." },
	grand_seal = { id = "grand_seal", title = "The Great Seal", minimumLevel = 8, speciesRequired = 5, sequence = { 3, 1, 2, 3, 2 }, description = "Five species hold the seal: activate their marks in order." },
	dominion = { id = "dominion", title = "Dominion Vigil", minimumLevel = 9, speciesRequired = 6, sequence = { 1, 2, 3, 1, 3, 2 }, majorRelicsRequired = 2, description = "Gather six species of your own and complete the final vigil." },
}
Config.Levels = {
	[0] = { level = 0, title = "Unrestored Sanctuary", capacity = 5, souls = 0, fragments = 0, discoveries = 0, benefit = "Five pedestals and a recoverable collection." },
	[1] = { level = 1, title = "Restored Courtyard", capacity = 6, souls = 150, fragments = 0, discoveries = 1, rituals = { "first_vigil" }, benefit = "Courtyard, entrance and altar restored; six pedestals." },
	[2] = { level = 2, title = "Collection Wing", capacity = 8, souls = 750, fragments = 6, discoveries = 3, contracts = 1, sets = { "haunted_house" }, benefit = "A new collection wing and eight pedestals." },
	[3] = { level = 3, title = "Enclosed Sanctuary", capacity = 10, souls = 2200, fragments = 14, discoveries = 5, contracts = 3, milestones = { recovery = 1, sealing = 1 }, benefit = "Facade, windows and a partial roof; ten pedestals." },
	[4] = { level = 4, title = "Upper Gallery", capacity = 14, souls = 6500, fragments = 24, discoveries = 7, sets = { "first_companions", "haunted_house" }, rituals = { "collection_vigil" }, benefit = "A second floor with a wide stair; fourteen pedestals." },
	[5] = { level = 5, title = "Expanded Gallery", capacity = 18, souls = 13000, fragments = 36, discoveries = 10, contracts = 8, sets = { "living_grove", "forgotten_music" }, milestones = { transport = 2 }, benefit = "An expanded second floor and eighteen pedestals." },
	[6] = { level = 6, title = "Protective Seal", capacity = 18, souls = 22000, fragments = 48, discoveries = 12, milestones = { sealing = 3, sealActivations = 9 }, benefit = "Seal the entrance for 30 seconds, followed by 60 seconds of vulnerability." },
	[7] = { level = 7, title = "Relic Hall", capacity = 22, souls = 45000, fragments = 70, discoveries = 15, contracts = 14, milestones = { majorRelics = 1 }, rituals = { "relic_consecration" }, benefit = "A third floor with a relic hall; twenty-two pedestals." },
	[8] = { level = 8, title = "Expanded Chamber", capacity = 26, souls = 80000, fragments = 90, discoveries = 20, anySets = { count = 3, ids = Config.CollectionSetOrder }, benefit = "An expanded third floor and twenty-six pedestals." },
	[9] = { level = 9, title = "Consecrated Sanctuary", capacity = 26, souls = 140000, fragments = 120, discoveries = 24, contracts = 22, milestones = { sealActivations = 18 }, rituals = { "grand_seal" }, benefit = "A consecrated emblem and a 40-second seal, followed by 60 seconds of vulnerability." },
	[10] = { level = 10, title = "Dominion of Curses", capacity = 30, souls = 220000, fragments = 160, discoveries = 28, contracts = 30, milestones = { majorRelics = 2 }, anySets = { count = 5, ids = Config.CollectionSetOrder }, rituals = { "collection_vigil", "relic_consecration", "grand_seal", "dominion" }, benefit = "Complete architecture and thirty pedestals; no income multiplier." },
}
Config.Protection = { minimumLevel = 6, duration = 30, consagratedLevel = 9, consagratedDuration = 40, vulnerabilitySeconds = 60 }
Config.MilestoneOrder = { "contracts", "recovery", "transport", "sealing", "majorRelics", "sealActivations" }
Config.MilestoneLabels = {
	contracts = "Contracts completed", recovery = "Recoveries completed", transport = "Deliveries completed",
	sealing = "Seal sequences completed", majorRelics = "Greater relics delivered", sealActivations = "Seal marks activated",
}
return Config
