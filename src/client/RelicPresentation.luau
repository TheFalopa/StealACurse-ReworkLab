local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local Collection=game:GetService('CollectionService')
local Presentation={}
function Presentation.start()
 local tracked={}
 local function add(model)
  if tracked[model] then return end
  tracked[model]={parts=nil,frame=nil}
 end
 Collection:GetInstanceAddedSignal('SanctuaryContractRelic'):Connect(add)
 Collection:GetInstanceRemovedSignal('SanctuaryContractRelic'):Connect(function(model)tracked[model]=nil end)
 for _,model in Collection:GetTagged('SanctuaryContractRelic') do add(model) end
 -- One loop for all relics; no tweens/network messages or independent timers.
 Run:BindToRenderStep('SanctuaryRelicPresentation',Enum.RenderPriority.Character.Value+2,function(dt)
  for model,entry in tracked do
   if not model.Parent then tracked[model]=nil;continue end
   local carrier=Players:GetPlayerByUserId(model:GetAttribute('CarrierUserId') or 0)
   local root=carrier and carrier.Character and carrier.Character:FindFirstChild('HumanoidRootPart')
   local primary=model.PrimaryPart
   if not root or not primary then continue end
   if not entry.parts then
    entry.parts={};for _,part in model:GetChildren() do
     if part:IsA('BasePart') then entry.parts[part]=primary.CFrame:ToObjectSpace(part.CFrame) end
    end
   end
   local target=root.CFrame*CFrame.new(1.8,.2,1.5)
   local previous=entry.frame
   entry.frame=if not previous or (target.Position-previous.Position).Magnitude>14 then target else previous:Lerp(target,1-math.exp(-dt/.07))
   for part,offset in entry.parts do if part.Parent then part.CFrame=entry.frame*offset end end
  end
 end)
end
return Presentation
