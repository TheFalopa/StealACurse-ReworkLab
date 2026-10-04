local Players = game:GetService("Players")
local CurseLabels = {}
function CurseLabels.start()
 task.spawn(function()
  while true do
   local camera=workspace.CurrentCamera
   local character=Players.LocalPlayer.Character
   local playerRoot=character and character:FindFirstChild("HumanoidRootPart")
   local map=workspace:FindFirstChild("StealACurseMap")
   local folder=map and map:FindFirstChild("ActiveCurses")
   local candidates={}
   if folder and camera and playerRoot then
    for _,model in folder:GetChildren() do
     local root=model:IsA("Model") and model:FindFirstChild("CurseMesh")
     local card=model:FindFirstChild("CurseInfo")
     if root and card and card:IsA("BillboardGui") then
      card.Enabled=false
      local distance=(playerRoot.Position-root.Position).Magnitude
      local position,onScreen=camera:WorldToViewportPoint(root.Position+card.StudsOffsetWorldSpace)
      local state=model:GetAttribute("CurseState")
      if onScreen and distance<(if state=="PLACED" then 25 else 40) then
       table.insert(candidates,{card=card,position=position,distance=distance,state=state})
      end
      for _,prompt in root:GetChildren() do
      if prompt:IsA("ProximityPrompt") then
       local center=camera:WorldToViewportPoint(root.Position)
       local bottom=camera:WorldToViewportPoint(root.Position-Vector3.new(0,root.Size.Y*.5,0))
       prompt.UIOffset=Vector2.new(0,math.clamp(bottom.Y-center.Y+45,60,240))
      end
      end
     end
    end
    table.sort(candidates,function(a,b) return a.distance<b.distance end)
    local selected={}
    local placed=false
    for _,candidate in candidates do
     local clear=#selected<2 and not(candidate.state=="PLACED" and placed)
     for _,other in selected do
      local delta=candidate.position-other.position
      if math.abs(delta.X)<176 and math.abs(delta.Y)<86 then clear=false end
     end
     if clear then
      candidate.card.Enabled=true;table.insert(selected,candidate)
      if candidate.state=="PLACED" then placed=true end
     end
    end
   end
   task.wait(.2)
  end
 end)
end
return CurseLabels
