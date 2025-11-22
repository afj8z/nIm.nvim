local M = {}

---@param opts table The main config.opts table
---@param modules table Loaded modules (e.g., { run_file = ..., redir = ... })
function M.setup(opts, modules)
	-- 1. Legacy Single Keymap (run_file)
	if opts.run_file and opts.run_file.keymap and modules.run_file then
		vim.keymap.set("n", opts.run_file.keymap, modules.run_file.logic, {
			desc = "Run file in split",
		})
	end

	-- 2. NEW: Plugin-Specific Action Keymaps
	-- Iterates through enabled plugins (e.g., "redir")
	for name, mod in pairs(modules) do
		local plugin_conf = opts[name]

		-- Check if plugin has an 'actions' table and user provided 'keymaps'
		if mod.actions and plugin_conf and plugin_conf.keymaps then
			for action_name, lhs in pairs(plugin_conf.keymaps) do
				local def = mod.actions[action_name]

				if def and lhs then
					local mode = def.mode or "n"
					local options = def.opts or {}
					options.desc = options.desc
						or ("nIM: " .. name .. "." .. action_name)

					vim.keymap.set(mode, lhs, def.func, options)
				elseif not def then
					vim.notify(
						"nIM: Unknown action '"
							.. action_name
							.. "' for plugin "
							.. name,
						vim.log.levels.WARN
					)
				end
			end
		end
	end
end

return M
