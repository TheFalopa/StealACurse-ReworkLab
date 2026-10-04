local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local ServerStorage=game:GetService('ServerStorage')
local HttpService=game:GetService('HttpService')
local DataStoreService=game:GetService('DataStoreService')
local Config=require(script.Parent.Config)
local Catalog=require(game.ReplicatedStorage.Shared.CurseCatalog)
local SanctuaryProgression=require(game.ReplicatedStorage.Shared.SanctuaryProgression)
local ToolInventory=require(game.ReplicatedStorage.Shared.ToolInventory)
local LedgerMath=require(game.ReplicatedStorage.Shared.TheftLedgerMath)
local TheftLedger=require(script.Parent.TheftLedger)
local Store={}

local function finite(value)
	return typeof(value)=='number' and value==value and value>-math.huge and value<math.huge
end
local function newProfile()
	return {schema=1,souls=Config.StartingSouls,curses={},revision=0,sanctuary=SanctuaryProgression.newProgress()}
end
local function valid(profile)
	if typeof(profile)~='table' or profile.schema~=1 or not finite(profile.souls)
		or profile.souls<0 or typeof(profile.curses)~='table'
		or not finite(profile.revision) or profile.revision<0 or profile.revision~=math.floor(profile.revision) then return false end
	if profile.tools~=nil and not ToolInventory.valid(profile.tools) then return false end
	if profile.toolTransfers~=nil and typeof(profile.toolTransfers)~='table' then return false end
	local seen={}
	if #profile.curses>Config.MaximumOwnedCurses then return false end
	for _,curse in profile.curses do
		if typeof(curse)~='table' or typeof(curse.uid)~='string' or seen[curse.uid]
			or #curse.uid==0 or #curse.uid>80 or not Catalog.Definitions[curse.definitionId]
			or (curse.state~='PLACED' and curse.state~='UNPLACED')
			or (curse.revision~=nil and (not finite(curse.revision) or curse.revision<0 or curse.revision~=math.floor(curse.revision)))
			or (curse.pedestalId~=nil and (typeof(curse.pedestalId)~='string' or #curse.pedestalId>80)) then return false end
		seen[curse.uid]=true
	end
	return true
end
function Store.start()
	local profiles,loading,dirty,saving,removed={},{},{},{},{}
	local callbacks={}
	local session=HttpService:GenerateGUID(false)
	local studio=RunService:IsStudio()
	local dataStore=if not studio then DataStoreService:GetDataStore('StealACurseProfilesV1') else nil
	local bridge
	local service={}
	local function key(player) return 'u'..tostring(player.UserId) end
	local function localBridge()
		if bridge and bridge.Parent and bridge:GetAttribute('Ready') then return bridge end
		local deadline=os.clock()+12
		repeat
			bridge=ServerStorage:FindFirstChild('LocalProfileBridge')
			if bridge and bridge:GetAttribute('Ready') then return bridge end
			task.wait(.1)
		until os.clock()>deadline
		return nil
	end
	local function load(player)
		loading[player]=true
		player:SetAttribute('ProfileStatus','LOADING')
		local migrationChanged=false
		local ok,result=pcall(function()
			if studio then
				local b=localBridge()
				assert(b,'Install the local profile plugin before Play. No account was overwritten.')
				local stored=HttpService:JSONDecode(b.Seed.Value)
				assert(typeof(stored)=='table','Invalid local profile seed; preserved without replacement')
				local p=stored[key(player)]
				if p~=nil then
					assert(valid(p),'Invalid saved profile; preserved without replacement')
					local _,changed=SanctuaryProgression.migrate(p);migrationChanged=changed
				else migrationChanged=true end
				p=p or newProfile()
				migrationChanged=ToolInventory.migrate(p) or migrationChanged
				migrationChanged=LedgerMath.recover(p,player.UserId,TheftLedger.read()) or migrationChanged
				assert(valid(p),'Ownership recovery validation failed; preserve original profile')
				return p
			else
				local busy=false
				local loaded=dataStore:UpdateAsync(key(player),function(previous)
					if previous and previous.lease then
						assert(typeof(previous.lease)=='table' and typeof(previous.lease.session)=='string' and finite(previous.lease.expires),'Invalid lease; saved profile preserved')
						if previous.lease.session~=session and previous.lease.expires>os.time() then busy=true;return nil end
					end
					local p=previous or newProfile()
					assert(valid(p),'Invalid saved profile; preserved without replacement')
					local _,changed=SanctuaryProgression.migrate(p);migrationChanged=changed or previous==nil
					migrationChanged=ToolInventory.migrate(p) or migrationChanged
					p.lease={session=session,expires=os.time()+180}
					return p
				end)
				assert(not busy and loaded,'Profile is active on another server')
				return loaded
			end
		end)
		loading[player]=nil
		if not ok or (result~=nil and not valid(result)) then
			player:SetAttribute('ProfileStatus','UNAVAILABLE')
			player:SetAttribute('HUDNotice','Saved account unavailable. Purchases are paused; your data is preserved.')
			player:SetAttribute('HUDNoticeSerial',(player:GetAttribute('HUDNoticeSerial') or 0)+1)
			warn('Profile load failed for '..key(player)..': '..tostring(result))
			return
		end
		local p=result or newProfile()
		p.session=session;p.lease=nil
		profiles[player]=p
		-- A player leaving during load must not initialize or rewrite inventory.
		if player.Parent~=Players or removed[player] then service:commit(player);service:flush(player,true);profiles[player]=nil;return end
		local initialized,initializeError=pcall(function()
			for _,callback in callbacks do callback(player,p) end
		end)
		if not initialized then
			profiles[player]=nil;player:SetAttribute('ProfileStatus','UNAVAILABLE')
			warn('Account initialization failed; saved profile preserved: '..tostring(initializeError));return
		end
		-- One acknowledged journal write per migration/new profile; no per-movement persistence.
		if migrationChanged then service:commit(player) end
		player:SetAttribute('ProfileMigrationStatus',if migrationChanged then 'UPGRADED' else 'CURRENT')
		player:SetAttribute('ProfileStatus','READY')
	end
	function service:get(player) return profiles[player] end
	function service:onLoaded(callback)
		table.insert(callbacks,callback)
		for player,p in profiles do callback(player,p) end
	end
	function service:commit(player)
		local p=profiles[player];if not p then return end
		p.revision=(p.revision or 0)+1;p.savedAt=workspace:GetServerTimeNow();p.session=session
		dirty[player]=true
		-- This write does not yield. The Studio plugin durably acknowledges it.
		if studio and bridge and bridge:GetAttribute('Ready') then
			local journal=bridge:FindFirstChild('Journal')
			if journal then
				local v=journal:FindFirstChild(key(player))
				if not v then v=Instance.new('StringValue');v.Name=key(player);v.Parent=journal end
				v.Value=HttpService:JSONEncode(p)
			end
		end
	end
	function service:flush(player,release)
		local p=profiles[player];if not p then return false end
		if saving[player] then
			local deadline=os.clock()+8
			while saving[player] and os.clock()<deadline do task.wait(.05) end
			if saving[player] then return false end
		end
		saving[player]=true
		local revision=p.revision
		local snapshot=HttpService:JSONDecode(HttpService:JSONEncode(p))
		local ok,err=pcall(function()
			if studio then
				local b=localBridge();assert(b,'Local profile bridge unavailable')
				local v=b.Journal:FindFirstChild(key(player));assert(v,'Missing local profile journal')
				local deadline=os.clock()+5
				while (v:GetAttribute('SavedRevision') or -1)<revision and os.clock()<deadline do task.wait(.05) end
				assert((v:GetAttribute('SavedRevision') or -1)>=revision,v:GetAttribute('SaveError') or 'Local save was not acknowledged')
			else
				local lost=false
				dataStore:UpdateAsync(key(player),function(previous)
					if previous and previous.lease and previous.lease.session~=session then lost=true;return nil end
					snapshot.lease=if release then nil else {session=session,expires=os.time()+180}
					return snapshot
				end)
				assert(not lost,'Session lease was lost; newer profile preserved')
			end
		end)
		saving[player]=nil
		if ok then
			if p.revision==revision then dirty[player]=nil end
			player:SetAttribute('ProfileSaveStatus','SAVED')
		else
			player:SetAttribute('ProfileSaveStatus','RETRYING')
			warn('Profile save pending: '..tostring(err))
		end
		return ok
	end
	function service:release(player)
		removed[player]=true
		self:commit(player)
		local saved=false
		for attempt=1,3 do
			if self:flush(player,true) then saved=true;break end
			task.wait(attempt*.5)
		end
		-- Keep an unsaved profile in memory for the autosave/retry worker.
		if saved then profiles[player]=nil;dirty[player]=nil end
		return saved
	end
	Players.PlayerAdded:Connect(function(player)task.spawn(load,player)end)
	for _,player in Players:GetPlayers() do task.spawn(load,player) end
	task.spawn(function()
		while true do
			task.wait(Config.ProfileAutosaveSeconds)
			for player in profiles do
				service:commit(player)
				task.spawn(function()
					if service:flush(player,removed[player]) and removed[player] then profiles[player]=nil;dirty[player]=nil end
				end)
			end
		end
	end)
	game:BindToClose(function()
		local pending=0
		for player in profiles do
			pending+=1
			task.spawn(function()service:commit(player);service:flush(player,true);pending-=1 end)
		end
		local deadline=os.clock()+25
		while pending>0 and os.clock()<deadline do task.wait(.05) end
	end)
	return service
end
return Store
