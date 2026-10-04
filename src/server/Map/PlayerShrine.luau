-- The archived animated delivery contains the original five-slot court.
-- Restoration keeps its public map entry point and stable gameplay markers.
local Architecture = require(script.Parent.RestorationArchitecture)
local PlayerShrine = {}
function PlayerShrine.build(map: Model)
	return Architecture.buildInitial(map)
end
return PlayerShrine
