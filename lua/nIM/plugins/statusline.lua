local M = {}
local opts = {}
local progress_status = {}

---Utility: Get colors dynamically from the active scheme
local function get_normal_colors()
	local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
	return {
		fg = normal.fg or "#ffffff",
		bg = normal.bg or "#000000",
	}
end

---Utility: Strip highlights
local function strip_highlights(str)
	if not str then
		return ""
	end
	str = str:gsub("%%#[^#]+#", "")
	str = str:gsub("%%%*", "")
	return str
end

---Utility: Concat with separators
local function concat_components(components)
	return vim.iter(components)
		:skip(1)
		:fold(components[1], function(acc, component)
			return #component > 0 and string.format("%s  %s", acc, component)
				or acc
		end)
end

---Component: LSP
function M.lsp_active()
	if not rawget(vim, "lsp") then
		return ""
	end
	local ignore = { copilot = true, ruff = true, stylua = true }
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	if #clients == 0 then
		return "[No LSP]"
	end

	local names = {}
	for _, client in ipairs(clients) do
		if client.name and not ignore[client.name] then
			table.insert(names, client.name)
		end
	end
	if #names == 0 then
		return ""
	end

	local display_str = #names == 1 and names[1]
		or string.format("%d clients", #names)

	if
		progress_status.title
		and progress_status.client
		and not ignore[progress_status.client]
	then
		return string.format(
			"%%#StatuslineTitle#%s (%s: %s)",
			display_str,
			progress_status.client,
			progress_status.title
		)
	end
	return string.format("%%#StatuslineTitle#%s", display_str)
end

---Component: Diagnostics
local last_diagnostic_component = ""
function M.diagnostics_component()
	if vim.startswith(vim.api.nvim_get_mode().mode, "i") then
		return last_diagnostic_component
	end

	local counts = { ERROR = 0, WARN = 0, HINT = 0, INFO = 0 }
	for _, d in ipairs(vim.diagnostic.get(0)) do
		local s = vim.diagnostic.severity[d.severity]
		counts[s] = counts[s] + 1
	end

	local parts = {}
	for severity, count in pairs(counts) do
		if count > 0 then
			local hl = "Diagnostic"
				.. severity:sub(1, 1)
				.. severity:sub(2):lower()
			local icon = opts.icons.diagnostics[severity] or ""
			table.insert(parts, string.format("%%#%s#%s %d", hl, icon, count))
		end
	end

	last_diagnostic_component = table.concat(parts, " ")
	return last_diagnostic_component
end

---Component: Filename
function M.filename()
	local fname = vim.fn.expand("%:t")
	if fname == "" then
		fname = "[No Name]"
	end
	local mod = vim.bo.modified and " [+]" or ""
	return fname .. mod .. " "
end

---Component: Position
function M.position_component()
	local line = vim.fn.line(".")
	local count = vim.api.nvim_buf_line_count(0)
	local col = vim.fn.virtcol(".")
	return string.format(
		"%%#StatuslineTitle#%d%%#StatuslineItalic#/%d-%d",
		line,
		count,
		col
	)
end

---Renderer: Special (Full Path)
---Renders for filetypes defined in opts.special_fts (e.g. oil, fzf)
function M.render_special()
	local path = vim.fn.expand("%:p")
	return string.format("%%#StatusLineReversed#%s %%= %%*", path)
end

---Renderer: Quickfix
function M.render_qf()
	local title = vim.fn.getqflist({ title = 1 }).title
	if title == "" then
		title = "[Quickfix List]"
	end
	local pos = strip_highlights(M.position_component())
	return string.format("%%#StatusLineReversed#%s %%=%s %%*", title, pos)
end

---Renderer: Internal
function M.render_internal()
	local ft = vim.bo.filetype ~= "" and vim.bo.filetype or "[No Name]"
	local pos = strip_highlights(M.position_component())
	return string.format("%%#StatusLineReversed#%s %%=%s %%*", ft, pos)
end

---Main Render
function M.render()
	local ft = vim.bo.filetype

	for _, s_ft in ipairs(opts.special_fts or {}) do
		if ft == s_ft then
			return M.render_special()
		end
	end

	for _, int_ft in ipairs(opts.internal_fts) do
		if ft == int_ft then
			return string.format(
				"%%#StatusLineReversed#%s %%*",
				M.render_internal()
			)
		end
	end

	if ft == "qf" then
		return M.render_qf()
	end

	return table.concat({
		concat_components({ M.filename() }),
		"%=",
		"%S ",
		"%#StatusLine#%=",
		concat_components({
			M.lsp_active(),
			M.diagnostics_component(),
			M.position_component(),
		}),
		" ",
	})
end

-- Global Entry Point
function M.render_global()
	local winid = vim.g.statusline_winid
	if winid == vim.api.nvim_get_current_win() then
		return M.render()
	else
		-- Inactive Render
		local buf = vim.api.nvim_win_get_buf(winid)
		local name = vim.api.nvim_buf_get_name(buf)
		name = name ~= "" and vim.fn.fnamemodify(name, ":t") or "[No Name]"
		return string.format("%%#StatusLineNC#%s ", name)
	end
end

function M.setup(config)
	opts = config

	-- Set Autocmds
	local grp = vim.api.nvim_create_augroup("nIM_Statusline", { clear = true })
	vim.api.nvim_create_autocmd("LspProgress", {
		group = grp,
		callback = function(args)
			if not args.data then
				return
			end
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			if not client then
				return
			end

			local val = args.data.params.value
			progress_status =
				{ client = client.name, kind = val.kind, title = val.title }

			if progress_status.kind == "end" then
				progress_status.title = nil
				vim.defer_fn(vim.cmd.redrawstatus, 3000)
			else
				vim.cmd.redrawstatus()
			end
		end,
	})

	-- Set Highlights (Dynamic Reverse)
	local c = get_normal_colors()
	vim.api.nvim_set_hl(0, "StatusLineReversed", { fg = c.bg, bg = c.fg })

	-- Set Global Option
	vim.g.qf_disable_statusline = 1
	vim.opt.statusline =
		"%!v:lua.require('nIM.plugins.statusline').render_global()"
end

return M
