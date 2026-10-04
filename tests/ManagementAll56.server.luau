local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Http=game:GetService('HttpService')
local Catalog=require(RS.Shared.CurseCatalog)
local ready,answers={},{}
local control=Instance.new('RemoteEvent');control.Name='ManagementTestControl';control.Parent=RS
control.OnServerEvent:Connect(function(p,nonce,ok,value)
 if nonce=='ready'then ready[p]=true else answers[nonce]={player=p,ok=ok,value=value}end
end)
local map=require(script.Map.Build).build()
local profiles=require(script.Gameplay.ProfileStore).start()
local souls=require(script.Gameplay.SoulsService).start(profiles)
local bases=require(script.Gameplay.BaseService).start(map)
local curses=require(script.Gameplay.CurseService).start(map,bases,souls,profiles)
local p=Players:GetPlayers()[1]or Players.PlayerAdded:Wait()
local rows={};local seq=0
local function await(fn,seconds)
 local finish=os.clock()+seconds
 repeat if fn()then return true end;task.wait(.1)until os.clock()>finish
 return false
end
local function client(action,args)
 seq+=1;local nonce=tostring(seq);control:FireClient(p,nonce,action,args)
 assert(await(function()return answers[nonce]end,12),'client '..action)
 local a=answers[nonce];answers[nonce]=nil;assert(a.ok,tostring(a.value));task.wait(.14);return a.value
end
local function pose(pos)
 p.Character:PivotTo(CFrame.new(pos));p.Character.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero;task.wait(.12)
end
local function model(uid)
 for _,m in map.ActiveCurses:GetChildren()do if m:GetAttribute('CurseUid')==uid then return m end end
end
task.spawn(function()
 local ok,err=pcall(function()
  assert(await(function()return ready[p]and p:GetAttribute('ProfileStatus')=='READY'and p.Character and p.Character:FindFirstChild('HumanoidRootPart')end,30),'ready')
  local base=bases:getBaseById('Base03');pose(base.ClaimMarker.Position-Vector3.new(0,2,0))
  client('prompt',base.ClaimMarker.ClaimSanctuary)
  map:SetAttribute('Management56Status','WAITING_CLAIM')
  assert(await(function()return bases:getBaseForPlayer(p)==base end,60),'native claim')
  local slots=bases:getPedestals(base);local one,two=slots['floor1-slot1'],slots['floor1-slot2']
  souls:credit(p,10000000);profiles:commit(p)
  for _,id in Catalog.enabledSpawnIds()do
   local d=Catalog.Definitions[id];pose(Vector3.new(0,4,38))
   local uid=curses:spawn(id,CFrame.new(0,5.3,34));task.wait(.15)
   local m=model(uid);local mesh=m.CurseMesh;local boneCount=0
   for _,b in mesh:GetDescendants()do if b:IsA('Bone')then boneCount+=1 end end
   assert(mesh.MeshId==d.meshId and boneCount>0,'real imported rig '..id)
   assert(curses:purchase(p,uid),'purchase '..id)
   assert(p:GetAttribute('SoulsPerSecond')==0 and curses:getState(uid)=='CARRYING','carrying '..id)
   local h=p.Character.Humanoid;local start=p.Character.HumanoidRootPart.Position
   h:MoveTo(start+Vector3.new(10,0,0));task.wait(.8)
   assert((p.Character.HumanoidRootPart.Position-start).Magnitude>2,'physical transport '..id)
   pose(one.Position+Vector3.new(0,3.5,4));assert(client('place',{uid,'floor1-slot1'}).ok,'place '..id)
   assert(p:GetAttribute('SoulsPerSecond')==d.baseSoulsPerSecond,'production '..id)
   assert(client('pickup',{uid}).ok,'pickup '..id)
   assert(p:GetAttribute('SoulsPerSecond')==0 and one:GetAttribute('OccupiedCurseUid')==nil,'freed '..id)
   pose(two.Position+Vector3.new(0,3.5,4));assert(client('place',{uid,'floor1-slot2'}).ok,'relocate '..id)
   local q=client('quote',{uid}).data;assert(q.sale==math.floor(d.price*.5),'exact sale '..id)
   assert(client('sell',{uid,nil,q.token}).ok,'sell '..id)
   assert(not model(uid)and not two:GetAttribute('OccupiedCurseUid')and p:GetAttribute('SoulsPerSecond')==0,'clean '..id)
   table.insert(rows,{id=id,meshId=mesh.MeshId,bones=boneCount,price=d.price,sale=q.sale,income=d.baseSoulsPerSecond,manualPlacement=true,physicalWalkStuds=10,passed=true})
   map:SetAttribute('Management56Observed',Http:JSONEncode(rows));print('MANAGEMENT_56_PASS',id)
  end
  assert(#rows==56,'full roster');assert(profiles:flush(p,false),'durable flush')
  map:SetAttribute('Management56Status','PASS')
 end)
 if not ok then map:SetAttribute('Management56Status','FAIL');warn('MANAGEMENT_56_FAIL',err)end
end)
