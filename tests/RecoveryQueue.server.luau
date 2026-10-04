-- Stress only a disposable namespace. The production store and services own
-- every transition after this test-only saved-profile setup.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Http=game:GetService('HttpService')
local ready,answers={},{}
local control=Instance.new('RemoteEvent');control.Name='ManagementTestControl';control.Parent=RS
control.OnServerEvent:Connect(function(p,nonce,ok,value)
 if nonce=='ready' then ready[p]=true else answers[nonce]={player=p,ok=ok,value=value}end
end)
local map=require(script.Map.Build).build()
local profiles=require(script.Gameplay.ProfileStore).start()
local souls=require(script.Gameplay.SoulsService).start(profiles)
local bases=require(script.Gameplay.BaseService).start(map)
local function await(fn,seconds)
 local finish=os.clock()+seconds
 repeat if fn()then return true end;task.wait(.1)until os.clock()>finish
 return false
end
local p=Players:GetPlayers()[1]or Players.PlayerAdded:Wait()
assert(await(function()return profiles:get(p)and p.Character and p.Character:FindFirstChild('HumanoidRootPart')end,30),'profile ready')
local defs={'the_void','the_unwritten','the_last_star','the_first_grave','nameless_door','crown_of_silence','cursed_doll','cold_teacup'}
local profile=profiles:get(p);profile.curses={}
for i=1,128 do table.insert(profile.curses,{uid=string.format('queue-%03d',i),definitionId=defs[(i-1)%#defs+1],state='UNPLACED',revision=0})end
profile.souls=500;profiles:commit(p)
local curses=require(script.Gameplay.CurseService).start(map,bases,souls,profiles)
local base=bases:getBaseById('Base02')
local seq=0;local observed={}
local function check(ok,label,data)
 table.insert(observed,{ok=not not ok,label=label,data=data})
 map:SetAttribute('RecoveryQueueObserved',Http:JSONEncode(observed))
 assert(ok,label);print('RECOVERY_QUEUE_PASS',label)
end
local function client(action,args)
 seq+=1;local nonce=tostring(seq);control:FireClient(p,nonce,action,args)
 assert(await(function()return answers[nonce]end,12),'client '..action)
 local a=answers[nonce];answers[nonce]=nil;assert(a.ok,tostring(a.value));task.wait(.16);return a.value
end
local function pose(pos)
 p.Character:PivotTo(CFrame.new(pos));p.Character.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero;task.wait(.25)
end
local function visible()
 local models={}
 for _,m in map.ActiveCurses:GetChildren()do if m:GetAttribute('OwnerUserId')==p.UserId and m:GetAttribute('CurseState')=='UNPLACED'then table.insert(models,m)end end
 table.sort(models,function(a,b)return a:GetAttribute('CurseUid')<b:GetAttribute('CurseUid')end)
 return models
end
task.spawn(function()
 local ok,err=pcall(function()
  assert(await(function()return ready[p]end,12),'management client ready')
  pose(base.ClaimMarker.Position-Vector3.new(0,2,0));client('prompt',base.ClaimMarker.ClaimSanctuary)
  map:SetAttribute('RecoveryQueueStatus','WAITING_CLAIM')
  check(await(function()return bases:getBaseForPlayer(p)==base end,60),'native sanctuary claim')
  check(#profiles:get(p).curses==128 and #visible()==6 and p:GetAttribute('SoulsPerSecond')==0,'128 owned retained; six physical bays; zero income')
  local positions={}
  for _,m in visible()do
   local root=m.PrimaryPart;local localPos=base.PlayerSpawn.CFrame:PointToObjectSpace(root.Position)
   check(math.abs(localPos.X)<=15.01 and localPos.Z>=-3.01 and localPos.Z<=10.01,'recovery bay remains in front court '..m:GetAttribute('CurseUid'),{localPos.X,localPos.Y,localPos.Z})
   table.insert(positions,{x=root.Position.X,z=root.Position.Z,width=root.Size.X,depth=root.Size.Z})
  end
  for i=1,#positions do for j=i+1,#positions do
   local a,b=positions[i],positions[j]
   check(math.abs(a.x-b.x)>(a.width+b.width)/2+.25 or math.abs(a.z-b.z)>(a.depth+b.depth)/2+.25,'large recovery visuals have separate footprints '..i..' '..j)
  end end
  local slot=bases:getPedestals(base)['floor1-slot1']
  for i=1,9 do
   local before=#profiles:get(p).curses;local m=visible()[1];local uid=m:GetAttribute('CurseUid')
   pose(m.PrimaryPart.Position+Vector3.new(0,0,4))
   check(client('pickup',{uid}).ok,'manual pickup queued instance '..i)
   check(#visible()==6 and p:GetAttribute('SoulsPerSecond')==0,'freed bay materializes next waiting instance '..i)
   pose(slot.Position+Vector3.new(0,3.5,4));check(client('place',{uid,'floor1-slot1'}).ok,'manual place from queue '..i)
   local q=client('quote',{uid}).data;check(q and client('sell',{uid,nil,q.token}).ok,'single sale after manual recovery '..i)
   check(#profiles:get(p).curses==before-1 and p:GetAttribute('SoulsPerSecond')==0,'queue and income consistent after sale '..i)
  end
  local m=visible()[1];local uid=m:GetAttribute('CurseUid');pose(m.PrimaryPart.Position+Vector3.new(0,0,4))
  check(client('pickup',{uid}).ok,'carry before full-bay death')
  p.Character.Humanoid.Health=0
  check(await(function()return curses:getState(uid)=='UNPLACED'end,5),'death retains queued Curse when every bay is occupied')
  check(#visible()==6 and #profiles:get(p).curses==119 and p:GetAttribute('SoulsPerSecond')==0,'death has no teleport to pedestal, duplication or income')
  check(profiles:flush(p,false),'all 119 remaining records acknowledged by durable provider')
  map:SetAttribute('RecoveryQueueStatus','PASS')
 end)
 if not ok then map:SetAttribute('RecoveryQueueStatus','FAIL');warn('RECOVERY_QUEUE_FAIL',err)end
end)
