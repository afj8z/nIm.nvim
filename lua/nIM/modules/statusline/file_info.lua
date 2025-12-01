local M = {}

-- Default options
local opts = {
	show = {
		filetype = true,
		encoding = true,
		filesize = true,
		permissions = true,
	},
	separator = " | ",
	permissions = {
		short = true,
		symbols = {
			readonly = "RO",
			executable = "EXE",
			rw = "RW",
		},
		only_show = nil,
	},
}

function M.setup(config)
	opts = vim.tbl_deep_extend("force", opts, config or {})
end

---Format bytes to human readable string
local function format_filesize(bytes)
	if bytes <= 0 then
		return "0B"
	end
	if bytes < 1024 then
		return bytes .. "B"
	end

	local units = { "k", "M", "G", "T" }
	local i = 1
	while bytes >= 1024 and i <= #units do
		bytes = bytes / 1024
		i = i + 1
	end

	return string.format("%.1f%s", bytes, units[i - 1])
end

---Analyze permissions and buffer state
local function format_permissions(fpath, config)
	local perm_string = vim.fn.getfperm(fpath)
	if perm_string == "" then
		return nil
	end

	-- LOGIC FIX: Determine state based on Buffer Status first, then File Bits.
	local state = "rw"

	-- 1. Check if effectively Read Only (Buffer option OR not modifiable)
	if vim.bo.readonly or not vim.bo.modifiable then
		state = "readonly"
	else
		-- 2. If writable, check if Executable (User Executable bit is index 3)
		-- perm_string format: rwxrwxrwx
		local u_x = perm_string:sub(3, 3)
		if u_x == "x" then
			state = "executable"
		end
	end

	-- Filter Logic (only_show)
	if config.only_show and #config.only_show > 0 then
		local show_it = false
		for _, required_state in ipairs(config.only_show) do
			if state == required_state then
				show_it = true
				break
			end
		end
		if not show_it then
			return nil
		end
	end

	-- Return logic
	if not config.short then
		return perm_string
	end

	return config.symbols[state] or state:upper()
end

function M.render(render_opts)
	local config = vim.tbl_deep_extend("force", opts, render_opts or {})
	local show = config.show
	local parts = {}
	local fpath = vim.fn.expand("%:p")

	-- 1. Filetype
	if show.filetype then
		local ft = vim.bo.filetype
		if ft ~= "" then
			table.insert(parts, ft)
		end
	end

	-- 2. Encoding
	if show.encoding then
		local enc = vim.bo.fileencoding
		if enc == "" then
			enc = vim.o.encoding
		end
		if enc ~= "" then
			table.insert(parts, enc)
		end
	end

	-- 3. Filesize
	if show.filesize and fpath ~= "" then
		local size = vim.fn.getfsize(fpath)
		if size > 0 then
			table.insert(parts, format_filesize(size))
		end
	end

	-- 4. Permissions
	if show.permissions and fpath ~= "" then
		local perm_text = format_permissions(fpath, config.permissions)
		if perm_text then
			table.insert(parts, perm_text)
		end
	end

	return table.concat(parts, config.separator)
end

return M
