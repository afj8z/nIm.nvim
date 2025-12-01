local M = {}
local global_config = require("nIM.config") -- Access the main config to get special_fts

-- Default options
local opts = {
	icon = "",
	show_icon = true,
	max_len = 20,
	fallback_to_hash = true,
}

function M.setup(config)
	opts = vim.tbl_deep_extend("force", opts, config or {})

	local grp =
		vim.api.nvim_create_augroup("nIM_Statusline_Git", { clear = true })

	vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "DirChanged" }, {
		group = grp,
		callback = function(ev)
			M.update_branch(ev.buf)
		end,
	})
end

---Check if a filetype is ignored (special or internal)
local function is_ignored_ft(ft)
	local stl_opts = global_config.opts.statusline or {}

	-- Check special_fts
	if vim.tbl_contains(stl_opts.special_fts or {}, ft) then
		return true
	end

	-- Check internal_fts
	if vim.tbl_contains(stl_opts.internal_fts or {}, ft) then
		return true
	end

	return false
end

---Updates the buffer-local variable with the git branch
function M.update_branch(buf)
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	-- 1. Check Filetype Exclusion
	local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
	if is_ignored_ft(ft) then
		return
	end

	-- 2. Check Buftype Exclusion (optimization for other non-file buffers)
	local bt = vim.api.nvim_get_option_value("buftype", { buf = buf })
	if bt ~= "" and bt ~= "acwrite" then
		return
	end

	-- 3. Get Path and Directory
	local fpath = vim.api.nvim_buf_get_name(buf)
	if fpath == "" then
		return
	end

	-- Resolve directory (Handle oil:// or standard paths)
	local cwd
	if fpath:match("^oil://") then
		cwd = fpath:gsub("^oil://", "")
	else
		cwd = vim.fn.fnamemodify(fpath, ":h")
	end

	-- 4. Safety Check: Ensure valid directory
	if vim.fn.isdirectory(cwd) == 0 then
		return
	end

	-- 5. Run Git Job
	vim.fn.jobstart({ "git", "symbolic-ref", "--short", "HEAD" }, {
		cwd = cwd,
		stdout_buffered = true,
		on_stdout = function(_, data)
			local branch = data and data[1] or ""
			if branch ~= "" then
				vim.b[buf].nim_git_branch = branch
			else
				if opts.fallback_to_hash then
					vim.fn.jobstart({ "git", "rev-parse", "--short", "HEAD" }, {
						cwd = cwd,
						stdout_buffered = true,
						on_stdout = function(_, hash_data)
							local hash = hash_data and hash_data[1] or ""
							if hash ~= "" then
								vim.b[buf].nim_git_branch = ":" .. hash
							else
								vim.b[buf].nim_git_branch = nil
							end
						end,
					})
				else
					vim.b[buf].nim_git_branch = nil
				end
			end
		end,
	})
end

local function truncate(str, max)
	if not max or #str <= max then
		return str
	end
	return str:sub(1, max - 1) .. "…"
end

function M.render(render_opts)
	local config = vim.tbl_deep_extend("force", opts, render_opts or {})

	local branch = vim.b.nim_git_branch
	if not branch or branch == "" then
		return ""
	end

	local parts = {}
	if config.show_icon and config.icon then
		table.insert(parts, config.icon)
	end
	table.insert(parts, truncate(branch, config.max_len))

	return table.concat(parts, " ")
end

return M
