-- Shared presentation geometry. This module never mutates ownership or rules.
local Motion = {}

function Motion.route(points, lengths, distance)
	local traveled = 0
	for index, length in ipairs(lengths) do
		if distance < traveled + length then
			local alpha = math.clamp((distance - traveled) / length, 0, 1)
			local position = points[index]:Lerp(points[index + 1], alpha)
			return CFrame.lookAt(position, position + (points[index + 1] - points[index]).Unit)
		end
		traveled += length
	end
	return CFrame.lookAt(points[#points], points[#points] + Vector3.zAxis)
end

function Motion.follow(frame: CFrame, size: Vector3, groundY: number?): CFrame
	local target = frame.Position - frame.LookVector * math.max(4, size.Z * .5 + 2.5)
		+ frame.RightVector * math.max(3.1, size.X * .5 + 1.5)
	local y = math.max(frame.Position.Y - 2.3, groundY or -math.huge) + size.Y * .5 + .12
	local _, yaw = frame:ToOrientation()
	return CFrame.new(target.X, y, target.Z) * CFrame.Angles(0, yaw, 0)
end

function Motion.alpha(dt: number, responseSeconds: number): number
	return 1 - math.exp(-math.max(dt, 0) / responseSeconds)
end

-- THE VOID: one envelope shared by its bone act and its hero VFX, so the
-- effect's beats land on the bone beats. Times are seconds into the cycle.
Motion.VoidPeriod = 8.4
Motion.VoidBeats = { draw = 1.5, tension = 3.9, release = 5.8, settle = 7.4 }

local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- Anticipation: from the draw beat the rift leans out to about -VoidLean,
-- built over 0.6 s, while the pull already starts underneath it.
Motion.VoidLean = 0.36

-- Returns draw, release, tension and the cycle time. draw is signed: exactly 0
-- in the hold, a clear outward lean (anticipation, about -0.35 at 0.6 s after
-- the draw beat) before it draws in to 1, a slow strain to 1.06, then a snap
-- past rest (about -0.4) that rings down and is exactly still again before the
-- wrap. release (0..1) peaks just after the snap; tension (0..1) covers the
-- strained near-stillness before it.
function Motion.voidPull(t: number): (number, number, number, number)
	local p = t % 8.4
	local draw, release = 0, 0
	if p < 5.8 then
		local lean = if p > 1.5 and p < 2.7 then math.sin(math.pi * (p - 1.5) / 1.2) ^ 2 else 0
		draw = smooth((p - 2) / 1.9) * (1 + 0.06 * smooth((p - 3.9) / 1.9)) - Motion.VoidLean * lean
	else
		local r = p - 5.8
		local still = 1 - smooth((p - 7.4) / 1)
		draw = 1.06 * math.exp(-2.4 * r) * math.cos(r * math.pi * 2.5) * still
		release = smooth(r / 0.12) * math.exp(-math.max(0, r - 0.12) / 0.5) * still
	end
	local tension = smooth((p - 3.7) / 0.5) * (1 - smooth((p - 5.8) / 0.15))
	return draw, release, tension, p
end

return Motion
