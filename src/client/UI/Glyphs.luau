-- Native monoline glyphs for the HUD dock. One family: a 22 x 22 art box,
-- 2 px strokes, rounded caps, one colour. Built only from Frames, UIStroke,
-- UICorner and Rotation (no uploaded images, no asset ids).
--
-- UIStroke is left at its default outer position, so an outline's frame is
-- the hole and the stroke grows 2 px outward; `outline` takes the OUTER
-- bounds. Axis-aligned parts sit on whole pixels; only the sigil and the
-- tag are rotated. UDim offsets are integers, so a fractional coordinate
-- (the tilted tag) puts its remainder in Scale of the exact 22 px art box.
-- The art is never scaled: a larger container centres the 22 px box.
local TweenService = game:GetService("TweenService")

local Glyphs = {}

local BOX, STROKE = 22, 2
Glyphs.box = BOX
Glyphs.kinds = { "grimoire", "shop", "settings" }

-- Art pixels -> UDim2: whole pixels in Offset, any fraction in Scale.
local function px(x: number, y: number): UDim2
	local ix, iy = math.floor(x), math.floor(y)
	return UDim2.new((x - ix) / BOX, ix, (y - iy) / BOX, iy)
end

local function frame(art: Frame, name: string, w: number, h: number, radius: number): Frame
	local part = Instance.new("Frame")
	part.Name = name
	part.BorderSizePixel = 0
	part.BackgroundTransparency = 1
	part.Size = px(w, h)
	if radius > 0 then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, radius)
		corner.Parent = part
	end
	part.Parent = art
	return part
end

-- Solid shape painted with BackgroundColor3. (x, y) is the top-left corner.
local function fill(art: Frame, name: string, x: number, y: number, w: number, h: number, radius: number): Frame
	local part = frame(art, name, w, h, radius)
	part.Position = px(x, y)
	part.BackgroundTransparency = 0
	part:SetAttribute("GlyphFill", true)
	return part
end

-- 2 px outline whose OUTER bounds are (x, y, w, h).
local function outline(art: Frame, name: string, x: number, y: number, w: number, h: number, radius: number): Frame
	local part = frame(art, name, w - 2 * STROKE, h - 2 * STROKE, radius)
	part.Position = px(x + STROKE, y + STROKE)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = STROKE
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = part
	return part
end

-- Centres a part on (cx, cy) in art pixels and turns it about that centre.
local function centre(part: Frame, cx: number, cy: number, rotation: number)
	part.AnchorPoint = Vector2.new(0.5, 0.5)
	part.Position = px(cx, cy)
	part.Rotation = rotation
end

-- 2 px line from (x1, y1) to (x2, y2) with round caps: a rounded bar turned
-- onto the segment. Caps overlap at shared points, so joins stay round.
local function line(art: Frame, name: string, x1: number, y1: number, x2: number, y2: number): Frame
	local dx, dy = x2 - x1, y2 - y1
	local part = fill(art, name, 0, 0, math.sqrt(dx * dx + dy * dy) + STROKE, STROKE, STROKE / 2)
	centre(part, (x1 + x2) / 2, (y1 + y2) / 2, math.deg(math.atan2(dy, dx)))
	return part
end

local BUILD = {}

-- Closed book: 16 x 20 cover, a spine bar inside the left edge, the page
-- edge along the bottom and a small diamond sigil on the front cover.
function BUILD.grimoire(art: Frame)
	outline(art, "Cover", 3, 1, 16, 20, 2)
	fill(art, "Spine", 7, 3, 2, 16, 1)
	fill(art, "Pages", 9, 15, 8, 2, 0)
	local sigil = fill(art, "Sigil", 0, 0, 4, 4, 0)
	centre(sigil, 13, 9, 45)
end

-- Price tag: a pentagon outline (pointed head, square body, 10 px wide) with
-- the string hole under the head, tilted 45 degrees so the head points up-left.
-- The tilted outline's bounds are centred on the art box.
local TAG = { { -5, -2 }, { -5, 8 }, { 5, 8 }, { 5, -2 }, { 0, -8 } }
local TAG_HOLE = { 0, -2 }
function BUILD.shop(art: Frame)
	local angle = math.rad(-45)
	local cos, sin = math.cos(angle), math.sin(angle)
	local function turn(point: { number }): (number, number)
		return point[1] * cos - point[2] * sin, point[1] * sin + point[2] * cos
	end
	local points = {}
	local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
	for index, point in TAG do
		local x, y = turn(point)
		points[index] = { x, y }
		minX, maxX, minY, maxY = math.min(minX, x), math.max(maxX, x), math.min(minY, y), math.max(maxY, y)
	end
	local ox, oy = BOX / 2 - (minX + maxX) / 2, BOX / 2 - (minY + maxY) / 2
	for index, a in points do
		local b = points[index % #points + 1]
		line(art, "Edge" .. index, ox + a[1], oy + a[2], ox + b[1], oy + b[2])
	end
	local hx, hy = turn(TAG_HOLE)
	local hole = fill(art, "Hole", 0, 0, 4, 4, 2)
	centre(hole, ox + hx, oy + hy, 0)
end

-- Three slider rails with round knobs at different stops.
function BUILD.settings(art: Frame)
	for index, knobX in { 14, 7, 11 } do
		local y = 3 + (index - 1) * 7
		fill(art, "Rail" .. index, 3, y, 16, STROKE, 1)
		fill(art, "Knob" .. index, knobX - 3, y - 2, 6, 6, 3)
	end
end

-- Recolours every painted part; `seconds` > 0 tweens instead of snapping.
function Glyphs.setColor(glyph: Instance, color: Color3, seconds: number?)
	glyph:SetAttribute("GlyphColor", color)
	local info = if seconds and seconds > 0 then TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) else nil
	local function paint(object: Instance, property: string)
		if info then
			TweenService:Create(object, info, { [property] = color }):Play()
		else
			(object :: any)[property] = color
		end
	end
	for _, object in glyph:GetDescendants() do
		if object:IsA("UIStroke") then
			paint(object, "Color")
		elseif object:IsA("Frame") and object:GetAttribute("GlyphFill") then
			paint(object, "BackgroundColor3")
		end
	end
end

-- Returns the container Frame and a setColor(color, seconds?) helper.
function Glyphs.create(kind: string, parent: Instance, position: UDim2, size: UDim2, color: Color3): (Frame, (Color3, number?) -> ())
	local build = BUILD[kind]
	assert(build, "Glyphs: unknown kind " .. tostring(kind))
	local container = Instance.new("Frame")
	container.Name = kind .. "Glyph"
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.Position = position
	container.Size = size
	container:SetAttribute("GlyphKind", kind)
	-- Centred, unscaled art box (whole-pixel offset for even container sizes).
	local art = Instance.new("Frame")
	art.Name = "Art"
	art.BackgroundTransparency = 1
	art.BorderSizePixel = 0
	art.Position = UDim2.new(0.5, -BOX / 2, 0.5, -BOX / 2)
	art.Size = UDim2.fromOffset(BOX, BOX)
	art.Parent = container
	build(art)
	Glyphs.setColor(container, color)
	container.Parent = parent
	return container, function(newColor: Color3, seconds: number?)
		Glyphs.setColor(container, newColor, seconds)
	end
end

return Glyphs
