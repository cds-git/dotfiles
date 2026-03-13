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
---@type fun()|nil
M.on_update = nil

function M.clear()
	M.nodes = {}
	M.root_id = nil
end

---@param node TestNode
function M.register(node)
	local existing = M.nodes[node.id]
	if existing then
		node.expanded = existing.expanded
	end
	M.nodes[node.id] = node
end

---@param id string
---@return TestNode|nil
function M.get(id)
	return M.nodes[id]
end

---@param parent_id string
---@return TestNode[]
function M.children(parent_id)
	local result = {}
	for _, node in pairs(M.nodes) do
		if node.parent_id == parent_id then
			result[#result + 1] = node
		end
	end
	table.sort(result, function(a, b)
		local ta, tb = type_order[a.type] or 9, type_order[b.type] or 9
		if ta ~= tb then
			return ta < tb
		end
		return a.display_name < b.display_name
	end)
	return result
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

---@return { total: number, passed: number, failed: number, skipped: number }
function M.counts()
	local c = { total = 0, passed = 0, failed = 0, skipped = 0 }
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
	return c
end

function M.cancel()
	if M.active_job then
		vim.fn.jobstop(M.active_job)
		M.active_job = nil
	end
end

return M
