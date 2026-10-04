-- Controlled test actions travel over the real management RemoteFunction.
local RS=game:GetService('ReplicatedStorage')
local control=RS:WaitForChild('ManagementTestControl')
local request=RS:WaitForChild('CurseManagement'):WaitForChild('Request')
control.OnClientEvent:Connect(function(nonce,action,args)
	local ok,answer=pcall(function()
		if action=='prompt' then args:InputHoldBegin();task.wait(.1);args:InputHoldEnd();return true end
		if action=='burst' then
			local output,remaining={},#args
			for i,values in args do task.spawn(function()
				output[i]=request:InvokeServer(table.unpack(values));remaining-=1
			end) end
			while remaining>0 do task.wait() end
			return output
		end
		return request:InvokeServer(action,table.unpack(args))
	end)
	control:FireServer(nonce,ok,answer)
end)
control:FireServer('ready',true)
