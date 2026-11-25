-- Animated spinner notification for anything that takes a while.
--
--   local stop = require("utility.spinner").start("Finding references...")
--   -- ... later, when done:
--   stop()
local M = {}

local frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local counter = 0

---@param msg string
---@param opts? { title?: string }
---@return fun() stop Hides the notification. Safe to call more than once.
function M.start(msg, opts)
	opts = opts or {}
	counter = counter + 1
	local id = "spinner_" .. counter
	local frame = 1
	local timer = assert(vim.uv.new_timer())
	local stopped = false

	local function show()
		if stopped then
			return
		end
		vim.notify(frames[frame] .. " " .. msg, vim.log.levels.INFO, { id = id, timeout = false, title = opts.title })
		frame = frame % #frames + 1
	end
	show()
	timer:start(100, 100, vim.schedule_wrap(show))

	return function()
		if stopped then
			return
		end
		stopped = true
		timer:stop()
		timer:close()
		Snacks.notifier.hide(id)
	end
end

return M
