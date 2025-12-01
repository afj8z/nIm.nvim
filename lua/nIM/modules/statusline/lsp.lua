local M = {}
local progress_status = {}

local opts = {
	ignore_list = { "copilot", "copilot.lua" },
	use_conform = true,
	show_formatter = false,
}

function M.setup(config)
	opts = vim.tbl_deep_extend("force", opts, config or {})

	local grp =
		vim.api.nvim_create_augroup("nIM_Statusline_LSP", { clear = true })
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
				-- Trigger a delayed redraw to ensure UI settles
				vim.defer_fn(vim.cmd.redrawstatus, 3000)
			else
				vim.cmd.redrawstatus()
			end
		end,
	})
end

---Helper: Build a set of ignored client names
local function get_ignored_names()
	local ignored = {}

	-- Add hardcoded ignore list
	for _, name in ipairs(opts.ignore_list) do
		ignored[name] = true
	end

	-- Add conform formatters if enabled (hide from LSP count)
	if opts.use_conform then
		local ok, conform = pcall(require, "conform")
		if ok then
			local formatters = conform.list_formatters(0)
			for _, fmt in ipairs(formatters) do
				if fmt.name then
					ignored[fmt.name] = true
				end
			end
		end
	end

	return ignored
end

---Helper: Get active formatters for display
local function get_active_formatters()
	if not opts.use_conform then
		return {}
	end
	local ok, conform = pcall(require, "conform")
	if not ok then
		return {}
	end

	local available = {}
	local formatters = conform.list_formatters(0)
	for _, fmt in ipairs(formatters) do
		if fmt.available then
			table.insert(available, fmt.name)
		end
	end
	return available
end

function M.render()
	if not rawget(vim, "lsp") then
		return ""
	end

	-- Show Progress (Priority)
	if progress_status.client and progress_status.title then
		return string.format(
			"%s: %s",
			progress_status.client,
			progress_status.title
		)
	end

	-- Calculate Active LSPs
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	if #clients == 0 then
		return ""
	end

	local names = {}
	-- Optimization: Only check conform/ignore list multiple clients or an ignore list
	local ignored_set = (#clients > 1 or next(opts.ignore_list))
		and get_ignored_names()
		or {}

	local active_lsp_set = {}

	for _, client in ipairs(clients) do
		if not ignored_set[client.name] then
			table.insert(names, client.name)
			active_lsp_set[client.name] = true
		end
	end

	if #names == 0 then
		return ""
	end
	local lsp_str = #names == 1 and names[1]
		or string.format("%d clients", #names)

	-- Append Formatter Info
	if opts.show_formatter then
		local formatters = get_active_formatters()
		local unique_formatters = {}

		for _, fmt in ipairs(formatters) do
			-- Only show formatter if it is NOT currently displayed as an LSP
			if not active_lsp_set[fmt] then
				table.insert(unique_formatters, fmt)
			end
		end

		if #unique_formatters > 0 then
			-- Example output: "lua_ls [stylua]"
			return string.format(
				"%s [%s]",
				lsp_str,
				table.concat(unique_formatters, ", ")
			)
		end
	end

	return lsp_str
end

return M
