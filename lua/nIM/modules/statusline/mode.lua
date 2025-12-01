local M = {}

-- Default options
local opts = {
	name = "full",
	colors = "mode",
	markers = "--",
}

-- Mappings for "full" names
local full_names = {
	["n"] = "NORMAL",
	["no"] = "O-PENDING",
	["nov"] = "O-PENDING",
	["noV"] = "O-PENDING",
	["no\22"] = "O-PENDING",
	["niI"] = "NORMAL",
	["niR"] = "NORMAL",
	["niV"] = "NORMAL",
	["nt"] = "NORMAL",
	["v"] = "VISUAL",
	["vs"] = "VISUAL",
	["V"] = "V-LINE",
	["Vs"] = "V-LINE",
	["\22"] = "V-BLOCK",
	["\22s"] = "V-BLOCK",
	["s"] = "SELECT",
	["S"] = "S-LINE",
	["\19"] = "S-BLOCK",
	["i"] = "INSERT",
	["ic"] = "INSERT",
	["ix"] = "INSERT",
	["R"] = "REPLACE",
	["Rc"] = "REPLACE",
	["Rx"] = "REPLACE",
	["Rv"] = "V-REPLACE",
	["Rvc"] = "V-REPLACE",
	["Rvx"] = "V-REPLACE",
	["c"] = "COMMAND",
	["cv"] = "EX",
	["r"] = "REPLACE",
	["rm"] = "MORE",
	["r?"] = "CONFIRM",
	["!"] = "SHELL",
	["t"] = "TERMINAL",
}

-- Mappings for "short" names
local short_names = {
	["n"] = "N",
	["no"] = "OP",
	["nov"] = "OP",
	["noV"] = "OP",
	["no\22"] = "OP",
	["niI"] = "N",
	["niR"] = "N",
	["niV"] = "N",
	["nt"] = "N",
	["v"] = "V",
	["vs"] = "V",
	["V"] = "V-L",
	["Vs"] = "V-L",
	["\22"] = "V-B",
	["\22s"] = "V-B",
	["s"] = "S",
	["S"] = "S-L",
	["\19"] = "S-B",
	["i"] = "I",
	["ic"] = "I",
	["ix"] = "I",
	["R"] = "R",
	["Rc"] = "R",
	["Rx"] = "R",
	["Rv"] = "V-R",
	["Rvc"] = "V-R",
	["Rvx"] = "V-R",
	["c"] = "C",
	["cv"] = "EX",
	["r"] = "R",
	["rm"] = "M",
	["r?"] = "?",
	["!"] = "SH",
	["t"] = "T",
}

-- Rainbow Preset: Maps mode characters (first char mostly) to Highlight Groups
-- We use standard Vim highlights that usually have distinct colors.
local rainbow_colors = {
	n = "Function", -- Usually Blue
	i = "String", -- Usually Green
	v = "Statement", -- Usually Purple/Yellow
	V = "Statement",
	["\22"] = "Statement",
	R = "ErrorMsg", -- Usually Red
	c = "WarningMsg", -- Usually Orange
	t = "Directory", -- Usually Blue/Cyan
}

function M.setup(config)
	opts = vim.tbl_deep_extend("force", opts, config or {})
end

function M.render(render_opts)
	local config = vim.tbl_deep_extend("force", opts, render_opts or {})
	local mode_code = vim.api.nvim_get_mode().mode

	-- Get Text
	local text
	if config.name == "short" then
		text = short_names[mode_code] or mode_code
	else
		text = full_names[mode_code] or mode_code
	end

	-- Apply Markers
	if config.markers and config.markers ~= "" then
		text = string.format("%s%s%s", config.markers, text, config.markers)
	end

	-- Determine Highlight
	local hl_group = "ModeMsg" -- Default fallback

	if type(config.colors) == "table" then
		-- Custom Table: Match exact mode first, then first char (recursion-lite)
		hl_group = config.colors[mode_code]
			or config.colors[mode_code:sub(1, 1)]
			or hl_group
	elseif config.colors == "rainbow" then
		-- Rainbow Preset
		if rainbow_colors[mode_code] then
			hl_group = rainbow_colors[mode_code]
		else
			hl_group = rainbow_colors[mode_code:sub(1, 1)] or "ModeMsg"
		end
	end
	-- "mode" strategy uses 'ModeMsg' by default, so we do nothing extra.

	return text, hl_group
end

return M
