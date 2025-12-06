local M = {}
local check = require("util.error_checks")

local filetype, keymap

local function move_screenshot()
	local path = os.getenv("HOME")

	local destination = path .. "/pictures/testdir/"
	local handle = io.popen(
		"python util/find_clip.py "
			.. path
			.. "/pictures/screenshots/ "
			.. destination
	)
	local result = handle:read("*a")
	handle:close()
	return result
end

local function copy_clip()
	local snip = move_screenshot()
	local pattern1 = "^.*/(.+)"
	local f_name = string.match(snip, pattern1)
	-- vim.fn.setreg(f_name)
	print(f_name)
end

copy_clip()

function M.setup(opts)
	filetype = opts.filetype
	keymap = opts.keymap
end
