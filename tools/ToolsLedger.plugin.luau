-- Local durable ownership journal. Kept separate from the UI/VFX work.
local Run=game:GetService('RunService');local Storage=game:GetService('ServerStorage');local Http=game:GetService('HttpService')
local function equal(a,b)
 if typeof(a)~=typeof(b)then return false end;if typeof(a)~='table'then return a==b end
 for k,v in a do if not equal(v,b[k])then return false end end;for k in b do if a[k]==nil then return false end end;return true
end
task.spawn(function()
 local shared=game:GetService('ReplicatedStorage'):WaitForChild('Shared',15)
 if not shared or not shared:FindFirstChild('ToolCatalog') or (Run:IsRunning() and Run:IsClient() and not Run:IsServer())then return end
 local profile=Storage:WaitForChild('LocalProfileBridge',12);if not profile then return end
 local key='StealACurseToolLedgerV1'..(profile:GetAttribute('Namespace') or 'play')
 local ok,stored=pcall(function()return plugin:GetSetting(key)end)
 if not ok or (stored~=nil and typeof(stored)~='table')then warn('Tool ledger unavailable; ownership preserved');return end
 local b=Storage:FindFirstChild('ToolLedgerBridge') or Instance.new('Folder');b.Name='ToolLedgerBridge';b.Parent=Storage
 local seed=b:FindFirstChild('Seed')or Instance.new('StringValue');seed.Name='Seed';seed.Parent=b;seed.Value=Http:JSONEncode(stored or {})
 local journal=b:FindFirstChild('Journal')or Instance.new('StringValue');journal.Name='Journal';journal.Parent=b;journal.Value=''
 journal:GetAttributeChangedSignal('RequestId'):Connect(function()
  local parsed,data=pcall(Http.JSONDecode,Http,journal.Value);if not parsed or typeof(data)~='table'then return end
  if b:GetAttribute('SimulateSaveFailure') and Run:IsRunning() then journal:SetAttribute('SaveError','Injected Studio failure');return end
  -- Validate at the durable decision boundary, before SetSetting. Late callbacks
  -- cannot convert a cancelled, dead or disconnected carrier into an owner.
  if os.clock()>(journal:GetAttribute('WriteDeadline')or 0)then journal:SetAttribute('SaveError','Expired journal request');return end
  local op=data[journal:GetAttribute('PendingUid')]
  if not op then journal:SetAttribute('SaveError','Missing operation');return end
  if op.phase=='COMMITTED'then
   local players=game:GetService('Players');local p=players:GetPlayerByUserId(op.owner);local original=players:GetPlayerByUserId(op.from)
   local h=p and p.Character and p.Character:FindFirstChildOfClass('Humanoid');local root=p and p.Character and p.Character:FindFirstChild('HumanoidRootPart')
   local map=workspace:FindFirstChild('StealACurseMap');local base=map and map.PlayerSanctuaries:FindFirstChild(op.baseId)
   local pedestal
   if base then for _,v in base:GetDescendants()do if v:IsA('BasePart')and v:GetAttribute('PedestalId')==op.pedestalId then pedestal=v;break end end end
   if not p or not original or not h or h.Health<=0 or not root or p:GetAttribute('StolenCurseUid')~=op.uid or p:GetAttribute('TheftDeliveryUid')~=op.uid or not base or base:GetAttribute('OwnerUserId')~=op.owner or not pedestal or pedestal:GetAttribute('OccupiedCurseUid')or(root.Position-pedestal.Position).Magnitude>10 then
    journal:SetAttribute('SaveError','Delivery no longer valid');return
   end
  end
  local wrote,failure=pcall(function()plugin:SetSetting(key,data)end)
  local read,check=pcall(function()return plugin:GetSetting(key)end)
  if wrote and read and equal(check,data)then
   seed.Value=journal.Value;journal:SetAttribute('SavedPayload',journal.Value);journal:SetAttribute('SaveError',nil)
  else journal:SetAttribute('SaveError',tostring(failure or 'Readback failed'))end
 end)
 b:SetAttribute('Ready',true)
end)
