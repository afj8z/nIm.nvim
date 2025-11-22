local M = {}
local winopts = require("nIM.util.winopts")

---Captures command output
function M.cmd_output(cmd)
	local ok, result = pcall(vim.api.nvim_exec2, cmd, { output = true })
	if not ok then
		return nil, result
	end
	return result.output
end

---Opens content using the shared window logic
---@param content string The text content
---@param opts table The full config table (containing .win, .win_opts, .style)
function M.open_scratch(content, opts)
	opts = opts or {}
	local lines = vim.split(content, "\n", { plain = true })
	local buf_name = "[Redir]"

	-- 1. Delegate window/buffer creation to winopts
	-- This handles floats, splits, resizing, and styling automatically
	local res = winopts.create_window(opts, buf_name)
	local buf = res.buf_id

	-- 2. Set Content
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	-- 3. Apply Specific Buffer Settings
	vim.bo[buf].filetype = opts.filetype or "vim"
	vim.bo[buf].modifiable = false -- Lock it after writing
end

return M
