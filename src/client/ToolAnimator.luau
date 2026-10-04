-- Procedural tool motion for every character (no uploaded animations).
-- The server publishes Character attributes ToolActionId / ToolActionAt /
-- ToolActionWindup when a use is accepted; each client layers a short pose on
-- top of the normal Animator output (composed in PreSimulation), so everyone
-- sees the same anticipation -> action -> recovery. Also owns the local
-- ragdoll humanoid state and small camera feedback.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Animator = {}

-- Poses are (shoulderPitch, shoulderRoll, elbow, waistYaw, waistPitch,
-- leftShoulderPitch) in radians for R15. Positive pitch raises the arm forward.
local STYLE = {
	shovel = "swing", impact_urn = "throw", jailer_chain = "whip",
	exorcist_lantern = "raise", mist_censer = "raise", double_mirror = "raise",
	consecrated_salt = "pour", root_trap = "pour", break_talisman = "ward", ash_boots = "crouch",
}
local POSES = {
	--            anticipation (end of windup)          action (peak)                       hold
	swing  = { a = { 2.6, 0.2, -0.4, 0.55, 0.15, 2.4 }, b = { -0.35, -0.1, -0.1, -0.6, -0.25, -0.2 }, hold = 0.12 },
	throw  = { a = { 2.9, 0.5, -1.2, 0.5, 0.1, 0.2 }, b = { 0.9, -0.2, 0, -0.45, -0.15, 0.3 }, hold = 0.1 },
	whip   = { a = { 2.5, 0.6, -1.4, 0.6, 0.1, 0 }, b = { 1.25, -0.15, 0, -0.5, -0.1, 0 }, hold = 0.2 },
	raise  = { a = { 1.2, 0, -0.6, 0, 0, 0 }, b = { 2.3, 0, -0.2, 0, 0.05, 0 }, hold = 0.35 },
	pour   = { a = { 1.0, 0, -0.3, 0.1, -0.15, 0 }, b = { 0.55, 0, 0, 0, -0.35, 0 }, hold = 0.35 },
	ward   = { a = { 1.8, 0.2, -1.6, 0, 0, 0 }, b = { 2.2, 0.1, -1.9, 0, 0.05, 0 }, hold = 0.3 },
	crouch = { a = { 0.3, 0, 0, 0, -0.35, 0.3 }, b = { -0.2, 0, 0, 0, 0.15, -0.2 }, hold = 0.05 },
}
local STRIKE = 0.14 -- seconds from anticipation pose to action pose
local RECOVER = 0.35

local function ease(t) t = math.clamp(t, 0, 1) return t * t * (3 - 2 * t) end
local function lerpPose(a, b, t)
	local out = {}
	for i = 1, 6 do out[i] = a[i] + (b[i] - a[i]) * t end
	return out
end
local ZERO = { 0, 0, 0, 0, 0, 0 }

-- Pose weight curve for a given time since ToolActionAt.
local function poseAt(style, windup, age)
	local p = POSES[style]
	if not p then return nil end
	if age < 0 then return nil end
	if age < windup then return lerpPose(ZERO, p.a, ease(age / math.max(windup, 0.05))) end
	age -= windup
	if age < STRIKE then return lerpPose(p.a, p.b, ease(age / STRIKE) ^ 0.6) end
	age -= STRIKE
	if age < p.hold then return p.b end
	age -= p.hold
	if age < RECOVER then return lerpPose(p.b, ZERO, ease(age / RECOVER)) end
	return nil
end

local function joints(character)
	local function motor(partName, motorName)
		local part = character:FindFirstChild(partName)
		local m = part and part:FindFirstChild(motorName)
		return if m and m:IsA("Motor6D") then m else nil
	end
	local r15 = motor("RightUpperArm", "RightShoulder")
	if r15 then
		return {
			rig = "R15", shoulder = r15, elbow = motor("RightLowerArm", "RightElbow"),
			waist = motor("UpperTorso", "Waist"), left = motor("LeftUpperArm", "LeftShoulder"),
		}
	end
	local r6 = motor("Torso", "Right Shoulder")
	if r6 then return { rig = "R6", shoulder = r6, left = motor("Torso", "Left Shoulder") } end
	return nil
end

function Animator.start()
	local player = Players.LocalPlayer
	local tracked = {}

	local function apply(character, j, pose)
		if j.rig == "R15" then
			if j.shoulder then j.shoulder.Transform *= CFrame.Angles(pose[1], 0, -pose[2]) end
			if j.elbow then j.elbow.Transform *= CFrame.Angles(pose[3], 0, 0) end
			if j.waist then j.waist.Transform *= CFrame.Angles(pose[5], pose[4], 0) end
			if j.left and pose[6] ~= 0 then j.left.Transform *= CFrame.Angles(pose[6], 0, pose[2] * 0.5) end
		else
			if j.shoulder then j.shoulder.Transform *= CFrame.Angles(0, 0, pose[1]) end
			if j.left and pose[6] ~= 0 then j.left.Transform *= CFrame.Angles(0, 0, -pose[6]) end
		end
	end

	RunService.PreSimulation:Connect(function()
		local now = workspace:GetServerTimeNow()
		for character, entry in tracked do
			if not character.Parent then tracked[character] = nil continue end
			local id = character:GetAttribute("ToolActionId")
			local at = character:GetAttribute("ToolActionAt")
			if typeof(id) ~= "string" or typeof(at) ~= "number" or character:GetAttribute("Ragdolled") then continue end
			local windup = character:GetAttribute("ToolActionWindup") or 0.2
			local pose = poseAt(STYLE[id], windup, now - at)
			if not pose then continue end
			entry.joints = entry.joints or joints(character)
			if entry.joints then apply(character, entry.joints, pose) end
		end
	end)

	local function track(character)
		tracked[character] = {}
		character.DescendantAdded:Connect(function() if tracked[character] then tracked[character].joints = nil end end)
	end
	local function watch(p)
		p.CharacterAdded:Connect(track)
		if p.Character then track(p.Character) end
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in Players:GetPlayers() do watch(p) end

	-- Local ragdoll state: the server owns physics, the owner humanoid must not
	-- try to stand until recovery.
	local function ownCharacter(character)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if not humanoid then return end
		character:GetAttributeChangedSignal("Ragdolled"):Connect(function()
			if character:GetAttribute("Ragdolled") then
				humanoid:ChangeState(Enum.HumanoidStateType.Physics)
				-- Victim feedback: a short downward camera kick, no long shake.
				local camera = workspace.CurrentCamera
				if camera then
					local fov = camera.FieldOfView
					camera.FieldOfView = fov + 6
					TweenService:Create(camera, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { FieldOfView = fov }):Play()
				end
			else
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end)
	end
	player.CharacterAdded:Connect(ownCharacter)
	if player.Character then task.spawn(ownCharacter, player.Character) end

	-- Attacker feedback: a tiny FOV punch when your shovel lands.
	task.spawn(function()
		local remote = ReplicatedStorage:WaitForChild("ToolsFoundation", 60)
		local effect = remote and remote:WaitForChild("Effect", 30)
		if not effect then return end
		effect.OnClientEvent:Connect(function(id, _, data)
			if id == "shovel_hit" and typeof(data) == "table" and data.userId == player.UserId then
				local camera = workspace.CurrentCamera
				if camera then
					local fov = camera.FieldOfView
					camera.FieldOfView = fov - 4
					TweenService:Create(camera, TweenInfo.new(0.25, Enum.EasingStyle.Back), { FieldOfView = fov }):Play()
				end
			end
		end)
	end)
end

return Animator
