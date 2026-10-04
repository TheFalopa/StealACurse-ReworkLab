-- ECLIPSE STAG: a lunar creature crowned by an eclipse.
-- Primary: an eclipse halo behind the antlers (dark disc, ember-orange corona).
-- Secondary: pale lunar motes and tiny crescents rising from the antlers;
--            ember sparks and short trails at the hooves when it moves.
-- Detail: faint celestial dust along the mane.
-- Event: the corona slowly brightens into a brief "totality" flare.

local LUNAR = Color3.fromRGB(214, 232, 255)
local EMBER = Color3.fromRGB(255, 146, 72)
local DARK = Color3.fromRGB(10, 6, 20)
local TOTALITY_PERIOD = 6.4

return function(fx)
	local s = fx.scale
	local eclipse = fx:at("Eclipse", "Head", Vector3.new(-0.05, 2.0, -0.7))
	local antlers = fx:at("Antlers", "Head", Vector3.new(-0.1, 2.1, 0.1))
	local mane = fx:at("Mane", "Mane", Vector3.new(0, 0.3, 0.1))

	fx:emitter("EclipseDisc", eclipse, 1, {
		Texture = "void_core", Color = DARK, Size = 2.1 * s, Lifetime = 3, Speed = 0,
		Transparency = { { 0, 1 }, { 0.2, 0.05 }, { 0.8, 0.05 }, { 1, 1 } },
		LightEmission = 0, ZOffset = -0.8, LockedToPart = true,
	})
	local corona = fx:emitter("Corona", eclipse, 1, {
		Texture = "horizon_rim", Color = EMBER, Size = 2.8 * s, Lifetime = 3, Speed = 0,
		Rotation = { 0, 360 }, RotSpeed = { -8, 8 },
		Transparency = { { 0, 1 }, { 0.3, 0.32 }, { 0.7, 0.32 }, { 1, 1 } },
		LightEmission = 1, ZOffset = -0.7, LockedToPart = true,
	})
	fx:emitter("LunarGlow", eclipse, 0.6, {
		Texture = "glow_soft", Color = LUNAR, Size = 5 * s, Lifetime = 3, Speed = 0,
		Transparency = { { 0, 1 }, { 0.3, 0.8 }, { 0.7, 0.8 }, { 1, 1 } },
		LightEmission = 1, ZOffset = -1, LockedToPart = true,
	})
	local crown = fx:volume("Antlers", Vector3.new(2.8, 1.6, 1.4) * s, antlers)
	fx:emitter("LunarMotes", crown, 3, {
		Texture = "mote", Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		EmissionDirection = Enum.NormalId.Top, Speed = { 0.3 * s, 0.6 * s }, Lifetime = { 1.8, 2.6 }, Drag = 0.4,
		Size = { { 0, 0 }, { 0.25, 0.28 * s }, { 1, 0 } }, Color = LUNAR, LightEmission = 1, ZOffset = 0.5,
	})
	fx:emitter("Crescents", crown, 0.9, {
		Texture = "crescent", Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		EmissionDirection = Enum.NormalId.Top, Speed = { 0.25 * s, 0.45 * s }, Lifetime = { 2, 2.8 },
		Rotation = { -30, 30 }, RotSpeed = { -25, 25 }, Size = { { 0, 0 }, { 0.25, 0.42 * s }, { 1, 0 } },
		Color = { { 0, LUNAR }, { 1, Color3.fromRGB(255, 200, 150) } }, LightEmission = 1, ZOffset = 0.6,
	})
	local dust = fx:volume("Mane", Vector3.new(3.2, 1.2, 1.4) * s, mane)
	fx:emitter("Dust", dust, 1.6, {
		Texture = "mote", Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		EmissionDirection = Enum.NormalId.Top, Speed = { 0.05 * s, 0.15 * s }, Lifetime = { 2.5, 3.5 },
		Size = { { 0, 0 }, { 0.3, 0.18 * s }, { 1, 0 } }, Color = LUNAR, Transparency = 0.3, LightEmission = 1, ZOffset = 0.3,
	})
	-- Hooves: ember sparks, and short trails that only show while moving.
	for index, knee in { "Knee0", "Knee1", "Knee2", "Knee3" } do
		local hoof = fx:at("Hoof" .. index, knee, Vector3.new(0, -1.2, 0))
		fx:emitter("HoofEmber" .. index, hoof, 0.8, {
			Texture = "ember", EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(40, 40),
			Speed = { 0.4 * s, 0.9 * s }, Lifetime = { 0.6, 1 }, Size = { { 0, 0.22 * s }, { 1, 0 } },
			Color = { { 0, Color3.fromRGB(255, 210, 150) }, { 1, EMBER } }, LightEmission = 1, ZOffset = 0.3,
		})
		if index == 1 or index == 3 then
			local upper = fx:at("HoofTop" .. index, knee, Vector3.new(0, -0.85, 0))
			fx:trail("HoofTrail" .. index, hoof, upper, {
				Lifetime = 0.35, MinLength = 0.05, LightEmission = 1,
				Color = { { 0, LUNAR }, { 1, EMBER } }, Transparency = { { 0, 0.45 }, { 1, 1 } },
			})
		end
	end
	local flare = fx:emitter("Totality", eclipse, 0, {
		Texture = "spark", Color = Color3.fromRGB(255, 220, 180), Lifetime = 0.6, Speed = 0, Rotation = { 0, 45 },
		Size = { { 0, 1 * s }, { 0.3, 4.6 * s }, { 1, 0 } }, Transparency = { { 0, 0.15 }, { 1, 1 } },
		LightEmission = 1, ZOffset = -0.5, LockedToPart = true,
	})
	fx:light("LunarLight", eclipse, Color3.fromRGB(255, 196, 150), 9 * s, 0.9)

	local lastFlare = -math.huge
	local controller = {}
	function controller.update(t: number)
		local cycle = (t + fx.phase) % TOTALITY_PERIOD
		local build = cycle / TOTALITY_PERIOD
		corona.Brightness = 1 + 1.2 * build ^ 3
		if cycle < 0.1 and t - lastFlare > 1 then
			lastFlare = t
			fx:burst(flare, 1)
		end
		fx:setLight(1, 0.7 + 0.5 * build ^ 3 + 1 * math.exp(-(t - lastFlare) * 3))
	end
	return controller
end
