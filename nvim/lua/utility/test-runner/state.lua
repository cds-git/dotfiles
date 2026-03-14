local M = {}

M.Status = {
	IDLE = "idle",
	RUNNING = "running",
	PASSED = "passed",
	FAILED = "failed",
	SKIPPED = "skipped",
	BUILDING = "building",
	DISCOVERING = "discovering",
}

M.Type = {
	SOLUTION = "solution",
	PROJECT = "project",
	NAMESPACE = "namespace",
	CLASS = "class",
	THEORY = "theory",
	TEST = "test",
}

-- Priority for status propagation (higher wins)
local status_priority = {
	[M.Status.IDLE] = 0,
	[M.Status.SKIPPED] = 1,
	[M.Status.PASSED] = 2,
	[M.Status.FAILED] = 3,
	[M.Status.RUNNING] = 4,
	[M.Status.BUILDING] = 5,
	[M.Status.DISCOVERING] = 6,
}

-- Sort order for node types
local type_order = {
	[M.Type.SOLUTION] = 0,
	[M.Type.PROJECT] = 1,
	[M.Type.NAMESPACE] = 2,
	[M.Type.CLASS] = 3,
	[M.Type.THEORY] = 4,
	[M.Type.TEST] = 5,
}

---@class TestNode
---@field id string
---@field display_name string
---@field type string
---@field status string
---@field expanded boolean
---@field parent_id string|nil
---@field fqn string|nil
---@field project_path string|nil
---@field uses_mtp boolean|nil
---@field duration string|nil
---@field error_message string|nil
---@field stack_trace string|nil
---@field stdout string|nil

---@type table<string, TestNode>
M.nodes = {}
---@type string|nil
M.root_id = nil
---@type string|nil
M.sln_path = nil
---@type number|nil
M.active_job = nil
---@type number[]
M.active_jobs = {}
---@type fun()|nil
M.on_update = nil

-- Children cache: parent_id -> sorted TestNode[]
---@type table<string, TestNode[]>
local children_cache = {}
local children_dirty = true

local function invalidate_children()
	children_dirty = true
	children_cache = {}
end

local function ensure_children_cache()
	if not children_dirty then
		return
	end
	children_cache = {}
	for _, node in pairs(M.nodes) do
		if node.parent_id then
			local list = children_cache[node.parent_id]
			if not list then
				list = {}
				children_cache[node.parent_id] = list
			end
			list[#list + 1] = node
		end
	end
	for _, list in pairs(children_cache) do
		table.sort(list, function(a, b)
			local ta, tb = type_order[a.type] or 9, type_order[b.type] or 9
			if ta ~= tb then
				return ta < tb
			end
			return a.display_name < b.display_name
		end)
	end
	children_dirty = false
end

function M.clear()
	M.nodes = {}
	M.root_id = nil
	invalidate_children()
end

---@param node TestNode
function M.register(node)
	local existing = M.nodes[node.id]
	if existing then
		node.expanded = existing.expanded
	end
	M.nodes[node.id] = node
	invalidate_children()
end

---@param id string
---@return TestNode|nil
function M.get(id)
	return M.nodes[id]
end

---@param parent_id string
---@return TestNode[]
function M.children(parent_id)
	ensure_children_cache()
	return children_cache[parent_id] or {}
end

---@param id string|nil
function M.propagate_status(id)
	if not id then
		return
	end
	local node = M.nodes[id]
	if not node then
		return
	end
	local kids = M.children(id)
	if #kids == 0 then
		return
	end
	local best, best_pri = M.Status.IDLE, 0
	for _, child in ipairs(kids) do
		local pri = status_priority[child.status] or 0
		if pri > best_pri then
			best, best_pri = child.status, pri
		end
	end
	node.status = best
	M.propagate_status(node.parent_id)
end

---@param id string
---@param status string
---@param details? { duration: string, error_message: string, stack_trace: string, stdout: string }
function M.update_status(id, status, details)
	local node = M.nodes[id]
	if not node then
		return
	end
	node.status = status
	if details then
		node.duration = details.duration
		node.error_message = details.error_message
		node.stack_trace = details.stack_trace
		node.stdout = details.stdout
	end
	M.propagate_status(node.parent_id)
	if M.on_update then
		M.on_update()
	end
end

---@param callback fun(node: TestNode, depth: number)
function M.traverse_visible(callback)
	if not M.root_id then
		return
	end
	local function walk(id, depth)
		local node = M.nodes[id]
		if not node then
			return
		end
		callback(node, depth)
		if node.expanded then
			for _, child in ipairs(M.children(id)) do
				walk(child.id, depth + 1)
			end
		end
	end
	walk(M.root_id, 0)
end

---@param node_id string
---@param status string
function M.set_descendants_status(node_id, status)
	for _, child in ipairs(M.children(node_id)) do
		if child.type == M.Type.TEST then
			child.status = status
			child.duration = nil
			child.error_message = nil
			child.stack_trace = nil
			child.stdout = nil
		end
		M.set_descendants_status(child.id, status)
	end
end

---@param node_id string
---@param expanded boolean
local function set_expanded_recursive(node_id, expanded)
	local node = M.nodes[node_id]
	if not node then
		return
	end
	node.expanded = expanded
	for _, child in ipairs(M.children(node_id)) do
		set_expanded_recursive(child.id, expanded)
	end
end

function M.expand_all(node_id)
	set_expanded_recursive(node_id, true)
end

function M.collapse_all(node_id)
	set_expanded_recursive(node_id, false)
end

---@param node_id? string
---@return { total: number, passed: number, failed: number, skipped: number }
function M.counts(node_id)
	local c = { total = 0, passed = 0, failed = 0, skipped = 0 }
	if node_id then
		for _, child in ipairs(M.children(node_id)) do
			if child.type == M.Type.TEST then
				c.total = c.total + 1
				if child.status == M.Status.PASSED then
					c.passed = c.passed + 1
				elseif child.status == M.Status.FAILED then
					c.failed = c.failed + 1
				elseif child.status == M.Status.SKIPPED then
					c.skipped = c.skipped + 1
				end
			else
				local sub = M.counts(child.id)
				c.total = c.total + sub.total
				c.passed = c.passed + sub.passed
				c.failed = c.failed + sub.failed
				c.skipped = c.skipped + sub.skipped
			end
		end
	else
		for _, node in pairs(M.nodes) do
			if node.type == M.Type.TEST then
				c.total = c.total + 1
				if node.status == M.Status.PASSED then
					c.passed = c.passed + 1
				elseif node.status == M.Status.FAILED then
					c.failed = c.failed + 1
				elseif node.status == M.Status.SKIPPED then
					c.skipped = c.skipped + 1
				end
			end
		end
	end
	return c
end

--- Parse a formatted duration string back to milliseconds
---@param dur string|nil
---@return number
local function parse_duration_ms(dur)
	if not dur then
		return 0
	end
	local val, unit = dur:match("^([%d%.]+)(.*)")
	local n = tonumber(val) or 0
	if unit == "ms" then
		return n
	elseif unit == "s" then
		return n * 1000
	elseif unit == "m" then
		return n * 60000
	end
	return 0
end

--- Format milliseconds to a human-readable duration
---@param ms number
---@return string
function M.format_ms(ms)
	if ms <= 0 then
		return ""
	elseif ms >= 60000 then
		return string.format("%.1fm", ms / 60000)
	elseif ms >= 1000 then
		return string.format("%.1fs", ms / 1000)
	end
	return string.format("%.0fms", ms)
end

--- Sum durations of all test descendants
---@param node_id string
---@return number ms
function M.total_duration_ms(node_id)
	local total = 0
	for _, child in ipairs(M.children(node_id)) do
		if child.type == M.Type.TEST then
			total = total + parse_duration_ms(child.duration)
		else
			total = total + M.total_duration_ms(child.id)
		end
	end
	return total
end

function M.cancel()
	if M.active_job then
		pcall(vim.fn.jobstop, M.active_job)
		M.active_job = nil
	end
	for _, job in ipairs(M.active_jobs) do
		pcall(vim.fn.jobstop, job)
	end
	M.active_jobs = {}
end

return M
