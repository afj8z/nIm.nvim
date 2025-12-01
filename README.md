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

Executes the current file using a filetype-specific interpreter.
Streams output to a dedicated buffer, which is a "nofile" buffer rather than
a terminal. Creates a "link" between the file and output, allowing for execution
of the file from within the output-buffer and avoiding duplicate output-buffers.

- Window Flexibility: Choose between splits (`split`, `vsplit`),
  floating windows (`float`), or new buffers (`new`).

- Smart Keymaps: Defaults to `q` (`close`) and `d` (`quickfix` `diagnostics`),
  but fully customizable via `buf_keymaps`.

In its current form its useful for short scripts.

### Redir:

Capture command output into a navigable buffer.

- Usage: `:Redir` highlight or `:Redir !ls -la`.

- Modifiers: Supports `:vertical Redir ...` or `:tab Redir ...`.

- Shortcuts: Map a key (e.g., `<C-v>`) to capture the current command line
  command before executing.

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
    keymap = "<Leader>m", -- Trigger run_file
  },
  redir = {
    keymaps = {
      expand_cmd = "<C-v>" -- Redirect current command line
    }
  }
})
```

### Full Configuration (Defaults)

Users may override any portion of the default configuration
by passing a table to the `setup()` function.
Here you can find all configurable options:

```lua
require("nIM").setup({
  -- Master table to enable or disable specific sub-modules.
  enabled = {
    match_parens = true,
    run_file = true,
    redir = true,
  },

  -- Global defaults for floating windows
  float = {
    width = 0.8, -- 0.0-1.0 (ratio) or fixed integer
    height = 0.8,
    border = "rounded",
    style = "minimal",
  },

  -- Global defaults for window options (vim.wo)
  style = {
    number = false,
    relativenumber = false,
  },

  match_parens = {
    pairs = { ["("] = ")", ["["] = "]", ["{"] = "}", ["<"] = ">" }, -- (and reverse)
    hl_groups = {
      region = "BracketRegion",
      paren = "MatchParen",
    },
  },

  run_file = {
    keymap = nil,
    interpreters = require("nIM.interpreters").defaults,

    -- Window strategy: "splitb", "split", "vsplit", "vsplitl", "float", "new"
    win = "splitb",

    win_opts = {
      height = 0.25,
      width = 0.3,
      max_height = 9,
      min_height = 3,
      border = "rounded",
    },

    -- Buffer-local keymaps for the output window
    -- Format: { {mode, lhs, rhs, opts}, ... }
    buf_keymaps = {},

    -- Override global styles for this plugin
    style = { number = false },
  },

  redir = {
    win = "float",

    win_opts = {
      width = 0.4,
      height = 0.5,
      border = "rounded",
    },

    style = { number = false },

    -- Plugin actions
    keymaps = {
      expand_cmd = "<C-v>", -- Redirect current cmdline
    },

    -- Default buffer keymaps
    buf_keymaps = {
      { "n", "q", ":close<CR>", { desc = "Close Redir window" } },
    },
  },
})
```
