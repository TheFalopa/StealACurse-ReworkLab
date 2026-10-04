-- JUDGEMENT SCALES: celestial gold, weighing a soul against light.
-- Primary: the heavy (lower) pan holds a flickering cyan soul flame, the same
--          spectral cyan as the game's Souls currency.
-- Secondary: the light pan sheds rising golden motes; a soft golden backlight
--            behind the crystal head separates it from the night.
-- Detail: falling gold drips under the heavy pan.
-- Event: the pans take turns being "judged" with a short flash.

local IVORY = Color3.fromRGB(255, 242, 206)
local GOLD = Color3.fromRGB(246, 190, 90)
local SOUL = Color3.fromRGB(112, 240, 226)
local SOUL_CORE = Color3.fromRGB(220, 255, 250)
local PERIOD = 3.4

return function(fx)
	local s = fx.scale
	-- PanL hangs lower in the rig (heavy); PanR is the lighter, higher pan.
	local heavy = fx:at("HeavyPan", "PanL", Vector3.new(0, 0.35, 0.1))
	local light = fx:at("LightPan", "PanR", Vector3.new(0, 0.3, 0.1))
	local drip = fx:at("HeavyDrip", "PanL", Vector3.new(0, -0.45, 0.1))
	local back = fx:at("Backlight", "Root", Vector3.new(0, 2.2, -0.9))

	fx:emitter("Backlight", back, 0.6, {
		Texture = "glow_soft", Color = GOLD, Size = 5.2 * s, Lifetime = 3, Speed = 0,
		Transparency = { { 0, 1 }, { 0.3, 0.55 }, { 0.7, 0.55 }, { 1, 1 } },
		LightEmission = 1, ZOffset = -2, LockedToPart = true,
	})
	-- The weighed soul: a small flame that licks upward out of the heavy pan.
	fx:emitter("SoulGlow", heavy, 1, {
		Texture = "glow_core", Color = SOUL, Size = 1.9 * s, Lifetime = 2, Speed = 0,
		Transparency = { { 0, 1 }, { 0.3, 0.35 }, { 0.7, 0.35 }, { 1, 1 } },
		LightEmission = 1, ZOffset = 1, LockedToPart = true,
	})
	fx:emitter("SoulFlame", heavy, 9, {
		Texture = "wisp", Lifetime = { 0.6, 0.9 }, Speed = { 0.7 * s, 1.1 * s },
		EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(12, 12),
		Acceleration = Vector3.new(0, 0.8, 0) * s, Drag = 1.2,
		Size = { { 0, 0.75 * s }, { 0.4, 0.55 * s }, { 1, 0.1 * s } },
		Color = { { 0, SOUL_CORE }, { 0.45, SOUL }, { 1, Color3.fromRGB(40, 150, 170) } },
		Transparency = { { 0, 0.3 }, { 0.6, 0.45 }, { 1, 1 } },
		Rotation = { -20, 20 }, RotSpeed = { -40, 40 },
		LightEmission = 1, ZOffset = 1.1,
	})
	local lightDish = fx:volume("LightDish", Vector3.new(1.3, 0.12, 1.3) * s, light)
	local motes = fx:emitter("Motes", lightDish, 4, {
		Texture = "mote", Shape = Enum.ParticleEmitterShape.Disc,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		Color = { { 0, IVORY }, { 1, GOLD } }, Lifetime = { 1.6, 2.4 }, Speed = { 0.5 * s, 1 * s },
		SpreadAngle = Vector2.new(20, 20), EmissionDirection = Enum.NormalId.Top,
		Acceleration = Vector3.new(0, 0.1, 0) * s, Drag = 0.45,
		Size = { { 0, 0 }, { 0.2, 0.5 * s }, { 1, 0 } }, LightEmission = 1, ZOffset = 0.8,
	})
	fx:emitter("Drip", drip, 1.6, {
		Texture = "streak", Color = GOLD, Lifetime = 0.6, Speed = { 0.6 * s, 1 * s },
		EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(6, 6),
		Acceleration = Vector3.new(0, -5, 0) * s, Orientation = Enum.ParticleOrientation.VelocityParallel,
		Size = { { 0, 0.3 * s }, { 1, 0.12 * s } }, Squash = 2,
		Transparency = { { 0, 0.1 }, { 1, 1 } }, LightEmission = 1, ZOffset = 0.6,
	})
	local flashes = {
		fx:emitter("JudgedSoul", heavy, 0, {
			Texture = "glow_core", Color = SOUL, Lifetime = 0.6, Speed = 0,
			Size = { { 0, 3.4 * s }, { 1, 0.8 * s } }, Transparency = { { 0, 0.25 }, { 1, 1 } },
			LightEmission = 1, ZOffset = 1.2, LockedToPart = true,
		}),
		fx:emitter("JudgedLight", light, 0, {
			Texture = "glow_core", Color = GOLD, Lifetime = 0.6, Speed = 0,
			Size = { { 0, 3.4 * s }, { 1, 0.8 * s } }, Transparency = { { 0, 0.25 }, { 1, 1 } },
			LightEmission = 1, ZOffset = 1.2, LockedToPart = true,
		}),
	}
	fx:light("SoulLight", heavy, SOUL, 8 * s, 1.2)

	-- Balance: a single mote of light crosses from the light pan, over the
	-- fulcrum, into the weighed soul, then the soul flares (judgement).
	local traveler = fx:attach("Transfer", Vector3.zero)
	local trail = fx:emitter("TransferTrail", traveler, 40, {
		Texture = "mote", Color = { { 0, IVORY }, { 1, GOLD } }, Lifetime = { 0.35, 0.5 }, Speed = 0,
		Size = { { 0, 0.42 * s }, { 1, 0 } }, Transparency = { { 0, 0.1 }, { 1, 1 } }, LightEmission = 1, ZOffset = 1,
	})
	local TRAVEL = 1.3

	local lastJudge = -math.huge
	local controller = {}
	function controller.frame(t: number)
		local age = (t + fx.phase) % PERIOD
		local a, b = light.CFrame.Position, heavy.CFrame.Position
		if age > TRAVEL then
			trail.Enabled = false
			traveler.Position = a
			return
		end
		trail.Enabled = true
		local u = age / TRAVEL
		u = u * u * (3 - 2 * u)
		local top = (a + b) * 0.5 + Vector3.new(0, 2.6 * s, 0.6 * s)
		-- Quadratic arc over the fulcrum.
		traveler.Position = a:Lerp(top, u):Lerp(top:Lerp(b, u), u)
	end
	function controller.update(t: number)
		local cycle = (t + fx.phase) % (PERIOD * 2)
		local age = cycle % PERIOD
		-- The transferred light reaches the soul: it is judged and flares.
		-- Every other judgement the light pan answers with a burst of motes.
		if age >= TRAVEL and age < TRAVEL + 0.1 and t - lastJudge > 1 then
			lastJudge = t
			fx:burst(flashes[1], 1)
			if cycle >= PERIOD then
				fx:burst(flashes[2], 1)
				fx:burst(motes, 10)
			end
		end
		-- The soul light flickers like a flame and flares when it is judged.
		local since = age - TRAVEL
		local flare = if since >= 0 then math.exp(-since * 3) else 0
		fx:setLight(1, 0.8 + 0.15 * math.sin(t * 9) + 0.1 * math.sin(t * 13.7) + 0.8 * flare)
	end
	return controller
end
