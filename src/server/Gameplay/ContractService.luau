local Players=game:GetService('Players')
local Http=game:GetService('HttpService')
local Config=require(game.ReplicatedStorage.Shared.SanctuaryConfig)
local Progression=require(game.ReplicatedStorage.Shared.SanctuaryProgression)
local Sites=require(script.Parent.Parent.Map.ContractSites)
local Contracts={}
function Contracts.start(map,bases,profiles,souls,carry,changed,openPanel)
 local nodes=Sites.build(map)
 local service={}
 local bindNode
 function service:repairSites()
  local missing=false;for id in Sites.Positions do if not nodes[id] or not nodes[id].Parent then missing=true end end
  if missing then
   local repaired=Sites.build(map)
   for id,marker in repaired do if nodes[id]~=marker then nodes[id]=marker;if bindNode then bindNode(id,marker) end end end
  end
  return true
 end
 local function profile(player) return profiles:get(player) end
 local function rootOf(player)
  local c=player.Character;local h=c and c:FindFirstChildOfClass('Humanoid');local root=c and c:FindFirstChild('HumanoidRootPart')
  return if player.Parent==Players and player:GetAttribute('ProfileStatus')=='READY' and h and h.Health>0 then root else nil
 end
 function service:getNode(player,id)
  if id=='sanctuary_altar' then local base=bases:getBaseForPlayer(player);return base and base:FindFirstChild('RestorationAltar',true) end
  local marker=nodes[id]
  if not marker or not marker.Parent then self:repairSites();marker=nodes[id] end
  return marker
 end
 function service:snapshot(player)
  local p=profile(player);local c=p and p.sanctuary.contract
  if not c then return nil end
  local d=Config.Contracts[c.id];if not d then return nil end
  local target=d.nodes[(c.step or 0)+1];local marker=self:getNode(player,target)
  return {id=c.id,token=c.token,title=d.title,kind=d.kind,step=c.step,total=#d.nodes,phase=c.phase,
   reward=d.rewardFragments,targetNodeId=target,targetName=Config.NodeLabels[target],
   position=marker and {marker.Position.X,marker.Position.Y,marker.Position.Z},
   carrying=carry:get(player)~=nil,description=d.description}
 end
 function service:accept(player,id)
  self:repairSites()
  local p=profile(player);local d=if typeof(id)=='string' then Config.Contracts[id] else nil
  if not p or not d or not rootOf(player) then return false,'Contract unavailable.' end
  if not bases:getBaseForPlayer(player) then return false,'Claim your sanctuary first.' end
  if p.sanctuary.contract then return false,'You already have an active contract.' end
  if p.sanctuary.level<d.minLevel then return false,'Restore your sanctuary further for this contract.' end
  if p.sanctuary.fragments+d.rewardFragments>Config.MaximumFragments then return false,'Spend some seal fragments before taking another contract.' end
  local board=nodes.gravekeeper_board
  if not board or (rootOf(player).Position-board.Position).Magnitude>12 then return false,"Pick contracts at the Gravekeeper's board." end
  p.sanctuary.contract={id=id,step=0,phase='ACTIVE',token=Http:GenerateGUID(false),startedAt=os.time()}
  profiles:commit(player);changed(player)
  return true,'Contract accepted. '..d.description
 end
 function service:abandon(player)
  local p=profile(player);if not p or not p.sanctuary.contract then return false,'You have no active contract.' end
  carry:clear(player);p.sanctuary.contract=nil;profiles:commit(player);changed(player)
  return true,'Contract abandoned. You keep your seal fragments.'
 end
 function service:restart(player)
  local p=profile(player);local c=p and p.sanctuary.contract
  if not c then return false,'You have no active contract.' end
  self:repairSites();carry:clear(player);c.step=0;c.phase='ACTIVE';c.carryState=nil;profiles:commit(player);changed(player)
  return true,'Activity restarted. Return to the first target.'
 end
 function service:interact(player,nodeId)
  local p=profile(player);local c=p and p.sanctuary.contract;local root=rootOf(player)
  if not c or not root then return false,"Pick a contract at the Gravekeeper's board." end
  local d=Config.Contracts[c.id];if not d then return false,'Restart the contract from the board.' end
  if c.step>=#d.nodes then return false,'Restart this activity from the board; its target is still pending.' end
  if p.sanctuary.fragments+d.rewardFragments>Config.MaximumFragments then return false,'Spend some seal fragments before delivering.' end
  local target=d.nodes[c.step+1]
  if nodeId~=target then return false,'Your target is at '..Config.NodeLabels[target]..'.' end
  local marker=self:getNode(player,target)
  if not marker or not marker.Parent then return false,'Target unavailable. You can restart the contract without losing materials.' end
  if (root.Position-marker.Position).Magnitude>12 then return false,'Get closer to the target to interact.' end
  if d.kind~='SEAL' and c.step==0 then
   local ok,message=carry:take(player,c.token,if d.kind=='TRANSPORT' then 'Ritual lantern' else if d.majorRelic then 'Greater relic' else 'Seal piece',d.majorRelic)
   if not ok then return false,message end
   c.phase='CARRYING';c.carryState={nodeId=nodeId};c.step=1
  elseif d.kind~='SEAL' then
   local entry=carry:get(player)
   if c.phase~='CARRYING' or not entry or entry.token~=c.token then return false,'Recover the relic at the first target.' end
   c.step+=1
  else
   -- A step is monotonic and never yields. Duplicate remote/prompt calls cannot
   -- activate this mark twice or advance out-of-order remote instructions.
   c.step+=1;Progression.recordSealActivation(p)
  end
  if c.step>=#d.nodes then
   local awarded=Progression.awardContract(p,c.id,c.token)
   if not awarded then return false,'That delivery is already recorded.' end
   carry:clear(player);profiles:commit(player);changed(player)
   return true,'Contract complete: +'..d.rewardFragments..' seal fragments.'
  end
  profiles:commit(player);changed(player)
  return true,if d.kind=='SEAL' then 'Mark activated. Head to the next point.' else 'Carry the relic to '..Config.NodeLabels[d.nodes[c.step+1]]..'.'
 end
 bindNode=function(id,marker)
  marker.ContractInteraction.Triggered:Connect(function(player)
   if id=='gravekeeper_board' then
    local p=profile(player);local c=p and p.sanctuary.contract
    if not c or Config.Contracts[c.id].nodes[c.step+1]~=id then
     local root=rootOf(player);if root and (root.Position-marker.Position).Magnitude<=12 then openPanel(player,'CONTRACTS') end;return
    end
   end
   local ok,message=service:interact(player,id);souls:notify(player,message)
  end)
 end
 for id,marker in nodes do bindNode(id,marker) end
 carry:onInterrupted(function(player,token)
  local p=profile(player);local c=p and p.sanctuary.contract
  if c and c.token==token then
   c.step=0;c.phase='RECOVERABLE';c.carryState=nil;profiles:commit(player);changed(player)
   souls:notify(player,'The relic was dropped. Pick it up again at the first target.')
  end
 end)
 profiles:onLoaded(function(player,p)
  if p.sanctuary.contract and p.sanctuary.contract.phase=='CARRYING' then
   p.sanctuary.contract.step=0;p.sanctuary.contract.phase='RECOVERABLE';p.sanctuary.contract.carryState=nil
   profiles:commit(player)
  end
 end)
 return service
end
return Contracts
