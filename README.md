# daymemo.nvim

A simple and lightweight daily memo taking plugin for Neovim.

## Features

- **Daily Memo Creation**: Automatically creates and opens a markdown memo named with the current date (`memo_YYYY-MM-DD.md`).
- **Auto Timestamping**: Inserts a timestamp header when creating a new memo or appending to an existing one.
- **Memo Navigator**: Opens a vertical sidebar to browse and open past memos easily.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
require("lazy").setup({

    {
      dir = "~/src/lua/daymemo.nvim",
      name = "daymemo.nvim",
      dev = true,
      -- Lazy load when these commands are executed
      cmd = { "DMemo", "DMemoList" },

      -- Pass the macOS path configuration directly to setup()
      opts = {
        memo_dir = os.getenv("HOME") .. "/DocumentsFolderPath"
      }
    },

})
