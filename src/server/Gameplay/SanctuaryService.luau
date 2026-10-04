local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Http=game:GetService('HttpService')
local Config=require(RS.Shared.SanctuaryConfig)
local Progression=require(RS.Shared.SanctuaryProgression)
local Architecture=require(script.Parent.Parent.Map.RestorationArchitecture)
local Sanctuary={}
function Sanctuary.start(map,bases,souls,profiles)
 local remote=Instance.new('Folder');remote.Name='SanctuaryRestoration';remote.Parent=RS
 local request=Instance.new('RemoteFunction');request.Name='Request';request.Parent=remote
 local push=Instance.new('RemoteEvent');push.Name='Changed';push.Parent=remote
 local open=Instance.new('RemoteEvent');open.Name='Open';open.Parent=remote
 local service={};local curses,contracts,rituals;local bound,seals,cooldowns={},{},{}
 local function result(ok,message,data) return {ok=ok,message=message,data=data} end
 local function rootOf(player)
  local c=player.Character;local h=c and c:FindFirstChildOfClass('Humanoid');local root=c and c:FindFirstChild('HumanoidRootPart')
  return if player.Parent==Players and player:GetAttribute('ProfileStatus')=='READY' and h and h.Health>0 then root else nil
 end
 local function featuredSlot(player)
  local p=profiles:get(player);if not p or not p.sanctuary.featuredUid or not curses then return nil end
  for _,r in curses:getOwned(player) do if r.uid==p.sanctuary.featuredUid and r.state=='PLACED' then return r.pedestalId end end
  return nil
 end
 function service:snapshot(player)
  local p=profiles:get(player);if not p then return nil end
  local s=p.sanctuary;local base=bases:getBaseForPlayer(player);local seal=base and seals[base]
  return {progress=Progression.snapshot(s),souls=math.floor(p.souls),capacity=Progression.capacity(s.level),baseId=base and base.Name,
   upgrade=Progression.evaluate(p,s.level+1),contract=contracts and contracts:snapshot(player),ritual=rituals and rituals:snapshot(player),
   owned=curses and curses:getOwned(player) or {},seal={endsAt=seal and seal.endsAt or 0,availableAt=seal and seal.availableAt or 0},
   sets=Progression.setReports and Progression.setReports(p) or nil}
 end
 function service:changed(player)
  local p=profiles:get(player);if not p then return end
  player:SetAttribute('SanctuaryLevel',p.sanctuary.level);player:SetAttribute('SealFragments',p.sanctuary.fragments)
  player:SetAttribute('SanctuaryStyle',p.sanctuary.style)
  if player.Parent==Players then push:FireClient(player,self:snapshot(player)) end
 end
 function service:open(player,page) open:FireClient(player,page,self:snapshot(player)) end
 local function altarNear(player,base)
  local root=rootOf(player);local altar=base and base:FindFirstChild('RestorationAltar',true)
  return root and altar and (root.Position-altar.Position).Magnitude<=14
 end
 local function notice(player,answer) souls:notify(player,answer.message) end
 local function bindBase(base)
  if bound[base] then return end;bound[base]=true
  local function bind(item)
   if not item:IsA('BasePart') or item:GetAttribute('SanctuaryInteractionBound') then return end
   if item.Name=='RestorationAltar' or item.Name:match('^RitualMark_%d$') then
    item:SetAttribute('SanctuaryInteractionBound',true)
    local prompt=item:FindFirstChild('RestorationPrompt') or Instance.new('ProximityPrompt')
    prompt.Name='RestorationPrompt';prompt.ActionText=if item.Name=='RestorationAltar' then 'Restore / deliver' else 'Activate mark'
    prompt.ObjectText=if item.Name=='RestorationAltar' then 'Sanctuary altar' else 'Mark '..item.Name:sub(-1)
    prompt.RequiresLineOfSight=false;prompt.MaxActivationDistance=10;prompt.HoldDuration=0;prompt.Parent=item
    prompt.Triggered:Connect(function(player)
     if bases:getBaseForPlayer(player)~=base then souls:notify(player,'This altar belongs to another sanctuary.');return end
     if item.Name=='RestorationAltar' then
      local p=profiles:get(player);local c=p and p.sanctuary.contract
      if contracts and c and Config.Contracts[c.id].nodes[c.step+1]=='sanctuary_altar' then
       local ok,message=contracts:interact(player,'sanctuary_altar');souls:notify(player,message)
      elseif altarNear(player,base) then service:open(player,'UPGRADE') end
     elseif rituals then local ok,message=rituals:activate(player,tonumber(item.Name:sub(-1)));souls:notify(player,message) end
    end)
   end
  end
  for _,item in base:GetDescendants() do bind(item) end
  base.DescendantAdded:Connect(bind)
 end
 local function apply(player,base)
  local p=profiles:get(player);assert(p,'Ready profile required')
  Architecture.apply(base,p.sanctuary.level,p.sanctuary.style,featuredSlot(player))
  bindBase(base)
 end
 bases:onClaimed(function(player,base)apply(player,base);service:changed(player)end)
 profiles:onLoaded(function(player)service:changed(player)end)
 local function resetSeal(base)
  local state=seals[base];seals[base]=nil
  if state and state.constraints then state.constraints:Destroy() end
  local barrier=base:FindFirstChild('SealBarrier',true)
  if barrier then barrier.CanCollide=false;barrier.Transparency=1 end
  base:SetAttribute('SealEndsAt',0);base:SetAttribute('SealAvailableAt',0)
 end
 local function ownerAccess(player,barrier,state)
  if state.constraints then state.constraints:Destroy() end
  local folder=Instance.new('Folder');folder.Name='OwnerSealAccess';folder.Parent=barrier;state.constraints=folder
  if player.Character then for _,part in player.Character:GetDescendants() do if part:IsA('BasePart') then
   local link=Instance.new('NoCollisionConstraint');link.Part0=barrier;link.Part1=part;link.Parent=folder
  end end end
 end
 function service:activateSeal(player)
  local p=profiles:get(player);local base=bases:getBaseForPlayer(player)
  if not p or not base or not altarNear(player,base) then return false,'Activate the seal from your altar.' end
  if p.sanctuary.level<Config.Protection.minimumLevel then return false,'The protective seal unlocks at level 6.' end
  local now=workspace:GetServerTimeNow();local previous=seals[base]
  if previous and now<previous.availableAt then return false,'The seal is still recharging.' end
  local barrier=base:FindFirstChild('SealBarrier',true);if not barrier then return false,'The entrance is being rebuilt.' end
  local duration=if p.sanctuary.level>=Config.Protection.consagratedLevel then Config.Protection.consagratedDuration else Config.Protection.duration
  local state={owner=player,endsAt=now+duration,availableAt=now+duration+Config.Protection.vulnerabilitySeconds}
  seals[base]=state;ownerAccess(player,barrier,state)
  barrier.CanCollide=true;barrier.Transparency=.48
  base:SetAttribute('SealEndsAt',state.endsAt);base:SetAttribute('SealAvailableAt',state.availableAt);service:changed(player)
  return true,'Entrance sealed for '..duration..' seconds. You can still come and go.'
 end
 function service:action(player,action,value)
  local p=profiles:get(player);if not p or not rootOf(player) then return result(false,'Wait for your account and character to load.') end
  if action=='snapshot' then return result(true,'',self:snapshot(player)) end
  local base=bases:getBaseForPlayer(player)
  if not base or base:GetAttribute('OwnerUserId')~=player.UserId then return result(false,'Claim your sanctuary first.') end
  if action=='upgrade' then
   if not altarNear(player,base) then return result(false,'Go to your altar to restore your sanctuary.') end
   if value~=tostring(p.sanctuary.level) then return result(false,'Your level changed. Check the requirements before restoring again.',self:snapshot(player)) end
   -- next level never comes from the client. Snapshot values allow exact rollback
   -- if architecture unexpectedly fails; there is no yield during this transaction.
   local oldLevel,oldSouls,oldFragments=p.sanctuary.level,p.souls,p.sanctuary.fragments
   local ok,report=Progression.tryUpgrade(p,oldLevel+1)
   if not ok then return result(false,'Some requirements for this level are still missing.',report) end
   local constructed,failure=pcall(function()apply(player,base);if curses then curses:refreshPedestals(base) end end)
   if not constructed then
    p.sanctuary.level=oldLevel;p.souls=oldSouls;p.sanctuary.fragments=oldFragments
    pcall(apply,player,base);warn('Restoration rolled back without cost: '..tostring(failure))
    return result(false,'The restoration could not finish. Your resources are kept.')
   end
   souls:refresh(player);profiles:commit(player);self:changed(player)
   return result(true,'Level '..p.sanctuary.level..' restored.',self:snapshot(player))
  elseif action=='style' then
   if not Config.Styles[value] then return result(false,'Style unavailable.') end
   local old=p.sanctuary.style;p.sanctuary.style=value
   local ok=pcall(apply,player,base)
   if not ok then p.sanctuary.style=old;pcall(apply,player,base);return result(false,'Could not change style. Your collection is kept.') end
   profiles:commit(player);self:changed(player);return result(true,'Style: '..Config.Styles[value].title..'.',self:snapshot(player))
  elseif action=='featured' then
   local old=p.sanctuary.featuredUid
   if not Progression.selectFeatured(p,if value=='' then nil else value) then return result(false,'Choose one of your placed Curses.') end
   local ok=pcall(apply,player,base)
   if not ok then p.sanctuary.featuredUid=old;pcall(apply,player,base);return result(false,'The display could not update. Your collection is kept.') end
   profiles:commit(player);self:changed(player);return result(true,'Featured display updated. Same Curse, no extra income.',self:snapshot(player))
  elseif action=='seal' then local ok,message=self:activateSeal(player);return result(ok,message,self:snapshot(player))
  elseif action=='contract_accept' and contracts then local ok,message=contracts:accept(player,value);return result(ok,message,self:snapshot(player))
  elseif action=='contract_abandon' and contracts then local ok,message=contracts:abandon(player);return result(ok,message,self:snapshot(player))
  elseif action=='contract_restart' and contracts then local ok,message=contracts:restart(player);return result(ok,message,self:snapshot(player))
  elseif action=='ritual_begin' and rituals then local ok,message=rituals:begin(player,value);return result(ok,message,self:snapshot(player))
  elseif action=='ritual_cancel' and rituals then local ok,message=rituals:cancel(player);return result(ok,message,self:snapshot(player)) end
  return result(false,'Action unavailable.')
 end
 request.OnServerInvoke=function(player,action,value)
  if typeof(action)~='string' or #action>40 or (value~=nil and (typeof(value)~='string' or #value>80)) then return result(false,'Invalid request.') end
  local now=os.clock();if now-(cooldowns[player.UserId] or -math.huge)<.15 then return result(false,'One moment.') end
  cooldowns[player.UserId]=now
  return service:action(player,action,value)
 end
 function service:attach(curseService,contractService,ritualService)
  curses,contracts,rituals=curseService,contractService,ritualService
  curses.onLegitimatePlacement=function(player,id)
   local p=profiles:get(player);if p and Progression.discover(p,id) then profiles:commit(player);souls:notify(player,'New species in your Grimoire: '..require(RS.Shared.CurseCatalog).Definitions[id].displayName) end
   service:changed(player)
  end
  curses.onOwnedChanged=function(player)
   local p=profiles:get(player)
   if p and p.sanctuary.featuredUid then
    local slot=featuredSlot(player)
    if not slot then p.sanctuary.featuredUid=nil end
    local base=bases:getBaseForPlayer(player)
    if base and base:GetAttribute('FeaturedPedestalId')~=slot then pcall(apply,player,base) end
    if not slot then profiles:commit(player) end
   end
   service:changed(player)
  end
  -- Register after CurseService's release callback, so no occupied pedestal is
  -- removed before its inventory snapshot and runtime cleanup have completed.
  bases:onReleased(function(player,base)
   if rituals then rituals:cancel(player) end
   resetSeal(base);Architecture.apply(base,0,'CRYPT');cooldowns[player.UserId]=nil
  end)
 end
 local function track(player)
  player.CharacterAdded:Connect(function()
   local base=bases:getBaseForPlayer(player);local state=base and seals[base]
   if state and workspace:GetServerTimeNow()<state.endsAt then
    local barrier=base:FindFirstChild('SealBarrier',true)
    task.delay(.3,function()if barrier and barrier.Parent and seals[base]==state then ownerAccess(player,barrier,state) end end)
   end
  end)
 end
 Players.PlayerAdded:Connect(track);for _,player in Players:GetPlayers() do track(player) end
 task.spawn(function()
  while map.Parent do
   task.wait(.2);local now=workspace:GetServerTimeNow()
   for base,state in seals do
    local barrier=base:FindFirstChild('SealBarrier',true)
    if now>=state.endsAt then
     if barrier and barrier.CanCollide then
      barrier.CanCollide=false;barrier.Transparency=1;if state.constraints then state.constraints:Destroy();state.constraints=nil end
      service:changed(state.owner)
     end
    elseif barrier then
     -- Collision remains server-owned. This guard also catches a client that
     -- locally disables collision and crosses the boundary of a closed base.
     local frame=base:GetAttribute('SanctuaryFrame')
     if typeof(frame)=='CFrame' then for _,player in Players:GetPlayers() do
      if player~=state.owner then local root=rootOf(player)
       if root then local point=frame:PointToObjectSpace(root.Position)
        if math.abs(point.X)<52 and point.Z>-36 and point.Z<68 and point.Y>-2 and point.Y<72 then
         player.Character:PivotTo(frame*CFrame.new(0,4,-45));root.AssemblyLinearVelocity=Vector3.zero
         souls:notify(player,"This sanctuary's entrance is temporarily sealed.")
        end
       end
      end
     end end
    end
   end
  end
 end)
 return service
end
return Sanctuary
