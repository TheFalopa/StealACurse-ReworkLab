-- A durable ownership decision precedes both profile projections. Not a pair of
-- supposedly atomic saves. Applied markers allow later legitimate sale/removal.
local L={}
function L.recover(profile,userId,ledger)
 profile.toolTransfers=profile.toolTransfers or {};local changed=false
 for uid,op in ledger do
  assert(typeof(op)=='table' and op.uid==uid and typeof(op.tx)=='string' and typeof(op.owner)=='number' and (op.phase=='ATTEMPT' or op.phase=='COMMITTED'),'Invalid ownership ledger; stop without replacing profile')
  local key=op.tx..':'..op.phase;local found
  for i=#profile.curses,1,-1 do local r=profile.curses[i]
   if r.uid==uid then
    if op.owner~=userId then table.remove(profile.curses,i);changed=true else found=r end
   end
  end
  if op.owner==userId and not profile.toolTransfers[key] then
   if not found then found={uid=uid,definitionId=op.definitionId,revision=op.revision or 0};table.insert(profile.curses,found) end
   found.state='UNPLACED';found.pedestalId=nil;profile.toolTransfers[key]=true;changed=true
  end
 end
 return changed
end
return L
