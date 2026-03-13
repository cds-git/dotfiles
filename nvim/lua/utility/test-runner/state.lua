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

---@class TestNode
---@field id string
---@field display_name string
---@field type string
---@field status string
---@field expanded boolean
---@field parent_id string|nil
---@field fqn string|nil -- fully qualified test name
---@field project_path string|nil -- .csproj path for project nodes
---@field duration string|nil
---@field error_message string|nil
---@field stack_trace string|nil
---@field stdout string|nil

--- All nodes keyed by id
---@type table<string, TestNode>
M.nodes = {}

--- Root node id (the solution)
---@type string|nil
M.root_id = nil

--- Solution path
---@type string|nil
M.sln_path = nil

--- Currently active job id
---@type number|nil
M.active_job = nil

--- Callback fired whenever state changes (for UI refresh)
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

--- Get sorted children of a parent node
---@param parent_id string
---@return TestNode[]
function M.children(parent_id)
	local result = {}
	for _, node in pairs(M.nodes) do
		if node.parent_id == parent_id then
			table.insert(result, node)
		end
	end
	table.sort(result, function(a, b)
		-- Sort by type first (namespaces before classes before tests), then name
		local type_order = {
			[M.Type.SOLUTION] = 0,
			[M.Type.PROJECT] = 1,
			[M.Type.NAMESPACE] = 2,
			[M.Type.CLASS] = 3,
			[M.Type.THEORY] = 4,
			[M.Type.TEST] = 5,
		}
		local ta = type_order[a.type] or 9
		local tb = type_order[b.type] or 9
		if ta ~= tb then
			return ta < tb
		end
		return a.display_name < b.display_name
	end)
	return result
end

--- Update status of a node and propagate to parents
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

--- Propagate aggregated status from children to parent
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

	local has_running = false
	local has_failed = false
	local has_skipped = false
	local has_passed = false
	local has_building = false

	for _, child in ipairs(kids) do
		if child.status == M.Status.RUNNING then
			has_running = true
		end
		if child.status == M.Status.BUILDING then
			has_building = true
		end
		if child.status == M.Status.FAILED then
			has_failed = true
		end
		if child.status == M.Status.SKIPPED then
			has_skipped = true
		end
		if child.status == M.Status.PASSED then
			has_passed = true
		end
	end

	if has_building then
		node.status = M.Status.BUILDING
	elseif has_running then
		node.status = M.Status.RUNNING
	elseif has_failed then
		node.status = M.Status.FAILED
	elseif has_passed and not has_skipped then
		node.status = M.Status.PASSED
	elseif has_skipped then
		node.status = M.Status.SKIPPED
	end

	M.propagate_status(node.parent_id)
end

--- Walk visible (expanded) nodes in display order
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

--- Set all descendant test nodes to a status (clears details)
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

--- Expand a node and all its descendants
---@param node_id string
function M.expand_all(node_id)
	local node = M.nodes[node_id]
	if not node then
		return
	end
	node.expanded = true
	for _, child in ipairs(M.children(node_id)) do
		M.expand_all(child.id)
	end
end

--- Collapse a node and all its descendants
---@param node_id string
function M.collapse_all(node_id)
	local node = M.nodes[node_id]
	if not node then
		return
	end
	node.expanded = false
	for _, child in ipairs(M.children(node_id)) do
		M.collapse_all(child.id)
	end
end

--- Get test counts for display
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

--- Cancel active job if running
function M.cancel()
	if M.active_job then
		vim.fn.jobstop(M.active_job)
		M.active_job = nil
	end
end

return M
