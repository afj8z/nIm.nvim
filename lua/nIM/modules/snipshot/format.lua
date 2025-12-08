-- lua/nIM/modules/snipshot/format.lua
local M = {}

M.defaults = {
	-- Markdown: ![filename](path)
	markdown = "![%s](%s)",

	-- Typst: #image("path")
	typst = '#image("%s")',

	-- LaTeX: \includegraphics{path}
	tex = "\\includegraphics{%s}",

	-- HTML: <img src="path" alt="filename">
	html = '<img src="%s" alt="%s">',

	-- CSS: url("path")
	css = 'url("%s")',

	-- Default fallback
	text = "%s",
}

return M
