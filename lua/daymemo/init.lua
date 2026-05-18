-- lua/daymemo/init.lua
local M = {}

M.setup = function()
  -- setup
end

-- Define the directory where notes will be saved
local memo_dir = os.getenv("HOME") .. "/Documents/nvim_memos"

M.open_memo = function()
  -- 1. Create the directory if it doesn't exist
  vim.fn.mkdir(memo_dir, "p")

  -- 2. Generate a filename based on the current date
  local filename = memo_dir .. "/memo_" .. os.date("%Y-%m-%d") .. ".md"

  -- 3. Open the file in a new buffer
  vim.cmd("edit " .. filename)

  -- 4. get time
  local timestamp = os.date("# %Y%m%d %H:%M:%S")

  -- 5 get last line
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
  -- Default width if not provided
  local split_width = width or 30

  if vim.fn.isdirectory(memo_dir) == 0 then
    vim.notify("Directory not found: " .. memo_dir, vim.log.levels.ERROR)
    return
  end

  -- 1. Create a vertical split with specific width
  -- This executes command like ":30vsplit"
  vim.cmd(split_width .. "vsplit")

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)

  local files = vim.fn.readdir(memo_dir)
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

    local full_path = memo_dir .. '/' .. filename

    -- "wincmd p" moves the cursor to the previous (right-side) window
    vim.cmd("wincmd p")
    vim.cmd('edit ' .. vim.fn.fnameescape(full_path))
  end, vim.tbl_extend("force", opts, { desc = "Open memo in right window" }))

  -- Action: Close the split window
  vim.keymap.set('n', 'q', '<cmd>close<CR>', 
    vim.tbl_extend("force", opts, { desc = "Close memo list" }))
end

vim.api.nvim_create_user_command(
  "DMemo",
  function()
    M.open_memo()
  end,
  { desc = "Open a daily memo file" }
)

-- Command definition (Allows passing width as an argument, e.g., :MemoList 40)
vim.api.nvim_create_user_command("DMemoList", function(opts)
  local width = tonumber(opts.args)
  M.list_memos(width)
end, { nargs = "?" })


return M

