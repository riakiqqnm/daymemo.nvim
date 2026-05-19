-- lua/daymemo/init.lua
local M = {}

-- Initialize configuration with nil. Path selection is completely driven by lazy.nvim.
local config = {
  memo_dir = nil
}

-- Setup function to receive configuration options from lazy.nvim
M.setup = function(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
end

M.open_memo = function()
  -- Safety check: Ensure memo_dir has been provided via setup()
  if not config.memo_dir then
    vim.notify("daymemo: memo_dir is not configured. Please specify a path in setup().", vim.log.levels.ERROR)
    return
  end

  -- 1. Create the directory if it doesn't exist
  vim.fn.mkdir(config.memo_dir, "p")

  -- 2. Generate a filename based on the current date
  local filename = config.memo_dir .. "/memo_" .. os.date("%Y-%m-%d") .. ".md"

  -- 3. Open the file in a new buffer
  vim.cmd("edit " .. filename)

  -- 4. Get time
  local timestamp = os.date("# %Y%m%d %H:%M:%S")

  -- 5. Get last line
  local last_line = vim.fn.line("$")

  if last_line == 1 and vim.fn.getline(1) == "" then
    vim.api.nvim_buf_set_lines(0, 0, 1, false, {timestamp, ""})
  else
    vim.api.nvim_buf_set_lines(0, last_line, last_line, false, {"", timestamp, ""})
  end

  vim.cmd("$")
end

--- List memo files in a vertical split with custom width
--- @param width number? Optional width for the split (defaults to 30)
M.list_memos = function(width)
  local split_width = width or 30

  if not config.memo_dir or vim.fn.isdirectory(config.memo_dir) == 0 then
    vim.notify("Directory not found: " .. tostring(config.memo_dir), vim.log.levels.ERROR)
    return
  end

  -- Create a vertical split with specific width
  vim.cmd(split_width .. "vsplit")

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)

  local files = vim.fn.readdir(config.memo_dir)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, files)

  -- Buffer-local options
  local b = vim.bo[buf]
  b.modifiable = false
  b.buftype = "nofile"
  b.bufhidden = "wipe"
  b.swapfile = false

  -- Keymaps
  local opts = { buffer = buf, silent = true }

  -- Action: Open file in the previous window (the right side)
  vim.keymap.set('n', '<CR>', function()
    local filename = vim.api.nvim_get_current_line()
    if filename == "" then return end

    local full_path = config.memo_dir .. '/' .. filename

    vim.cmd("wincmd p")
    vim.cmd('edit ' .. vim.fn.fnameescape(full_path))
  end, vim.tbl_extend("force", opts, { desc = "Open memo in right window" }))

  -- Action: Close the split window
  vim.keymap.set('n', 'q', '<cmd>close<CR>', 
    vim.tbl_extend("force", opts, { desc = "Close memo list" }))
end

-- Define user commands
vim.api.nvim_create_user_command(
  "DMemo",
  function()
    M.open_memo()
  end,
  { desc = "Open a daily memo file" }
)

vim.api.nvim_create_user_command(
  "DMemoList",
  function(opts)
    local width = tonumber(opts.args)
    M.list_memos(width)
  end,
  { nargs = "?", desc = "List memo files in a vertical split" }
)

return M
