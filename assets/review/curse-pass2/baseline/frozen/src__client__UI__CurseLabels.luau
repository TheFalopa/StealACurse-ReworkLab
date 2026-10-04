local Players = game:GetService("Players")

local CurseLabels = {}

function CurseLabels.start()
	-- Five fixed-pixel cards project onto each other from side-on base cameras.
	-- Inspect the closest pedestal locally; never change server Curse state.
	task.spawn(function()
		while true do
			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local map = workspace:FindFirstChild("StealACurseMap")
			local folder = map and map:FindFirstChild("ActiveCurses")
			if folder then
				local nearest, distance = nil, 25
				local labels = {}
				for _, model in ipairs(folder:GetChildren()) do
					if model:IsA("Model") and model:GetAttribute("CurseState") == "PLACED" then
						local label = model:FindFirstChild("CurseInfo")
						if label and label:IsA("BillboardGui") then
							labels[label] = true
							if root and model.PrimaryPart then
								local d = (root.Position - model.PrimaryPart.Position).Magnitude
								if d < distance then nearest, distance = label, d end
								end
						end
					end
				end
				for label in pairs(labels) do label.Enabled = label == nearest end
			end
			task.wait(0.2)
		end
	end)
end

return CurseLabels
