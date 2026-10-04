-- THE VOID: a wound in the air that something keeps trying to close.
-- Primary: the absence. A jagged tear of flat black runs the rift's own axis,
--          from the notch between the fractured tips down to the sill, in
--          three tilted cuts inside a thin sheath of dark glass (desktop Glass
--          refracts what is behind it). Most of the aperture stays empty.
-- Secondary: cold fragments creep down the inner edges while it draws; air
--            peels off both inner rims and is pulled across into the tear.
-- Detail: shard glints while it strains; low mist on the sill.
-- Event: the release - the tear rips open from the sill up, a cold flash runs
--        back up both edges, dark shards are spat at the viewer and a cold back
--        light swells, then everything settles back to stillness.
-- Every beat reads Motion.voidPull on the act clock, so it lands with the
-- bones. It reads from both sides: the tear sits on its glass's mid-plane,
-- and the rim travellers, suction, mist, glints, spit and back light are
-- placed every frame by the side the camera is on (a carried Curse is seen
-- from behind, the procession from the side). Nothing circular surrounds the
-- centre, and the centre stays dark.
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

-- Live rig space (root studs at scale 1). The aperture (about 5.9 x 8.2) is
-- centred near APERTURE; MID is its mid-plane. The authored front with the
-- silver edges is -Z, the side assumed until the camera is known.
local MID = 0.15
local APERTURE = Vector3.new(0.37, 0.58, MID)
local FRONT = -1
-- How far each cue sits toward the camera from the mid-plane: the inner lip
-- of the arcs, the suction plane and spit/mist (ahead of the glass, whose
-- faces are 0.25 off the mid-plane), glints off the shards, and the back light
-- on the far side.
local LIP, AHEAD, GLINT_AHEAD, BEHIND = 0.32, 0.45, 0.75, 1.3

-- The tear: a polyline from the notch between the fractured tips down to the
-- sill, kinked so it reads as a cut, never as a centred pupil. Each cut is a
-- thin ellipsoid; inner joints overlap so the three read as one tear.
local TEAR = { Vector3.new(0.56, 4.5, MID), Vector3.new(0.02, 1.62, MID), Vector3.new(0.82, -1.02, MID), Vector3.new(0.36, -3.74, MID) }
local TEAR_WIDTH = { 0.5, 0.8, 0.55 }
local GLASS_WIDTH = { 1.5, 2, 1.6 }
local TEAR_LAG = { 0.1, 0.05, 0 } -- it rips open from the sill up
local JOINT = 0.45

-- Inner edges from each fractured top tip down to the sill, on the mid-plane.
local function edge(points)
	local list = {}
	for _, p in points do
		table.insert(list, { point = Vector3.new(p[1], p[2], MID), bone = p[3] })
	end
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

-- Rotation about Z that turns local +Y onto `axis` (in the XY plane).
local function tilt(axis: Vector3): CFrame
	return CFrame.Angles(0, 0, math.atan2(-axis.X, axis.Y))
end

-- X of the tear at height y (rig units), for easing things toward it.
local function tearX(y: number): number
	for i = 1, #TEAR - 1 do
		local a, b = TEAR[i], TEAR[i + 1]
		if y >= b.Y or i == #TEAR - 1 then
			return a.X + (b.X - a.X) * math.clamp((y - a.Y) / (b.Y - a.Y), 0, 1)
		end
	end
	return TEAR[1].X
end

return function(fx)
	local s = fx.scale
	local beats = Motion.VoidBeats

	-- The absence and its glass, both symmetric about the mid-plane so either
	-- side sees glass, then absence. The black cuts stay on low quality
	-- (opaque, cheap); the Glass sheath does not.
	local segments = {}
	for i = 1, #TEAR - 1 do
		local top, bottom = TEAR[i], TEAR[i + 1]
		local axis = (top - bottom).Unit
		local upper = if i == 1 then top else top + axis * JOINT
		local lower = if i == #TEAR - 1 then bottom else bottom - axis * JOINT
		local length = (upper - lower).Magnitude
		local at = fx:attach("Tear" .. i, (upper + lower) / 2 * s, "Root", tilt(axis))
		local cut = fx:solid("Tear" .. i, at, Vector3.new(TEAR_WIDTH[i], length, 0.12) * s, {
			Material = Enum.Material.Neon, Color = OBSIDIAN, Transparency = 0,
		}, true)
		local glass = fx:solid("Glass" .. i, at, Vector3.new(GLASS_WIDTH[i], length, 0.5) * s, {
			Material = Enum.Material.Glass, Color = INDIGO, Transparency = 0.55, Reflectance = 0.04,
		})
		table.insert(segments, { cut = cut, glass = glass, lag = TEAR_LAG[i] })
	end

	-- Suction: one thin band along each inner rim (bound to its arc), so the
	-- streaks peel off the edge and fly across into the tear. A band's local X
	-- stays close to root X, so the +X rim emits Left and the -X rim Right.
	local function rim(name: string, bone: string, top: Vector3, bottom: Vector3, outward: number, inward: Enum.NormalId)
		local axis = (top - bottom).Unit
		local home = (top + bottom) / 2 + Vector3.new(outward, 0, 0)
		local turn = tilt(axis)
		local at = fx:attach(name, home * s, bone, turn)
		local band = fx:volume(name, Vector3.new(0.4, (top - bottom).Magnitude + 0.6, 0.1) * s, at)
		local emitter = fx:emitter(name, band, 8, {
			Texture = "streak", Shape = Enum.ParticleEmitterShape.Box,
			ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume, EmissionDirection = inward,
			SpreadAngle = Vector2.new(8, 8), Orientation = Enum.ParticleOrientation.VelocityParallel,
			Squash = { { 0, 1.2 }, { 1, 2.4 } }, Color = { { 0, SILVER }, { 0.55, SLATE }, { 1, INDIGO } },
			Size = { { 0, 0.04 * s }, { 0.35, 0.12 * s }, { 1, 0.02 * s } },
			Transparency = { { 0, 1 }, { 0.25, 0.45 }, { 0.8, 0.65 }, { 1, 1 } },
			Speed = { 1.6 * s, 2.1 * s }, Drag = -0.8, Lifetime = { 0.85, 1.05 },
			LightEmission = 0.8, LockedToPart = true, ZOffset = 0.3,
		})
		return { at = at, home = home, turn = turn, emitter = emitter }
	end
	local rims = {
		rim("RimL", "ArcL", Vector3.new(2.6, 3.19, MID), Vector3.new(3.06, -1.22, MID), 0.12, Enum.NormalId.Left),
		rim("RimR", "ArcR", Vector3.new(-1.92, 3.43, MID), Vector3.new(-2.12, -0.68, MID), -0.12, Enum.NormalId.Right),
	}

	-- Edge fragments: one traveller per side along the posed inner edge. Its
	-- motes are locked to it, so the trace stays on the frame while it moves.
	local travellers = {}
	for index, path in EDGES do
		local at = fx:attach("Edge" .. index, path[1].point * s)
		local wake = fx:emitter("Edge" .. index, at, 30, {
			Texture = "mote", Color = { { 0, COLD }, { 1, SLATE } }, Lifetime = { 0.25, 0.4 },
			Speed = { 0.05 * s, 0.3 * s }, SpreadAngle = Vector2.new(180, 180),
			Size = { { 0, 0.32 * s }, { 1, 0 } }, Transparency = { { 0, 0.15 }, { 1, 1 } },
			LightEmission = 1, LockedToPart = true, ZOffset = 0.6,
		})
		table.insert(travellers, { at = at, wake = wake, path = path, offset = index * 2.1 })
	end

	-- Glints are 0.35 s apart and live 0.28 s, so moving the attachment for the
	-- next one never drags a live (locked) glint with it.
	local glintAt = fx:attach("Glint", Vector3.zero)
	local glint = fx:emitter("Glint", glintAt, 0, {
		Texture = "spark", Color = COLD, Lifetime = 0.28, Speed = 0, Rotation = { 0, 90 },
		Size = { { 0, 0 }, { 0.35, 1 * s }, { 1, 0 } }, LightEmission = 1, LockedToPart = true, ZOffset = 1,
	})
	-- Dark shards spat out of the tear toward the camera, from a band just
	-- ahead of the glass on the camera's side (free particles: they are thrown).
	local spitHome = Vector3.new(0.42, 0.26, MID)
	local spitAt = fx:attach("Spit", spitHome * s, "Root")
	local spitVolume = fx:volume("Spit", Vector3.new(1, 7, 0.1) * s, spitAt)
	local spit = fx:emitter("Spit", spitVolume, 0, {
		Texture = "shard", Color = SHARD_TINT, Shape = Enum.ParticleEmitterShape.Box,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume, EmissionDirection = Enum.NormalId.Front,
		SpreadAngle = Vector2.new(35, 50), Speed = { 5 * s, 8 * s }, Drag = 1.8,
		Acceleration = Vector3.new(0, -2.5, 0) * s, Lifetime = { 0.9, 1.3 },
		Size = { { 0, 0.2 * s }, { 0.12, 0.5 * s }, { 0.8, 0.42 * s }, { 1, 0 } },
		Rotation = { 0, 360 }, RotSpeed = { -240, 240 },
		Transparency = { { 0, 0 }, { 0.8, 0 }, { 1, 1 } }, LightEmission = 0, ZOffset = 0.5,
	})
	local sillAt = fx:at("Sill", "ArcBase", Vector3.new(0.15, 0.4, 0))
	local sillHome = sillAt.CFrame
	local sillVolume = fx:volume("Sill", Vector3.new(2.6, 0.2, 0.3) * s, sillAt)
	local sill = fx:emitter("Sill", sillVolume, 1.2, {
		Texture = "wisp", Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		EmissionDirection = Enum.NormalId.Top, Speed = { 0.08 * s, 0.2 * s }, Drag = 0.5, Lifetime = { 3, 4 },
		Acceleration = Vector3.new(0, 0.04, 0) * s, Size = { { 0, 0.8 * s }, { 0.5, 1.6 * s }, { 1, 2 * s } },
		Color = { { 0, SLATE }, { 1, Color3.fromRGB(150, 165, 185) } }, Rotation = { 0, 360 }, RotSpeed = { -8, 8 },
		Transparency = { { 0, 1 }, { 0.35, 0.82 }, { 1, 1 } }, LightEmission = 0.15, LightInfluence = 0.6,
		LockedToPart = true, ZOffset = 0.1,
	})
	-- One cold back light on the far side of the frame rims the inner edges.
	local backAt = fx:attach("Back", (APERTURE - Vector3.new(0, 0, FRONT * BEHIND)) * s, "Root")
	fx:light("Backlight", backAt, BACKLIGHT, 9 * s, 1.2)

	-- Nothing emits before the first update has read the reveal.
	for _, item in rims do
		fx:setRate(item.emitter, 0)
	end
	for _, item in travellers do
		fx:setRate(item.wake, 0)
	end
	fx:setRate(sill, 0)

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
	-- Which side of the rift the camera is on: -1 front (-Z), +1 behind, easing
	-- through 0 when it is seen edge-on so nothing jumps as a viewer walks past.
	local side = FRONT
	local function cameraSide(): number
		local camera = workspace.CurrentCamera
		if not camera then
			return side
		end
		local eye = fx.root.CFrame:PointToObjectSpace(camera.CFrame.Position)
		return math.clamp(eye.Z / math.max(1, math.sqrt(eye.X * eye.X + eye.Z * eye.Z)) * 3, -1, 1)
	end

	local lastPhase, lastAt
	local controller = {}
	function controller.update()
		local at = fx:actTime()
		local d, release, tension, phase = Motion.voidPull(at)
		local shown = fx.root.Transparency < 1
		local on = if shown then 1 else 0
		local opening = math.max(0, -d)
		local flow = if phase < beats.release then closing(at) else 0
		-- It holds its breath while it leans out and while it rips open.
		local inhale = (0.12 + 0.88 * flow + 0.25 * tension) * (1 - release) * math.max(0, 1 - 3 * opening)
		for _, item in rims do
			fx:setRate(item.emitter, on * inhale)
		end
		-- The travellers brighten as they pull back up for the lean, and flare as
		-- they race back up the edges on the release.
		local trace = (0.18 + 0.82 * flow + 1.2 * opening) * (1 - release) + 2.5 * release
		for _, item in travellers do
			fx:setRate(item.wake, on * trace)
		end
		fx:setRate(sill, on * (0.6 + 0.4 * math.max(0, d)))
		fx:setLight(1, on * (0.45 - 0.25 * math.clamp(d, 0, 1) + 2.2 * release))
		-- Beats crossed since the last tick; a gap (culled, inactive) skips them.
		local fresh = lastAt == nil or at - lastAt > 0.5 or at < lastAt
		local from = lastPhase
		lastPhase, lastAt = phase, at
		if fresh or not shown or not fx.active then
			return
		end
		local function crossed(beat: number): boolean
			if phase >= from then
				return from < beat and beat <= phase
			end
			return beat > from or beat <= phase
		end
		for _, item in GLINTS do
			if crossed(item[1]) then
				local p = fx:posed(item[2])
				if p then
					glintAt.Position = p + Vector3.new(0, 0, side * GLINT_AHEAD * s)
					fx:burst(glint, 1)
				end
			end
		end
		if crossed(beats.release) then
			spit.EmissionDirection = if side > 0 then Enum.NormalId.Back else Enum.NormalId.Front
			fx:burst(spit, 8)
			fx:burst(sill, 2)
			-- The cold flash starts at the sill, where the tear rips from, and
			-- rides both travellers back up the edges.
			for _, item in travellers do
				fx:burst(item.wake, 8)
			end
		end
	end
	function controller.frame()
		local at = fx:actTime()
		local d = Motion.voidPull(at)
		local drawn = math.clamp(d, 0, 1)
		local opening = math.max(0, -d)
		-- Each cut widens 15-20% as the rift leans out, is drawn narrow, then
		-- snaps open past rest (the lowest first) and settles; its glass
		-- darkens while drawn and clears as the depth opens.
		for _, item in segments do
			local ds, rs = Motion.voidPull(at - item.lag)
			local dn, op = math.clamp(ds, 0, 1), math.max(0, -ds)
			item.cut.mesh.Scale = Vector3.new(1 - 0.45 * dn + 0.5 * op + 0.9 * rs, 1 - 0.04 * dn + 0.06 * rs, 1)
			item.glass.mesh.Scale = Vector3.new(1 - 0.08 * dn + 0.12 * op + 0.2 * rs, 1, 1)
			item.glass.transparency = 0.55 - 0.12 * dn + 0.15 * rs
		end
		-- Every depth cue goes to the camera's side; the light to the far side.
		side = cameraSide()
		for _, item in rims do
			fx:rebase(item.at, CFrame.new((item.home + Vector3.new(0, 0, side * AHEAD)) * s) * item.turn)
		end
		fx:rebase(spitAt, CFrame.new((spitHome + Vector3.new(0, 0, side * AHEAD)) * s))
		fx:rebase(sillAt, sillHome + Vector3.new(0, 0, side * AHEAD * s))
		fx:rebase(backAt, CFrame.new((APERTURE - Vector3.new(0, 0, side * BEHIND)) * s))
		-- Travellers idle near the top tips, pull back up to them as it leans
		-- out, are drawn down the edges to the sill as the wound closes (easing
		-- slightly in toward the tear) and race back up when it rips open.
		pose()
		local lip = Vector3.new(0, 0, side * LIP * s)
		for _, item in travellers do
			local rest = 0.12 + 0.1 * math.sin(at * 0.6 + item.offset)
			local p = edgePoint(item.path, rest * math.max(0, 1 - opening / 0.3) + (1 - rest) * drawn)
			item.at.Position = p:Lerp(Vector3.new(tearX(p.Y / s) * s, p.Y, p.Z), 0.12 * drawn) + lip
		end
	end
	return controller
end
