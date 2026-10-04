-- Sole receipt controller. Catalog IDs remain zero/disabled until the owner
-- configures verified experience offers. Grant+receipt are one profile snapshot.
local Market=game:GetService('MarketplaceService');local Players=game:GetService('Players');local Run=game:GetService('RunService');local RS=game:GetService('ReplicatedStorage')
local C=require(RS.Shared.ToolCatalog);local I=require(RS.Shared.ToolInventory)
local Commerce={}
function Commerce.start(profiles,tools)
 local busy={};local service={}
 local remote=Instance.new('RemoteFunction');remote.Name='Commerce';remote.Parent=RS.ToolsFoundation
 local function configured(offer)return offer and offer.enabled==true and typeof(offer.id)=='number'and offer.id>0 and offer.id==math.floor(offer.id)end
 function service:grantReceipt(player,offerId,receiptId,simulated)
  if not player or typeof(offerId)~='string'or typeof(receiptId)~='string'or #receiptId<1 or #receiptId>110 then return false end
  local offer=C.Offers[offerId];local p=profiles:get(player)
  if not p or player:GetAttribute('ProfileStatus')~='READY' or busy[player] or not offer or offer.kind~='product'then return false end
  if simulated then
   local bridge=game.ServerStorage:FindFirstChild('LocalProfileBridge')
   if not Run:IsStudio()or not bridge or not tostring(bridge:GetAttribute('Namespace')):match('^qa%-tools')then return false end
   receiptId='studio:'..receiptId
  elseif not C.RealPurchasesEnabled or not configured(offer)or Run:IsStudio()then return false end
  busy[player]=true
  local ok,result=pcall(function()
   local accepted=I.receipt(p.tools,receiptId,offer.item,offer.amount);if not accepted then return false end
   profiles:commit(player)
   -- Never acknowledge before durable profile readback / successful UpdateAsync.
   local saved=profiles:flush(player,false);tools:publish(player);return saved
  end)
  busy[player]=nil;return ok and result==true
 end
 Market.ProcessReceipt=function(receipt)
  if typeof(receipt)~='table'or typeof(receipt.PurchaseId)~='string'or typeof(receipt.PlayerId)~='number'or typeof(receipt.ProductId)~='number'then return Enum.ProductPurchaseDecision.NotProcessedYet end
  local player=Players:GetPlayerByUserId(receipt.PlayerId);if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
  for id,offer in C.Offers do
   if configured(offer)and offer.kind=='product'and offer.id==receipt.ProductId then
    if service:grantReceipt(player,id,receipt.PurchaseId,false)then return Enum.ProductPurchaseDecision.PurchaseGranted end
   end
  end;return Enum.ProductPurchaseDecision.NotProcessedYet
 end
 function service:refreshPasses(player)
  for _,offer in C.Offers do if offer.kind=='pass'then
   local owns=false
   if C.RealPurchasesEnabled and configured(offer)then local ok,value=pcall(function()return Market:UserOwnsGamePassAsync(player.UserId,offer.id)end);owns=ok and value==true end
   tools:setPass(player,offer.item,owns)
  end end
 end
 function service:simulatePass(player,id,owns)
  local b=game.ServerStorage:FindFirstChild('LocalProfileBridge');local o=C.Offers[id]
  if not Run:IsStudio()or not b or not tostring(b:GetAttribute('Namespace')):match('^qa%-tools')or not o or o.kind~='pass'then return false end
  tools:setPass(player,o.item,owns==true);return true
 end
 remote.OnServerInvoke=function(player,action,id)
  if typeof(id)~='string'or #id>40 then return {ok=false,message='Invalid offer.'}end
  local o=C.Offers[id];if not C.RealPurchasesEnabled or not configured(o)or Run:IsStudio()then return {ok=false,message='This offer is not available yet.',enabled=false}end
  if action=='offer'then return {ok=true,id=o.id,kind=o.kind,enabled=true,item=o.item}end
  return {ok=false,message='Action not available.'}
 end
 profiles:onLoaded(function(player)task.spawn(function()service:refreshPasses(player)end)end)
 Market.PromptGamePassPurchaseFinished:Connect(function(player)task.spawn(function()service:refreshPasses(player)end)end)
 Players.PlayerRemoving:Connect(function(player)busy[player]=nil end)
 return service
end
return Commerce
