local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local Http=game:GetService('HttpService')
local Collection=game:GetService('CollectionService')
local p=game.Players.LocalPlayer
local signal=RS:WaitForChild('AnimationPerformance',45)
local folder=workspace:WaitForChild('AnimationPerformance',45)
local Animation=require(script.Parent:WaitForChild('Client',30):WaitForChild('CurseAnimation',30))
local gui=Instance.new('ScreenGui');gui.Name='AnimationPerformanceControls';gui.Parent=p.PlayerGui
local b=Instance.new('TextButton');b.Size=UDim2.fromOffset(240,40);b.Position=UDim2.new(0,15,1,-60)
b.Text='Test 56 rigs / LOD / cleanup';b.Parent=gui
local busy=false;local camera=workspace.CurrentCamera
local function realMesh(model)
 if not model:IsA('Model') then return nil end
 local mesh=model:FindFirstChild('CurseMesh')
 return if mesh and mesh:IsA('MeshPart') and mesh.MeshId~='' then mesh else nil
end
local function liveTaggedModels()
 local count=0
 for _,model in Collection:GetTagged('ExpansionCurseVFX') do
  if model:IsDescendantOf(workspace) and realMesh(model) then count+=1 end
 end
 return count
end
local function measure(label,position,seconds)
 local samples={};local first=Animation.metrics();local started=os.clock();local ending=started+seconds
 while os.clock()<ending do
  camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=75
  camera.CFrame=CFrame.lookAt(position,Vector3.new(0,5,150))
  table.insert(samples,Run.RenderStepped:Wait())
 end
 table.sort(samples);local sum=0;for _,dt in samples do sum+=dt end
 local elapsed=os.clock()-started
 local last=Animation.metrics();local models,loaded,waiting,vfxBound,lights,emitters=0,0,0,0,0,0
 local children=folder:GetChildren();local invalidChildren,unloaded={},{}
 for _,m in children do
  if not realMesh(m) then
   table.insert(invalidChildren,m.Name..' ('..m.ClassName..')')
   continue
  end
  models+=1
  if m:GetAttribute('MeshPreloadStatus')=='Success' then loaded+=1 else
   waiting+=1
   table.insert(unloaded,m.Name..': '..tostring(m:GetAttribute('MeshPreloadStatus')))
  end
  for _,x in m:GetDescendants()do
   if x:IsA('Attachment')and x:GetAttribute('AnimatedVFXBone')then vfxBound+=1 end
   if x:IsA('ParticleEmitter')and x.Rate>0 then emitters+=1 end
   if x:IsA('PointLight')and x.Enabled then lights+=1 end
  end
 end
 return {label=label,models=models,folderChildren=#children,loaded=loaded,waiting=waiting,
  invalidChildren=invalidChildren,unloaded=unloaded,liveTaggedModels=liveTaggedModels(),vfxBound=vfxBound,
  emitters=emitters,lights=lights,touch=game:GetService('UserInputService').TouchEnabled,
  frames=#samples,elapsedSeconds=elapsed,meanFrameSeconds=if #samples>0 then sum/#samples else 0,
  p95FrameSeconds=samples[math.ceil(#samples*.95)] or 0,maxFrameSeconds=samples[#samples] or 0,
  first=first,last=last,boneWrites=last.boneWrites-first.boneWrites,poses=last.posed-first.posed,
  boneWritesPerSecond=(last.boneWrites-first.boneWrites)/elapsed}
end
b.Activated:Connect(function()
 if busy then return end;busy=true;p:SetAttribute('PerformanceStatus','RUNNING')
 local rows,checks,failures={},{},{}
 p:SetAttribute('PerformanceChecks','[]');p:SetAttribute('PerformanceFailures','[]')
 local function check(name,passed,observed)
  table.insert(checks,{name=name,passed=passed,observed=observed})
  if not passed then
   local message=name..': '..observed
   table.insert(failures,message);warn('[AnimationPerformance] FAIL '..message)
  end
 end
 local function fixtureReady(row)
  check(row.label..' / 56 real meshes loaded',row.models==56 and row.loaded==56 and row.waiting==0 and #row.invalidChildren==0,
   Http:JSONEncode({models=row.models,loaded=row.loaded,waiting=row.waiting,invalid=row.invalidChildren,unloaded=row.unloaded}))
 end
 local ok,problem=xpcall(function()
  table.insert(rows,measure('baseline',Vector3.new(0,25,228),4))
  signal:FireServer('spawn');task.wait(12)
  local near=measure('56-near-and-mid',Vector3.new(0,25,228),8);table.insert(rows,near)
  local far=measure('56-far',Vector3.new(0,90,650),6);table.insert(rows,far)
  -- Revisit the same view before deleting anything: frozen distant poses must resume.
  local resume=measure('56-return-near',Vector3.new(0,25,228),6);table.insert(rows,resume)
  signal:FireServer('clear');task.wait(2)
  local cleanup=measure('after-cleanup',Vector3.new(0,25,228),4);table.insert(rows,cleanup)
  fixtureReady(near);fixtureReady(far);fixtureReady(resume)
  for _,row in rows do
   check(row.label..' / no missing acts',row.first.missingActs==0 and row.last.missingActs==0,
    string.format('first=%d, last=%d',row.first.missingActs,row.last.missingActs))
  end
  for _,row in {near,resume} do
   check(row.label..' / active bone writes',row.boneWrites>0 and row.poses>0,
    string.format('boneWrites=%d, poses=%d',row.boneWrites,row.poses))
  end
  check('far / 56 rigs suspended',far.last.suspended>=56,string.format('suspended=%d',far.last.suspended))
  check('far / reduced bone work',far.boneWritesPerSecond<near.boneWritesPerSecond,
   string.format('near=%.2f/s, far=%.2f/s',near.boneWritesPerSecond,far.boneWritesPerSecond))
  check('return-near / suspension released',resume.last.suspended<far.last.suspended,
   string.format('far=%d, return-near=%d',far.last.suspended,resume.last.suspended))
  check('cleanup / fixture empty',cleanup.folderChildren==0 and cleanup.models==0,
   string.format('children=%d, models=%d',cleanup.folderChildren,cleanup.models))
  -- Natural offers keep spawning. Compare against live tagged meshes at this snapshot,
  -- not the baseline count, which is no longer expected to remain constant.
  check('cleanup / tracked matches live meshes',cleanup.last.tracked==cleanup.liveTaggedModels,
   string.format('tracked=%d, liveTaggedMeshes=%d',cleanup.last.tracked,cleanup.liveTaggedModels))
 end,debug.traceback)
 if not ok then
  check('test execution',false,tostring(problem))
  signal:FireServer('clear')
 end
 p:SetAttribute('PerformanceObserved',Http:JSONEncode(rows))
 p:SetAttribute('PerformanceChecks',Http:JSONEncode(checks))
 p:SetAttribute('PerformanceFailures',Http:JSONEncode(failures))
 local status=if #failures==0 then 'PASS' else 'FAIL'
 p:SetAttribute('PerformanceStatus',status);busy=false
 print(string.format('[AnimationPerformance] %s: %d checks, %d failures',status,#checks,#failures))
end)
