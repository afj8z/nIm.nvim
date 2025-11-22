local M = {}

-- Default window options for plugin windows
M.defaults = {
	number = false,
	relativenumber = false,
	signcolumn = "no",
	foldcolumn = "0",
	wrap = false,
}

---Applies style options to a window
---@param win_id number The window handle
---@param style_opts table key-value pairs matching vim.wo options
function M.apply(win_id, style_opts)
	if not win_id or not vim.api.nvim_win_is_valid(win_id) then
		return
	end

	for k, v in pairs(style_opts) do
		-- Using pcall to avoid crashing if an invalid option is passed
		local ok = pcall(function()
			vim.wo[win_id][k] = v
		end)
		if not ok then
			vim.notify(
				"nIM: Invalid style option '" .. k .. "'",
				vim.log.levels.WARN
			)
		end
	end
end

return M
