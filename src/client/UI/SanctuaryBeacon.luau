-- Discreet world-space locator for the LOCAL player's claimed sanctuary only.
-- Reads Player.ClaimedBaseId (written by BaseService) and the map model; it
-- never changes claims, bases or any gameplay state.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VisualAssets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VisualAssets"))
local Theme = require(script.Parent.Theme)
local ClientSettings = require(script.Parent.ClientSettings)
local C, F = Theme.colors, Theme.fonts

local SanctuaryBeacon = {}
local HIDE_INSIDE = 40 -- studs: you are already there
local FADE_RANGE = 30 -- studs over which it fades back in
local HEIGHT_ABOVE = 10 -- studs above the sanctuary's bounding box

function SanctuaryBeacon.start(playerGui: PlayerGui)
	local player = Players.LocalPlayer
	local anchor = Instance.new("Attachment")
	anchor.Name = "SanctuaryBeaconAnchor"
	anchor.Parent = workspace.Terrain
	local billboard = Theme.make("BillboardGui", {
		-- Depth-tested on purpose: scenery may hide it and it never draws over
		-- Curse labels; it floats well above the sanctuary to stay visible.
		Name = "SanctuaryBeacon", Adornee = anchor, AlwaysOnTop = false, LightInfluence = 0,
		Size = UDim2.fromOffset(150, 66), MaxDistance = 4000, ResetOnSpawn = false, Enabled = false,
	}, playerGui)
	-- CanvasGroup does not render inside BillboardGuis; fade each element.
	local group = Theme.make("Frame", {
		Name = "Group", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
	}, billboard)
	local glow = Theme.image(group, "Glow", VisualAssets.Textures.glow_soft, UDim2.new(0.5, -26, 0, -8), UDim2.fromOffset(52, 52), {
		ImageColor3 = C.violet, ImageTransparency = 0.55,
	})
	local icon = Theme.image(group, "Icon", VisualAssets.Icons.sanctuary, UDim2.new(0.5, -15, 0, 3), UDim2.fromOffset(30, 30))
	local title = Theme.label(group, "Title", "YOUR SANCTUARY", UDim2.fromOffset(0, 34), UDim2.new(1, 0, 0, 14), 11, C.white, F.heavy)
	title.TextXAlignment = Enum.TextXAlignment.Center
	Theme.make("UIStroke", { Color = C.ink, Thickness = 1.5, Transparency = 0.2 }, title)
	local distance = Theme.label(group, "Distance", "", UDim2.fromOffset(0, 49), UDim2.new(1, 0, 0, 14), 12, C.cyan, F.bold)
	distance.TextXAlignment = Enum.TextXAlignment.Center
	Theme.make("UIStroke", { Color = C.ink, Thickness = 1.5, Transparency = 0.2 }, distance)

	local strokes = { title:FindFirstChildOfClass("UIStroke"), distance:FindFirstChildOfClass("UIStroke") }
	local function setFade(fade: number)
		icon.ImageTransparency = fade
		title.TextTransparency = fade
		distance.TextTransparency = fade
		for _, stroke in strokes do stroke.Transparency = 0.2 + 0.8 * fade end
		group:SetAttribute("Fade", fade)
	end

	local target: Vector3? = nil
	local function retarget()
		target = nil
		local id = player:GetAttribute("ClaimedBaseId")
		local map = workspace:FindFirstChild("StealACurseMap")
		local sanctuaries = map and map:FindFirstChild("PlayerSanctuaries")
		local base = if typeof(id) == "string" and sanctuaries then sanctuaries:FindFirstChild(id) else nil
		if base and base:IsA("Model") then
			local frame, size = base:GetBoundingBox()
			target = frame.Position + Vector3.new(0, size.Y * 0.5 + HEIGHT_ABOVE, 0)
			anchor.WorldPosition = target
		end
		billboard:SetAttribute("BaseId", if target then id else nil)
	end
	player:GetAttributeChangedSignal("ClaimedBaseId"):Connect(retarget)
	retarget()

	local elapsed, sinceRetarget = 0, 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.1 then return end
		sinceRetarget += elapsed
		elapsed = 0
		-- Sanctuary architecture can grow with upgrades; refresh the height.
		if sinceRetarget > 5 then sinceRetarget = 0 retarget() end
		local camera = workspace.CurrentCamera
		if not target or not camera or ClientSettings.get("sanctuaryMarker") == "Off" then
			billboard.Enabled = false
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local from = if root then root.Position else camera.CFrame.Position
		local flat = Vector3.new(target.X - from.X, 0, target.Z - from.Z).Magnitude
		billboard.Enabled = flat > HIDE_INSIDE
		local fade = 0.08 + 0.92 * (1 - math.clamp((flat - HIDE_INSIDE) / FADE_RANGE, 0, 1))
		setFade(fade)
		distance.Text = string.format("%d studs", math.floor(flat + 0.5))
		-- Slow bob and breathing glow: alive, never flashing.
		local t = os.clock()
		icon.Position = UDim2.new(0.5, -15, 0, 3 + math.sin(t * 2) * 2)
		glow.ImageTransparency = 1 - (1 - fade) * (0.45 - 0.1 * math.sin(t * 2.4))
	end)
	return billboard
end

return SanctuaryBeacon
