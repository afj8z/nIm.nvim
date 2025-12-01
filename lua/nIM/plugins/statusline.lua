local M = {}
local opts = {}
local loaded_modules = {}

--  Preset & Palette Definitions

local presets = {
	powerline = { left_sep = "", right_sep = "" },
	slanted = { left_sep = "", right_sep = "" },
	bubble = { left_sep = "", right_sep = "" },
	block = { left_sep = " ", right_sep = " " },
}

local palette_sources = {
	"Function",
	"String",
	"Type",
	"Statement",
	"Constant",
	"Special",
	"Identifier",
}

local greyscale_palette = {
	"#737373",
	"#808080",
	"#8c8c8c",
	"#999999",
	"#a6a6a6",
	"#b3b3b3",
	"#bfbfbf",
}

-- 2. Color & Highlight Logic -------------------------------------------------

local function get_color(group, attr)
	local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
	return hl[attr] or (attr == "fg" and "#ffffff" or "#000000")
end

local transition_cache = {}

local function get_or_create_transition(name_a, name_b)
	local trans_name = "nIM_Stl_Trans_" .. name_a .. "_to_" .. name_b
	if not transition_cache[trans_name] then
		local bg_a = get_color(name_a, "bg")
		local bg_b = get_color(name_b, "bg")
		vim.api.nvim_set_hl(0, trans_name, { fg = bg_a, bg = bg_b })
		transition_cache[trans_name] = true
	end
	return trans_name
end

local function generate_highlights()
	local style = opts.style or {}
	local mode = style.colors
	transition_cache = {}

	if not mode then
		return
	end

	local normal_bg = get_color("Normal", "bg")
	local normal_fg = get_color("Normal", "fg")

	-- Generate Module Blocks (Color or Greyscale)
	for i, source in ipairs(palette_sources) do
		local source_fg
		if style.greyscale then
			-- Pick from greyscale palette (looping if needed)
			local g_idx = ((i - 1) % #greyscale_palette) + 1
			source_fg = greyscale_palette[g_idx]
		else
			source_fg = get_color(source, "fg")
		end

		local block_name = "nIM_Stl_Block_" .. i

		if mode == "colorblocks" or mode == "groups" then
			-- Block: FG = Normal BG, BG = Color/Grey
			vim.api.nvim_set_hl(
				0,
				block_name,
				{ fg = normal_bg, bg = source_fg }
			)
		elseif mode == "each" then
			-- Text: FG = Color/Grey, BG = Normal BG
			vim.api.nvim_set_hl(
				0,
				block_name,
				{ fg = source_fg, bg = normal_bg }
			)
		end
	end

	-- Generate Diagnostics Highlights
	-- User requirement: If style is active, FG = Normal BG (Dark), BG = Diagnostic Color
	local severities = { "Error", "Warn", "Hint", "Info" }
	for _, sev in ipairs(severities) do
		local base_hl = "Diagnostic" .. sev
		local color = get_color(base_hl, "fg")
		local stl_hl = "nIM_Stl_Diag_" .. sev

		if mode == "colorblocks" or mode == "groups" or mode == "each" then
			vim.api.nvim_set_hl(0, stl_hl, { fg = normal_bg, bg = color })
		else
			-- Fallback to standard
			vim.api.nvim_set_hl(0, stl_hl, { link = base_hl })
		end
	end

	vim.api.nvim_set_hl(0, "StatusLine", { fg = normal_fg, bg = normal_bg })
	vim.api.nvim_set_hl(0, "StatusLineNC", { link = "StatusLine" })
	vim.api.nvim_set_hl(0, "nIM_Stl_Empty", { fg = normal_fg, bg = normal_bg })
end

-- Module Loader

local function load_module_content(name, config)
	local content, highlight

	if type(config) == "table" and config.component then
		local comp = config.component
		content = type(comp) == "function" and comp() or comp
		highlight = config.highlight
	elseif type(config) == "function" then
		content = config()
	else
		if not loaded_modules[name] then
			local ok, mod = pcall(require, "nIM.modules.statusline." .. name)
			if not ok then
				return nil, nil
			end
			local mod_opts = type(config) == "table" and config or {}
			mod_opts.icons = opts.icons
			if mod.setup then
				mod.setup(mod_opts)
			end
			loaded_modules[name] = mod
		end
		local mod = loaded_modules[name]
		if mod and mod.render then
			local mod_opts = type(config) == "table" and config or {}
			mod_opts.icons = opts.icons

			-- pass style context to modules
			mod_opts.style_mode = opts.style.colors

			content, highlight = mod.render(mod_opts)
		end
	end
	return content, highlight
end

-- Rendering Logic

local function render_item_content(content, hl)
	local style = opts.style or {}
	local pad = string.rep(" ", style.padding and style.padding.modules or 0)
	return string.format("%%#%s#%s%s%s", hl, pad, content, pad)
end

local function build_section(section_items, align)
	local parts = {}
	local style = opts.style or {}
	local color_mode = style.colors
	local preset = presets[style.preset]

	local sep_char = ""
	if preset then
		sep_char = (align == "right") and preset.right_sep or preset.left_sep
	elseif style.separator and style.separator.enabled then
		sep_char = (align == "right") and style.separator.right
			or style.separator.left
	end

	local items = {}
	local group_hl_idx = (align == "left") and 1
		or ((align == "center") and 2 or 3)
	local block_index = 1

	for _, item_name in ipairs(section_items or {}) do
		if item_name == "separator" and not preset then
			if style.separator and style.separator.enabled then
				table.insert(items, { type = "sep", content = sep_char })
			end
		elseif item_name ~= "separator" then
			local item_config = opts.modules[item_name]
			if item_config then
				local content, hl_override =
					load_module_content(item_name, item_config)
				if content and content ~= "" then
					local hl_group = "StatusLine"

					if color_mode == "colorblocks" or color_mode == "each" then
						local hl_idx = ((block_index - 1) % #palette_sources)
							+ 1
						hl_group = "nIM_Stl_Block_" .. hl_idx
					elseif color_mode == "groups" then
						hl_group = "nIM_Stl_Block_" .. group_hl_idx
					elseif hl_override then
						hl_group = hl_override
					elseif
						type(item_config) == "table" and item_config.highlight
					then
						hl_group = item_config.highlight
					end

					table.insert(
						items,
						{ type = "mod", content = content, hl = hl_group }
					)
					block_index = block_index + 1
				end
			end
		end
	end

	for i, item in ipairs(items) do
		if item.type == "mod" then
			table.insert(parts, render_item_content(item.content, item.hl))
			if preset then
				local next_item = items[i + 1]
				local next_hl = next_item and next_item.hl or "nIM_Stl_Empty"
				if not style.islands or style.islands == "each" then
					if align == "right" then
						-- Right-side separator logic handled in reverse loop usually,
						-- but for simple stacking leave as is or adapt.
					else
						local trans_hl =
							get_or_create_transition(item.hl, next_hl)
						table.insert(
							parts,
							string.format("%%#%s#%s", trans_hl, sep_char)
						)
					end
				end
			elseif
				style.separator
				and style.separator.enabled
				and i < #items
			then
				table.insert(
					parts,
					string.format("%%#%s#%s", item.hl, sep_char)
				)
			end
		elseif item.type == "sep" then
			table.insert(parts, item.content)
		end
	end

	-- Right Align
	if align == "right" and preset then
		parts = {}
		for i, item in ipairs(items) do
			if item.type == "mod" then
				local prev_hl = (i == 1) and "nIM_Stl_Empty" or items[i - 1].hl
				local trans_hl = get_or_create_transition(item.hl, prev_hl)
				table.insert(
					parts,
					string.format("%%#%s#%s", trans_hl, sep_char)
				)
				table.insert(parts, render_item_content(item.content, item.hl))
			end
		end
	end

	return table.concat(parts, "")
end

function M.render()
	local ft = vim.bo.filetype
	if
		vim.tbl_contains(opts.special_fts or {}, ft)
		or vim.tbl_contains(opts.internal_fts or {}, ft)
	then
		return require("nIM.modules.statusline.special").render_internal()
	end

	local style = opts.style or {}
	local pad_line = string.rep(" ", style.padding and style.padding.line or 0)

	local left = build_section(opts.order.left, "left")
	local center = build_section(opts.order.center, "center")
	local right = build_section(opts.order.right, "right")

	return table.concat({
		pad_line,
		left,
		"%=",
		center,
		"%=",
		right,
		pad_line,
	})
end

function M.render_global()
	local winid = vim.g.statusline_winid
	if winid == vim.api.nvim_get_current_win() then
		return M.render()
	else
		local buf = vim.api.nvim_win_get_buf(winid)
		local name = vim.api.nvim_buf_get_name(buf)
		name = name ~= "" and vim.fn.fnamemodify(name, ":t") or "[No Name]"
		return string.format("%%#StatusLineNC# %s ", name)
	end
end

function M.setup(config)
	opts = config or {}
	vim.g.qf_disable_statusline = 1
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("nIM_Stl_Colors", { clear = true }),
		callback = generate_highlights,
	})
	generate_highlights()
	vim.opt.statusline =
	"%!v:lua.require('nIM.plugins.statusline').render_global()"
end

return M
