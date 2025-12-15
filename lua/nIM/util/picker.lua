local M = {}
local preview_util = require("nIM.util.preview")

---File picker that prioritizes Fzf-Lua > Telescope > vim.ui.select
---@param prompt string prompt title
---@param cwd string directory to browse
---@param callback function(selected_path) function to run with absolute path
function M.open(prompt, cwd, callback)
	if not vim.fn.isdirectory(cwd) then
		vim.notify("nIM: Directory not found: " .. cwd, vim.log.levels.WARN)
		return
	end

	-- Fzf-Lua
	local has_fzf, fzf = pcall(require, "fzf-lua")
	if has_fzf then
		fzf.files({
			prompt = prompt .. "> ",
			cwd = cwd,
			previewer = "builtin",
			actions = {
				["default"] = function(selected)
					if selected and selected[1] then
						local path =
							vim.fn.fnamemodify(cwd .. "/" .. selected[1], ":p")
						callback(path)
					end
				end,
			},
		})
		return
	end

	-- Telescope
	local has_tele, tele = pcall(require, "telescope.builtin")
	if has_tele then
		tele.find_files({
			prompt_title = prompt,
			cwd = cwd,
			previewer = require("nIM.util.preview").telescope(),
			attach_mappings = function(prompt_bufnr, _)
				local actions = require("telescope.actions")
				local action_state = require("telescope.actions.state")
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if selection then
						callback(selection.path or selection[1])
					end
				end)
				return true
			end,
		})
		return
	end

	-- Fallback vim.ui.select
	local files = vim.fn.globpath(cwd, "*", false, true)
	vim.ui.select(files, { prompt = prompt }, function(item)
		if item then
			callback(item)
		end
	end)
end

---Generic list picker that prioritizes Fzf-Lua > Telescope > vim.ui.select
---@param items table List of strings to pick from
---@param prompt string The prompt title
---@param callback function(selected_item)
function M.select(items, prompt, callback)
	-- Fzf-Lua
	local has_fzf, fzf = pcall(require, "fzf-lua")
	if has_fzf then
		fzf.fzf_exec(items, {
			prompt = prompt .. "> ",
			actions = {
				["default"] = function(selected)
					if selected and selected[1] then
						callback(selected[1])
					end
				end,
			},
		})
		return
	end

	-- Telescope
	local has_tele, _ = pcall(require, "telescope")
	if has_tele then
		local pickers = require("telescope.pickers")
		local finders = require("telescope.finders")
		local conf = require("telescope.config").values
		local actions = require("telescope.actions")
		local action_state = require("telescope.actions.state")

		pickers
			.new({}, {
				prompt_title = prompt,
				finder = finders.new_table({
					results = items,
				}),
				sorter = conf.generic_sorter({}),
				attach_mappings = function(prompt_bufnr, _)
					actions.select_default:replace(function()
						actions.close(prompt_bufnr)
						local selection = action_state.get_selected_entry()
						if selection then
							callback(selection[1])
						end
					end)
					return true
				end,
			})
			:find()
		return
	end

	-- Fallback
	vim.ui.select(items, { prompt = prompt }, function(item)
		if item then
			callback(item)
		end
	end)
end

return M
