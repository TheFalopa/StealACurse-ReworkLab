-- BLOOD MOON ROSE: a living crimson bloom with a heartbeat.
-- Primary: a "lub-dub" glow pulse on the face of the bloom, backed by a low
--          blood-moon halo that separates the silhouette from the night.
-- Secondary: petals shed from the bloom face, fluttering to the ground;
--            garnet pollen embers rising from the heart.
-- Detail: occasional glints at the thorn-arm tips.

local CRIMSON = Color3.fromRGB(236, 40, 74)
local HOT = Color3.fromRGB(255, 196, 204)
local MOON = Color3.fromRGB(196, 18, 52)
local BEAT_PERIOD = 1.55

return function(fx)
	local s = fx.scale
	-- The bloom face sits ~1.3 studs in front of the Bloom joint.
	local heart = fx:at("Heart", "Bloom", Vector3.new(0, 0.95, 1.55))
	local moon = fx:at("Moon", "Bloom", Vector3.new(0, 1.0, -0.9))
	local face = fx:at("Face", "Bloom", Vector3.new(0, 1.0, 1.25))
	local thornL = fx:at("ThornL", "ThornArmL", Vector3.new(1.35, 0.05, 0.3))
	local thornR = fx:at("ThornR", "ThornArmR", Vector3.new(-1.35, 0.05, 0.3))

	fx:emitter("BloodMoon", moon, 0.6, {
		Texture = "glow_soft", Color = MOON, Size = 7 * s, Lifetime = 3, Speed = 0,
		Transparency = { { 0, 1 }, { 0.3, 0.42 }, { 0.7, 0.42 }, { 1, 1 } },
		LightEmission = 1, ZOffset = -2, LockedToPart = true,
	})
	-- The bloom must stay readable: the heart is a small hot point, and the
	-- beat is a brief, translucent swell rather than an opaque orb.
	fx:emitter("HeartCore", heart, 1, {
		Texture = "glow_core", Color = HOT, Size = 0.75 * s, Lifetime = 2, Speed = 0,
		Transparency = { { 0, 1 }, { 0.3, 0.45 }, { 0.7, 0.45 }, { 1, 1 } },
		LightEmission = 1, ZOffset = 1.4, LockedToPart = true,
	})
	local beat = fx:emitter("Heartbeat", heart, 0, {
		Texture = "glow_soft", Color = CRIMSON, Lifetime = 0.5, Speed = 0,
		Size = { { 0, 1.2 * s }, { 0.2, 2.1 * s }, { 1, 1.8 * s } },
		Transparency = { { 0, 0.55 }, { 1, 1 } },
		LightEmission = 1, ZOffset = 1.2, LockedToPart = true,
	})
	-- Petals shed across the bloom face, flutter and settle toward the ground.
	local sheet = fx:volume("Face", Vector3.new(2.8, 2.6, 0.3) * s, face)
	fx:emitter("Petals", sheet, 2.4, {
		Texture = "petal", Shape = Enum.ParticleEmitterShape.Box,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		Color = Color3.fromRGB(205, 70, 96), Lifetime = { 2.6, 3.4 }, Speed = { 0.3, 0.7 },
		-- The model faces +Z, which is the part's Back face.
		EmissionDirection = Enum.NormalId.Back, SpreadAngle = Vector2.new(40, 40),
		Size = { { 0, 0 }, { 0.08, 0.5 * s }, { 0.85, 0.44 * s }, { 1, 0 } },
		Transparency = { { 0, 0 }, { 0.85, 0.05 }, { 1, 1 } },
		Rotation = { 0, 360 }, RotSpeed = { -100, 100 },
		Acceleration = Vector3.new(0.35, -1, 0.25) * s, Drag = 0.8,
		LightEmission = 0.05, LightInfluence = 0.5, ZOffset = 0.3,
	})
	local pollen = fx:emitter("Pollen", heart, 6, {
		Texture = "ember", Lifetime = { 1.3, 2.1 }, Speed = { 0.8 * s, 1.6 * s },
		SpreadAngle = Vector2.new(42, 42), EmissionDirection = Enum.NormalId.Top,
		Acceleration = Vector3.new(0.15, 0.5, 0.1) * s, Drag = 0.6,
		Size = { { 0, 0.28 * s }, { 0.5, 0.22 * s }, { 1, 0 } },
		Squash = 0.8, Orientation = Enum.ParticleOrientation.VelocityParallel,
		Color = { { 0, Color3.fromRGB(255, 214, 160) }, { 0.35, Color3.fromRGB(255, 74, 92) }, { 1, Color3.fromRGB(120, 8, 30) } },
		Transparency = { { 0, 0.05 }, { 1, 1 } }, LightEmission = 1, ZOffset = 1,
	})
	for _, thorn in { thornL, thornR } do
		fx:emitter("Glint", thorn, 0.4, {
			Texture = "spark", Color = Color3.fromRGB(255, 190, 200), Lifetime = 0.4, Speed = 0,
			Size = { { 0, 0 }, { 0.5, 1 * s }, { 1, 0 } }, Rotation = { 0, 45 },
			LightEmission = 1, ZOffset = 1, LockedToPart = true,
		})
	end
	fx:light("Glow", heart, CRIMSON, 10 * s, 1.5)

	local bloomBurst = fx:emitter("BloomBurst", sheet, 0, {
		Texture = "petal", Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		Color = Color3.fromRGB(225, 80, 106), Lifetime = { 1.8, 2.6 }, Speed = { 1.4 * s, 2.4 * s },
		EmissionDirection = Enum.NormalId.Back, SpreadAngle = Vector2.new(65, 65),
		Size = { { 0, 0 }, { 0.08, 0.46 * s }, { 1, 0 } }, Rotation = { 0, 360 }, RotSpeed = { -220, 220 },
		Acceleration = Vector3.new(0, -2.2, 0) * s, Drag = 1.6, LightEmission = 0.1, LightInfluence = 0.5, ZOffset = 0.5,
	})
	local lastBeat, lastDub = -math.huge, -math.huge
	local beats = 0
	local controller = {}
	function controller.update(t: number)
		local cycle = (t + fx.phase) % BEAT_PERIOD
		if cycle < 0.08 and t - lastBeat > 0.5 then
			lastBeat = t
			beats += 1
			fx:burst(beat, 1)
			fx:burst(pollen, 4)
			-- Every fourth beat the bloom answers with a stronger exhale.
			if beats % 4 == 0 then
				fx:burst(bloomBurst, 7)
				fx:burst(pollen, 10)
				fx:burst(beat, 1)
			end
		elseif cycle >= 0.24 and cycle < 0.32 and t - lastDub > 0.5 then
			lastDub = t
			fx:burst(beat, 1)
		end
		local lub = math.exp(-((cycle - 0.04) / 0.09) ^ 2)
		local dub = 0.7 * math.exp(-((cycle - 0.28) / 0.09) ^ 2)
		local strong = if beats % 4 == 0 then 1.6 else 1
		fx:setLight(1, 0.55 + 0.9 * (lub + dub) * strong)
	end
	return controller
end
