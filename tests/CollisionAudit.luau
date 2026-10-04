-- STUDIO-ONLY audit (not mapped by default.project.json). Server command bar
-- during Play:  print(require(<this module>).run())
-- Reports (1) large visible non-collidable parts without a collision hull,
-- (2) blocking hulls that overlap walkable paths or procession points, and
-- (3) grounded props whose lowest corner floats above the support below.
-- It never moves or edits the map: audit -> inspect -> correct in source.
local Audit = {}

local SKIP = { DistantHauntedWorld = true, OuterBoundary = true, Ground = true, ActiveCurses = true, ToolEffects = true }
local GROUNDED = {
	grave_arched = true, grave_spire = true, grave_broken = true, final_pumpkin = true, rock_crag = true,
	tree_widow = true, tree_claw = true, tree_sundered = true, final_hero_grave = true, stone_warden = true,
	final_buttress = true, final_iron_fence = true, final_giant_tree = true,
}

local function topGroup(map, d)
	local top = d
	while top.Parent and top.Parent ~= map do top = top.Parent end
	return top.Name
end

function Audit.run(): string
	local map = workspace:FindFirstChild("StealACurseMap")
	assert(map, "Run during Play after the map is built")
	local out = {}
	-- 1. Unhulled solids
	local unhulled = {}
	for _, d in map:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 0.9 and not d.CanCollide and d.Size.Y > 2.5 and not SKIP[topGroup(map, d)] then
			local category = d:GetAttribute("CollisionCategory")
			if category ~= "Soft" and not d:FindFirstChild("CollisionHulls") then
				local key = topGroup(map, d) .. "/" .. (d:GetAttribute("SourceTemplate") or string.gsub(d.Name, "%d+", "#"))
				unhulled[key] = (unhulled[key] or 0) + 1
			end
		end
	end
	table.insert(out, "Unhulled non-soft solids (review case by case):")
	for k, v in unhulled do table.insert(out, string.format("  %3d %s", v, k)) end
	-- 2. Hull conflicts
	local paths = map:FindFirstChild("Paths")
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { paths }
	local hulls, conflicts = 0, 0
	for _, h in map:GetDescendants() do
		if h:IsA("BasePart") and h:GetAttribute("EnvironmentCollisionHull") then
			hulls += 1
			if paths and #workspace:GetPartBoundsInBox(h.CFrame, h.Size + Vector3.new(0, 2, 0), params) > 0 then conflicts += 1 end
		end
	end
	table.insert(out, string.format("Hulls: %d, overlapping path strips: %d", hulls, conflicts))
	-- 3. Floating grounded props
	local exclude = {}
	for _, d in map:GetDescendants() do
		if d:IsA("BasePart") and (d:GetAttribute("EnvironmentCollisionHull") or not d.CanCollide) then table.insert(exclude, d) end
	end
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances = exclude
	local floating = 0
	for _, d in map:GetDescendants() do
		if d:IsA("MeshPart") and GROUNDED[d:GetAttribute("SourceTemplate") or ""] and not SKIP[topGroup(map, d)] then
			local lowest, s = math.huge, d.Size * 0.5
			for _, x in { -1, 1 } do for _, y in { -1, 1 } do for _, z in { -1, 1 } do
				lowest = math.min(lowest, (d.CFrame * Vector3.new(x * s.X, y * s.Y, z * s.Z)).Y)
			end end end
			local hit = workspace:Raycast(Vector3.new(d.Position.X, lowest + 6, d.Position.Z), Vector3.new(0, -30, 0), ray)
			if hit and lowest - hit.Position.Y > 0.6 then
				floating += 1
				table.insert(out, string.format("  floating %.2f %s", lowest - hit.Position.Y, d:GetFullName()))
			end
		end
	end
	table.insert(out, "Floating grounded props (>0.6 studs): " .. floating)
	return table.concat(out, "\n")
end

return Audit
