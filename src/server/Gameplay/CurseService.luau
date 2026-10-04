local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Http=game:GetService('HttpService')
local Catalog=require(RS.Shared.CurseCatalog)
local NumberFormat=require(RS.Shared.NumberFormat)
local Config=require(script.Parent.Config)
local Visual=require(script.Parent.CurseVisualService)
local CarryGeometry=require(RS.Shared.CurseCarryGeometry)
local Rules=require(script.Parent.OwnedCurseRules)
local CurseService={}
function CurseService.start(map,bases,souls,profiles)
 assert(map.Parent==workspace,'Completed map required')
 local folder=Instance.new('Folder');folder.Name='ActiveCurses';folder.Parent=map
 local records,runtime,carried,occupied,quotes,lastRequest,clearing={},{},{},{},{},{},{}
 local remoteFolder=Instance.new('Folder');remoteFolder.Name='CurseManagement';remoteFolder.Parent=RS
 local request=Instance.new('RemoteFunction');request.Name='Request';request.Parent=remoteFolder
 local open=Instance.new('RemoteEvent');open.Name='Open';open.Parent=remoteFolder
 local service={}
 local function definition(r) return Catalog.Definitions[r.definitionId] end
 local function rootOf(p)
  if p.Parent~=Players or p:GetAttribute('ProfileStatus')~='READY' then return nil end
  local c=p.Character;local h=c and c:FindFirstChildOfClass('Humanoid');local r=c and c:FindFirstChild('HumanoidRootPart')
  return if h and h.Health>0 and r and r:IsA('BasePart') then r else nil
 end
 local function result(ok,message,data) return {ok=ok,message=message,data=data} end
 local function destroyRuntime(uid)
  local rt=runtime[uid];if not rt then return end
  for _,c in rt.connections or {} do c:Disconnect() end
  if rt.model then rt.model:Destroy() end
  runtime[uid]=nil
 end
 local function production(p)
  local total=0
  for _,r in records do if r.ownerUserId==p.UserId and r.state=='PLACED' and not r.stealingUserId then total+=definition(r).baseSoulsPerSecond end end
  souls:setProduction(p,total)
 end
 local function saveOwned(p)
  local profile=profiles:get(p);if not profile then return end
  local list={}
  for _,r in records do
   if r.ownerUserId==p.UserId then
    table.insert(list,{uid=r.uid,definitionId=r.definitionId,state=if r.state=='PLACED' or r.state=='WAITING_PLACEMENT' then 'PLACED' else 'UNPLACED',
     pedestalId=if r.state=='PLACED' or r.state=='WAITING_PLACEMENT' then r.pedestalId else nil,revision=r.revision})
   end
  end
  table.sort(list,function(a,b)return a.uid<b.uid end)
  profile.curses=list;profiles:commit(p)
  if service.onOwnedChanged then service.onOwnedChanged(p) end
 end
 local function ownedCount(p)
  local count=0;for _,r in records do if r.ownerUserId==p.UserId then count+=1 end end;return count
 end
 local function publish(r,intentional)
  local rt=runtime[r.uid];if not rt then return end
  local m=rt.model;local d=definition(r)
  m:SetAttribute('OwnerUserId',r.ownerUserId);m:SetAttribute('CarrierUserId',r.carrierUserId)
  m:SetAttribute('StealingUserId',r.stealingUserId)
  m:SetAttribute('CarryBaseId',if r.stealingUserId then bases:getBaseIdForPlayer(Players:GetPlayerByUserId(r.stealingUserId))else nil)
  m:SetAttribute('PedestalId',r.pedestalId);m:SetAttribute('BaseId',r.baseId)
  m:SetAttribute('StateRevision',r.revision);m:SetAttribute('StateStartedAt',workspace:GetServerTimeNow())
  m:SetAttribute('OperationLocked',r.locked or r.stealingUserId~=nil)
  Visual.setState(m,d,r.state)
  rt.manage.Enabled=r.ownerUserId~=nil and (r.state=='PLACED' or r.state=='UNPLACED') and not r.locked and not r.stealingUserId
  rt.manage.ActionText=if r.state=='UNPLACED' then 'Pick up' else 'Manage'
  if rt.steal then rt.steal.Enabled=r.state=='PLACED' and not r.locked and not r.stealingUserId end
  if intentional then m:SetAttribute('MotionRevision',(m:GetAttribute('MotionRevision') or 0)+1) end
  local panel=m.CurseInfo.Panel
  panel.InfoIncome.Text=if r.state=='PLACED' or r.state=='PROCESSION' then '+'..NumberFormat.compact(d.baseSoulsPerSecond)..' Souls/s' else 'No income'
  panel.InfoPrice.Text=if r.state=='UNPLACED' then 'Unplaced' else if r.state=='CARRYING' then 'Being carried' else NumberFormat.compact(d.price)..' Souls'
 end
 local function pedestal(base,id)
  if not base or not base.Parent or typeof(id)~='string' then return nil end
  return bases:getPedestals(base)[id]
 end
 local function markPedestal(r,uid)
  local base=bases:getBaseById(r.baseId)
  local part=base and pedestal(base,r.pedestalId)
  if part then part:SetAttribute('OccupiedCurseUid',uid);part:SetAttribute('PedestalOwnerUserId',base:GetAttribute('OwnerUserId')) end
 end
 local function releasePedestal(r)
  if r.baseId and r.pedestalId then
   local slots=occupied[r.baseId]
   if slots and slots[r.pedestalId]==r.uid then slots[r.pedestalId]=nil;markPedestal(r,nil) end
  end
  r.pedestalId=nil
 end
 local function freeSlot(base)
  local list={};for id in bases:getPedestals(base) do table.insert(list,id) end;table.sort(list)
  local slots=occupied[base.Name] or {}
  for _,id in list do if not slots[id] then return id end end
  return nil
 end
 local function onPlinth(r,base)
  local p=pedestal(base,r.pedestalId);local rt=runtime[r.uid]
  if not p or not rt or not rt.model.PrimaryPart then return false end
  local rise=p.Size.Y*.5+rt.model.PrimaryPart.Size.Y*.5+.18
  local index=p:GetAttribute('LegacySlotIndex')
  Visual.move(rt.model,p.CFrame*CFrame.new(0,rise,0)*CFrame.Angles(0,if index then math.rad((index-1)*15) else 0,0),true)
  return true
 end
 local function createRuntime(r)
  local m,prompt=Visual.create(definition(r),folder)
  m:SetAttribute('CurseUid',r.uid);m:SetAttribute('DefinitionId',r.definitionId)
  local manage=Instance.new('ProximityPrompt');manage.Name='ManageCurse';manage.ObjectText=definition(r).displayName
  manage.ActionText='Manage';manage.KeyboardKeyCode=Enum.KeyCode.E;manage.HoldDuration=0
  manage.MaxActivationDistance=Config.ManagementDistanceStuds;manage.RequiresLineOfSight=false
  manage.Exclusivity=Enum.ProximityPromptExclusivity.OnePerButton;manage.UIOffset=Vector2.new(0,100);manage.Enabled=false;manage.Parent=m.PrimaryPart
  local rt={model=m,prompt=prompt,manage=manage,connections={}};runtime[r.uid]=rt
  local steal=Instance.new('ProximityPrompt');steal.Name='StealCurse';steal.ActionText='Steal';steal.ObjectText=definition(r).displayName
  steal.KeyboardKeyCode=Enum.KeyCode.F;steal.HoldDuration=.6;steal.MaxActivationDistance=Config.ManagementDistanceStuds;steal.RequiresLineOfSight=true;steal.Parent=m.PrimaryPart;rt.steal=steal
  table.insert(rt.connections,steal.Triggered:Connect(function(p)if service.onTheftStart then service.onTheftStart(p,r.uid)end end))
  table.insert(rt.connections,prompt.Triggered:Connect(function(p)service:purchase(p,r.uid)end))
  table.insert(rt.connections,manage.Triggered:Connect(function(p)
   if r.state=='UNPLACED' then
    local answer=service:action(p,'pickup',r.uid);if not answer.ok then souls:notify(p,answer.message) end
   elseif r.state=='PLACED' then
    local answer=service:action(p,'inspect',r.uid);if answer.ok then open:FireClient(p,r.uid)else souls:notify(p,answer.message)end
   end
  end))
  publish(r)
  return m
 end
 local function recovery(r,base,index)
  if runtime[r.uid] and (not runtime[r.uid].model.Parent or not runtime[r.uid].model.PrimaryPart) then destroyRuntime(r.uid) end
  if runtime[r.uid] and runtime[r.uid].recoveryBay then return true end
  local used={}
  for uid,rt in runtime do
   local other=records[uid]
   if other and other.baseId==base.Name and other.state=='UNPLACED' and rt.recoveryBay then used[rt.recoveryBay]=true end
  end
  local bay
  for i=1,6 do if not used[i] then bay=i;break end end
  if not bay then destroyRuntime(r.uid);return false end
  if not runtime[r.uid] then createRuntime(r) end
  local m=runtime[r.uid].model;runtime[r.uid].recoveryBay=bay
  Visual.move(m,bases:getRecoveryFrame(base,m.PrimaryPart.Size,bay),true)
  publish(r,true)
  return true
 end
 local function fillRecovery(p,base)
  local list={}
  for uid,r in records do if r.ownerUserId==p.UserId and r.state=='UNPLACED' then table.insert(list,uid) end end
  table.sort(list)
  for _,uid in list do recovery(records[uid],base) end
  local waiting=0;for _,uid in list do if not runtime[uid] then waiting+=1 end end
  return waiting
 end
 local function drop(p,reason)
  if p:GetAttribute('StolenCurseUid') and service.onTheftInterrupt then service.onTheftInterrupt(p,reason);return end
  local uid=carried[p.UserId];if not uid then return end
  local r=records[uid];carried[p.UserId]=nil;p:SetAttribute('CarriedCurseUid',nil)
  if not r or r.ownerUserId~=p.UserId then return end
  r.state='UNPLACED';r.carrierUserId=nil;r.pedestalId=nil;r.revision+=1
  local base=bases:getBaseForPlayer(p);local rt=runtime[uid]
  if base then
   -- A safe recovery area requires walking back and picking it up manually.
   -- This is never the original pedestal and never resumes production.
   local ok,err=pcall(recovery,r,base,1)
   if not ok then warn('Unplaced visual recovery pending; ownership retained: '..tostring(err)) end
  elseif rt and rt.model.Parent and rt.model.PrimaryPart then publish(r,true) end
  production(p);saveOwned(p)
  if reason then souls:notify(p,reason..' Your Curse is unplaced; pick it up at your sanctuary.') end
 end
 function service:purchase(p,uid)
  local root=rootOf(p);local r=records[uid];local rt=runtime[uid]
  if not root or not r or r.state~='PROCESSION' or r.locked or not rt or not rt.model.Parent then return false end
  local now=os.clock();if now-(lastRequest[p.UserId] or -math.huge)<Config.PurchaseAttemptCooldownSeconds then return false end
  lastRequest[p.UserId]=now
  if (root.Position-rt.model.PrimaryPart.Position).Magnitude>Config.MaxPurchaseDistanceStuds then return false end
  local base=bases:getBaseForPlayer(p)
  if not base then souls:notify(p,'Claim a sanctuary first.');return false end
  if carried[p.UserId] or p:GetAttribute('CarriedRelicUid') then souls:notify(p,'You are already carrying a Curse or relic. Place or deliver it first.');return false end
  if not freeSlot(base) then souls:notify(p,'No free pedestals.');return false end
  if ownedCount(p)>=Config.MaximumOwnedCurses then souls:notify(p,'Your collection is full.');return false end
  r.state='RESERVED';rt.prompt.Enabled=false
  if not souls:trySpend(p,definition(r).price) then r.state='PROCESSION';rt.prompt.Enabled=true;souls:notify(p,'Not enough Souls.');return false end
  r.ownerUserId=p.UserId;r.carrierUserId=p.UserId;r.baseId=base.Name;r.state='CARRYING';r.revision+=1
  carried[p.UserId]=uid;p:SetAttribute('CarriedCurseUid',uid)
  publish(r,true);saveOwned(p)
  souls:notify(p,definition(r).displayName..' bought. Carry it to a free pedestal and press Place.')
  return true
 end
 function service:spawn(id,frame)
  assert(Catalog.Definitions[id],'Unknown Curse')
  local uid=Http:GenerateGUID(false)
  local r={uid=uid,definitionId=id,state='PROCESSION',revision=0};records[uid]=r
  local m=createRuntime(r);Visual.move(m,frame+Vector3.new(0,m.PrimaryPart.Size.Y*.5-3.5,0),true)
  return uid
 end
 function service:getState(uid) local r=records[uid];return r and r.state end
 function service:setProcessionMotion(uid,epoch,speed,phase)
  local rt=runtime[uid];if not rt then return end
  rt.model:SetAttribute('RouteSpeed',speed);rt.model:SetAttribute('RouteStartedAt',epoch);rt.model:SetAttribute('MotionPhase',phase)
 end
 function service:moveProcession(uid,frame)
  local r,rt=records[uid],runtime[uid]
  if not r or r.state~='PROCESSION' then return false end
  if not rt or not rt.model.Parent then destroyRuntime(uid);records[uid]=nil;return false end
  Visual.move(rt.model,frame+Vector3.new(0,rt.model.PrimaryPart.Size.Y*.5-3.5,0));return true
 end
 function service:despawnUnsold(uid)
  if records[uid] and records[uid].state=='PROCESSION' then destroyRuntime(uid);records[uid]=nil end
 end
 function service:action(p,action,uid,pedestalId,token)
  local root=rootOf(p)
  if not root then return result(false,'Not available yet. Wait for your account and character to load.') end
  local r=if typeof(uid)=='string' then records[uid] else nil
  if not r or r.ownerUserId~=p.UserId then return result(false,'That Curse is not yours or is no longer available.') end
  local base=bases:getBaseForPlayer(p)
  if not base or base:GetAttribute('OwnerUserId')~=p.UserId or r.baseId~=base.Name then return result(false,'Use your own sanctuary.') end
  local rt=runtime[uid]
  if not rt or not rt.model.Parent then return result(false,'That Curse is being recovered. Try again.') end
  if r.locked or r.stealingUserId or rt.model:GetAttribute('OperationLocked') then return result(false,'Curse is busy with another action.') end
  if action=='place' then
   local destination=pedestal(base,pedestalId)
   if not destination then return result(false,'Pedestal unavailable.') end
   if (root.Position-destination.Position).Magnitude>Config.PlacementDistanceStuds then return result(false,'Get closer to the pedestal to place it.') end
   occupied[base.Name]=occupied[base.Name] or {}
   if occupied[base.Name][pedestalId] then return result(false,'Pedestal taken.') end
   if not Rules.canPlace(r,p.UserId,carried[p.UserId],occupied[base.Name][pedestalId]) then return result(false,'You must carry this Curse there.') end
   r.locked=true;occupied[base.Name][pedestalId]=uid;r.pedestalId=pedestalId
   if not onPlinth(r,base) then occupied[base.Name][pedestalId]=nil;r.pedestalId=nil;r.locked=nil;return result(false,'That pedestal is no longer available.') end
   r.state='PLACED';r.carrierUserId=nil;r.locked=nil;r.revision+=1
   carried[p.UserId]=nil;p:SetAttribute('CarriedCurseUid',nil);markPedestal(r,uid);publish(r,true)
   production(p);saveOwned(p)
   if service.onLegitimatePlacement then service.onLegitimatePlacement(p,r.definitionId,r.uid) end
   return result(true,definition(r).displayName..' placed.')
  end
  if (root.Position-rt.model.PrimaryPart.Position).Magnitude>Config.ManagementDistanceStuds then return result(false,'Get closer to your Curse.') end
  if action=='inspect' then
   if not Rules.canManage(r,p.UserId,'PLACED') then return result(false,'Curse is being carried or unplaced.') end
   local d=definition(r)
   return result(true,'',{uid=uid,name=d.displayName,rarity=Catalog.Rarities[d.rarity].label,price=d.price,sale=Rules.saleValue(d.price,Config.SellFraction)})
  elseif action=='pickup' then
   if carried[p.UserId] or p:GetAttribute('CarriedRelicUid') then return result(false,'Place or deliver what you carry before picking up another Curse.') end
   if not (Rules.canManage(r,p.UserId,'PLACED') or Rules.canManage(r,p.UserId,'UNPLACED')) then return result(false,"You can't pick up this Curse right now.") end
   r.locked=true;releasePedestal(r);rt.recoveryBay=nil;r.state='CARRYING';r.carrierUserId=p.UserId;r.revision+=1;r.locked=nil
   carried[p.UserId]=uid;p:SetAttribute('CarriedCurseUid',uid);quotes[p.UserId]=nil
   Visual.move(rt.model,CarryGeometry.follow(root.CFrame,rt.model.PrimaryPart.Size,map,base),true);publish(r,true)
   production(p);saveOwned(p)
   fillRecovery(p,base)
   return result(true,'Carry it to a free pedestal and press Place.')
  elseif action=='quote' then
   if not Rules.canManage(r,p.UserId,'PLACED') then return result(false,'You can only sell a placed, available Curse.') end
   local value=Rules.saleValue(definition(r).price,Config.SellFraction)
   local quote={token=Http:GenerateGUID(false),uid=uid,userId=p.UserId,revision=r.revision,expires=os.clock()+Config.SellQuoteLifetimeSeconds,value=value}
   quotes[p.UserId]=quote
   return result(true,'',{token=quote.token,uid=uid,name=definition(r).displayName,rarity=Catalog.Rarities[definition(r).rarity].label,sale=value})
  elseif action=='sell' then
   if not Rules.canManage(r,p.UserId,'PLACED') then return result(false,'This Curse can no longer be sold.') end
   local quote=quotes[p.UserId]
   if not Rules.consumeQuote(quote,token,uid,p.UserId,r.revision,os.clock()) then return result(false,'Confirmation expired. Review the sale again.') end
   local value=Rules.saleValue(definition(r).price,Config.SellFraction)
   if value~=quote.value then quotes[p.UserId]=nil;return result(false,'The price changed. Review the sale again.') end
   r.locked=true;r.state='SOLD';releasePedestal(r);records[uid]=nil;quotes[p.UserId]=nil
   souls:credit(p,value);destroyRuntime(uid);production(p);saveOwned(p)
   return result(true,'Sold. You received '..tostring(value)..' Souls.')
  end
  return result(false,'Action unavailable.')
 end
 local remoteCooldown={}
 request.OnServerInvoke=function(p,action,uid,pedestalId,token)
  if typeof(action)~='string' or typeof(uid)~='string' or #uid>80 then return result(false,'Invalid request.') end
  local now=os.clock()
  if now-(remoteCooldown[p.UserId] or -math.huge)<.12 then return result(false,'One moment.') end
  remoteCooldown[p.UserId]=now
  return service:action(p,action,uid,pedestalId,token)
 end
	local function addPedestalPrompt(part,base)
  if not part:IsA('BasePart') or not part:GetAttribute('PedestalId') or part:FindFirstChild('PlaceCurse') then return end
		game:GetService('CollectionService'):AddTag(part,'OwnedCursePedestal')
		local prompt=Instance.new('ProximityPrompt');prompt.Name='PlaceCurse';prompt.ActionText='Place';prompt.ObjectText='Pedestal'
  prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.RequiresLineOfSight=false;prompt.MaxActivationDistance=Config.PlacementDistanceStuds
  prompt.Exclusivity=Enum.ProximityPromptExclusivity.OnePerButton;prompt.Parent=part
  prompt.Triggered:Connect(function(p)
   local answer=if p:GetAttribute('StolenCurseUid') and service.onTheftPlace then service.onTheftPlace(p,part:GetAttribute('PedestalId'))else service:action(p,'place',carried[p.UserId],part:GetAttribute('PedestalId'))
   souls:notify(p,answer.message)
  end)
 end
 local function decorateBase(base)
  for _,part in bases:getPedestals(base) do addPedestalPrompt(part,base) end
  if not base:FindFirstChild('RecoveryDesk') then
   local marker=Instance.new('Part');marker.Name='RecoveryDesk';marker.Size=Vector3.one
   marker.Anchored=true;marker.CanCollide=false;marker.CanQuery=false;marker.CanTouch=false;marker.Transparency=1
   marker.CFrame=base.PlayerSpawn.CFrame*CFrame.new(20,2,7);marker.Parent=base
   local prompt=Instance.new('ProximityPrompt');prompt.Name='RecoverWaiting';prompt.ActionText='Recover pending'
   prompt.ObjectText='Recovery bay';prompt.RequiresLineOfSight=false;prompt.MaxActivationDistance=10;prompt.Parent=marker
   prompt.Triggered:Connect(function(p)
    local root=rootOf(p)
    if not root or bases:getBaseForPlayer(p)~=base or (root.Position-marker.Position).Magnitude>12 then return end
    local waiting=fillRecovery(p,base)
    souls:notify(p,if waiting>0 then tostring(waiting)..' pending. Pick up a Curse from the bay to free space.' else 'Pick up and place the Curses in this bay yourself.')
   end)
  end
 end
 function service:getOwned(p)
  local list={}
  for _,r in records do if r.ownerUserId==p.UserId then
   table.insert(list,{uid=r.uid,definitionId=r.definitionId,state=r.state,pedestalId=r.pedestalId,locked=r.locked,stealingUserId=r.stealingUserId})
  end end
  return list
 end
 function service:refreshPedestals(base)
  decorateBase(base)
  for _,r in records do if r.baseId==base.Name and r.state=='PLACED' then markPedestal(r,r.uid) end end
 end
 function service:restore(p,base)
  occupied[base.Name]=occupied[base.Name] or {};decorateBase(base)
  local ids={};for uid,r in records do if r.ownerUserId==p.UserId then table.insert(ids,uid) end end;table.sort(ids)
  local unplaced=0
  for _,uid in ids do
   local r=records[uid];r.baseId=base.Name;r.carrierUserId=nil
   local slot=r.pedestalId
   if r.state=='WAITING_PLACEMENT' and slot and pedestal(base,slot) and not occupied[base.Name][slot] then
    if not runtime[uid] then createRuntime(r) end
    r.state='PLACED';occupied[base.Name][slot]=uid;markPedestal(r,uid);onPlinth(r,base);publish(r,true)
   else
    r.state='UNPLACED';r.pedestalId=nil;unplaced+=1;recovery(r,base,unplaced)
   end
  end
  production(p);saveOwned(p)
  if unplaced>0 then souls:notify(p,tostring(unplaced).." unplaced Curses. Pick them up at your sanctuary's recovery bay.") end
 end
	profiles:onLoaded(function(p,profile)
		clearing[p.UserId]=nil
  local seen={}
  for _,saved in profile.curses do
   if Catalog.Definitions[saved.definitionId] and typeof(saved.uid)=='string' and not seen[saved.uid] and not records[saved.uid] then
    seen[saved.uid]=true
    records[saved.uid]={uid=saved.uid,definitionId=saved.definitionId,state=if saved.state=='PLACED' then 'WAITING_PLACEMENT' else 'UNPLACED',
     ownerUserId=p.UserId,pedestalId=if saved.state=='PLACED' then saved.pedestalId else nil,revision=saved.revision or 0}
   else warn('Saved Curse needs recovery review; account retained: '..tostring(saved.definitionId)) end
  end
  local base=bases:getBaseForPlayer(p);if base then service:restore(p,base) end
 end)
 bases:onClaimed(function(p,base)service:restore(p,base)end)
 function service:clearForUser(p,base)
  if clearing[p.UserId] then return end;clearing[p.UserId]=true
  if service.onBeforeClearUser then service.onBeforeClearUser(p)end
  drop(p,nil);saveOwned(p);souls:setProduction(p,0)
  local remove={}
  for uid,r in records do if r.ownerUserId==p.UserId then releasePedestal(r);table.insert(remove,uid) end end
  -- The profile snapshot was taken before visual removal; no inventory is lost.
  for _,uid in remove do destroyRuntime(uid);records[uid]=nil end
  if base then occupied[base.Name]=nil end
  lastRequest[p.UserId]=nil;remoteCooldown[p.UserId]=nil;quotes[p.UserId]=nil
  profiles:release(p)
 end
 bases:onReleased(function(p,base)service:clearForUser(p,base)end)
 Players.PlayerRemoving:Connect(function(p)if not clearing[p.UserId] then service:clearForUser(p,bases:getBaseForPlayer(p)) end end)
 local function track(p)
  p.CharacterRemoving:Connect(function() drop(p,'You reset your character.') end)
  local function character(c)
   local h=c:WaitForChild('Humanoid',10)
   if h then h.Died:Connect(function()drop(p,'You died.')end) end
  end
  p.CharacterAdded:Connect(character);if p.Character then task.spawn(character,p.Character)end
 end
 Players.PlayerAdded:Connect(track);for _,p in Players:GetPlayers()do track(p)end
 task.spawn(function()
  local reconcile=0
  while map.Parent==workspace do
   task.wait(Config.DeliveryStepSeconds)
   for userId,uid in carried do
    local p=Players:GetPlayerByUserId(userId);local r=records[uid];local rt=runtime[uid];local root=p and rootOf(p)
    if not p or not r or r.carrierUserId~=userId or r.state~='CARRYING' then carried[userId]=nil
    elseif not root or not rt or not rt.model.Parent or (not r.stealingUserId and bases:getBaseIdForPlayer(p)~=r.baseId) then drop(p,'Carry interrupted.')
    else Visual.move(rt.model,CarryGeometry.follow(root.CFrame,rt.model.PrimaryPart.Size,map,bases:getBaseForPlayer(p))) end
   end
   if os.clock()>reconcile then
    reconcile=os.clock()+3
    for i=1,8 do local base=bases:getBaseById(string.format('Base%02d',i));decorateBase(base) end
    for uid,r in records do
     if r.ownerUserId and r.baseId and (r.state=='PLACED' or r.state=='UNPLACED') then
      local p=Players:GetPlayerByUserId(r.ownerUserId);local base=p and bases:getBaseForPlayer(p)
      if base then
       if r.state=='PLACED' and not pedestal(base,r.pedestalId) then releasePedestal(r);r.state='UNPLACED';r.revision+=1;recovery(r,base,1);production(p);saveOwned(p)
       elseif not runtime[uid] or not runtime[uid].model.Parent then
        destroyRuntime(uid)
        local ok,err=pcall(function()if r.state=='PLACED' then createRuntime(r);onPlinth(r,base);publish(r,true)else recovery(r,base,1)end end)
        if not ok then warn('Curse visual recovery pending; ownership preserved: '..tostring(err)) end
       end
      end
     end
    end
   end
  end
 end)
 -- Theft reuses these records, carry channel, occupancy and presentation. It
 -- never maintains another collection registry.
 function service:prepareTheft(p,uid)
  local r=records[uid];local rt=runtime[uid];local root=rootOf(p);local base=bases:getBaseForPlayer(p)
  if not root or not base or not r or not rt or r.ownerUserId==p.UserId or not r.ownerUserId or r.state~='PLACED' or r.locked or r.stealingUserId then return nil,"This Curse can't be stolen right now."end
  local owner=Players:GetPlayerByUserId(r.ownerUserId);local source=bases:getBaseById(r.baseId)
  if not owner or owner:GetAttribute('ProfileStatus')~='READY' or not source or (source:GetAttribute('SealEndsAt')or 0)>workspace:GetServerTimeNow()then return nil,'Sanctuary sealed or owner unavailable.'end
  if carried[p.UserId] or p:GetAttribute('CarriedRelicUid')or not freeSlot(base)or ownedCount(p)>=Config.MaximumOwnedCurses then return nil,'You need a free pedestal and empty hands.'end
  if (root.Position-rt.model.PrimaryPart.Position).Magnitude>Config.ManagementDistanceStuds then return nil,'Get closer to the Curse.'end
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={p.Character,owner.Character,rt.model}
  local hit=workspace:Raycast(root.Position,rt.model.PrimaryPart.Position-root.Position,params)
  if hit and hit.Instance.CanCollide and (hit.Position-rt.model.PrimaryPart.Position).Magnitude>2 then return nil,"You can't steal through walls."end
  r.locked=true;publish(r)
  return {uid=uid,definitionId=r.definitionId,owner=r.ownerUserId,revision=r.revision,sourceBase=r.baseId},nil
 end
 function service:cancelTheftReservation(uid)local r=records[uid];if r and not r.stealingUserId then r.locked=nil;publish(r)end end
 function service:beginTheft(p,uid)
  local r=records[uid];local rt=runtime[uid];local root=rootOf(p);local source=r and bases:getBaseById(r.baseId)
  local destination=bases:getBaseForPlayer(p);local owner=r and Players:GetPlayerByUserId(r.ownerUserId)
  if not destination or not freeSlot(destination)or not owner or owner:GetAttribute('ProfileStatus')~='READY' or ownedCount(p)>=Config.MaximumOwnedCurses then self:cancelTheftReservation(uid);return false end
  if not r or not rt or not r.locked or not root or not source or (source:GetAttribute('SealEndsAt')or 0)>workspace:GetServerTimeNow()or (root.Position-rt.model.PrimaryPart.Position).Magnitude>Config.ManagementDistanceStuds or carried[p.UserId]or p:GetAttribute('CarriedRelicUid')then self:cancelTheftReservation(uid);return false end
  releasePedestal(r);r.state='CARRYING';r.carrierUserId=p.UserId;r.stealingUserId=p.UserId;r.locked=nil;r.revision+=1
  carried[p.UserId]=uid;p:SetAttribute('CarriedCurseUid',uid);p:SetAttribute('StolenCurseUid',uid)
  Visual.move(rt.model,CarryGeometry.follow(root.CFrame,rt.model.PrimaryPart.Size,map,bases:getBaseForPlayer(p)),true);publish(r,true)
  local owner=Players:GetPlayerByUserId(r.ownerUserId);if owner then production(owner);saveOwned(owner)end
  return true
 end
 function service:interruptTheft(uid)
  local r=records[uid];if not r then return end
  local p=r.stealingUserId and Players:GetPlayerByUserId(r.stealingUserId)
  if r.stealingUserId then carried[r.stealingUserId]=nil end
  if p then p:SetAttribute('CarriedCurseUid',nil);p:SetAttribute('StolenCurseUid',nil)end
  r.stealingUserId=nil;r.carrierUserId=nil;r.locked=nil;r.state='UNPLACED';r.revision+=1
  local owner=Players:GetPlayerByUserId(r.ownerUserId);local base=owner and bases:getBaseForPlayer(owner)
  if base then recovery(r,base,1)end
  if owner then production(owner);saveOwned(owner)end
 end
 function service:reserveTheftDelivery(p,uid,id)
  local r=records[uid];local root=rootOf(p);local base=bases:getBaseForPlayer(p);local part=pedestal(base,id)
  if not r or r.locked or r.stealingUserId~=p.UserId or carried[p.UserId]~=uid or not root or not part or (root.Position-part.Position).Magnitude>Config.PlacementDistanceStuds or ownedCount(p)>=Config.MaximumOwnedCurses then return nil,'Carry the Curse near one of your free pedestals.'end
  occupied[base.Name]=occupied[base.Name]or{};if occupied[base.Name][id]then return nil,'Pedestal taken.'end
  occupied[base.Name][id]=uid;r.locked=true;publish(r)
  return {baseId=base.Name,pedestalId=id},nil
 end
 function service:releaseTheftDelivery(plan,uid)
  local slots=occupied[plan.baseId];if slots and slots[plan.pedestalId]==uid then slots[plan.pedestalId]=nil end
  local r=records[uid];if r then r.locked=nil;publish(r)end
 end
 function service:finishTheft(p,op,plan)
  local r=records[op.uid];local old=Players:GetPlayerByUserId(op.from)
  if not r then r={uid=op.uid,definitionId=op.definitionId,revision=op.revision or 0};records[op.uid]=r end
  if r.carrierUserId then carried[r.carrierUserId]=nil end
  p:SetAttribute('CarriedCurseUid',nil);p:SetAttribute('StolenCurseUid',nil)
  r.ownerUserId=p.UserId;r.stealingUserId=nil;r.carrierUserId=nil;r.locked=nil;r.baseId=plan.baseId;r.pedestalId=plan.pedestalId;r.revision+=1
  local base=bases:getBaseForPlayer(p);local placed=false
  if rootOf(p) and base and base.Name==plan.baseId and pedestal(base,plan.pedestalId) then
   if not runtime[r.uid]then createRuntime(r)end;placed=onPlinth(r,base)
  end
  r.state=if placed then 'PLACED'else 'UNPLACED'
  if placed then occupied[base.Name]=occupied[base.Name]or{};occupied[base.Name][plan.pedestalId]=r.uid;markPedestal(r,r.uid);publish(r,true)
  else self:releaseTheftDelivery(plan,r.uid);r.pedestalId=nil;if base then recovery(r,base,1)end end
  local profile=profiles:get(p);if profile then profile.toolTransfers=profile.toolTransfers or{};profile.toolTransfers[op.tx..':COMMITTED']=true end
  if old then production(old);saveOwned(old)end
  if profile then production(p);saveOwned(p)end
  if placed and service.onLegitimatePlacement then service.onLegitimatePlacement(p,r.definitionId,r.uid)end
  return placed
 end
 return service
end
return CurseService
