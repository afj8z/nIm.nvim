local M = {}

local config = require("nIM.config")
local keymaps = require("nIM.keymaps")

---@param user_opts table|nil
function M.setup(user_opts)
	config.setup(user_opts)
	local opts = config.opts

	-- Table will hold the loaded modules to pass
	-- their functions to the keymapper
	local loaded_modules = {}

	if opts.enabled.match_parens then
		local ok, mod = pcall(require, "nIM.plugins.match_parens")
		if ok then
			mod.setup(opts.match_parens)
			loaded_modules.match_parens = mod
		else
			vim.notify(
				"Failed to load nIM.plugins.match_parens: " .. tostring(mod),
				vim.log.levels.ERROR
			)
		end
	end

	if opts.enabled.run_file then
		local ok, mod = pcall(require, "nIM.plugins.run_file")
		if ok then
			mod.setup(opts.run_file)
			loaded_modules.run_file = mod -- Store the module
		else
			vim.notify(
				"Failed to load nIM.plugins.run_file: " .. tostring(mod),
				vim.log.levels.ERROR
			)
		end
	end

	keymaps.setup(opts, loaded_modules)
end

return M
