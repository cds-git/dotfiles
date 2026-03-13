return {
	"mfussenegger/nvim-dap",
	event = "VeryLazy",
	config = function()
		local dap = require("dap")

		-- VS Code style F-key bindings
		vim.keymap.set("n", "<F5>", dap.continue, { desc = "[DAP] Continue / Start" })
		vim.keymap.set("n", "<F9>", dap.toggle_breakpoint, { desc = "[DAP] Toggle Breakpoint" })
		vim.keymap.set("n", "<F10>", dap.step_over, { desc = "[DAP] Step Over" })
		vim.keymap.set("n", "<F11>", dap.step_into, { desc = "[DAP] Step Into" })
		vim.keymap.set("n", "<S-F11>", dap.step_out, { desc = "[DAP] Step Out" })
		vim.keymap.set("n", "<F2>", require("dap.ui.widgets").hover, { desc = "[DAP] Hover" })
		vim.keymap.set("n", "<S-F5>", dap.terminate, { desc = "[DAP] Stop / Terminate" })
		vim.keymap.set("n", "<F6>", dap.terminate, { desc = "[DAP] Stop / Terminate" })
		vim.keymap.set("n", "<C-S-F5>", dap.run_last, { desc = "[DAP] Restart (Run Last)" })

		local dotnet = require("utility.dotnet")
		dotnet.setup_debug()
		dotnet.setup_commands()

		-- Sign icons
		vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticSignError", numhl = "" })
		vim.fn.sign_define("DapBreakpointCondition", { text = "⚑ ", texthl = "DiagnosticSignError", numhl = "" })
		vim.fn.sign_define("DapBreakpointRejected", { text = " ", texthl = "DiagnosticSignWarn", numhl = "" })
		vim.fn.sign_define("DapLogPoint", { text = " ", texthl = "DiagnosticSignInfo", numhl = "" })
		vim.fn.sign_define("DapStopped", { text = "󰁕 ", texthl = "DiagnosticSignOk", numhl = "" })
	end,
	keys = {
		{
			"<leader>db",
			function()
				require("dap").toggle_breakpoint()
			end,
			desc = "[DAP] Toggle Breakpoint",
		},
		{
			"<leader>dB",
			function()
				require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end,
			desc = "[DAP] Breakpoint Condition",
		},
		{
			"<leader>dC",
			function()
				require("dap").clear_breakpoints()
			end,
			desc = "[DAP] Clear All Breakpoints",
		},
		{
			"<leader>dr",
			function()
				require("dap").repl.toggle()
			end,
			desc = "[DAP] Toggle REPL",
		},
		{
			"<leader>da",
			function()
				require("utility.dotnet").attach_to_process()
			end,
			desc = "[DAP] Attach to .NET Process",
		},
		{
			"<leader>dd",
			function()
				require("utility.dotnet").debug_project()
			end,
			desc = "[DAP] Debug .NET Project (pick & launch)",
		},
	},
	dependencies = {
		{
			"theHamsta/nvim-dap-virtual-text",
			opts = {
				highlight_changed_variables = true,
				show_stop_reason = true,
				virt_text_pos = "eol",
			},
		},
		{
			"rcarriga/nvim-dap-ui",
			dependencies = { "nvim-neotest/nvim-nio" },
			keys = {
				{
					"<leader>du",
					function()
						require("dapui").toggle({})
					end,
					desc = "[DAP] UI",
				},
				{
					"<leader>de",
					function()
						require("dapui").eval()
					end,
					desc = "[DAP] Eval",
					mode = { "n", "v" },
				},
			},
			opts = {},
			config = function(_, opts)
				local dap = require("dap")
				local dapui = require("dapui")

				dapui.setup(opts)

				dap.listeners.before.attach.dapui_config = function()
					dapui.open()
				end
				dap.listeners.before.launch.dapui_config = function()
					dapui.open()
				end
				dap.listeners.before.event_terminated.dapui_config = function()
					dapui.close()
				end
				dap.listeners.before.event_exited.dapui_config = function()
					dapui.close()
				end
			end,
		},
	},
}
