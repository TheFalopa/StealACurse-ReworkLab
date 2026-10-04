local RS=game:GetService('ReplicatedStorage')
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local Catalog=require(RS.Shared.CurseCatalog)
local Animation=require(script.Parent:WaitForChild('Client',30):WaitForChild('CurseAnimation',30))
local camera=workspace.CurrentCamera
local signal=RS:WaitForChild('AnimationReview',50)
local folder=workspace:WaitForChild('AnimationReview',50)
local player=Players.LocalPlayer
game:GetService('ProximityPromptService').Enabled=false
task.spawn(function()
 local hud=player.PlayerGui:WaitForChild('StealACurseHUD',30)
 if hud then hud.Enabled=false end
end)
local order={'cursed_doll','watching_eye','soul_chains','plague_monarch','the_void'}
for _,id in Catalog.AllOrder do if not table.find(order,id) then table.insert(order,id) end end
assert(#order==56,'Every enabled concept must be reviewed')
local cursor,stateIndex,far=1,1,false
local galleryBatch,busy=RS:GetAttribute('ReviewStartBatch') or 0,false
local batchSize=2 -- More time to see the held idle performance, not just a twitch.
local galleryObservations={}
local recordedVideos={}
local states={'PLACED','PROCESSION','CARRYING','UNPLACED'}
local controls=Instance.new('ScreenGui');controls.Name='AnimationReviewControls';controls.ResetOnSpawn=false;controls.Parent=player.PlayerGui
local text=Instance.new('TextLabel');text.Name='Status';text.Size=UDim2.fromOffset(640,28);text.Position=UDim2.fromOffset(12,10)
text.Position=UDim2.new(0,12,1,-84)
text.BackgroundColor3=Color3.fromRGB(15,20,30);text.TextColor3=Color3.new(1,1,1);text.Parent=controls
local function show() signal:FireServer({order[cursor]},states[stateIndex]) end
local function button(name,x,fn)
 local b=Instance.new('TextButton');b.Name=name;b.Text=name;b.Size=UDim2.fromOffset(115,38);b.Position=UDim2.fromOffset(x,45)
 b.Position=UDim2.new(0,x,1,-49)
 b.BackgroundColor3=Color3.fromRGB(30,50,60);b.TextColor3=Color3.new(1,1,1);b.Parent=controls;b.Activated:Connect(fn)
end
button('Previous',12,function()cursor=(cursor-2)%#order+1;show()end)
button('Next',133,function()cursor=cursor%#order+1;show()end)
button('State',254,function()stateIndex=stateIndex%4+1;show()end)
button('Near / Far',375,function()far=not far end)
button('Walk / Stop',496,function()
 local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
 if h then h:MoveTo(Vector3.new(8,4.6,78))end
end)
button('Native video',617,function()
 game:GetService('CaptureService'):StartVideoCaptureAsync(function(status,video)
  if video then table.insert(recordedVideos,video);player:SetAttribute('ReviewClipSeconds',video.TimeLength)end
 end,{})
end)
button('Gallery clip',738,function()
 if busy then return end
 busy=true;galleryBatch+=1
 local first=(galleryBatch-1)*batchSize+1
 if first>#order then galleryBatch=1;first=1 end
 player:SetAttribute('GalleryClipReady',false)
 player:SetAttribute('GalleryBatch',galleryBatch)
 game:GetService('CaptureService'):StartVideoCaptureAsync(function(status,video)
  if video then
   table.insert(recordedVideos,video)
   player:SetAttribute('ReviewClipSeconds',video.TimeLength)
   player:SetAttribute('GalleryClipReady',true)
  else player:SetAttribute('GalleryCaptureFailure',tostring(status)) end
  busy=false
 end,{})
 task.spawn(function()
  for i=first,math.min(first+batchSize-1,#order) do
   cursor=i
   for stage=1,3 do
    stateIndex=stage;show()
    task.wait(.35)
    if stage==3 then
     local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
     if h then h:MoveTo(Vector3.new(10,4.6,78))end
    end
    local samples,changed,frames={},{},{}
    local observedMeshId,observedSize,preloadStatus
    local endAt=os.clock()+(if stage==1 then 6.8 else 3.15)
    while os.clock()<endAt do
     local model=folder:FindFirstChild(order[i]);local mesh=model and model:FindFirstChild('CurseMesh')
     if mesh then
      observedMeshId=mesh.MeshId;observedSize={mesh.Size.X,mesh.Size.Y,mesh.Size.Z};preloadStatus=model:GetAttribute('MeshPreloadStatus')
      for _,bone in mesh:GetDescendants()do
       if bone:IsA('Bone') then
        if samples[bone.Name] and samples[bone.Name]~=bone.Transform then changed[bone.Name]=true end
        samples[bone.Name]=bone.Transform
       end
      end
     end
     table.insert(frames,Run.RenderStepped:Wait())
    end
    local names={};for name in changed do table.insert(names,name)end;table.sort(names)
    table.sort(frames)
    local sum=0;for _,dt in frames do sum+=dt end
    local row={id=order[i],state=states[stage],meshId=observedMeshId,size=observedSize,preloadStatus=preloadStatus,changedBones=names,
     frames={count=#frames,mean=sum/math.max(1,#frames),p95=frames[math.max(1,math.ceil(#frames*.95))],maximum=frames[#frames]},metrics=Animation.metrics()}
    table.insert(galleryObservations,row)
    player:SetAttribute('GalleryObservations',game:GetService('HttpService'):JSONEncode(galleryObservations))
   end
  end
 end)
end)
-- Finite fixture camera, excluded from the experience build.
task.spawn(function()
 local endAt=os.clock()+1800
 while os.clock()<endAt do
  local id=folder:GetAttribute('ReviewId');local model=id and folder:FindFirstChild(id)
  if model then
   local mesh=model:FindFirstChild('CurseMesh')
   if mesh then
    local focus=mesh.Position;local distance=math.max(12,mesh.Size.Y*1.55)
    if far then distance*=2.3 end
    camera.CameraType=Enum.CameraType.Scriptable
    camera.CFrame=CFrame.lookAt(focus+Vector3.new(distance*.16,mesh.Size.Y*.10,distance),focus)
    camera.FieldOfView=55
   end
  end
  local m=Animation.metrics()
  text.Text=string.format('%s · %s · rig QA | active %d / suspended %d',id or '',folder:GetAttribute('ReviewState')or'',m.tracked,m.suspended)
  Run.RenderStepped:Wait()
 end
end)
