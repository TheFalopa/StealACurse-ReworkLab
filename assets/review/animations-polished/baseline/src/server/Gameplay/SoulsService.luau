local Players=game:GetService('Players')
local Config=require(script.Parent.Config)
local SoulsService={}
function SoulsService.start(profiles)
 local production={};local service={}
 local function publish(player)
  local p=profiles:get(player)
  if p then player:SetAttribute('Souls',math.floor(p.souls*100+.5)/100);player:SetAttribute('SoulsPerSecond',production[player.UserId] or 0) end
 end
 profiles:onLoaded(function(player) production[player.UserId]=0;player:SetAttribute('HUDNoticeSerial',0);publish(player) end)
 function service:getBalance(player) local p=profiles:get(player);return if p then p.souls else 0 end
 function service:trySpend(player,amount)
  assert(amount>0,'Server price must be positive');local p=profiles:get(player)
  if not p or p.souls+.0001<amount then return false end
  p.souls-=amount;publish(player);return true
 end
 function service:credit(player,amount)
  assert(amount>=0,'Server credit must be nonnegative');local p=profiles:get(player);if not p then return false end
  p.souls+=amount;publish(player);return true
 end
 function service:setProduction(player,rate)
  assert(rate>=0,'Production must be nonnegative');production[player.UserId]=rate;player:SetAttribute('SoulsPerSecond',rate)
 end
 function service:notify(player,message)
  if player.Parent~=Players then return end
  player:SetAttribute('HUDNotice',message);player:SetAttribute('HUDNoticeSerial',(player:GetAttribute('HUDNoticeSerial') or 0)+1)
 end
 Players.PlayerRemoving:Connect(function(player) production[player.UserId]=nil end)
 task.spawn(function()
  local last=os.clock()
  while true do
   task.wait(Config.SoulsTickSeconds);local now=os.clock();local elapsed=math.max(0,now-last);last=now
   for _,player in Players:GetPlayers() do
    local p=profiles:get(player);local rate=production[player.UserId] or 0
    if p and rate>0 then p.souls+=rate*elapsed;publish(player) end
   end
  end
 end)
 return service
end
return SoulsService
