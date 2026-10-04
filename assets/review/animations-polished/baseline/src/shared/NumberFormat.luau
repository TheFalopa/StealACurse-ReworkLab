-- Keep suffixes in one place so the HUD and world labels use the same scale.
local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

local NumberFormat = {}

function NumberFormat.compact(value: number): string
	if type(value) ~= "number" or value ~= value then
		return "—"
	end
	if value == math.huge then
		return "∞"
	elseif value == -math.huge then
		return "−∞"
	end

	local negative = value < 0
	local magnitude = math.abs(value)
	local suffixIndex = 1
	while magnitude >= 1000 and suffixIndex < #SUFFIXES do
		magnitude /= 1000
		suffixIndex += 1
	end

	if suffixIndex == #SUFFIXES and magnitude >= 1000 then
		return string.format("%.1e", value)
	end

	local digits: string
	if suffixIndex == 1 then
		-- Never show a whole Soul the player has not actually earned yet.
		digits = tostring(math.floor(magnitude))
	else
		local rounded = math.floor(magnitude * 10 + 0.5) / 10
		if rounded >= 1000 and suffixIndex < #SUFFIXES then
			rounded /= 1000
			suffixIndex += 1
		end
		digits = string.format("%.1f", rounded):gsub("%.0$", "")
	end

	return (if negative then "−" else "") .. digits .. SUFFIXES[suffixIndex]
end

return NumberFormat
