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
require(script.Gameplay.ToolCommerce).start(profiles, tools)

-- Progression (rework): Luck, Mortimer's missions and the Wheel of Fate.
require(script.Gameplay.LuckService).start()
local progression = require(script.Gameplay.ProgressionService).start(map, profiles, souls, tools, bases)
local ProgressionWorld = require(script.Map.ProgressionWorld)
local board = map:FindFirstChild("ContractBoard", true)
if board then
	local _, npcAt = ProgressionWorld.buildNpc(map, board)
	progression.npcPosition = npcAt
	local wheelSpot = board.Position + board.CFrame.RightVector * -20 + board.CFrame.LookVector * -2
	local _, wheelAt = ProgressionWorld.buildWheel(map, wheelSpot, board.CFrame.LookVector)
	progression.wheelPosition = wheelAt
end
