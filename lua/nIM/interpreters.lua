local M = {}

---Smart runner for TypeScript.
---Tries to find tsx, ts-node, or deno.
local function ts_runner(fpath)
	if vim.fn.executable("tsx") == 1 then
		return { "tsx", fpath }
	end
	if vim.fn.executable("ts-node") == 1 then
		return { "ts-node", fpath }
	end
	if vim.fn.executable("deno") == 1 then
		return { "deno", "run", fpath }
	end
	vim.notify("No TS runner (tsx, ts-node, deno) found", vim.log.levels.WARN)
	return nil -- Will fallback to shebang/executable check
end

---Smart runner for C.
---Compiles with gcc and runs the output binary.
local function c_runner(fpath)
	local exe = vim.fn.fnamemodify(fpath, ":r") -- /path/to/file.c -> /path/to/file
	local job = vim.fn.jobstart({ "gcc", fpath, "-o", exe, "-lm" }, {
		stderr_buffered = true,
	})
	local stderr = vim.fn.jobwait(job)[2]

	if vim.v.shell_error ~= 0 or (stderr and not vim.tbl_isempty(stderr)) then
		vim.notify(
			"C compilation failed:\n" .. table.concat(stderr, "\n"),
			vim.log.levels.ERROR
		)
		return nil
	end
	return { exe } -- Return the path to the compiled executable
end

---Smart runner for C++.
---Compiles with g++ and runs the output binary.
local function cpp_runner(fpath)
	local exe = vim.fn.fnamemodify(fpath, ":r")
	local job = vim.fn.jobstart({ "g++", fpath, "-o", exe, "-lstdc++" }, {
		stderr_buffered = true,
	})
	local stderr = vim.fn.jobwait(job)[2]

	if vim.v.shell_error ~= 0 or (stderr and not vim.tbl_isempty(stderr)) then
		vim.notify(
			"C++ compilation failed:\n" .. table.concat(stderr, "\n"),
			vim.log.levels.ERROR
		)
		return nil
	end
	return { exe }
end

-- default interpreter map
M.defaults = {
	python = { "python3" },
	lua = { "lua" },
	javascript = { "node" },
	sh = { "bash" },
	bash = { "bash" },
	zsh = { "zsh" },
	go = { "go", "run" },
	ruby = { "ruby" },
	perl = { "perl" },
	php = { "php" },
	r = { "Rscript" },
	julia = { "julia" },
	java = { "java" },

	-- Smart runners
	c = c_runner,
	cpp = cpp_runner,
	typescript = ts_runner,
}

return M
