-- SOUL CHAINS: a soul imprisoned by its own chains.
-- Primary: the trapped soul at the core (cyan glow + faint ghost face).
-- Secondary: spectral energy travelling down both chains and across the
--            crown of links; a dark binding haze behind the core.
-- Detail: occasional sparks on random links.
-- Event: a tension pulse every few seconds (all links spark, energy races).
local Kit = require(script.Parent.Parent.Kit)

local SOUL = Color3.fromRGB(120, 236, 226)
local PALE = Color3.fromRGB(196, 176, 255)
local BIND = Color3.fromRGB(46, 18, 84)
local TENSION_PERIOD = 3.6

local function names(prefix: string, first: number, last: number)
	local list = {}
	for i = first, last, if last >= first then 1 else -1 do table.insert(list, prefix .. i) end
	return list
end

return function(fx)
	local s = fx.scale
	local core = fx:at("Core", "Core", Vector3.new(0, 0, 0.95))
	local binding = fx:at("Binding", "Core", Vector3.new(0, 0.3, -0.7))

	fx:emitter("Binding", binding, 0.6, {
		Texture = "glow_soft", Color = BIND, Size = 6 * s, Lifetime = 3, Speed = 0,
		Transparency = { { 0, 1 }, { 0.3, 0.4 }, { 0.7, 0.4 }, { 1, 1 } },
		LightEmission = 0, ZOffset = -1.5, LockedToPart = true,
	})
	fx:emitter("SoulGlow", core, 1, {
		Texture = "glow_core", Color = SOUL, Size = 1.5 * s, Lifetime = 2, Speed = 0,
		Transparency = { { 0, 1 }, { 0.3, 0.55 }, { 0.7, 0.55 }, { 1, 1 } },
		LightEmission = 1, ZOffset = 1, LockedToPart = true,
	})
	fx:emitter("TrappedSoul", core, 0.8, {
		Texture = "specter", Color = Color3.fromRGB(150, 245, 236), Size = 2.4 * s, Lifetime = 2.6,
		Speed = 0.12 * s, EmissionDirection = Enum.NormalId.Top, Rotation = { -8, 8 }, RotSpeed = { -6, 6 },
		Transparency = { { 0, 1 }, { 0.3, 0.3 }, { 0.7, 0.3 }, { 1, 1 } },
		LightEmission = 0.8, ZOffset = 1.1, LockedToPart = true,
	})
	local flash = fx:emitter("CoreFlash", core, 0, {
		Texture = "glow_soft", Color = SOUL, Lifetime = 0.5, Speed = 0,
		Size = { { 0, 2.5 * s }, { 1, 4.2 * s } }, Transparency = { { 0, 0.35 }, { 1, 1 } },
		LightEmission = 1, ZOffset = 0.9, LockedToPart = true,
	})

	-- Energy travellers: each follows a polyline of the CURRENT bone poses.
	local paths = {
		{ bones = names("ChainL", 0, 5), speed = 0.42, offset = 0 },
		{ bones = names("ChainR", 0, 5), speed = 0.42, offset = 0.5 },
		{ bones = names("CrownLink", 0, 6), speed = 0.3, offset = 0.25 },
		{ bones = names("CrownLink", 6, 0), speed = 0.3, offset = 0.75 },
	}
	local travellers = {}
	for index, path in paths do
		local at = fx:attach("Traveller" .. index, Vector3.zero)
		fx:emitter("Wake" .. index, at, 42, {
			Texture = "mote", Color = { { 0, SOUL }, { 1, PALE } }, Lifetime = { 0.35, 0.55 }, Speed = 0,
			Size = { { 0, 0.55 * s }, { 1, 0 } }, Transparency = { { 0, 0.1 }, { 1, 1 } },
			LightEmission = 1, ZOffset = 0.9,
		})
		fx:emitter("Head" .. index, at, 10, {
			Texture = "glow_core", Color = Color3.fromRGB(220, 255, 252), Lifetime = 0.2, Speed = 0,
			Size = 0.9 * s, Transparency = 0.25, LightEmission = 1, ZOffset = 1, LockedToPart = true,
		})
		table.insert(travellers, { at = at, path = path })
	end
	local sparkAt = fx:attach("LinkSpark", Vector3.zero)
	local spark = fx:emitter("LinkSpark", sparkAt, 0, {
		Texture = "spark", Color = Color3.fromRGB(226, 255, 252), Lifetime = 0.28, Speed = 0,
		Size = { { 0, 0 }, { 0.4, 1.1 * s }, { 1, 0 } }, Rotation = { 0, 90 }, LightEmission = 1, ZOffset = 1.2,
	})
	fx:light("SoulLight", core, SOUL, 9 * s, 1.1)

	local allLinks = {}
	for _, list in { names("ChainL", 0, 5), names("ChainR", 0, 5), names("CrownLink", 0, 6) } do
		for _, name in list do table.insert(allLinks, name) end
	end
	local function linkPosition(name: string): Vector3?
		local p = fx:posed(name)
		return p and (p + Vector3.new(0, 0, 0.55 * s))
	end

	local lastTension, lastSpark = -math.huge, -math.huge
	local travel, lastFrame = 0, nil
	local controller = {}
	function controller.frame(t: number)
		local dt = math.clamp(t - (lastFrame or t), 0, 0.1)
		lastFrame = t
		local tension = math.max(0, 1 - (t - lastTension) / 0.6)
		travel += dt * (1 + 2.5 * tension)
		for _, item in travellers do
			local points = {}
			for _, name in item.path.bones do
				local p = linkPosition(name)
				if p then table.insert(points, p) end
			end
			if #points >= 2 then
				item.at.Position = Kit.along(points, (travel * item.path.speed + item.path.offset) % 1)
			end
		end
	end
	function controller.update(t: number)
		local cycle = (t + fx.phase) % TENSION_PERIOD
		if cycle < 0.1 and t - lastTension > 1 then
			lastTension = t
			fx:burst(flash, 1)
			if fx.active then
				for _, name in allLinks do
					local p = linkPosition(name)
					if p then sparkAt.Position = p spark:Emit(1) end
				end
			end
		elseif t - lastSpark > 0.45 and fx.active then
			lastSpark = t
			local p = linkPosition(allLinks[math.random(1, #allLinks)])
			if p then sparkAt.Position = p spark:Emit(1) end
		end
		local since = t - lastTension
		fx:setLight(1, 0.75 + 0.15 * math.sin(t * 2.3) + 1.1 * math.exp(-since * 4))
	end
	return controller
end
