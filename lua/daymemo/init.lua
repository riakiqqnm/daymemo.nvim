-- lua/daymemo/init.lua
local M = {}

-- Initial configuration
local config = {
  memo_dir = nil
}

-- Normalize path (handles tilde expansion and trailing slashes)
local function get_clean_dir()
  if not config.memo_dir then return nil end
  return vim.fn.fnamemodify(config.memo_dir, ":p")
end

-- Helper to create today's memo file if it doesn't exist
local function ensure_today_memo_exists(memo_dir)
  local today_file = vim.fs.joinpath(memo_dir, "memo_" .. os.date("%Y-%m-%d") .. ".md")
  
  -- Check if the file already exists
  if vim.fn.filereadable(today_file) == 0 then
    -- Create the directory just in case
    vim.fn.mkdir(memo_dir, "p")
    
    -- Write initial timestamp header into the new file
    local timestamp = os.date("# %Y%m%d %H:%M:%S")
    local f = io.open(today_file, "w")
    if f then
      f:write(timestamp .. "\n\n")
      f:close()
    end
  end
end

M.setup = function(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
end

M.open_memo = function()
  local memo_dir = get_clean_dir()
  if not memo_dir then
    vim.notify("daymemo: memo_dir is not configured. Please specify a path in setup().", vim.log.levels.ERROR)
    return
  end

  -- 1. Create directory if it doesn't exist
  vim.fn.mkdir(memo_dir, "p")

  -- 2. Generate safe file path using vim.fs.joinpath
  local filename = vim.fs.joinpath(memo_dir, "memo_" .. os.date("%Y-%m-%d") .. ".md")

  -- 3. Open file with escaping for safety
  vim.cmd("edit " .. vim.fn.fnameescape(filename))

  -- 4. Append timestamp header
  local timestamp = os.date("# %Y%m%d %H:%M:%S")
  local last_line = vim.fn.line("$")

  if last_line == 1 and vim.fn.getline(1) == "" then
    vim.api.nvim_buf_set_lines(0, 0, 1, false, {timestamp, ""})
  else
    vim.api.nvim_buf_set_lines(0, last_line, last_line, false, {"", timestamp, ""})
  end

  -- Move cursor to the end of the file
  vim.cmd("$")
end

M.list_memos = function(width)
  local split_width = width or 30
  local memo_dir = get_clean_dir()

  if not memo_dir then
    vim.notify("daymemo: memo_dir is not configured. Please specify a path in setup().", vim.log.levels.ERROR)
    return
  end

  -- NEW: Ensure today's file exists before reading the directory
  ensure_today_memo_exists(memo_dir)

  -- 1. Save the original window ID (the main/right window)
  local original_win = vim.api.nvim_get_current_win()

  -- 2. Create a scratch buffer for the file list
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- 3. Open vertical split on the left and assign the buffer
  vim.cmd("topleft vnew")
  local list_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(list_win, buf)
  vim.api.nvim_win_set_width(list_win, split_width)

  -- 4. Read directory (now guaranteed to include today's file) and set lines
  local files = vim.fn.readdir(memo_dir)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, files)

  -- Buffer-local options for the list buffer
  local b = vim.bo[buf]
  b.modifiable = false
  b.buftype = "nofile"
  b.bufhidden = "wipe"
  b.swapfile = false
  b.filetype = "daymemo-list"

  -- Window-local options for sidebar appearance
  local w = vim.wo[list_win]
  w.number = false
  w.relativenumber = false
  w.signcolumn = "no"
  w.winfixwidth = true

  -- Helper function to preview the file under the cursor
  local function preview_current_file()
    local filename = vim.api.nvim_get_current_line()
    if filename == "" or vim.fn.isdirectory(vim.fs.joinpath(memo_dir, filename)) == 1 then
      return
    end

    local full_path = vim.fs.joinpath(memo_dir, filename)

    -- Ensure the original window still exists
    if vim.api.nvim_win_is_valid(original_win) then
      -- Temporarily switch to the original window to load the file
      vim.api.nvim_set_current_win(original_win)
      vim.cmd("edit " .. vim.fn.fnameescape(full_path))
      -- Set as view-only mode for preview safety
      vim.bo.readonly = true
      vim.bo.bufhidden = "hide"
      -- Return focus back to the list window
      vim.api.nvim_set_current_win(list_win)
    end
  end

  -- Trigger initial preview for the first item
  preview_current_file()

  -- Create an autocommand to update the preview on cursor move
  local augroup = vim.api.nvim_create_augroup("DayMemoPreview_" .. buf, { clear = true })
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = augroup,
    buffer = buf,
    callback = preview_current_file,
  })

  -- Keymaps
  local opts = { buffer = buf, silent = true }

  -- Action: Confirm and edit the file (removes readonly status)
  vim.keymap.set('n', '<CR>', function()
    local filename = vim.api.nvim_get_current_line()
    if filename == "" or vim.fn.isdirectory(vim.fs.joinpath(memo_dir, filename)) == 1 then 
      return 
    end

    if vim.api.nvim_win_is_valid(original_win) then
      vim.api.nvim_set_current_win(original_win)
      vim.bo.readonly = false -- Allow editing
    end
  end, vim.tbl_extend("force", opts, { desc = "Edit selected memo" }))

  -- Action: Close the list window
  vim.keymap.set('n', 'q', function()
    -- Clean up the autocommand group before closing
    vim.api.nvim_del_augroup_by_id(augroup)
    vim.api.nvim_win_close(list_win, true)
  end, vim.tbl_extend("force", opts, { desc = "Close memo list" }))
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
