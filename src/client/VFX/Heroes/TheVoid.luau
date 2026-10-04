-- THE VOID: a wound in the air that something keeps trying to close.
-- Primary: the depth inside the empty aperture. A dark glass lens shaped to
--          the aperture (desktop Glass refracts what is behind it) over a
--          recessed slit of absence that is drawn narrow, then tears open.
-- Secondary: cold fragments creep down the inner edges while it draws; an
--            elongated suction converges on the slit.
-- Detail: shard glints while it strains; low mist on the sill.
-- Event: the release - one cold edge flash, dark shards spat at the viewer,
--        the slit snapping wide and a cold back light swelling, then settling.
-- Every beat reads Motion.voidPull on the act clock, so it lands with the
-- bones. Nothing circular surrounds the centre, and the centre stays dark.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Motion = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CurseMotionMath"))

local SLATE = Color3.fromRGB(87, 99, 117)
local SILVER = Color3.fromRGB(217, 230, 240)
local COLD = Color3.fromRGB(221, 232, 245)
local OBSIDIAN = Color3.fromRGB(10, 13, 19)
local INDIGO = Color3.fromRGB(40, 34, 70) -- only ever inside the depth
local BACKLIGHT = Color3.fromRGB(200, 214, 255)
-- The 'shard' texture bakes a violet rim. This tint maps its body to
-- obsidian, its facet to slate and its rim to a cold grey.
local SHARD_TINT = Color3.fromRGB(119, 251, 130)

-- Live rig space (root studs at scale 1). The authored front with the silver
-- edges is -Z: the rig source puts the arc bones 0.1 behind the shards and the
-- import has them at +Z. The viewer side is FRONT * Z; flip FRONT to mirror
-- every depth cue. The aperture is about 5.9 x 8.2 studs.
local FRONT = -1
local APERTURE = Vector3.new(0.37, 0.58, 0.15)
local function toward(depth: number): Vector3
	return Vector3.new(0, 0, FRONT * depth)
end
-- Inner edges from each fractured top tip down to the sill, on the front lip.
local LIP = APERTURE.Z + FRONT * 0.32
local function edge(points)
	local list = {}
	for _, p in points do table.insert(list, { point = Vector3.new(p[1], p[2], LIP), bone = p[3] }) end
	return list
end
local EDGES = {
	edge({ { 1.35, 4.51, "ArcL" }, { 2.6, 3.19, "ArcL" }, { 3.3, 1.25, "ArcL" }, { 3.06, -1.22, "ArcL" },
		{ 2.02, -3.49, "ArcL" }, { 0.95, -4.03, "ArcBase" }, { 0.35, -3.72, "ArcBase" } }),
	edge({ { -0.3, 4.8, "ArcR" }, { -1.92, 3.43, "ArcR" }, { -2.56, 1.73, "ArcR" }, { -2.12, -0.68, "ArcR" },
		{ -1.15, -2.85, "ArcR" }, { -0.31, -3.48, "ArcBase" }, { 0.35, -3.72, "ArcBase" } }),
}
-- Glints run top first, the order the act draws the shards in.
local GLINTS = { { 4.0, "Shard1" }, { 4.35, "Shard2" }, { 4.7, "Shard0" }, { 5.05, "Shard3" }, { 5.4, "Shard4" } }
local FLASH_POINTS = 16

return function(fx)
	local s = fx.scale
	local beats = Motion.VoidBeats

	-- The depth: lens over the aperture, slit of absence recessed behind it.
	-- The slit stays on low quality (opaque, cheap); the Glass lens does not.
	local lensAt = fx:attach("Lens", APERTURE * s, "Root")
	local lens = fx:solid("Lens", lensAt, Vector3.new(5.5, 7.9, 0.45) * s, {
		Material = Enum.Material.Glass, Color = INDIGO, Transparency = 0.42, Reflectance = 0.04,
	})
	local slitAt = fx:attach("Slit", (APERTURE + Vector3.new(0, -0.1, 0) - toward(0.5)) * s, "Root")
	local slit = fx:solid("Slit", slitAt, Vector3.new(2.4, 7, 0.12) * s, {
		Material = Enum.Material.Neon, Color = OBSIDIAN, Transparency = 0,
	}, true)

	-- Suction: a thin elliptical rim, turned so the volume's +Y faces the
	-- viewer axis; streaks start on the outer band and converge on the slit.
	local flowAt = fx:attach("Flow", (APERTURE + toward(0.35)) * s, "Root", CFrame.Angles(math.pi / 2, 0, 0))
	local flowVolume = fx:volume("Flow", Vector3.new(5, 0.2, 7.4) * s, flowAt)
	local suction = fx:emitter("Suction", flowVolume, 14, {
		Texture = "streak", Shape = Enum.ParticleEmitterShape.Disc,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume, ShapePartial = 0.8,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward, EmissionDirection = Enum.NormalId.Top,
		Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = { { 0, 1.2 }, { 1, 2.4 } },
		Color = { { 0, SILVER }, { 0.55, SLATE }, { 1, INDIGO } },
		Size = { { 0, 0.05 * s }, { 0.35, 0.13 * s }, { 1, 0.02 * s } },
		Transparency = { { 0, 1 }, { 0.3, 0.4 }, { 1, 1 } },
		Speed = { 1.4 * s, 1.9 * s }, Drag = -0.8, Lifetime = { 0.8, 1 },
		LightEmission = 0.8, LockedToPart = true, ZOffset = 0.3,
	})
	-- A faint indigo falloff over the depth, tall and soft (never a disc).
	fx:emitter("Depth", flowAt, 0.5, {
		Texture = "glow_soft", Color = INDIGO, Size = 6.2 * s, Squash = 1.1, Lifetime = 4, Speed = 0,
		Transparency = { { 0, 1 }, { 0.3, 0.84 }, { 0.7, 0.84 }, { 1, 1 } },
		LightEmission = 0, LockedToPart = true, ZOffset = -0.4,
	})

	-- Edge fragments: one traveller per side along the posed inner edge.
	local travellers = {}
	for index, path in EDGES do
		local at = fx:attach("Edge" .. index, path[1].point * s)
		local wake = fx:emitter("Edge" .. index, at, 30, {
			Texture = "mote", Color = { { 0, COLD }, { 1, SLATE } }, Lifetime = { 0.35, 0.55 },
			Speed = { 0.05 * s, 0.25 * s }, SpreadAngle = Vector2.new(180, 180),
			Size = { { 0, 0.32 * s }, { 1, 0 } }, Transparency = { { 0, 0.15 }, { 1, 1 } },
			LightEmission = 1, ZOffset = 0.6,
		})
		table.insert(travellers, { at = at, wake = wake, path = path, offset = index * 2.1 })
	end

	local glintAt = fx:attach("Glint", Vector3.zero)
	local glint = fx:emitter("Glint", glintAt, 0, {
		Texture = "spark", Color = COLD, Lifetime = 0.35, Speed = 0, Rotation = { 0, 90 },
		Size = { { 0, 0 }, { 0.35, 1 * s }, { 1, 0 } }, LightEmission = 1, ZOffset = 1,
	})
	-- Dark shards spat out of the slit toward the viewer.
	local spit = fx:emitter("Spit", slit.part, 0, {
		Texture = "shard", Color = SHARD_TINT, Shape = Enum.ParticleEmitterShape.Box,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		EmissionDirection = if FRONT < 0 then Enum.NormalId.Front else Enum.NormalId.Back,
		SpreadAngle = Vector2.new(35, 50), Speed = { 5 * s, 8 * s }, Drag = 1.8,
		Acceleration = Vector3.new(0, -2.5, 0) * s, Lifetime = { 0.9, 1.3 },
		Size = { { 0, 0.2 * s }, { 0.12, 0.5 * s }, { 0.8, 0.42 * s }, { 1, 0 } },
		Rotation = { 0, 360 }, RotSpeed = { -240, 240 },
		Transparency = { { 0, 0 }, { 0.8, 0 }, { 1, 1 } }, LightEmission = 0, ZOffset = 0.5,
	})
	local sillAt = fx:at("Sill", "ArcBase", Vector3.new(0.15, 0.4, 0) + toward(0.15))
	local sillVolume = fx:volume("Sill", Vector3.new(2.6, 0.2, 0.7) * s, sillAt)
	local sill = fx:emitter("Sill", sillVolume, 1.2, {
		Texture = "wisp", Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		EmissionDirection = Enum.NormalId.Top, Speed = { 0.08 * s, 0.2 * s }, Drag = 0.5, Lifetime = { 3, 4 },
		Acceleration = Vector3.new(0, 0.04, 0) * s, Size = { { 0, 0.8 * s }, { 0.5, 1.6 * s }, { 1, 2 * s } },
		Color = { { 0, SLATE }, { 1, Color3.fromRGB(150, 165, 185) } }, Rotation = { 0, 360 }, RotSpeed = { -8, 8 },
		Transparency = { { 0, 1 }, { 0.35, 0.82 }, { 1, 1 } }, LightEmission = 0.15, LightInfluence = 0.6, ZOffset = 0.1,
	})
	-- One cold back light behind the frame rims the inner edges.
	local backAt = fx:attach("Back", (APERTURE - toward(1.3)) * s, "Root")
	fx:light("Backlight", backAt, BACKLIGHT, 9 * s, 1.2)

	local deltas = {}
	local function edgePoint(path, u: number): Vector3
		local f = math.clamp(u, 0, 1) * (#path - 1)
		local i = math.min(#path - 1, math.floor(f) + 1)
		local a, b = path[i], path[i + 1]
		return (deltas[a.bone] * (a.point * s)):Lerp(deltas[b.bone] * (b.point * s), f - (i - 1))
	end
	local function pose()
		deltas.ArcL, deltas.ArcR, deltas.ArcBase = fx:delta("ArcL"), fx:delta("ArcR"), fx:delta("ArcBase")
	end
	-- Closing speed of the wound: positive only while it is drawn shut.
	local function closing(at: number): number
		return math.clamp((Motion.voidPull(at) - Motion.voidPull(at - 0.1)) * 13, 0, 1)
	end

	local lastPhase, lastAt
	local controller = {}
	function controller.update()
		local at = fx:actTime()
		local d, release, tension, phase = Motion.voidPull(at)
		local shown = fx.root.Transparency < 1
		local flow = if phase < beats.release then closing(at) else 0
		local on = if shown then 1 else 0
		fx:setRate(suction, on * (0.12 + 0.88 * flow + 0.25 * tension) * (1 - release))
		for _, item in travellers do fx:setRate(item.wake, on * (0.18 + 0.82 * flow) * (1 - release)) end
		fx:setRate(sill, on * (0.6 + 0.4 * math.max(0, d)))
		fx:setLight(1, on * (0.45 - 0.25 * math.clamp(d, 0, 1) + 2.2 * release))
		-- Beats crossed since the last tick; a gap (culled, inactive) skips them.
		local fresh = lastAt == nil or at - lastAt > 0.5 or at < lastAt
		local from = lastPhase
		lastPhase, lastAt = phase, at
		if fresh or not shown or not fx.active then return end
		local function crossed(beat: number): boolean
			if phase >= from then return from < beat and beat <= phase end
			return beat > from or beat <= phase
		end
		for _, item in GLINTS do
			if crossed(item[1]) then
				local p = fx:posed(item[2])
				if p then glintAt.Position = p + toward(0.75) * s glint:Emit(1) end
			end
		end
		if crossed(beats.release) then
			fx:burst(spit, 8)
			fx:burst(sill, 2)
			-- One cold flash runs the whole inner edge as the wound tears open.
			pose()
			for _, item in travellers do
				for k = 0, FLASH_POINTS do
					item.at.Position = edgePoint(item.path, k / FLASH_POINTS)
					item.wake:Emit(2)
				end
			end
		end
	end
	function controller.frame()
		local at = fx:actTime()
		local d, release = Motion.voidPull(at)
		local drawn = math.clamp(d, 0, 1)
		-- The slit is drawn narrow, snaps past rest when it tears and settles;
		-- the glass darkens while drawn and clears as the depth widens.
		slit.mesh.Scale = Vector3.new(1 - 0.45 * d + 0.25 * release, 1 - 0.05 * d, 1)
		lens.mesh.Scale = Vector3.new(1 - 0.06 * drawn, 1, 1)
		lens.transparency = 0.42 - 0.14 * drawn + 0.18 * release
		-- Travellers idle near the top tips, then are drawn down the edges to
		-- the sill as the wound closes, easing slightly in toward the slit.
		pose()
		for _, item in travellers do
			local rest = 0.12 + 0.1 * math.sin(at * 0.6 + item.offset)
			local p = edgePoint(item.path, rest + (1 - rest) * drawn)
			item.at.Position = p:Lerp(Vector3.new(APERTURE.X * s, p.Y, p.Z), 0.12 * drawn)
		end
	end
	return controller
end
