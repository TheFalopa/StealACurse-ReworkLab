-- Same native camera sequence for frozen/current worlds; excluded from release.
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local player=Players.LocalPlayer
workspace:WaitForChild('StealACurseMap',45)
local recordings={};local busy=false
local gui=Instance.new('ScreenGui');gui.Name='PavementCompare';gui.Parent=player.PlayerGui
local b=Instance.new('TextButton');b.Size=UDim2.fromOffset(200,40);b.Position=UDim2.new(0,15,1,-60)
b.Text='Record pavement';b.BackgroundColor3=Color3.fromRGB(25,45,55);b.TextColor3=Color3.new(1,1,1);b.Parent=gui
b.Activated:Connect(function()
 if busy then return end;busy=true;player:SetAttribute('PavementCaptureReady',false)
 game:GetService('CaptureService'):StartVideoCaptureAsync(function(status,video)
  if video then table.insert(recordings,video);player:SetAttribute('PavementCaptureReady',true);player:SetAttribute('PavementCaptureSeconds',video.TimeLength)end
  busy=false
 end,{})
 task.spawn(function()
  local camera=workspace.CurrentCamera;local started=os.clock()
  local sites={Vector3.new(0,1.42,34),Vector3.new(-25,1.2,61)}
  while os.clock()-started<29 do
   local age=os.clock()-started;local focus=sites[if age<15 then 1 else 2];local localAge=age%15
   local radius,height
   if localAge<5 then radius=12;height=1.2 elseif localAge<10 then radius=20;height=7 else radius=42;height=15 end
   local angle=localAge*.55+.45
   camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=65
   camera.CFrame=CFrame.lookAt(focus+Vector3.new(math.sin(angle)*radius,height,math.cos(angle)*radius),focus)
   Run.RenderStepped:Wait()
  end
 end)
end)
