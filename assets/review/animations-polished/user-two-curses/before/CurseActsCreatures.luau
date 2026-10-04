-- Concept acting for sixteen actual sculpted rigs. Called by the one shared animator.
-- Contacts are measured from the authored sources in Roblox axes, normalized to height 6.
-- No gameplay frames, network messages, VFX objects, connections or private loops here.
local contact = {
	grave_hopper = {Vector3.new(2.0654826,-2.6999369,-1.4732912),Vector3.new(-2.0654826,-2.6999369,-1.4732912),Vector3.new(2.5222721,-2.7396576,0.1155418),Vector3.new(-2.5222721,-2.7396576,0.1155418)},
	hourglass_hound = {Vector3.new(3.2647164,-2.6944444,-1.3180553),Vector3.new(3.3227701,-2.6944444,1.3180553),Vector3.new(-1.0312707,-2.6944444,-1.2458332),Vector3.new(-1.1183516,-2.6944444,1.3180553)},
	nail_beetle = {Vector3.new(4.9995017,-2.8948271,-4.1444588),Vector3.new(4.9995017,-2.8948271,-2.6566699),Vector3.new(4.9995017,-2.8948271,-1.1688811),Vector3.new(-4.9836578,-2.8948271,-4.1444588),Vector3.new(-4.9836578,-2.8948271,-2.6566699),Vector3.new(-4.9836578,-2.8948271,-1.1688811)},
	coin_crawler = {Vector3.new(4.9074893,-2.5831106,-1.7696874),Vector3.new(4.9074893,-2.5831106,1.4887463),Vector3.new(-4.9074893,-2.5831106,-1.7696874),Vector3.new(-4.9074893,-2.5831106,1.4887463)},
	thimble_spider = {Vector3.new(4.8546634,-2.9379637,-2.5983429),Vector3.new(4.7483988,-2.9379637,-1.6448008),Vector3.new(4.5273046,-2.9379637,-0.6912588),Vector3.new(4.3946533,-2.9379637,0.2622832),Vector3.new(-4.8541255,-2.9379637,-2.5983429),Vector3.new(-4.7478614,-2.9379637,-1.6448008),Vector3.new(-4.5267668,-2.9379637,-0.6912588),Vector3.new(-4.3941159,-2.9379637,0.2622832)},
	anchor_crab = {Vector3.new(3.7041504,-2.9564598,-0.8054091),Vector3.new(3.8479767,-2.9564598,-0.1273712),Vector3.new(3.9918029,-2.9564598,0.5506667),Vector3.new(-2.9118552,-2.9564598,-0.8054091),Vector3.new(-3.0556815,-2.9564598,-0.1273712),Vector3.new(-3.1995077,-2.9564598,0.5506667)},
	hollow_violin = {Vector3.new(0.9031251,-2.8520744,-0.1590311),Vector3.new(-0.9031251,-2.8520744,-0.1590311)},
	clockwork_raven = {Vector3.new(0.6986296,-2.7720098,-0.4352235),Vector3.new(-0.6986296,-2.7720098,-0.4352235)},
	eclipse_stag = {Vector3.new(-0.3280140,-2.8592606,-0.6277730),Vector3.new(-0.3576434,-2.8592606,0.2611092),Vector3.new(1.4053059,-2.8592606,-0.6425878),Vector3.new(1.3016030,-2.8592606,0.2759239)},
	thorn_cathedral = {Vector3.new(1.5542774,-2.7630653,-0.7816825),Vector3.new(-1.2395831,-2.7630653,-0.7816825),Vector3.new(1.4282385,-2.7630653,0.8437979),Vector3.new(-1.4286413,-2.7630653,0.8437979)},
	endless_library = {Vector3.new(2.3122289,-2.8757401,-0.6752487),Vector3.new(1.8320886,-2.8757401,0.2989496),Vector3.new(-2.3062644,-2.8757401,-0.6752487),Vector3.new(-1.8718517,-2.8757401,0.2989496)},
}
local TAU = math.pi * 2
local zero = Vector3.zero
local diagonal = {0, .5, .5, 0}
local biped = {0, .5}
local tripod = {0, .5, 0, .5, 0, .5}
local tetrapod = {0, .5, 0, .5, .5, 0, .5, 0}
local contactCenter = {
	grave_hopper=.4, hourglass_hound=.12, nail_beetle=.15, coin_crawler=.12,
	thimble_spider=.4, anchor_crab=.12, hollow_violin=.15, clockwork_raven=.12,
	eclipse_stag=.15, thorn_cathedral=.25, endless_library=.4,
}

return function(H)
	local pose, pulse, smooth, gait = H.pose, H.pulse, H.smooth, H.gait
	local function root(e, x, y, z, p)
		pose(e, "Root", x, y, z, p)
		return CFrame.new((p or zero) * e.scale) * CFrame.Angles(x, y, z)
	end

	local function align(from, to)
		if from.Magnitude < .00001 or to.Magnitude < .00001 then return CFrame.identity end
		local a, b = from.Unit, to.Unit
		local axis = a:Cross(b)
		local d = math.clamp(a:Dot(b), -1, 1)
		if axis.Magnitude < .00001 then
			if d >= 0 then return CFrame.identity end
			axis = a:Cross(Vector3.xAxis)
			if axis.Magnitude < .00001 then axis = a:Cross(Vector3.zAxis) end
		end
		return CFrame.fromAxisAngle(axis.Unit, math.acos(d))
	end

	-- The planted interval cancels forward (-Z) travel. Swing returns the foot
	-- with a smooth rise/landing; phase is accumulated travel, never a wall-clock walk.
	local function footCycle(q, stride, duty, lift)
		local f = (q / TAU) % 1
		local reach = stride * duty
		if f < duty then return reach * (f / duty - .5), 0, f / duty end
		local s = (f - duty) / (1 - duty)
		return reach * (.5 - smooth(s)), lift * math.sin(math.pi * s) ^ 2, 1 + s
	end

	-- Solve around the actual imported rest pivots. Upper/lower rotations keep
	-- the attached hip fixed; a body lean/breath is compensated at the contacts.
	local function plant(e, id, phases, stride, duty, lift, body, g, jump)
		local q = gait(e, {stride = stride, phase = 0})
		for i, marker in contact[id] do
			local upperName, lowerName = "Leg" .. (i - 1), "Knee" .. (i - 1)
			local upperRest, lowerRest = e.rest[upperName], e.rest[lowerName]
			if upperRest and lowerRest then
				local z, y = footCycle(q + phases[i] * TAU, stride, duty, lift)
				local foot = marker * e.scale
				-- Tuck the authored forward-splayed rest contacts under their hips during
				-- locomotion, retaining room for both ends of the planted interval.
				local centerZ = (upperRest.Z - foot.Z) * contactCenter[id] * g
				local target = body:PointToObjectSpace(foot + Vector3.new(0, y * g + (jump or 0), z * g) * e.scale
					+ Vector3.new(0, 0, centerZ))
				local desired = upperRest:PointToObjectSpace(target)
				local originalUpper = lowerRest.Position
				local originalLower = lowerRest:PointToObjectSpace(upperRest:PointToObjectSpace(foot))
				local l1, l2 = originalUpper.Magnitude, originalLower.Magnitude
				if l1 > .0001 and l2 > .0001 and desired.Magnitude > .0001 then
					local d = math.clamp(desired.Magnitude, math.abs(l1 - l2) + .00001, l1 + l2 - .00001)
					local direction = desired.Unit
					local plane = originalUpper - direction * originalUpper:Dot(direction)
					if plane.Magnitude < .00001 then
						plane = Vector3.new(if upperRest.X >= 0 then 1 else -1, 0, 0)
						plane -= direction * plane:Dot(direction)
						if plane.Magnitude < .00001 then
							plane = Vector3.zAxis - direction * direction.Z
						end
					end
					local along = (l1 * l1 - l2 * l2 + d * d) / (2 * d)
					local side = math.sqrt(math.max(0, l1 * l1 - along * along))
					local nextUpper = direction * along + plane.Unit * side
					local upperTurn = align(originalUpper, nextUpper)
					local nextLower = upperTurn:VectorToObjectSpace(direction * d - nextUpper)
					local lowerTurn = align(originalLower, lowerRest.Rotation:VectorToObjectSpace(nextLower))
					local x, yy, zz = upperTurn:ToEulerAnglesXYZ()
					pose(e, upperName, x, yy, zz)
					local lx, ly, lz = lowerTurn:ToEulerAnglesXYZ()
					pose(e, lowerName, lx, ly, lz)
				end
			end
		end
		return q
	end

	local acts = {}

	acts.grave_hopper = function(e, t, g, idle)
		local q = gait(e, {stride = 2.3})
		local spring = math.max(0, math.sin(q)) ^ 2
		local startle = pulse(t, 7.8, 5.4, .62) * idle
		local body = root(e, .028 * math.sin(q) * g, 0, .014 * math.sin(t * .9) * idle,
			Vector3.new(0, -.16 * g + .12 * spring * g + .24 * startle, 0))
		plant(e, "grave_hopper", {0, 0, .5, .5}, 2.3, .52, .32, body, g, .12 * spring * g + .24 * startle)
		pose(e, "Shell", -.07 * spring * g + .12 * startle, .11 * math.sin(t * .56) * idle,
			.035 * math.sin(t * 1.1) * idle, Vector3.new(0, -.055 * spring * g, 0))
	end

	acts.hourglass_hound = function(e, t, g, idle)
		local sniff = pulse(t, 6.4, 4.2, 1.05)
		local body = root(e, 0, .018 * math.sin(t * .78) * idle, .018 * math.sin(t * 1.9),
			Vector3.new(0, -.16 * g - .035 * (1 - math.sin(t * 1.9)) * idle, 0))
		plant(e, "hourglass_hound", diagonal, 2.4, .60, .24, body, g)
		pose(e, "Head", .055 * sniff, .24 * math.sin(t * .82) * idle + .07 * math.sin(t * 2.7) * g,
			-.12 * sniff, Vector3.new(0, -.035 * sniff, 0))
		pose(e, "Tail", .06 * math.sin(t * 1.5), (.26 + .09 * g) * math.sin(t * 2.9), .04 * sniff)
	end

	acts.nail_beetle = function(e, t, g, idle)
		local q = gait(e, {stride = 2.2})
		local tick = pulse(t, 4.9, 3.3, .24)
		local body = root(e, .013 * math.sin(q * 2) * g, 0, .02 * math.sin(q) * g,
			Vector3.new(0, -.13 * g + .025 * tick * idle, 0))
		plant(e, "nail_beetle", tripod, 2.2, .68, .24, body, g)
		pose(e, "Nail", -.15 * tick, .07 * math.sin(t * .54) * idle, .045 * tick,
			Vector3.new(0, .05 * tick, 0))
	end

	acts.coin_crawler = function(e, t, g, idle)
		local peek = pulse(t, 6.7, 4.1, 1.25)
		local q = gait(e, {stride = 2})
		local body = root(e, .015 * math.sin(q * 2) * g, 0, .016 * math.sin(q) * g,
			Vector3.new(0, -.14 * g, 0))
		plant(e, "coin_crawler", diagonal, 2, .70, .20, body, g)
		pose(e, "CoinLid", -.11 * peek, 0, .028 * math.sin(t * 1.1) * idle,
			Vector3.new(0, .17 * peek, 0))
		pose(e, "Gaze", 0, .24 * math.sin(t * .77), 0,
			Vector3.new(.055 * math.sin(t * .77), .035 * peek, 0))
	end

	acts.thimble_spider = function(e, t, g, idle)
		local creep = pulse(t, 8.3, 5.5, 1.3) * idle
		local q = gait(e, {stride = 2.9})
		local body = root(e, -.018 * creep, .035 * math.sin(t * .7) * idle, .012 * math.sin(q) * g,
			Vector3.new(0, -.24 * g - .09 * creep, .055 * creep))
		plant(e, "thimble_spider", tetrapod, 2.9, .66, .25, body, g)
		pose(e, "Fangs", .30 * pulse(t, 4.1, 2.9, .56), 0, .06 * math.sin(t * 2.4))
	end

	acts.anchor_crab = function(e, t, g, idle)
		local threat = pulse(t, 7.1, 4.7, 1.05)
		local body = root(e, .012 * math.sin(t * .8) * idle, 0, -.025 * threat * idle,
			Vector3.new(0, -.13 * g, 0))
		plant(e, "anchor_crab", {0, .18, .36, .50, .68, .86}, 2.1, .76, .21, body, g)
		pose(e, "ClawL", .07 * math.sin(t * 1.4), -.08 * threat, -.17 * threat)
		pose(e, "JawL", 0, 0, .28 * pulse(t + .30, 7.1, 4.7, .62))
		pose(e, "ClawR", -.10 * threat, .11 * threat, .23 * threat)
		pose(e, "JawR", 0, 0, -.36 * pulse(t, 7.1, 4.7, .82))
	end

	acts.hollow_violin = function(e, t, g, idle)
		local phrase = pulse(t, 5.8, 3.7, 1.15)
		local body = root(e, 0, 0, -.035 * phrase * idle, Vector3.new(0, -.19 * g, 0))
		plant(e, "hollow_violin", biped, 1.4, .64, .22, body, g)
		pose(e, "Scroll", -.04 * phrase, .20 * math.sin(t * .63), -.06 * phrase)
		for i = 0, 2 do
			local pluck = pulse(t - i * .24, 5.8, 3.7, .63)
			pose(e, "String" .. i, 0, 0, .022 * math.sin(t * (19 + i * 3)) * pluck,
				Vector3.new(.028 * math.sin(t * (19 + i * 3)) * pluck, 0, 0))
		end
	end

	acts.clockwork_raven = function(e, t, g, idle)
		local q = gait(e, {stride = 1.8})
		local scan = math.sin(t * .71) + .27 * pulse(t, 3.4, 2.2, .23)
		local wing = pulse(t, 6.5, 4.1, 1.45)
		local body = root(e, .023 * math.sin(q) * g, 0, .017 * math.sin(q) * g,
			Vector3.new(0, -.11 * g - .025 * (1 - wing) * idle, 0))
		plant(e, "clockwork_raven", biped, 1.8, .61, .25, body, g)
		-- Native WingL is on positive X: these signs lift the tips away from the ground.
		pose(e, "WingL", .045 * g, -.045 * wing, .11 + .18 * wing + .045 * math.sin(q) * g)
		pose(e, "WingR", -.04 * g, .05 * wing, -.09 - .20 * pulse(t - .23, 6.5, 4.1, 1.45))
		pose(e, "Head", -.055 * wing, .22 * scan, .075 * pulse(t, 3.4, 2.2, .23))
		pose(e, "Wheel", 0, 0, (t % 5) * TAU / 5 + .10 * math.sin(t * 8))
		pose(e, "Tail", -.12 * g + .08 * math.sin(t * .96) * idle, 0, .045 * math.sin(q) * g)
	end

	acts.eclipse_stag = function(e, t, g, idle)
		local survey = pulse(t, 8.7, 5.8, 1.8)
		local q = gait(e, {stride = 2.25})
		local body = root(e, .012 * math.sin(t * .95) * idle, .012 * math.sin(q) * g,
			.012 * math.sin(q) * g, Vector3.new(0, -.24 * g - .028 * (1 - math.sin(t * 1.15)) * idle, 0))
		plant(e, "eclipse_stag", diagonal, 2.25, .64, .24, body, g)
		pose(e, "Head", .06 * survey, .21 * math.sin(t * .48) * (idle + g * .35), -.095 * survey)
		pose(e, "Mane", .13 * math.sin(t * 1.7) + .065 * g, 0, .05 * math.sin(t * 1.1))
		pose(e, "Tail", .07 * math.sin(t * 1.4), .22 * math.sin(t * 1.1), 0)
	end

	acts.thorn_cathedral = function(e, t, g, idle)
		local chime = pulse(t, 6.3, 4.3, 1.4)
		local body = root(e, 0, 0, .008 * math.sin(t * .64) * idle,
			Vector3.new(0, -.23 * g, 0))
		plant(e, "thorn_cathedral", {0, .5, .75, .25}, 1.35, .77, .18, body, g)
		local cycle = t % 9.6
		local turn = smooth(math.clamp((cycle - 2.7) / 1.5, 0, 1))
			* (1 - smooth(math.clamp((cycle - 7.8) / 1.3, 0, 1)))
		pose(e, "RoseWindow", 0, 0, .48 * math.sin(t * .18) + .12 * turn)
		pose(e, "Belfry", .018 * chime, 0, .048 * math.sin(t * 3.6) * chime)
	end

	acts.endless_library = function(e, t, g, idle)
		local body = root(e, .008 * math.sin(t * .79) * idle, 0, 0, Vector3.new(0, -.23 * g, 0))
		plant(e, "endless_library", diagonal, 1.5, .74, .20, body, g)
		for i = 0, 2 do
			local consult = pulse(t - i * .57, 7.8, 4.1, 1.2)
			pose(e, "Book" .. i, -.08 * consult, .035 * math.sin(t * .7 + i),
				(i - 1) * .035 * consult, Vector3.new(0, .13 * consult, 0))
		end
		local read = pulse(t, 7.8, 5.0, 1.7)
		pose(e, "PageL", .06 * math.sin(t * 1.4), 0, .35 * read)
		pose(e, "PageR", -.05 * math.sin(t * 1.4 - .3), 0, -.38 * pulse(t - .26, 7.8, 5.0, 1.7))
		pose(e, "Bookmarks", .23 * math.sin(t * 1.7) * (g * .8 + idle * .35), 0, .055 * math.sin(t * 1.1))
	end

	acts.marrow_dice = function(e, t, g, idle)
		local rollL = pulse(t, 5.4, 3.3, 1.20)
		local rollR = pulse(t - .58, 5.4, 3.3, 1.07)
		root(e, 0, 0, 0)
		pose(e, "DieL", .13 * rollL, .33 * math.sin(t * .86), .08 * math.sin(t * .86),
			Vector3.new(-.055 * rollL, .28 + .18 * rollL + .05 * math.sin(t * 1.9), 0))
		pose(e, "DieR", -.16 * rollR, -.39 * math.sin(t * .86 - .5), -.10 * rollR,
			Vector3.new(.075 * rollR, .28 + .23 * rollR, .035 * g))
		for i = 0, 2 do
			local rattle = pulse(t - i * .13, 5.4, 3.4, .70)
			pose(e, "Pip" .. i, .07 * math.sin(t * 2 + i), 0, .09 * rattle,
				Vector3.new(.08 * math.sin(t * 1.6 + i), .20 * math.sin(t * 1.6 + i), .06 * rattle))
		end
	end

	acts.music_box_dancer = function(e, t, g, idle)
		local bow = pulse(t, 7.9, 5.8, 1.05)
		root(e, 0, 0, 0)
		-- The pedestal stays fixed while its ivory performer makes the full turn.
		pose(e, "Dancer", .025 * math.sin(t * 1.8), (t % 8) * TAU / 8, .025 * math.sin(t * 1.5))
		pose(e, "Head", .19 * bow, -.08 * math.sin(t * 1.1), .065 * math.sin(t * .7))
		pose(e, "ArmR", -.16 * bow, .08 * math.sin(t * 1.3), -.27 * math.sin(t * .65))
		pose(e, "Lid", -.09 * pulse(t, 7.9, 5.8, 1.6), 0, 0)
	end

	local bootBounds = {
		{Vector3.new(.648184,-3,-1.793094), Vector3.new(3.898223,3,3.269762)},
		{Vector3.new(-3.898223,-2.966042,-3.269762), Vector3.new(-.642717,1.837731,1.495669)},
	}
	acts.sleepwalker_shoes = function(e, t, g, idle)
		root(e, 0, 0, 0)
		local q = gait(e, {stride = 2.6})
		for i = 0, 1 do
			local z, lift, part = footCycle(q + i * math.pi, 2.6, .62, .38)
			local tap = pulse(t - i * .34, 6.8, 4.4, .60) * idle
			local pitch = (if part <= 1 then .16 * math.sin(part * math.pi * 2) else -.23 * math.sin((part - 1) * math.pi)) * g + .09 * tap
			local turn = CFrame.Angles(pitch, .045 * math.sin(t * .64 + i) * idle, 0)
			local rest = e.rest["Boot" .. i]
			if rest then
				local lo, hi = bootBounds[i + 1][1] * e.scale, bootBounds[i + 1][2] * e.scale
				local minY = math.huge
				for _, x in {lo.X, hi.X} do
					for _, y in {lo.Y, hi.Y} do
						for _, zz in {lo.Z, hi.Z} do
							local moved = rest:PointToWorldSpace(turn:PointToWorldSpace(rest:PointToObjectSpace(Vector3.new(x, y, zz))))
							minY = math.min(minY, moved.Y)
						end
					end
				end
				local x, yy, zz = turn:ToEulerAnglesXYZ()
				pose(e, "Boot" .. i, x, yy, zz,
					Vector3.new(0, math.max(0, (lo.Y - minY) / e.scale) + lift * g + .04 * tap, z * g))
			end
		end
	end

	acts.phantom_marionette = function(e, t, g, idle)
		local pull = pulse(t, 6.9, 4.3, 1.3)
		local counter = pulse(t - .47, 6.9, 4.3, 1.3)
		root(e, 0, 0, 0)
		pose(e, "Body", .045 * math.sin(t * 1.1) * idle, .075 * math.sin(t * .8), .11 * pull - .055 * counter,
			Vector3.new(0, .10 * pull, .05 * math.sin(t * 1.1) * g))
		pose(e, "Head", .10 * counter, -.20 * math.sin(t * .73), -.17 * pull)
		pose(e, "ArmL", -.13 * pull, .05 * math.sin(t * 1.4), .23 * pull)
		pose(e, "ArmLTip", .08 * pull, 0, -.28 * counter)
		pose(e, "ArmR", .18 * counter, -.06 * math.sin(t * 1.4), -.21 * counter)
		pose(e, "ArmRTip", -.08 * counter, 0, .27 * pull)
		-- This puppet is suspended; its uneven kicks follow distance without pretending to plant feet.
		local q = gait(e, {stride = 3.2})
		pose(e, "LegL", .18 * math.sin(q) * g + .12 * counter * idle, 0, -.11 * pull)
		pose(e, "LegLTip", -.24 * math.max(0, math.sin(q)) * g, 0, -.15 * counter * idle)
		pose(e, "LegR", -.15 * math.sin(q) * g, 0, .13 * counter)
		pose(e, "LegRTip", -.22 * math.max(0, -math.sin(q)) * g, 0, .18 * pull * idle)
	end

	acts.sunken_crown = function(e, t, g, idle)
		local tide = pulse(t, 7.7, 5.0, 1.8)
		root(e, .015 * math.sin(t * .63), .045 * math.sin(t * .38), 0,
			Vector3.new(0, .34 + .09 * math.sin(t * .73), 0))
		for i = 0, 5 do
			local angle = i * TAU / 6
			local wave = math.sin(t * 1.15 - i * .68)
			local follow = math.sin(t * 1.15 - i * .68 - .83)
			local x, z = math.sin(angle), math.cos(angle)
			pose(e, "Tendril" .. i, x * (.12 * wave + .06 * tide), .045 * wave,
				z * (.12 * wave + .06 * tide), Vector3.new(0, .02 * wave, 0))
			pose(e, "Tip" .. i, x * .20 * follow, .16 * math.sin(t * .84 - i * .65), z * .20 * follow,
				Vector3.new(0, .045 * follow, .035 * g))
		end
	end

	return acts
end
