local M = {}

local function pos()
	return string.format(
		"%d/%d",
		vim.fn.line("."),
		vim.api.nvim_buf_line_count(0)
	)
end

function M.render_internal()
	local ft = vim.bo.filetype
	local title = (ft == "qf") and vim.fn.getqflist({ title = 1 }).title or ft
	if title == "" then
		title = "[No Name]"
	end

	return string.format("%%#StatusLineReversed# %s %%=%s %%*", title, pos())
end

return M
