-- Boundary between the gameplay-owned offer catalogue and the store UI.
-- The UI never decides prices, ownership or purchases; it only renders offers.
--
-- Offer contract (fields the UI reads; all others are ignored):
--   OfferKey: string             stable identifier
--   DisplayName: string
--   Description: string
--   OfferType: "GamePass" | "DevProduct"
--   Owned: boolean?              GamePass owned by the local player
--   Available: boolean?          false/nil => COMING SOON
--   Price: number?               shown only when Available
--   Currency: string?            defaults to "Robux"
--   IconPresentationKey: string? key in Shared.VisualAssets.Icons
--   Badge: string?, AccentKey: string?   optional presentation hints
--
-- Provider (owned by codex/gameplay, not implemented here):
--   ReplicatedStorage.StoreOffers : ModuleScript returning
--     { getOffers: () -> {Offer}, Changed: RBXScriptSignal?, prompt: (offerKey: string) -> () }
--   prompt() is where the gameplay branch calls MarketplaceService. Until the
--   module exists the adapter serves StorePresentationConfig.PreviewOffers.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(script.Parent.StorePresentationConfig)

local OfferAdapter = {}
local listeners = {}
local provider = nil

local function loadProvider()
	local module = ReplicatedStorage:FindFirstChild("StoreOffers")
	if not module or not module:IsA("ModuleScript") then return nil end
	local ok, result = pcall(require, module)
	if ok and typeof(result) == "table" and typeof(result.getOffers) == "function" then return result end
	warn("StoreOffers provider is not usable; showing previews: " .. tostring(result))
	return nil
end

local function notify()
	for _, callback in listeners do task.spawn(callback) end
end

function OfferAdapter.hasProvider(): boolean
	return provider ~= nil
end

function OfferAdapter.offers(offerType: string)
	local source = if provider then provider.getOffers() else Config.PreviewOffers
	local list = {}
	for _, offer in source do
		if offer.OfferType == offerType and typeof(offer.OfferKey) == "string" then table.insert(list, offer) end
	end
	return list
end

function OfferAdapter.isPurchasable(offer): boolean
	return provider ~= nil and offer.Available == true and offer.Owned ~= true and typeof(offer.Price) == "number"
end

-- Returns true when the request was handed to the gameplay provider.
function OfferAdapter.request(offerKey: string): boolean
	if provider and typeof(provider.prompt) == "function" then
		task.spawn(provider.prompt, offerKey)
		return true
	end
	return false
end

function OfferAdapter.onChanged(callback)
	table.insert(listeners, callback)
end

provider = loadProvider()
if provider and provider.Changed then provider.Changed:Connect(notify) end
ReplicatedStorage.ChildAdded:Connect(function(child)
	if child.Name == "StoreOffers" and not provider then
		provider = loadProvider()
		if provider and provider.Changed then provider.Changed:Connect(notify) end
		notify()
	end
end)

return OfferAdapter
