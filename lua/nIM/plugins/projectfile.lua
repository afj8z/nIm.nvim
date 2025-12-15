local M = {}
local picker = require("nIM.util.picker")

local config = {
	-- Default files to look for
	files = {
		"README.md",
		"README",
		"Makefile",
		"justfile",
		".gitignore",
		".gitmodules",
		"package.json",
		"pyproject.toml",
		"requirements.txt",
		"Cargo.toml",
		"go.mod",
		".luarc.json",
		"stylua.toml",
		"LICENSE",
		"TODO",
		"TODO.md",
		"CHANGELOG.md",
	},
	-- Action keymaps
	keymaps = {
		find = nil, -- e.g. "<Leader>pf"
	},
}

function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})
end

function M.find_project_files()
	local current_dir = vim.fn.expand("%:p:h")
	local cwd = vim.fn.getcwd()
	local found_files = {}
	local checked_dirs = {}

	-- Safety check: Ensure current_dir is inside or equal to cwd
	-- If the buffer is outside the CWD, we just check the current dir
	if not vim.startswith(current_dir, cwd) then
		current_dir = cwd
	end

	local dir = current_dir
	while dir do
		-- Avoid cycles or going above CWD
		if checked_dirs[dir] then
			break
		end
		checked_dirs[dir] = true

		for _, filename in ipairs(config.files) do
			local p = dir .. "/" .. filename
			if vim.fn.filereadable(p) == 1 then
				-- Store relative path for cleaner UI, or absolute if preferred
				local display_path = vim.fn.fnamemodify(p, ":.")
				table.insert(found_files, display_path)
			end
		end

		if dir == cwd then
			break
		end

		-- Move up
		local parent = vim.fn.fnamemodify(dir, ":h")
		if parent == dir then
			break
		end -- Reached root
		dir = parent
	end

	if #found_files == 0 then
		vim.notify("nIM: No project files found.", vim.log.levels.INFO)
		return
	end

	-- Deduplicate just in case
	local unique = {}
	local hash = {}
	for _, v in ipairs(found_files) do
		if not hash[v] then
			table.insert(unique, v)
			hash[v] = true
		end
	end

	-- Use the updated picker utility
	picker.select(unique, "Project Files", function(selected)
		if selected then
			vim.cmd("edit " .. selected)
		end
	end)
end

M.actions = {
	find = {
		mode = "n",
		func = M.find_project_files,
		opts = { desc = "nIM: Find Project Files" },
	},
}

return M
