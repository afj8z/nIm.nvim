local M = {}

-- Default options
local opts = {
	icons = {},
	severity = { error = true, warn = true, hint = true, info = true },
	persist = { error = false, warn = false, hint = false, info = false },
	style_mode = nil, -- Injected by engine
}

function M.setup(config)
	opts = vim.tbl_deep_extend("force", opts, config or {})
end

function M.render(render_opts)
	local config = vim.tbl_deep_extend("force", opts, render_opts or {})
	local icons = config.icons and config.icons.diagnostics or {}

	-- Check to use special block-style highlights
	local use_style_hl = (
		config.style_mode == "colorblocks"
		or config.style_mode == "groups"
		or config.style_mode == "each"
	)

	local counts = { ERROR = 0, WARN = 0, HINT = 0, INFO = 0 }
	for _, d in ipairs(vim.diagnostic.get(0)) do
		local s = vim.diagnostic.severity[d.severity]
		if s then
			counts[s] = counts[s] + 1
		end
	end

	local severity_levels = {
		{ key = "error", name = "ERROR" },
		{ key = "warn", name = "WARN" },
		{ key = "hint", name = "HINT" },
		{ key = "info", name = "INFO" },
	}

	local parts = {}

	for _, level in ipairs(severity_levels) do
		local key = level.key
		local name = level.name

		if config.severity[key] then
			local count = counts[name] or 0
			local should_show = (count > 0) or (config.persist[key] == true)

			if should_show then
				local icon = icons[name] or name:sub(1, 1)
				local suffix_hl = key:gsub("^%l", string.upper) -- error -> Error

				-- Select Highlight: Standard "DiagnosticError" or Statusline "nIM_Stl_Diag_Error"
				local hl = use_style_hl and ("nIM_Stl_Diag_" .. suffix_hl)
					or ("Diagnostic" .. suffix_hl)

				table.insert(
					parts,
					string.format("%%#%s#%s %d%%*", hl, icon, count)
				)
			end
		end
	end

	return table.concat(parts, " ")
end

return M
