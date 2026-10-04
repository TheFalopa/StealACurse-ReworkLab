local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local CollectionService=game:GetService('CollectionService')
local Theme=require(script.Parent.Theme)
local Management={}
function Management.start()
	local player=Players.LocalPlayer
	local remote=RS:WaitForChild('CurseManagement')
	local request=remote:WaitForChild('Request');local open=remote:WaitForChild('Open')
	local gui=Theme.make('ScreenGui',{Name='CurseManagementUI',ResetOnSpawn=false,ScreenInsets=Enum.ScreenInsets.DeviceSafeInsets,DisplayOrder=35,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},player:WaitForChild('PlayerGui'))
	local shade=Theme.make('Frame',{Name='Shade',Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.35,BorderSizePixel=0,Visible=false,Active=true},gui)
	local panel=Theme.make('Frame',{Name='Panel',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(424,310),BackgroundColor3=Theme.colors.panel,BorderSizePixel=0},shade)
	Theme.corner(panel,16);Theme.stroke(panel,Theme.colors.line,1)
	local scale=Theme.make('UIScale',{Scale=1},panel)
	local title=Theme.label(panel,'Title','TU CURSE',UDim2.fromOffset(22,18),UDim2.new(1,-90,0,28),20,Theme.colors.white,Enum.Font.GothamBold)
	local close=Theme.make('TextButton',{Name='Close',Text='×',Position=UDim2.new(1,-60,0,10),Size=UDim2.fromOffset(48,48),BackgroundTransparency=1,TextColor3=Theme.colors.muted,TextSize=30,Font=Enum.Font.GothamBold},panel)
	local name=Theme.label(panel,'CurseName','',UDim2.fromOffset(22,60),UDim2.new(1,-44,0,28),20,Theme.colors.white,Enum.Font.GothamBold)
	name.TextTruncate=Enum.TextTruncate.AtEnd
	local rarity=Theme.label(panel,'Rarity','',UDim2.fromOffset(22,91),UDim2.new(1,-44,0,20),12,Theme.colors.violet,Enum.Font.GothamBold)
	local body=Theme.label(panel,'Description','',UDim2.fromOffset(22,112),UDim2.new(1,-44,0,46),15,Theme.colors.muted)
	body.TextWrapped=true;body.TextYAlignment=Enum.TextYAlignment.Top
	local function button(id,y,text,color)
		local b=Theme.make('TextButton',{Name=id,Text=text,Position=UDim2.fromOffset(22,y),Size=UDim2.new(1,-44,0,52),BackgroundColor3=color,TextColor3=Theme.colors.ink,TextSize=16,Font=Enum.Font.GothamBold,BorderSizePixel=0,AutoButtonColor=false},panel)
		Theme.corner(b,9);Theme.buttonFeedback(b,color,color:Lerp(Color3.new(1,1,1),.13));return b
	end
	local pickup=button('Pickup',166,'RECOGER',Theme.colors.cyan)
	local sell=button('Sell',230,'VENDER…',Theme.colors.amber)
	local confirm=button('ConfirmSell',166,'CONFIRMAR VENTA',Theme.colors.amber);confirm.Visible=false
	local back=button('Back',230,'VOLVER',Theme.colors.card);back.TextColor3=Theme.colors.white;back.Visible=false
	local uid,quote,busy,serial=nil,nil,false,0
	local function notice(message)
		-- UI-only result text; never modifies ownership, Souls or placement.
		body.Text=message
	end
	local function closePanel()serial+=1;shade.Visible=false;uid=nil;quote=nil end
	close.Activated:Connect(closePanel)
	local function call(action,callback)
		if busy or not uid then return end
		busy=true;local generation=serial;local selected=uid
		pickup.Active=false;sell.Active=false;confirm.Active=false
		local ok,answer=pcall(function()return request:InvokeServer(action,selected,nil,quote and quote.token)end)
		busy=false;pickup.Active=true;sell.Active=true;confirm.Active=true
		if generation~=serial then return end
		if not ok or typeof(answer)~='table' then notice('No se pudo completar la acción. Inténtalo de nuevo.');return end
		if not answer.ok then notice(answer.message);return end
		callback(answer)
	end
	local function mainPage()
		title.Text='TU CURSE';pickup.Visible=true;sell.Visible=true;confirm.Visible=false;back.Visible=false
		body.Text='Recógela para llevarla a otro pedestal. Mientras la transportas no produce Souls.'
	end
	open.OnClientEvent:Connect(function(selected)
		if typeof(selected)~='string' or busy then return end
		serial+=1;uid=selected;quote=nil;shade.Visible=true;mainPage()
		call('inspect',function(answer)name.Text=answer.data.name;rarity.Text=answer.data.rarity;sell.Text='VENDER · '..tostring(answer.data.sale)..' SOULS'end)
	end)
	pickup.Activated:Connect(function()call('pickup',function()closePanel()end)end)
	sell.Activated:Connect(function()
		call('quote',function(answer)
			quote=answer.data;title.Text='CONFIRMAR VENTA';name.Text=quote.name;rarity.Text=quote.rarity
			body.Text='Recibirás exactamente '..tostring(quote.sale)..' Souls. Esta Curse se eliminará de tu colección.'
			pickup.Visible=false;sell.Visible=false;confirm.Visible=true;back.Visible=true
			confirm.Text='VENDER POR '..tostring(quote.sale)..' SOULS'
		end)
	end)
	confirm.Activated:Connect(function()call('sell',function(answer)closePanel()end)end)
	back.Activated:Connect(function()quote=nil;mainPage()end)
	player.CharacterRemoving:Connect(closePanel)
	local function resize()
		-- ScreenGui safe area is smaller than Camera.ViewportSize on notched
		-- devices. Size against the actual available parent, not the camera.
		local available=shade.AbsoluteSize
		if available.X>0 and available.Y>0 then scale.Scale=math.max(.1,math.min(1,(available.X-28)/424,(available.Y-24)/310)) end
	end
	task.spawn(function()
		while gui.Parent do
			resize()
			for _,part in CollectionService:GetTagged('OwnedCursePedestal') do
				local prompt=part:FindFirstChild('PlaceCurse');local base=part.Parent
				while base and not base:GetAttribute('BaseId') do base=base.Parent end
				if prompt and base then
					prompt.Enabled=base:GetAttribute('OwnerUserId')==player.UserId and player:GetAttribute('CarriedCurseUid')~=nil
					prompt.ActionText=if part:GetAttribute('OccupiedCurseUid') then 'Pedestal ocupado' else 'Colocar'
				end
			end
			local map=workspace:FindFirstChild('StealACurseMap');local folder=map and map:FindFirstChild('ActiveCurses')
			if folder then for _,model in folder:GetChildren() do
				local mesh=model:FindFirstChild('CurseMesh');local prompt=mesh and mesh:FindFirstChild('ManageCurse')
				if prompt then
					local state=model:GetAttribute('CurseState')
					prompt.Enabled=model:GetAttribute('OwnerUserId')==player.UserId and (state=='PLACED' or state=='UNPLACED') and not model:GetAttribute('OperationLocked')
				end
			end end
			task.wait(.2)
		end
	end)
end
return Management
