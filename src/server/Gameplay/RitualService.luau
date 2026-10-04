local Players=game:GetService('Players')
local Config=require(game.ReplicatedStorage.Shared.SanctuaryConfig)
local Progression=require(game.ReplicatedStorage.Shared.SanctuaryProgression)
local Catalog=require(game.ReplicatedStorage.Shared.CurseCatalog)
local Visual=require(script.Parent.CurseVisualService)
local Rituals={}
function Rituals.start(map,bases,profiles,curses,carry,souls,changed)
 local sessions={};local service={}
 local echoes=Instance.new('Folder');echoes.Name='RestorationRitualEchoes';echoes.Parent=map
 local function rootOf(player)
  local c=player.Character;local h=c and c:FindFirstChildOfClass('Humanoid');local r=c and c:FindFirstChild('HumanoidRootPart')
  return if player.Parent==Players and player:GetAttribute('ProfileStatus')=='READY' and h and h.Health>0 then r else nil
 end
 function service:cancel(player,message)
  local session=sessions[player.UserId];sessions[player.UserId]=nil
  if session and session.folder then session.folder:Destroy() end
  player:SetAttribute('ActiveRitual',nil);changed(player)
  return true,message or 'Ritual closed. Your collection and resources are kept.'
 end
 local function ownedPresentation(player,count)
  local selected,seen={},{}
  local owned=curses:getOwned(player)
  table.sort(owned,function(a,b)return a.definitionId<b.definitionId end)
  for _,r in owned do
   if r.state=='PLACED' and not r.locked and not r.stealingUserId and not seen[r.definitionId] then
    seen[r.definitionId]=true;table.insert(selected,{uid=r.uid,definitionId=r.definitionId})
    if #selected==count then return selected end
   end
  end
  return nil
 end
 function service:begin(player,id)
  local profile=profiles:get(player);local def=if typeof(id)=='string' then Config.Rituals[id] else nil
  local base=bases:getBaseForPlayer(player);local root=rootOf(player)
  local altar=base and base:FindFirstChild('RestorationAltar',true)
  if not profile or not def or not root or not altar then return false,'Ritual unavailable.' end
  if profile.sanctuary.rituals[id] then return false,'This ritual is already complete.' end
  if profile.sanctuary.level<def.minimumLevel then return false,'Restore your sanctuary further before this ritual.' end
  if (profile.sanctuary.milestones.majorRelics or 0)<(def.majorRelicsRequired or 0) then return false,'Deliver a greater relic before consecrating it.' end
  if (root.Position-altar.Position).Magnitude>14 then return false,'Go to your altar to begin.' end
  if carry:isBusy(player) then return false,'Place or deliver what you carry before the ritual.' end
  local selected=ownedPresentation(player,def.speciesRequired)
  if not selected then return false,'Place '..def.speciesRequired..' different species of your own for this ritual.' end
  self:cancel(player)
  local folder=Instance.new('Folder');folder.Name='Ritual_'..player.UserId;folder.Parent=echoes
  local session={id=id,step=0,base=base,folder=folder,selected=selected,lastTap=-math.huge};sessions[player.UserId]=session
  for i,choice in selected do
   local model,prompt=Visual.create(Catalog.Definitions[choice.definitionId],folder)
   model:SetAttribute('CurseUid','ritual-echo-'..player.UserId..'-'..choice.uid)
   model:SetAttribute('RitualEcho',true);model:SetAttribute('OwnerUserId',player.UserId)
   model:ScaleTo(.38);prompt.Enabled=false;Visual.setState(model,Catalog.Definitions[choice.definitionId],'RITUAL')
   local angle=(i-1)*math.pi*2/#selected
   local offset=Vector3.new(math.cos(angle)*10,model.PrimaryPart.Size.Y*.5+1,math.sin(angle)*7)
   Visual.move(model,altar.CFrame*CFrame.new(offset),true)
   local info=model:FindFirstChild('CurseInfo')
   if info then
    info.Size=UDim2.fromOffset(112,36);info.MaxDistance=26
    local panel=info:FindFirstChild('Panel')
    if panel then for _,child in panel:GetChildren() do
     if child:IsA('TextLabel') then child.Visible=false end
    end
    local label=Instance.new('TextLabel');label.Name='EchoLabel';label.Size=UDim2.fromScale(1,1)
    label.BackgroundTransparency=1;label.Text='RITUAL ECHO\nNo income';label.Font=Enum.Font.GothamMedium;label.TextSize=11
    label.TextColor3=Color3.fromRGB(164,218,211);label.Parent=panel end
   end
  end
  player:SetAttribute('ActiveRitual',id);changed(player)
  return true,'Activate the marks in this order: '..table.concat(def.sequence,' → ')..'. Echoes earn no Souls.'
 end
 function service:snapshot(player)
  local session=sessions[player.UserId];if not session then return nil end
  local d=Config.Rituals[session.id]
  return {id=d.id,title=d.title,step=session.step,total=#d.sequence,sequence=table.clone(d.sequence),nextMark=d.sequence[session.step+1],description=d.description}
 end
 function service:activate(player,mark)
  local session=sessions[player.UserId];local root=rootOf(player)
  if not session or not root then return false,'Begin a ritual at your altar.' end
  local base=bases:getBaseForPlayer(player)
  if base~=session.base then self:cancel(player);return false,'The ritual was interrupted. You can try again.' end
  local marker=base:FindFirstChild('RitualMark_'..tostring(mark),true)
  if not marker or (root.Position-marker.Position).Magnitude>10 then return false,'Get closer to the altar mark.' end
  local now=os.clock();if now-session.lastTap<.25 then return false,'Wait for the mark to respond.' end
  session.lastTap=now
  local valid={};for _,r in curses:getOwned(player) do if r.state=='PLACED' and not r.locked and not r.stealingUserId then valid[r.uid]=r.definitionId end end
  for _,choice in session.selected do
   if valid[choice.uid]~=choice.definitionId then self:cancel(player);return false,'Your display changed. Place your collection and try again.' end
  end
  local d=Config.Rituals[session.id]
  if mark~=d.sequence[session.step+1] then
   session.step=0;changed(player)
   return false,'Wrong mark. The sequence restarts; you lose nothing.'
  end
  session.step+=1
  Visual.pulse(map,marker.Position,Color3.fromRGB(143,216,185))
  if session.step==#d.sequence then
   local p=profiles:get(player)
   if not p or not Progression.completeRitual(p,session.id) then self:cancel(player);return false,"The ritual's requirements aren't met. You can retry." end
   profiles:commit(player);self:cancel(player)
   return true,'Ritual complete. Its milestone is saved forever.'
  end
  changed(player);return true,'Mark '..mark..' activated. Next: mark '..d.sequence[session.step+1]..'.'
 end
 local function track(player)
  player.CharacterRemoving:Connect(function()service:cancel(player)end)
  player.CharacterAdded:Connect(function(character)local h=character:WaitForChild('Humanoid',10);if h then h.Died:Connect(function()service:cancel(player)end)end end)
  if player.Character then local h=player.Character:FindFirstChildOfClass('Humanoid');if h then h.Died:Connect(function()service:cancel(player)end)end end
 end
 Players.PlayerAdded:Connect(track);for _,p in Players:GetPlayers() do track(p) end
 Players.PlayerRemoving:Connect(function(p)service:cancel(p)end)
 return service
end
return Rituals
