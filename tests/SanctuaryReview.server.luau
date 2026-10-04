-- Local-only fixture invoking the same production services at validated positions.
-- Teleporting to a marker tests server rules, not real walking/navigation.
local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local Http=game:GetService('HttpService')
assert(game:GetService('RunService'):IsStudio(),'Local review only')
local evidence=Instance.new('Folder');evidence.Name='SanctuaryReview';evidence.Parent=RS
local rows={}
local function record(ok,label,detail)
 table.insert(rows,{ok=ok,label=label,detail=detail});evidence:SetAttribute('ResultsJSON',Http:JSONEncode(rows))
 assert(ok,label..': '..tostring(detail));print('RESTORATION_PASS',label)
end
local function await(fn,seconds)
 local deadline=os.clock()+seconds;repeat if fn() then return true end;task.wait(.1) until os.clock()>deadline;return false
end
task.spawn(function()
 local ok,failure=xpcall(function()
  evidence:SetAttribute('Stage','BOOT')
  if not RS:GetAttribute('FullRestorationReview') then
   local unit=require(game.ServerStorage.UnitTest.RunUnitTest)();evidence:SetAttribute('UnitJSON',Http:JSONEncode(unit));assert(unit.failed==0,'Unit failures')
  end
  local map=require(script.Map.Build).build()
  local profiles=require(script.Gameplay.ProfileStore).start();local souls=require(script.Gameplay.SoulsService).start(profiles)
  local bases=require(script.Gameplay.BaseService).start(map)
  local sanctuary=require(script.Gameplay.SanctuaryService).start(map,bases,souls,profiles)
  local carry=require(script.Gameplay.CarryService).start(map)
  local curses=require(script.Gameplay.CurseService).start(map,bases,souls,profiles)
  local contracts=require(script.Gameplay.ContractService).start(map,bases,profiles,souls,carry,function(p)sanctuary:changed(p)end,function(p,page)sanctuary:open(p,page)end)
  local rituals=require(script.Gameplay.RitualService).start(map,bases,profiles,curses,carry,souls,function(p)sanctuary:changed(p)end)
  sanctuary:attach(curses,contracts,rituals)
  require(script.Gameplay.CurseProcessionService).start(map,curses)
  record(await(function()local p=Players:GetPlayers()[1];return p and p:GetAttribute('ProfileStatus')=='READY' and p.Character and p.Character:FindFirstChild('HumanoidRootPart') end,45),'actual local profile loaded')
  local player=Players:GetPlayers()[1];local p=profiles:get(player);local base=bases:getBaseById('Base03')
  local function pose(frame)
   player.Character:PivotTo(frame);player.Character.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero;task.wait(.3)
  end
  local function near(marker)pose(marker.CFrame*CFrame.new(0,1,-3))end
  near(base.ClaimMarker);evidence:SetAttribute('Stage','WAIT_CLAIM')
  record(await(function()return bases:getBaseForPlayer(player)==base end,180),'native E claim')
  local context={player=player,profiles=profiles,bases=bases,curses=curses,contracts=contracts,rituals=rituals,sanctuary=sanctuary,map=map,souls=souls,carry=carry,near=near,pose=pose,record=record,await=await}
  if game.ServerStorage:FindFirstChild('NativeReview')then require(game.ServerStorage.NativeReview)(context)end
  if p.sanctuary.level==10 then
   record(#p.curses==6 and p.sanctuary.featuredUid~=nil and p.sanctuary.rituals.dominion,'durable advanced ownership rituals and featured reload')
   local featured;for _,r in p.curses do if r.uid==p.sanctuary.featuredUid then featured=r end end
   record(featured and featured.pedestalId=='floor3-slot10' and base:GetAttribute('FeaturedPedestalId')==featured.pedestalId,'durable featured current floor rebuilt')
   record(base:GetAttribute('RestorationLevel')==10 and #bases:getSlots(base)==30 and base:GetAttribute('SanctuaryStyle')==p.sanctuary.style,'durable advanced architecture and style reconstructed')
   evidence:SetAttribute('ReloadProfileJSON',Http:JSONEncode(p));evidence:SetAttribute('Stage','FULL_RELOAD_PASS');sanctuary:open(player,'UPGRADE');return
  end
  if p.sanctuary.level>0 and RS:GetAttribute('FullRestorationReview') then
   evidence:SetAttribute('Stage','FULL_REVIEW')
   local result=require(game.ServerStorage.FullReview)({player=player,profiles=profiles,bases=bases,curses=curses,contracts=contracts,rituals=rituals,sanctuary=sanctuary,map=map,souls=souls,carry=carry,near=near,pose=pose,record=record,await=await})
   evidence:SetAttribute('FullReviewJSON',Http:JSONEncode(result));evidence:SetAttribute('Stage','FULL_PASS');sanctuary:open(player,'UPGRADE');return
  end
  if p.sanctuary.level>0 then
   record(p.sanctuary.level==1 and p.sanctuary.rituals.first_vigil and p.sanctuary.milestones.contracts==1,'durable stage ritual and contract reload')
   record(p.sanctuary.discoveries.cursed_doll and #p.curses==1 and p.curses[1].pedestalId=='floor1-slot1','durable real ownership and logical placement reload')
   record(base:GetAttribute('RestorationLevel')==1 and #bases:getSlots(base)==6,'durable architecture reconstructed')
   evidence:SetAttribute('Stage','RELOAD_PASS');sanctuary:open(player,'UPGRADE');return
  end
  record(p.souls==500 and #p.curses==0 and p.sanctuary.fragments==0,'clean new account without test balance')
  evidence:SetAttribute('Stage','FIRST_FLOW')
  near(contracts:getNode(player,'gravekeeper_board'));local accepted,message=contracts:accept(player,'lost_seal');record(accepted,'recovery contract accepted',message)
  near(contracts:getNode(player,'cemetery_gate'));local picked,why=contracts:interact(player,'cemetery_gate');record(picked and carry:get(player)~=nil,'real physical relic picked',why)
  local uid=curses:spawn('cursed_doll',player.Character.HumanoidRootPart.CFrame*CFrame.new(0,3.5,-4))
  record(not curses:purchase(player,uid),'relic excludes simultaneous Curse purchase')
  near(contracts:getNode(player,'sanctuary_altar'));local delivered,delivery=contracts:interact(player,'sanctuary_altar');record(delivered and not carry:get(player) and p.sanctuary.fragments==4,'physical delivery awards once',delivery)
  record(not contracts:interact(player,'sanctuary_altar') and p.sanctuary.fragments==4,'duplicate delivery cannot pay')
  local model;for _,m in map.ActiveCurses:GetChildren()do if m:GetAttribute('CurseUid')==uid then model=m end end
  near(model.PrimaryPart);record(curses:purchase(player,uid),'production purchase succeeds after relic delivery')
  record(not p.sanctuary.discoveries.cursed_doll,'purchase without placement does not discover')
  local slot=bases:getPedestals(base)['floor1-slot1'];near(slot)
  local placed=curses:action(player,'place',uid,'floor1-slot1');record(placed.ok and p.sanctuary.discoveries.cursed_doll,'legitimate manual placement records one species',placed.message)
  near(base.RestorationAltar);local began,start=rituals:begin(player,'first_vigil');record(began,'first ritual uses actual owned species',start)
  for _,index in {1,2} do near(base.RitualMarkers['RitualMark_'..index]);local activated,reason=rituals:activate(player,index);record(activated,'first ritual physical mark '..index,reason) end
  record(p.sanctuary.rituals.first_vigil and #p.curses==1 and curses:getState(uid)=='PLACED','ritual consumes no Curse and leaves real production instance')
  near(base.RestorationAltar);local before=p.souls;local upgrade=sanctuary:action(player,'upgrade','0');record(upgrade.ok and p.sanctuary.level==1 and p.souls>=before-150,'first upgrade grants permanent capacity',upgrade.message)
  record(#bases:getSlots(base)==6 and slot:GetAttribute('OccupiedCurseUid')==uid,'upgrade adds empty slot and preserves occupied identity')
  local balance=p.souls;record(not sanctuary:action(player,'upgrade','0').ok and p.souls==balance,'stale duplicate upgrade cannot debit')
  record(profiles:flush(player,false),'local journal flush acknowledged')
  evidence:SetAttribute('Stage','FIRST_FLOW_PASS');sanctuary:open(player,'UPGRADE')
 end,debug.traceback)
 if not ok then evidence:SetAttribute('Stage','FAILED');evidence:SetAttribute('Failure',tostring(failure));warn('RESTORATION_REVIEW_FAILED',failure) end
end)
