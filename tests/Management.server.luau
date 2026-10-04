-- Integration fixture: real players, production services, controlled setup.
-- Native UI and natural walking are reviewed separately in the normal build.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local control=Instance.new('RemoteEvent');control.Name='ManagementTestControl';control.Parent=RS
local ready,answers={},{}
control.OnServerEvent:Connect(function(p,nonce,ok,value)
	if nonce=='ready' then ready[p]=true else answers[nonce]={player=p,ok=ok,value=value} end
end)
local map=require(script.Map.Build).build()
local profiles=require(script.Gameplay.ProfileStore).start()
local souls=require(script.Gameplay.SoulsService).start(profiles)
local bases=require(script.Gameplay.BaseService).start(map)
local curses=require(script.Gameplay.CurseService).start(map,bases,souls,profiles)
local seq=0
local function await(fn,seconds)
	local deadline=os.clock()+(seconds or 10)
	repeat if fn() then return true end;task.wait(.1)until os.clock()>deadline
	return false
end
local function check(ok,label)assert(ok,label);print('MANAGEMENT_PASS',label)end
local function client(p,action,args)
	seq+=1;local nonce=tostring(seq);control:FireClient(p,nonce,action,args)
	assert(await(function()return answers[nonce]end,10),'Client request timeout: '..action)
	local response=answers[nonce];answers[nonce]=nil
	assert(response.player==p and response.ok,tostring(response.value));task.wait(.15)
	return response.value
end
local function pose(p,position)
	p.Character:PivotTo(CFrame.new(position));p.Character.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero;task.wait(.25)
end
local function model(uid)
	for _,m in map.ActiveCurses:GetChildren()do if m:GetAttribute('CurseUid')==uid then return m end end
end
task.spawn(function()
	local ok,err=pcall(function()
		check(await(function()local p=Players:GetPlayers()[1];return p and ready[p] and p:GetAttribute('ProfileStatus')=='READY' and p.Character and p.Character:FindFirstChild('HumanoidRootPart') end,25),'profile and avatar ready with local durable provider')
		local p=Players:GetPlayers()[1];local base=bases:getBaseById('Base02')
		pose(p,base.ClaimMarker.Position-Vector3.new(0,2,0))
		client(p,'prompt',base.ClaimMarker.ClaimSanctuary)
		map:SetAttribute('ManagementTestStage','WAITING_NATIVE_CLAIM')
		check(await(function()return bases:getBaseForPlayer(p)==base end,60),'native claim reached server')
		local totals=require(game.ServerStorage.UnitTest.RunUnitTest)()
		check(totals.failed==0,'pure ownership, quote and sale rules')
		-- A previous session intentionally ended while carrying. Its real saved
		-- record must return unplaced, without a resurrected original pedestal.
		for _,saved in table.clone(profiles:get(p).curses) do
			if saved.state=='UNPLACED' or saved.state=='PLACED' then
				local restored=model(saved.uid)
				if saved.state=='UNPLACED' then
				check(restored and curses:getState(saved.uid)=='UNPLACED' and not restored:GetAttribute('PedestalId'),'closed-session Curse reloads unplaced')
				local expectedIncome=0
				for _,other in profiles:get(p).curses do if other.state=='PLACED' then expectedIncome+=require(RS.Shared.CurseCatalog).Definitions[other.definitionId].baseSoulsPerSecond end end
				check(p:GetAttribute('SoulsPerSecond')==expectedIncome and not p:GetAttribute('CarriedCurseUid'),'reconnect does not restore carrier or unplaced income')
				pose(p,restored.PrimaryPart.Position+Vector3.new(0,0,4))
				check(client(p,'pickup',{saved.uid}).ok,'reloaded Curse requires manual pickup')
				local target=bases:getPedestals(base)['floor1-slot1'];pose(p,target.Position+Vector3.new(0,3.5,4))
				check(client(p,'place',{saved.uid,'floor1-slot1'}).ok,'reloaded Curse requires nearby manual placement')
				else
					check(restored and curses:getState(saved.uid)=='PLACED','placed saved instance restores on its identified pedestal')
					pose(p,restored.PrimaryPart.Position+Vector3.new(0,0,4))
				end
				local q=client(p,'quote',{saved.uid}).data;check(client(p,'sell',{saved.uid,nil,q.token}).ok,'recovered previous session can be managed')
			end
		end
		-- A controlled test account receives credit; normal account is isolated.
		souls:credit(p,10000);profiles:commit(p)
		pose(p,Vector3.new(0,4,36))
		local uid=curses:spawn('cursed_doll',CFrame.new(0,5.3,32))
		task.wait(.5);local before=souls:getBalance(p)
		check(curses:purchase(p,uid),'validated server purchase in controlled setup')
		check(souls:getBalance(p)==before-100 and p:GetAttribute('SoulsPerSecond')==0,'purchase charges once and carried income is zero')
		check(not curses:purchase(p,uid),'duplicate purchase rejected')
		local slots=bases:getPedestals(base);local first=slots['floor1-slot1'];local second=slots['floor1-slot2']
		check(not client(p,'place',{uid,'floor1-slot1'}).ok,'remote placement rejected')
		pose(p,first.Position+Vector3.new(0,3.5,4))
		check(client(p,'place',{uid,'floor1-slot1'}).ok,'manual placement near destination')
		check(first:GetAttribute('OccupiedCurseUid')==uid and p:GetAttribute('SoulsPerSecond')==3,'one occupied pedestal and one production contribution')
		local quote=client(p,'quote',{uid}).data
		check(quote.sale==50 and quote.name=='Cursed Doll' and quote.rarity=='COMMON','sale quote gives exact name rarity and half price')
		check(client(p,'pickup',{uid}).ok,'own placed Curse can be physically picked up')
		check(first:GetAttribute('OccupiedCurseUid')==nil and p:GetAttribute('SoulsPerSecond')==0,'pickup frees old pedestal and stops income')
		check(not client(p,'sell',{uid,nil,quote.token}).ok,'carried Curse cannot use earlier sale confirmation')
		pose(p,second.Position+Vector3.new(0,3.5,4))
		check(client(p,'place',{uid,'floor1-slot2'}).ok,'relocation to different identified pedestal')
		check(p:GetAttribute('SoulsPerSecond')==3,'relocation resumes production once')
		local sale=client(p,'quote',{uid}).data;local balance=souls:getBalance(p)
		local burst=client(p,'burst',{{'sell',uid,nil,sale.token},{'sell',uid,nil,sale.token},{'pickup',uid}})
		local successes=0;for _,answer in burst do if answer.ok then successes+=1 end end
		check(successes==1 and burst[1].ok,'simultaneous duplicate sale and pickup commit one sale')
		check(souls:getBalance(p)>=balance+50 and souls:getBalance(p)<balance+51,'exact single sale payment plus bounded pre-sale tick')
		check(not client(p,'sell',{uid,nil,sale.token}).ok,'duplicate sale cannot pay twice')
		check(not model(uid) and not second:GetAttribute('OccupiedCurseUid') and p:GetAttribute('SoulsPerSecond')==0,'sale destroys one instance frees pedestal and stops income')
		-- Geometry added only in this fixture tests IDs and full 3D distance.
		pose(p,Vector3.new(0,4,36))
		local recoverUid=curses:spawn('grave_key',CFrame.new(0,5.3,32));task.wait(.5)
		check(curses:purchase(p,recoverUid),'recovery test owns a real imported Curse')
		pose(p,first.Position+Vector3.new(0,3.5,4));check(client(p,'place',{recoverUid,'floor1-slot1'}).ok,'recovery test starts on pedestal')
		check(client(p,'pickup',{recoverUid}).ok,'recovery test physically picks up')
		local beforeDeath=souls:getBalance(p);p.Character.Humanoid.Health=0
		check(await(function()return curses:getState(recoverUid)=='UNPLACED'end,5),'death leaves owned unplaced Curse')
		check(not first:GetAttribute('OccupiedCurseUid') and p:GetAttribute('SoulsPerSecond')==0,'death does not return to original pedestal or resume income')
		check(souls:getBalance(p)==beforeDeath,'death does not refund or pay Souls')
		check(await(function()return p.Character and p.Character:FindFirstChildOfClass('Humanoid') and p.Character.Humanoid.Health>0 end,15),'character respawns')
		local recoveryModel=model(recoverUid);local bottom=recoveryModel.PrimaryPart.Position.Y-recoveryModel.PrimaryPart.Size.Y/2
		check(bottom>0 and bottom<base.PlayerSpawn.Position.Y+5,'unplaced recovery position is supported and reachable')
		pose(p,recoveryModel.PrimaryPart.Position+Vector3.new(0,0,4))
		check(client(p,'pickup',{recoverUid}).ok,'manual recovery pickup after death')
		local elevated=first:Clone();elevated.Name='FixtureElevatedPedestal';elevated:ClearAllChildren()
		elevated:SetAttribute('PedestalId','future-floor-slotA');elevated:SetAttribute('OccupiedCurseUid',nil);elevated:SetAttribute('LegacySlotIndex',nil)
		elevated.CFrame=first.CFrame*CFrame.new(10,8,0);elevated.Parent=base
		pose(p,elevated.Position+Vector3.new(0,-18,0))
		check(not client(p,'place',{recoverUid,'future-floor-slotA'}).ok,'vertical remote placement is rejected')
		pose(p,elevated.Position+Vector3.new(0,3.5,4))
		check(client(p,'place',{recoverUid,'future-floor-slotA'}).ok,'future elevated pedestal is found by identity and ownership')
		check(elevated:GetAttribute('OccupiedCurseUid')==recoverUid,'future pedestal occupied consistently')
		pose(p,Vector3.new(0,4,36))
		local otherUid=curses:spawn('candle_wisp',CFrame.new(0,5.3,32));task.wait(.5)
		check(curses:purchase(p,otherUid),'second owned instance for occupied pedestal checks')
		pose(p,elevated.Position+Vector3.new(0,3.5,4))
		check(not client(p,'place',{otherUid,'future-floor-slotA'}).ok,'occupied destination rejects placement')
		check(not client(p,'pickup',{recoverUid}).ok,'one carried Curse blocks second pickup')
		pose(p,first.Position+Vector3.new(0,3.5,4))
		check(client(p,'place',{otherUid,'floor1-slot1'}).ok,'rejected actions preserve carried instance')
		local otherQuote=client(p,'quote',{otherUid}).data
		check(client(p,'sell',{otherUid,nil,otherQuote.token}).ok,'selling one instance leaves other ownership intact')
		pose(p,elevated.Position+Vector3.new(0,3.5,4))
		check(client(p,'pickup',{recoverUid}).ok,'pickup frees future pedestal')
		elevated:Destroy()
		-- A technical destruction of the visible model must retain ownership.
		model(recoverUid):Destroy()
		check(await(function()return curses:getState(recoverUid)=='UNPLACED' and model(recoverUid) end,6),'destroyed carried visual is recoverable without losing inventory')
		pose(p,model(recoverUid).PrimaryPart.Position+Vector3.new(0,0,4));check(client(p,'pickup',{recoverUid}).ok,'technical recovery still needs manual pickup')
		p:LoadCharacterAsync()
		check(curses:getState(recoverUid)=='UNPLACED' and p:GetAttribute('SoulsPerSecond')==0,'reset also leaves unplaced Curse without income')
		check(await(function()return p.Character and p.Character:FindFirstChild('HumanoidRootPart') and p.Character.Humanoid.Health>0 end,15),'reset character is available')
		pose(p,model(recoverUid).PrimaryPart.Position+Vector3.new(0,0,4));check(client(p,'pickup',{recoverUid}).ok,'manual recovery after reset')
		local carriedAtClose=profiles:get(p).curses
		local savedRecovery;for _,v in carriedAtClose do if v.uid==recoverUid then savedRecovery=v end end
		check(savedRecovery and savedRecovery.state=='UNPLACED' and not savedRecovery.pedestalId,'carried snapshot persists as unplaced with no original pedestal')
		-- Leaving this owned Curse carried enables the next Play to check reload.
		map:SetAttribute('RecoveryReviewUid',recoverUid)
		check(profiles:flush(p,false),'local profile acknowledged by durable plugin')
		map:SetAttribute('ManagementTestStatus','PASS');print('MANAGEMENT_DONE','sale, relocation, death and future pedestal batch')
	end)
	if not ok then map:SetAttribute('ManagementTestStatus','FAIL');warn('MANAGEMENT_FAIL',err)end
end)
