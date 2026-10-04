-- Real test client input and observations. This does not create presentation
-- stand-ins or invoke server purchase/delivery handlers directly.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local Catalog = require(ReplicatedStorage.Shared.CurseCatalog)
local Profiles = require(ReplicatedStorage.Shared.CurseVFXProfiles)
local control = ReplicatedStorage:WaitForChild("CurseReworkTestControl")
local stressModels = {}
local function await(predicate, timeout)
	local deadline = os.clock() + timeout
	repeat if predicate() then return true end; task.wait(0.05) until os.clock() > deadline
	return false
end
local function inspect(target)
	local model = target.model
	assert(await(function() return model and model.PrimaryPart and model.PrimaryPart:FindFirstChild("CurseVFXHook") end, 8), "Client root/VFX hook replication timed out")
	local root = model.PrimaryPart
	local id = model:GetAttribute("CurseId")
	local profile = Profiles.Definitions[id]
	assert(profile ~= nil and Catalog.Definitions[id].isExpansion, "Current concept profile missing on client")
	local camera = workspace.CurrentCamera
	local previousType, previousFrame = camera.CameraType, camera.CFrame
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(root.CFrame:PointToWorldSpace(Vector3.new(9, 3, -9)), root.Position)
	local ok, result = pcall(function()
		local hook = root.CurseVFXHook
		assert(await(function() return hook:FindFirstChild("ConceptParticles") and hook:FindFirstChild("ConceptFocus") end, 8), "Production client VFX did not attach")
		local emitter, focus = hook.ConceptParticles, hook.ConceptFocus
		local semanticHooks = {}
		assert(await(function()
			for name in Catalog.Definitions[id].vfxHooks or {} do
				if not root:FindFirstChild("VFX_" .. name) then return false end
			end
			return true
		end, 5), "Authored semantic attachment replication timed out: " .. id)
		for name, expected in Catalog.Definitions[id].vfxHooks or {} do
			local attachment = root:FindFirstChild("VFX_" .. name)
			assert(attachment and attachment:IsA("Attachment") and (attachment.Position - expected).Magnitude < .001,
				"Authored semantic VFX hook differs on client: " .. id .. "/" .. name)
			semanticHooks[name] = { attachment.Position.X, attachment.Position.Y, attachment.Position.Z }
		end
		assert(emitter:IsA("ParticleEmitter") and focus:IsA("SphereHandleAdornment"), "Incorrect native VFX classes")
		assert(await(function() return emitter.Rate > 0 and focus.Visible end, 3), "Near-camera production VFX budget did not activate")
		local emitters, lights, focuses = 0, 0, 0
		for _, item in model:GetDescendants() do
			if item:IsA("ParticleEmitter") then emitters += 1 end
			if item:IsA("PointLight") then lights += 1 end
			if item:IsA("SphereHandleAdornment") then focuses += 1 end
		end
		assert(emitters == 1 and focuses == 1 and lights <= 1, "Production concept VFX instance count differs")
		local glassPanes = 0
		if id == "thorn_reliquary" then
			for _, item in model:GetDescendants() do
				if item:IsA("BasePart") and string.find(item.Name, "ReliquaryGlass_", 1, true) then
					assert(item.Material == Enum.Material.Glass and not item.CanCollide and not item.CanTouch and not item.CanQuery,
						"Reliquary native glass must stay visual and noncolliding")
					glassPanes += 1
				end
			end
			assert(glassPanes == 4, "Reliquary needs four actual native glass panes")
		end
		local samples, positionMin, positionMax, opacityMin, opacityMax = 0, hook.Position, hook.Position, 1, 0
		local rateMin, rateMax, pausedSamples, emittingSamples = math.huge, 0, 0, 0
		local semanticVisits = {}
		local firstRoot = root.Position
		local observationAt = os.clock()
		local deadline = observationAt + 4.2
		while os.clock() < deadline do
			RunService.Heartbeat:Wait(); samples += 1
			positionMin = Vector3.new(math.min(positionMin.X, hook.Position.X), math.min(positionMin.Y, hook.Position.Y), math.min(positionMin.Z, hook.Position.Z))
			positionMax = Vector3.new(math.max(positionMax.X, hook.Position.X), math.max(positionMax.Y, hook.Position.Y), math.max(positionMax.Z, hook.Position.Z))
			opacityMin = math.min(opacityMin, focus.Transparency); opacityMax = math.max(opacityMax, focus.Transparency)
			rateMin = math.min(rateMin, emitter.Rate); rateMax = math.max(rateMax, emitter.Rate)
			if emitter.Rate > 0 then emittingSamples += 1 else pausedSamples += 1 end
			for name, position in semanticHooks do
				if (hook.Position - Vector3.new(position[1], position[2], position[3])).Magnitude < .25 then semanticVisits[name] = true end
			end
		end
		local observedSeconds = os.clock() - observationAt
		assert(samples > 10 and ((positionMax - positionMin).Magnitude > 0.005 or opacityMax - opacityMin > 0.015), "Production VFX motion/pulse was not observed")
		assert(emittingSamples > 0 and rateMax > 0, "Actual near-camera particles never emitted")
		if profile.motion == "heartbeat" or profile.motion == "tick" then
			assert(rateMin > 0 and rateMax > rateMin * 1.5, "Actual rhythmic emitter did not alternate its low and burst rates")
		elseif profile.motion == "silence" or profile.motion == "erase" then
			assert(pausedSamples > 0 and emittingSamples > 0 and rateMin == 0, "Actual interrupted emitter did not pause and resume over its full cycle")
		end
		if profile.motion == "choir" then
			assert(semanticVisits.leftHead and semanticVisits.middleHead and semanticVisits.rightHead, "Actual choir effect did not visit all three authored heads")
		elseif profile.motion == "scales" then
			assert(semanticVisits.leftPan and semanticVisits.rightPan, "Actual scales effect did not visit both authored pans")
		elseif profile.motion == "gramophone" then
			-- The turntable orbit has a radius, so observe a genuine transition
			-- away from the authored horn mouth without recreating its orbit math.
			assert(semanticVisits.hornMouth and (positionMax - positionMin).Magnitude > .4,
				"Actual gramophone effect did not alternate horn and turntable phrase")
		end
		assert(model:GetAttribute("CurseState") == target.state, "Unexpected state during client inspection")
		local info = model:FindFirstChild("CurseInfo")
		assert(info and info.Adornee == root and info.Enabled, "Current Curse label must be visible from inspection position")
		local fields = {}
		for _, name in { "InfoName", "InfoRarity", "InfoIncome", "InfoPrice" } do
			local field = info.Panel:FindFirstChild(name)
			assert(field and field:IsA("TextLabel") and #field.Text > 0, "Missing client label text: " .. name)
			assert(field.AbsoluteSize.X > 0 and field.AbsoluteSize.Y > 0, "Label has no rendered bounds: " .. name)
			assert(field.TextBounds.X <= field.AbsoluteSize.X + 2 and field.TextBounds.Y <= field.AbsoluteSize.Y + 2, "Label text exceeds its rendered field: " .. id .. "/" .. name)
			fields[name] = { text = field.Text, width = field.AbsoluteSize.X, height = field.AbsoluteSize.Y,
				textWidth = field.TextBounds.X, textHeight = field.TextBounds.Y }
		end
		assert(info.Panel.InfoName.Text == string.upper(Catalog.Definitions[id].displayName), "Display identity differs from catalog")
		if (target.holdSeconds or 0) > 0 then task.wait(target.holdSeconds) end
		return { id = id, state = target.state, nativeEmitterCount = emitters, nativeLightCount = lights,
			nativeFocusCount = focuses, particleRate = emitter.Rate, particleTexture = emitter.Texture,
			profileMotion = profile.motion, samples = samples, hookMovementStuds = (positionMax - positionMin).Magnitude,
			semanticHookPositions = semanticHooks,
			semanticHookVisits = semanticVisits, nativeGlassPaneCount = glassPanes,
			observedSeconds = observedSeconds, reviewHoldSeconds = target.holdSeconds or 0,
			particleRateMin = rateMin, particleRateMax = rateMax,
			pausedSamples = pausedSamples, emittingSamples = emittingSamples,
			pulseRange = opacityMax - opacityMin, rootMovementStuds = (root.Position - firstRoot).Magnitude,
			labelFields = fields, fbxSha256 = model:GetAttribute("FbxSha256") }
	end)
	camera.CameraType = previousType; camera.CFrame = previousFrame
	if not ok then error(result) end
	return result
end

local function stress(target)
	stressModels = target.models
	local mobile = UserInputService.TouchEnabled
	if target.expectMobile then assert(mobile, "Mobile stress requires TouchEnabled before production client initialization; start with Studio device emulation") end
	assert(#stressModels == 46, "Stress client did not receive forty displays plus six actual offers")
	assert(await(function()
		for _, model in stressModels do
			local root = model and model.PrimaryPart; local hook = root and root:FindFirstChild("CurseVFXHook")
			if not hook or not hook:FindFirstChild("ConceptParticles") or not hook:FindFirstChild("ConceptFocus") then return false end
		end
		return true
	end, 10), "All 46 actual native presentation effects must replicate")
	local camera = workspace.CurrentCamera
	local previousType, previousFrame = camera.CameraType, camera.CFrame
	camera.CameraType = Enum.CameraType.Scriptable
	local function sampleCounts()
		local result = { emitters = 0, activeEmitters = 0, lights = 0, activeLights = 0,
			focuses = 0, visibleFocuses = 0, nativeGlassPanes = 0, totalParticleRate = 0,
			billboards = 0, enabledBillboards = 0 }
		for _, model in stressModels do
			for _, item in model:GetDescendants() do
				if item:IsA("ParticleEmitter") then
					result.emitters += 1
					if item.Enabled and item.Rate > 0 then result.activeEmitters += 1; result.totalParticleRate += item.Rate end
				elseif item:IsA("PointLight") then
					result.lights += 1; if item.Enabled and item.Brightness > 0 then result.activeLights += 1 end
				elseif item:IsA("SphereHandleAdornment") then
					result.focuses += 1; if item.Visible then result.visibleFocuses += 1 end
				elseif item:IsA("BillboardGui") then
					result.billboards += 1; if item.Enabled then result.enabledBillboards += 1 end
				elseif item:IsA("BasePart") and string.find(item.Name, "ReliquaryGlass_", 1, true) then result.nativeGlassPanes += 1 end
			end
		end
		return result
	end
	local function observe(name, frame)
		camera.CFrame = frame; task.wait(1)
		local frames, timing, samples = {}, { sum = 0, maximum = 0, over33ms = 0, over50ms = 0 }, 0
		local maximumActive, minimumActive, maximumLights, maximumRate = 0, math.huge, 0, 0
		local elapsed, observationAt = 0, os.clock()
		local finalCounts
		while os.clock() - observationAt < 15 do
			local dt = RunService.RenderStepped:Wait()
			table.insert(frames, dt); timing.sum += dt; timing.maximum = math.max(timing.maximum, dt)
			if dt > 1/30 then timing.over33ms += 1 end
			if dt > .05 then timing.over50ms += 1 end
			elapsed += dt
			if elapsed >= .1 then
				elapsed = 0; samples += 1; local counts = sampleCounts(); finalCounts = counts
				assert(counts.emitters == 46 and counts.focuses == 46, "46-active native effect instance count changed")
				assert(counts.activeEmitters <= (if mobile then 12 else 20) and counts.visibleFocuses == counts.activeEmitters,
					"Production native VFX exceeds its real mobile/desktop live cap")
				assert(counts.activeLights <= (if mobile then 0 else 2), "Production native VFX light budget exceeded")
				if name == "far" then assert(counts.activeEmitters == 0 and counts.activeLights == 0, "Far native effects did not cull") end
				maximumActive = math.max(maximumActive, counts.activeEmitters); minimumActive = math.min(minimumActive, counts.activeEmitters)
				maximumLights = math.max(maximumLights, counts.activeLights); maximumRate = math.max(maximumRate, counts.totalParticleRate)
			end
		end
		assert(#frames > 10 and samples > 10, "Insufficient actual rendered stress observations")
		if name == "near" then assert(maximumActive == (if mobile then 12 else 20), "Near cluster did not exercise the full native VFX budget") end
		table.sort(frames)
		local function percentile(p) return frames[math.clamp(math.ceil(#frames*p), 1, #frames)] * 1000 end
		local average = timing.sum / #frames
		return { phase = name, observedSeconds = os.clock()-observationAt, frameCount = #frames, countSamples = samples,
			maximumActiveEmitters = maximumActive, minimumActiveEmitters = minimumActive, maximumActiveLights = maximumLights,
			maximumParticleRate = maximumRate, finalNativeCounts = finalCounts, meanFrameMs = average*1000,
			p50FrameMs = percentile(.5), p95FrameMs = percentile(.95), p99FrameMs = percentile(.99),
			maximumFrameMs = timing.maximum*1000, meanObservedFps = 1/average,
			framesOver33ms = timing.over33ms, framesOver50ms = timing.over50ms }
	end
	local ok, result = pcall(function()
		local near = observe("near", CFrame.lookAt(target.center + Vector3.new(0, 13, 24), target.center + Vector3.new(0, 2, 0)))
		local far = observe("far", CFrame.lookAt(target.center + Vector3.new(350, 120, 350), target.center))
		return { touchEnabled = mobile, viewport = { camera.ViewportSize.X, camera.ViewportSize.Y },
			deviceScope = "Actual local Studio client; device emulation when TouchEnabled, not a physical-device benchmark",
			fixtureObservationOverheadIncluded = true, liveEffectCap = if mobile then 12 else 20,
			lightCap = if mobile then 0 else 2, near = near, far = far }
	end)
	camera.CameraType = previousType; camera.CFrame = previousFrame
	if not ok then error(result) end
	return result
end
control.OnClientEvent:Connect(function(nonce, action, target)
	local ok, result = pcall(function()
		if action == "prompt" then
			assert(target and target:IsA("ProximityPrompt"), "A real ProximityPrompt is required")
			local inputs = 0
			for attempt = 1, 6 do
				if not target.Parent or not target.Enabled then break end
				target:InputHoldBegin(); inputs += 1
				task.wait(math.max(0.15, target.HoldDuration + 0.05))
				if target.Parent then target:InputHoldEnd() end
				if not target.Parent or not target.Enabled then break end
				if attempt < 6 then task.wait(0.35) end
			end
			return { nativePromptInputCount = inputs, inputAPI = "InputHoldBegin/InputHoldEnd" }
		elseif action == "inspect" then return inspect(target)
		elseif action == "stress" then return stress(target)
		elseif action == "stressCleanup" then
			assert(await(function()
				for _, model in stressModels do if model:IsDescendantOf(workspace) then return false end end
				return true
			end, 5), "Temporary stress models survived cleanup")
			local remaining = 0
			for _, model in CollectionService:GetTagged("ExpansionCurseVFX") do if model:IsDescendantOf(workspace) then remaining += 1 end end
			assert(remaining == 0, "Temporary native VFX tags survived stress cleanup")
			local cleaned = #stressModels; stressModels = {}
			return { cleanedModels = cleaned, remainingLiveExpansionTags = remaining }
		else error("Unknown fixture client action: " .. tostring(action)) end
	end)
	control:FireServer(nonce, ok, if ok then result else tostring(result))
end)
control:FireServer("ready", true)
