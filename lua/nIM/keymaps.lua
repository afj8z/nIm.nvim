local M = {}

---@param opts table The main config.opts table
---@param modules table A table of loaded plugin modules (e.g., { run_file = ... })
function M.setup(opts, modules)
	-- Set keymap for run_file if provided by user
	if opts.run_file and opts.run_file.keymap and modules.run_file then
		vim.keymap.set("n", opts.run_file.keymap, modules.run_file.logic, {
			desc = "Run file in split",
		})
	end

	--[[
  -- Example future plugin
  if opts.another_plugin and opts.another_plugin.keymap and modules.another_plugin then
    vim.keymap.set("n", opts.another_plugin.keymap, modules.another_plugin.logic_func, {
      desc = "Do another thing",
    })
  end
  ]]
end

return M
