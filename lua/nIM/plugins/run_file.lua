local M = {}

local winopts = require("nIM.util.winopts")
local interpreters, keymap, win_opts

-- Table tracks active run-file window
local run_state = {
	win_id = nil,
	buf_id = nil,
	fpath = nil,
}

local function get_command(fpath, ftype)
	local custom_cmd = interpreters[ftype]

	if type(custom_cmd) == "function" then
		return custom_cmd(fpath)
	elseif type(custom_cmd) == "table" then
		local cmd = vim.deepcopy(custom_cmd)
		table.insert(cmd, fpath)
		return cmd
	end

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
	local fpath
	local ftype
	local original_bufnr -- Store the bufnr of the file run

	local current_buf = vim.api.nvim_get_current_buf()
	if run_state.buf_id and current_buf == run_state.buf_id then
		if not run_state.fpath then
			vim.notify(
				"Cannot rerun, original file path is unknown.",
				vim.log.levels.ERROR
			)
			return
		end
		fpath = run_state.fpath
		ftype = vim.filetype.match({ filename = fpath })
		original_bufnr = vim.fn.bufnr(fpath)
	else
		fpath = vim.api.nvim_buf_get_name(0)
		ftype = vim.bo.filetype
		original_bufnr = vim.api.nvim_get_current_buf()
		if vim.bo.modified then
			vim.cmd.write()
		end
	end

	if fpath == "" then
		vim.notify("No file to run", vim.log.levels.WARN)
		return
	end

	local cmd = get_command(fpath, ftype)
	if not cmd then
		vim.notify(
			"No runner for filetype '" .. ftype .. "'",
			vim.log.levels.ERROR
		)
		return
	end

	local cwd = vim.fn.fnamemodify(fpath, ":p:h")
	local buf_id
	local line_to_add = 0

	-- Generate the buffer name
	local buf_name = "[nIM_run:" .. vim.fn.fnamemodify(fpath, ":t") .. "]"

	if
		not (run_state.win_id and vim.api.nvim_win_is_valid(run_state.win_id))
	then
		run_state.win_id = nil
		run_state.buf_id = nil
		run_state.fpath = nil
	end

	if run_state.win_id then
		buf_id = run_state.buf_id
		vim.api.nvim_set_current_win(run_state.win_id)
		vim.api.nvim_buf_set_name(buf_id, buf_name) -- Set name on reuse
		vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, {})
	else
		-- Create new window and pass the buffer name
		local new_win = winopts.open_in_split(win_opts, buf_name)
		run_state.win_id = new_win.win_id
		run_state.buf_id = new_win.buf_id
		buf_id = new_win.buf_id

		-- buffer-local keymaps
		-- 'q' to close the window
		vim.keymap.set("n", "q", function()
			if vim.api.nvim_win_is_valid(run_state.win_id) then
				vim.api.nvim_win_close(run_state.win_id, false)
			end
		end, { buffer = buf_id, desc = "Close run window" })

		-- 'd' to show diagnostics in quickfix and close
		vim.keymap.set("n", "d", function()
			local diagnostics = vim.diagnostic.get(original_bufnr)
			if #diagnostics > 0 then
				local qf_items = vim.diagnostic.toqflist(diagnostics)
				vim.fn.setqflist(qf_items, "r")
				vim.cmd.copen()
			else
				vim.notify(
					"No diagnostics to show for "
						.. vim.fn.fnamemodify(fpath, ":t"),
					vim.log.levels.INFO
				)
			end
			if vim.api.nvim_win_is_valid(run_state.win_id) then
				vim.api.nvim_win_close(run_state.win_id, false)
			end
		end, { buffer = buf_id, desc = "Show diagnostics in quickfix" })

		local augroup = vim.api.nvim_create_augroup(
			"NIM_RunFileWinClosed",
			{ clear = true }
		)
		vim.api.nvim_create_autocmd("WinClosed", {
			group = augroup,
			buffer = buf_id,
			once = true,
			callback = function()
				run_state.win_id = nil
				run_state.buf_id = nil
				run_state.fpath = nil
			end,
		})
	end

	run_state.fpath = fpath

	local header =
		{ "Running " .. table.concat(cmd, " ") .. " in " .. cwd, "---" }
	vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, header)
	line_to_add = #header

	vim.fn.jobstart(cmd, {
		cwd = cwd,
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = vim.schedule_wrap(function(_, data)
			if data then
				vim.api.nvim_buf_set_lines(
					buf_id,
					line_to_add,
					line_to_add,
					false,
					data
				)
				line_to_add = line_to_add + #data
			end
		end),
		on_stderr = vim.schedule_wrap(function(_, data)
			if data then
				vim.api.nvim_buf_set_lines(
					buf_id,
					line_to_add,
					line_to_add,
					false,
					data
				)
				line_to_add = line_to_add + #data
			end
		end),
		on_exit = vim.schedule_wrap(function(_, code)
			local msg = { "---", "Process exited with code " .. code }
			vim.api.nvim_buf_set_lines(
				buf_id,
				line_to_add,
				line_to_add,
				false,
				msg
			)
		end),
	})
end

function M.setup(opts)
	interpreters = opts.interpreters
	keymap = opts.keymap
	win_opts = opts.win_opts
end

M.logic = run_file_logic

return M
