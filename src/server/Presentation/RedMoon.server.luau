-- Starts the Red Moon schedule. Lives in its own Script so the shared server
-- entry point (init.server.luau) stays untouched.
require(script.Parent.RedMoonService).start()
