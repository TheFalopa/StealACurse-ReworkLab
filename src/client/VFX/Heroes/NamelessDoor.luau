-- NAMELESS DOOR: a forbidden threshold with something behind it.
-- Primary: the inner depth - doorway outlines flowing away from the viewer
--          into the interior, over a deep glow at the back.
-- Secondary: motes drawn in through the threshold; low threshold mist.
-- Event: occasionally something escapes - a short outward burst + glow swell.

local TEAL = Color3.fromRGB(90, 240, 212)
local VIOLET = Color3.fromRGB(160, 110, 255)
local ESCAPE_PERIOD = 5.6

return function(fx)
	local s = fx.scale
	-- Attachment +Y points into the door (-Z), so Top emission flows inward.
	local inward = CFrame.Angles(-math.pi / 2, 0, 0)
	local mouth = fx:at("Mouth", "Root", Vector3.new(-0.13, -0.3, 1.6), inward)
	local deep = fx:at("Deep", "Root", Vector3.new(-0.13, -0.3, -1.9))
	local front = fx:at("Front", "Root", Vector3.new(-0.13, -0.4, 2.8))
	local sill = fx:at("Sill", "Root", Vector3.new(-0.13, -3.9, 1.2))

	-- A dark interior so the doorway reads as depth, not as a see-through frame.
	fx:emitter("Void", deep, 1, {
		Texture = "void_core", Color = Color3.fromRGB(8, 10, 22), Size = 5.4 * s, Squash = 0.45, Lifetime = 3, Speed = 0,
		Transparency = { { 0, 1 }, { 0.2, 0.08 }, { 0.8, 0.08 }, { 1, 1 } },
		LightEmission = 0, ZOffset = -0.8, LockedToPart = true,
	})
	fx:emitter("DeepGlow", deep, 0.7, {
		Texture = "glow_soft", Color = TEAL, Size = 5.4 * s, Lifetime = 3, Speed = 0,
		Transparency = { { 0, 1 }, { 0.3, 0.5 }, { 0.7, 0.5 }, { 1, 1 } },
		LightEmission = 1, ZOffset = -0.5, LockedToPart = true,
	})
	fx:emitter("Depth", mouth, 0.85, {
		Texture = "portal_frame", Color = { { 0, TEAL }, { 1, VIOLET } }, Lifetime = 2.4,
		Speed = 1.5 * s, Size = { { 0, 4.8 * s }, { 1, 1.2 * s } },
		Transparency = { { 0, 1 }, { 0.15, 0.25 }, { 0.75, 0.55 }, { 1, 1 } },
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.zero,
		LightEmission = 1, Brightness = 1.4, LockedToPart = true, ZOffset = 0.2,
	})
	local field = fx:volume("Threshold", Vector3.new(4.2, 6.2, 0.6) * s, front)
	fx:emitter("Drawn", field, 6, {
		Texture = "mote", Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		EmissionDirection = Enum.NormalId.Front, Speed = { 0.9 * s, 1.4 * s }, Drag = -0.5,
		Lifetime = { 1.8, 2.4 }, Size = { { 0, 0 }, { 0.2, 0.3 * s }, { 1, 0 } },
		Color = { { 0, TEAL }, { 1, VIOLET } }, Transparency = { { 0, 1 }, { 0.2, 0.1 }, { 1, 0.6 } },
		LightEmission = 1, ZOffset = 0.4,
	})
	local floor = fx:volume("Sill", Vector3.new(3.6, 0.2, 1.6) * s, sill)
	fx:emitter("Mist", floor, 2.5, {
		Texture = "wisp", Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		EmissionDirection = Enum.NormalId.Back, Speed = { 0.2 * s, 0.45 * s }, Lifetime = { 2.4, 3.2 },
		Size = { { 0, 1 * s }, { 1, 2.4 * s } }, Color = TEAL, Rotation = { 0, 360 }, RotSpeed = { -15, 15 },
		Transparency = { { 0, 1 }, { 0.3, 0.72 }, { 1, 1 } }, LightEmission = 0.6, ZOffset = 0.1,
	})
	local escape = fx:emitter("Escape", deep, 0, {
		Texture = "streak", EmissionDirection = Enum.NormalId.Back, SpreadAngle = Vector2.new(28, 28),
		Speed = { 3 * s, 5 * s }, Drag = 1.5, Lifetime = { 0.6, 1 },
		Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = 1.8,
		Size = { { 0, 0.25 * s }, { 1, 0.05 * s } }, Color = { { 0, Color3.fromRGB(220, 200, 255) }, { 1, VIOLET } },
		Transparency = { { 0, 0.1 }, { 1, 1 } }, LightEmission = 1, ZOffset = 0.8,
	})
	local swell = fx:emitter("Swell", deep, 0, {
		Texture = "glow_soft", Color = VIOLET, Lifetime = 0.8, Speed = 0,
		Size = { { 0, 3 * s }, { 1, 6 * s } }, Transparency = { { 0, 0.4 }, { 1, 1 } },
		LightEmission = 1, ZOffset = -0.3, LockedToPart = true,
	})
	fx:light("DoorLight", front, TEAL, 10 * s, 1.1)

	local lastEscape = -math.huge
	local controller = {}
	function controller.update(t: number)
		local cycle = (t + fx.phase) % ESCAPE_PERIOD
		if cycle < 0.1 and t - lastEscape > 1 then
			lastEscape = t
			fx:burst(swell, 1)
			fx:burst(escape, 12)
		end
		-- Quiet, slightly uneven breathing of the interior light.
		fx:setLight(1, 0.8 + 0.12 * math.sin(t * 1.7) + 0.06 * math.sin(t * 4.3) + 0.9 * math.exp(-cycle * 3))
	end
	return controller
end
