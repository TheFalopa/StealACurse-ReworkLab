-- Native presentation QA. Real production meshes/rigs and avatar; no ownership
-- records are forged and this fixture never enters a release build.
local RS=game:GetService('ReplicatedStorage')
local Players=game:GetService('Players')
local Http=game:GetService('HttpService')
local Catalog=require(RS.Shared.CurseCatalog)
local Visual=require(game.ServerScriptService.Server.Gameplay.CurseVisualService)
local map=workspace:WaitForChild('StealACurseMap',45)
local player=Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
local character=player.Character or player.CharacterAdded:Wait()
character:WaitForChild('HumanoidRootPart')
local folder=Instance.new('Folder');folder.Name='AnimationReview';folder.Parent=workspace
local signal=Instance.new('RemoteEvent');signal.Name='AnimationReview';signal.Parent=RS
local selected,models={},{}
local function show(ids,state)
	folder:ClearAllChildren();table.clear(models);selected=ids
	for i,id in ids do
		local d=Catalog.Definitions[id];if not d then continue end
		local m,p=Visual.create(d,folder);p.Enabled=false;m.Name=id
		local x=(i-(#ids+1)/2)*12
		m:SetAttribute('CurseUid','animation-review-'..id)
		m:SetAttribute('StateStartedAt',workspace:GetServerTimeNow())
		m:SetAttribute('CarrierUserId',if state=='CARRYING' then player.UserId else nil)
		Visual.setState(m,d,state)
		Visual.move(m,CFrame.new(x,1.6+m.PrimaryPart.Size.Y*.5,78)*CFrame.Angles(0,math.pi,0),true)
		m:SetAttribute('ReviewOrigin',m.PrimaryPart.CFrame)
		m.CurseInfo.Enabled=false
		models[id]=m
	end
	character:PivotTo(CFrame.new(-7,4.6,78))
	folder:SetAttribute('ReviewId',ids[1]);folder:SetAttribute('ReviewState',state)
	folder:SetAttribute('ReviewCount',#ids)
end
signal.OnServerEvent:Connect(function(p,ids,state)
	if p~=player or typeof(ids)~='table' or #ids>56 then return end
	if state~='PLACED' and state~='PROCESSION' and state~='CARRYING' and state~='UNPLACED' then return end
	show(ids,state)
end)
show({'cursed_doll'},'PLACED')
task.spawn(function()
	while folder.Parent do
		local now=workspace:GetServerTimeNow()
		for _,m in models do
			if m:GetAttribute('CurseState')=='PROCESSION' then
				local origin=m:GetAttribute('ReviewOrigin');local age=now-m:GetAttribute('StateStartedAt')
				Visual.move(m,origin*CFrame.new(0,0,age*6.5),false)
			end
		end
		task.wait(.08)
	end
end)
print('ANIMATION_REVIEW_READY','real imported templates, decorative bone poses, server anchor')
