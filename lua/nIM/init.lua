local M = {}

local config = require("nIM.config")

---@param user_opts table|nil
function M.setup(user_opts)
	-- Merge user config into the defaults
	config.setup(user_opts)
	local opts = config.opts

	-- Load enabled sub-plugins
	if opts.enabled.match_parens then
		-- FIX: check the result of pcall before using the module
		local ok, match_parens_mod = pcall(require, "nIM.plugins.match_parens")
		if ok then
			match_parens_mod.setup(opts.match_parens)
		else
			vim.notify(
				"Failed to load nIM_nvim.plugins.match_parens: " .. tostring(match_parens_mod),
				vim.log.levels.ERROR
			)
		end
	end

	if opts.enabled.run_file then
		-- FIX: check the result of pcall before using the module
		local ok, run_file_mod = pcall(require, "nIM.plugins.run_file")
		if ok then
			run_file_mod.setup(opts.run_file)
		else
			vim.notify("Failed to load nIM_nvim.plugins.run_file: " .. tostring(run_file_mod), vim.log.levels.ERROR)
		end
	end
end

return M
