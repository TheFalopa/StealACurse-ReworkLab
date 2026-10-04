-- Native frame measurements only. Production owns mesh poses and VFX writes.
local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local Run = game:GetService('RunService')
local Http = game:GetService('HttpService')
local Collection = game:GetService('CollectionService')
local Input = game:GetService('UserInputService')
local Capture = game:GetService('CaptureService')
assert(Run:IsStudio(), 'Sanctuary performance client is local Studio QA only')
local player = Players.LocalPlayer
local control = RS:WaitForChild('SanctuaryPerformanceControl',120)
assert(control, 'Sanctuary performance server fixture did not start')
local folder = workspace:WaitForChild('SanctuaryPerformanceModels',120)
assert(folder, 'Full production initialization or fixture startup failed')
local Animation = require(script.Parent:WaitForChild('Client',120):WaitForChild('CurseAnimation'))
local camera = workspace.CurrentCamera
local busy, captureBusy, completed = false, false, false
local recordings, captureRows = {}, {}
local gui = Instance.new('ScreenGui')
gui.Name,gui.ResetOnSpawn,gui.DisplayOrder='SanctuaryPerformanceControls',false,180
gui.Parent = player:WaitForChild('PlayerGui')
local label = Instance.new('TextLabel')
label.Size,label.Position=UDim2.new(1,-24,0,44),UDim2.new(0,12,1,-102)
label.BackgroundColor3,label.TextColor3=Color3.fromRGB(20,23,34),Color3.new(1,1,1)
label.TextWrapped,label.TextSize,label.Font=true,13,Enum.Font.Gotham
label.Text='Carga de QA: 8 bases etapa 10 + 56 representaciones sin propiedad ni ingresos.'
label.Parent=gui
local function button(name,x,width,callback)
 local b=Instance.new('TextButton')
 b.Name,b.Text=name,name
 b.Size,b.Position=UDim2.fromOffset(width,38),UDim2.new(0,x,1,-50)
 b.BackgroundColor3,b.TextColor3=Color3.fromRGB(42,43,68),Color3.new(1,1,1)
 b.TextSize,b.Font=13,Enum.Font.GothamMedium
 b.Parent=gui
 b.Activated:Connect(callback)
 return b
end
local function capture()
 if captureBusy then return end
 captureBusy=true
 local started=DateTime.now().UnixTimestampMillis
 player:SetAttribute('SanctuaryPerformanceCaptureStartedUnixMillis',started)
 local ok,failure=pcall(function()
  Capture:StartVideoCaptureAsync(function(status,video)
   local row={startedUnixMillis=started,status=tostring(status),scope='Native QA draw load; no ownership or pixel approval implied'}
   if video then
    table.insert(recordings,video)
    row.seconds=video.TimeLength
    player:SetAttribute('SanctuaryPerformanceCaptureReady',true)
    player:SetAttribute('SanctuaryPerformanceCaptureCount',#recordings)
    player:SetAttribute('SanctuaryPerformanceCaptureSeconds',video.TimeLength)
    print('SANCTUARY_PERFORMANCE_VIDEO',started,video.TimeLength)
   else row.failure=tostring(status) end
   table.insert(captureRows,row)
   player:SetAttribute('SanctuaryPerformanceCapturesJSON',Http:JSONEncode(captureRows))
   captureBusy=false
  end,{})
 end)
 if not ok then
  captureBusy=false
  player:SetAttribute('SanctuaryPerformanceCaptureFailure',tostring(failure))
 end
end
local function nativeMesh(model)
 if not model:IsA('Model') then return nil end
 local mesh=model:FindFirstChild('CurseMesh')
 return if mesh and mesh:IsA('MeshPart') and mesh.MeshId~='' then mesh else nil
end
local function liveTagged()
 local count=0
 for _,model in Collection:GetTagged('ExpansionCurseVFX') do
  if model:IsDescendantOf(workspace) and nativeMesh(model) then count+=1 end
 end
 return count
end
local function modelSnapshot()
 local models,loaded,ready,bones,bound,emitters,lights=0,0,0,0,0,0,0
 local invalid,waiting={},{}
 local tiers={near=0,mid=0,low=0,suspended=0}
 for _,model in folder:GetChildren() do
  local mesh=nativeMesh(model)
  if not mesh then table.insert(invalid,model.Name..' ('..model.ClassName..')');continue end
  models+=1
  if model:GetAttribute('PresentationReady') then ready+=1 end
  if model:GetAttribute('MeshPreloadStatus')=='Success' then loaded+=1
  else table.insert(waiting,{id=model:GetAttribute('CurseId'),status=tostring(model:GetAttribute('MeshPreloadStatus'))}) end
  local distance=(mesh.Position-camera.CFrame.Position).Magnitude
  local _,onscreen=camera:WorldToViewportPoint(mesh.Position)
  local tier=if distance>115 or (not onscreen and distance>50) then 'suspended'
   elseif distance<32 then 'near' elseif distance<75 then 'mid' else 'low'
  tiers[tier]+=1
  for _,item in model:GetDescendants() do
   if item:IsA('Bone') then bones+=1 end
   if item:IsA('Attachment') and item:GetAttribute('AnimatedVFXBone') then bound+=1 end
   if item:IsA('ParticleEmitter') and item.Enabled and item.Rate>0 then emitters+=1 end
   if item:IsA('PointLight') and item.Enabled then lights+=1 end
  end
 end
 return {models=models,loaded=loaded,ready=ready,bones=bones,invalid=invalid,waiting=waiting,
  projectedQATiers=tiers,animatedVFXBindings=bound,activeEmitters=emitters,activeCurseLights=lights,
  liveTaggedModels=liveTagged(),folderChildren=#folder:GetChildren()}
end
local function invoke(action)
 local response=control:InvokeServer(action)
 assert(response and response.ok,response and response.message or 'No fixture response')
 return response.result
end
local function waitFor(predicate,seconds)
 local deadline=os.clock()+seconds
 repeat
  if predicate() then return true end
  task.wait(.1)
 until os.clock()>=deadline
 return false
end
local function list3(v) return {v.X,v.Y,v.Z} end
local function measure(name,view,seconds)
 label.Text='QA · '..name..' · modelos nativos, animación y VFX de producción'
 player:SetAttribute('SanctuaryPerformancePhase',name)
 camera.CameraType,camera.FieldOfView=Enum.CameraType.Scriptable,70
 camera.CFrame=view
 -- Let distance budgets and presentation settle before collecting this view.
 task.wait(1)
 local first=Animation.metrics()
 local liveFirst=liveTagged()
 local started=os.clock()
 local samples={}
 while os.clock()-started<seconds do
  camera.CameraType=Enum.CameraType.Scriptable
  camera.CFrame=view
  table.insert(samples,Run.RenderStepped:Wait())
 end
 local elapsed=os.clock()-started
 local last=Animation.metrics()
 table.sort(samples)
 local sum=0;for _,dt in samples do sum+=dt end
 local row=modelSnapshot()
 row.label,row.frames,row.elapsedSeconds=name,#samples,elapsed
 row.meanFrameSeconds=if #samples>0 then sum/#samples else 0
 row.p95FrameSeconds=samples[math.ceil(#samples*.95)] or 0
 row.maxFrameSeconds=samples[#samples] or 0
 row.meanFPS=if sum>0 then #samples/sum else 0
 row.first,row.last,row.liveTaggedModelsAtStart=first,last,liveFirst
 row.boneWrites,row.poses=last.boneWrites-first.boneWrites,last.posed-first.posed
 row.boneWritesPerSecond=row.boneWrites/math.max(.001,elapsed)
 row.camera={position=list3(view.Position),lookVector=list3(view.LookVector),fov=70,
  viewport={camera.ViewportSize.X,camera.ViewportSize.Y}}
 row.touchEnabled=Input.TouchEnabled
 row.nativeCaptureActiveAtEnd=captureBusy
 -- Includes natural procession offers, whose actual count is recorded above.
 row.metricsScope='Production controller totals; QA 56 plus ordinary live offers. RenderStepped frame duration includes Studio and any active native capture; not isolated CPU time or a phone benchmark.'
 return row
end
local startButton
startButton=button('Medir carga de QA',12,210,function()
 if busy or completed then return end
 busy=true;startButton.Active=false
 player:SetAttribute('SanctuaryPerformanceStatus','RUNNING')
 local rows,checks,failures={},{},{}
 local function check(name,passed,observed)
  table.insert(checks,{name=name,passed=passed,observed=observed})
  if not passed then table.insert(failures,name..': '..tostring(observed)) end
 end
 local function populated(row)
  check(row.label..' / 56 real meshes loaded',row.models==56 and row.loaded==56 and row.ready==56 and #row.invalid==0,
   Http:JSONEncode({models=row.models,loaded=row.loaded,ready=row.ready,invalid=row.invalid,waiting=row.waiting}))
 end
 local originalType,originalFrame,originalFOV=camera.CameraType,camera.CFrame,camera.FieldOfView
 local ok,problem=xpcall(function()
  assert(waitFor(function()return player:GetAttribute('ProfileStatus')=='READY'end,25),
   'Full production profile initialization is not READY; use the installed local profile bridge')
  invoke('prepare')
  local map=workspace.StealACurseMap
  local frame=map.PlayerSanctuaries.Base01:GetAttribute('SanctuaryFrame')
  assert(typeof(frame)=='CFrame','Production architecture frame is missing')
  local near=CFrame.lookAt((frame*CFrame.new(0,26,-20)).Position,(frame*CFrame.new(0,28,24)).Position)
  local mid=CFrame.lookAt((frame*CFrame.new(0,34,-65)).Position,(frame*CFrame.new(0,29,24)).Position)
  local far=CFrame.lookAt(Vector3.new(0,260,850),Vector3.new(0,25,0))
  task.wait(3)
  table.insert(rows,measure('baseline-8-level10-bases',near,6))
  local loadStarted=os.clock()
  invoke('spawn')
  local complete=waitFor(function()
   local loaded=modelSnapshot()
   return loaded.models==56 and loaded.loaded==56 and loaded.ready==56
  end,45)
  player:SetAttribute('SanctuaryPerformanceLoadSeconds',os.clock()-loadStarted)
  check('bounded asset loading',complete,'56 production native meshes, 45-second maximum; observed '..string.format('%.3f s',os.clock()-loadStarted))
  capture()
  local populatedNear=measure('56-near',near,8);table.insert(rows,populatedNear)
  local populatedMid=measure('56-mid',mid,6);table.insert(rows,populatedMid)
  local populatedFar=measure('56-far',far,6);table.insert(rows,populatedFar)
  local revisit=measure('56-revisit-near',near,6);table.insert(rows,revisit)
  local removed=invoke('clear')
  task.wait(2)
  local cleanup=measure('after-model-destroy-8-bases-retained',near,6);table.insert(rows,cleanup)
  for _,row in {populatedNear,populatedMid,populatedFar,revisit} do populated(row) end
  for _,row in rows do
   check(row.label..' / no missing acts',row.first.missingActs==0 and row.last.missingActs==0,
    string.format('first=%d, last=%d',row.first.missingActs,row.last.missingActs))
  end
  for _,row in {populatedNear,revisit} do
   check(row.label..' / active bone writes',row.boneWrites>0 and row.poses>0,
    string.format('boneWrites=%d, poses=%d',row.boneWrites,row.poses))
  end
  check('far / all QA meshes beyond suspension threshold',populatedFar.projectedQATiers.suspended==56,
   Http:JSONEncode(populatedFar.projectedQATiers))
  check('far / production rigs suspended',populatedFar.last.suspended>=56,
   'global suspended='..populatedFar.last.suspended)
  check('far / reduced controller bone work',populatedFar.boneWritesPerSecond<populatedNear.boneWritesPerSecond,
   string.format('near=%.2f/s, far=%.2f/s',populatedNear.boneWritesPerSecond,populatedFar.boneWritesPerSecond))
  check('revisit / suspension released',revisit.last.suspended<populatedFar.last.suspended,
   string.format('far=%d, revisit=%d',populatedFar.last.suspended,revisit.last.suspended))
  check('cleanup / destroyed exactly 56 QA models',removed.destroyed==56 and cleanup.folderChildren==0,
   Http:JSONEncode({destroyed=removed.destroyed,remaining=cleanup.folderChildren}))
  check('cleanup / tracked matches current live meshes',cleanup.last.tracked==cleanup.liveTaggedModels,
   string.format('tracked=%d, live=%d',cleanup.last.tracked,cleanup.liveTaggedModels))
  local retained=0
  for _,base in map.PlayerSanctuaries:GetChildren() do
   if base:IsA('Model') and base:GetAttribute('RestorationLevel')==10
    and base:GetAttribute('SanctuaryCapacity')==30 and base:GetAttribute('QADrawArchitecture') then retained+=1 end
  end
  check('cleanup / retained 8 advanced bases',retained==8,'Advanced architectures retained='..retained)
 end,debug.traceback)
 if not ok then
  check('fixture execution',false,tostring(problem))
  pcall(invoke,'clear')
 end
 player:SetAttribute('SanctuaryPerformanceObservedJSON',Http:JSONEncode(rows))
 player:SetAttribute('SanctuaryPerformanceChecksJSON',Http:JSONEncode(checks))
 player:SetAttribute('SanctuaryPerformanceFailuresJSON',Http:JSONEncode(failures))
 local status=if #failures==0 then 'PASS' else 'FAIL'
 player:SetAttribute('SanctuaryPerformanceStatus',status)
 label.Text=string.format('QA %s · %d comprobaciones / %d fallos. Datos de Studio; no equivale a teléfono físico.',status,#checks,#failures)
 print('SANCTUARY_PERFORMANCE_RESULT',status,Http:JSONEncode(rows))
 camera.CameraType,camera.CFrame,camera.FieldOfView=originalType,originalFrame,originalFOV
 busy,completed=false,true
 -- Restart Play for another sample, preserving a fresh architecture baseline.
 startButton.Text='Medición terminada: reinicia Play'
end)
button('Grabar 30 s',230,120,capture)
-- Native-clicked camera views, after the bounded measurements. No model pose
-- or ownership changes; Studio's command tool otherwise resets camera type.
for index,name in ipairs({'Cripta','Bosque','Observatorio'}) do
 local b=Instance.new('TextButton')
 b.Name,b.Text='ArchitectureView'..index,'QA: '..name
 b.Size,b.Position=UDim2.fromOffset(150,36),UDim2.fromOffset(180+(index-1)*160,12)
 b.Parent=gui
 b.Activated:Connect(function()
  if busy or not completed then return end
  local base=workspace.StealACurseMap.PlayerSanctuaries:FindFirstChild(string.format('Base%02d',index))
  local frame=base:GetAttribute('SanctuaryFrame')
  camera.CameraType=Enum.CameraType.Scriptable
  camera.CFrame=CFrame.lookAt((frame*CFrame.new(58,42,-87)).Position,(frame*CFrame.new(0,29,16)).Position)
 end)
end
