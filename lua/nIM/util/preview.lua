local M = {}

-- Check for optional dependencies
M.has_image, M.image_api = pcall(require, "image")
M.has_chafa = vim.fn.executable("chafa") == 1
M.has_bat = vim.fn.executable("bat") == 1

---Gets the appropriate Telescope previewer
---@return table previewer The telescope previewer object
function M.telescope()
	local previewers = require("telescope.previewers")
	local putils = require("telescope.previewers.utils")
	local conf = require("telescope.config").values

	-- 1. High-Res Preview (image.nvim)
	-- Leverages Kitty/Sixel/Uberzug via image.nvim for full resolution
	if M.has_image then
		return previewers.new_buffer_previewer({
			title = "Image Preview",
			dyn_title = function(_, entry)
				return vim.fn.fnamemodify(entry.path or entry.value, ":t")
			end,

			get_buffer_by_name = function(_, entry)
				return entry.path or entry.value
			end,

			define_preview = function(self, entry, status)
				local path = entry.path or entry.value
				-- Fallback for non-images (e.g. text files in the same dir)
				local ext = vim.fn.fnamemodify(path, ":e"):lower()
				local image_exts =
				{ "png", "jpg", "jpeg", "gif", "webp", "avif" }

				if not vim.tbl_contains(image_exts, ext) then
					-- Use 'bat' or 'cat' for text files
					conf.buffer_previewer_maker(path, self.state.bufnr, {
						bufname = self.state.bufname,
						winid = self.state.winid,
					})
					return
				end

				-- Render Image
				-- We must clear the buffer first to remove old text/images
				vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {})

				local img = M.image_api.from_file(path, {
					window = status.preview_win,
					buffer = self.state.bufnr,
					with_virtual_padding = true,
				})

				if img then
					img:render()
				end
			end,
		})
	end

	-- 2. Terminal Block Preview (Chafa)
	-- Fallback if image.nvim is not installed
	return previewers.new_termopen_previewer({
		get_command = function(entry, status)
			local path = entry.path or entry.value
			local width = status.preview_win_width or 80
			local height = status.preview_win_height or 24
			local ext = vim.fn.fnamemodify(path, ":e"):lower()
			local image_exts =
			{ "png", "jpg", "jpeg", "gif", "webp", "ico", "svg" }

			if M.has_chafa and vim.tbl_contains(image_exts, ext) then
				return {
					"chafa",
					"--size=" .. width .. "x" .. height,
					"--format=symbols", -- 'symbols' is safer for standard term buffers than 'kitty'
					"--animate=off",
					path,
				}
			elseif M.has_bat then
				return { "bat", "--style=plain", "--color=always", path }
			else
				return { "cat", path }
			end
		end,
	})
end

return M
