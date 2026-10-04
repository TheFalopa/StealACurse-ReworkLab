local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local event=RS:WaitForChild("Pass2AuditSelect",60)
if not event then return end
local player=game.Players.LocalPlayer
local gui=Instance.new("ScreenGui"); gui.Name="Pass2AuditControls"; gui.ResetOnSpawn=false; gui.Parent=player.PlayerGui
local text=Instance.new("TextLabel"); text.Size=UDim2.fromOffset(510,35); text.Position=UDim2.new(.5,-255,1,-40)
text.BackgroundColor3=Color3.fromRGB(14,18,28); text.TextColor3=Color3.new(1,1,1); text.TextSize=16; text.Parent=gui
local current=1
local order=require(RS.Shared.CurseCatalog).AllOrder
local soloIndex=1
local batchIndex=0
local batchIds={"grave_key","mourning_ribbon","wilted_sprout","hourglass_hound","nail_beetle","cold_teacup","umbrella_wraith","veil_mourner","raven_quill","thorn_reliquary","night_harp","blood_moon_rose","judgement_scales","eclipse_stag","hollow_throne","worldroot","the_last_funeral","the_unwritten","the_void"}
local function show()
	event:FireServer(current)
	text.Text=string.format("VISUAL PASS 2 · %02d / 14 · PageDown / PageUp · avatars for scale",current)
end
UIS.InputBegan:Connect(function(input,processed)
	if processed then return end
	if input.KeyCode==Enum.KeyCode.PageDown then current=current%14+1;show()
	elseif input.KeyCode==Enum.KeyCode.PageUp then current=(current-2)%14+1;show() end
	if input.KeyCode==Enum.KeyCode.Right then soloIndex=soloIndex%#order+1;event:FireServer(order[soloIndex])
	elseif input.KeyCode==Enum.KeyCode.Left then soloIndex=(soloIndex-2)%#order+1;event:FireServer(order[soloIndex]) end
	if input.KeyCode==Enum.KeyCode.B then batchIndex=batchIndex%#batchIds+1;soloIndex=table.find(order,batchIds[batchIndex]);event:FireServer(batchIds[batchIndex]) end
end)
Run:BindToRenderStep("Pass2FixedAuditCamera",Enum.RenderPriority.Camera.Value+5,function()
	local camera=workspace.CurrentCamera
	camera.CameraType=Enum.CameraType.Scriptable
	camera.FieldOfView=65
	local folder=workspace:FindFirstChild("Pass2Audit")
	local id=folder and folder:GetAttribute("ReviewId")
	if id and id~="" then
		camera.CFrame=CFrame.lookAt(Vector3.new(0,6.4,100),Vector3.new(0,5.1,78))
		text.Text=id.." · 22 studs · 65° · actual avatar · ← / →"
	else camera.CFrame=CFrame.lookAt(Vector3.new(0,6,100),Vector3.new(0,3.5,78)) end
end)
show()
