-- Review-fixture-only summaries. No updater loops, inputs, remotes, state
-- changes, purchases or movement. Call from the intended server/client context.
local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ReviewSummary = {}

local function firstItems(values, limit)
	local result = {}
	for index = 1, math.min(#(values or {}), limit) do table.insert(result, values[index]) end
	return result
end
local function finite(value)
	return if typeof(value) == "number" and value == value and math.abs(value) < math.huge then value else "not sampled"
end
local function vector(value)
	return { value.X, value.Y }
end
local function bounds(object)
	return if object and object:IsA("GuiObject") then { position = vector(object.AbsolutePosition), size = vector(object.AbsoluteSize) } else nil
end
local function reportIssues(report)
	return { failureCount = #(report.failures or {}), warningCount = #(report.warnings or {}),
		failures = firstItems(report.failures, 8), warnings = firstItems(report.warnings, 5) }
end
local function worldSummary()
	local report = _G.QualityPassReport
	if not report then return { available = false, reason = "Server QualityPass report not available in this context yet" } end
	local result = reportIssues(report)
	result.available, result.counts, result.footprint, result.layout = true, report.counts, report.footprint, report.layout
	result.groundedPlacementRecords = #(report.grounding or {})
	result.bases, result.paths = report.bases, report.paths
	return result
end
local function expansionSummary()
	local report = _G.ExpansionReport
	if not report then return { available = false, reason = "Server Expansion report not available in this context yet" } end
	local result = reportIssues(report)
	result.available, result.phase, result.observedSeconds, result.counts = true, report.phase, report.observedSeconds, report.counts
	local catalog, route = report.catalog, report.procession
	result.catalog = { total = catalog.total, expansion = catalog.expansion, firstWave = catalog.firstWave,
		availableFirstWaveTemplates = catalog.availableFirstWaveTemplates, statuses = catalog.statuses,
		rarities = catalog.rarities, pendingImports = catalog.pendingImports }
	result.procession = { points = route.points, lengthStuds = route.lengthStuds, routeArtSegments = route.routeArtSegments,
		maximumSimultaneous = route.maximumSimultaneous, observedModels = route.observedModels,
		naturalUnsoldExits = route.naturalUnsoldExits, purchasedModels = route.purchasedModels,
		castleEmergences = route.castleEmergences, samples = route.samples, unsupportedSegments = route.unsupportedSegments,
		solidBoundsCandidateCount = #(route.solidBoundsCandidates or {}), solidBoundsCandidates = firstItems(route.solidBoundsCandidates, 8),
		visualTreeBoundsCandidateCount = #(route.visualTreeBoundsCandidates or {}), visualTreeBoundsCandidates = firstItems(route.visualTreeBoundsCandidates, 5),
		minimumX = finite(route.minimumX), maximumX = finite(route.maximumX), minimumZ = finite(route.minimumZ), maximumZ = finite(route.maximumZ) }
	return result
end
local function readLogs(limit)
	local ok, history = pcall(function() return LogService:GetLogHistory() end)
	if not ok then return {}, nil, "LogService history unavailable: " .. tostring(history) end
	local events, uiReport = {}, nil
	-- Bounded scan per explicit request, not an event listener or background loop.
	for index = #history, math.max(1, #history - 199), -1 do
		local entry = history[index]
		local message = tostring(entry.message or "")
		if not uiReport then
			local json = string.match(message, "^QUALITY_UI_REPORT%s+({.*})$")
			if json then
				local decoded, value = pcall(function() return HttpService:JSONDecode(json) end)
				if decoded and typeof(value) == "table" then uiReport = value end
			end
		end
		local marker = string.match(message, "^([A-Z][A-Z_]+)")
		local warning = entry.messageType == Enum.MessageType.MessageWarning or entry.messageType == Enum.MessageType.MessageError
		local relevant = marker and (string.match(marker, "^QUALITY_") or string.match(marker, "^EXPANSION_")
			or string.match(marker, "^FINAL_") or string.match(marker, "^SLICE_"))
		if #events < limit and (warning or relevant) then
			table.insert(events, 1, { marker = marker or "STUDIO_MESSAGE", type = tostring(entry.messageType),
				time = finite(entry.timestamp), message = string.sub(message, 1, 280), truncated = #message > 280 })
		end
	end
	return events, uiReport
end
local function uiSummary(lastReport)
	local player = Players.LocalPlayer
	local playerGui = player and player:FindFirstChild("PlayerGui")
	local gui = playerGui and playerGui:FindFirstChild("StealACurseHUD")
	if not gui then return { available = false, reason = "Client HUD not available in this context yet", lastObservedReport = lastReport } end
	local holder = gui:FindFirstChild("SoulsHUD")
	local card = holder and holder:FindFirstChild("Card")
	local shop = gui:FindFirstChild("ShopOverlay")
	local panel = shop and shop:FindFirstChild("ShopPanel")
	local pages = {}
	for _, name in { "Passes", "Boosts", "SoulPacks" } do
		local page = panel and panel:FindFirstChild(name .. "Page")
		if page and page:IsA("ScrollingFrame") then
			table.insert(pages, { name = name, visible = page.Visible, canvasPosition = vector(page.CanvasPosition),
				canvasSize = vector(page.AbsoluteCanvasSize), windowSize = vector(page.AbsoluteWindowSize),
				hasVerticalOverflow = page.AbsoluteCanvasSize.Y > page.AbsoluteWindowSize.Y + 1, scrollingEnabled = page.ScrollingEnabled })
		end
	end
	local amount = card and card:FindFirstChild("Amount")
	local rate = card and card:FindFirstChild("SoulsPerSecond")
	local camera = workspace.CurrentCamera
	return { available = true, viewport = camera and vector(camera.ViewportSize), safeSize = vector(gui.AbsoluteSize),
		card = bounds(card), navigation = bounds(gui:FindFirstChild("Navigation")),
		soulsText = amount and amount.Text, rateText = rate and rate.Text,
		soulsAttribute = player:GetAttribute("Souls"), rateAttribute = player:GetAttribute("SoulsPerSecond"),
		shopVisible = shop and shop.Visible, selectedTab = panel and panel:GetAttribute("SelectedTab"), pages = pages,
		lastObservedReport = lastReport,
		method = "Current UI snapshot plus latest retained QUALITY_UI_REPORT. Not new validation, proof of input, or hardware FPS." }
end
local function travelSummary()
	local module = ReplicatedStorage:FindFirstChild("TestFinalWalk")
	if not RunService:IsClient() or not module then return { available = false, reason = "FinalWalk is a client fixture module" } end
	local summary = require(module).summary()
	local result = { available = true, busy = summary.busy, progress = summary.progress, completedRuns = summary.completedRuns }
	local last = summary.lastResult
	if last then
		result.lastRun = { runId = last.runId, reached = last.reached, elapsedSeconds = last.elapsedSeconds, failure = last.failure, legs = {} }
		for _, leg in firstItems(last.legs, 8) do
			table.insert(result.lastRun.legs, { label = leg.label, target = leg.target, reached = leg.reached, failure = leg.failure,
				walkSpeed = leg.walkSpeed, planningSeconds = leg.planningSeconds, actualWalkingSeconds = leg.actualWalkingSeconds,
				actualDistanceStuds = leg.actualDistanceStuds, pathLengthStuds = leg.pathLengthStuds, actualJumps = leg.actualJumps })
		end
	end
	return result
end
function ReviewSummary.summary(logLimit: number?)
	local limit = math.clamp(math.floor(logLimit or 8), 0, 20)
	local logs, uiReport, logError = readLogs(limit)
	return { context = if RunService:IsClient() then "client" else "server", world = worldSummary(), expansion = expansionSummary(),
		ui = uiSummary(uiReport), travel = travelSummary(), logs = logs, logError = logError,
		method = "Read-only compact evidence. Server/client globals are separate; READY is not DONE. No inputs or state changes." }
end
function ReviewSummary.install()
	_G.ReportSummary = ReviewSummary.summary
	_G.PrintReportSummary = ReviewSummary.printSummary
	print("REVIEW_SUMMARY_READY", if RunService:IsClient() then "client" else "server", "CommandBar: require(game.ReplicatedStorage.TestReviewSummary).printSummary(); readonly")
end
function ReviewSummary.printSummary(logLimit: number?)
	local result = ReviewSummary.summary(logLimit)
	print("REVIEW_SUMMARY", HttpService:JSONEncode(result))
	return result
end
return ReviewSummary
