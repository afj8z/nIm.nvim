-- lua/nIM_nvim/util/winopts.lua
local M = {}

---@param cmd table: The command to run (e.g., {"python3", "file.py"})
---@param cwd string: The CWD for the command
---@param win_opts table: The window configuration
function M.open_in_split(cmd, cwd, win_opts)
	local curwin = vim.api.nvim_get_current_win()
	local cur_height = vim.api.nvim_win_get_height(curwin)

	-- Calculate target height
	local target_height = math.floor(cur_height * (win_opts.height or 0.25))
	target_height = math.max(target_height, win_opts.min_height or 3)
	target_height = math.min(target_height, win_opts.max_height or 9)

	local split_cmd = string.format(win_opts.split_cmd or "belowright %dsplit", target_height)

	local was_equalalways = vim.o.equalalways
	vim.o.equalalways = false
	vim.cmd(split_cmd)

	vim.cmd("enew")
	local termbuf = vim.api.nvim_get_current_buf()
	vim.bo[termbuf].bufhidden = "wipe"
	vim.wo.number = false
	vim.wo.relativenumber = false
	vim.wo.signcolumn = "no"
	pcall(vim.diagnostic.disable, termbuf)

	vim.fn.termopen(cmd, { cwd = cwd })
	vim.cmd("startinsert")

	vim.cmd("wincmd p")
	vim.o.equalalways = was_equalalways
end

return M
