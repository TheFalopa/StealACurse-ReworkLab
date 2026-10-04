-- Excluded from default.project.json. Real client prompts, not server event fakes.
local Players = game:GetService("Players")
local Pathfinding = game:GetService("PathfindingService")
local control = game:GetService("ReplicatedStorage"):WaitForChild("SliceTestControl")
control.OnClientEvent:Connect(function(nonce, action, target)
	local ok, result = pcall(function()
		if action == "race" then
			local when = target.when
			target = target.prompt
			while workspace:GetServerTimeNow() < when do task.wait() end
			target:InputHoldBegin()
			task.wait(0.15)
			target:InputHoldEnd()
		elseif action == "prompt" then
			-- A freshly replicated/rebuilt map can expose its prompt Instance before
			-- the client's prompt UI has registered the first hold. Retry real input
			-- briefly; never fire Triggered or modify authoritative gameplay state.
			-- Successful claim/purchase disables the prompt. Rejected purchases can
			-- remain enabled, so retries are bounded and harmless server rechecks.
			for attempt = 1, 6 do
				if not target.Parent or not target.Enabled then break end
				target:InputHoldBegin()
				task.wait(0.15)
				if target.Parent then target:InputHoldEnd() end
				if not target.Parent or not target.Enabled then break end
				if attempt < 6 then task.wait(0.35) end
			end
		elseif action == "labels" then
			local visible = 0
			for _, model in ipairs(workspace.StealACurseMap.ActiveCurses:GetChildren()) do
				if model:GetAttribute("CurseState") == "PLACED" and model.CurseInfo.Enabled then visible += 1 end
			end
			assert(visible == 1, "Exactly one nearest pedestal detail must be visible")
			assert(Players.LocalPlayer.PlayerGui.StealACurseHUD.SoulsHUD.Card.SoulsPerSecond.Text == "+222 Souls/s", "HUD rate text mismatch")
		elseif action == "walk" then
			local character = Players.LocalPlayer.Character
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local path = Pathfinding:CreatePath({ AgentRadius = 2, AgentHeight = 5, WaypointSpacing = 6 })
			path:ComputeAsync(character.HumanoidRootPart.Position, target)
			assert(path.Status == Enum.PathStatus.Success, "No navigable return path")
			for _, waypoint in ipairs(path:GetWaypoints()) do
				if waypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
				humanoid:MoveTo(waypoint.Position)
				assert(humanoid.MoveToFinished:Wait(), "Return walk blocked")
			end
		end
		return true
	end)
	control:FireServer(nonce, ok, tostring(result))
end)
control:FireServer("ready", true)
