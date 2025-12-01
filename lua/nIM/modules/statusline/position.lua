local M = {}

-- Default options
local opts = {
	mode = "numbers", -- "numbers" | "percentage"
	numbers = {
		show = {
			line = true,
			total_lines = true,
			col = true,
			line_length = false,
		},
		separators = {
			vertical = ":",
			line = "/",
			col = "/",
		},
	},
}

function M.setup(config)
	opts = vim.tbl_deep_extend("force", opts, config or {})
end

---Render for "percentage" mode
local function render_percentage()
	local curr_line = vim.fn.line(".")
	local total_lines = vim.api.nvim_buf_line_count(0)

	if total_lines == 0 then
		return "0%%"
	end
	local percent = math.floor((curr_line / total_lines) * 100)

	-- Handles Top/Bot special cases if desired, or just raw %
	if curr_line == 1 then
		return "Top"
	end
	if curr_line == total_lines then
		return "Bot"
	end
	return string.format("%d%%%%", percent)
end

---Render for "numbers" mode
local function render_numbers(config)
	local show = config.show or {}
	local sep = config.separators or {}

	-- Build Line Section
	local line_part = ""
	if show.line then
		line_part = string.format("%d", vim.fn.line("."))
		if show.total_lines then
			line_part = line_part .. sep.line .. vim.api.nvim_buf_line_count(0)
		end
	elseif show.total_lines then
		-- Edge case: Total lines enabled but current line disabled
		line_part = string.format("%d", vim.api.nvim_buf_line_count(0))
	end

	--  Build Column Section
	local col_part = ""
	if show.col then
		col_part = string.format("%d", vim.fn.virtcol("."))
		if show.line_length then
			local len = math.max(0, vim.fn.virtcol("$") - 1)
			col_part = col_part .. sep.col .. len
		end
	elseif show.line_length then
		col_part = string.format("%d", math.max(0, vim.fn.virtcol("$") - 1))
	end

	-- Join Sections
	if line_part ~= "" and col_part ~= "" then
		return line_part .. sep.vertical .. col_part
	end

	return line_part .. col_part
end

function M.render(render_opts)
	local config = vim.tbl_deep_extend("force", opts, render_opts or {})

	if config.mode == "percentage" then
		return render_percentage()
	end

	return render_numbers(config.numbers)
end

return M
