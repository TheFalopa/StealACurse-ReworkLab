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

return Motion
