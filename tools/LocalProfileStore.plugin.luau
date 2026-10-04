-- Local Studio persistence for this unpublished project. No web requests.
-- Plugin settings survive closing Studio; the playable place contains no plugin.
local RunService=game:GetService('RunService')
local HttpService=game:GetService('HttpService')
local ServerStorage=game:GetService('ServerStorage')
local KEY='StealACurseLocalProfilesV1'
local stopped=false
plugin.Unloading:Connect(function() stopped=true end)
task.spawn(function()
	local shared=game:GetService('ReplicatedStorage'):WaitForChild('Shared',15)
	if not shared or not shared:FindFirstChild('CurseCatalog') or (RunService:IsRunning() and RunService:IsClient() and not RunService:IsServer()) then return end
	local bridge=ServerStorage:FindFirstChild('LocalProfileBridge')
	if not bridge then bridge=Instance.new('Folder');bridge.Name='LocalProfileBridge';bridge.Parent=ServerStorage end
	local key=KEY..(bridge:GetAttribute('Namespace') or 'play')
	local seed=bridge:FindFirstChild('Seed')
	if not seed then seed=Instance.new('StringValue');seed.Name='Seed';seed.Parent=bridge end
	local journal=bridge:FindFirstChild('Journal')
	if not journal then journal=Instance.new('Folder');journal.Name='Journal';journal.Parent=bridge end
	local ok,stored=pcall(function() return plugin:GetSetting(key) end)
	if not ok then bridge:SetAttribute('Error','Could not read local plugin settings');return end
	if typeof(stored)~='table' then stored={} end
	seed.Value=HttpService:JSONEncode(stored)
	bridge:SetAttribute('Ready',true)
	bridge:SetAttribute('Provider','PluginSettings')
	bridge:SetAttribute('Context',if RunService:IsRunning() then 'Play' else 'Edit')
	local attached={}
	local function save(value)
		if not value:IsA('StringValue') or value.Value=='' then return end
		local parsed,profile=pcall(HttpService.JSONDecode,HttpService,value.Value)
		if not parsed or typeof(profile)~='table' or profile.schema~=1 then return end
		local read,current=pcall(function() return plugin:GetSetting(key) end)
		if not read then value:SetAttribute('SaveError','Local settings read failed');return end
		if typeof(current)~='table' then current={} end
		local previous=current[value.Name]
		if previous and (previous.savedAt or 0)>(profile.savedAt or 0) then
			value:SetAttribute('SaveError','A newer local session already saved this profile');return
		end
		current[value.Name]=profile
		local wrote,err=pcall(function() plugin:SetSetting(key,current) end)
		-- Read back: SetSetting can fail silently. Only acknowledge durable data.
		local check,roundtrip=pcall(function()return plugin:GetSetting(key)end)
		local saved=check and typeof(roundtrip)=='table' and roundtrip[value.Name]
		if wrote and saved and saved.revision==profile.revision and saved.session==profile.session then
			value:SetAttribute('SavedRevision',profile.revision)
			value:SetAttribute('SaveError',nil)
			bridge:SetAttribute('LastSavedAt',profile.savedAt)
		else value:SetAttribute('SaveError',tostring(err or 'Local settings readback failed')) end
	end
	local function attach(value)
		if attached[value] or not value:IsA('StringValue') then return end
		attached[value]=value:GetPropertyChangedSignal('Value'):Connect(function() save(value) end)
		save(value)
	end
	journal.ChildAdded:Connect(attach)
	for _,value in journal:GetChildren() do attach(value) end
	-- Edit receives a fresh seed whenever Play ends. The Play plugin writes the
	-- journal while the server is running, before its DataModel is discarded.
	while not stopped and bridge.Parent do
		task.wait(1)
		if RunService:IsEdit() then
			local read,fresh=pcall(function()return plugin:GetSetting(key)end)
			if read and typeof(fresh)=='table' then seed.Value=HttpService:JSONEncode(fresh) end
		end
	end
end)
