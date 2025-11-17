-- lua/nIM/config.lua
local M = {}

local interpreter_defaults = require("nIM.interpreters").defaults

M.opts = {
	enabled = {
		match_parens = true,
		run_file = true,
	},

	match_parens = {
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
		hl_groups = {
			region = "BracketRegion",
			paren = "MatchParen",
		},
	},

	run_file = {
		keymap = nil,
		interpreters = interpreter_defaults,
		win_opts = {
			height = 0.15,
			max_height = 5,
			min_height = 3,
			-- FIX: Add the %d placeholder for the height
			split_cmd = "belowright %dsplit",
		},
	},
}

M.setup = function(opts)
	M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
end

return M
