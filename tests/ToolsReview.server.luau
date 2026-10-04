local MapBuilder = require(script.Map.Build)
local SoulsService = require(script.Gameplay.SoulsService)
local BaseService = require(script.Gameplay.BaseService)
local CurseService = require(script.Gameplay.CurseService)
local CurseProcessionService = require(script.Gameplay.CurseProcessionService)
local ProfileStore = require(script.Gameplay.ProfileStore)
local SanctuaryService = require(script.Gameplay.SanctuaryService)
local CarryService = require(script.Gameplay.CarryService)
local ContractService = require(script.Gameplay.ContractService)
local RitualService = require(script.Gameplay.RitualService)

-- MapBuilder assembles outside Workspace, then publishes the complete model.
-- Gameplay never searches for generated markers before that lifecycle ends.
local map = MapBuilder.build()
local profiles = ProfileStore.start()
local souls = SoulsService.start(profiles)
local bases = BaseService.start(map)
-- Claim callbacks restore permanent architecture before CurseService restores
-- inventory by logical pedestal identity. No automatic placement on upgrades.
local sanctuary = SanctuaryService.start(map, bases, souls, profiles)
local carry = CarryService.start(map)
local curses = CurseService.start(map, bases, souls, profiles)
local contracts = ContractService.start(map, bases, profiles, souls, carry,
 function(player)sanctuary:changed(player)end,function(player,page)sanctuary:open(player,page)end)
local rituals = RitualService.start(map,bases,profiles,curses,carry,souls,function(player)sanctuary:changed(player)end)
sanctuary:attach(curses,contracts,rituals)
CurseProcessionService.start(map, curses)

-- Tools/theft integration: isolated presentation and catalogs; existing UI/VFX intact.
local tools = require(script.Gameplay.ToolService).start(map, profiles, souls, bases, carry)
local theft = require(script.Gameplay.TheftService).start(map, profiles, souls, bases, curses)
tools:attachTheft(theft)
local commerce = require(script.Gameplay.ToolCommerce).start(profiles, tools)

assert(game:GetService('RunService'):IsStudio())
local context={map=map,profiles=profiles,souls=souls,bases=bases,carry=carry,curses=curses,tools=tools,theft=theft,commerce=commerce,contracts=contracts,rituals=rituals,sanctuary=sanctuary}
local api=Instance.new('BindableFunction');api.Name='ToolsReviewAPI';api.Parent=game.ServerStorage
api.OnInvoke=function(service,method,user,args)
 local p=user and game.Players:GetPlayerByUserId(user);args=args or {}
 if service=='seed'then
  local profile=profiles:get(p);for k,v in args do profile[k]=v end;profiles:commit(p);tools:rebuild(p);tools:publish(p);return true
 elseif service=='interrupt'then theft:interrupt(p,'QA interruption');return true
 elseif service=='status'then return tools.status[method](tools.status,p,table.unpack(args))
 elseif service=='faultReceipt'then
  local flush=profiles.flush;profiles.flush=function()return false end
  local ok,value=pcall(function()return commerce:grantReceipt(p,args[1],args[2],true)end)
  profiles.flush=flush;assert(ok,value);return value
 elseif service=='pose'then p.Character:PivotTo(args[1]);p.Character.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero;return true
 elseif service=='spawn'then return curses:spawn(args[1],args[2])
 elseif service=='summary'then
  local list={};for _,q in game.Players:GetPlayers()do table.insert(list,{user=q.UserId,name=q.Name,status=q:GetAttribute('ProfileStatus'),base=q:GetAttribute('ClaimedBaseId')})end
  return {players=list,units=workspace:GetAttribute('ToolsUnitJSON'),practice=tools.practicePosition}
 elseif service=='profile'then return profiles:get(p)
 elseif service=='getOwned'then return curses:getOwned(p)
 elseif context[service] and context[service][method]then return context[service][method](context[service],p,table.unpack(args))end
 error('Unknown QA action')
end
local result=require(script.Unit.RunUnitTest)('ToolsFoundation')
workspace:SetAttribute('ToolsUnitJSON',game.HttpService:JSONEncode(result))
profiles:onLoaded(function(p)
 local profile=profiles:get(p)
 if not profile.tools.qaSeeded then
  profile.souls=50000;profile.sanctuary.level=3;profile.tools.qaSeeded=true;profiles:commit(p);souls:refresh(p)
 end
end)
