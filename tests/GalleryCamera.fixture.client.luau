-- Optional gallery capture camera only. No player move, prompts, ownership,
-- credits or production client edits. Root captures the actual Play viewport.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local metadata = ReplicatedStorage:WaitForChild("CurseReviewGalleryMetadata", 50)
assert(metadata, "Gallery capture metadata is missing")
local deadline = os.clock()+30
while metadata:GetAttribute("Phase") ~= "ready" and os.clock() < deadline do task.wait(.1) end
assert(metadata:GetAttribute("Phase") == "ready", "Gallery capture metadata never became ready")
local report = HttpService:JSONDecode(metadata.Value)
assert(#report.displays == 5, "Gallery capture needs the five actual display records")
-- Allow the untouched production UI and optional initial UI observations to
-- settle before any presentation camera change.
task.wait(8)
local camera = workspace.CurrentCamera
assert(camera, "Actual Play client camera is missing")
local previous = { type = camera.CameraType, frame = camera.CFrame, fov = camera.FieldOfView }
local currentFrame
RunService:BindToRenderStep("CurseReviewGalleryCaptureCamera", Enum.RenderPriority.Camera.Value+1, function()
	if currentFrame then
		local actual = workspace.CurrentCamera
		actual.CameraType = Enum.CameraType.Scriptable; actual.FieldOfView = 65; actual.CFrame = currentFrame
	end
end)
local function show(display, index)
	currentFrame = CFrame.new(table.unpack(display.cameraCFrame))
	metadata:SetAttribute("ClientReviewId", display.id)
	metadata:SetAttribute("ClientReviewState", "capturing")
	metadata:SetAttribute("ClientReviewIndex", index)
	metadata:SetAttribute("ClientReviewHoldSeconds", 30)
	print("CURSE_GALLERY_CAPTURE_BEGIN", display.id, "30 seconds; actual client Scriptable camera; no character move")
	task.wait(30)
	print("CURSE_GALLERY_CAPTURE_END", display.id)
end
local ok, err = pcall(function()
	for index, display in report.displays do show(display, index) end
	-- A final repeat gives the reviewer another chance to capture Common after
	-- checking the first ready event. This is still the same actual static clone.
	show(report.displays[1], 6)
end)
currentFrame = nil
RunService:UnbindFromRenderStep("CurseReviewGalleryCaptureCamera")
camera = workspace.CurrentCamera
camera.CameraType = previous.type; camera.CFrame = previous.frame; camera.FieldOfView = previous.fov
metadata:SetAttribute("ClientReviewId", "")
metadata:SetAttribute("ClientReviewState", if ok then "complete" else "failed")
if not ok then warn("CURSE_GALLERY_CAPTURE_FAILED", err) end
