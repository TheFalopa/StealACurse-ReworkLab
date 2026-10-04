local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Motion = require(ReplicatedStorage.Shared.CurseMotionMath)
local VFX = require(script.Parent.CurseVFX)
local Animation = require(script.Parent.CurseAnimation)
local Catalog = require(ReplicatedStorage.Shared.CurseCatalog)

local Presentation = {}
local tracked, pending, preloadQueue = {}, {}, {}
local routeCache
local started = false
local promptElapsed = 0

local function route()
	local map = workspace:FindFirstChild("StealACurseMap")
	local folder = map and map:FindFirstChild("CurseProcessionRoute")
	if not folder then return nil end
	if routeCache and routeCache.folder == folder then return routeCache end
	local points, lengths = {}, {}
	for index = 1, folder:GetAttribute("PointCount") or 0 do
		local value = folder:FindFirstChild(string.format("Point_%02d", index))
		if not value or not value:IsA("Vector3Value") then return nil end
		table.insert(points, value.Value)
	end
	if #points < 2 then return nil end
	for i = 1, #points - 1 do lengths[i] = (points[i + 1] - points[i]).Magnitude end
	routeCache = { folder = folder, points = points, lengths = lengths }
	return routeCache
end

local function remove(model)
	local entry=tracked[model]
	if entry then Animation.remove(entry.animation) end
	tracked[model], pending[model] = nil, nil
end

local function add(model)
	if tracked[model] or pending[model] then return end
	pending[model] = true
end

local function initialize(model)
	local anchor = model:FindFirstChild("CurseAnchor")
	local mesh = model:FindFirstChild("CurseMesh")
	if not anchor or not mesh or not model:GetAttribute("MotionFormat") then return false end
	if not anchor:IsA("BasePart") or not mesh:IsA("MeshPart") then return false end
	local now = workspace:GetServerTimeNow()
	local entry = { model=model, anchor=anchor, mesh=mesh, frame=anchor.CFrame,
		previous=anchor.CFrame, sample=anchor.CFrame, previousTime=now, sampleTime=now,
		state=model:GetAttribute("CurseState"), revision=model:GetAttribute("MotionRevision"),
		shown=false, readyAt=os.clock()+2, preloadStarted=os.clock(), phase=model:GetAttribute("MotionPhase") or 0 }
	mesh.CFrame = anchor.CFrame
	entry.animation=Animation.create(model,mesh)
	entry.promptDeadline=os.clock()+5
	-- Reparent the same replicated prompt locally so its screen position follows
	-- the rendered mesh. Its server instance and distance validation stay on anchor.
	for _,prompt in anchor:GetChildren() do
		if prompt:IsA('ProximityPrompt') then prompt.Parent=mesh end
	end
	tracked[model] = entry
	pending[model] = nil
	table.insert(preloadQueue, entry)
	return true
end

local function followTarget(entry)
	local id = entry.model:GetAttribute("CarrierUserId")
	local player = if typeof(id)=="number" then Players:GetPlayerByUserId(id) else nil
	local character = player and player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then return nil end
	return Motion.follow(root.CFrame, entry.anchor.Size, entry.model:GetAttribute("FollowGroundY"))
end

local function sampleTarget(entry, now)
	local sample = entry.anchor.CFrame
	if (sample.Position-entry.sample.Position).Magnitude>.00001
		or sample.LookVector:Dot(entry.sample.LookVector)<.999999 then
		entry.previous, entry.previousTime = entry.sample, entry.sampleTime
		entry.sample, entry.sampleTime = sample, now
	end
	local duration = entry.sampleTime-entry.previousTime
	if duration<.001 then return sample end
	-- A bounded interpolation buffer with at most 100 ms extrapolation. Delayed
	-- packets cannot make the presentation chase an obsolete target indefinitely.
	local alpha = math.clamp((now-.10-entry.previousTime)/duration, 0, 1)
	local result = entry.previous:Lerp(entry.sample, alpha)
	local ahead = math.clamp(now-.10-entry.sampleTime, 0, .10)
	if ahead>0 then
		local velocity = (entry.sample.Position-entry.previous.Position)/duration
		if velocity.Magnitude<40 then result += velocity*ahead end
	end
	return result
end

local function render(dt)
	local now = workspace:GetServerTimeNow()
	promptElapsed+=dt
	local checkPrompts=promptElapsed>=.2
	if checkPrompts then promptElapsed=0 end
	for model in pending do
		if not model:IsDescendantOf(workspace) then pending[model]=nil else initialize(model) end
	end
	local cachedRoute = route()
	local camera = workspace.CurrentCamera
	for model, entry in tracked do
		if not model:IsDescendantOf(workspace) or not entry.anchor.Parent or not entry.mesh.Parent then
			remove(model)
			continue
		end
		local state = model:GetAttribute("CurseState")
		-- ManageCurse can replicate after the tagged mesh. Bind it once it arrives,
		-- rather than leaving its UI attached to the discretely replicated anchor.
		if checkPrompts and not entry.promptsReady then
			for _,prompt in entry.anchor:GetChildren() do
				if prompt:IsA('ProximityPrompt') then prompt.Parent=entry.mesh end
			end
			entry.promptsReady=entry.mesh:FindFirstChild('ManageCurse')~=nil or os.clock()>entry.promptDeadline
		end
		local revision = model:GetAttribute("MotionRevision")
		local target, analytic = entry.anchor.CFrame, false
		local epoch = model:GetAttribute("RouteStartedAt")
		if state=="PROCESSION" and cachedRoute and typeof(epoch)=="number" then
			target = Motion.route(cachedRoute.points, cachedRoute.lengths,
				math.max(0,now-epoch)*(model:GetAttribute("RouteSpeed") or 6.5))
			target += Vector3.new(0,entry.anchor.Size.Y*.5-3.5,0)
			analytic=true
		elseif state=="DELIVERING" or state=="CARRYING" then
			target=followTarget(entry) or sampleTarget(entry,now)
		elseif state=="PLACED" or state=="UNPLACED" then
			target=entry.anchor.CFrame
		else
			target=sampleTarget(entry,now)
		end
		local stateChanged = state~=entry.state
		local intentional = revision~=entry.revision or (target.Position-entry.frame.Position).Magnitude>24
		if intentional or not entry.shown or (stateChanged and state=="PLACED") then
			entry.frame=target
			entry.previous,entry.sample=entry.anchor.CFrame,entry.anchor.CFrame
			entry.previousTime,entry.sampleTime=now,now
		elseif analytic then
			local direction=entry.frame.Rotation:Lerp(target.Rotation,Motion.alpha(dt,.075))
			entry.frame=CFrame.new(target.Position)*direction
		else
			entry.frame=entry.frame:Lerp(target,Motion.alpha(dt,.055))
		end
		local speed=if intentional then 0 else (entry.frame.Position-entry.mesh.Position).Magnitude/math.max(dt,.001)
		entry.state,entry.revision=state,revision
		entry.mesh.CFrame=entry.frame
		Animation.update(entry.animation,now,dt,state,math.min(speed,32),camera)
		if not entry.shown and (entry.loaded or os.clock()>=entry.readyAt) then
			entry.shown=true
			entry.mesh.Transparency=0
			model:SetAttribute("PresentationReady",true)
		end
		if camera and entry.shown then
			-- Only the local camera can fade a close large mesh; the gameplay
			-- volume, other clients, and the model's physical size do not change.
			local localEye=entry.frame:PointToObjectSpace(camera.CFrame.Position)
			local half=entry.anchor.Size*.5
			local inside=math.abs(localEye.X)<half.X+.3 and math.abs(localEye.Y)<half.Y+.3
				and math.abs(localEye.Z)<half.Z+.3
			entry.mesh.LocalTransparencyModifier=if inside then .75 else 0
		end
	end
	VFX.render()
end

function Presentation.start()
	if started then return end
	started=true
	CollectionService:GetInstanceAddedSignal("ExpansionCurseVFX"):Connect(add)
	CollectionService:GetInstanceRemovedSignal("ExpansionCurseVFX"):Connect(remove)
	for _,model in CollectionService:GetTagged("ExpansionCurseVFX") do add(model) end
	RunService:BindToRenderStep("CursePresentation",Enum.RenderPriority.Character.Value+1,render)
	-- A single worker and small batches; no per-Curse preload task or startup gate.
	task.spawn(function()
		-- Warm a small, likely opening set while the world remains interactive.
		-- Newly spawned meshes always take priority over speculative resources.
		local opening={'cursed_doll','haunted_mirror','crying_mask','watching_eye','soul_chains','the_void',
			'candle_wisp','grave_hopper','grave_key','ink_imp','ashen_book','pale_guest'}
		local warmIndex=1
		while started do
			if #preloadQueue==0 then
				if warmIndex<=#opening then
					local ids={}
					for _=1,4 do
						local id=opening[warmIndex];if not id then break end
						warmIndex+=1;table.insert(ids,Catalog.Definitions[id].meshId)
					end
					pcall(function()ContentProvider:PreloadAsync(ids)end)
				else task.wait(.1) end
				continue
			end
			local batch, entries = {}, {}
			for _=1,math.min(4,#preloadQueue) do
				local entry=table.remove(preloadQueue,1)
				if tracked[entry.model] then table.insert(batch,entry.mesh) table.insert(entries,entry) end
			end
			local ok=pcall(function() ContentProvider:PreloadAsync(batch) end)
			for _,entry in entries do
				local status=ContentProvider:GetAssetFetchStatus(entry.mesh.MeshId)
				entry.loaded=ok and status==Enum.AssetFetchStatus.Success
				if entry.model.Parent then
					entry.model:SetAttribute('MeshPreloadStatus',status.Name)
					entry.model:SetAttribute('MeshPreloadSeconds',os.clock()-entry.preloadStarted)
				end
			end
		end
	end)
end

return Presentation
