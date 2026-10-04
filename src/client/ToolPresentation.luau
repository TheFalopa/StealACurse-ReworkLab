-- Client presentation of tool effects (ToolsFoundation.Effect). Pure visuals:
-- authoritative zones live in StealACurseMap.ToolEffects and are never read
-- from these particles. One-shot bursts are pooled per effect and cleaned with
-- Debris; persistent mist follows its zone's lifetime.
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local VisualAssets = require(RS:WaitForChild("Shared"):WaitForChild("VisualAssets"))
local T = VisualAssets.Textures

local P = {}

-- Replaceable sound cues (built-in client sounds until original audio exists).
P.Sounds = {
	shovel_hit = { id = "rbxasset://sounds/action_jump_land.mp3", volume = 0.9, pitch = 0.75 },
	shovel_block = { id = "rbxasset://sounds/action_jump_land.mp3", volume = 0.5, pitch = 1.3 },
	impact = { id = "rbxasset://sounds/impact_explosion_03.mp3", volume = 0.35, pitch = 1.15 },
	decoy_break = { id = "rbxasset://sounds/impact_explosion_03.mp3", volume = 0.2, pitch = 2 },
}

local RANGE = 140

local function seq(points)
	if typeof(points) == "number" then return NumberSequence.new(points) end
	local k = {}
	for _, p in points do table.insert(k, NumberSequenceKeypoint.new(p[1], p[2])) end
	return NumberSequence.new(k)
end

function P.start()
	local remote = RS:WaitForChild("ToolsFoundation")
	local folder = Instance.new("Folder")
	folder.Name = "LocalToolEffects"
	folder.Parent = workspace

	local function anchor(at: Vector3, life: number)
		local a = Instance.new("Attachment")
		a.Name = "ToolFX"
		a.WorldPosition = at
		a.Parent = workspace.Terrain
		Debris:AddItem(a, life + 0.5)
		return a
	end
	local function burst(at, count, props, life)
		local a = anchor(at, life or 2)
		local e = Instance.new("ParticleEmitter")
		e.Rate = 0
		e.LightInfluence = 0
		for k, v in props do e[k] = v end
		e.Parent = a
		e:Emit(count)
		return a, e
	end
	local function sound(id, at)
		local cue = P.Sounds[id]
		if not cue then return end
		local a = anchor(at, 3)
		local s = Instance.new("Sound")
		s.SoundId = cue.id
		s.Volume = cue.volume
		s.PlaybackSpeed = cue.pitch
		s.RollOffMaxDistance = 90
		s.Parent = a
		s:Play()
	end

	-- Shared looks.
	local function dust(at, count, scale, color)
		burst(at, count, {
			Texture = T.wisp, Color = ColorSequence.new(color or Color3.fromRGB(150, 138, 120)),
			Size = seq({ { 0, 0.8 * scale }, { 1, 2.6 * scale } }), Transparency = seq({ { 0, 0.35 }, { 1, 1 } }),
			Lifetime = NumberRange.new(0.6, 1), Speed = NumberRange.new(4 * scale, 9 * scale), SpreadAngle = Vector2.new(70, 70),
			Drag = 4, Acceleration = Vector3.new(0, 2, 0), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-90, 90),
			EmissionDirection = Enum.NormalId.Top,
		})
	end
	local function sparks(at, count, color, size)
		burst(at, count, {
			Texture = T.spark, Color = ColorSequence.new(color), LightEmission = 1,
			Size = seq({ { 0, size or 0.9 }, { 1, 0 } }), Lifetime = NumberRange.new(0.15, 0.3), Speed = NumberRange.new(0, 0.5),
			Rotation = NumberRange.new(0, 90),
		})
	end
	local function chips(at, count, color)
		burst(at, count, {
			Texture = T.shard, Color = ColorSequence.new(color or Color3.new(1, 1, 1)),
			Size = seq({ { 0, 0.35 }, { 1, 0.2 } }), Lifetime = NumberRange.new(0.5, 0.8), Speed = NumberRange.new(8, 14),
			SpreadAngle = Vector2.new(60, 60), Acceleration = Vector3.new(0, -40, 0), Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-400, 400), EmissionDirection = Enum.NormalId.Top,
		})
	end
	local function motes(at, count, color, up)
		burst(at, count, {
			Texture = T.mote, Color = ColorSequence.new(color), LightEmission = 1,
			Size = seq({ { 0, 0.35 }, { 1, 0 } }), Lifetime = NumberRange.new(0.6, 1.1), Speed = NumberRange.new(2, 5),
			SpreadAngle = Vector2.new(50, 50), Acceleration = Vector3.new(0, up or 4, 0), Drag = 1.5,
			EmissionDirection = Enum.NormalId.Top,
		})
	end

	local active = {}
	remote.Effect.OnClientEvent:Connect(function(id, at, data)
		local camera = workspace.CurrentCamera
		if typeof(at) ~= "Vector3" or not camera or (camera.CFrame.Position - at).Magnitude > RANGE then return end
		data = if typeof(data) == "table" then data else {}
		local life = data.duration or 0.45
		local made = {}
		if id == "shovel_hit" then
			dust(at - Vector3.new(0, 2, 0), 10, 1)
			sparks(at + Vector3.new(0, 1, 0), 2, Color3.fromRGB(255, 238, 200), 2.6)
			chips(at, 6, Color3.fromRGB(120, 110, 100))
			sound("shovel_hit", at)
		elseif id == "shovel_block" then
			sparks(at + Vector3.new(0, 1, 0), 2, Color3.fromRGB(180, 230, 255), 1.6)
			sound("shovel_block", at)
		elseif id == "swing" then
			burst(at, 4, {
				Texture = T.streak, Color = ColorSequence.new(Color3.fromRGB(220, 220, 230)), LightEmission = 0.4,
				Size = seq({ { 0, 0.5 }, { 1, 0 } }), Squash = seq(1.5), Lifetime = NumberRange.new(0.15, 0.22),
				Speed = NumberRange.new(10, 14), SpreadAngle = Vector2.new(40, 10), Orientation = Enum.ParticleOrientation.VelocityParallel,
				Transparency = seq({ { 0, 0.4 }, { 1, 1 } }),
			})
		elseif id == "impact" then
			local r = math.min(data.radius or 6, 12)
			dust(at, 18, r / 6)
			sparks(at + Vector3.new(0, 1, 0), 2, Color3.fromRGB(255, 180, 110), 4)
			chips(at, 10, Color3.fromRGB(150, 80, 55))
			sound("impact", at)
		elseif id == "decoy_break" then
			chips(at + Vector3.new(0, 2, 0), 14, Color3.fromRGB(170, 220, 230))
			motes(at + Vector3.new(0, 2, 0), 10, Color3.fromRGB(170, 230, 240), 1)
			sound("decoy_break", at)
		elseif id == "chain" then
			local finish = data.finish
			if typeof(finish) == "Vector3" then
				local a0, a1 = anchor(at, life), anchor(finish, life)
				local beam = Instance.new("Beam")
				beam.Attachment0, beam.Attachment1 = a0, a1
				beam.Texture = T.streak
				beam.TextureMode = Enum.TextureMode.Wrap
				beam.TextureLength = 0.6
				beam.TextureSpeed = 4
				beam.Width0, beam.Width1 = 0.35, 0.25
				beam.Color = ColorSequence.new(Color3.fromRGB(190, 170, 140), Color3.fromRGB(120, 110, 100))
				beam.LightInfluence = 0.3
				beam.FaceCamera = true
				beam.Parent = a0
				sparks(finish, 1, Color3.fromRGB(255, 230, 190), 1.8)
			end
		elseif id == "chain_lost" then
			dust(at, 8, 0.8, Color3.fromRGB(150, 160, 170))
		elseif id == "mist_censer" then
			local center = at + Vector3.new(0, 2.5, 0)
			local a = anchor(center, life)
			local e = Instance.new("ParticleEmitter")
			e.Texture = T.wisp
			e.Color = ColorSequence.new(Color3.fromRGB(150, 158, 170))
			e.Size = seq({ { 0, 5 }, { 1, 9 } })
			e.Transparency = seq({ { 0, 1 }, { 0.25, 0.55 }, { 0.75, 0.6 }, { 1, 1 } })
			e.Lifetime = NumberRange.new(2.5, 3.5)
			e.Rate = 14
			e.Speed = NumberRange.new(1, 3)
			e.SpreadAngle = Vector2.new(180, 30)
			e.Rotation = NumberRange.new(0, 360)
			e.RotSpeed = NumberRange.new(-12, 12)
			e.LightInfluence = 0.6
			e.Parent = a
			task.delay(math.max(0, life - 2), function() e.Enabled = false end)
			table.insert(made, a)
		elseif id == "consecrated_salt" then
			motes(at, 16, Color3.fromRGB(240, 232, 200), 0.5)
		elseif id == "root_trap" then
			dust(at, 4, 0.5, Color3.fromRGB(90, 70, 50))
		elseif id == "roots" then
			chips(at, 8, Color3.fromRGB(110, 80, 50))
			dust(at - Vector3.new(0, 2, 0), 6, 0.7, Color3.fromRGB(100, 85, 60))
		elseif id == "disarm" then
			sparks(at, 1, Color3.fromRGB(220, 240, 200), 2)
		elseif id == "cleanse" then
			motes(at, 18, Color3.fromRGB(150, 245, 230), 6)
			sparks(at + Vector3.new(0, 1, 0), 1, Color3.fromRGB(200, 255, 250), 3)
		elseif id == "lantern" then
			local a = anchor(at + Vector3.new(0, 2, 0), 1)
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(170, 240, 220)
			light.Range = 24
			light.Brightness = 3
			light.Shadows = false
			light.Parent = a
			TweenService:Create(light, TweenInfo.new(0.9), { Brightness = 0, Range = 34 }):Play()
			motes(at + Vector3.new(0, 1.5, 0), 20, Color3.fromRGB(170, 240, 220), 2)
		elseif id == "reveal" then
			local map = workspace:FindFirstChild("StealACurseMap")
			local world = map and map:FindFirstChild("ToolEffects")
			local target = world and typeof(data.token) == "string" and world:FindFirstChild(data.token)
			if target then
				local h = Instance.new("Highlight")
				h.Name = "ToolReveal"
				h.Adornee = target
				h.FillTransparency = 0.75
				h.FillColor = Color3.fromRGB(120, 240, 220)
				h.OutlineColor = Color3.fromRGB(200, 255, 245)
				h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				h.Parent = folder
				Debris:AddItem(h, life)
			end
		elseif id == "ash_boots" then
			local player = Players:GetPlayerByUserId(data.userId or 0)
			local c = player and player.Character
			if c then
				for _, name in { "LeftFoot", "RightFoot", "Left Leg", "Right Leg" } do
					local foot = c:FindFirstChild(name)
					if foot then
						local a = Instance.new("Attachment")
						a.Name = "ToolAshHook"
						a.Parent = foot
						Debris:AddItem(a, life)
						local e = Instance.new("ParticleEmitter")
						e.Name = "ToolAsh"
						e.Texture = T.ember
						e.Color = ColorSequence.new(Color3.fromRGB(255, 170, 110), Color3.fromRGB(90, 80, 75))
						e.LightEmission = 0.8
						e.Rate = 24
						e.Lifetime = NumberRange.new(0.3, 0.6)
						e.Speed = NumberRange.new(0.5, 2)
						e.Size = seq({ { 0, 0.3 }, { 1, 0 } })
						e.Acceleration = Vector3.new(0, 3, 0)
						e.Parent = a
					end
				end
			end
		end
		if data.token then active[data.token] = made end
	end)
	-- Persistent effects disappear with their authoritative zone (death,
	-- unequip, expiry). One observer, no per-zone loops.
	task.spawn(function()
		local map = workspace:WaitForChild("StealACurseMap")
		local world = map:WaitForChild("ToolEffects")
		world.ChildRemoved:Connect(function(model)
			local token = model:GetAttribute("EffectToken")
			local list = token and active[token]
			if list then for _, v in list do v:Destroy() end active[token] = nil end
		end)
	end)
end

return P
