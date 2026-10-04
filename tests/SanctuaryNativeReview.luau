-- Local native visual evidence using normal production purchases and placement.
-- QA positions are teleported between sites; walking inside each segment is real.
return function(ctx)
 assert(game:GetService('RunService'):IsStudio())
 local RS=game.ReplicatedStorage;local Http=game:GetService('HttpService')
 local Catalog=require(RS.Shared.CurseCatalog);local Motion=require(RS.Shared.CurseMotionMath)
 local control=Instance.new('RemoteEvent');control.Name='SanctuaryNativeReview';control.Parent=RS
 local player,map,curses,bases=ctx.player,ctx.map,ctx.curses,ctx.bases
 local base=bases:getBaseForPlayer(player);local busy=false;local rows={}
 local function model(uid)
  for _,m in map.ActiveCurses:GetChildren()do if m:GetAttribute('CurseUid')==uid then return m end end
 end
 local function check(ok,label,detail)
  table.insert(rows,{ok=ok,label=label,detail=detail});control:SetAttribute('ResultsJSON',Http:JSONEncode(rows));assert(ok,label)
 end
 control:SetAttribute('Stage','READY')
 control.OnServerEvent:Connect(function(sender,action,id)
  if sender~=player or busy then return end
  if action=='spatial' or action=='largeSpatial' then
   if not game.ServerStorage:FindFirstChild('SpatialReview')then return end
   busy=true;task.spawn(function()
    local temporaryUid
    local ok,answer=xpcall(function()
     if action=='largeSpatial' then
      temporaryUid=curses:spawn('the_void',map.CurseProcessionRoute.Point_01.Value and CFrame.new(map.CurseProcessionRoute.Point_01.Value))
      local m=model(temporaryUid);ctx.near(m.PrimaryPart)
      assert(curses:purchase(player,temporaryUid),'Actual large Curse purchase required')
      ctx.near(bases:getPedestals(base)['floor1-slot1'])
      assert(curses:action(player,'place',temporaryUid,'floor1-slot1').ok,'Actual initial large placement required')
      ctx.spatialDefinitionId='the_void'
     else ctx.spatialDefinitionId=nil end
     local value=require(game.ServerStorage.SpatialReview)(ctx)
     if temporaryUid then
      ctx.near(model(temporaryUid).PrimaryPart);local quote=curses:action(player,'quote',temporaryUid)
      assert(quote.ok and curses:action(player,'sell',temporaryUid,nil,quote.data.token).ok,'Sell only temporary real QA purchase after manual return')
      value.temporaryPurchaseRemoved=true
     end
     ctx.spatialDefinitionId=nil
     return value
    end,debug.traceback)
    control:SetAttribute('SpatialJSON',Http:JSONEncode({ok=ok,result=answer}));control:SetAttribute('Stage',ok and 'SPATIAL_PASS' or 'FAILED');busy=false
   end);return
  end
  if action~='remodel' or not table.find({'grave_hopper','nail_beetle','coin_crawler'},id)then return end
  busy=true;task.spawn(function()
   local uid
   local ok,failure=xpcall(function()
    local route=map.CurseProcessionRoute;local points,lengths={},{}
    for i=1,route:GetAttribute('PointCount')do points[i]=route[string.format('Point_%02d',i)].Value end
    for i=1,#points-1 do lengths[i]=(points[i+1]-points[i]).Magnitude end
    uid=curses:spawn(id,Motion.route(points,lengths,0));local m=model(uid)
    check(m and m.CurseMesh.MeshId==Catalog.Definitions[id].meshId,id..' actual native mesh')
    control:SetAttribute('FocusUid',uid);control:SetAttribute('FocusId',id);control:SetAttribute('Stage','PROCESSION')
    local epoch=workspace:GetServerTimeNow();curses:setProcessionMotion(uid,epoch,6.5,.7)
    while workspace:GetServerTimeNow()-epoch<6 do
     curses:moveProcession(uid,Motion.route(points,lengths,(workspace:GetServerTimeNow()-epoch)*6.5));task.wait(.08)
    end
    ctx.near(m.PrimaryPart);check(curses:purchase(player,uid),id..' normal production purchase')
    local frame=base:GetAttribute('SanctuaryFrame');ctx.pose(frame*CFrame.new(0,4,-7))
    control:SetAttribute('Stage','CARRYING')
    local h=player.Character:FindFirstChildOfClass('Humanoid');h:MoveTo((frame*CFrame.new(0,4,35)).Position);task.wait(3.4)
    h:MoveTo((frame*CFrame.new(8,4,2)).Position);task.wait(3.4)
    h:MoveTo(player.Character.HumanoidRootPart.Position);task.wait(.8)
    local slot=bases:getPedestals(base)['floor1-slot1'];ctx.near(slot)
    check(curses:action(player,'place',uid,'floor1-slot1').ok,id..' normal manual placement')
    control:SetAttribute('Stage','PLACED');task.wait(10)
    ctx.near(m.PrimaryPart);local quote=curses:action(player,'quote',uid)
    check(quote.ok and curses:action(player,'sell',uid,nil,quote.data.token).ok,id..' real sale removes review copy')
    check(not model(uid),id..' controller instance removed')
    control:SetAttribute('Stage','REMOVED');task.wait(1)
    ctx.profiles:flush(player,false);control:SetAttribute('Stage','READY')
   end,debug.traceback)
   if not ok then control:SetAttribute('Stage','FAILED');control:SetAttribute('Failure',tostring(failure));warn(failure) end
   busy=false
  end)
 end)
 return control
end
