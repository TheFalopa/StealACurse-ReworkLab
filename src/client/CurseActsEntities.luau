-- Concept acting for 17 existing entities. No transforms on gameplay anchors,
-- CFrames on MeshParts, connections, tasks, VFX changes or asset dependencies.
-- Helpers and state smoothing are owned by the integrated animation controller.
return function(H)
	local pose, pulse, smooth, gait = H.pose, H.pulse, H.smooth, H.gait
	local sin, cos, pi, abs = math.sin, math.cos, math.pi, math.abs
	local tau = pi * 2
	local acts = {}
	local pair = {0, pi}
	local diagonal = {0, pi, pi, 0}
	local stops = {-.36, .05, .43, .05}
	local settings = {
		sundial_sentinel={stride=1.8}, night_harp={stride=1.7}, blood_moon_rose={stride=1.35},
		judgement_scales={stride=1.85}, cathedral_heart={stride=1.9}, hollow_throne={stride=1.8},
		nameless_door={stride=1.35}, the_first_grave={stride=2.5},
		the_last_funeral={stride=3.4}, the_last_star={stride=2.6}, worldroot={stride=2.65},
	}
	-- Broad stance occupies 62% of a distance-driven cycle. During stance each
	-- foot sweeps steadily back; recovery follows a separate lifted arc. Knees
	-- counter-rotate the shin in stance and flex during recovery. A hip-height
	-- correction compensates for the upper link's shortening under rotation.
	local function legs(e, q, g, phases, amplitude, flex, brace)
		for i, offset in phases do
			local p = ((q + offset) / tau) % 1
			local reach, lift
			if p < .62 then
				reach, lift = 1 - 2 * p / .62, 0
			else
				local recovery = (p - .62) / .38
				reach, lift = -cos(pi * recovery), sin(pi * recovery)^1.5
			end
			local angle = amplitude * reach * g + (brace or 0) * (if i < 3 then 1 else -1)
			local name = tostring(i - 1)
			local kneeRest = e.rest and e.rest['Knee'..name]
			local length = if kneeRest then abs(kneeRest.Position.Y) / e.scale else .45
			local compensate = length * (1 - cos(angle))
			pose(e, 'Leg'..name, angle, 0, 0, Vector3.new(0, -compensate, 0))
			pose(e, 'Knee'..name, -angle * .8 - flex * lift * g, 0, 0)
		end
	end
	-- A closed, continuously eased gesture envelope with a deliberate hold.
	local function gesture(t, period, start, rise, hold, fall)
		local p = (t % period) - start
		if p < 0 then return 0 end
		if p < rise then return smooth(p / rise) end
		if p < rise + hold then return 1 end
		if p < rise + hold + fall then return 1 - smooth((p - rise - hold) / fall) end
		return 0
	end
	local function carrying(e)
		return if e.state == 'CARRYING' then 1 else 0
	end
	local function pickup(e)
		return if e.state == 'CARRYING' then 1 - smooth(math.clamp((e.stateAge or 10) / .7, 0, 1)) else 0
	end
	local function placing(e)
		return if e.state == 'PLACED' then math.max(0, 1 - abs((e.stateAge or 10) - .3) / .3)^2 else 0
	end

	function acts.veil_mourner(e, t, g, idle)
		local grief = gesture(t, 8.3, 1.4, .75, 1.1, 1.25)
		local shiver = pulse(t, 8.3, 3.2, .42) * sin(t * 22)
		local huddle = .15 * grief + .045 * carrying(e) + .10 * pickup(e)
		pose(e, 'Root', .035 + .055 * g, 0, .012 * shiver, Vector3.new(0, .10, 0))
		pose(e, 'VeilL', -.035 * g, .065 * grief, -.14 * grief - .06 * sin(t * .95), Vector3.new(.055 * grief, 0, 0))
		pose(e, 'VeilR', -.045 * g, -.065 * grief, .14 * grief + .06 * sin(t * .95 - .4), Vector3.new(-.055 * grief, 0, 0))
		pose(e, 'HandL', .12 + huddle + .025 * shiver, 0, -.09 * grief)
		pose(e, 'HandR', .12 + huddle - .025 * shiver, 0, .09 * grief)
		pose(e, 'Comb', .10 * grief, .055 * sin(t * .38), .02 * shiver)
	end

	function acts.umbrella_wraith(e, t, g, idle)
		local beat = sin(t * 1.85)
		local open = gesture(t, 9.7, .9, .7, 1.8, 1.3) * idle
		local spread = .12 + .20 * open + .13 * g * beat - .12 * pickup(e)
		pose(e, 'Root', -.08 * g, 0, .025 * sin(t * .53), Vector3.new(0, .16 + .055 * (beat + 1) * g, 0))
		pose(e, 'WingL', -.035 * g, .025 * sin(t), -spread)
		pose(e, 'WingR', -.035 * g, -.025 * sin(t), spread * .94)
		pose(e, 'RagL', .12 * g + .16 * sin(t * 2.3 - .6), 0, -.07 * sin(t * 1.45 - .5))
		pose(e, 'RagR', .12 * g + .13 * sin(t * 2.3 - 1.1), 0, .065 * sin(t * 1.45 - .8))
	end

	function acts.sundial_sentinel(e, t, g, idle)
		local q = gait(e, settings.sundial_sentinel)
		legs(e, q, g, pair, .28, .26)
		-- Three held shadow directions, with an accelerated change between them.
		local tick = (t / 3.9) % 4
		local n = math.floor(tick) + 1
		local turn = smooth(math.clamp((tick % 1) / .23, 0, 1))
		local shadow = stops[n] + (stops[n % 4 + 1] - stops[n]) * turn
		shadow *= 1 - .5 * pickup(e)
		pose(e, 'Shadow', 0, 0, shadow)
		pose(e, 'Root', .035 * g, 0, .024 * sin(q) * g, Vector3.new(0, .05 * g, 0))
	end

	function acts.blood_moon_rose(e, t, g, idle)
		local q = gait(e, settings.blood_moon_rose)
		legs(e, q, g, diagonal, .24, .33)
		local bloom = math.max(gesture(t, 7.4, .6, 1.15, 1.4, 1.9), placing(e))
		local bite = math.max(gesture(t, 7.4, 4.25, .5, .35, .65), pickup(e))
		pose(e, 'Root', .025 * g, .02 * sin(q * .5) * g, 0, Vector3.new(0, .065 * g, 0))
		pose(e, 'Bloom', -.055 * bloom, .11 * sin(t * .46), 0)
		for i=0,3 do
			local petal = .055 + .13 * bloom + .035 * sin(t * .8 - i * .65)
			local sign = if i < 2 then -1 else 1
			pose(e, 'Petal'..i, if i % 2 == 1 then sign * petal else 0, 0, if i % 2 == 0 then sign * petal else 0)
		end
		pose(e, 'ThornArmL', .07 * g, -.035 * bite, -.07 + .22 * bite)
		pose(e, 'ThornArmR', .07 * g, .035 * bite, .07 - .22 * bite)
	end

	function acts.night_harp(e, t, g, idle)
		local q = gait(e, settings.night_harp)
		legs(e, q, g, diagonal, .27, .29)
		local listen = math.max(gesture(t, 6.8, .75, .8, 1.3, 1.1), pickup(e))
		pose(e, 'Root', .018 * g, 0, .016 * sin(q) * g, Vector3.new(0, .035 * g, 0))
		pose(e, 'Head', -.10 * listen, .20 * sin(t * .52), .06 * listen)
		for i=0,3 do
			local pluck = gesture(t - i * .27, 4.6, .8, .07, .03, .54)
			-- Only tube centers are weighted: frame and both endpoints stay fixed.
			local vibration = .065 * pluck * cos((t - i * .27) * 17)
			pose(e, 'String'..i, 0, 0, 0, Vector3.new(vibration, 0, 0))
		end
	end

	function acts.judgement_scales(e, t, g, idle)
		local q = gait(e, settings.judgement_scales)
		legs(e, q, g, pair, .29, .24)
		local deliberation = t % 10.8
		local weigh
		if deliberation < 2 then weigh = -.24 + .44 * smooth(deliberation / 2)
		elseif deliberation < 4.7 then weigh = .20
		elseif deliberation < 6.3 then weigh = .20 - .51 * smooth((deliberation - 4.7) / 1.6)
		elseif deliberation < 8 then weigh = -.31
		else weigh = -.31 + .07 * smooth((deliberation - 8) / 2.8) end
		local damping = (1 - .28 * g) * (1 - .7 * pickup(e))
		weigh *= damping
		-- Both beam halves rotate together; pans counter-rotate and stay level.
		pose(e, 'BalanceL', 0, 0, weigh)
		pose(e, 'BalanceR', 0, 0, weigh)
		pose(e, 'PanL', .035 * sin(t * 2.1) * (1 - damping), 0, -weigh)
		pose(e, 'PanR', -.035 * sin(t * 2.1) * (1 - damping), 0, -weigh)
		pose(e, 'Root', .025 * g, 0, .018 * sin(q) * g, Vector3.new(0, .05 * g, 0))
	end

	function acts.cathedral_heart(e, t, g, idle)
		local q = gait(e, settings.cathedral_heart)
		legs(e, q, g, diagonal, .29, .25)
		local beat = pulse(t, 2.2, .46, .20) + .68 * pulse(t, 2.2, .91, .26) + .4 * placing(e)
		pose(e, 'Root', .012 * g, 0, .012 * sin(q) * g, Vector3.new(0, .055 * g, 0))
		pose(e, 'HeartL', .02 * beat, 0, -.032 * beat, Vector3.new(-.075 * beat, .015 * beat, -.075 * beat))
		pose(e, 'HeartR', .02 * beat, 0, .032 * beat, Vector3.new(.075 * beat, .015 * beat, -.075 * beat))
	end

	function acts.hollow_throne(e, t, g, idle)
		local q = gait(e, settings.hollow_throne)
		legs(e, q, g, diagonal, .29, .30)
		local appear = gesture(t, 9.3, 1.1, 1.05, 2.1, 1.8) * (1 - .4 * pickup(e))
		local lean = gesture(t, 9.3, 3.1, .75, .45, .9)
		pose(e, 'Root', .018 * g, 0, .016 * sin(q) * g, Vector3.new(0, .065 * g, 0))
		pose(e, 'Ghost', -.10 * lean, .12 * sin(t * .36), -.02 * appear, Vector3.new(0, .22 * appear, -.05 * lean))
		pose(e, 'Mantle', .055 * appear, 0, .11 * sin(t * .74 - .7) * (.4 + appear * .6))
	end

	function acts.nameless_door(e, t, g, idle)
		local q = gait(e, settings.nameless_door)
		legs(e, q, g, pair, .29, .27)
		local inviting = math.max(gesture(t, 8.7, .5, 1.25, 2.3, 1.7), placing(e)) * (1 - pickup(e))
		local knock = pulse(t, 8.7, 6.8, .13) - .65 * pulse(t, 8.7, 7.15, .10)
		pose(e, 'Door', 0, -.31 * inviting + .028 * knock, 0)
		pose(e, 'LintelMoss', .14 * g + .12 * sin(t * .9), 0, .025 * sin(q) * g)
		pose(e, 'Root', .018 * g, 0, .016 * sin(q) * g, Vector3.new(0, .045 * g, 0))
	end

	function acts.silent_choir(e, t, g, idle)
		pose(e, 'Root', -.025 * g, 0, 0, Vector3.new(0, .035, 0))
		-- Each singer enters the phrase separately, then all bow on its cadence.
		local cadence = math.max(gesture(t, 9.6, 6.2, .65, .55, 1.1), placing(e))
		for i=0,2 do
			local phrase = gesture(t - i * .95, 9.6, .9, .65, 1.0, 1.3)
			local sign = if i == 0 then -1 elseif i == 2 then 1 else 0
			pose(e, 'Singer'..i, .065 * cadence, 0, sign * .03 * phrase, Vector3.new(0, .065 * phrase, 0))
			pose(e, 'Bell'..i, -.11 * phrase + .10 * cadence, sign * .085 * phrase, sign * .055 * sin(t * .8 - i))
		end
	end

	function acts.the_first_grave(e, t, g, idle)
		local q = gait(e, settings.the_first_grave)
		legs(e, q, g, pair, .30, .28)
		local remember = math.max(gesture(t, 10.1, 1.2, 1.4, 1.5, 1.4) * idle, .45 * pickup(e))
		pose(e, 'Root', .048 * g + .022 * remember, 0, .025 * sin(q) * g, Vector3.new(0, .065 * g, 0))
		pose(e, 'ArmL', -.16 * sin(q) * g - .26 * remember, .04 * remember, .04)
		pose(e, 'ArmR', .16 * sin(q) * g - .16 * remember, -.04 * remember, -.04)
		pose(e, 'FingersL', .07 * remember, 0, -.18 * remember)
		pose(e, 'FingersR', .07 * remember, 0, .18 * remember)
		pose(e, 'MossL', .06 + .13 * sin(t * .87 - .6) + .10 * g * sin(q - .4), 0, 0)
		pose(e, 'MossR', .05 + .11 * sin(t * .87 - 1.1) - .10 * g * sin(q - .4), 0, 0)
	end

	function acts.the_last_funeral(e, t, g, idle)
		local q = gait(e, settings.the_last_funeral)
		local settle = gesture(t, 13.7, 3.2, 1.3, .9, 1.9) * idle
		local brace = .075 * settle + .055 * pickup(e) + .045 * placing(e)
		legs(e, q, g, diagonal, .30, .32, brace)
		-- Carrier straps above their hip attach rigidly to the coffin. Only the
		-- suspended coffin's weight shift accompanies the four bearing limbs.
		pose(e, 'Root', .012 * sin(q) * g, 0, .018 * sin(q) * g,
			Vector3.new(0, .045 * g + .025 * abs(sin(q)) * g + .032 * settle, 0))
	end

	function acts.the_last_star(e, t, g, idle)
		local q = gait(e, settings.the_last_star)
		legs(e, q, g, diagonal, .29, .25)
		-- An imprisoned star indexes one eighth-turn, then holds. The boundary
		-- between steps is continuous, even when its angle passes a full turn.
		local cycle = t / 3.3
		local index = math.floor(cycle)
		local turn = (index + smooth(math.clamp((cycle % 1) / .26, 0, 1))) * pi / 4
		local tighten = math.max(gesture(t, 8.8, 1.3, .6, 1.5, .8), pickup(e))
		pose(e, 'Star', 0, .02 * sin(t * .7), turn, Vector3.new(0, .015 * tighten, 0))
		pose(e, 'Helm', .065 * tighten, .20 * sin(t * .34), 0)
		pose(e, 'ArmL', -.055 * g, .07 * tighten, -.055 + .14 * tighten)
		pose(e, 'ArmR', -.055 * g, -.07 * tighten, .055 - .14 * tighten)
		pose(e, 'TalonsL', .24 * tighten + .055 * carrying(e), 0, -.04 * tighten)
		pose(e, 'TalonsR', .24 * tighten + .055 * carrying(e), 0, .04 * tighten)
		pose(e, 'Root', .025 * g, 0, .012 * sin(q) * g, Vector3.new(0, .06 * g, 0))
	end

	function acts.crown_of_silence(e, t, g, idle)
		local hush = math.max(gesture(t, 10.4, 1.1, 1.1, 1.9, 1.6), placing(e))
		pose(e, 'Root', -.055 * g, 0, 0, Vector3.new(0, .12, 0))
		for i=0,3 do
			local lifted = gesture(t - i * .7, 10.4, .7, 1.1, 2.0, 1.8)
			local sign = if i % 2 == 0 then -1 else 1
			pose(e, 'Crown'..i, .065 * lifted, sign * .07 * lifted, sign * .12 * lifted,
				Vector3.new(sign * (.035 * lifted - .025 * pickup(e)), .17 * lifted - .055 * pickup(e), 0))
			pose(e, 'Robe'..i, .08 * g + .11 * sin(t * .8 - i * .9) * (.35 + .65 * hush),
				0, sign * .035 * hush)
		end
		pose(e, 'SleeveL', .05 * g, -.045 * hush, -.10 - .15 * hush)
		pose(e, 'SleeveR', .05 * g, .045 * hush, .10 + .15 * hush)
	end

	function acts.the_undertow(e, t, g, idle)
		local surge = gesture(t, 6.7, .6, .95, .45, 1.3)
		local drag = .12 * g
		pose(e, 'Root', -.075 * g, 0, .018 * sin(t * .5), Vector3.new(0, .15 + .075 * surge, 0))
		pose(e, 'Clapper', (.22 + .10 * g) * sin(t * 1.65 - .25) * (1 - .6 * pickup(e)), .04 * sin(t * .83), 0)
		pose(e, 'BladeL', drag + .06 * surge, .11 * surge, -.12 - .18 * surge)
		pose(e, 'BladeR', drag + .045 * surge, -.09 * surge, .09 + .23 * surge)
		pose(e, 'Vortex', 0, t * .47, .03 * sin(t * 1.1), Vector3.new(0, .13 * surge, 0))
		pose(e, 'Hanger', -.04 * g, 0, .055 * sin(t * 1.65 - .65))
	end

	function acts.the_unwritten(e, t, g, idle)
		local phase = t % 7.6
		local prepare = math.max(gesture(t, 7.6, .4, .65, 2.7, .9), .65 * pickup(e))
		local write = gesture(t, 7.6, 1.15, .2, 2.0, .35)
		local erase = gesture(t, 7.6, 4.9, .4, .6, .65)
		local pen = sin(t * 8.5) * write
		pose(e, 'Root', -.055 * g, 0, 0, Vector3.new(0, .13, 0))
		pose(e, 'Head', .13 * prepare - .07 * erase, -.10 * erase, .05 * sin(t * .41))
		pose(e, 'SleeveL', -.11 * prepare + .06 * g, .035 * write, -.08 - .11 * prepare)
		pose(e, 'SleeveR', -.13 * erase + .06 * g, -.04 * erase, .06 + .22 * erase)
		pose(e, 'WritingHandL', .16 * prepare + .14 * pen, .065 * cos(t * 6) * write, -.075 * write)
		pose(e, 'WritingHandR', .12 * prepare - .28 * erase, -.09 * sin(phase * 4) * erase, .20 * erase)
		for i=0,3 do
			local page = gesture(t - i * .35, 7.6, 3.65, .32, .24, .85)
			local sign = if i % 2 == 0 then -1 else 1
			pose(e, 'PageTail'..i, .18 * g + .09 * sin(t * 1.5 - i * .8), sign * .08 * page,
				sign * (.045 + .14 * page), Vector3.new(0, .035 * page, .03 * g))
		end
	end

	function acts.worldroot(e, t, g, idle)
		local q = gait(e, settings.worldroot)
		legs(e, q, g, diagonal, .29, .30)
		local unfurl = gesture(t, 11.3, 1.2, 1.9, 2.0, 2.3)
		pose(e, 'Root', .025 * g, 0, .015 * sin(q) * g, Vector3.new(0, .065 * g, 0))
		pose(e, 'TrunkL', 0, -.025 * unfurl, -.055 * unfurl)
		pose(e, 'TrunkR', 0, .025 * unfurl, .055 * unfurl)
		pose(e, 'Seed', .075 * sin(t * .53), t * .23, 0, Vector3.new(0, .19 * unfurl + .035 * sin(t * .91) - .07 * pickup(e), 0))
		pose(e, 'MossL', .15 * g + .16 * sin(t * .94 - .6), 0, -.035 * sin(t * .52))
		pose(e, 'MossR', .15 * g + .14 * sin(t * .94 - 1.1), 0, .035 * sin(t * .52))
	end

	return acts
end
