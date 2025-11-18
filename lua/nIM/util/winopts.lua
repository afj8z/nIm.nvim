local M = {}
local config = require("nIM.config")
local style = require("nIM.ui.style")

local function get_float()
	return require("nIM.ui.float")
end

---@param opts table The plugin config table
---@param buf_name string The name for the new buffer
function M.create_window(opts, buf_name)
	local strategy = opts.win or "splitb"
	local w_opts = opts.win_opts or {}
	local result = { win_id = nil, buf_id = nil }

	if buf_name then
		local existing_buf =
			vim.fn.bufnr("^" .. vim.fn.escape(buf_name, "\\/.$[]*~") .. "$")
		if existing_buf ~= -1 then
			vim.api.nvim_buf_delete(existing_buf, { force = true })
		end
	end

	-- ... (Window Creation Logic - Same as before) ...
	if strategy == "float" then
		local res = get_float().create_float(w_opts, buf_name)
		result.win_id = res.win
		result.buf_id = res.buf
	elseif strategy == "new" then
		vim.cmd("enew")
		local buf = vim.api.nvim_get_current_buf()
		vim.api.nvim_buf_set_name(buf, buf_name)
		vim.bo[buf].bufhidden = "wipe"
		vim.bo[buf].buftype = "nofile"
		vim.bo[buf].swapfile = false
		result.win_id = vim.api.nvim_get_current_win()
		result.buf_id = buf
	else
		-- Splits logic
		local cmds = {
			splitb = "belowright split",
			split = "aboveleft split",
			vsplit = "belowright vsplit",
			vsplitl = "topleft vsplit",
		}
		local cmd = cmds[strategy] or "belowright split"
		local is_vertical = (strategy == "vsplit" or strategy == "vsplitl")
		local curwin = vim.api.nvim_get_current_win()
		local target_size

		if is_vertical then
			local cur_width = vim.api.nvim_win_get_width(curwin)
			target_size = math.floor(cur_width * (w_opts.width or 0.3))
		else
			local cur_height = vim.api.nvim_win_get_height(curwin)
			target_size = math.floor(cur_height * (w_opts.height or 0.25))
			target_size = math.max(target_size, w_opts.min_height or 3)
			target_size = math.min(target_size, w_opts.max_height or 9)
		end

		local was_equalalways = vim.o.equalalways
		vim.o.equalalways = false

		vim.cmd(cmd)
		local win_id = vim.api.nvim_get_current_win()
		vim.cmd("enew")
		local buf_id = vim.api.nvim_get_current_buf()
		vim.api.nvim_buf_set_name(buf_id, buf_name)
		vim.bo[buf_id].bufhidden = "wipe"
		vim.bo[buf_id].buftype = "nofile"
		vim.bo[buf_id].swapfile = false
		pcall(vim.diagnostic.disable, buf_id)

		vim.schedule(function()
			if not vim.api.nvim_win_is_valid(win_id) then
				return
			end
			if is_vertical then
				vim.api.nvim_win_set_width(win_id, target_size)
			else
				vim.api.nvim_win_set_height(win_id, target_size)
			end
		end)
		vim.o.equalalways = was_equalalways

		result.win_id = win_id
		result.buf_id = buf_id
	end

	-- 1. Apply Styles
	local global_style = config.opts.style or style.defaults
	local plugin_style = opts.style or {}
	local final_style = vim.tbl_deep_extend("force", global_style, plugin_style)
	style.apply(result.win_id, final_style)

	-- 2. Apply Buffer Keymaps
	if opts.buf_keymaps and type(opts.buf_keymaps) == "table" then
		for _, map in ipairs(opts.buf_keymaps) do
			-- map structure: { mode, lhs, rhs, opts }
			local mode, lhs, rhs = map[1], map[2], map[3]

			-- FIX: Deepcopy opts to avoid mutating the global config table
			-- If we didn't do this, 'map_opts.buffer' would stay set to the old buffer ID forever
			local map_opts = vim.deepcopy(map[4] or {})
			map_opts.buffer = result.buf_id

			vim.keymap.set(mode, lhs, rhs, map_opts)
		end
	end

	return result
end

return M
