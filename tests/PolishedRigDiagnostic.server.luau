-- Diagnostic only. The same real imported asset is compared before/after
-- native ApplyMesh. Kept outside the release project.
local Players=game:GetService('Players')
local Storage=game:GetService('ServerStorage')
local Assets=game:GetService('AssetService')
local folder=Instance.new('Folder');folder.Name='PolishedRigDiagnostic';folder.Parent=workspace
local ids={'cursed_doll','watching_eye','plague_monarch'}
local report={}
for index,id in ids do
 local source=Storage.CurseMeshKit[id]
 local native=Assets:CreateMeshPartAsync(Content.fromUri(source.MeshId))
 for _,mode in {'Before','After'} do
  local mesh=source:Clone();mesh.Name=id..mode
  if mode=='After' then mesh:ApplyMesh(native) end
  mesh.Size=source.Size;mesh.Anchored=true;mesh.CanCollide=false
  mesh.Transparency=0;mesh.CFrame=CFrame.new(if mode=='Before' then -6 else 6,1.6+mesh.Size.Y/2,78+index*22)*CFrame.Angles(0,math.pi,0)
  mesh.Parent=folder
 end
 report[id]={before=source.HasSkinnedMesh,after=native.HasSkinnedMesh}
 native:Destroy()
end
folder:SetAttribute('Report',game:GetService('HttpService'):JSONEncode(report))
local player=Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
local char=player.Character or player.CharacterAdded:Wait()
char:WaitForChild('HumanoidRootPart');char:PivotTo(CFrame.new(0,4.6,99))
print('POLISHED_RIG_DIAGNOSTIC_READY',folder:GetAttribute('Report'))
