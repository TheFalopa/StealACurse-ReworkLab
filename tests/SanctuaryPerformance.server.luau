-- Local Studio draw-load fixture, separate from the full production entrypoint.
-- These models are QA_NON_OWNED representations: no inventory, rewards or income.
local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local Run = game:GetService('RunService')
local Http = game:GetService('HttpService')
assert(Run:IsStudio(), 'Sanctuary performance fixture is local Studio QA only')

local Catalog = require(RS.Shared.CurseCatalog)
local Config = require(RS.Shared.SanctuaryConfig)
local Architecture = require(game.ServerScriptService.Server.Map.RestorationArchitecture)
local Visual = require(game.ServerScriptService.Server.Gameplay.CurseVisualService)
local control = Instance.new('RemoteFunction')
control.Name = 'SanctuaryPerformanceControl'
control:SetAttribute('Stage', 'WAITING_FOR_PRODUCTION')
control:SetAttribute('Scope', 'QA draw load: 8 level-10 bases, 56 non-owned native representations on 2 bases; no income, account seeding or mobile score')
control.Parent = RS
local map = workspace:WaitForChild('StealACurseMap', 120)
assert(map, 'Full production map did not start')
assert(map:WaitForChild('ActiveCurses', 90), 'Production CurseService did not start')
assert(RS:WaitForChild('CurseManagement', 90), 'Production management did not start')
assert(RS:WaitForChild('SanctuaryRestoration', 90), 'Production restoration did not start')

local folder = Instance.new('Folder')
folder.Name = 'SanctuaryPerformanceModels'
folder:SetAttribute('QAOwnership', 'QA_NON_OWNED')
folder:SetAttribute('QAIncomeSoulsPerSecond', 0)
folder.Parent = workspace
local operator, prepared, busy = nil, false, false
local bases, metadata = {}, {}

local function countPhysical(parent)
 local parts, meshes, bones, lights = 0, 0, 0, 0
 for _,item in parent:GetDescendants() do
  if item:IsA('BasePart') then parts += 1 end
  if item:IsA('MeshPart') then meshes += 1 end
  if item:IsA('Bone') then bones += 1 end
  if item:IsA('PointLight') then lights += 1 end
 end
 return {parts=parts,meshes=meshes,bones=bones,pointLights=lights}
end

local function prepare()
 assert(not prepared, 'Architecture fixture is already prepared')
 local affectedChecks=require(game.ServerStorage.UnitTest.RunUnitTest)('Architecture')
 control:SetAttribute('ArchitectureChecksJSON',Http:JSONEncode(affectedChecks))
 assert(affectedChecks.failed==0,'Affected architecture checks failed; do not approve load or facade')
 local sanctuaries = map:FindFirstChild('PlayerSanctuaries')
 assert(sanctuaries, 'Production sanctuaries are missing')
 -- Do not overwrite an account's legitimately claimed architecture.
 for index=1,8 do
  local base = sanctuaries:FindFirstChild(string.format('Base%02d',index))
  assert(base and not base:GetAttribute('OwnerUserId'), 'Use a fresh fixture with all sanctuaries unclaimed')
  bases[index] = base
 end
 local started = os.clock()
 local rows = {}
 for index,base in bases do
  local style = Config.StyleOrder[(index-1)%#Config.StyleOrder+1]
  Architecture.apply(base,10,style,nil)
  base:SetAttribute('QADrawArchitecture', true)
  base:SetAttribute('QAOwnership', 'QA_NON_OWNED')
  for _,item in base:GetDescendants() do
   if item:IsA('ProximityPrompt') then item.Enabled = false end
  end
  table.insert(rows,{id=base.Name,level=base:GetAttribute('RestorationLevel'),
   style=base:GetAttribute('SanctuaryStyle'),capacity=base:GetAttribute('SanctuaryCapacity'),
   counts=countPhysical(base)})
 end
 metadata = {scope=control:GetAttribute('Scope'),architectureBuildSeconds=os.clock()-started,
  bases=rows,mapCounts=countPhysical(map),population={Base01=30,Base02=26},
  productionEntrypoint='src/server/init.server.luau',
  presentation='Production CursePresentation, CurseAnimation and CurseVFX; no QA bone or mesh transform writer'}
 prepared = true
 control:SetAttribute('ArchitectureJSON', Http:JSONEncode(metadata))
 control:SetAttribute('Stage', 'ARCHITECTURE_READY')
 return metadata
end

local function populate()
 assert(prepared, 'Prepare architecture before spawning QA models')
 assert(#folder:GetChildren()==0, 'Clear existing QA models before another population')
 local ids = Catalog.enabledSpawnIds()
 assert(#ids==56, 'Fixture expects the current 56 enabled Curses')
 local rows = {}
 for index,id in ids do
  local definition = Catalog.Definitions[id]
  local baseIndex = if index<=30 then 1 else 2
  local ordinal = if index<=30 then index else index-30
  local floor = math.floor((ordinal-1)/10)+1
  local slot = (ordinal-1)%10+1
  local pedestalId = string.format('floor%d-slot%d',floor,slot)
  local marker
  for _,item in bases[baseIndex]:GetChildren() do
   if item:IsA('BasePart') and item:GetAttribute('PedestalId')==pedestalId then marker=item;break end
  end
  assert(marker, 'Missing active QA destination '..pedestalId)
  local model,prompt = Visual.create(definition,folder)
  model.Name = id
  model:SetAttribute('CurseUid','qa-sanctuary-performance-'..id)
  model:SetAttribute('QAOwnership','QA_NON_OWNED')
  model:SetAttribute('QAIncomeSoulsPerSecond',0)
  model:SetAttribute('QABaseId',bases[baseIndex].Name)
  model:SetAttribute('QAPedestalId',pedestalId)
  model:SetAttribute('StateStartedAt',workspace:GetServerTimeNow())
  Visual.setState(model,definition,'PLACED')
  prompt.Enabled = false
  model.CurseInfo.Enabled = false
  Visual.move(model,marker.CFrame*CFrame.new(0,marker.Size.Y/2+model.PrimaryPart.Size.Y/2+.18,0),true)
  -- No OwnerUserId, OccupiedCurseUid or CurseService record is created.
  local mesh = model:FindFirstChild('CurseMesh')
  table.insert(rows,{id=id,meshId=mesh.MeshId,base=bases[baseIndex].Name,pedestal=pedestalId,
   qaOwnership='QA_NON_OWNED',income=0,counts=countPhysical(model)})
 end
 control:SetAttribute('PopulationJSON',Http:JSONEncode(rows))
 control:SetAttribute('Stage','POPULATED')
 return {models=#rows,counts=countPhysical(folder)}
end

control.OnServerInvoke = function(player,action)
 if busy or (operator and operator~=player) then return {ok=false,message='Another local QA operation is active'} end
 if typeof(action)~='string' or (action~='prepare' and action~='spawn' and action~='clear') then
  return {ok=false,message='Unknown fixture action'}
 end
 operator = player
 busy = true
 local ok,result = xpcall(function()
  if action=='prepare' then return prepare()
  elseif action=='spawn' then return populate()
  else
   local removed=#folder:GetChildren()
   folder:ClearAllChildren()
   control:SetAttribute('Stage','CLEANED')
   return {destroyed=removed,remaining=#folder:GetChildren()}
  end
 end,debug.traceback)
 busy = false
 if not ok then
  if action=='spawn' then folder:ClearAllChildren() end
  control:SetAttribute('Failure',tostring(result))
  control:SetAttribute('Stage','FAILED')
  warn('SANCTUARY_PERFORMANCE_SERVER',result)
 end
 return {ok=ok,result=if ok then result else nil,message=if ok then '' else tostring(result)}
end
Players.PlayerRemoving:Connect(function(player)
 if player==operator then folder:ClearAllChildren();operator=nil end
end)
control:SetAttribute('Stage','READY')
