local M = {}

M.opts = {
	-- enable/disable sub-plugins
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
		keymap = nil, -- Default to nil. User must provide this in setup()
		interpreters = {
			python = { "python3" },
			lua = { "lua" },
			javascript = { "node" },
			typescript = { "tsx" },
			sh = { "bash" },
			bash = { "bash" },
			zsh = { "zsh" },
			go = { "go", "run" },
		},
		win_opts = {
			height = 0.25,
			max_height = 9,
			min_height = 3,
			split_cmd = "belowright %dsplit",
		},
	},
}

M.setup = function(opts)
	M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
end

return M
