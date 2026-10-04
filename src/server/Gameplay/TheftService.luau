local Players=game:GetService('Players');local Run=game:GetService('RunService');local Http=game:GetService('HttpService');local RS=game:GetService('ReplicatedStorage')
local C=require(RS.Shared.ToolCatalog);local Ledger=require(script.Parent.TheftLedger)
local S={}
function S.start(map,profiles,souls,bases,curses)
 local ops,busy,spam={},{},{};local service={}
 local folder=Instance.new('Folder');folder.Name='CurseTheft';folder.Parent=RS
 local request=Instance.new('RemoteFunction');request.Name='Request';request.Parent=folder
 local function answer(ok,message)return {ok=ok,message=message}end
 function service:interrupt(p,message)
  for uid,op in ops do if op.thief==p or op.from==p.UserId then
   if op.committing then op.interrupted=true;op.thief:SetAttribute('TheftDeliveryUid',nil)
   else curses:interruptTheft(uid);ops[uid]=nil;souls:notify(op.thief,message or 'Theft interrupted. The Curse still belongs to its owner.')end
  end end
 end
 function service:start(p,uid)
  if not Run:IsStudio()then return answer(false,'Online stealing is disabled until saves are verified.')end
  if busy[p]then return answer(false,'Already in progress.')end
  local info,message=curses:prepareTheft(p,uid);if not info then return answer(false,message)end
  busy[p]=true;local op={tx=Http:GenerateGUID(false),uid=uid,definitionId=info.definitionId,from=info.owner,owner=info.owner,phase='ATTEMPT',revision=info.revision,thief=p}
  local payload=table.clone(op);payload.thief=nil
  local saved,err=Ledger.write(payload)
  if saved then
   local owner=Players:GetPlayerByUserId(op.from);local profile=owner and profiles:get(owner)
   if profile then profile.toolTransfers=profile.toolTransfers or {};profile.toolTransfers[op.tx..':ATTEMPT']=true;profiles:commit(owner)end
  end
  local ok=saved and curses:beginTheft(p,uid);busy[p]=nil
  if not ok then curses:cancelTheftReservation(uid);return answer(false,err or 'That steal is no longer possible.')end
  ops[uid]=op;local owner=Players:GetPlayerByUserId(op.from);if owner then souls:notify(owner,'Someone is stealing your Curse! Stop them before they reach their sanctuary.')end
  return answer(true,'Stolen! Carry it to a free pedestal in your sanctuary and place it.')
 end
 function service:place(p,id)
  local uid=p:GetAttribute('StolenCurseUid');local op=uid and ops[uid]
  if not op or op.thief~=p or op.committing then return answer(false,'You are not carrying a stolen Curse.')end
  local plan,message=curses:reserveTheftDelivery(p,uid,id);if not plan then return answer(false,message)end
  op.committing=true;p:SetAttribute('TheftDeliveryUid',uid)
  local payload={uid=uid,tx=op.tx,from=op.from,owner=p.UserId,definitionId=op.definitionId,phase='COMMITTED',revision=op.revision+1,baseId=plan.baseId,pedestalId=plan.pedestalId}
  local saved,err=Ledger.write(payload)
  p:SetAttribute('TheftDeliveryUid',nil)
  if not saved then op.committing=nil;curses:releaseTheftDelivery(plan,uid);if op.interrupted then service:interrupt(p)end;return answer(false,err)end
  -- Journal is the durable source of ownership if either projection fails or a
  -- player disconnects during this yield. Reload recovers one unplaced instance.
  curses:finishTheft(p,payload,plan);ops[uid]=nil
  return answer(true,'Delivered! The Curse is yours now.')
 end
 curses.onTheftStart=function(p,uid)local a=service:start(p,uid);souls:notify(p,a.message);return a end
 curses.onTheftPlace=function(p,id)return service:place(p,id)end
 curses.onTheftInterrupt=function(p,message)service:interrupt(p,message)end
 curses.onBeforeClearUser=function(p)service:interrupt(p,'A player left. The theft was cancelled.')end
 request.OnServerInvoke=function(p,action,value)
  if typeof(action)~='string'or typeof(value)~='string'or #value>80 then return answer(false,'Invalid request.')end
  local now=os.clock();if now-(spam[p]or -1e6)<.25 then return answer(false,'One moment.')end;spam[p]=now
  if action=='start'then local a=service:start(p,value);souls:notify(p,a.message);return a elseif action=='place'then return service:place(p,value)end
  return answer(false,'Action not available.')
 end
 Players.PlayerRemoving:Connect(function(p)service:interrupt(p);spam[p]=nil;busy[p]=nil end)
 return service
end
return S
