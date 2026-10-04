-- Pure check of The Void's shared act envelope (no Studio needed). Run from
-- the repo root:
--   lune run tools/void_motion_check.luau
-- Fails (exit 1) if Motion.voidPull loses its 8.4 s period, its beat order,
-- its stillness in the hold, its continuity at the wrap or its bounds.
local process = require("@lune/process")

local Motion = require("../src/shared/CurseMotionMath")

local failures, checks = {}, 0
local function check(ok: boolean, message: string)
	checks += 1
	if not ok then table.insert(failures, message) end
end

local period, beats = Motion.VoidPeriod, Motion.VoidBeats
check(period == 8.4, "VoidPeriod must stay 8.4 s (the act cycle)")
check(0 < beats.draw and beats.draw < beats.tension and beats.tension < beats.release
	and beats.release < beats.settle and beats.settle < period, "Void beats must be ordered hold < draw < tension < release < settle < period")

-- Dense sample of one cycle (plus an epoch-sized offset, like server time).
local STEP = 0.001
local base = 1.75e9 - (1.75e9 % period)
local minDraw, maxDraw, minAt, peakRelease, peakAt = math.huge, -math.huge, 0, 0, 0
local holdStill, settleQuiet, finite, ranged, timed, leanMin = true, true, true, true, true, 0
local previous
local maxJump = 0
for i = 0, math.floor(period / STEP) do
	local p = i * STEP
	local draw, release, tension, phase = Motion.voidPull(p)
	if draw ~= draw or release ~= release or tension ~= tension then finite = false end
	if draw < minDraw then minDraw, minAt = draw, p end
	maxDraw = math.max(maxDraw, draw)
	if release > peakRelease then peakRelease, peakAt = release, p end
	if release < 0 or release > 1 or tension < 0 or tension > 1 then ranged = false end
	if math.abs(phase - p) > 1e-9 and p < period - STEP then timed = false end
	if p < beats.draw and (draw ~= 0 or release ~= 0) then holdStill = false end
	if p > beats.draw and p < beats.draw + 0.7 then leanMin = math.min(leanMin, draw) end
	if p > beats.settle + 0.05 and math.abs(draw) > 0.05 then settleQuiet = false end
	-- Only the release is allowed to move fast (it is a snap, not a jump).
	if previous and math.abs(p - beats.release) > STEP * 1.5 then maxJump = math.max(maxJump, math.abs(draw - previous)) end
	previous = draw
end
check(finite, "envelope must never return NaN")
check(ranged, "release and tension must stay within 0..1")
check(timed, "the returned cycle time must equal t % 8.4")
check(holdStill, "HOLD must be perfectly still (draw = 0, release = 0)")
check(leanMin < -0.08 and leanMin > -0.25, `anticipation lean must dip outward first (got {leanMin})`)
local _, _, tensionMid = Motion.voidPull((beats.tension + beats.release) / 2)
check(tensionMid > 0.99, "tension must hold between the draw and the release")
local drawnIn = Motion.voidPull(beats.tension)
check(drawnIn > 0.98, `draw must arrive by the tension beat (got {drawnIn})`)
check(peakAt > beats.release and peakAt < beats.release + 0.3 and peakRelease > 0.9, `release must peak just after the release beat (at {peakAt})`)
check(minAt > beats.release and minAt < beats.release + 0.7 and minDraw < -0.3, `release must overshoot past rest (min {minDraw} at {minAt})`)
check(settleQuiet, "draw must be settled after the settle beat")
check(maxDraw <= 1.1 and minDraw >= -0.5, `draw out of bounds ({minDraw}..{maxDraw})`)
check(maxJump < 0.01, `draw must be continuous outside the release snap (max step {maxJump})`)

-- Continuity at the wrap and periodicity (also at epoch-sized times).
local beforeWrap = Motion.voidPull(period - 1e-6)
local atWrap = Motion.voidPull(0)
check(math.abs(beforeWrap - atWrap) < 1e-4, "draw must be continuous at the wrap")
for _, p in { 0.4, 1.8, 3, 4.6, 5.85, 6.2, 7.9 } do
	local a, ra, ta = Motion.voidPull(p)
	local b, rb, tb = Motion.voidPull(base + p)
	local c = Motion.voidPull(p + period * 3)
	check(math.abs(a - b) < 1e-3 and math.abs(ra - rb) < 1e-3 and math.abs(ta - tb) < 1e-3, `period broken at epoch + {p}`)
	check(math.abs(a - c) < 1e-6, `period broken at {p} + 3 cycles`)
end

if #failures > 0 then
	for _, message in failures do print("[FAIL] " .. message) end
	print(`[SUMMARY] {checks} checks, {#failures} failed`)
	process.exit(1)
end
print(`[PASS] void motion: {checks} checks`)
