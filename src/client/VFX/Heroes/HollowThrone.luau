-- HOLLOW THRONE: dead royalty, an empty seat that is not quite empty.
-- Primary: a faint spectral occupant on the seat.
-- Secondary: a slow vertical ascent of souls rising from the seat; a drifting
--            cold royal aura behind the backrest.
-- Event: an occasional, clearer apparition with a cold flash.

local GHOST = Color3.fromRGB(206, 226, 255)
local COLD = Color3.fromRGB(150, 176, 255)
local VIOLET = Color3.fromRGB(176, 156, 255)
local APPARITION_PERIOD = 7.2

return function(fx)
	local s = fx.scale
	local seat = fx:at("Seat", "Ghost", Vector3.new(0, 1.7, 0.75))
	local cushion = fx:at("Cushion", "Ghost", Vector3.new(0, 0.1, 0.5))
	local backrest = fx:at("Backrest", "Mantle", Vector3.new(0, 1.6, -0.9))

	fx:emitter("Occupant", seat, 0.5, {
		Texture = "specter", Color = GHOST, Size = 3.7 * s, Lifetime = 4, Speed = 0.06 * s,
		EmissionDirection = Enum.NormalId.Top, Rotation = { -3, 3 },
		Transparency = { { 0, 1 }, { 0.3, 0.76 }, { 0.7, 0.76 }, { 1, 1 } },
		LightEmission = 0.9, ZOffset = 0.8, LockedToPart = true,
	})
	local apparition = fx:emitter("Apparition", seat, 0, {
		Texture = "specter", Color = Color3.fromRGB(232, 242, 255), Size = { { 0, 3.5 * s }, { 1, 4.1 * s } },
		Lifetime = 2.2, Speed = 0.2 * s, EmissionDirection = Enum.NormalId.Top,
		Transparency = { { 0, 1 }, { 0.2, 0.35 }, { 0.6, 0.45 }, { 1, 1 } },
		LightEmission = 1, ZOffset = 0.9, LockedToPart = true,
	})
	local pad = fx:volume("Seat", Vector3.new(2.2, 0.2, 1.4) * s, cushion)
	fx:emitter("Ascent", pad, 5, {
		Texture = "streak", Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		EmissionDirection = Enum.NormalId.Top, Speed = { 1 * s, 1.6 * s }, Lifetime = { 2.2, 3 },
		Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = 1.6,
		Size = { { 0, 0.3 * s }, { 1, 0.05 * s } }, Color = { { 0, GHOST }, { 1, VIOLET } },
		Transparency = { { 0, 1 }, { 0.2, 0.35 }, { 1, 1 } }, LightEmission = 1, ZOffset = 0.6,
	})
	local back = fx:volume("Aura", Vector3.new(4.6, 6.4, 0.6) * s, backrest)
	fx:emitter("Aura", back, 3, {
		Texture = "mote", Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		EmissionDirection = Enum.NormalId.Top, Speed = { 0.08 * s, 0.25 * s }, Lifetime = { 3.5, 5 },
		Size = { { 0, 0 }, { 0.3, 0.3 * s }, { 1, 0 } }, Color = { { 0, COLD }, { 1, VIOLET } },
		LightEmission = 1, ZOffset = 0.2,
	})
	fx:light("ColdLight", seat, COLD, 9 * s, 0.9)

	local lastApparition = -math.huge
	local controller = {}
	function controller.update(t: number)
		local cycle = (t + fx.phase) % APPARITION_PERIOD
		if cycle < 0.1 and t - lastApparition > 1 then
			lastApparition = t
			fx:burst(apparition, 1)
		end
		local since = t - lastApparition
		fx:setLight(1, 0.65 + 0.1 * math.sin(t * 0.9) + 1.1 * math.exp(-((since - 0.5) / 0.5) ^ 2))
	end
	return controller
end
