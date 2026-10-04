-- THE VOID: a miniature black hole held inside the model's aperture.
-- Primary: dark singularity + hot asymmetric horizon lip.
-- Secondary: tilted accretion vortex (two speeds) and inward suction streaks.
-- Detail: three short comet streaks orbiting on the disc plane.
-- Event: periodic gravitational compression pulse.
-- Everything stays within ~0.7x the model width around its centre.

local VOID = Color3.fromRGB(6, 2, 16)
local MAGENTA = Color3.fromRGB(238, 98, 214)
local VIOLET = Color3.fromRGB(132, 70, 255)
local HOT = Color3.fromRGB(255, 228, 252)
local PULSE_PERIOD = 5.2

return function(fx)
	local s = fx.scale
	local center = Vector3.new(0, 0.25, 0.6) * s
	-- Disc normal tilted from up toward the viewer, with a slight roll, so the
	-- vortex reads as a lit ellipse instead of a face-on hoop.
	local discTilt = CFrame.Angles(math.rad(24), 0, math.rad(-9))
	local core = fx:attach("Core", center, "Root")
	local disc = fx:attach("Disc", center, "Root", discTilt)

	fx:emitter("Halo", core, 0.6, {
		Texture = "glow_soft", Color = VIOLET, Size = 7.8 * s, Lifetime = 3,
		Transparency = { { 0, 1 }, { 0.3, 0.78 }, { 0.7, 0.78 }, { 1, 1 } },
		LightEmission = 1, ZOffset = -1, LockedToPart = true, Speed = 0,
	})
	fx:emitter("DiscOuter", disc, 0.75, {
		Texture = "accretion", Color = Color3.new(1, 1, 1), Size = 7.2 * s, Lifetime = 4,
		Transparency = { { 0, 1 }, { 0.25, 0.05 }, { 0.75, 0.05 }, { 1, 1 } },
		Rotation = { 0, 360 }, RotSpeed = { 30, 38 }, Speed = 0.02,
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.zero,
		LightEmission = 1, Brightness = 1.15, LockedToPart = true, ZOffset = 0.4,
	})
	fx:emitter("DiscInner", disc, 0.8, {
		Texture = "accretion", Color = HOT, Size = 4.6 * s, Lifetime = 3,
		Transparency = { { 0, 1 }, { 0.25, 0.4 }, { 0.75, 0.4 }, { 1, 1 } },
		Rotation = { 0, 360 }, RotSpeed = { 70, 84 }, Speed = 0.02,
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.zero,
		LightEmission = 1, Brightness = 1.4, LockedToPart = true, ZOffset = 0.5,
	})
	fx:emitter("Singularity", core, 1, {
		Texture = "void_core", Color = VOID, Size = 2.6 * s, Lifetime = 3, Speed = 0,
		Transparency = { { 0, 1 }, { 0.2, 0 }, { 0.8, 0 }, { 1, 1 } },
		LightEmission = 0, ZOffset = 1.4, LockedToPart = true,
	})
	local rim = fx:emitter("Horizon", core, 1, {
		Texture = "horizon_rim", Color = MAGENTA, Size = 3.2 * s, Lifetime = 3, Speed = 0,
		Transparency = { { 0, 1 }, { 0.3, 0.2 }, { 0.7, 0.2 }, { 1, 1 } },
		Rotation = { 0, 360 }, RotSpeed = { -14, 14 },
		LightEmission = 1, Brightness = 1.4, ZOffset = 1.6, LockedToPart = true,
	})
	-- Inward suction: streaks spawn on a shell and accelerate into the core.
	local shell = fx:volume("Suction", Vector3.one * 7.6 * s, disc)
	local suction = fx:emitter("Suction", shell, 18, {
		Texture = "streak", Shape = Enum.ParticleEmitterShape.Sphere,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface, ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
		Color = { { 0, VIOLET }, { 0.6, MAGENTA }, { 1, HOT } },
		Size = { { 0, 0.08 * s }, { 0.4, 0.24 * s }, { 1, 0.05 * s } },
		Squash = { { 0, 1.4 }, { 1, 2.6 } }, Orientation = Enum.ParticleOrientation.VelocityParallel,
		Transparency = { { 0, 1 }, { 0.25, 0.05 }, { 1, 0.25 } },
		Speed = { 1.9 * s, 2.6 * s }, Drag = -1.4, Lifetime = { 0.95, 1.1 },
		LightEmission = 1, Brightness = 1.6, ZOffset = 1,
	})
	-- A faster, partial inner flow: overlapping lifetimes make the vortex's
	-- brightness break up and drift instead of reading as one smooth ring.
	fx:emitter("Flow", disc, 1.3, {
		Texture = "accretion", Color = MAGENTA, Size = { { 0, 5.2 * s }, { 1, 4.4 * s } }, Lifetime = { 1.4, 1.9 },
		Transparency = { { 0, 1 }, { 0.3, 0.5 }, { 0.6, 0.6 }, { 1, 1 } },
		Rotation = { 0, 360 }, RotSpeed = { 110, 140 }, Speed = 0.02,
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.zero,
		LightEmission = 1, Brightness = 1.2, LockedToPart = true, ZOffset = 0.45,
	})
	-- Controlled debris: a few dark tumbling fragments drawn slowly inward.
	local debrisShell = fx:volume("Debris", Vector3.one * 8.4 * s, disc)
	fx:emitter("Debris", debrisShell, 1.4, {
		Texture = "shard", Shape = Enum.ParticleEmitterShape.Sphere,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface, ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
		Color = Color3.new(1, 1, 1), Size = { { 0, 0 }, { 0.15, 0.42 * s }, { 0.85, 0.3 * s }, { 1, 0 } },
		Speed = { 0.7 * s, 1.1 * s }, Drag = -0.35, Lifetime = { 3.4, 4.2 },
		Rotation = { 0, 360 }, RotSpeed = { -140, 140 }, Transparency = { { 0, 1 }, { 0.15, 0 }, { 0.9, 0 }, { 1, 1 } },
		LightEmission = 0.15, ZOffset = 0.7,
	})
	local flare = fx:emitter("Flare", core, 0, {
		Texture = "spark", Color = HOT, Lifetime = 0.45, Speed = 0, Rotation = { 0, 90 },
		Size = { { 0, 1 * s }, { 0.3, 4.2 * s }, { 1, 0 } }, Transparency = { { 0, 0.1 }, { 1, 1 } },
		LightEmission = 1, ZOffset = 1.8, LockedToPart = true,
	})
	local pulse = fx:emitter("Compression", core, 0, {
		Texture = "glow_soft", Color = MAGENTA, Lifetime = 0.5, Speed = 0,
		Size = { { 0, 8 * s }, { 1, 1.4 * s } },
		Transparency = { { 0, 0.95 }, { 0.45, 0.45 }, { 1, 1 } },
		LightEmission = 1, ZOffset = 1.3, LockedToPart = true,
	})
	fx:light("Glow", core, VIOLET, 12 * s, 1.6)

	-- Three comet streaks orbiting on the disc plane at different radii/speeds.
	local orbiters = {}
	for i, data in { { 2.3, 1.55, 0 }, { 2.9, 1.15, 2.1 }, { 3.4, 0.9, 4.2 } } do
		local a0 = fx:attach("Orbit" .. i .. "A", center)
		local a1 = fx:attach("Orbit" .. i .. "B", center)
		fx:trail("Orbit" .. i, a0, a1, {
			Lifetime = 0.34, MinLength = 0.02, LightEmission = 1, Brightness = 2,
			Color = { { 0, HOT }, { 1, MAGENTA } },
			Transparency = { { 0, 0.05 }, { 1, 1 } }, WidthScale = { { 0, 1 }, { 1, 0 } },
		})
		table.insert(orbiters, { a0 = a0, a1 = a1, radius = data[1] * s, speed = data[2], offset = data[3] })
	end

	local lastPulse = -math.huge
	local controller = {}
	function controller.update(t: number)
		local cycle = (t + fx.phase) % PULSE_PERIOD
		if cycle < 0.1 and t - lastPulse > 1 then
			lastPulse = t
			fx:burst(pulse, 1)
			fx:burst(suction, 18)
			-- The release after the compression: one short flare.
			task.delay(0.42, function() fx:burst(flare, 1) end)
		end
		-- Light swells into the compression and settles afterwards.
		local swell = if cycle < 0.45 then 1 + 1.3 * math.sin(cycle / 0.45 * math.pi) else 1
		fx:setLight(1, (0.85 + 0.15 * math.sin(t * 1.3)) * swell)
		rim.Brightness = 1.4 * swell
	end
	function controller.frame(t: number)
		local discFrame = disc.CFrame
		local right, forward = discFrame.RightVector, discFrame.LookVector
		local normal = discFrame.UpVector * 0.09 * s
		for _, o in orbiters do
			local angle = -(t * o.speed + o.offset)
			local radius = o.radius * (1 + 0.04 * math.sin(t * 2.3 + o.offset))
			local p = discFrame.Position + right * math.cos(angle) * radius + forward * math.sin(angle) * radius
			o.a0.Position = p + normal
			o.a1.Position = p - normal
		end
	end
	return controller
end
