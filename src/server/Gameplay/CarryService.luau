-- One load channel shared by contract relics and Curses. Authority stays here;
-- RelicPresentation only draws the carrier-relative visual on each client.
local Players = game:GetService('Players')
local Collection = game:GetService('CollectionService')
local Carry = {}
function Carry.start(map)
 local folder=Instance.new('Folder');folder.Name='ContractRelics';folder.Parent=map
 local carried, callbacks = {}, {}
 local service={}
 function service:isBusy(player)
  return player:GetAttribute('CarriedCurseUid')~=nil or carried[player.UserId]~=nil
 end
 function service:onInterrupted(callback) table.insert(callbacks,callback) end
 function service:get(player) return carried[player.UserId] end
 function service:clear(player)
  local entry=carried[player.UserId];carried[player.UserId]=nil
  player:SetAttribute('CarriedRelicUid',nil);player:SetAttribute('CarriedRelicName',nil)
  if entry and entry.model then entry.model:Destroy() end
 end
 function service:take(player,token,title,major)
  if self:isBusy(player) then return false,'Place what you are carrying before picking up a relic.' end
  local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
  local humanoid=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
  if not root or not humanoid or humanoid.Health<=0 then return false,'Your character is not available.' end
  local model=Instance.new('Model');model.Name='Relic_'..token
  model:SetAttribute('RelicToken',token);model:SetAttribute('CarrierUserId',player.UserId)
  model:SetAttribute('RelicName',title);model:SetAttribute('MajorRelic',major==true)
  local size=if major then 1.45 else 1
  local function part(name,dimensions,offset,color,material)
   local p=Instance.new('Part');p.Name=name;p.Size=dimensions*size;p.Color=color;p.Material=material
   p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
   p.CFrame=root.CFrame*CFrame.new(offset*size);p.Parent=model;return p
  end
  local core=part('RelicBody',Vector3.new(1.3,1.8,1.3),Vector3.new(1.8,.2,1.5),Color3.fromRGB(63,79,91),Enum.Material.Slate)
  model.PrimaryPart=core
  part('SealFace',Vector3.new(.65,.75,1.38),Vector3.new(1.8,.3,1.5),Color3.fromRGB(145,219,191),Enum.Material.Neon)
  part('IronCrown',Vector3.new(1.6,.24,1.6),Vector3.new(1.8,1.22,1.5),Color3.fromRGB(141,107,62),Enum.Material.Metal)
  part('IronFoot',Vector3.new(1.6,.24,1.6),Vector3.new(1.8,-.83,1.5),Color3.fromRGB(141,107,62),Enum.Material.Metal)
  local hook=Instance.new('Attachment');hook.Name='RelicSealHook';hook.Parent=core
  model.Parent=folder;Collection:AddTag(model,'SanctuaryContractRelic')
  carried[player.UserId]={token=token,model=model}
  player:SetAttribute('CarriedRelicUid',token);player:SetAttribute('CarriedRelicName',title)
  return true
 end
 local function interrupt(player)
  local entry=carried[player.UserId];if not entry then return end
  service:clear(player)
  for _,callback in callbacks do callback(player,entry.token) end
 end
 local function track(player)
  player.CharacterRemoving:Connect(function()interrupt(player)end)
  player.CharacterAdded:Connect(function(character)
   local h=character:WaitForChild('Humanoid',10)
   if h then h.Died:Connect(function()interrupt(player)end) end
  end)
  if player.Character then
   local h=player.Character:FindFirstChildOfClass('Humanoid')
   if h then h.Died:Connect(function()interrupt(player)end) end
  end
 end
 Players.PlayerAdded:Connect(track);for _,p in Players:GetPlayers() do track(p) end
 Players.PlayerRemoving:Connect(interrupt)
 task.spawn(function()
  while map.Parent do
   task.wait(.1)
   for userId,entry in carried do
    local player=Players:GetPlayerByUserId(userId)
    local root=player and player.Character and player.Character:FindFirstChild('HumanoidRootPart')
    if not root or not entry.model.Parent then if player then interrupt(player) end
    else entry.model:PivotTo(root.CFrame*CFrame.new(1.8,.2,1.5)) end
   end
  end
 end)
 return service
end
return Carry
