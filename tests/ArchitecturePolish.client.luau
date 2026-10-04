local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local Run=game:GetService('RunService');local Http=game:GetService('HttpService')
local player=Players.LocalPlayer
local control=RS:WaitForChild('ArchitecturePolish',300);if not control then return end
local gui=Instance.new('ScreenGui');gui.Name='ArchitecturePolishReview';gui.ResetOnSpawn=false;gui.DisplayOrder=200;gui.Parent=player.PlayerGui
local camera=workspace.CurrentCamera;local data=control:InvokeServer('show');local mode='FRONT';local busy=false;local samples={}
local label=Instance.new('TextLabel');label.Size=UDim2.new(1,-20,0,28);label.Position=UDim2.new(0,10,1,-138);label.BackgroundColor3=Color3.fromRGB(18,22,29);label.TextColor3=Color3.new(1,1,1);label.Parent=gui
local function button(text,x,y,width,fn)
 local b=Instance.new('TextButton');b.Text=text;b.Size=UDim2.fromOffset(width,30);b.Position=UDim2.new(0,x,1,y);b.BackgroundColor3=Color3.fromRGB(34,45,63);b.TextColor3=Color3.new(1,1,1);b.Parent=gui;b.Activated:Connect(fn)
end
for i=0,10 do button(tostring(i),10+i*43,-103,39,function() data=control:InvokeServer('level',i);mode='FRONT' end) end
for i,style in {'CRYPT','FOREST','OBSERVATORY'}do button(style,10+(i-1)*132,-68,127,function()data=control:InvokeServer('style',style)end)end
button('ANTES / AHORA',411,-68,160,function()data=control:InvokeServer('before')end)
for i,name in {'FRONT','REAR','LEFT','RIGHT','TOP','INSIDE1','INSIDE2','INSIDE3'} do button(name,10+(i-1)*82,-33,78,function()mode=name end)end
button('RECORRER',494,-103,100,function()local r=control:InvokeServer('walk');if r then mode='PLAYER';camera.CameraType=Enum.CameraType.Custom end end)
button('CARGA 8',599,-103,88,function()
 if busy then return end busy=true
 task.spawn(function()
  local result={}
  for _,old in {true,false}do
   local geometry=control:InvokeServer('all',old);data=control:InvokeServer('show');mode='FRONT';task.wait(3);samples={};task.wait(5)
   local sum=0;for _,dt in samples do sum+=dt end table.sort(samples)
   table.insert(result,{before=old,geometry=geometry,frames=#samples,meanMs=sum/math.max(#samples,1)*1000,p95Ms=(samples[math.max(1,math.floor(#samples*.95))]or 0)*1000})
  end
  player:SetAttribute('ArchitecturePolishLoadJSON',Http:JSONEncode(result));busy=false
 end)
end)
local views={FRONT={Vector3.new(115,88,-138),Vector3.new(0,42,16)},REAR={Vector3.new(-115,88,170),Vector3.new(0,42,16)},LEFT={Vector3.new(-160,55,14),Vector3.new(0,35,16)},RIGHT={Vector3.new(160,55,14),Vector3.new(0,35,16)},TOP={Vector3.new(40,165,10),Vector3.new(0,0,16)}}
Run.RenderStepped:Connect(function(dt)
 if busy then table.insert(samples,dt)end
 if data and mode~='PLAYER'then
  camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=60
  local v=views[mode]
  if not v then local floor=tonumber(mode:sub(-1))or 1;v={Vector3.new(0,10+(floor-1)*22,-26),Vector3.new(0,10+(floor-1)*22,55)}end
  camera.CFrame=CFrame.lookAt(data.frame:PointToWorldSpace(v[1]),data.frame:PointToWorldSpace(v[2]))
 end
 label.Text=string.format('%s | NIVEL %s | %s | %s | %s',data and data.before and 'ANTES' or 'AHORA',data and data.level or '?',data and data.style or '?',mode,control:GetAttribute('Stage')or'')
end)
