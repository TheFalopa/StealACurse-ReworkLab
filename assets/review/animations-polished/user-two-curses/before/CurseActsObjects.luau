-- Acting for the actual weighted mechanisms of eighteen Curses.
-- Only the shared animation controller calls these acts. They never move the
-- gameplay anchor, create connections, touch ownership, or replace VFX.
return function(H)
	local pose = H.pose
	local sin, pi = math.sin, math.pi
	local tau = pi * 2
	local zero = Vector3.zero
	local function ease(v)
		v = math.clamp(v, 0, 1)
		return v * v * (3 - 2 * v)
	end
	local function hold(t, period, start, rise, stay, fall)
		local u = (t - start) % period
		if u < rise then return ease(u / rise) end
		if u < rise + stay then return 1 end
		if u < rise + stay + fall then return 1 - ease((u - rise - stay) / fall) end
		return 0
	end
	local function accent(e)
		local age = e.stateAge or math.huge
		if age < 0 or age > 0.65 then return 0 end
		return sin(pi * age / 0.65) ^ 2
	end
	local function carried(e)
		return if e.state == "CARRYING" then 1 else 0
	end
	-- Effective pivot corrections preserve the imported bind/rest skeleton.
	-- offset is measured in authored studs at six studs of model height.
	local function around(e, name, x, y, z, offset, position)
		local rotation = CFrame.Angles(x % tau, y % tau, z % tau)
		pose(e, name, x, y, z, offset - rotation:VectorToWorldSpace(offset) + (position or zero))
	end
	local strideMirror = { stride = 1.85 }
	local strideKey = { stride = 2.1 }
	local strideBook = { stride = 1.7 }
	local strideLantern = { stride = 2.25 }
	local strideGramophone = { stride = 2.45 }
	local strideQuill = { stride = 2.45 }
	-- Long contact, short recovery. Phase follows distance, so feet stop when
	-- the Curse stops. Knee flex is restricted to the recovery stroke.
	local function step(q, duty)
		local u = (q / tau) % 1
		if u < duty then
			return 1 - 2 * u / duty, 0
		end
		local swing = (u - duty) / (1 - duty)
		return -1 + 2 * ease(swing), sin(pi * swing) ^ 2
	end
	local function foot(e, index, q, g, amplitude, bend, duty, pivot)
		local sweep, lift = step(q, duty or 0.64)
		local hip = amplitude * sweep * g
		if pivot then
			around(e, "Leg" .. index, hip, 0, 0, pivot)
		else
			pose(e, "Leg" .. index, hip, 0, 0)
		end
		pose(e, "Knee" .. index, -(bend * lift + 0.055 * (1 - lift)) * g, 0, 0)
		return lift
	end
	local acts = {}

	acts.haunted_mirror = function(e, t, g, idle)
		local q = H.gait(e, strideMirror)
		local a = foot(e, 0, q, g, 0.39, 0.52, 0.65)
		local b = foot(e, 1, q + pi, g, 0.39, 0.52, 0.65)
		local emerge = hold(t, 6.9, 1.0, 0.75, 0.7, 1.1)
		local glance = hold(t, 5.4, 0.3, 0.35, 0.65, 0.7)
		pose(e, "Root", 0, 0, 0.022 * sin(q) * g, Vector3.new(0, (0.04 + 0.055 * (a + b)) * g, 0))
		pose(e, "Reflection", 0.035 * sin(t * 1.3), 0, 0.05 * sin(t * 0.9), Vector3.new(0, 0.20 * emerge, -0.10 * emerge))
		pose(e, "GhostHead", -0.09 * emerge, 0.25 * glance - 0.10 * hold(t, 5.4, 2.8, 0.4, 0.5, 0.7), -0.18 * emerge + 0.05 * sin(t * 1.1))
	end

	acts.crying_mask = function(e, t, g, idle)
		local sob = hold(t, 5.8, 0.8, 0.65, 0.4, 1.1)
		local shiver = sin(t * 18) * hold(t, 5.8, 1.55, 0.08, 0.22, 0.28)
		local trail = 0.11 + 0.12 * g + 0.035 * carried(e)
		pose(e, "Root", 0, 0, 0, Vector3.new(0, 0.30 + 0.08 * sob, 0))
		pose(e, "Sorrow", 0.18 * sob + 0.03 * g, 0.09 * sin(t * 0.65), 0.045 * shiver - 0.025 * sob)
		pose(e, "TieL", 0.11 * g + 0.055 * sin(t * 2.1), 0.04 * sin(t * 1.4), -trail + 0.085 * sin(t * 2.4 - 0.5))
		pose(e, "TieR", 0.11 * g + 0.055 * sin(t * 2.1 - 0.55), -0.04 * sin(t * 1.4), trail + 0.065 * sin(t * 2.7 + 0.45))
	end

	acts.candle_wisp = function(e, t, g, idle)
		local shelter = hold(t, 4.9, 0.6, 0.35, 0.6, 0.6)
		local beckon = hold(t, 7.2, 3.1, 0.4, 0.35, 0.9) * idle
		local flame = 0.18 * sin(t * 5.1) + 0.09 * sin(t * 8.7)
		pose(e, "Root", 0, 0, 0, Vector3.new(0, 0.09 * g + 0.025 * (1 + sin(t * 2)), 0))
		pose(e, "Flame", -0.13 * g + 0.075 * sin(t * 3.3), 0.12 * sin(t * 2.7), flame, Vector3.new(0, 0.07 * shelter + 0.05 * accent(e), 0))
		pose(e, "HandL", -0.16 * shelter, 0.07 * beckon, 0.30 * shelter + 0.46 * beckon + 0.08 * g)
		pose(e, "HandR", -0.16 * shelter, -0.08 * shelter, -0.30 * shelter - 0.14 * hold(t, 4.9, 2.7, 0.3, 0.25, 0.65))
	end

	acts.grave_key = function(e, t, g, idle)
		local q = H.gait(e, strideKey)
		local a = foot(e, 0, q, g, 0.47, 0.63, 0.63, Vector3.new(-0.33, 0.10, 0))
		local b = foot(e, 1, q + pi + 0.17, g, 0.53, 0.57, 0.66, Vector3.new(0.70, 0.13, 0))
		local tryLock = hold(t, 6.3, 1.2, 0.4, 0.45, 0.65) * idle
		pose(e, "Root", 0, 0.15 * tryLock, 0.05 * sin(q + 0.15) * g, Vector3.new(0, 0.065 * g + 0.06 * (a + b) * g, 0))
		pose(e, "Scarf", 0.23 * g + 0.06 * sin(t * 2.6), 0.09 * sin(t * 3.2), 0.26 * sin(t * 3.8 - 0.6) + 0.08 * accent(e))
	end

	acts.mourning_ribbon = function(e, t, g, idle)
		local tighten = hold(t, 5.6, 0.8, 0.65, 0.25, 1.0)
		local release = hold(t, 5.6, 3.2, 0.22, 0.25, 0.75)
		pose(e, "Root", 0, 0, 0, Vector3.new(0, 0.34 + 0.10 * g + 0.035 * tighten, 0))
		pose(e, "LoopL", 0.07 * release, 0.27 * tighten - 0.10 * release, -0.04 * tighten)
		pose(e, "LoopR", -0.07 * release, -0.27 * tighten + 0.10 * release, 0.04 * tighten)
		pose(e, "TailL", 0.24 * g + 0.17 * sin(t * 2.2 - 0.7), 0.13 * sin(t * 1.9), -0.035 * tighten + 0.055 * sin(t * 2.4 - 1.0))
		pose(e, "TailR", 0.24 * g + 0.16 * sin(t * 2.2 - 1.1), -0.13 * sin(t * 1.9), 0.035 * tighten + 0.055 * sin(t * 2.1 + 0.3))
	end

	acts.wilted_sprout = function(e, t, g, idle)
		local revive = hold(t, 7.1, 0.7, 1.0, 0.6, 1.4)
		local flop = hold(t, 7.1, 3.45, 0.35, 0.3, 0.7)
		pose(e, "Root", 0, 0, 0, Vector3.new(0, 0.035 * g, 0))
		pose(e, "Stem", 0.045 * g, 0, 0.10 * revive - 0.035 * g)
		pose(e, "Bloom", -0.18 * revive + 0.09 * flop, 0.17 * sin(t * 0.8), 0.21 * revive - 0.12 * flop + 0.055 * accent(e))
		pose(e, "Leaf", 0.29 * flop - 0.16 * revive + 0.06 * sin(t * 2.7) * g, 0, 0.11 * sin(t * 1.35))
	end

	acts.ink_imp = function(e, t, g, idle)
		local reach = hold(t, 4.3, 0.45, 0.3, 0.35, 0.7)
		local retract = hold(t, 4.3, 2.25, 0.16, 0.14, 0.65)
		local wipe = hold(t, 6.1, 3.0, 0.45, 0.25, 0.55) * idle
		pose(e, "Root", 0, 0, 0)
		pose(e, "Ink", -0.09 * g - 0.08 * reach, 0.08 * sin(t * 1.6), 0.10 * retract, Vector3.new(0, 0.16 * reach - 0.04 * retract, 0))
		pose(e, "HandL", -0.17 * reach, 0.17 * wipe, 0.48 * reach - 0.17 * retract)
		pose(e, "HandR", -0.12 * reach, -0.14 * wipe, -0.27 * reach - 0.32 * wipe)
		pose(e, "Tail", 0.11 * sin(t * 2.2), 0.32 * sin(t * 2.7 - 0.5), 0.22 * retract - 0.13 * reach)
	end

	acts.lost_locket = function(e, t, g, idle)
		local open = hold(t, 6.8, 0.65, 0.7, 1.05, 1.2)
		local reach = hold(t, 6.8, 1.75, 0.4, 0.4, 0.9)
		local shut = hold(t, 6.8, 4.6, 0.15, 0.16, 0.65)
		pose(e, "Root", 0, 0, 0, Vector3.new(0, 0.06 * g, 0))
		pose(e, "Cover", 0, 0.44 * open - 0.12 * shut + 0.08 * carried(e), 0)
		pose(e, "Palm", -0.10 * reach, 0, 0, Vector3.new(0, 0.065 * reach, -0.18 * reach))
		for index = 0, 2 do
			local knock = hold(t, 6.8, 2.05 + index * 0.21, 0.13, 0.12, 0.3)
			pose(e, "Finger" .. index, 0.32 * knock - 0.12 * open, 0, (index - 1) * 0.07 * open)
		end
	end

	acts.ashen_book = function(e, t, g, idle)
		local q = H.gait(e, strideBook)
		local a = foot(e, 0, q, g, 0.28, 0.42, 0.59)
		local b = foot(e, 1, q + pi, g, 0.28, 0.42, 0.59)
		local read = hold(t, 5.7, 0.4, 0.55, 0.85, 0.9)
		local flick = hold(t, 2.2, 0.25, 0.12, 0.08, 0.36)
		pose(e, "Root", 0.018 * sin(q * 2) * g, 0, 0, Vector3.new(0, (0.03 + 0.07 * (a + b)) * g, 0))
		pose(e, "Cover", 0.15 * read + 0.04 * accent(e), 0, 0)
		pose(e, "PageWing", -0.07 * read, -0.055 * g, -0.32 * flick - 0.13 * read + 0.075 * sin(t * 10.5) * g)
	end

	acts.lantern_lurker = function(e, t, g, idle)
		local q = H.gait(e, strideLantern)
		-- Front left / rear right, then front right / rear left.
		local a = foot(e, 0, q, g, 0.43, 0.60, 0.67)
		local b = foot(e, 1, q + pi, g, 0.43, 0.60, 0.67)
		local c = foot(e, 2, q + pi + 0.18, g, 0.40, 0.56, 0.67)
		local d = foot(e, 3, q + 0.18, g, 0.40, 0.56, 0.67)
		local struggle = hold(t, 5.5, 1.1, 0.18, 0.25, 0.65)
		pose(e, "Root", 0.025 * sin(q * 2) * g, 0, 0.025 * sin(q) * g, Vector3.new(0, (0.09 + 0.045 * (a + b + c + d)) * g, 0))
		pose(e, "Handle", 0.085 * sin(q - 0.6) * g, 0, 0.15 * sin(t * 2.3 - 0.5) + 0.06 * struggle)
		pose(e, "Captive", 0.08 * sin(t * 7.0) * struggle, 0.19 * sin(t * 6.5) * struggle, 0.16 * sin(t * 8.1) * struggle, Vector3.new(0, 0.12 * struggle, 0))
	end

	acts.pale_guest = function(e, t, g, idle)
		local peer = hold(t, 6.2, 0.8, 0.65, 0.65, 1.0)
		local shy = hold(t, 6.2, 3.4, 0.25, 0.3, 0.85)
		pose(e, "Root", 0, 0, 0, Vector3.new(0, 0.07 * g, 0))
		pose(e, "Ghost", -0.045 * peer, 0, 0.10 * shy, Vector3.new(0, 0.07 * peer, -0.15 * peer + 0.04 * shy))
		pose(e, "Head", 0.08 * shy, 0.20 * hold(t, 6.2, 1.5, 0.3, 0.5, 0.8), -0.23 * peer + 0.10 * shy)
		pose(e, "GripL", 0.31 * peer + 0.08 * accent(e), 0, 0.035 * sin(t * 3.3))
		pose(e, "GripR", 0.25 * hold(t, 6.2, 1.0, 0.45, 0.6, 1.0), 0, -0.035 * sin(t * 3.3 - 0.4))
	end

	acts.cold_teacup = function(e, t, g, idle)
		local curl = hold(t, 4.7, 0.4, 0.7, 0.35, 1.0)
		local snap = hold(t, 4.7, 2.85, 0.2, 0.18, 0.55)
		pose(e, "Root", 0, 0, 0, Vector3.new(0, 0.04 * g, 0))
		pose(e, "Steam", -0.10 * g + 0.09 * sin(t * 1.8), 0.23 * curl, -0.17 * curl + 0.05 * sin(t * 2.2))
		pose(e, "SteamTip", 0.14 * snap, -0.29 * curl, 0.34 * curl - 0.21 * snap + 0.07 * sin(t * 3.6 - 0.4))
	end

	acts.grave_compass = function(e, t, g, idle)
		-- Search, hesitate at a false direction, then decisively point back.
		local left = hold(t, 5.9, 0.25, 0.6, 0.35, 0.65)
		local right = hold(t, 5.9, 2.05, 0.42, 0.55, 0.8)
		local tremble = hold(t, 5.9, 3.75, 0.08, 0.15, 0.3)
		pose(e, "Root", 0, 0, 0, Vector3.new(0, 0.06 * g, 0))
		pose(e, "Needle", 0, 0, 0.48 * left - 0.53 * right + 0.055 * sin(t * 22) * tremble)
		pose(e, "Lid", 0, 0.22 * hold(t, 7.3, 0.8, 0.6, 0.8, 1.0) + 0.045 * g, 0)
		-- Ring's source pivot is 1.0 stud to the left of its actual suspension.
		around(e, "Ring", 0.08 * sin(t * 1.7) * g, 0, 0.17 * sin(t * 2.15), Vector3.new(-1.35, 0.55, 0))
	end

	acts.pale_gramophone = function(e, t, g, idle)
		local q = H.gait(e, strideGramophone)
		-- Ordering in the real rig is left-front, left-rear, right-front,
		-- right-rear; preserve both diagonal supports instead of moving a side.
		local a = foot(e, 0, q, g, 0.39, 0.50, 0.67)
		local b = foot(e, 1, q + pi, g, 0.39, 0.50, 0.67)
		local c = foot(e, 2, q + pi, g, 0.39, 0.50, 0.67)
		local d = foot(e, 3, q, g, 0.39, 0.50, 0.67)
		local listen = hold(t, 5.2, 0.5, 0.55, 0.5, 1.0)
		pose(e, "Root", 0, 0, 0.018 * sin(q) * g, Vector3.new(0, (0.045 + 0.04 * (a + b + c + d)) * g, 0))
		pose(e, "Horn", -0.04 * listen, 0.15 * listen - 0.07 * hold(t, 5.2, 3.1, 0.4, 0.4, 0.8), 0.04 * sin(t * 2.6))
		-- True center of the grooved disk, measured from editable geometry.
		around(e, "Record", 0, (t * tau / 3.1) % tau, 0, Vector3.new(0.156, -0.009, 0.081))
		pose(e, "Crank", 0, 0, -(t * tau / 3.1) % tau)
	end

	acts.raven_quill = function(e, t, g, idle)
		local q = H.gait(e, strideQuill)
		local a = foot(e, 0, q, g, 0.48, 0.64, 0.61)
		local b = foot(e, 1, q + pi, g, 0.48, 0.64, 0.61)
		local write = hold(t, 5.0, 0.7, 0.32, 0.55, 0.8) * idle
		local nib = sin(t * 10.8) * hold(t, 5.0, 1.15, 0.1, 0.5, 0.2) * idle
		local ruffle = hold(t, 7.1, 4.0, 0.14, 0.16, 0.6)
		pose(e, "Root", 0, 0, 0.024 * sin(q) * g, Vector3.new(0, (0.035 + 0.07 * (a + b)) * g, 0))
		pose(e, "Nib", 0.22 * write + 0.055 * nib, 0.09 * sin(t * 1.6), 0.035 * nib)
		pose(e, "BarbsL", 0.07 * g, 0, -0.12 * ruffle - 0.055 * sin(t * 4.2) * g)
		pose(e, "BarbsR", 0.07 * g, 0, 0.16 * ruffle + 0.045 * sin(t * 4.2 - 0.35) * g)
	end

	acts.sorrow_chalice = function(e, t, g, idle)
		local lament = hold(t, 6.4, 0.6, 0.85, 0.45, 1.0)
		pose(e, "Root", 0, 0, 0, Vector3.new(0, 0.04 * g, 0))
		pose(e, "Spirit", -0.10 * lament, 0.11 * sin(t * 0.75), 0.17 * lament - 0.07 * sin(t * 1.2), Vector3.new(0, 0.12 * lament, 0))
		for index = 0, 2 do
			local drop = hold(t, 4.9, index * 1.35, 0.4, 0.1, 0.95)
			pose(e, "Drop" .. index, 0.08 * sin(t * 2.8 + index), 0, 0.07 * sin(t * 2.3 + index), Vector3.new(0, -0.28 * drop, 0))
		end
	end

	acts.thorn_reliquary = function(e, t, g, idle)
		-- The cage stays fixed; the captive strains first, its tip follows later.
		local strain = hold(t, 5.9, 0.65, 0.6, 0.55, 1.0)
		local recoil = hold(t, 5.9, 2.9, 0.15, 0.12, 0.6)
		local tip = hold(t, 5.9, 1.05, 0.45, 0.4, 0.8)
		pose(e, "Root", 0, 0, 0, Vector3.new(0, 0.025 * g, 0))
		pose(e, "Thorn", 0.07 * strain, 0.08 * sin(t * 1.4), 0.10 * strain - 0.055 * recoil)
		pose(e, "ThornTip", -0.075 * tip, -0.23 * tip + 0.11 * recoil, -0.13 * tip + 0.075 * recoil)
	end

	acts.chime_triplets = function(e, t, g, idle)
		local call = hold(t, 6.8, 0.2, 0.3, 0.1, 0.55)
		pose(e, "Root", 0, 0, 0, Vector3.new(0, 0.18 + 0.025 * g, 0))
		for index = 0, 2 do
			-- A little call and two replies, each with a different damped swing.
			local u = (t - 0.55 - index * 0.68) % 6.8
			local ring = if u < 3.3 then sin(u * (4.5 + index * 0.48)) * math.exp(-u * 0.9) * ease(u / 0.1) else 0
			local drift = 0.075 * sin(t * (1.5 + index * 0.17) - index * 0.4) * g
			-- Forward/backward keeps the wide bells apart; lateral swing is small.
			pose(e, "Bell" .. index, (0.18 + index * 0.025) * ring + drift, 0, 0.035 * call * (index - 1))
		end
	end

	return acts
end
