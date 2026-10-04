from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]
server=(root/'tests/ArchitecturePolish.server.luau').read_text()
start=server.index('  if p.sanctuary.level==10 then')
end=server.index("  local unit=require(game.ServerStorage.UnitTest.RunUnitTest)('Architecture')")
server=server[:start]+"  record(p.sanctuary.level==0 and #p.curses==0,'isolated interior profile starts empty')\n"+server[end:]
server=server.replace('ArchitecturePolish','InteriorPolish').replace("local level,style,old=10,'CRYPT',false","local level,style,old=8,'CRYPT',false")
server=server.replace("if b~=base then (if value then before else A).apply(b,10,({'CRYPT','FOREST','OBSERVATORY'})[(i-1)%3+1],nil) end","local renderer=if value then before else A;renderer.apply(b,10,({'CRYPT','FOREST','OBSERVATORY'})[(i-1)%3+1],nil)")
(root/'tests/InteriorPolish.server.luau').write_text(server)
client=(root/'tests/ArchitecturePolish.client.luau').read_text().replace('ArchitecturePolish','InteriorPolish')
client=client.replace("data=control:InvokeServer('show');mode='FRONT';task.wait(3)","mode='FRONT';task.wait(3)")
client=client.replace("'INSIDE3'}","'INSIDE3','STAIR','GALLERY'}")
client=client.replace("local views={","local views={GALLERY={Vector3.new(6,60,-24),Vector3.new(5,36,35)},STAIR={Vector3.new(-19,18,-19),Vector3.new(-42,10,1)},")
client=client.replace("button('CARGA 8',", "local captureObjects={}\nbutton('VIDEO ESCALERA',695,-103,155,function()\n if busy then return end\n mode='ORBIT';local old=data.before\n game:GetService('CaptureService'):StartVideoCaptureAsync(function(status,video)\n  table.insert(captureObjects,video);player:SetAttribute(old and 'BeforeVideoStatus' or 'AfterVideoStatus',tostring(status));\n  if video then player:SetAttribute(old and 'BeforeVideoLength' or 'AfterVideoLength',video.TimeLength)end\n end,{})\nend)\nbutton('CARGA 8',")
client=client.replace("local v=views[mode]","local v=views[mode]\n  if mode=='ORBIT' then local t=(os.clock()%8)/8*math.pi*2;v={Vector3.new(-24+math.sin(t)*7,12+math.sin(t*.5)*3,-16+math.cos(t)*12),Vector3.new(-42,10,1)} end")
(root/'tests/InteriorPolish.client.luau').write_text(client)
project=json.loads((root/'build-architecture-polish-review.project.json').read_text())
tree=project['tree']
tree['ServerScriptService']['Server']['$path']=str(root/'tests/InteriorPolish.server.luau')
tree['StarterPlayer']['StarterPlayerScripts']['InteriorPolish']=tree['StarterPlayer']['StarterPlayerScripts'].pop('ArchitecturePolish')
tree['StarterPlayer']['StarterPlayerScripts']['InteriorPolish']['$path']=str(root/'tests/InteriorPolish.client.luau')
tree['ServerStorage']['ArchitectureBefore']['RestorationArchitecture']['$path']=str(root/'assets/review/sanctuary-interior-polish/checkpoints/00-start/RestorationArchitecture.luau')
tree['ServerStorage']['LocalProfileBridge']['$attributes']['Namespace']='qa-interior-polish-154000'
tree['ReplicatedStorage']['$attributes']['FullRestorationReview']=True
(root/'build-interior-polish-review.project.json').write_text(json.dumps(project,indent=2))
