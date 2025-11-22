local M = {}
local config = require("nIM.config")

local function resolve_dim(val, max_val)
	if val and val < 1 then
		return math.floor(max_val * val)
	end
	return val or math.floor(max_val * 0.5)
end

function M.create_float(plugin_opts, buf_name)
	local global_opts = config.opts.float or {}
	local opts = vim.tbl_deep_extend("force", global_opts, plugin_opts or {})

	local max_height = vim.api.nvim_win_get_height(0)
	local max_width = vim.api.nvim_win_get_width(0)

	local height = resolve_dim(opts.height, max_height)
	local width = resolve_dim(opts.width, max_width)

	-- FIX: Safe Buffer Deletion
	if buf_name then
		local existing_buf =
			vim.fn.bufnr("^" .. vim.fn.escape(buf_name, "\\/.$[]*~") .. "$")
		if existing_buf ~= -1 then
			vim.api.nvim_buf_delete(existing_buf, { force = true })
		end
	end

	local buf = vim.api.nvim_create_buf(false, true)
	if buf_name then
		vim.api.nvim_buf_set_name(buf, buf_name)
	end

	local win_conf = {
		relative = "editor",
		row = math.floor((max_height - height) / 2),
		col = math.floor((max_width - width) / 2),
		width = width,
		height = height,
		style = opts.style,
		border = opts.border,
	}

	local win = vim.api.nvim_open_win(buf, true, win_conf)

	return { win = win, buf = buf }
end

return M

