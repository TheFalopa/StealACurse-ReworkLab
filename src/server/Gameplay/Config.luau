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
}
