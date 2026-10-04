-- Native QA camera and capture only; never writes production mesh or bone poses.
local RS=game.ReplicatedStorage;local Run=game:GetService('RunService');local Players=game.Players
local player=Players.LocalPlayer;local control=RS:WaitForChild('SanctuaryNativeReview',220)
if not control then return end
local Animation=require(script.Parent.Client.CurseAnimation);local captures={};local camera=workspace.CurrentCamera
local gui=Instance.new('ScreenGui');gui.Name='SanctuaryReviewControls';gui.DisplayOrder=150;gui.ResetOnSpawn=false;gui.Parent=player.PlayerGui
local label=Instance.new('TextLabel');label.Size=UDim2.new(1,-24,0,28);label.Position=UDim2.new(0,12,1,-94);label.TextColor3=Color3.new(1,1,1);label.BackgroundColor3=Color3.fromRGB(16,22,32);label.Parent=gui
local ids={'grave_hopper','nail_beetle','coin_crawler'};local focusId=ids[1];local mode='MODEL';local capturing=false;local observations={}
local function button(text,x,width,callback)
 local b=Instance.new('TextButton');b.Text=text;b.Name=text;b.Size=UDim2.fromOffset(width,38);b.Position=UDim2.new(0,x,1,-50);b.BackgroundColor3=Color3.fromRGB(38,43,64);b.TextColor3=Color3.new(1,1,1);b.Parent=gui;b.Activated:Connect(callback)
end
local function capture()
 if capturing then return end;capturing=true
 player:SetAttribute('SanctuaryCaptureStarted',DateTime.now().UnixTimestampMillis)
 player:SetAttribute('SanctuaryCaptureId',focusId)
 game:GetService('CaptureService'):StartVideoCaptureAsync(function(status,video)
  if video then table.insert(captures,video);player:SetAttribute('SanctuaryCaptureSeconds',video.TimeLength);player:SetAttribute('SanctuaryCaptureCount',#captures)
  else player:SetAttribute('SanctuaryCaptureFailure',tostring(status)) end;capturing=false
 end,{})
end
for i,id in ids do button(id,12+(i-1)*143,137,function()focusId=id;mode='MODEL';capture();task.delay(.4,function()control:FireServer('remodel',id)end)end) end
button('Base',449,70,function()mode='BASE' end)
button('Recorrer',525,85,function()mode='PLAYER';camera.CameraType=Enum.CameraType.Custom;control:FireServer('spatial')end)
button('Mapa',616,70,function()mode='MAP' end)
button('Captura',692,80,capture)
local upper=Instance.new('TextButton');upper.Text='Galería superior';upper.Size=UDim2.fromOffset(150,32);upper.Position=UDim2.new(0,12,1,-140);upper.Parent=gui
upper.Activated:Connect(function()mode='UPPER' end)
local large=Instance.new('TextButton');large.Text='Recorrer con The Void';large.Size=UDim2.fromOffset(180,32);large.Position=UDim2.new(0,170,1,-140);large.Parent=gui
large.Activated:Connect(function()focusId='the_void';mode='PLAYER';camera.CameraType=Enum.CameraType.Custom;capture();control:FireServer('largeSpatial')end)
local previous={}
local started=os.clock();local elapsed=0
Run.RenderStepped:Connect(function(dt)
 elapsed+=dt
 local map=workspace:FindFirstChild('StealACurseMap');if not map then return end
 local model;local uid=control:GetAttribute('FocusUid')
 for _,m in map.ActiveCurses:GetChildren()do
  if mode=='MODEL' and ((uid and m:GetAttribute('CurseUid')==uid and m:GetAttribute('CurseId')==focusId) or (not model and m:GetAttribute('OwnerUserId')==player.UserId and m:GetAttribute('CurseId')==focusId)) then model=m end
 end
 local base;for _,b in map.PlayerSanctuaries:GetChildren()do if b:GetAttribute('OwnerUserId')==player.UserId then base=b end end
 if mode=='MODEL' and model and model:FindFirstChild('CurseMesh')then
  local mesh=model.CurseMesh;local f=mesh.CFrame;local position=(f*CFrame.new(8,mesh.Size.Y*.42,-14)).Position
  camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=55;camera.CFrame=CFrame.lookAt(position,mesh.Position+Vector3.new(0,.3,0))
  if elapsed>=.3 then
   local moving={};for _,bone in mesh:GetDescendants()do if bone:IsA('Bone')then
    if previous[bone.Name] and previous[bone.Name]~=bone.Transform then table.insert(moving,bone.Name)end;previous[bone.Name]=bone.Transform
   end end
   table.insert(observations,{id=focusId,state=model:GetAttribute('CurseState'),meshId=mesh.MeshId,time=os.clock()-started,movingBones=moving,metrics=Animation.metrics()})
   if #observations>160 then table.remove(observations,1)end
   player:SetAttribute('SanctuaryVisualSamples',game:GetService('HttpService'):JSONEncode(observations));elapsed=0
  end
 elseif mode=='BASE' and base then
  local f=base:GetAttribute('SanctuaryFrame');camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=65
  camera.CFrame=CFrame.lookAt((f*CFrame.new(100,68,-112)).Position,(f*CFrame.new(0,28,17)).Position)
 elseif mode=='UPPER' and base then
  local f=base:GetAttribute('SanctuaryFrame');camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=60
  camera.CFrame=CFrame.lookAt((f*CFrame.new(-6,55,39)).Position,(f*CFrame.new(-23,54,57)).Position)
 elseif mode=='MAP' then
  camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=65;camera.CFrame=CFrame.lookAt(Vector3.new(0,280,410),Vector3.new(0,0,0))
 end
 label.Text=string.format('%s · %s · %s | rigs %d / suspendidos %d',focusId,mode,control:GetAttribute('Stage')or'',Animation.metrics().tracked,Animation.metrics().suspended)
end)
