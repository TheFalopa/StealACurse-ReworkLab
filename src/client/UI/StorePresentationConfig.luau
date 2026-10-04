-- PRESENTATION-ONLY store mock. Not a catalogue of record: there are no
-- GamePass/DevProduct IDs, no prices, no ownership and no purchase logic.
-- The gameplay branch owns real offers; OfferAdapter swaps these out as soon
-- as a gameplay provider exists. Entries use the same field names as the
-- offer contract (see OfferAdapter) plus presentation-only keys.
local StorePresentationConfig = {}

StorePresentationConfig.Tabs = {
	{ key = "Passes", label = "GAMEPASSES", short = "PASSES", offerType = "GamePass" },
	{ key = "Products", label = "SHOP", short = "SHOP", offerType = "DevProduct" },
}

-- Available = false keeps every card in its COMING SOON state.
StorePresentationConfig.PreviewOffers = {
	{ OfferKey = "preview.double_souls", OfferType = "GamePass", DisplayName = "x2 Souls", Description = "Double every Soul your Curses produce.", IconPresentationKey = "double_souls", AccentKey = "cyan", Badge = "BEST" },
	{ OfferKey = "preview.vip", OfferType = "GamePass", DisplayName = "VIP", Description = "A crowned look for the most cursed collectors.", IconPresentationKey = "vip", AccentKey = "amber" },
	{ OfferKey = "preview.luck", OfferType = "GamePass", DisplayName = "Luck Boost", Description = "Rarer Curses appear more often.", IconPresentationKey = "luck", AccentKey = "soulGreen" },
	{ OfferKey = "preview.extra_slot", OfferType = "GamePass", DisplayName = "Extra Slot", Description = "One more pedestal in your sanctuary.", IconPresentationKey = "slot", AccentKey = "violet" },
	{ OfferKey = "preview.fast_delivery", OfferType = "GamePass", DisplayName = "Fast Delivery", Description = "Move faster while carrying a Curse.", IconPresentationKey = "speed", AccentKey = "cyan" },
	{ OfferKey = "preview.spectral_trail", OfferType = "GamePass", DisplayName = "Spectral Trail", Description = "A cosmetic ghost trail behind you.", IconPresentationKey = "trail", AccentKey = "magenta" },
	{ OfferKey = "preview.starter_souls", OfferType = "DevProduct", DisplayName = "Starter Souls", Description = "A small bundle of Souls.", IconPresentationKey = "soul_jar", AccentKey = "cyan", Badge = "STARTER" },
	{ OfferKey = "preview.soul_hoard", OfferType = "DevProduct", DisplayName = "Soul Hoard", Description = "A large bundle of Souls.", IconPresentationKey = "soul_jar", AccentKey = "violet" },
	{ OfferKey = "preview.luck_potion", OfferType = "DevProduct", DisplayName = "Luck Potion", Description = "Temporary luck for the next spawns.", IconPresentationKey = "potion", AccentKey = "soulGreen" },
	{ OfferKey = "preview.soul_surge", OfferType = "DevProduct", DisplayName = "Soul Surge", Description = "Temporary x2 Souls production.", IconPresentationKey = "double_souls", AccentKey = "magenta" },
	-- Tool offers mirror codex/gameplay's ToolsFoundation.Commerce ids. Real
	-- purchases are disabled there (IDs = 0, RealPurchasesEnabled = false), so
	-- they stay COMING SOON until a StoreOffers provider reports them available.
	{ OfferKey = "chain_pass", OfferType = "GamePass", DisplayName = "Jailer Chain", Description = "Tool pass: bind a rival thief in place.", IconPresentationKey = "gamepass", AccentKey = "violet" },
	{ OfferKey = "mirror_pass", OfferType = "GamePass", DisplayName = "Double Mirror", Description = "Tool pass: leave a decoy behind.", IconPresentationKey = "gamepass", AccentKey = "cyan" },
	{ OfferKey = "urn_bundle", OfferType = "DevProduct", DisplayName = "Impact Urn x10", Description = "Ten Impact Urn charges.", IconPresentationKey = "tool_pack", AccentKey = "amber" },
	{ OfferKey = "salt_bundle", OfferType = "DevProduct", DisplayName = "Consecrated Salt x10", Description = "Ten Consecrated Salt charges.", IconPresentationKey = "tool_pack", AccentKey = "cyan" },
	{ OfferKey = "talisman_bundle", OfferType = "DevProduct", DisplayName = "Break Talisman x10", Description = "Ten Break Talisman charges.", IconPresentationKey = "tool_pack", AccentKey = "magenta" },
}

return StorePresentationConfig
