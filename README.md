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
    "riakiqqnm/daymemo.nvim",
    lazy = false,
    config = function()
      require("daymemo")
    end,
  },
})
