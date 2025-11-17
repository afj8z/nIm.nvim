local M = {}

local interpreter_defaults = require("nIM.interpreters").defaults

---@class NIM_Options
---@field enabled table Table to enable/disable sub-modules.
---@field match_parens NIM_MatchParens_Options
---@field run_file NIM_RunFile_Options
M.opts = {
	---@type table<string, boolean>
	-- A top-level table to enable/disable sub-plugins by name.
	enabled = {
		match_parens = true,
		run_file = true,
	},

	---@class NIM_MatchParens_Options
	match_parens = {
		---@type table<string, string>
		-- A map of bracket pairs to match.
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
			region = "BracketRegion", -- The region *between* the brackets
			paren = "MatchParen", -- The brackets themselves
		},
	},

	---@class NIM_RunFile_Options
	run_file = {
		---@type string|nil
		-- Keymap to trigger the run_file logic.
		-- This is `nil` by default. You MUST set this in your setup() call.
		-- Example: keymap = "<Leader>m"
		keymap = nil,

		---@type table<string, table|function>
		-- Map of filetypes to the command to run them.
		-- Can be a table of strings (e.g., {"python3"})
		-- or a function that returns a table (e.g., for smart runners).
		interpreters = interpreter_defaults,

		---@type table
		-- Options for the output window.
		win_opts = {
			height = 0.25, -- Percentage of total screen height (0.0 to 1.0)
			max_height = 9, -- Max height in rows
			min_height = 3, -- Min height in rows
			split_cmd = "belowright %dsplit", -- The vim command to create the split
		},
	},
}

M.setup = function(opts)
	M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
end

return M
