local M = {}

---@param win_opts table The window configuration
---@param buf_name string The name for the new buffer
---@return table table A table with { win_id, buf_id }
function M.open_in_split(win_opts, buf_name)
	local curwin = vim.api.nvim_get_current_win()
	local cur_height = vim.api.nvim_win_get_height(curwin)

	local target_height = math.floor(cur_height * (win_opts.height or 0.25))
	target_height = math.max(target_height, win_opts.min_height or 3)
	target_height = math.min(target_height, win_opts.max_height or 9)

	local was_equalalways = vim.o.equalalways
	vim.o.equalalways = false

	vim.cmd("belowright split")
	local new_win_id = vim.api.nvim_get_current_win()

	vim.cmd("enew")
	local new_buf_id = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_name(new_buf_id, buf_name)
	vim.bo[new_buf_id].bufhidden = "wipe"
	vim.bo[new_buf_id].buftype = "nofile"
	vim.bo[new_buf_id].swapfile = false
	vim.wo.number = false
	vim.wo.relativenumber = false
	vim.wo.signcolumn = "no"
	pcall(vim.diagnostic.disable, new_buf_id)

	vim.schedule(function()
		vim.api.nvim_win_set_height(new_win_id, target_height)
	end)

	vim.o.equalalways = was_equalalways

	return { win_id = new_win_id, buf_id = new_buf_id }
end

return M
