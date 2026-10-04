-- Missions, boosts and the Wheel of Fate: one tuning file. Server services
-- validate everything; the client only renders these definitions.
--
-- Economy reference (CurseCatalog): Commons 80–120 Souls / 2–3 per s,
-- Rares ~400–1000 / 10–20, Legendary ~2.5–6K / 45–70, Mythic ~10–15K / 150+,
-- Secret ~50K / 750. Sanctuary Lv1 costs 150 Souls, Lv2 750, Lv3 2200.
-- Rewards are sized to the NEXT step, never to skip a tier.
local P = {}

---------------------------------------------------------------- Luck
-- One effective luck multiplier for the shared procession. Sources add.
-- Applied to non-Common rarity weights only (Commons keep their weight), so
-- x2 Luck roughly doubles the share of Rare-and-above without removing Commons.
P.Luck = {
	PotionBonus = 1.0,        -- each active potion adds +100% (x2)
	MaxServerMultiplier = 3,  -- cap: x3
	PotionSeconds = 300,      -- 5 minutes per potion, stacks duration
	MaxPotionStackSeconds = 1800,
	RedMoonBonus = 0.5,       -- Red Moon adds +50% while active
}

-- Weighted procession: pick a rarity tier by share, then a Curse inside the
-- tier by its CurseCatalog spawnWeight. (Catalog weights mix two scales: the
-- original six use 40..5, the expansion 4..0.1, so tiers are chosen first.)
P.SpawnRarityShare = { COMMON = 55, RARE = 28, LEGENDARY = 12, MYTHIC = 4, SECRET = 1 }

---------------------------------------------------------------- Items (consumables outside tools)
P.Items = {
	luck_potion = { name = "Luck Potion", blurb = "x2 server Luck for 5 minutes. Stacks duration.", icon = "potion" },
}

---------------------------------------------------------------- Missions
-- kind: claim_and_place | souls_rate | sanctuary_level | unique_curses | rarity_owned | red_moon | steal
-- rewards: { souls = n, items = { luck_potion = n }, tools = { impact_urn = n }, spins = n }
P.NpcName = "Mortimer"
P.NpcTitle = "The Gravekeeper"
P.Missions = {
	{
		id = "first_binding", title = "The First Binding",
		line = "Every keeper needs a shrine. Claim one, then bind a Curse to it.",
		objective = "Claim a sanctuary and place a Curse", kind = "claim_and_place", target = 1,
		rewards = { souls = 250, items = { luck_potion = 1 } }, cinematic = "first_binding",
	},
	{
		id = "feed_the_shrine", title = "Feed the Shrine",
		line = "Bound Curses breathe Souls. Let me hear yours breathe louder.",
		objective = "Reach 30 Souls/s", kind = "souls_rate", target = 30,
		rewards = { souls = 1000, tools = { impact_urn = 3 } },
	},
	{
		id = "strengthen_walls", title = "Strengthen the Walls",
		line = "A shrine with cracked walls invites thieves. Restore it.",
		objective = "Restore your sanctuary to Level 2", kind = "sanctuary_level", target = 2,
		rewards = { souls = 2000, spins = 1 }, cinematic = "wheel_unlock",
	},
	{
		id = "growing_collection", title = "A Growing Collection",
		line = "Collectors are remembered. Hoarders are envied. Be both.",
		objective = "Own 5 different Curses", kind = "unique_curses", target = 5,
		rewards = { souls = 3500, items = { luck_potion = 1 } },
	},
	{
		id = "rarer_blood", title = "Rarer Blood",
		line = "Commons whisper. Legends scream. Bring me a scream.",
		objective = "Own a Legendary Curse or better", kind = "rarity_owned", target = 1, rarity = "LEGENDARY",
		rewards = { souls = 8000, items = { luck_potion = 2 } },
	},
}
-- Optional side mission, offered while a Red Moon is active.
P.EventMission = {
	id = "blood_above", title = "The Blood Above",
	line = "The moon bleeds tonight. Stand beneath it and come back changed.",
	objective = "Stay online during a Red Moon", kind = "red_moon", target = 60,
	rewards = { souls = 1500, items = { luck_potion = 1 } },
}

---------------------------------------------------------------- Wheel of Fate
-- Real, server-side probabilities. displayProbability is derived from weight.
-- `grant` kinds: souls | luck_potion | tool | spin | boost | prank
P.Wheel = {
	Name = "Wheel of Fate",
	-- Daily free spin resets at 00:00 UTC (server clock). Documented in docs.
	FreeSpinsPerDay = 1,
	PaidSpinsEnabled = false, -- never enable without real product IDs + policy review
	SpinSeconds = 5.2,
	Sectors = {
		{ id = "souls_small", label = "250 Souls", rarity = "COMMON", weight = 26, grant = "souls", amount = 250, icon = "soul" },
		{ id = "spirits_laugh", label = "The spirits laugh", rarity = "CURSED", weight = 14, grant = "prank", prank = "laugh", icon = "red_moon" },
		{ id = "urns", label = "3 Impact Urns", rarity = "COMMON", weight = 16, grant = "tool", tool = "impact_urn", amount = 3, icon = "tool_pack" },
		{ id = "souls_mid", label = "1,500 Souls", rarity = "GOOD", weight = 14, grant = "souls", amount = 1500, icon = "soul_jar" },
		{ id = "heavy_feet", label = "Heavy feet (15s)", rarity = "CURSED", weight = 10, grant = "prank", prank = "heavy_feet", icon = "speed" },
		{ id = "luck_potion", label = "Luck Potion", rarity = "GOOD", weight = 11, grant = "luck_potion", amount = 1, icon = "potion" },
		{ id = "souls_big", label = "6,000 Souls", rarity = "RARE", weight = 6, grant = "souls", amount = 6000, icon = "double_souls" },
		{ id = "extra_spin", label = "Spin again", rarity = "RARE", weight = 3, grant = "spin", amount = 1, icon = "gamepass" },
	},
}
P.WheelRarityColors = {
	COMMON = Color3.fromRGB(96, 104, 140), GOOD = Color3.fromRGB(70, 170, 150),
	RARE = Color3.fromRGB(196, 140, 60), CURSED = Color3.fromRGB(150, 40, 70),
}

function P.wheelTotalWeight(): number
	local total = 0
	for _, s in P.Wheel.Sectors do total += s.weight end
	return total
end

return P
