-- PLAGUE MONARCH: royal corruption.
-- Primary: a corrupted crown/core pulse with irregular, organic timing.
-- Secondary: a low poisonous haze pooling around the feet; slow spores.
-- Detail: small dark decayed wisps shed from the crown.

local TOXIC = Color3.fromRGB(150, 255, 96)
local MOSS = Color3.fromRGB(88, 168, 60)
local ROT = Color3.fromRGB(48, 86, 34)

return function(fx)
	local s = fx.scale
	local size = fx.size
	local core = fx:at("Core", "Root", Vector3.new(-0.11, 0.31, 1.35))
	local crown = fx:at("Crown", "Crown", Vector3.new(0, 1.2, 0.2))
	local feet = fx:at("Feet", "Root", Vector3.new(0, -size.Y / s * 0.47, 0.2))
	local body = fx:at("Body", "Root", Vector3.new(0, 0.4, 0))

	fx:emitter("CoreGlow", core, 1, {
		Texture = "glow_core", Color = TOXIC, Size = 1.2 * s, Lifetime = 2, Speed = 0,
		Transparency = { { 0, 1 }, { 0.3, 0.5 }, { 0.7, 0.5 }, { 1, 1 } },
		LightEmission = 1, ZOffset = 1, LockedToPart = true,
	})
	local pulse = fx:emitter("CorruptPulse", core, 0, {
		Texture = "glow_soft", Color = TOXIC, Lifetime = 0.7, Speed = 0,
		Size = { { 0, 1.8 * s }, { 0.25, 3.4 * s }, { 1, 3 * s } }, Transparency = { { 0, 0.45 }, { 1, 1 } },
		LightEmission = 1, ZOffset = 0.9, LockedToPart = true,
	})
	local floor = fx:volume("Haze", Vector3.new(size.X * 1.05, 0.3, size.Z * 1.2), feet)
	fx:emitter("Haze", floor, 3, {
		Texture = "wisp", Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		EmissionDirection = Enum.NormalId.Top, Speed = { 0.1 * s, 0.3 * s }, Lifetime = { 4, 6 },
		Acceleration = Vector3.new(0.15, -0.02, 0.05) * s,
		Size = { { 0, 2 * s }, { 1, 4.6 * s } }, Color = { { 0, MOSS }, { 1, ROT } },
		Rotation = { 0, 360 }, RotSpeed = { -10, 10 },
		Transparency = { { 0, 1 }, { 0.3, 0.55 }, { 0.7, 0.62 }, { 1, 1 } }, LightEmission = 0.35, ZOffset = -0.2,
	})
	local around = fx:volume("Spores", Vector3.new(size.X * 0.8, size.Y * 0.6, size.Z * 0.9), body)
	local spores = fx:emitter("Spores", around, 7, {
		Texture = "spore", Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		EmissionDirection = Enum.NormalId.Top, Speed = { 0.12 * s, 0.35 * s }, Lifetime = { 3, 4.5 },
		Acceleration = Vector3.new(0.05, 0.12, 0) * s, Drag = 0.8, Rotation = { 0, 360 }, RotSpeed = { -40, 40 },
		Size = { { 0, 0 }, { 0.2, 0.4 * s }, { 1, 0.12 * s } }, Color = { { 0, TOXIC }, { 1, MOSS } },
		Transparency = { { 0, 1 }, { 0.15, 0.15 }, { 1, 1 } }, LightEmission = 0.9, ZOffset = 0.5,
	})
	fx:emitter("Decay", crown, 2, {
		Texture = "ember", EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(30, 30),
		Speed = { 0.4 * s, 0.8 * s }, Lifetime = { 1.4, 2.2 }, Drag = 0.6,
		Size = { { 0, 0.3 * s }, { 1, 0 } }, Color = { { 0, MOSS }, { 1, ROT } },
		Transparency = { { 0, 0.3 }, { 1, 1 } }, LightEmission = 0.2, ZOffset = 0.4,
	})
	fx:light("PlagueLight", core, TOXIC, 8 * s, 0.9)

	-- Irregular pulse timing: never a metronome.
	local nextPulse, lastPulse = 0, -math.huge
	local controller = {}
	function controller.update(t: number)
		if t >= nextPulse then
			lastPulse = t
			nextPulse = t + 1.1 + math.random() * 1.6
			fx:burst(pulse, 1)
			if math.random() < 0.4 then fx:burst(spores, 6) end
		end
		fx:setLight(1, 0.6 + 0.9 * math.exp(-(t - lastPulse) * 3) + 0.05 * math.sin(t * 5.3))
	end
	return controller
end
