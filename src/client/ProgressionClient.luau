-- Client side of progression: prompts, Mortimer's idle life and reactions,
-- the "!" / "?" indicator, cinematics, Wheel pranks. Server owns all rules.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local VisualAssets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VisualAssets"))
local Theme = require(script.Parent.UI.Theme)
local MissionDialog = require(script.Parent.UI.MissionDialog)
local WheelPanel = require(script.Parent.UI.WheelPanel)
local Cinematics = require(script.Parent.Cinematics)
local C, F = Theme.colors, Theme.fonts

local Client = {}

function Client.start()
	local player = Players.LocalPlayer
	local folder = ReplicatedStorage:WaitForChild("Progression", 60)
	if not folder then return end
	local request = folder:WaitForChild("Request")
	local gui = Theme.make("ScreenGui", {
		Name = "ProgressionUI", ResetOnSpawn = false, DisplayOrder = 12, ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, player:WaitForChild("PlayerGui"))
	local state = nil
	local dialog = MissionDialog.start(gui, request, function(s) state = s end)
	local wheel = WheelPanel.start(gui, request, function(answer)
		if answer.state then state = answer.state dialog.setState(state) end
	end)
	local function fit() wheel.fit(gui.AbsoluteSize) end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()

	local function apply(s)
		state = s
		dialog.setState(s)
		wheel.setState(s)
	end
	folder:WaitForChild("Changed").OnClientEvent:Connect(apply)
	task.spawn(function()
		local ok, answer = pcall(function() return request:InvokeServer("state") end)
		if ok and answer and answer.state then apply(answer.state) end
	end)

	---------------------------------------------------------------- world hooks
	local map = workspace:WaitForChild("StealACurseMap", 60)
	local npcFolder = map and map:WaitForChild("MortimerTheGravekeeper", 30)
	local npc = npcFolder and npcFolder:WaitForChild("Mortimer", 10)
	local wheelModel = map and map:WaitForChild("WheelOfFate", 30)
	if npc then
		local root = npc:WaitForChild("HumanoidRootPart")
		local prompt = root:WaitForChild("TalkToMortimer", 10)
		if prompt then prompt.Triggered:Connect(function() dialog.open(state) end) end
		-- Indicator: "!" when a task is offered, "?" when one is ready to claim.
		local mark = Theme.make("BillboardGui", { Name = "MissionMark", Adornee = npc:FindFirstChild("Head"), Size = UDim2.fromOffset(44, 54), StudsOffsetWorldSpace = Vector3.new(0, 5, 0), LightInfluence = 0, MaxDistance = 140, AlwaysOnTop = false }, gui)
		local markText = Theme.label(mark, "Mark", "!", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 46, C.amber, F.number)
		markText.TextXAlignment = Enum.TextXAlignment.Center
		Theme.make("UIStroke", { Color = Color3.fromRGB(40, 16, 4), Thickness = 3 }, markText)
		local name = Theme.make("BillboardGui", { Name = "NpcName", Adornee = npc:FindFirstChild("Head"), Size = UDim2.fromOffset(200, 40), StudsOffsetWorldSpace = Vector3.new(0, 2.4, 0), LightInfluence = 0, MaxDistance = 45 }, gui)
		local nameText = Theme.label(name, "Name", "MORTIMER", UDim2.fromScale(0, 0), UDim2.new(1, 0, 0, 22), 20, Color3.fromRGB(255, 226, 170), F.display)
		nameText.TextXAlignment = Enum.TextXAlignment.Center
		Theme.make("UIStroke", { Color = C.ink, Thickness = 2 }, nameText)
		local titleText = Theme.label(name, "Title", "The Gravekeeper", UDim2.fromOffset(0, 22), UDim2.new(1, 0, 0, 16), 12, C.muted, F.bold)
		titleText.TextXAlignment = Enum.TextXAlignment.Center
		Theme.make("UIStroke", { Color = C.ink, Thickness = 1.5 }, titleText)

		-- Idle life: breathing, slow head tracking, lantern sway, rare gesture.
		local motors = {}
		for _, m in npc:GetDescendants() do if m:IsA("Motor6D") then motors[m.Name] = m end end
		local reactUntil = 0
		RunService.PreSimulation:Connect(function()
			local t = os.clock()
			local camera = workspace.CurrentCamera
			if not camera or (camera.CFrame.Position - root.Position).Magnitude > 120 then return end
			local breathe = math.sin(t * 1.6)
			if motors.Waist then motors.Waist.Transform = CFrame.Angles(0.04 + breathe * 0.025, math.sin(t * 0.3) * 0.05, 0) end
			-- Head follows the local player when near, otherwise scans slowly.
			local look = 0
			local character = player.Character
			local pr = character and character:FindFirstChild("HumanoidRootPart")
			if pr and (pr.Position - root.Position).Magnitude < 22 then
				local rel = root.CFrame:PointToObjectSpace(pr.Position)
				look = math.clamp(math.atan2(-rel.X, -rel.Z), -0.7, 0.7)
			else
				look = math.sin(t * 0.25) * 0.35
			end
			if motors.Neck then motors.Neck.Transform = CFrame.Angles(-0.05 + breathe * 0.02, look, 0) end
			local react = math.clamp((reactUntil - t) / 1.2, 0, 1)
			if motors.RightShoulder then motors.RightShoulder.Transform = CFrame.Angles(0.35 + math.sin(t * 1.1) * 0.06 + react * 1.6, 0, 0.08) end
			if motors.LeftShoulder then motors.LeftShoulder.Transform = CFrame.Angles(0.05 + math.sin(t * 1.3 + 1) * 0.03, 0, -0.05 - react * 0.6) end
			-- Rare signature: a slow hat tip every ~14 s.
			local tip = (t % 14) < 1.4 and math.sin((t % 14) / 1.4 * math.pi) or 0
			if motors.Neck then motors.Neck.Transform *= CFrame.Angles(tip * 0.25, 0, 0) end
		end)
		RunService.Heartbeat:Connect(function()
			local s = state
			local m = s and s.mission
			local markKind = if (m and m.complete) or (s and s.event and s.event.complete) then "?" elseif m and not m.accepted then "!" else nil
			mark.Enabled = markKind ~= nil
			markText.Text = markKind or ""
			markText.TextColor3 = if markKind == "?" then C.soulGreen else C.amber
			markText.Position = UDim2.fromOffset(0, math.sin(os.clock() * 3) * 3)
		end)
		Client.react = function() reactUntil = os.clock() + 1.2 end
	end
	if wheelModel then
		-- Paint the real sectors on the physical wheel (front end-cap of the disc).
		local face = wheelModel:WaitForChild("WheelFace", 10)
		if face then
			local Config = require(ReplicatedStorage.Shared.ProgressionConfig)
			local surface = Theme.make("SurfaceGui", { Name = "Sectors", Face = Enum.NormalId.Right, CanvasSize = Vector2.new(512, 512), LightInfluence = 0.6, Adornee = face, ResetOnSpawn = false }, gui)
			local step = 360 / #Config.Wheel.Sectors
			for i, s in Config.Wheel.Sectors do
				Theme.image(surface, "Sector" .. i, VisualAssets.Textures.wheel_wedge, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), { ImageColor3 = Config.WheelRarityColors[s.rarity], Rotation = (i - 1) * step })
				local a = math.rad((i - 1) * step)
				Theme.image(surface, "Icon" .. i, VisualAssets.Icons[s.icon] or VisualAssets.Icons.soul, UDim2.fromScale(0.5 + math.sin(a) * 0.33, 0.5 - math.cos(a) * 0.33), UDim2.fromScale(0.16, 0.16), { AnchorPoint = Vector2.new(0.5, 0.5), Rotation = (i - 1) * step })
			end
		end
		local base = wheelModel:WaitForChild("Plinth", 10)
		local prompt = base and base:WaitForChild("SpinWheel", 10)
		if prompt then
			prompt.Triggered:Connect(function()
				wheel.show(true)
				local ok, answer = pcall(function() return request:InvokeServer("state") end)
				if ok and answer and answer.state then apply(answer.state) end
			end)
		end
		-- Prompt text reflects the free spin.
		RunService.Heartbeat:Connect(function()
			if prompt and state and state.wheel then
				prompt.ActionText = if state.wheel.freeAvailable then "Free spin!" elseif state.wheel.bonusSpins > 0 then "Spin (" .. state.wheel.bonusSpins .. ")" else "Wheel of Fate"
			end
		end)
	end

	---------------------------------------------------------------- cinematics
	local CINEMATICS = {
		first_binding = function()
			local base = map and player:GetAttribute("ClaimedBaseId") and map.PlayerSanctuaries:FindFirstChild(player:GetAttribute("ClaimedBaseId"))
			local altar = base and base:FindFirstChild("RestorationAltar", true)
			local target = if altar and altar:IsA("BasePart") then altar.Position elseif npc then npc.HumanoidRootPart.Position else nil
			if not target then return nil end
			return {
				{ kind = "shot", from = CFrame.lookAt(target + Vector3.new(26, 18, 26), target), to = CFrame.lookAt(target + Vector3.new(12, 7, 14), target + Vector3.new(0, 2, 0)), seconds = 2.6 },
				{ kind = "caption", text = "Your shrine has awakened", seconds = 2.2 },
				{ kind = "wait", seconds = 1.6 },
			}
		end,
		wheel_unlock = function()
			local face = wheelModel and wheelModel:FindFirstChild("WheelFace")
			if not face then return nil end
			local p = face.Position
			local forward = face.CFrame.RightVector -- cylinder axis faces out
			return {
				{ kind = "shot", from = CFrame.lookAt(p + forward * 34 + Vector3.new(0, 10, 0), p), to = CFrame.lookAt(p + forward * 14 + Vector3.new(0, 2, 0), p), seconds = 2.8 },
				{ kind = "caption", text = "The Wheel of Fate awakens", seconds = 2.4 },
				{ kind = "call", fn = function()
					local value = Instance.new("NumberValue")
					local base = face:GetAttribute("BaseCFrame")
					value.Changed:Connect(function(v) if base then face.CFrame = base * CFrame.Angles(math.rad(v), 0, 0) end end)
					game:GetService("TweenService"):Create(value, TweenInfo.new(2.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Value = 720 }):Play()
					Debris:AddItem(value, 3)
				end },
				{ kind = "wait", seconds = 2.2 },
			}
		end,
	}
	folder:WaitForChild("Cinematic").OnClientEvent:Connect(function(id)
		if Client.react then Client.react() end
		local build = CINEMATICS[id]
		local steps = build and build()
		if steps then task.delay(0.6, function() Cinematics.play(steps) end) end
	end)

	---------------------------------------------------------------- Wheel pranks (harmless, local)
	local function bats()
		local character = player.Character
		local r = character and character:FindFirstChild("HumanoidRootPart")
		if not r then return end
		local a = Instance.new("Attachment")
		a.Parent = r
		Debris:AddItem(a, 4)
		local e = Instance.new("ParticleEmitter")
		e.Texture = VisualAssets.Textures.crescent
		e.Color = ColorSequence.new(Color3.fromRGB(40, 20, 50))
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0.2) })
		e.Speed = NumberRange.new(6, 10)
		e.SpreadAngle = Vector2.new(180, 60)
		e.Lifetime = NumberRange.new(1, 1.6)
		e.RotSpeed = NumberRange.new(-300, 300)
		e.Rate = 0
		e.Parent = a
		e:Emit(18)
	end
	player:GetAttributeChangedSignal("WheelPrank"):Connect(function()
		local prank = player:GetAttribute("WheelPrank")
		local untilAt = player:GetAttribute("WheelPrankUntil") or 0
		local delayFor = math.max(0, untilAt - 15 - workspace:GetServerTimeNow())
		task.delay(delayFor, function()
			if prank == "laugh" then bats() dialog.toast("The spirits laughed at you.", false)
			elseif prank == "heavy_feet" then dialog.toast("Heavy feet! (15s)", false) end
		end)
	end)
end

return Client
