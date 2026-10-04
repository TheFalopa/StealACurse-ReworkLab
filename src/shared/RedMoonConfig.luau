-- Single source of truth for the Red Moon event timing and presentation knobs.
-- Schedule: every real-world day at StartHour:StartMinute in the US Pacific
-- time zone (America/Los_Angeles), following PST/PDT automatically.
return {
	StartHour = 22, -- 10:00 PM Pacific
	StartMinute = 0,
	DurationSeconds = 20 * 60, -- active window length
	WarningSeconds = 12, -- "the moon stirs" lead-in before the start
	RiseSeconds = 6, -- sky/lighting transition into the event (client)
	SetSeconds = 8, -- transition back to the normal night (client)
	AnnouncementSeconds = 4.5, -- how long the RED MOON RISING banner holds

	-- Exposed to gameplay through RedMoonService.getMutationWeightMultiplier().
	-- No mutation system exists yet; nothing consumes this value today.
	MutationWeightMultiplier = 3,

	-- Studio-only debug: length of a forced event (see RedMoonService).
	DebugDurationSeconds = 90,

	-- Lighting.ClockTime during the event: places the moon low enough to be a
	-- visible focal point from normal gameplay cameras.
	-- 19.8 puts the moon ~25 degrees above the horizon (latitude 41.7).
	EventClockTime = 19.8,
}
