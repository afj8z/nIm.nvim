local M = {}

function M.render(opts)
	opts = opts or {}
	local path_opt = opts.path or "name"
	local fname

	-- 1. Resolve Path
	if path_opt == "relative" then
		fname = vim.fn.expand("%:~:.")
	elseif path_opt == "full" then
		fname = vim.fn.expand("%:p")
	else
		fname = vim.fn.expand("%:t") -- Default
	end

	if fname == "" then
		fname = "[No Name]"
	end

	-- 2. Resolve Extension
	if opts.filetype == false then
		fname = vim.fn.fnamemodify(fname, ":r")
	end

	local mod = vim.bo.modified and " [+]" or ""

	-- Return content and nil (uses default highlight from config)
	return fname .. mod, nil
end

return M
