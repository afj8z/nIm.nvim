local M = {}

local ns, pairs_map, hl_groups

---Checks syntax using Tree-sitter.
---@return boolean
local function is_in_syntax_ts(lnum, col)
	local ok, parser = pcall(vim.treesitter.get_parser, 0)
	if not ok or not parser then
		return false
	end
	local node =
		vim.treesitter.get_node({ bufnr = 0, pos = { lnum - 1, col - 1 } })
	if not node then
		return false
	end
	local current_node = node
	while current_node do
		local node_type = current_node:type()
		if node_type:find("string") or node_type:find("comment") then
			return true
		end
		current_node = current_node:parent()
	end
	return false
end

-- Checks syntax using legacy synID (fallback).
local function is_in_syntax_legacy(lnum, col)
	local syn_id = vim.fn.synID(lnum, col, 0)
	local syn_name = vim.fn.synIDattr(syn_id, "name") or ""
	return string.find(string.lower(syn_name), "string")
		or string.find(string.lower(syn_name), "comment")
end

-- Dispatches to TS or legacy syntax checker.
local function is_in_syntax(lnum, col)
	local l = lnum or vim.fn.line(".")
	local c = col or vim.fn.col(".")
	local ts_ok, _ = pcall(vim.treesitter.get_parser, 0)
	if ts_ok then
		return is_in_syntax_ts(l, c)
	else
		return is_in_syntax_legacy(l, c)
	end
end

local function find_match(row, col, ch)
	local open_pat, close_pat, flags
	local function lit(c)
		return "\\V" .. c
	end
	if pairs_map[ch] and (ch == "(" or ch == "[" or ch == "{" or ch == "<") then
		open_pat, close_pat, flags = lit(ch), lit(pairs_map[ch]), "W"
	elseif pairs_map[ch] then
		open_pat, close_pat, flags = lit(pairs_map[ch]), lit(ch), "bW"
	else
		return nil
	end

	local skip_arg = is_in_syntax
	local view = vim.fn.winsaveview()
	pcall(vim.api.nvim_win_set_cursor, 0, { row + 1, col })
	local pos = vim.fn.searchpairpos(open_pat, "", close_pat, flags, skip_arg)
	vim.fn.winrestview(view)

	if type(pos) == "table" and pos[1] and pos[1] > 0 then
		return pos[1] - 1, pos[2] - 1
	end
	return nil
end

local function get_char_at(row, col)
	local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ""
	if col < 0 or col >= #line then
		return nil
	end
	return line:sub(col + 1, col + 1)
end

local function highlight_between()
	vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
	local mode = vim.api.nvim_get_mode().mode
	if not (mode == "n" or mode == "i") then
		return
	end
	local pos = vim.api.nvim_win_get_cursor(0)
	local row, col = pos[1] - 1, pos[2]
	local ch = get_char_at(row, col)
	if not pairs_map[ch or ""] then
		ch = get_char_at(row, col - 1)
		if pairs_map[ch or ""] then
			col = col - 1
		else
			return
		end
	end
	if is_in_syntax(row + 1, col + 1) then
		return
	end
	local mr, mc = find_match(row, col, ch)
	if not mr then
		return
	end
	local sr, sc, er, ec
	if ch == "(" or ch == "[" or ch == "{" or ch == "<" then
		sr, sc = row, col + 1
		er, ec = mr, mc
	else
		sr, sc = mr, mc + 1
		er, ec = row, col
	end
	if (er < sr) or (er == sr and ec < sc) then
		sr, er = er, sr
		sc, ec = ec, sc
	end
	if not (sr == er and ec <= sc) then
		vim.api.nvim_buf_set_extmark(0, ns, sr, sc, {
			end_row = er,
			end_col = ec,
			hl_group = hl_groups.region,
			hl_eol = true,
			priority = 200,
		})
	end
	vim.api.nvim_buf_set_extmark(0, ns, row, col, {
		end_row = row,
		end_col = col + 1,
		hl_group = hl_groups.paren,
		priority = 190,
	})
	vim.api.nvim_buf_set_extmark(0, ns, mr, mc, {
		end_row = mr,
		end_col = mc + 1,
		hl_group = hl_groups.paren,
		priority = 190,
	})
end

---@param opts table: The config.match_parens table
function M.setup(opts)
	-- Set module-level variables from config
	ns = vim.api.nvim_create_namespace("bracket-region")
	pairs_map = opts.pairs
	hl_groups = opts.hl_groups

	-- Disable built-in matchparen
	vim.g.loaded_matchparen = 1

	local aug1 =
		vim.api.nvim_create_augroup("BracketRegionHL", { clear = true })
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		group = aug1,
		callback = highlight_between,
	})
	local aug2 =
		vim.api.nvim_create_augroup("BracketRegionHL_Clear", { clear = true })
	vim.api.nvim_create_autocmd({ "BufLeave", "InsertLeave" }, {
		group = aug2,
		callback = function()
			pcall(vim.api.nvim_buf_clear_namespace, 0, ns, 0, -1)
		end,
	})
end

return M
