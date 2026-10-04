local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local folder=workspace:WaitForChild('PolishedRigDiagnostic',60)
local player=Players.LocalPlayer
local ids={'cursed_doll','watching_eye','plague_monarch'}
local index,posed=1,false
local gui=Instance.new('ScreenGui');gui.Name='PolishedRigDiagnosticControls';gui.Parent=player:WaitForChild('PlayerGui')
local function button(name,x,fn)
 local b=Instance.new('TextButton');b.Name=name;b.Text=name;b.Size=UDim2.fromOffset(180,40);b.Position=UDim2.new(0,x,1,-50);b.Parent=gui;b.Activated:Connect(fn)
end
local label=Instance.new('TextLabel');label.Size=UDim2.fromOffset(680,28);label.Position=UDim2.new(0,12,1,-85);label.Parent=gui
button('Pose / Rest',12,function() posed=not posed end)
button('Next',202,function()index=index%3+1;posed=false end)
task.spawn(function()local hud=player.PlayerGui:WaitForChild('StealACurseHUD',30)if hud then hud.Enabled=false end end)
game:GetService('ProximityPromptService').Enabled=false
local function pose(mesh,name,cf)
 for _,bone in mesh:GetDescendants()do
  if bone:IsA('Bone') and (bone.Name==name or bone.Name==ids[index]..'__'..name)then bone.Transform=cf end
 end
end
local deadline=os.clock()+1800
while os.clock()<deadline do
 local id=ids[index]
 for _,mode in {'Before','After'}do
  local mesh=folder:WaitForChild(id..mode)
  for _,b in mesh:GetDescendants()do if b:IsA('Bone')then b.Transform=CFrame.identity end end
  if posed then
   if id=='cursed_doll'then
    pose(mesh,'Head',CFrame.Angles(0,0,.8));pose(mesh,'ArmL',CFrame.Angles(0,0,1.1));pose(mesh,'LegR',CFrame.Angles(.9,0,0))
   elseif id=='watching_eye'then
    pose(mesh,'ArmL',CFrame.Angles(0,0,.7));pose(mesh,'ForearmR',CFrame.Angles(.65,0,0));pose(mesh,'Gaze',CFrame.Angles(0,.45,0));pose(mesh,'LidUpper',CFrame.Angles(math.pi*.9,0,0))
   else
    for leg=0,3 do pose(mesh,'Leg'..leg,CFrame.Angles(if leg%2==0 then .6 else -.6,0,0));pose(mesh,'Shin'..leg,CFrame.Angles(-.7,0,0))end
    pose(mesh,'Mask',CFrame.Angles(0,.6,0))
   end
  end
 end
 local right=folder[id..'After'];local focus=Vector3.new(0,right.Position.Y,right.Position.Z)
 local cam=workspace.CurrentCamera;cam.CameraType=Enum.CameraType.Scriptable
 cam.CFrame=CFrame.lookAt(focus+Vector3.new(0,1,math.max(22,right.Size.Y*2.4)),focus);cam.FieldOfView=55
 label.Text=id..' | LEFT: existing template / RIGHT: native skinning | '..(if posed then 'HELD POSE'else 'REST')
 player:SetAttribute('PolishDiagnosticId',id);player:SetAttribute('PolishDiagnosticPose',posed)
 Run.RenderStepped:Wait()
end
