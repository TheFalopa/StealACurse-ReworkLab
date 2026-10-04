-- Presentation for mutated Curses. Contract (owned by codex/gameplay):
--   Curse model attribute "Mutation" = "Blood" (more kinds may follow).
-- No mutation system exists yet; this layer renders as soon as gameplay sets
-- the attribute. It ADDS a controlled crimson accent on top of the Curse's own
-- effect, so the Curse keeps its identity instead of being recoloured.
local Kit = require(script.Parent.Kit)

local CRIMSON = Color3.fromRGB(240, 40, 70)
local DEEP = Color3.fromRGB(110, 6, 26)

local Mutations = {}

local BUILDERS = {}

BUILDERS.Blood = function(fx)
	local s = fx.scale
	local size = fx.size
	local center = fx:attach("BloodCore", Vector3.new(0, 0, 0))
	local base = fx:attach("BloodBase", Vector3.new(0, -size.Y * 0.45, 0))
	fx:emitter("BloodAura", center, 0.6, {
		Texture = "glow_soft", Color = DEEP, Size = math.max(size.X, size.Y) * 0.95, Lifetime = 3, Speed = 0,
		Transparency = { { 0, 1 }, { 0.3, 0.55 }, { 0.7, 0.55 }, { 1, 1 } },
		LightEmission = 1, ZOffset = -2.5, LockedToPart = true,
	})
	local footprint = fx:volume("BloodBase", Vector3.new(size.X * 0.8, 0.2, math.max(1, size.Z) * 0.8), base)
	local embers = fx:emitter("BloodEmbers", footprint, 7, {
		Texture = "ember", Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		EmissionDirection = Enum.NormalId.Top, Speed = { 1.2 * s, 2.4 * s }, Lifetime = { 1.2, 2 },
		Acceleration = Vector3.new(0, 0.6, 0) * s, Drag = 0.5,
		Size = { { 0, 0.22 * s }, { 1, 0 } }, Squash = 0.8, Orientation = Enum.ParticleOrientation.VelocityParallel,
		Color = { { 0, Color3.fromRGB(255, 160, 140) }, { 0.4, CRIMSON }, { 1, DEEP } },
		Transparency = { { 0, 0.1 }, { 1, 1 } }, LightEmission = 1, ZOffset = 0.5,
	})
	local pulse = fx:emitter("BloodPulse", center, 0, {
		Texture = "glow_soft", Color = CRIMSON, Lifetime = 0.6, Speed = 0,
		Size = { { 0, size.X * 0.5 }, { 1, size.X * 1.2 } }, Transparency = { { 0, 0.55 }, { 1, 1 } },
		LightEmission = 1, ZOffset = -1, LockedToPart = true,
	})
	fx:light("BloodLight", center, CRIMSON, 9 * s, 0.9)
	local last = -math.huge
	return {
		update = function(t: number)
			local cycle = (t + fx.phase) % 2.2
			if cycle < 0.1 and t - last > 1 then
				last = t
				fx:burst(pulse, 1)
				fx:burst(embers, 5)
			end
			fx:setLight(1, 0.6 + 0.6 * math.exp(-cycle * 3))
		end,
	}
end

function Mutations.kind(model: Model): string?
	local kind = model:GetAttribute("Mutation")
	return if typeof(kind) == "string" and BUILDERS[kind] then kind else nil
end

-- Returns an effect + controller, or nil when the model has no supported mutation.
function Mutations.build(model: Model, root: BasePart)
	local kind = Mutations.kind(model)
	if not kind then return nil end
	local fx = Kit.new(model, root)
	local ok, controller = pcall(BUILDERS[kind], fx)
	if not ok then
		fx:destroy()
		warn("Mutation VFX failed: " .. tostring(controller))
		return nil
	end
	return { fx = fx, controller = controller, kind = kind }
end

return Mutations
