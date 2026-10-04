-- Replaceable UI adapter. Price lookup runs on the buying client so Roblox
-- returns the personalized/regional price; receipt authority stays server-side.
local Market=game:GetService('MarketplaceService');local Players=game:GetService('Players')
local O={}
function O.describe(id)
 local remote=game.ReplicatedStorage:WaitForChild('ToolsFoundation'):WaitForChild('Commerce')
 local offer=remote:InvokeServer('offer',id);if not offer.ok then return offer end
 local kind=if offer.kind=='pass'then Enum.InfoType.GamePass else Enum.InfoType.Product
 local ok,info=pcall(function()return Market:GetProductInfoAsync(offer.id,kind)end)
 if not ok or typeof(info.PriceInRobux)~='number'then return {ok=false,message='Price unavailable.'}end
 offer.priceInRobux=info.PriceInRobux;offer.name=info.Name;return offer
end
function O.prompt(id)
 local offer=O.describe(id);if not offer.ok then return offer end
 if offer.kind=='pass'then Market:PromptGamePassPurchase(Players.LocalPlayer,offer.id)
 else Market:PromptProductPurchase(Players.LocalPlayer,offer.id)end
 return {ok=true,message='Purchase dialog open; the server decides the grant.'}
end
return O
