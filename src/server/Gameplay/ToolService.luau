local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local Run=game:GetService('RunService')
local Tween=game:GetService('TweenService');local Debris=game:GetService('Debris');local Http=game:GetService('HttpService')
local C=require(RS.Shared.ToolCatalog);local I=require(RS.Shared.ToolInventory);local Math=require(RS.Shared.ToolEffectsMath)
local Models=require(script.Parent.ToolModels);local Status=require(script.Parent.ToolStatusService)
local Tools={}
function Tools.start(map,profiles,souls,bases,carry)
 local remote=Instance.new('Folder');remote.Name='ToolsFoundation';remote.Parent=RS
 local request=Instance.new('RemoteFunction');request.Name='Request';request.Parent=remote
 local changed=Instance.new('RemoteEvent');changed.Name='Changed';changed.Parent=remote
 local fx=Instance.new('RemoteEvent');fx.Name='Effect';fx.Parent=remote
 local effects=Instance.new('Folder');effects.Name='ToolEffects';effects.Parent=map
 local templates=Instance.new('Folder');templates.Name='ToolTemplates';templates.Parent=game.ServerStorage
 for _,id in C.Order do Models.create(id).Parent=templates end
 local status=Status.start(map);local cooldowns,spam,passOwned,trials,zones,casting={},{},{},{},{},{}
 local service={status=status,effects=effects};local theft
 local function root(p)
  local c=p.Character;local h=c and c:FindFirstChildOfClass('Humanoid');local r=c and c:FindFirstChild('HumanoidRootPart')
  return if p.Parent==Players and p:GetAttribute('ProfileStatus')=='READY' and h and h.Health>0 and r then r else nil
 end
 local function answer(ok,message,data)return {ok=ok,message=message,data=data}end
 local function emit(id,at,data)fx:FireAllClients(id,at,data or {})end
 local function owns(p,id)
  local profile=profiles:get(p);return profile and I.owns(profile.tools,id,passOwned[p] and passOwned[p][id])
 end
 local function los(a,b,ignore)
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances=ignore or {effects,map.ActiveCurses}
  local hit=workspace:Raycast(a,b-a,params);return not hit or (hit.Position-b).Magnitude<1
 end
 local function protected(p,at)
  for _,b in map.PlayerSanctuaries:GetChildren()do
   if b:GetAttribute('OwnerUserId')~=p.UserId and (b:GetAttribute('SealEndsAt')or 0)>workspace:GetServerTimeNow()then
    local f=b:GetAttribute('SanctuaryFrame');if typeof(f)=='CFrame'then local q=f:PointToObjectSpace(at)
     if math.abs(q.X)<53 and q.Z>-37 and q.Z<69 and q.Y>-3 and q.Y<75 then return true end
    end
   end
  end;return false
 end
 local function findTool(p,id)
  local c=p.Character;return c and c:FindFirstChild(id)
 end
 local function removeZones(p,id)
  for token,z in zones do if z.owner==p and (not id or z.id==id)then if z.model then z.model:Destroy()end;zones[token]=nil end end
 end
 function service:snapshot(p)
  local profile=profiles:get(p);if not profile then return nil end
  local data={items={},equipped=table.clone(profile.tools.equipped),maxEquipped=C.MaxEquipped,theft=p:GetAttribute('StolenCurseUid'),carried=p:GetAttribute('CarriedCurseUid')}
  for _,id in C.Order do local d=C.Items[id];data.items[id]={id=id,name=d.name,owned=owns(p,id)==true,charges=profile.tools.charges[id]or 0,kind=d.kind,
   equipped=table.find(profile.tools.equipped,id)~=nil,price=d.price,pack=d.pack or 1,level=d.level,cooldownEnds=(cooldowns[p]or{})[id]or 0}end
  return data
 end
 function service:publish(p)if p.Parent==Players then changed:FireClient(p,self:snapshot(p))end end
 function service:setPass(p,id,value)
  passOwned[p]=passOwned[p]or{};passOwned[p][id]=value==true;self:rebuild(p);self:publish(p)
 end
 function service:attachTheft(s)theft=s end
 function service:cleanup(p)
  removeZones(p);for _,v in effects:GetChildren()do if v:GetAttribute('ProjectileOwner')==p.UserId then v:Destroy()end end;status:clear(p,false);trials[p]=nil;casting[p]=nil
 end
 function service:rebuild(p)
  local profile=profiles:get(p);local backpack=p:FindFirstChildOfClass('Backpack');if not profile or not backpack then return end
  local wanted={};for _,id in profile.tools.equipped do if owns(p,id)then wanted[id]=true end end
  if trials[p]then wanted[trials[p]]=true end
  local existing={}
  for _,container in {backpack,p.Character}do if container then for _,v in container:GetChildren()do
   if v:IsA('Tool') and v:GetAttribute('ToolId')then
    local id=v:GetAttribute('ToolId');if not wanted[id] or existing[id]then v:Destroy()else existing[id]=v end
   end
  end end end
  for id in wanted do if not existing[id]then
   local tool=templates[id]:Clone();tool.ToolTip=C.Items[id].name;tool:SetAttribute('Trial',trials[p]==id)
   local footwear
   tool.Equipped:Connect(function()if id=='ash_boots'and p.Character then if footwear then footwear:Destroy()end;footwear=Models.footwear(p.Character)end end)
   local function removeFootwear()if footwear then footwear:Destroy();footwear=nil end end
   tool.Destroying:Connect(removeFootwear)
   tool.Unequipped:Connect(function()removeFootwear();casting[p]=nil;if id=='ash_boots'then status:remove(p,'ash_boots')end end)
   tool.Parent=backpack
  end end
 end
 local function countZones(p,id)local n=0;for _,z in zones do if z.owner==p and z.id==id then n+=1 end end;return n end
 local function ground(p,aim)
  local r=root(p);if not r or not Math.vector(aim) or (aim-r.Position).Magnitude>10 or protected(p,aim)then return nil end
  if not los(r.Position,aim,{p.Character,effects,map.ActiveCurses})then return nil end
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={p.Character,effects,map.ActiveCurses}
  local hit=workspace:Raycast(aim+Vector3.new(0,3,0),Vector3.new(0,-9,0),params)
  if not hit or not hit.Instance.CanCollide or hit.Normal.Y<.8 then return nil end
  return hit.Position+Vector3.new(0,.12,0)
 end
 local function zone(p,id,at,d)
  local token=Http:GenerateGUID(false);local model=Instance.new('Model');model.Name=id..'_'..token;model:SetAttribute('Kind',id);model:SetAttribute('EffectToken',token);model:SetAttribute('OwnerUserId',p.UserId)
  model:SetAttribute('EndsAt',workspace:GetServerTimeNow()+d.duration)
  local body=Instance.new('Part');body.Name='Area';body.Anchored=true;body.CanCollide=false;body.CanTouch=false;body.CanQuery=false;body.Material=Enum.Material.Slate
  body.Size=if id=='mist_censer'then Vector3.new(2,.2,2)else if id=='consecrated_salt'then Vector3.new(9,.13,2)else Vector3.new(3,.15,3)
  body.Color=if id=='consecrated_salt'then Color3.fromRGB(225,213,173)else Color3.fromRGB(94,65,38)
  body.CFrame=CFrame.new(at)*CFrame.Angles(0,select(2,root(p).CFrame:ToOrientation()),0);body.Parent=model;model.PrimaryPart=body
  if id=='root_trap'then
   local art=Models.create(id)
   for _,part in art:GetChildren()do if part:IsA('BasePart')then part:ClearAllChildren();part.Anchored=true;part.CFrame=body.CFrame*part.CFrame;part.Parent=model end end;art:Destroy()
   local prompt=Instance.new('ProximityPrompt');prompt.Name='Disarm';prompt.ActionText='Disarm';prompt.ObjectText='Root Trap';prompt.HoldDuration=.7;prompt.MaxActivationDistance=5;prompt.Parent=body
   prompt.Triggered:Connect(function(q)local rr=root(q);if rr and (rr.Position-at).Magnitude<6 then zones[token]=nil;emit('disarm',at);model:Destroy()end end)
  elseif id=='double_mirror'then
   body.Size=Vector3.new(2,4,1);body.CanQuery=true;body.Transparency=.32;body.Color=Color3.fromRGB(127,181,191);body.CFrame+=Vector3.new(0,2,0)
   local head=body:Clone();head.Name='DecoyHead';head.Size=Vector3.new(1.25,1.25,1.25);head.Shape=Enum.PartType.Ball;head.CFrame=body.CFrame*CFrame.new(0,2.6,0);head.Parent=model
   for side=-1,1,2 do local arm=body:Clone();arm.Name='DecoyArm';arm.Size=Vector3.new(.65,2.4,.65);arm.CFrame=body.CFrame*CFrame.new(side*1.3,.2,0);arm.Parent=model end
   model:SetAttribute('Decoy',true);model:SetAttribute('HitPoints',1)
  end
  model.Parent=effects;zones[token]={id=id,owner=p,model=model,at=at,expires=os.clock()+d.duration,triggered={}}
  emit(id,at,{duration=d.duration,radius=d.radius or 3,token=token})
 end
 local function impact(p,at,radius,strength)
  local hits=0
  for _,q in Players:GetPlayers()do local rr=root(q)
   if q~=p and rr and root(p) and (rr.Position-at).Magnitude<=radius and not protected(p,rr.Position)and los(root(p).Position,rr.Position,{p.Character,q.Character,effects,map.ActiveCurses})and los(at+Vector3.new(0,1,0),rr.Position,{p.Character,q.Character,effects,map.ActiveCurses})then
    local delta=rr.Position-at;local horizontal=Vector3.new(delta.X,0,delta.Z);if horizontal.Magnitude<.1 then horizontal=Vector3.xAxis end
    if status:impulse(q,horizontal.Unit*strength+Vector3.new(0,5,0))then hits+=1;if theft then theft:interrupt(q,'The blast knocked the stolen Curse loose.')end end
   end
  end
  for token,z in zones do if z.id=='double_mirror'and (z.at-at).Magnitude<=radius and los(at+Vector3.new(0,1,0),z.at+Vector3.new(0,2,0),{p.Character,effects,map.ActiveCurses})then emit('decoy_break',z.at);z.model:Destroy();zones[token]=nil end end
  emit('impact',at,{radius=radius});return hits
 end
 -- Studio-only practice dummies (tag "ToolPracticeDummy") can be struck to
 -- test the ragdoll without a second player. They never exist in live games.
 local dummies={}
 -- Gravekeeper Shovel: one target, the closest in a frontal cone with line of
 -- sight. ~1 s ragdoll with a modest knockback, then recovery protection.
 local function melee(p,rr,d)
  local look=Vector3.new(rr.CFrame.LookVector.X,0,rr.CFrame.LookVector.Z).Unit
  local best,bestDistance,bestDummy=nil,math.huge,nil
  local function consider(target,targetRoot,dummy)
   local delta=targetRoot.Position-rr.Position;local flat=Vector3.new(delta.X,0,delta.Z);local distance=flat.Magnitude
   if distance>d.range or distance<.05 or math.abs(delta.Y)>5 or flat.Unit:Dot(look)<.35 then return end
   if protected(p,targetRoot.Position)then return end
   if not los(rr.Position,targetRoot.Position,{p.Character,target,effects,map.ActiveCurses})then return end
   if distance<bestDistance then best,bestDistance,bestDummy=target,distance,dummy end
  end
  for _,q in Players:GetPlayers()do local qr=root(q);if q~=p and qr then consider(q.Character,qr,nil)end end
  for dummy in dummies do local dr=dummy:FindFirstChild('HumanoidRootPart');if dr then consider(dummy,dr,dummy)end end
  local strike=rr.Position+look*math.min(bestDistance,d.range)
  if not best then
   -- Mirrors in the swing are shattered even when no player is hit.
   for token,z in zones do if z.id=='double_mirror'and (z.at-(rr.Position+look*3)).Magnitude<=4 then emit('decoy_break',z.at);z.model:Destroy();zones[token]=nil end end
   emit('swing',rr.Position+look*3,{userId=p.UserId});return
  end
  local velocity=look*24+Vector3.new(0,12,0)
  local landed
  if bestDummy then landed=status:ragdollCharacter(bestDummy,d.ragdoll,velocity)
  else
   local q=Players:GetPlayerFromCharacter(best)
   landed=q and status:ragdoll(q,d.ragdoll,velocity)
   if landed and theft then theft:interrupt(q,'A shovel strike knocked the stolen Curse loose.')end
  end
  emit(if landed then 'shovel_hit'else 'shovel_block',best:FindFirstChild('HumanoidRootPart').Position,{userId=p.UserId,target=if bestDummy then 0 else(Players:GetPlayerFromCharacter(best)or{UserId=0}).UserId})
 end
 if Run:IsStudio()then
  task.defer(function()
   local origin=service.practicePosition;if not origin then return end
   local ok,dummy=pcall(function()
    local description=Instance.new('HumanoidDescription')
    local skin=Color3.fromRGB(176,168,196);local cloth=Color3.fromRGB(84,70,110)
    description.HeadColor=skin;description.LeftArmColor=skin;description.RightArmColor=skin
    description.TorsoColor=cloth;description.LeftLegColor=cloth;description.RightLegColor=cloth
    return Players:CreateHumanoidModelFromDescription(description,Enum.HumanoidRigType.R15)
   end)
   if not ok or not dummy then return end
   dummy.Name='PracticeDummy';dummy:SetAttribute('StudioOnly',true)
   local h=dummy:FindFirstChildOfClass('Humanoid');h.DisplayName='Practice Dummy';h.MaxHealth=math.huge;h.Health=math.huge
   dummy:PivotTo(CFrame.lookAt(origin+Vector3.new(0,3,-7),origin+Vector3.new(0,3,0)))
   dummy.Parent=map;dummies[dummy]=true
   game:GetService('CollectionService'):AddTag(dummy,'ToolPracticeDummy')
  end)
 end
 function service:use(p,id,aim)
  local profile=profiles:get(p);local r=root(p);local d=C.Items[id];local tool=findTool(p,id)
  if not profile or not r or not d or not tool or not tool:IsA('Tool')or tool:GetAttribute('ToolId')~=id then return answer(false,'Hold the tool first.')end
  local trial=trials[p]==id
  if trial and (r.Position-self.practicePosition).Magnitude>20 then trials[p]=nil;self:rebuild(p);return answer(false,'Trials only work at the practice bench.')end
  if not trial and (not owns(p,id)or not table.find(profile.tools.equipped,id))then return answer(false,'That tool is not available.')end
  local now=workspace:GetServerTimeNow();cooldowns[p]=cooldowns[p]or{}
  if now<(cooldowns[p][id]or 0)then return answer(false,'Still recharging.')end
  if d.kind=='consumable'and (profile.tools.charges[id]or 0)<1 then return answer(false,'No charges left. Restock at the Gravekeeper\'s Bench.')end
  if id=='impact_urn'or id=='jailer_chain'then if not Math.vector(aim)or (aim-r.Position).Magnitude>d.range or (aim-r.Position).Magnitude<1 then return answer(false,'Aim within range.')end end
  local at
  if id=='root_trap'or id=='consecrated_salt'or id=='double_mirror'then
   at=ground(p,aim);if not at then return answer(false,'Find clear ground nearby.')end
   if countZones(p,id)>=(if id=='consecrated_salt'then 2 else 1)then return answer(false,'You already have the maximum placed.')end
  elseif id=='mist_censer'and countZones(p,id)>=1 then return answer(false,'Your mist is already active.')end
  if not trial and not I.consume(profile.tools,id)then return answer(false,'No charges left.')end
  cooldowns[p][id]=now+d.cooldown;profiles:commit(p);self:publish(p)
  local token=Http:GenerateGUID(false);casting[p]=token
  emit('anticipate',r.Position,{id=id,userId=p.UserId,duration=d.windup or .15})
  local wind=d.windup or .15
  -- Every client animates the user's arms from these (ToolAnimator).
  local character=p.Character
  character:SetAttribute('ToolActionId',id);character:SetAttribute('ToolActionWindup',wind)
  character:SetAttribute('ToolActionAt',now)
  task.delay(wind,function()
   local rr=root(p);if not rr or not tool.Parent or tool.Parent~=p.Character or casting[p]~=token then return end
   if id=='shovel'then
    melee(p,rr,d)
   elseif id=='ash_boots'then
    status:add(p,'ash_boots',{duration=d.duration,bonus=if carry:isBusy(p)then 3 else 10});emit('ash_boots',rr.Position,{userId=p.UserId,duration=d.duration})
   elseif id=='break_talisman'then status:clear(p,true);emit('cleanse',rr.Position)
   elseif id=='mist_censer'then zone(p,id,rr.Position-Vector3.new(0,2.8,0),d)
   elseif id=='root_trap'or id=='consecrated_salt'or id=='double_mirror'then zone(p,id,at,d)
   elseif id=='exorcist_lantern'then
    local found=0;for _,z in zones do if z.id~='consecrated_salt'and (z.at-rr.Position).Magnitude<=d.range and los(rr.Position,z.at+Vector3.new(0,1,0),{p.Character,effects,map.ActiveCurses})then
     found+=1;emit('reveal',z.at,{duration=3,token=z.model.Name})
    end end;souls:notify(p,if found>0 then tostring(found)..' hidden things revealed.'else 'No traps, mist or doubles nearby.');emit('lantern',rr.Position,{radius=d.range})
   elseif id=='jailer_chain'then
    local vector=aim-rr.Position;if vector.Magnitude>d.range then vector=vector.Unit*d.range end
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={p.Character,effects,map.ActiveCurses}
    local hit=workspace:Raycast(rr.Position,vector,params);local q=hit and Players:GetPlayerFromCharacter(hit.Instance:FindFirstAncestorOfClass('Model'))
    emit('chain',rr.Position,{finish=hit and hit.Position or rr.Position+vector,duration=.35})
    local target=q and root(q)
    -- Mist Censer counterplay: a target inside someone else's mist cannot be hooked.
    if target then for _,z in zones do
     if z.id=='mist_censer'and z.owner~=p and (Vector3.new(z.at.X,0,z.at.Z)-Vector3.new(target.Position.X,0,target.Position.Z)).Magnitude<=C.Items.mist_censer.radius then
      emit('chain_lost',target.Position,{});target=nil;break
     end
    end end
    if target and not(trial and (target.Position-self.practicePosition).Magnitude>20)and not protected(p,target.Position)then
     if target then local delta=rr.Position-target.Position
      if status:impulse(q,delta.Unit*22)then status:add(q,'chain',{duration=.6,slow=.75,negative=true});if theft then theft:interrupt(q,'The chain yanked the stolen Curse away.')end end
     end
    end
   elseif id=='impact_urn'then
    task.spawn(function()
     local start=rr.Position+rr.CFrame.LookVector*1.5;local prev=start
     local art=Models.create('impact_urn');local projectile=Instance.new('Model');projectile.Name='UrnProjectile';projectile:SetAttribute('ProjectileOwner',p.UserId)
     for _,v in art:GetChildren()do v.Parent=projectile end;art:Destroy();projectile.PrimaryPart=projectile.Handle;projectile.Parent=effects
     for _,v in projectile:GetChildren()do if v:IsA('BasePart')then v.Anchored=true end end
     local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={p.Character,effects,map.ActiveCurses}
     local finish=aim;local started=os.clock()
     while projectile.Parent do local t=math.min((os.clock()-started)/.75,1);local point=start:Lerp(finish,t)+Vector3.new(0,math.sin(t*math.pi)*6,0)
      local hit=workspace:Raycast(prev,point-prev,params);projectile:PivotTo(CFrame.new(point));if hit then finish=hit.Position;break end
      if t>=1 then break end;prev=point;task.wait(.04)
     end;local valid=projectile.Parent~=nil;projectile:Destroy();if valid and root(p)then impact(p,finish,d.radius,24)end
    end)
   end
  end)
  return answer(true,'Used.',self:snapshot(p))
 end
 function service:action(p,action,id,value)
  local profile=profiles:get(p);if not profile or not root(p)then return answer(false,'Wait for your character to load.')end
  if action=='snapshot'then return answer(true,'',self:snapshot(p))end
  if action=='use'then return self:use(p,id,value)end
  local d=C.Items[id];if not d then return answer(false,'Unknown item.')end
  if action=='buy'then
   if (root(p).Position-self.practicePosition).Magnitude>15 then return answer(false,'Get closer to the Gravekeeper\'s Bench.')end
   if profile.sanctuary.level<d.level then return answer(false,'Requires sanctuary level '..d.level..'.')end
   if d.kind=='permanent'and owns(p,id)then return answer(false,'You already own this tool.')end
   local n=d.pack or 1;if d.kind=='consumable'and (profile.tools.charges[id]or 0)+n>C.MaxCharges then return answer(false,'Charge inventory full.')end
   if d.price>0 and not souls:trySpend(p,d.price)then return answer(false,'Not enough Souls.')end
   assert(I.grant(profile.tools,id,n));profiles:commit(p);self:publish(p);return answer(true,'Added to your tools.',self:snapshot(p))
  elseif action=='equip'then
   if typeof(value)~='boolean'then return answer(false,'Invalid request.')end
   local ok,msg=I.equip(profile.tools,id,value,passOwned[p]and passOwned[p][id]);if ok then
    if not value then removeZones(p,id);casting[p]=nil;status:remove(p,id)end
    profiles:commit(p);self:rebuild(p);self:publish(p)
   end;return answer(ok,msg or 'Loadout updated.',self:snapshot(p))
  elseif action=='hold'then
   local t=p.Backpack:FindFirstChild(id);local h=p.Character:FindFirstChildOfClass('Humanoid');if t and t:GetAttribute('ToolId')==id and h then h:EquipTool(t);return answer(true,'Tool in hand.')end
  elseif action=='trial'then
   if not Run:IsStudio()or not (id=='jailer_chain'or id=='double_mirror')or (root(p).Position-self.practicePosition).Magnitude>20 then return answer(false,'Premium trials only run at this bench in Studio.')end
   trials[p]=id;self:rebuild(p);local t=p.Backpack:FindFirstChild(id);if t then p.Character.Humanoid:EquipTool(t)end;return answer(true,'Local trial: no ownership granted.')
  end;return answer(false,'Action not available.')
 end
 request.OnServerInvoke=function(p,action,id,value)
  if typeof(action)~='string'or #action>24 or (id~=nil and (typeof(id)~='string'or #id>40))then return answer(false,'Invalid request.')end
  local now=os.clock();if now-(spam[p]or -1e6)<C.RequestInterval then return answer(false,'One moment.')end;spam[p]=now
  return service:action(p,action,id,value)
 end
 -- A small station beside the contract board, not another shop/HUD rewrite.
 local board=map:FindFirstChild('ContractBoard',true);local pos=if board then board.Position+Vector3.new(14,-2,0)else Vector3.new(-148,2,90)
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={effects}
 local hit=workspace:Raycast(pos+Vector3.new(0,12,0),Vector3.new(0,-30,0),params);pos=if hit then hit.Position+Vector3.new(0,1.2,0)else pos
 service.practicePosition=pos
 local station=Instance.new('Model');station.Name='ToolsPractice';station.Parent=map
 local tablePart=Instance.new('Part');tablePart.Name='PracticeStation';tablePart.Size=Vector3.new(6,1,3);tablePart.CFrame=CFrame.new(pos);tablePart.Color=Color3.fromRGB(74,49,33);tablePart.Material=Enum.Material.Wood;tablePart.Anchored=true;tablePart.Parent=station
 for side=-1,1,2 do local leg=tablePart:Clone();leg.Name='TableLeg';leg.Size=Vector3.new(.55,2,.55);leg.CFrame=tablePart.CFrame*CFrame.new(side*2.5,-1.25,0);leg.Parent=station end
 local prompt=Instance.new('ProximityPrompt');prompt.Name='ToolStation';prompt.ObjectText='Gravekeeper\'s Bench';prompt.ActionText='Tools';prompt.RequiresLineOfSight=false;prompt.MaxActivationDistance=12;prompt.Parent=tablePart
 prompt.Triggered:Connect(function(p)local rr=root(p);if rr and(rr.Position-pos).Magnitude<15 then changed:FireClient(p,service:snapshot(p),true)end end)
 profiles:onLoaded(function(p)service:rebuild(p);service:publish(p)end)
 local function track(p)
  p.CharacterRemoving:Connect(function()service:cleanup(p)end)
  p.CharacterAdded:Connect(function(c)local h=c:WaitForChild('Humanoid',10);if h then h.Died:Once(function()service:cleanup(p)end)end;task.wait(.2);service:rebuild(p)end)
 end
 Players.PlayerAdded:Connect(track);for _,p in Players:GetPlayers()do track(p)end
 Players.PlayerRemoving:Connect(function(p)service:cleanup(p);cooldowns[p]=nil;spam[p]=nil;passOwned[p]=nil end)
 task.spawn(function()
  while map.Parent do task.wait(.1);local now=os.clock()
   for token,z in zones do
    if now>=z.expires or not z.model.Parent or not root(z.owner)then z.model:Destroy();zones[token]=nil
    elseif z.id=='root_trap'or z.id=='consecrated_salt'then
     for _,q in Players:GetPlayers()do local rr=root(q)
      if q~=z.owner and rr and not protected(z.owner,rr.Position)then
       local relative=z.model.PrimaryPart.CFrame:PointToObjectSpace(rr.Position)
       local inside=math.abs(relative.Y)<4 and math.abs(relative.X)<(if z.id=='root_trap'then 1.8 else 4.5)and math.abs(relative.Z)<(if z.id=='root_trap'then 1.8 else 1)
       if inside and los(z.at+Vector3.new(0,.5,0),rr.Position,{z.owner.Character,q.Character,effects,map.ActiveCurses})then
        if z.id=='root_trap'and not z.triggered[q]then
         if status:add(q,'roots',{root=true,negative=true,duration=1.1})then z.triggered[q]=true;z.expires=now+.2;emit('roots',rr.Position);if theft then theft:interrupt(q,'Roots tore the stolen Curse loose.')end end
        elseif z.id=='consecrated_salt'then status:add(q,'salt',{slow=.65,negative=true,duration=.3})end
       end
      end
     end
    end
   end
   for p in trials do local rr=root(p);if not rr or(rr.Position-pos).Magnitude>20 then trials[p]=nil;service:rebuild(p);removeZones(p)end end
  end
 end)
 return service
end
return Tools
