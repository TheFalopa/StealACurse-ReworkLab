-- THE LAST STAR: an endgame celestial relic.
-- Primary: an eight-point star flare held in the chest ring (cold white/blue).
-- Secondary: small crystalline fragments orbiting the star in the ring plane,
--            each shedding stellar dust.
-- Event: a rare, stronger stellar pulse.
local Kit = require(script.Parent.Parent.Kit)

local STAR = Color3.fromRGB(226, 240, 255)
local BLUE = Color3.fromRGB(140, 186, 255)
local PULSE_PERIOD = 7.5

return function(fx)
	local s = fx.scale
	local star = fx:at("Star", "Star", Vector3.new(0, 0, 0.95))

	fx:emitter("StarCore", star, 1, {
		Texture = "glow_core", Color = STAR, Size = 2.4 * s, Lifetime = 2, Speed = 0,
		Transparency = { { 0, 1 }, { 0.3, 0.35 }, { 0.7, 0.35 }, { 1, 1 } },
		LightEmission = 1, ZOffset = 1.2, LockedToPart = true,
	})
	local primary = fx:emitter("Flare", star, 0.8, {
		Texture = "spark", Color = STAR, Size = 3.6 * s, Lifetime = 2, Speed = 0,
		Rotation = { 0, 0 }, RotSpeed = { -5, 5 },
		Transparency = { { 0, 1 }, { 0.3, 0.12 }, { 0.7, 0.12 }, { 1, 1 } },
		LightEmission = 1, Brightness = 1.3, ZOffset = 1.4, LockedToPart = true,
	})
	fx:emitter("FlareDiagonal", star, 0.8, {
		Texture = "spark", Color = BLUE, Size = 2.3 * s, Lifetime = 2, Speed = 0,
		Rotation = { 45, 45 }, RotSpeed = { -5, 5 },
		Transparency = { { 0, 1 }, { 0.3, 0.3 }, { 0.7, 0.3 }, { 1, 1 } },
		LightEmission = 1, ZOffset = 1.35, LockedToPart = true,
	})
	-- Orbiting crystal fragments: a locked sprite rides each orbit attachment.
	local orbiters = {}
	for i, data in { { 1.9, 0.9, 0 }, { 2.35, -0.65, 1.6 }, { 2.1, 0.75, 3.3 }, { 2.6, -0.5, 4.8 } } do
		local at = fx:attach("Orbit" .. i, Vector3.zero)
		fx:emitter("Crystal" .. i, at, 2.5, {
			Texture = "crystal", Color = Color3.new(1, 1, 1), Lifetime = 0.45, Speed = 0,
			Size = 0.8 * s, Rotation = { -20, 20 }, LightEmission = 0.6, ZOffset = 1.3, LockedToPart = true,
		})
		fx:emitter("Stardust" .. i, at, 14, {
			Texture = "mote", Color = { { 0, STAR }, { 1, BLUE } }, Lifetime = { 0.5, 0.8 }, Speed = 0,
			Size = { { 0, 0.3 * s }, { 1, 0 } }, Transparency = { { 0, 0.15 }, { 1, 1 } }, LightEmission = 1, ZOffset = 1.2,
		})
		table.insert(orbiters, { at = at, radius = data[1] * s, speed = data[2], offset = data[3] })
	end
	local burst = fx:emitter("Supernal", star, 0, {
		Texture = "spark", Color = STAR, Lifetime = 0.6, Speed = 0, Rotation = { 22, 22 },
		Size = { { 0, 1 * s }, { 0.3, 7 * s }, { 1, 0 } }, Transparency = { { 0, 0.05 }, { 1, 1 } },
		LightEmission = 1, ZOffset = 1.5, LockedToPart = true,
	})
	local scatter = fx:emitter("Scatter", star, 0, {
		Texture = "mote", EmissionDirection = Enum.NormalId.Back, SpreadAngle = Vector2.new(80, 80),
		Speed = { 3 * s, 5 * s }, Drag = 3, Lifetime = { 0.8, 1.2 },
		Size = { { 0, 0.3 * s }, { 1, 0 } }, Color = { { 0, STAR }, { 1, BLUE } }, LightEmission = 1, ZOffset = 1.2,
	})
	fx:light("StarLight", star, BLUE, 11 * s, 1.1)

	local lastPulse = -math.huge
	local controller = {}
	function controller.frame(t: number)
		local center = star.CFrame.Position
		for _, o in orbiters do
			local angle = t * o.speed + o.offset
			-- Ring plane faces the viewer (XY), with a slight forward tilt.
			o.at.Position = center + Vector3.new(math.cos(angle) * o.radius, math.sin(angle) * o.radius * 0.92, math.sin(angle) * 0.25 * s)
		end
	end
	function controller.update(t: number)
		local cycle = (t + fx.phase) % PULSE_PERIOD
		if cycle < 0.1 and t - lastPulse > 1 then
			lastPulse = t
			fx:burst(burst, 1)
			fx:burst(scatter, 14)
		end
		local twinkle = 0.9 + 0.1 * math.sin(t * 3.1) * math.sin(t * 1.3)
		primary.Brightness = 1.3 * twinkle
		fx:setLight(1, 0.75 * twinkle + 1.3 * math.exp(-(t - lastPulse) * 2.5))
	end
	return controller
end
