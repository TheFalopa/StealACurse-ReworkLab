-- Fixture-only presentation camera. Does not move the character, alter the
-- environment, Lighting, gameplay, balances or remotes. Explicit manual calls.
local Players = game:GetService("Players")
local ReviewCamera = {}
local previous
local presets = {
	aerial = { Vector3.new(420, 620, 490), Vector3.new(0, 0, 0) },
	castleFront = { Vector3.new(57, 32, 100), Vector3.new(0, 24, -38) },
	castleSide = { Vector3.new(-133, 46, -87), Vector3.new(0, 24, -44) },
	route = { Vector3.new(-144, 81, 112), Vector3.new(-20, 3, -20) },
	sanctuary = { Vector3.new(28, 28, -246), Vector3.new(-12, 3, -299) },
	between = { Vector3.new(-182, 18, -216), Vector3.new(-102, 2, -241) },
	graveyard = { Vector3.new(-334, 15, 228), Vector3.new(-275, 3, 181) },
	forest = { Vector3.new(191, 19, -285), Vector3.new(279, 11, -287) },
	halloween = { Vector3.new(-161, 13, 153), Vector3.new(-181, 5, 116) },
	trees = { Vector3.new(-139, 29, 162), Vector3.new(-181, 29, 116) },
	material = { Vector3.new(-4, 9, -270), Vector3.new(-12, 8, -280) },
	gallery = { Vector3.new(500, 29, -52), Vector3.new(500, 2.5, 0) },
	galleryCommon = { Vector3.new(500, 7, -24), Vector3.new(500, 2.5, -10) },
	galleryRare = { Vector3.new(500, 7, -14), Vector3.new(500, 2.5, 0) },
	galleryRelics = { Vector3.new(500, 8, -5), Vector3.new(500, 3, 10) },
}
function ReviewCamera.frame(position: Vector3, target: Vector3)
	assert(Players.LocalPlayer, "ReviewCamera requires the real Play client")
	local camera = workspace.CurrentCamera
	assert(camera, "Camera missing")
	if not previous then previous = { type = camera.CameraType, frame = camera.CFrame, field = camera.FieldOfView } end
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = 65
	camera.CFrame = CFrame.lookAt(position, target)
	print("REVIEW_CAMERA", position, target, "presentation only; character unmoved")
end
function ReviewCamera.preset(name: string)
	local item = presets[name]
	assert(item, "Unknown review camera preset: " .. name)
	ReviewCamera.frame(item[1], item[2])
end
function ReviewCamera.restore()
	local camera = workspace.CurrentCamera
	assert(camera and previous, "No review camera to restore")
	camera.CameraType = previous.type
	camera.FieldOfView = previous.field
	camera.CFrame = previous.frame
	previous = nil
	print("REVIEW_CAMERA_RESTORED", "normal character camera")
end
return ReviewCamera
