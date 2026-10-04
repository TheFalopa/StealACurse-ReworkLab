-- Presentation fixture: imported production models beside copies of the real avatar.
-- It creates no CurseService records, income or completed gameplay tests.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HS = game:GetService("HttpService")
local Catalog = require(RS.Shared.CurseCatalog)
local Visual = require(game.ServerScriptService.Server.Gameplay.CurseVisualService)
local map = workspace:WaitForChild("StealACurseMap", 45)
local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
local character = player.Character or player.CharacterAdded:Wait()
character:WaitForChild("HumanoidRootPart")
task.wait(3)
character.Archivable = true
local avatar = character:Clone()
local folder = Instance.new("Folder"); folder.Name = "Pass2Audit"; folder.Parent = workspace
local report = { presentationOnly = true, gameplayValidated = false, rows = {}, groups = {}, cameraFov = 65 }
for group = 1, math.ceil(#Catalog.AllOrder/4) do
	local displays = Instance.new("Folder"); displays.Name = string.format("Group%02d", group); displays.Parent = folder
	for column = 1, 4 do
		local id = Catalog.AllOrder[(group-1)*4+column]
		if not id then break end
		local definition = Catalog.Definitions[id]
		local x = (column-2.5)*8
		local model, prompt = Visual.create(definition, displays)
		model.Name = id; model:SetAttribute("PresentationOnly", true); prompt.Enabled = false
		local root = model.PrimaryPart
		model:PivotTo(CFrame.new(x, 1.6+root.Size.Y*.5, 78) * CFrame.Angles(0,math.pi,0))
		for _, item in model:GetDescendants() do
			if item:IsA("BillboardGui") then item.Enabled = false end
		end
		local rig = avatar:Clone(); rig.Name = "AvatarReference_"..id
		for _, child in rig:GetDescendants() do
			if child:IsA("BasePart") then child.Anchored = true; child.CanCollide = false; child.CanQuery = false end
			if child:IsA("Script") or child:IsA("LocalScript") then child:Destroy() end
		end
		rig.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		rig:PivotTo(CFrame.new(x-2.7, 4.6, 80)); rig.Parent = displays
		table.insert(report.rows,{ id=id,group=group,rarity=definition.rarity,meshId=root.MeshId,
			size={root.Size.X,root.Size.Y,root.Size.Z},meshSize={root.MeshSize.X,root.MeshSize.Y,root.MeshSize.Z},
			cameraDistance=math.sqrt(x*x+22*22),avatarHeight=rig:GetExtentsSize().Y })
	end
	table.insert(report.groups, { index=group,folder=displays.Name })
	displays.Parent = nil
	displays.Parent = game.ServerStorage
end
avatar:Destroy()
local event = Instance.new("RemoteEvent"); event.Name="Pass2AuditSelect"; event.Parent=RS
local current = 0
event.OnServerEvent:Connect(function(_, group)
	if type(group)=="string" then
		local index=table.find(Catalog.AllOrder,group)
		if not index then return end
		if current>0 then folder:FindFirstChild(report.groups[current].folder).Parent=game.ServerStorage; current=0 end
		local old=folder:FindFirstChild("Solo"); if old then old:Destroy() end
		local solo=Instance.new("Folder"); solo.Name="Solo"; solo.Parent=folder
		local source=game.ServerStorage:FindFirstChild(string.format("Group%02d",math.ceil(index/4))):FindFirstChild(group)
		local model=source:Clone(); model.Parent=solo
		model:PivotTo(CFrame.new(0,1.6+model.PrimaryPart.Size.Y*.5,78)*CFrame.Angles(0,math.pi,0))
		model.CurseInfo.Enabled=true
		local rig=game.ServerStorage.Group01.AvatarReference_cursed_doll:Clone(); rig.Parent=solo
		rig:PivotTo(CFrame.new(-model.PrimaryPart.Size.X*.5-2,4.6,78))
		folder:SetAttribute("ReviewId",group); folder:SetAttribute("ReviewGroup",0)
		return
	end
	if type(group)~="number" or group%1~=0 or group<1 or group>#report.groups then return end
	local solo=folder:FindFirstChild("Solo"); if solo then solo:Destroy() end
	if current>0 then folder:FindFirstChild(report.groups[current].folder).Parent=game.ServerStorage end
	game.ServerStorage:FindFirstChild(report.groups[group].folder).Parent=folder; current=group
	folder:SetAttribute("ReviewGroup", group)
	folder:SetAttribute("ReviewId", "")
end)
local output=Instance.new("StringValue"); output.Name="Pass2AuditReport"; output.Value=HS:JSONEncode(report); output.Parent=RS
print("PASS2_AUDIT_READY",#report.rows,"actual templates, 14 groups, avatar references")
