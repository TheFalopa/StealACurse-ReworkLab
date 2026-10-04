-- Bounded native stress fixture, never included in the release project.
local RS=game:GetService('ReplicatedStorage')
local Catalog=require(RS.Shared.CurseCatalog)
local Visual=require(game.ServerScriptService.Server.Gameplay.CurseVisualService)
workspace:WaitForChild('StealACurseMap',45)
local folder=Instance.new('Folder');folder.Name='AnimationPerformance';folder.Parent=workspace
local signal=Instance.new('RemoteEvent');signal.Name='AnimationPerformance';signal.Parent=RS
signal.OnServerEvent:Connect(function(p,action)
 if action=='spawn' then
  folder:ClearAllChildren()
  for i,id in Catalog.AllOrder do
   local m,prompt=Visual.create(Catalog.Definitions[id],folder);m.Name=id;prompt.Enabled=false
   m:SetAttribute('CurseUid','perf-'..id);m:SetAttribute('StateStartedAt',workspace:GetServerTimeNow())
   Visual.setState(m,Catalog.Definitions[id],'PLACED');m.CurseInfo.Enabled=false
   Visual.move(m,CFrame.new(((i-1)%7-3)*16,1.6+m.PrimaryPart.Size.Y/2,95+math.floor((i-1)/7)*16),true)
  end
 elseif action=='clear' then folder:ClearAllChildren()end
end)
