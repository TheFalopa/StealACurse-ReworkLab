local MapBuilder = require(script.Map.Build)
local SoulsService = require(script.Gameplay.SoulsService)
local BaseService = require(script.Gameplay.BaseService)
local CurseService = require(script.Gameplay.CurseService)
local CurseProcessionService = require(script.Gameplay.CurseProcessionService)
local ProfileStore = require(script.Gameplay.ProfileStore)

-- MapBuilder assembles outside Workspace, then publishes the complete model.
-- Gameplay never searches for generated markers before that lifecycle ends.
local map = MapBuilder.build()
local profiles = ProfileStore.start()
local souls = SoulsService.start(profiles)
local bases = BaseService.start(map)
local curses = CurseService.start(map, bases, souls, profiles)
CurseProcessionService.start(map, curses)
