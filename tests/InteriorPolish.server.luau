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
  record(p.sanctuary.level==0 and #p.curses==0,'isolated interior profile starts empty')
  local unit=require(game.ServerStorage.UnitTest.RunUnitTest)('Architecture')
  evidence:SetAttribute('UnitJSON',Http:JSONEncode(unit))
  local A=require(script.Map.RestorationArchitecture)
  local before=require(game.ServerStorage.ArchitectureBefore.RestorationArchitecture)
  local control=Instance.new('RemoteFunction');control.Name='InteriorPolish';control.Parent=RS
  local display=bases:getBaseById('Base01')
  local busy=false
  local function counts(b)
   local n,l=0,0 for _,v in b:GetDescendants()do if v:IsA('BasePart')then n+=1 elseif v:IsA('PointLight')then l+=1 end end return {parts=n,lights=l}
  end
  local level,style,old=8,'CRYPT',false
  local function show()
   (if old then before else A).apply(display,level,style,nil)
   control:SetAttribute('Level',level);control:SetAttribute('Style',style);control:SetAttribute('Before',old)
   return {frame=A.getFrame(display),level=level,style=style,before=old,counts=counts(display)}
  end
  control.OnServerInvoke=function(sender,action,value)
   if sender~=player or busy then return nil end
   if action=='level' then level=math.clamp(tonumber(value) or 0,0,10);return show()
   elseif action=='style' then if table.find({'CRYPT','FOREST','OBSERVATORY'},value)then style=value end return show()
   elseif action=='before' then old=not old;return show()
   elseif action=='all' then
    local results={}
    for i=1,8 do
     local b=bases:getBaseById(string.format('Base%02d',i))
     local renderer=if value then before else A;renderer.apply(b,10,({'CRYPT','FOREST','OBSERVATORY'})[(i-1)%3+1],nil)
     results[b.Name]=counts(b)
    end
    control:SetAttribute(value and 'BeforeLoadJSON' or 'AfterLoadJSON',Http:JSONEncode(results));return results
   elseif action=='walk' then
    busy=true
    task.spawn(function()
     local ok,answer=xpcall(function()
      -- Only the isolated QA namespace is provisioned for this traversal.
      p.sanctuary.level=10;A.apply(base,10,'CRYPT',nil);souls:credit(player,60000);sanctuary:changed(player)
      local uid=curses:spawn('the_void',player.Character.HumanoidRootPart.CFrame*CFrame.new(0,3,-4))
      local m for _,v in map.ActiveCurses:GetChildren()do if v:GetAttribute('CurseUid')==uid then m=v end end
      near(m.PrimaryPart);assert(curses:purchase(player,uid),'Large Curse actual purchase')
      near(bases:getPedestals(base)['floor1-slot2']);assert(curses:action(player,'place',uid,'floor1-slot2').ok,'Initial large placement')
      near(base.RestorationAltar);local sealed=sanctuary:action(player,'seal');record(sealed.ok and base.SealBarrier.CanCollide,'Actual seal activation with rebuilt entrance')
      context.spatialDefinitionId='the_void'
      return require(game.ServerStorage.SpatialReview)(context)
     end,debug.traceback)
     control:SetAttribute('SpatialJSON',Http:JSONEncode({ok=ok,result=answer}));control:SetAttribute('Stage',ok and 'WALK_PASS' or 'WALK_FAILED');busy=false
    end)
    return {frame=A.getFrame(base)}
   end
   return show()
  end
  show();control:SetAttribute('Stage','READY');evidence:SetAttribute('Stage','POLISH_READY')
 end,debug.traceback)
 if not ok then evidence:SetAttribute('Stage','FAILED');evidence:SetAttribute('Failure',tostring(failure));warn('RESTORATION_REVIEW_FAILED',failure) end
end)
