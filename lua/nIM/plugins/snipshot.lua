local M = {}
local uv = vim.uv or vim.loop
local picker = require("nIM.util.picker")

local config = {}

local function get_ft_config(buf)
	local ft = vim.bo[buf].filetype
	local ft_conf = config.filetypes[ft] or {}
	return {
		relative_dir = ft_conf.relative_dir
			or config.default_relative_dir
			or "assets",
		format = ft_conf.format or config.default_format or "%s",
	}
end

local function get_newest_file(dir)
	local handle = uv.fs_scandir(dir)
	if not handle then
		return nil
	end
	local newest_file = nil
	local newest_time = 0
	while true do
		local name, type = uv.fs_scandir_next(handle)
		if not name then
			break
		end
		if type == "file" and not name:match("^%.") then
			local full_path = dir .. "/" .. name
			local stat = uv.fs_stat(full_path)
			if stat and stat.mtime.sec > newest_time then
				newest_time = stat.mtime.sec
				newest_file = full_path
			end
		end
	end
	return newest_file
end

local function move_file(src, dest)
	local dest_dir = vim.fn.fnamemodify(dest, ":h")
	if vim.fn.isdirectory(dest_dir) == 0 then
		vim.fn.mkdir(dest_dir, "p")
	end
	local success, err = os.rename(src, dest)
	if success then
		return true
	end
	local content = vim.fn.readfile(src, "b")
	if vim.fn.writefile(content, dest, "b") == 0 then
		vim.fn.delete(src)
		return true
	end
	vim.notify(
		"nIM: Failed to move file: " .. (err or ""),
		vim.log.levels.ERROR
	)
	return false
end

local function format_link(fmt, filename, rel_path)
	local _, count = fmt:gsub("%%s", "")
	if count == 2 then
		return string.format(fmt, filename, rel_path)
	else
		return string.format(fmt, rel_path)
	end
end

local function insert_text(text)
	vim.api.nvim_put({ text }, "c", true, true)
end

function M.paste_recent()
	local buf = vim.api.nvim_get_current_buf()
	local ft_opts = get_ft_config(buf)
	local cur_file_path = vim.api.nvim_buf_get_name(buf)

	if cur_file_path == "" then
		vim.notify("nIM: Save file first.", vim.log.levels.WARN)
		return
	end
	local src_file = get_newest_file(config.screenshot_dir)
	if not src_file then
		vim.notify(
			"No screenshots in " .. config.screenshot_dir,
			vim.log.levels.WARN
		)
		return
	end
	local filename = vim.fn.fnamemodify(src_file, ":t")
	local cur_dir = vim.fn.fnamemodify(cur_file_path, ":h")
	local dest_file = cur_dir .. "/" .. ft_opts.relative_dir .. "/" .. filename
	local link_path = ft_opts.relative_dir .. "/" .. filename

	if move_file(src_file, dest_file) then
		insert_text(format_link(ft_opts.format, filename, link_path))
		vim.notify("Pasted: " .. filename, vim.log.levels.INFO)
	end
end

function M.browse_global()
	local buf = vim.api.nvim_get_current_buf()
	local ft_opts = get_ft_config(buf)
	local cur_file_path = vim.api.nvim_buf_get_name(buf)

	picker.open("Screenshots", config.screenshot_dir, function(src_file)
		local filename = vim.fn.fnamemodify(src_file, ":t")
		local cur_dir = vim.fn.fnamemodify(cur_file_path, ":h")
		local dest_file = cur_dir
			.. "/"
			.. ft_opts.relative_dir
			.. "/"
			.. filename
		local link_path = ft_opts.relative_dir .. "/" .. filename

		if
			vim.fn.fnamemodify(src_file, ":p")
			== vim.fn.fnamemodify(dest_file, ":p")
		then
			insert_text(format_link(ft_opts.format, filename, link_path))
		else
			if move_file(src_file, dest_file) then
				insert_text(format_link(ft_opts.format, filename, link_path))
				vim.notify("Moved & Pasted: " .. filename, vim.log.levels.INFO)
			end
		end
	end)
end

function M.browse_local()
	local buf = vim.api.nvim_get_current_buf()
	local ft_opts = get_ft_config(buf)
	local cur_file_path = vim.api.nvim_buf_get_name(buf)
	if cur_file_path == "" then
		return
	end

	local cur_dir = vim.fn.fnamemodify(cur_file_path, ":h")
	local target_dir = cur_dir .. "/" .. ft_opts.relative_dir

	picker.open("Local Assets", target_dir, function(selected_path)
		local filename = vim.fn.fnamemodify(selected_path, ":t")
		local link_path = ft_opts.relative_dir .. "/" .. filename
		insert_text(format_link(ft_opts.format, filename, link_path))
	end)
end

M.actions = {
	paste_recent = {
		mode = "n",
		func = M.paste_recent,
		opts = { desc = "Snipshot: Paste Recent" },
	},
	browse_global = {
		mode = "n",
		func = M.browse_global,
		opts = { desc = "Snipshot: Browse Global Screenshots" },
	},
	browse_local = {
		mode = "n",
		func = M.browse_local,
		opts = { desc = "Snipshot: Browse Local Assets" },
	},
}

function M.setup(opts)
	config = opts or {}

	vim.api.nvim_create_user_command("SnipshotPaste", M.paste_recent, {})
	vim.api.nvim_create_user_command(
		"SnipshotBrowseGlobal",
		M.browse_global,
		{}
	)
	vim.api.nvim_create_user_command("SnipshotBrowseLocal", M.browse_local, {})
end

return M
