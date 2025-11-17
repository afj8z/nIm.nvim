local M = {}

local winopts = require("nIM_nvim.util.winopts")
local interpreters, keymap, win_opts

local function get_command(fpath, ftype)
	local custom_cmd = interpreters[ftype]
	if custom_cmd then
		-- Return a copy of the table with fpath appended
		local cmd = vim.tbl_deep_copy(custom_cmd)
		table.insert(cmd, fpath)
		return cmd
	end

	-- Fallback for shebang or executable
	local first_line = (vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or "")
	if first_line:sub(1, 2) == "#!" then
		local she = first_line:sub(3):gsub("^%s+", "")
		local parts = vim.split(she, "%s+")
		if parts[1]:find("env$") and parts[2] then
			return { parts[1], parts[2], fpath }
		else
			return { parts[1], fpath }
		end
	end

	if vim.fn.executable(fpath) == 1 then
		return { fpath }
	end

	return nil
end

local function run_file_logic()
	if vim.bo.modified then
		vim.cmd.write()
	end

	local fpath = vim.api.nvim_buf_get_name(0)
	if fpath == "" then
		vim.notify("No file to run", vim.log.levels.WARN)
		return
	end

	local ftype = vim.bo.filetype
	local cmd = get_command(fpath, ftype)

	if not cmd then
		vim.notify("No runner for filetype '" .. ftype .. "' and no shebang/executable file.", vim.log.levels.ERROR)
		return
	end

	local cwd = vim.fn.fnamemodify(fpath, ":p:h")
	winopts.open_in_split(cmd, cwd, win_opts)
end

---@param opts table: The config.run_file table
function M.setup(opts)
	-- Set module-level variables from config
	interpreters = opts.interpreters
	keymap = opts.keymap
	win_opts = opts.win_opts

	-- Set the keymap
	vim.keymap.set("n", keymap, run_file_logic, { desc = "Run file in split" })
end

return M
