local M = {}
local capture = require("nIM.util.capture")
local config_opts = {}

M.actions = {
	expand_cmd = {
		mode = "c",
		func = function()
			local cmd = vim.fn.getcmdline()
			vim.fn.setcmdline("") -- Clear command line
			vim.schedule(function()
				M.logic({ args = cmd, smods = { vertical = true } })
			end)
			return "<CR>"
		end,
		opts = { expr = true, desc = "Redir command output" },
	},
}

function M.logic(args)
	local cmd = args.args

	if cmd == "" then
		vim.notify("Redir: No command provided", vim.log.levels.WARN)
		return
	end

	local output, err = capture.cmd_output(cmd)
	if err then
		vim.notify("Redir Error: " .. err, vim.log.levels.ERROR)
		return
	end
	if not output or output == "" then
		vim.notify("No output: " .. cmd, vim.log.levels.INFO)
		return
	end

	local opts = vim.deepcopy(config_opts or {})

	if args.smods then
		if args.smods.vertical then
			opts.win = "vsplit"
		elseif args.smods.horizontal then
			opts.win = "split"
		elseif args.smods.tab and args.smods.tab ~= -1 then
			opts.win = "new"
		end
	end

	opts.filetype = "vim"
	capture.open_scratch(output, opts)
end

function M.setup(opts)
	config_opts = opts or {}
	vim.api.nvim_create_user_command("Redir", M.logic, {
		nargs = "+",
		complete = "command",
	})
end

return M
