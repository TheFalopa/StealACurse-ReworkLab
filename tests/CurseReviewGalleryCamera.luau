-- Optional manual client camera selector. Existing production client/VFX remain
-- intact; nothing happens until a reviewer explicitly calls frame(id).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local GalleryCamera = {}
local previous
function GalleryCamera.frame(id: string)
	assert(Players.LocalPlayer, "Gallery camera requires the actual Play client")
	local value = ReplicatedStorage:WaitForChild("CurseReviewGalleryMetadata", 40)
	assert(value and value:GetAttribute("Phase") == "ready", "Actual gallery metadata is not ready")
	local data = HttpService:JSONDecode(value.Value)
	local display
	for _, item in data.displays do if item.id == id then display = item; break end end
	assert(display, "Unknown actual gallery ID: " .. id)
	local camera = workspace.CurrentCamera
	assert(camera, "Actual client camera is missing")
	if not previous then previous = { camera.CameraType, camera.CFrame, camera.FieldOfView } end
	camera.CameraType = Enum.CameraType.Scriptable; camera.FieldOfView = 65
	camera.CFrame = CFrame.new(table.unpack(display.cameraCFrame))
	value:SetAttribute("ClientReviewId", id)
	value:SetAttribute("ClientCameraType", camera.CameraType.Name)
	print("CURSE_REVIEW_CAMERA", id, "actual client Scriptable camera; character unmoved")
	return display
end
function GalleryCamera.restore()
	local camera = workspace.CurrentCamera
	assert(previous and camera, "No gallery camera to restore")
	camera.CameraType = previous[1]; camera.CFrame = previous[2]; camera.FieldOfView = previous[3]
	previous = nil
end
return GalleryCamera
