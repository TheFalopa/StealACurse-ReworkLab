-- Reusable vector-like silhouettes made exclusively from Roblox UI geometry.
-- Coordinates are normalized so the same authored glyph reads at 24 or 64 px.
local Theme = require(script.Parent.Theme)
local C = Theme.colors
local Icons = {}

local function shape(parent: Instance, name: string, x: number, y: number, w: number, h: number, color: Color3, radius: number?, rotation: number?)
	local part = Theme.make("Frame", {
		Name = name, BackgroundColor3 = color, BorderSizePixel = 0,
		Position = UDim2.fromScale(x / 100, y / 100),
		Size = UDim2.fromScale(w / 100, h / 100), Rotation = rotation or 0,
	}, parent)
	if radius then Theme.make("UICorner", { CornerRadius = UDim.new(radius, 0) }, part) end
	return part
end

local function soul(root: Frame, accent: Color3)
	-- Three flame licks and a curling lower tail, not a stock ghost emoji.
	shape(root, "HighLick", 41, 8, 25, 29, accent, 0.22, 32)
	shape(root, "SideLick", 19, 28, 20, 27, accent, 0.24, -27)
	shape(root, "Curl", 54, 63, 25, 20, accent, 0.28, -30)
	local head = shape(root, "SpiritFlame", 22, 24, 56, 54, accent, 0.48)
	Theme.gradient(head, Color3.fromRGB(223, 255, 246), accent)
	shape(root, "LeftEye", 35, 43, 7, 13, C.ink, 0.45, -9)
	shape(root, "RightEye", 57, 43, 7, 13, C.ink, 0.45, 9)
	shape(root, "BrowGlint", 36, 31, 18, 4, Color3.fromRGB(237, 255, 251), 0.5, -16)
end

local function shop(root: Frame, accent: Color3)
	local handle = shape(root, "BagHandle", 34, 16, 32, 31, C.panel, 0.48)
	Theme.stroke(handle, accent, 2)
	local bag = shape(root, "CurioBag", 20, 36, 60, 48, accent, 0.14)
	Theme.gradient(bag, accent, accent:Lerp(C.violet, 0.5))
	shape(root, "Seal", 43, 49, 14, 14, C.ink, 0.15, 45)
	shape(root, "SealLight", 47, 53, 6, 6, C.white, 0.1, 45)
end

local function collection(root: Frame, accent: Color3)
	for index, data in { { 14, 27, -12 }, { 55, 27, 12 }, { 34, 16, 0 } } do
		local page = shape(root, "RelicCard" .. index, data[1], data[2], 30, 58, C.panel, 0.13, data[3])
		Theme.stroke(page, accent, 1.6)
	end
	shape(root, "Relic", 43, 35, 15, 22, accent, 0.16, 45)
	shape(root, "RelicLabel", 42, 66, 17, 3, accent, 0.5)
end

local function settings(root: Frame, accent: Color3)
	for index = 0, 7 do
		local angle = index * math.pi / 4
		local x, y = 50 + math.sin(angle) * 29, 50 - math.cos(angle) * 29
		shape(root, "CogTooth" .. index, x - 8, y - 10, 16, 20, accent, 0.14, index * 45)
	end
	shape(root, "CogRing", 24, 24, 52, 52, accent, 0.5)
	shape(root, "CogCenter", 39, 39, 22, 22, C.panel, 0.5)
end

local function star(root: Frame, accent: Color3)
	shape(root, "LuckVertical", 43, 14, 14, 72, accent, 0.3)
	shape(root, "LuckHorizontal", 14, 43, 72, 14, accent, 0.3)
	shape(root, "LuckDiamond", 31, 31, 38, 38, accent, 0.12, 45)
	shape(root, "LuckCenter", 44, 44, 12, 12, C.white, 0.4)
end

local function crown(root: Frame, accent: Color3)
	shape(root, "CrownBand", 20, 63, 60, 15, accent, 0.15)
	shape(root, "CrownLeft", 20, 35, 18, 32, accent, 0.12, -18)
	shape(root, "CrownRight", 62, 35, 18, 32, accent, 0.12, 18)
	shape(root, "CrownCenter", 41, 24, 18, 40, accent, 0.1, 0)
	shape(root, "CrownGem", 44, 48, 12, 12, C.ink, 0.1, 45)
end

local function slot(root: Frame, accent: Color3)
	shape(root, "PedestalTop", 24, 38, 52, 12, accent, 0.12)
	shape(root, "PedestalColumn", 39, 51, 22, 26, accent, 0.12)
	shape(root, "PedestalFoot", 26, 78, 48, 8, accent, 0.12)
	shape(root, "SlotVertical", 47, 13, 6, 19, accent, 0.1)
	shape(root, "SlotHorizontal", 41, 19, 18, 6, accent, 0.1)
end

local function speed(root: Frame, accent: Color3)
	for index = 0, 1 do
		local x = 25 + index * 28
		shape(root, "SpeedUpper" .. index, x, 28, 12, 36, accent, 0.18, -40)
		shape(root, "SpeedLower" .. index, x, 48, 12, 36, accent, 0.18, 40)
	end
end

function Icons.create(kind: string, parent: Instance, position: UDim2, size: UDim2, accent: Color3?): Frame
	local root = Theme.make("Frame", {
		Name = kind .. "Icon", BackgroundTransparency = 1, BorderSizePixel = 0,
		Position = position, Size = size,
	}, parent)
	local color = accent or C.cyan
	if kind == "souls" or kind == "double" then
		soul(root, color)
		if kind == "double" then
			local multiplier = Theme.label(root, "Multiplier", "2x", UDim2.fromScale(0.57, 0.62), UDim2.fromScale(0.43, 0.33), 14, C.white, Enum.Font.GothamBlack)
			multiplier.TextScaled = true
			Theme.make("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = 22 }, multiplier)
		end
	elseif kind == "shop" then shop(root, color)
	elseif kind == "curses" then collection(root, color)
	elseif kind == "settings" then settings(root, color)
	elseif kind == "luck" then star(root, color)
	elseif kind == "vip" then crown(root, color)
	elseif kind == "slot" then slot(root, color)
	elseif kind == "speed" then speed(root, color)
	else collection(root, color) end
	return root
end

return Icons
