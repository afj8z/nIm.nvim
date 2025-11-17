# nIM.nvim
nIM.nvim is a modular collection of personal Lua utilities for Neovim,
consolidated into a single, configurable plugin.

Every couple of months I decide that my workflow does in fact suck in the most
minor details. So the idea is to bunch my opinionated and personalized plugins
together, to ease configuration tweaks.
Also, the individual modules are kept as simple as possible, rellying on setup
but also making tweaks to the source code easy for further personalization.

## Features
This plugin provides several distinct modules (miniature 'sub-plugins')
to enhance the (my) Neovim experience.

### Match Parens: 
A replacement for the built-in matchparen functionality.

Highlights both the matching bracket pair (using the `MatchParen` highlight group)
and the interior region (using custom `BracketRegion` highlight group).
Fixes the built-in plugin bug where brackets in string would match to brackets
in code by leveraging Tree-sitter for syntax analysis.

Includes a fallback mechanism to the legacy syntax engine for
filetypes without an available Tree-sitter parser, though Tree-sitter is
recommended in order to avoid the string-bug.

### Run File:
Simple asynchronous file execution utility.

Executes the current file using a configurable, filetype-specific interpreter.
Streams both stdout and stderr asynchronously to a dedicated split window,
which is a "nofile" buffer rather than a terminal. Creates a "link" between
the file and output, allowing for execution of the file from within the
output-buffer and avoiding duplicate output-buffers.

Assigns buffer-local keymaps to the output window for improved usability

- `q`: Closes the output window.
- `d`: Gathers all diagnostics from the original source file, populates them
    into the quickfix list, and then closes the output window.

In its current form its useful for short scripts.

## Installation and Setup

Use your prefered plugin manager, or somehow ensure the plugin is in your
runtime-path.

It is **mandatory** to invoke the `setup()` function to initialize the plugin.
Please note that keymaps for sub-plugins, such as run_file, are not enabled
by default and must be explicitly defined in your configuration.

### Example Setup

The following is a minimal configuration demonstrating how to load the plugin
and assign a required keymap for the `run_file` module.

```lua
-- in init.lua
require("nIM").setup({
  run_file = {
    -- This keymap is essential for using the run_file module.
    keymap = "<Leader>m",
  },
})
Full Configuration (Defaults)Users may override any portion of the default configuration by passing a table to the setup() function. The structure below illustrates all available options with their default values.require("nIM").setup({
  -- Master table to enable or disable specific sub-modules.
  enabled = {
    match_parens = true,
    run_file = true,
  },

  -- Configuration options for the Match Parens module.
  match_parens = {
    -- A table defining the bracket pairs to be matched.
    pairs = {
      ["("] = ")",
      ["["] = "]",
      ["{"] = "}",
      [")"] = "(",
      ["]"] = "[",
      ["}"] = "{",
      ["<"] = ">",
      [">"] = "<",
    },
    -- Specify the highlight groups to be used.
    hl_groups = {
      region = "BracketRegion", -- For the region between brackets.
      paren = "MatchParen", -- For the brackets themselves.
    },
  },

  -- Configuration options for the Run File module.
  run_file = {
    -- Keymap to trigger the run_file logic.
    -- This is `nil` by default and must be set by the user.
    keymap = nil,

    -- A map of filetypes to their corresponding execution commands.
    -- Entries may be a table of strings (e.g., {"python3"})
    -- or a function that returns a table (for dynamic resolution).
    interpreters = {
      python = { "python3" },
      lua = { "lua" },
      typescript = function(fpath)
        if vim.fn.executable("tsx") == 1 then
          return { "tsx", fpath }
        end
        if vim.fn.executable("ts-node") == 1 then
          return { "ts-node", fpath }
        end
        if vim.fn.executable("deno") == 1 then
          return { "deno", "run", fpath }
        end
      end,
      -- ... Additional interpreters are defined in lua/nIM/interpreters.lua
    },

    -- Configuration for the output window.
    win_opts = {
      height = 0.25, -- Percentage of total screen height (0.0 to 1.0).
      max_height = 9, -- Maximum height in rows.
      min_height = 3, -- Minimum height in rows.
      split_cmd = "belowright %dsplit", -- The Vim command used to create the split.
    },
  },
})
```
