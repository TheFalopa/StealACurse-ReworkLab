local Sites={}
Sites.Positions={
 gravekeeper_board=Vector3.new(-44,0,121), cemetery_gate=Vector3.new(168,0,-32),
 old_well=Vector3.new(-35,0,144), forest_shrine=Vector3.new(-161,0,151),
 chapel_steps=Vector3.new(-114,0,-266), observatory_stone=Vector3.new(144,0,-174),
 castle_courtyard=Vector3.new(28,0,58),
}
Sites.Names={gravekeeper_board='Gravekeeper',cemetery_gate='East Memorial',old_well='Well of Echoes',forest_shrine='Forest Vigil',chapel_steps='Forgotten Chapel',observatory_stone='Astral Stone',castle_courtyard='Castle Courtyard'}
function Sites.build(map)
 local group=map:FindFirstChild('RestorationActivities')
 if not group then group=Instance.new('Model');group.Name='RestorationActivities' end
 local nodes={}
 local support=RaycastParams.new();support.FilterType=Enum.RaycastFilterType.Include
 support.FilterDescendantsInstances={map.Ground,map.Paths,map:FindFirstChild('CemeteryTerrain')}
 local function part(parent,name,size,frame,color,material,collide)
  local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=frame;p.Color=color;p.Material=material
  p.Anchored=true;p.CanCollide=collide==true;p.CanTouch=false;p.CastShadow=false;p.Parent=parent;return p
 end
 for id,at in Sites.Positions do
  local existing=group:FindFirstChild(id)
  local existingMarker=existing and existing:FindFirstChild('Interaction')
  if existingMarker and existingMarker:FindFirstChild('ContractInteraction') then nodes[id]=existingMarker;continue end
  if existing then existing:Destroy() end
  local hit=workspace:Raycast(at+Vector3.new(0,180,0),Vector3.new(0,-400,0),support)
  local y=if hit then hit.Position.Y else 1
  local node=Instance.new('Model');node.Name=id;node:SetAttribute('ContractNodeId',id);node.Parent=group
  local platform=part(node,'ActivityStone',Vector3.new(5,.4,5),CFrame.new(at.X,y+.2,at.Z),Color3.fromRGB(113,125,130),Enum.Material.Slate,true)
  local seal=part(node,'Seal',Vector3.new(2.8,.08,2.8),platform.CFrame*CFrame.new(0,.25,0)*CFrame.Angles(0,math.pi/4,0),Color3.fromRGB(132,212,191),Enum.Material.Neon,false)
  part(node,'SigilCross',Vector3.new(.24,.09,2),seal.CFrame*CFrame.new(0,.08,0),Color3.fromRGB(38,55,68),Enum.Material.Metal,false)
  local marker=part(node,'Interaction',Vector3.one,platform.CFrame*CFrame.new(0,2.5,0),Color3.new(1,1,1),Enum.Material.SmoothPlastic,false);marker.Transparency=1
  local prompt=Instance.new('ProximityPrompt');prompt.Name='ContractInteraction';prompt.ActionText='Interact';prompt.ObjectText=Sites.Names[id]
  -- Tap/E activates the step; distance, ownership and single reward remain server validated.
  prompt.RequiresLineOfSight=false;prompt.MaxActivationDistance=10;prompt.HoldDuration=0;prompt.Parent=marker
  marker:SetAttribute('ContractNodeId',id);nodes[id]=marker
  if id=='old_well' then
   for _,x in {-2.1,2.1} do part(node,'WellPost',Vector3.new(.4,3.5,.4),platform.CFrame*CFrame.new(x,1.95,1.7),Color3.fromRGB(100,69,53),Enum.Material.Wood,false) end
   part(node,'WellRafter',Vector3.new(4.7,.4,.5),platform.CFrame*CFrame.new(0,3.5,1.7),Color3.fromRGB(100,69,53),Enum.Material.Wood,false)
   for _,z in {-1.8,1.8} do part(node,'WellLip',Vector3.new(4.6,.6,.65),platform.CFrame*CFrame.new(0,.7,z),Color3.fromRGB(120,137,139),Enum.Material.Slate,false) end
  elseif id=='observatory_stone' then
   local pillar=part(node,'AstralSlab',Vector3.new(1.8,5,.9),platform.CFrame*CFrame.new(0,2.7,1.4)*CFrame.Angles(0,0,.08),Color3.fromRGB(53,65,92),Enum.Material.Slate,false)
   part(node,'Constellation',Vector3.new(.14,3,.12),pillar.CFrame*CFrame.new(0,0,-.5),Color3.fromRGB(168,194,232),Enum.Material.Neon,false)
  elseif id=='gravekeeper_board' then
   local frame=platform.CFrame*CFrame.new(0,0,3.8)
   part(node,'ContractBoard',Vector3.new(6,4,.45),frame*CFrame.new(0,3.6,0),Color3.fromRGB(91,66,48),Enum.Material.Wood,false)
   for _,x in {-2.5,2.5} do part(node,'BoardPost',Vector3.new(.5,5,.5),frame*CFrame.new(x,2.5,0),Color3.fromRGB(65,52,46),Enum.Material.Wood,false) end
   for i=1,3 do part(node,'ContractPaper'..i,Vector3.new(1.3,2,.08),frame*CFrame.new((i-2)*1.7,3.6,-.27)*CFrame.Angles(0,0,(i-2)*.05),Color3.fromRGB(214,207,171),Enum.Material.SmoothPlastic,false) end
   -- Mortimer (ProgressionWorld, placed from this board) is the only gravekeeper figure.
  end
 end
 group.Parent=map
 return nodes
end
return Sites
