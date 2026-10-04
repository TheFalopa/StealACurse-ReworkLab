-- Gameplay tuning in one place; the environment's Map.Config stays untouched.
return {
	StartingSouls = 500,
	SoulsTickSeconds = 0.25,
	ProcessionCadenceSeconds = 3,
	FirstProcessionDelaySeconds = 3,
	ProcessionStepSeconds = 0.08,
	-- "weighted" uses CurseCatalog spawnWeight x Luck; "cycle" shows every
	-- enabled Curse in order (the previous QA behaviour).
	ProcessionSelection = "weighted",
	ProcessionSpeedStudsPerSecond = 6.5,
	MaxProcessionCurses = 20,
	DeliveryStepSeconds = 0.1,
	MaxPurchaseDistanceStuds = 12,
	PurchaseAttemptCooldownSeconds = 0.3,
	SellFraction = 0.5,
	ManagementDistanceStuds = 12,
	PlacementDistanceStuds = 10,
	SellQuoteLifetimeSeconds = 15,
	MaximumOwnedCurses = 128,
	ProfileAutosaveSeconds = 20,
	-- ReworkLab isolation: live servers use a lab-only DataStore and only in
	-- universes listed here (by game.GameId). The list is empty on purpose, so
	-- a published lab place fails closed (UNAVAILABLE) instead of reading or
	-- writing any existing player profile. Studio keeps the local plugin store.
	ProfileStoreName = "StealACurseReworkLab_ProfilesV1",
	LiveProfileGameIds = {},
}
