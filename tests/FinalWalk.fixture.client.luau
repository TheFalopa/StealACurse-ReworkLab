-- Fixture bridge only. CommandBar should require the module, not depend on _G.
local walk = require(game:GetService("ReplicatedStorage"):WaitForChild("TestFinalWalk"))
_G.FinalWalk = walk
print("FINAL_WALK_READY", "Client module available: require(game.ReplicatedStorage.TestFinalWalk); no walk has started")
