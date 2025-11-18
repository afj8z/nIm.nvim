local M = {}

local interpreter_defaults = require("nIM.interpreters").defaults
local style_defaults = require("nIM.ui.style").defaults

---@class NIM_Options
---@field enabled table Table to enable/disable sub-modules.
---@field match_parens NIM_MatchParens_Options
---@field run_file NIM_RunFile_Options
---@field redir NIM_Redir_Options
---@field float NIM_Float_Options
---@field style NIM_Style_Options
M.opts = {
	---@type table<string, boolean>
	-- Master switch to enable or disable specific sub-plugins by name.
	-- Keys match the module names in 'lua/nIM/plugins/'.
	enabled = {
		match_parens = true,
		run_file = true,
		redir = true, -- Enable the Redir command/module by default.
	},

	---@class NIM_MatchParens_Options
	match_parens = {
		---@type table<string, string>
		-- A map of bracket pairs to match. Keys are the opening/closing chars, values are their partners.
		pairs = {
			["("] = ")",
			["["] = "]",
			["{"] = "}",
			[")"] = "(",
			["]"] = "[",
			["}"] = "{",
			["<"] = ">",
			[">"] = "<",
		},
		---@type table<string, string>
		-- The highlight groups to apply.
		hl_groups = {
			region = "BracketRegion", -- The region *between* the brackets.
			paren = "MatchParen", -- The brackets themselves.
		},
	},

	---@class NIM_RunFile_Options
	run_file = {
		---@type string|nil
		-- Keymap to trigger the run_file logic.
		-- This is `nil` by default. You MUST set this in your setup() call (e.g., "<Leader>m").
		keymap = nil,

		---@type table<string, table|function>
		-- Map of filetypes to the command used to run them.
		-- Entries can be a table of strings (e.g., {"python3"}) or a function returning a table.
		interpreters = interpreter_defaults,

		---@type string
		-- Strategy for opening the output window.
		-- Options: "splitb" (default), "split", "vsplit", "vsplitl", "float", "new".
		win = "splitb",

		---@type table
		-- Configuration for the output window dimensions.
		win_opts = {
			width = 0.3, -- Width ratio for vertical splits / floats (0.0 - 1.0).
			height = 0.25, -- Height ratio for horizontal splits / floats (0.0 - 1.0).
			max_height = 9, -- Maximum height in rows (for horizontal splits).
			min_height = 3, -- Minimum height in rows (for horizontal splits).
			border = "rounded", -- Border style if win="float".
		},

		---@type table[]
		-- Buffer-local keymaps for the output window.
		-- Format: { {mode, lhs, rhs, opts}, ... }
		-- These mappings will be applied only within the result buffer.
		buf_keymaps = {},

		---@type table|nil
		-- Style overrides for the output buffer (e.g., line numbers).
		-- If nil, global style defaults are used.
		style = {
			number = false,
			relativenumber = false,
		},
	},

	---@class NIM_Redir_Options
	redir = {
		---@type string
		-- Default window strategy for command output.
		-- Options: "splitb", "split", "vsplit", "vsplitl", "float", "new".
		win = "float",

		---@type table|nil
		-- Style overrides for the output buffer.
		style = {
			number = false,
			relativenumber = false,
		},

		---@type table
		-- Window dimensions for the Redir output.
		win_opts = {
			width = 0.4, -- Width ratio for floats/vsplits.
			height = 0.5, -- Height ratio for floats/splits.
			border = "rounded",
		},

		---@type table<string, string>|nil
		-- Keymaps to trigger plugin-specific actions.
		-- Map action names to key chords (e.g., expand_cmd = "<C-v>").
		keymaps = {
			-- "expand_cmd" captures the current command line and redirects output.
			expand_cmd = nil,
		},

		---@type table[]
		-- Buffer-local keymaps for the Redir output window.
		-- Format: { {mode, lhs, rhs, opts}, ... }
		buf_keymaps = {
			{ "n", "q", ":close<CR>", { desc = "Close Redir window" } },
		},
	},

	---@class NIM_Float_Options
	-- Global defaults for any floating window created by nIM.
	float = {
		width = 0.8, -- Default width ratio (0.0 - 1.0) or fixed columns.
		height = 0.8, -- Default height ratio (0.0 - 1.0) or fixed rows.
		border = "rounded", -- Border style: "single", "double", "rounded", "solid", "shadow".
		style = "minimal", -- Window style (usually "minimal").
	},

	---@class NIM_Style_Options
	-- Global defaults for window options (vim.wo) applied to nIM buffers.
	style = style_defaults,
}

M.setup = function(opts)
	M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
end

return M
