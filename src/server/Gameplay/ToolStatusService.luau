local Players=game:GetService('Players')
local M=require(game.ReplicatedStorage.Shared.ToolEffectsMath)
local S={}

-- Short, server-owned ragdoll for any R6/R15 character. Motors are disabled
-- and mirrored by limited ball sockets, then restored exactly; nothing is
-- destroyed, so death/respawn and repeated hits cannot leave a broken rig.
local RAGDOLL_MAX=2
local function buildRagdoll(character,root)
 local joints,collide={},{}
 for _,m in character:GetDescendants()do
  if m:IsA('Motor6D')and m.Enabled and m.Part0 and m.Part1 and m.Name~='RootJoint'and m.Name~='Root'then
   local a0=Instance.new('Attachment');a0.Name='RagdollA0';a0.CFrame=m.C0;a0.Parent=m.Part0
   local a1=Instance.new('Attachment');a1.Name='RagdollA1';a1.CFrame=m.C1;a1.Parent=m.Part1
   local socket=Instance.new('BallSocketConstraint');socket.Name='RagdollSocket';socket.Attachment0=a0;socket.Attachment1=a1
   socket.LimitsEnabled=true;socket.UpperAngle=55;socket.TwistLimitsEnabled=true;socket.TwistLowerAngle=-40;socket.TwistUpperAngle=40
   socket.Parent=m.Part1;m.Enabled=false
   table.insert(joints,{motor=m,parts={a0,a1,socket}})
  end
 end
 for _,part in character:GetChildren()do
  if part:IsA('BasePart')and part~=root and not part.CanCollide then collide[part]=true;part.CanCollide=true end
 end
 return joints,collide
end
local function releaseRagdoll(joints,collide)
 for _,j in joints do for _,v in j.parts do v:Destroy()end;if j.motor.Parent then j.motor.Enabled=true end end
 for part in collide do if part.Parent then part.CanCollide=false end end
end

function S.start(map)
 local states={};local service={}
 function service:clear(p,negativeOnly)
  local s=states[p];if not s then return end
  if negativeOnly then for id,e in s.effects do if e.negative and id~='ragdoll'then s.effects[id]=nil end end;s.immuneUntil=math.max(s.immuneUntil,os.clock()+2)
  else table.clear(s.effects) end
 end
 function service:remove(p,id)local s=states[p];if s then s.effects[id]=nil end end
 function service:add(p,id,e)
  local s=states[p];if not s or not s.h.Parent or s.h.Health<=0 then return false end
  local now=os.clock();if e.negative and now<s.immuneUntil then return false end
  if e.root then s.immuneUntil=now+(e.duration or 1)+2 end
  e.expires=now+math.clamp(e.duration or 1,.1,6);s.effects[id]=e;return true
 end
 function service:isRagdolled(p)local s=states[p];return s~=nil and s.ragdoll~=nil end
 function service:impulse(p,vector)
  local s=states[p];local r=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
  if not s or not r or not M.vector(vector) or os.clock()<s.impulseUntil or s.ragdoll then return false end
  s.impulseUntil=os.clock()+1.1;vector=if vector.Magnitude>32 then vector.Unit*32 else vector
  -- A server impulse on a client-owned character can be discarded by the next
  -- physics replication. Own the brief push, then restore automatic ownership.
  local can=r:CanSetNetworkOwnership();if not can then return false end
  r:SetNetworkOwner(nil)
  local attachment=Instance.new('Attachment');attachment.Name='ToolPushHook';attachment.Parent=r
  local velocity=Instance.new('LinearVelocity');velocity.Name='ToolPush';velocity.Attachment0=attachment;velocity.RelativeTo=Enum.ActuatorRelativeTo.World;velocity.VectorVelocity=vector;velocity.ForceLimitsEnabled=true;velocity.MaxForce=r.AssemblyMass*2500;velocity.Parent=r
  task.delay(.18,function()velocity:Destroy();attachment:Destroy()end)
  task.delay(.35,function()if r.Parent and not r.Anchored and not s.ragdoll then r:SetNetworkOwnershipAuto()end end)
  return true
 end
 -- Generic character ragdoll (players and Studio practice dummies). Returns a
 -- release function; the caller owns timing. Velocity is clamped.
 function service:ragdollCharacter(character,duration,velocity,onEnd)
  local h=character:FindFirstChildOfClass('Humanoid');local r=character:FindFirstChild('HumanoidRootPart')
  if not h or not r or h.Health<=0 or character:GetAttribute('Ragdolled')then return false end
  duration=math.clamp(duration,.3,RAGDOLL_MAX)
  if not M.vector(velocity)then velocity=Vector3.zero end
  if velocity.Magnitude>36 then velocity=velocity.Unit*36 end
  local owned=r:CanSetNetworkOwnership();if owned then r:SetNetworkOwner(nil)end
  local requiresNeck=h.RequiresNeck;h.RequiresNeck=false
  local joints,collide=buildRagdoll(character,r)
  character:SetAttribute('Ragdolled',true);character:SetAttribute('RagdollEndsAt',workspace:GetServerTimeNow()+duration)
  h:ChangeState(Enum.HumanoidStateType.Physics)
  r.AssemblyLinearVelocity=velocity
  r.AssemblyAngularVelocity=Vector3.new(math.random()-.5,0,math.random()-.5)*6
  local done=false
  local function finish()
   if done then return end;done=true
   releaseRagdoll(joints,collide)
   if character.Parent then
    character:SetAttribute('Ragdolled',nil);character:SetAttribute('RagdollEndsAt',nil)
    if h.Parent and h.Health>0 then
     h.RequiresNeck=requiresNeck
     -- Stand back up from wherever the body landed, facing the same way.
     local _,yaw=r.CFrame:ToOrientation()
     r.CFrame=CFrame.new(r.Position+Vector3.new(0,1.2,0))*CFrame.Angles(0,yaw,0)
     r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero
     h:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    task.delay(.25,function()if owned and r.Parent and not r.Anchored then r:SetNetworkOwnershipAuto()end end)
   end
   if onEnd then onEnd()end
  end
  task.delay(duration,finish)
  h.Died:Once(finish)
  return true
 end
 -- Player ragdoll: short control loss + recovery protection, then automatic
 -- recovery. Counts as a root effect so WalkSpeed math stays centralised.
 function service:ragdoll(p,duration,velocity)
  local s=states[p];local c=p.Character
  if not s or not c or not s.h.Parent or s.h.Health<=0 or s.ragdoll then return false end
  local now=os.clock();if now<s.immuneUntil then return false end
  local token={}
  if not self:ragdollCharacter(c,duration,velocity,function()
   if s.ragdoll==token then s.ragdoll=nil;s.effects.ragdoll=nil end
  end)then return false end
  s.ragdoll=token
  duration=math.clamp(duration,.3,RAGDOLL_MAX)
  s.effects.ragdoll={root=true,negative=true,expires=now+duration}
  -- Recovery protection: no chain-stun while getting up.
  s.immuneUntil=now+duration+1.5
  return true
 end
 local function track(p)
  local function character(c)
   local h=c:WaitForChild('Humanoid',10);if not h then return end
   states[p]={h=h,base=h.WalkSpeed,effects={},immuneUntil=os.clock()+3,impulseUntil=0,last=h.WalkSpeed}
   h.Died:Once(function()service:clear(p,false)end)
  end
  p.CharacterAdded:Connect(character);if p.Character then task.spawn(character,p.Character)end
 end
 Players.PlayerAdded:Connect(track);for _,p in Players:GetPlayers()do track(p)end
 Players.PlayerRemoving:Connect(function(p)states[p]=nil end)
 task.spawn(function()
  while map.Parent do task.wait(.05);local now=os.clock()
   for p,s in states do if s.h.Parent then
    -- Respect another movement system changing the base, then recompute all effects.
    if math.abs(s.h.WalkSpeed-s.last)>.01 then s.base=s.h.WalkSpeed end
    for id,e in s.effects do if e.expires<=now and id~='ragdoll' then s.effects[id]=nil end end
    local boots=s.effects.ash_boots
    if boots then boots.bonus=if p:GetAttribute('CarriedCurseUid')or p:GetAttribute('CarriedRelicUid')then 3 else 10 end
    s.last=M.speed(s.base,s.effects,now);s.h.WalkSpeed=s.last
    local n=0;for _ in s.effects do n+=1 end;p:SetAttribute('ToolEffectCount',n)
    -- Mirror active effects for HUD presentation (read-only on the client).
    p:SetAttribute('Rooted',s.effects.roots~=nil or s.effects.ragdoll~=nil)
    p:SetAttribute('Slowed',s.effects.salt~=nil or s.effects.chain~=nil)
    p:SetAttribute('ControlImmuneUntil',workspace:GetServerTimeNow()+math.max(0,s.immuneUntil-now))
   end end
  end
 end)
 return service
end
return S
