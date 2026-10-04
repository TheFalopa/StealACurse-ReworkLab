-- ReworkLab static safety check (no Studio needed). Run from the repo root:
--   lune run tools/lab_safety_check.luau
-- Fails (exit 1) if lab monetization or persistence isolation regresses:
-- real purchases enabled, a configured offer ID, a second receipt handler,
-- an unguarded purchase prompt, or a DataStore outside the lab store name.
local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local ToolCatalog = require("../src/shared/ToolCatalog")
local GameplayConfig = require("../src/server/Gameplay/Config")

local failures, checks = {}, 0
local function check(ok: boolean, message: string)
	checks += 1
	if not ok then table.insert(failures, message) end
end

-- 1. Commerce stays disabled with unset IDs.
check(ToolCatalog.RealPurchasesEnabled == false, "ToolCatalog.RealPurchasesEnabled must be false")
for key, offer in ToolCatalog.Offers do
	check(offer.id == 0, `ToolCatalog.Offers.{key}.id must stay 0 (unset)`)
	check(offer.enabled == false, `ToolCatalog.Offers.{key}.enabled must stay false`)
end
-- ProgressionConfig builds Color3 values, so it is checked as text here.
local progression = fs.readFile("src/shared/ProgressionConfig.luau")
check(progression:match("PaidSpinsEnabled%s*=%s*false") ~= nil and not progression:match("PaidSpinsEnabled%s*=%s*true"), "Wheel.PaidSpinsEnabled must stay false")

-- 2. Persistence is lab-isolated and fails closed.
check(GameplayConfig.ProfileStoreName == "StealACurseReworkLab_ProfilesV1", "Live profile store must be the lab-only name")
check(next(GameplayConfig.LiveProfileGameIds) == nil, "LiveProfileGameIds must be empty in the lab (fail closed)")

-- 2b. Studio saves use the lab's own local slot, never the shared "play" slot.
local namespace = GameplayConfig.LocalProfileNamespace
check(namespace == "reworklab", "Config.LocalProfileNamespace must be the lab slot 'reworklab'")
check(typeof(namespace) == "string" and namespace ~= "play" and namespace:match("^qa%-") == nil, "Lab namespace must not be the shared 'play' slot or a QA slot")
local project = serde.decode("json", fs.readFile("default.project.json"))
local bridge = project.tree.ServerStorage and project.tree.ServerStorage.LocalProfileBridge
local attributes = bridge and bridge["$attributes"]
check(bridge ~= nil and bridge["$className"] == "Folder", "default.project.json must define ServerStorage.LocalProfileBridge (Folder)")
check(attributes ~= nil and attributes.Namespace == namespace, "LocalProfileBridge.Namespace must equal Config.LocalProfileNamespace")
check(fs.readFile("src/server/Gameplay/ProfileStore.luau"):find("namespace==Config.LocalProfileNamespace", 1, true) ~= nil, "ProfileStore must refuse Studio slots other than the lab/QA namespaces")
check(fs.readFile("src/server/Gameplay/TheftLedger.luau"):find("assert(labSlot()", 1, true) ~= nil, "TheftLedger must refuse Studio slots other than the lab/QA namespaces")

-- 3. Source scan: one receipt handler, guarded prompts, no foreign stores.
local function walk(dir: string, out: { string })
	for _, name in fs.readDir(dir) do
		local path = `{dir}/{name}`
		if fs.isDir(path) then walk(path, out) elseif name:match("%.luau?$") then table.insert(out, path) end
	end
	return out
end
local receiptHandlers, promptFiles = 0, {}
for _, path in walk("src", {}) do
	local source = fs.readFile(path)
	for line in source:gmatch("[^\n]+") do
		local code = line:gsub("%-%-.*$", "")
		if code:match("ProcessReceipt%s*=") then receiptHandlers += 1 end
		if code:match("Prompt%w*Purchase%s*%(") then promptFiles[path] = true end
		if code:match("GetDataStore%s*%(") or code:match("GetOrderedDataStore%s*%(") then
			check(code:match("GetDataStore%(Config%.ProfileStoreName%)") ~= nil, `{path}: DataStore must use Config.ProfileStoreName`)
		end
		if code:match("StealACurseProfilesV1") then table.insert(failures, `{path}: production store name literal is not allowed in the lab`) end
	end
end
check(receiptHandlers == 1, `Expected exactly one ProcessReceipt assignment, found {receiptHandlers}`)
for path in promptFiles do
	-- The only client prompt path asks the server first ('offer' fails closed
	-- while RealPurchasesEnabled is false) and returns before prompting.
	check(path == "src/client/ToolOffers.luau", `{path}: unexpected purchase prompt`)
	local source = fs.readFile(path)
	check(source:find("local offer=O.describe(id);if not offer.ok then return offer end", 1, true) ~= nil, `{path}: purchase prompt must return when the server refuses the offer`)
	local server = fs.readFile("src/server/Gameplay/ToolCommerce.luau")
	check(server:find("if not C.RealPurchasesEnabled or not configured(o)or Run:IsStudio()then return {ok=false", 1, true) ~= nil, "ToolCommerce 'offer' must refuse while purchases are disabled")
end

if #failures > 0 then
	for _, message in failures do print("[FAIL] " .. message) end
	print(`[SUMMARY] {checks} checks, {#failures} failed`)
	process.exit(1)
end
print(`[PASS] lab safety: {checks} checks`)
