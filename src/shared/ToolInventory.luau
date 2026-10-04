local C=require(script.Parent.ToolCatalog)
local I={}
local function integer(v)return typeof(v)=='number' and v==v and v>=0 and v<=1e9 and v==math.floor(v)end
function I.migrate(profile)
 if profile.tools~=nil then assert(I.valid(profile.tools),'Invalid tool inventory; profile preserved');return false end
 profile.tools={version=1,owned={shovel=true},charges={},equipped={'shovel'},receipts={}};return true
end
function I.valid(s)
 if typeof(s)~='table' or s.version~=1 or typeof(s.owned)~='table' or typeof(s.charges)~='table' or typeof(s.equipped)~='table' or typeof(s.receipts)~='table' then return false end
 for id,v in s.owned do if not C.Items[id] or v~=true then return false end end
 for id,v in s.charges do if not C.Items[id] or C.Items[id].kind~='consumable' or not integer(v) or v>C.MaxCharges then return false end end
 local seen={};if #s.equipped>C.MaxEquipped then return false end
 for _,id in s.equipped do if not C.Items[id] or seen[id] then return false end;seen[id]=true end
 local n=0;for id,v in s.receipts do n+=1;if typeof(id)~='string' or #id>120 or v~=true or n>4096 then return false end end
 return true
end
function I.owns(s,id,pass)return s.owned[id]==true or pass==true end
function I.equip(s,id,enabled,pass)
 if not C.Items[id] or not I.owns(s,id,pass) then return false,'Tool not unlocked.' end
 local index=table.find(s.equipped,id)
 if enabled then if index then return true end;if #s.equipped>=C.MaxEquipped then return false,'You can equip three tools.' end;table.insert(s.equipped,id)
 elseif index then table.remove(s.equipped,index) end
 return true
end
function I.consume(s,id)
 local d=C.Items[id];if not d then return false end
 if d.kind=='permanent' then return true end
 local n=s.charges[id] or 0;if n<=0 then return false end;s.charges[id]=n-1;return true
end
function I.grant(s,id,amount)
 local d=C.Items[id];if not d or not integer(amount) then return false end
 if d.kind=='consumable' and (s.charges[id] or 0)+amount>C.MaxCharges then return false end
 s.owned[id]=true;if d.kind=='consumable' then s.charges[id]=(s.charges[id] or 0)+amount end;return true
end
function I.receipt(s,receipt,id,amount)
 if typeof(receipt)~='string' or #receipt<1 or #receipt>120 then return false,'invalid' end
 if s.receipts[receipt] then return true,'duplicate' end
 local n=0;for _ in s.receipts do n+=1 end;if n>=4096 then return false,'history_full' end
 if not I.grant(s,id,amount) then return false,'capacity' end;s.receipts[receipt]=true;return true,'granted'
end
return I
