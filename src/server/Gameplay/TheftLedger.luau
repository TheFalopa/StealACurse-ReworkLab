local Http=game:GetService('HttpService');local Storage=game:GetService('ServerStorage');local Run=game:GetService('RunService')
local L={};local busy=false
function L.read()
 if not Run:IsStudio()then return {}end
 local b=Storage:WaitForChild('ToolLedgerBridge',12);assert(b and b:GetAttribute('Ready'),'Install ToolsLedger plugin; saved profiles preserved')
 local ledger=Http:JSONDecode(b.Seed.Value);assert(typeof(ledger)=='table','Invalid durable ledger');return ledger
end
function L.write(op)
 if not Run:IsStudio()then return false,'Online theft is disabled.'end
 if busy then return false,'Another delivery is being saved.'end;busy=true
 local ok,answer=pcall(function()
  local b=Storage:FindFirstChild('ToolLedgerBridge');assert(b and b:GetAttribute('Ready'),'Ownership journal unavailable')
  local ledger=L.read();local n=0;for _ in ledger do n+=1 end;assert(ledger[op.uid] or n<4096,'Ownership journal full; preserve without pruning')
  ledger[op.uid]=op;local payload=Http:JSONEncode(ledger)
  b.Journal:SetAttribute('PendingUid',op.uid);b.Journal:SetAttribute('WriteDeadline',os.clock()+5)
  b.Journal:SetAttribute('SaveError',nil);b.Journal.Value=payload
  -- A retry can contain identical JSON after a failed save. Value alone would
  -- not fire again; each durable request has a fresh trigger.
  b.Journal:SetAttribute('RequestId',Http:GenerateGUID(false))
  local deadline=os.clock()+5
  repeat if b.Journal:GetAttribute('SavedPayload')==payload then return true end
   if b.Journal:GetAttribute('SaveError')then return false end;task.wait(.05)until os.clock()>deadline
  -- A timed-out write might still complete. Read back decides ownership; never
  -- assume failure means rollback after a durable COMMITTED decision.
  if b.Seed.Value==payload then return true end
  return false
 end)
 busy=false;return ok and answer==true,if ok then 'Save pending.'else tostring(answer)
end
return L
