local M = {}

local interpreter_defaults = require("nIM.interpreters").defaults
local style_defaults = require("nIM.ui.style").defaults
local format_defaults = require("nIM.modules.snipshot.format").defaults

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
		redir = true,
		statusline = true,
		snipshot = true,
		projectfile = true,
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
	---@class NIM_Statusline_Options
	statusline = {

		-- Module Definitions & Settings
		modules = {
			-- Built-in module configuration
			file = {
				path = "name", -- "name" | "relative" | "full"
				filetype = true, -- Show extension/ft
				highlight = "StatusLine",
			},
			lsp = {
				-- Manually ignore specific client names (e.g. Copilot, or specific linters)
				ignore_list = { "copilot", "copilot.lua" },

				-- If true, checks 'conform.nvim' for active formatters and excludes them
				-- from the LSP client count.
				use_conform = false,

				-- Show active formatter if different from active LSP
				-- "lua_ls [stylua]"
				show_formatter = false,
			},
			diagnostics = {
				-- Enable/Disable specific severity levels
				severity = {
					error = true,
					warn = true,
					hint = true,
					info = true,
				},
				-- Control persistence:
				-- true  = Show icon + '0' when there are no issues.
				-- false = Hide component entirely when count is 0.
				persist = {
					error = true,
					warn = true,
					hint = false,
					info = false,
				},
			},
			position = {
				-- Display mode: "numbers" or "percentage"
				mode = "numbers",
				-- Configuration for "numbers" mode
				numbers = {
					show = {
						line = true,
						total_lines = true,
						col = true,
						line_length = false,
					},
					separators = {
						-- Separator between Line info and Column info
						vertical = ":",
						-- Separator between Current Line and Total Lines
						line = "/",
						-- Separator between Current Column and Line Length
						col = "/",
					},
				},
			},
			file_info = {
				-- master switches for components
				show = {
					filetype = true,
					encoding = true,
					filesize = true,
					permissions = true,
				},
				separator = " ",

				-- Permissions Specific Settings
				permissions = {
					-- true = use abbreviations ("RO"), false = full string ("rwxr-xr-x")
					short = true,

					-- Custom abbreviations for 'short' mode
					symbols = {
						readonly = "RO", -- No write permission
						executable = "EXE", -- Execute permission
						rw = "RW", -- Standard Read/Write
					},

					-- Filter: Only show permissions if the file matches these states.
					-- Options: "readonly", "executable", "rw"
					-- Set to nil or {} to always show permissions (disable filtering).
					only_show = nil,
				},
			},

			git_branch = {
				icon = "",
				-- Toggle icon display
				show_icon = true,
				-- Max length before truncation (set to nil to disable)
				max_len = 20,

				-- If true, shows commit hash when in detached HEAD state (e.g. "a1b2c3d")
				fallback_to_hash = true,
			},
			mode = {
				-- "full" = "NORMAL", "short" = "N"
				name = "full",

				-- "mode"    = Use standard 'ModeMsg' highlight group.
				-- "rainbow" = Use preset distinct colors (Blue=Normal, Green=Insert, etc.)
				-- Table     = Custom map { "n" = "MyNormalHL", "i" = "MyInsertHL" }
				colors = "rainbow",

				-- String to wrap the mode name.
				markers = "--",
			},
		},

		-- Layout & Ordering
		-- Use the keys defined above. 'separator' is a special keyword.
		order = {
			left = { "mode", "file", "git_branch" },
			center = {},
			right = {
				"lsp",
				"diagnostics",
				"position",
			},
		},

		-- Styling & Separators
		style = {
			-- Presets: nil, "powerline", "slanted", "bubble", "block"
			preset = nil,

			-- Colors: nil, "colorblocks", "groups", "each"
			-- "colorblocks": Distinct BG per module, FG = Normal BG
			-- "groups": Distinct BG per alignment group (Left/Center/Right)
			-- "each": Distinct FG per module
			colors = nil,

			-- true: set backgrounds to greyscale
			greyscale = false,

			-- Islands: nil, "each", "groups", "both"
			-- "each": Separators around every module
			-- "groups": Separators around the whole group
			islands = nil,

			padding = {
				line = 0, -- Padding at start/end of the statusline
				modules = 1, -- Padding inside modules (e.g. " Name ")
			},

			-- Manual separator override (if preset is nil)
			separator = {
				enabled = false,
				left = ">",
				right = "<",
			},
			-- legacy, but potentially alternative to preset
			boxed = nil,
		},
		-- Icons table
		icons = {
			diagnostics = {
				ERROR = "",
				WARN = "",
				HINT = "",
				INFO = "",
			},
		},
		-- Filetypes that render a minimal "internal" statusline
		internal_fts = {
			"help",
			"qf",
			"checkhealth",
			"man",
			"lazy",
			"DiffviewFiles",
			"DiffviewFileHistory",
			"OverseerForm",
			"OverseerList",
			"ccc-ui",
			"dap-view",
			"grug-far",
			"codecompanion",
			"lazyterm",
			"minifiles",
		},
		special_fts = {
			"oil",
			"fzf",
			"fzf-lua",
		},
	},
	---@class NIM_Snipshot_Options
	snipshot = {
		screenshot_dir = os.getenv("HOME") .. "/pictures/screenshots",
		default_relative_dir = "assets",
		default_format = "%s",

		filetypes = {
			markdown = {
				relative_dir = "assets",
				format = format_defaults.markdown,
			},
			typst = { relative_dir = "images", format = format_defaults.typst },
			tex = { relative_dir = "figures", format = format_defaults.tex },
			html = { relative_dir = "img", format = format_defaults.html },
			css = { relative_dir = "img", format = format_defaults.css },
		},

		keymaps = {
			-- Map action names to key chords
			paste_recent = nil, -- e.g. "<Leader>p"
			browse_global = nil, -- e.g. "<Leader>pg"
			browse_local = nil, -- e.g. "<Leader>pl"
		},
	},
	---@class NIM_ProjectFile_Options
	projectfile = {
		---@type string[]
		-- Files to search for recursively up to CWD
		files = {
			"README.md",
			"Makefile",
			".gitignore",
			"package.json",
			"pyproject.toml",
			"Cargo.toml",
			"go.mod",
			".luarc.json",
			"LICENSE",
			"TODO.md",
		},
		---@type table<string, string>|nil
		-- Map action names to key chords
		keymaps = {
			find = nil, -- e.g., "<Leader>pf"
		},
	},

	---@class NIM_Float_Options
	-- Global defaults for any floating window created by nIM.
	float = {
		width = 0.8,  -- Default width ratio (0.0 - 1.0) or fixed columns.
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
