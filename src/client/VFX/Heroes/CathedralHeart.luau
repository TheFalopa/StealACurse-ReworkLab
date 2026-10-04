-- CATHEDRAL HEART: a sacred gothic heart.
-- Primary: warm ivory/pale-gold core with a lub-dub heartbeat.
-- Secondary: light leaking through the cracks on each beat (short radial
--            streaks); a faint golden shaft rising behind the arch.
-- Detail: very few sacred motes drifting upward.
-- Event: every fourth beat a brief, stronger heart flash.

local IVORY = Color3.fromRGB(255, 238, 200)
local GOLD = Color3.fromRGB(250, 204, 120)
local BEAT_PERIOD = 1.7

return function(fx)
	local s = fx.scale
	local heart = fx:at("Heart", "Root", Vector3.new(0, -0.2, 1.45))
	local shaft = fx:at("Shaft", "Root", Vector3.new(0, 2.4, -0.6))
	local nave = fx:at("Nave", "Root", Vector3.new(0, 0.6, 0.6))

	fx:emitter("Core", heart, 1, {
		Texture = "glow_core", Color = IVORY, Size = 2 * s, Lifetime = 2, Speed = 0,
		Transparency = { { 0, 1 }, { 0.3, 0.55 }, { 0.7, 0.55 }, { 1, 1 } },
		LightEmission = 1, ZOffset = 1, LockedToPart = true,
	})
	fx:emitter("Shaft", shaft, 0.5, {
		Texture = "rays", Color = GOLD, Size = 6.4 * s, Lifetime = 4, Speed = 0,
		Transparency = { { 0, 1 }, { 0.35, 0.72 }, { 0.65, 0.72 }, { 1, 1 } },
		LightEmission = 1, ZOffset = -1.5, LockedToPart = true,
	})
	local beat = fx:emitter("Beat", heart, 0, {
		Texture = "glow_soft", Color = GOLD, Lifetime = 0.55, Speed = 0,
		Size = { { 0, 2.2 * s }, { 0.2, 3.6 * s }, { 1, 3.2 * s } }, Transparency = { { 0, 0.4 }, { 1, 1 } },
		LightEmission = 1, ZOffset = 0.9, LockedToPart = true,
	})
	-- Radial fan in the heart's plane (facing the viewer).
	local cracks = fx:emitter("CrackLight", heart, 0, {
		Texture = "streak", EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(0, 180),
		Speed = { 5 * s, 7 * s }, Drag = 6, Lifetime = { 0.35, 0.5 },
		Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = 2.4,
		Size = { { 0, 0.35 * s }, { 1, 0.1 * s } }, Color = { { 0, IVORY }, { 1, GOLD } },
		Transparency = { { 0, 0.05 }, { 1, 1 } }, LightEmission = 1, ZOffset = 1.2,
	})
	local nave_ = fx:volume("Nave", Vector3.new(3.6, 4.6, 1.2) * s, nave)
	fx:emitter("SacredMotes", nave_, 1.8, {
		Texture = "mote", Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		EmissionDirection = Enum.NormalId.Top, Speed = { 0.15 * s, 0.35 * s }, Lifetime = { 3, 4.5 },
		Size = { { 0, 0 }, { 0.3, 0.28 * s }, { 1, 0 } }, Color = { { 0, IVORY }, { 1, GOLD } },
		LightEmission = 1, ZOffset = 0.6,
	})
	local flash = fx:emitter("Flash", heart, 0, {
		Texture = "spark", Color = IVORY, Lifetime = 0.5, Speed = 0, Rotation = { 0, 0 },
		Size = { { 0, 1 * s }, { 0.25, 5.4 * s }, { 1, 0 } }, Transparency = { { 0, 0.05 }, { 1, 1 } },
		LightEmission = 1, ZOffset = 1.4, LockedToPart = true,
	})
	fx:light("HeartLight", heart, GOLD, 10 * s, 1.2)

	local lastBeat, lastDub = -math.huge, -math.huge
	local beats = 0
	local controller = {}
	function controller.update(t: number)
		local cycle = (t + fx.phase) % BEAT_PERIOD
		if cycle < 0.08 and t - lastBeat > 0.5 then
			lastBeat = t
			beats += 1
			fx:burst(beat, 1)
			fx:burst(cracks, 7)
			if beats % 4 == 0 then
				fx:burst(flash, 1)
				fx:burst(cracks, 10)
			end
		elseif cycle >= 0.26 and cycle < 0.34 and t - lastDub > 0.5 then
			lastDub = t
			fx:burst(beat, 1)
		end
		local lub = math.exp(-((cycle - 0.04) / 0.1) ^ 2)
		local dub = 0.6 * math.exp(-((cycle - 0.3) / 0.1) ^ 2)
		local strong = if beats % 4 == 0 then 1.8 else 1
		fx:setLight(1, 0.6 + 0.8 * (lub + dub) * strong)
	end
	return controller
end
