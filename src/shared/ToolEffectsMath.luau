local M={}
function M.speed(base,effects,now)
 local multiplier,bonus,root=1,0,false
 for _,e in effects do if e.expires>now then multiplier=math.min(multiplier,e.slow or 1);bonus=math.max(bonus,e.bonus or 0);root=root or e.root==true end end
 return if root then 0 else math.clamp(base*multiplier+bonus,6,28)
end
function M.vector(v)
 return typeof(v)=='Vector3' and v.X==v.X and v.Y==v.Y and v.Z==v.Z and math.abs(v.X)<1e5 and math.abs(v.Y)<1e5 and math.abs(v.Z)<1e5
end
return M
