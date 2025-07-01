-- ~/.config/nvim/init.lua
-- Minimal Windows-like text editor configuration for Neovim

-- Basic settings
vim.opt.mouse = 'a'              -- Enable mouse
vim.opt.number = true            -- Show line numbers
vim.opt.relativenumber = true    -- Show relative line numbers
vim.opt.expandtab = true         -- Use spaces instead of tabs
vim.opt.tabstop = 4              -- Tab width
vim.opt.shiftwidth = 4           -- Indent width
vim.opt.clipboard = 'unnamedplus' -- Use system clipboard
vim.opt.wrap = true              -- Wrap long lines
vim.opt.linebreak = true         -- Wrap at word boundaries
vim.opt.ignorecase = true        -- Case insensitive search
vim.opt.smartcase = true         -- Unless uppercase is used
vim.opt.swapfile = false         -- No swap files
vim.opt.backup = false           -- No backup files
vim.opt.undofile = true          -- Persistent undo
vim.opt.termguicolors = true     -- Better colors
vim.opt.whichwrap = 'b,s,<,>,[,]' -- Allow arrow keys to wrap lines
vim.opt.virtualedit = 'block'    -- Allow cursor beyond end of line in visual block mode
vim.opt.startofline = false      -- Keep cursor column when moving vertically
vim.opt.backspace = 'indent,eol,start'  -- Allow backspace over everything

-- Optimize key mapping timeouts for instant response
vim.opt.timeout = true           -- Enable timeout for key sequences
vim.opt.timeoutlen = 100         -- Very short timeout - 100ms
vim.opt.ttimeout = true          -- Enable timeout for key codes
vim.opt.ttimeoutlen = 5          -- Extremely short timeout for key codes

-- Custom terminal title showing filename
vim.opt.title = true
vim.opt.titlestring = '%t - Neovim'  -- %t = filename

-- Update terminal title dynamically
vim.api.nvim_create_autocmd({'BufEnter', 'BufWinEnter', 'BufNewFile', 'BufReadPost'}, {
  callback = function()
    local filename = vim.fn.expand('%:t')
    if filename == "" then
      filename = "[No Name]"
    end
    -- Method 1: Set titlestring
    vim.cmd('let &titlestring = "' .. filename .. ' - Neovim"')
    
    -- Method 2: Direct escape sequence (for terminals that support it)
    if vim.env.TERM and vim.env.TERM:match('xterm') then
      io.write('\027]0;' .. filename .. ' - Neovim\007')
    end
  end
})

-- Start in insert mode
vim.cmd("autocmd BufEnter * startinsert")

-- Automatically set wrap for specific file types
vim.api.nvim_create_autocmd('FileType', {
  pattern = {'python', 'sql', 'rust', 'c', 'cpp', 'javascript', 'typescript', 'html', 'css', 'json', 'lua', 'nu'},
  callback = function()
    vim.opt_local.wrap = false
  end
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = {'text', 'markdown', 'txt'},
  callback = function()
    vim.opt_local.wrap = true
  end
})

-- Basic key mappings
local opts = { noremap = true, silent = true }


-- Helper function for user input
local function get_user_input(prompt, callback)
  if vim.ui and vim.ui.input then
    vim.ui.input({
      prompt = prompt,
      default = '',
    }, callback)
  else
    local input = vim.fn.input(prompt)
    callback(input ~= '' and input or nil)
  end
end

-- Enhanced smart save function
local function smart_save()
  local filename = vim.fn.expand('%')
  local bufname = vim.api.nvim_buf_get_name(0)
  local buftype = vim.api.nvim_buf_get_option(0, 'buftype')
  
  
  -- Check if buffer has a filename - improved detection
  -- A file has a name if filename is not empty OR bufname is not empty AND it's not a special buffer
  if (filename == '' and bufname == '') or buftype ~= '' then
    -- Truly unnamed buffer or special buffer - prompt for save as
    get_user_input('Save as: ', function(input)
      if input and input ~= '' then
        vim.cmd('write ' .. input)
        print('Saved as: ' .. input)
      end
      vim.cmd('startinsert')
    end)
  else
    -- File has a name - just save it
    vim.cmd('write')
    local display_name = vim.fn.expand('%:t')
    if display_name == '' then
      display_name = vim.fn.fnamemodify(bufname, ':t')
    end
    print('Saved: ' .. display_name)
    vim.cmd('startinsert')
  end
end

-- Enhanced smart quit function
local function smart_quit()
  -- FIRST: Check for unsaved changes and handle save confirmation BEFORE any buffer manipulation
  local has_changes = false
  local filename = ''
  local should_quit = true
  
  -- Check all buffers for unsaved changes and get the filename of the current buffer
  for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf_id) and vim.api.nvim_buf_get_option(buf_id, 'modified') then
      has_changes = true
      -- If this is the current buffer, get its filename
      if buf_id == vim.api.nvim_get_current_buf() then
        filename = vim.fn.expand('%:t')
        local bufname = vim.api.nvim_buf_get_name(0)
        
        if filename == '' and bufname ~= '' then
          filename = vim.fn.fnamemodify(bufname, ':t')
        end
        
        if filename == '' then filename = 'Untitled' end
      end
      break
    end
  end
  
  -- Handle save confirmation and perform save BEFORE any cleanup
  if has_changes then
    local choice = vim.fn.confirm(
      'Do you want to save the changes to ' .. filename .. '?',
      '&Yes\n&No\n&Cancel',
      3
    )
    
    if choice == 1 then
      -- Save NOW before any buffer manipulation
      if filename ~= 'Untitled' then
        vim.cmd('silent! write')
      else
        -- Truly unnamed file - prompt for filename
        local save_name = vim.fn.input('Save as: ')
        if save_name and save_name ~= '' then
          vim.cmd('silent! write ' .. save_name)
        else
          return  -- Cancel if no filename provided
        end
      end
    elseif choice == 3 then
      return  -- Cancel - don't quit
    end
    -- choice == 2 means "No" - proceed to quit without saving
  end
  
  -- SECOND: Switch to a main buffer window to ensure we're not in a floating window
  local main_win_found = false
  for _, win_id in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win_id) and vim.api.nvim_win_get_config(win_id).relative == '' then
      vim.api.nvim_set_current_win(win_id)
      main_win_found = true
      break
    end
  end
  
  -- If no main window found, create a new buffer
  if not main_win_found then
    vim.cmd('enew')
  end
  
  -- Close all open floating windows and delete their buffers to prevent terminal leftover
  for _, win_id in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win_id) and vim.api.nvim_win_get_config(win_id).relative ~= '' then
      local buf_id = vim.api.nvim_win_get_buf(win_id)
      -- Close floating window first
      vim.api.nvim_win_close(win_id, true)
      -- Then delete its buffer
      if vim.api.nvim_buf_is_valid(buf_id) then
        pcall(function()
          vim.api.nvim_buf_delete(buf_id, { force = true })
        end)
      end
    end
  end

  -- Delete all remaining unnamed/scratch buffers
  for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf_id) then
      local buf_name = vim.api.nvim_buf_get_name(buf_id)
      local buf_type = vim.api.nvim_buf_get_option(buf_id, 'buftype')
      -- Delete if unnamed OR if it's a special buffer type (nofile, prompt, etc.)
      if buf_name == '' or buf_type ~= '' then
        pcall(function()
          vim.api.nvim_buf_delete(buf_id, { force = true })
        end)
      end
    end
  end

  -- Clear all matches and highlights
  vim.fn.clearmatches()
  vim.cmd('nohlsearch')
  
  -- Force clear the entire screen to prevent terminal leftover
  vim.cmd('mode')  -- Switch to terminal mode briefly
  vim.cmd('redraw!')  -- Clear display artifacts
  
  -- Create a completely clean buffer to ensure terminal doesn't capture floating window content
  vim.cmd('enew!')
  vim.cmd('setlocal buftype=nofile')
  vim.cmd('setlocal noswapfile')
  vim.cmd('setlocal nonumber')
  vim.cmd('setlocal norelativenumber')
  
  
  -- Clear terminal screen and ensure cursor is at top
  -- Use only the terminal's built-in clear command for proper cursor positioning
  os.execute('clear 2>/dev/null || true')
  
  -- Force quit without saving (we already handled saving above)
  vim.cmd('silent! qall!')
end

-- File operations
vim.keymap.set({'i', 'n'}, '<C-s>', function() smart_save() end, opts)
vim.keymap.set({'i', 'n'}, '<C-q>', function() smart_quit() end, opts)
vim.keymap.set({'i', 'n'}, '<M-F4>', function() smart_quit() end, opts)

-- Standard editing shortcuts
vim.keymap.set({'i', 'n'}, '<C-z>', '<Esc>:silent! undo<CR>i', opts)
vim.keymap.set({'i', 'n'}, '<C-y>', '<Esc>:silent! redo<CR>i', opts)
vim.keymap.set({'i', 'n'}, '<C-a>', '<Esc>ggVG', opts)
-- Sublime-like search function
local function sublime_search()
  -- Enable incremental search and highlighting
  vim.opt.incsearch = true
  vim.opt.hlsearch = true
  
  -- Start search and return to insert mode after
  vim.cmd('normal! /')
  vim.cmd('startinsert')
end

-- Enhanced Sublime-like find and replace with floating input fields
local function sublime_replace()
  -- Enable incremental search and highlighting
  vim.opt.incsearch = true
  vim.opt.hlsearch = true
  
  -- Set better highlight for current match
  vim.cmd('highlight CurSearch guifg=#1a1a1a guibg=#ff6b6b gui=bold')
  vim.cmd('highlight Search guifg=#1a1a1a guibg=#ffeb3b gui=bold')
  
  -- Create a floating window for find/replace anchored to bottom
  local buf = vim.api.nvim_create_buf(false, true)
  local width = 60
  local height = 4
  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = vim.o.lines - height - 3,  -- Anchor to bottom
    anchor = 'NW',
    style = 'minimal',
    border = 'rounded',
    title = 'Find and Replace'
  }
  
  local win = vim.api.nvim_open_win(buf, true, win_opts)
  
  -- Set up the buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    'Find:    ',
    'Replace: ',
    '',
    'Ctrl+A: Replace All | Ctrl+H: Replace Current | Ctrl+Left/Right: Next/Previous Match | Esc: Cancel'
  })
  
  -- Make buffer modifiable
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_option(buf, 'buftype', '')
  
  -- Position cursor at the end of "Find: " and enter insert mode
  vim.api.nvim_win_set_cursor(win, {1, 9})
  
  -- Variables to store find and replace text
  local find_text = ''
  local replace_text = ''
  local current_field = 'find'  -- 'find' or 'replace'
  
  -- Function to update search highlighting without moving cursor
  local function update_search(text)
    if text and text ~= '' then
      -- Save current window and cursor position
      local current_win = vim.api.nvim_get_current_win()
      local current_cursor = vim.api.nvim_win_get_cursor(win)
      
      -- Clear previous search
      vim.cmd('nohlsearch')
      -- Set new search and highlight
      vim.fn.setreg('/', text)
      vim.cmd('set hlsearch')
      
      -- Temporarily switch to main window to avoid highlighting in floating window
      local main_windows = {}
      for _, w in ipairs(vim.api.nvim_list_wins()) do
        if w ~= win then
          table.insert(main_windows, w)
        end
      end
      
      -- Don't jump to matches - just enable highlighting
      -- pcall(function() vim.cmd('normal! n') end)  -- Removed this line
      
      -- Ensure we stay in the floating window
      vim.api.nvim_set_current_win(win)
      vim.api.nvim_win_set_cursor(win, current_cursor)
    else
      vim.cmd('nohlsearch')
    end
  end
  
  -- Key mappings for the floating window
  local keymap_opts = { noremap = true, silent = true, buffer = buf }
  
  -- Track which line we're on
  local function get_current_field()
    local cursor_pos = vim.api.nvim_win_get_cursor(win)
    return cursor_pos[1] == 1 and 'find' or 'replace'
  end
  
  -- Get text from buffer
  local function extract_text()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    if lines[1] and #lines[1] >= 9 then
      find_text = lines[1]:sub(10)
      update_search(find_text)
    end
    if lines[2] and #lines[2] >= 9 then
      replace_text = lines[2]:sub(10)
    end
  end
  
  -- Tab to switch between fields
  vim.keymap.set('i', '<Tab>', function()
    extract_text()
    current_field = get_current_field()
    if current_field == 'find' then
      vim.api.nvim_win_set_cursor(win, {2, 9 + #replace_text})
    else
      vim.api.nvim_win_set_cursor(win, {1, 9 + #find_text})
    end
  end, keymap_opts)
  
  -- Ctrl+A for replace all
  vim.keymap.set('i', '<C-a>', function()
    extract_text()
    if find_text ~= '' then
      -- Save floating window position
      local float_cursor = vim.api.nvim_win_get_cursor(win)
      
      -- Switch to main buffer temporarily to do replacement
      local main_buf = nil
      for _, w in ipairs(vim.api.nvim_list_wins()) do
        if w ~= win then
          vim.api.nvim_set_current_win(w)
          main_buf = vim.api.nvim_get_current_buf()
          break
        end
      end
      
      if main_buf then
        -- Break undo sequence before replacement
        vim.cmd('let &undolevels = &undolevels')
        
        -- Replace all in the main buffer only
        vim.cmd(':%s@' .. find_text .. '@' .. replace_text .. '@g')
        -- Replaced all occurrences silently
        
        -- Break undo sequence after replacement
        vim.cmd('let &undolevels = &undolevels')
      end
      
      -- Return to floating window
      vim.api.nvim_set_current_win(win)
      vim.api.nvim_win_set_cursor(win, float_cursor)
    end
    vim.cmd('startinsert')
  end, keymap_opts)

  -- Ctrl+H for replace current and auto-advance
  vim.keymap.set('i', '<C-h>', function()
    extract_text()
    if find_text and find_text ~= '' then
      local float_cursor = vim.api.nvim_win_get_cursor(win)
      
      -- Switch to main buffer
      local main_win = nil
      for _, w in ipairs(vim.api.nvim_list_wins()) do
        if w ~= win then main_win = w; break; end
      end
      
      if main_win then
        vim.api.nvim_set_current_win(main_win)
        
        vim.cmd('stopinsert') -- Ensure normal mode
        
        -- Break undo sequence before replacement
        vim.cmd('let &undolevels = &undolevels')
        
        -- Use a simpler approach: find next match and replace it
        vim.cmd('normal! n') -- Go to next match
        if replace_text and replace_text ~= '' then
          vim.cmd('normal! ciw' .. replace_text) -- Change inner word
          vim.cmd('normal! \\<Esc>') -- Exit insert mode
        end
        
        -- Break undo sequence after replacement
        vim.cmd('let &undolevels = &undolevels')
        
        -- Replaced and advanced to next match silently
        
        -- Return to floating window
        vim.api.nvim_set_current_win(win)
        vim.api.nvim_win_set_cursor(win, float_cursor)
      else
        -- Could not find main window
      end
    end
    vim.cmd('startinsert') -- Stay in insert mode in the floating window
  end, keymap_opts)

  -- Ctrl+Left/Right to navigate matches with wrapping
  vim.keymap.set('i', '<C-Left>', function()
    -- Save floating window position
    local float_cursor = vim.api.nvim_win_get_cursor(win)
    
    -- Switch to main buffer to navigate
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if w ~= win then
        vim.api.nvim_set_current_win(w)
        break
      end
    end
    
    -- Try to go to previous match
    local old_pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd('normal! N')
    local new_pos = vim.api.nvim_win_get_cursor(0)
    
    -- If we didn't move, we're at the first match, so wrap to the last
    if old_pos[1] == new_pos[1] and old_pos[2] == new_pos[2] then
      vim.cmd('normal! G')
      vim.cmd('normal! N')
    end
    
    -- Center the viewport on the current match (vertical and horizontal)
    vim.cmd('normal! zz')  -- Vertical centering
    vim.cmd('normal! zs')  -- Horizontal centering (scroll left)
    vim.cmd('normal! ze')  -- Horizontal centering (scroll right)
    
    -- Return to floating window
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_win_set_cursor(win, float_cursor)
  end, keymap_opts)
  
  vim.keymap.set('i', '<C-Right>', function()
    -- Save floating window position
    local float_cursor = vim.api.nvim_win_get_cursor(win)
    
    -- Switch to main buffer to navigate
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if w ~= win then
        vim.api.nvim_set_current_win(w)
        break
      end
    end
    
    -- Try to go to next match
    local old_pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd('normal! n')
    local new_pos = vim.api.nvim_win_get_cursor(0)
    
    -- If we didn't move, we're at the last match, so wrap to the first
    if old_pos[1] == new_pos[1] and old_pos[2] == new_pos[2] then
      vim.cmd('normal! gg')
      vim.cmd('normal! n')
    end
    
    -- Center the viewport on the current match (vertical and horizontal)
    vim.cmd('normal! zz')  -- Vertical centering
    vim.cmd('normal! zs')  -- Horizontal centering (scroll left)
    vim.cmd('normal! ze')  -- Horizontal centering (scroll right)
    
    -- Return to floating window
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_win_set_cursor(win, float_cursor)
  end, keymap_opts)
  
  -- Ctrl+Z for undo in main buffer while keeping floating window open
  vim.keymap.set({'i', 'n'}, '<C-z>', function()
    -- Save floating window position
    local float_cursor = vim.api.nvim_win_get_cursor(win)
    
    -- Switch to main buffer temporarily to perform undo
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if w ~= win then
        vim.api.nvim_set_current_win(w)
        vim.cmd('undo')
        -- Undo performed silently
        break
      end
    end
    
    -- Return to floating window
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_win_set_cursor(win, float_cursor)
    vim.cmd('startinsert')
  end, keymap_opts)
  
  -- Ctrl+Q to close window and exit application
  vim.keymap.set({'i', 'n'}, '<C-q>', function()
    -- Properly clean up floating window and buffer
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    
    -- Force delete the floating window buffer to prevent terminal leftover
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    
    vim.cmd('nohlsearch')  -- Clear any search highlighting
    
    -- Switch to main buffer before cleanup to prevent terminal leftover
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if w ~= win then
        vim.api.nvim_set_current_win(w)
        break
      end
    end
    
    vim.cmd('redraw!')     -- Force redraw to clear any display artifacts
    
    -- Call smart quit with no additional suppression needed
    smart_quit()
  end, keymap_opts)
  
  -- Escape to cancel (with higher priority)
  vim.keymap.set({'i', 'n'}, '<Esc>', function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    vim.cmd('nohlsearch')  -- Clear any search highlighting
    vim.cmd('startinsert')
  end, { noremap = true, silent = true, buffer = buf, desc = 'Close find/replace window' })
  
  -- Handle live search with timer to avoid interfering with cursor movement
  local search_timer = nil
  
  vim.api.nvim_create_autocmd({'TextChangedI'}, {
    buffer = buf,
    callback = function()
      -- Cancel previous timer if it exists
      if search_timer then
        search_timer:stop()
        search_timer:close()
      end
      
      -- Set a short delay to avoid interfering with typing
      search_timer = vim.loop.new_timer()
      search_timer:start(200, 0, vim.schedule_wrap(function()
        extract_text()
        update_search(find_text)
        search_timer:close()
        search_timer = nil
      end))
    end
  })
  
  -- Start in insert mode
  vim.cmd('startinsert')
end

vim.keymap.set({'i', 'n'}, '<C-f>', function() sublime_replace() end, opts)

-- Copy/Paste
-- Visual mode: copy/cut with proper newline handling and Windows-like selection
vim.keymap.set('v', '<C-c>', function()
  -- Simple approach: yank, get content, clean, set clipboard
  vim.cmd('normal! y')
  local content = vim.fn.getreg('"')
  
  -- Remove trailing newline if present (for cleaner clipboard content)
  if content:sub(-1) == '\n' then
    content = content:sub(1, -2)
  end
  
  -- Set to system clipboard without any additional trimming
  vim.fn.setreg('+', content)
  vim.cmd('normal! gv')  -- Restore selection
end, opts)

vim.keymap.set('v', '<C-x>', function()
  -- Capture the selection using yank
  vim.cmd('normal! "zy')  -- Yank to register z
  local yanked_content = vim.fn.getreg('z')
  
  -- Clean up the content - remove trailing newline if present
  local content = yanked_content
  if content:sub(-1) == '\n' then
    content = content:sub(1, -2)
  end
  
  -- Set to system clipboard
  vim.fn.setreg('+', content)
  
  -- Restore visual selection and delete it
  vim.cmd('normal! gv')
  vim.cmd('normal! d')
  
  vim.cmd('startinsert')
end, opts)

vim.keymap.set('v', '<C-v>', function()
  -- Paste at cursor position (not after) and return to insert mode
  vim.cmd('normal! "+P')
  vim.cmd('startinsert')
end, opts)

vim.keymap.set('i', '<C-v>', function()
  -- Exit insert, paste at cursor position, return to insert
  vim.cmd('normal! "+P')
  vim.cmd('startinsert')
end, opts)

-- For normal mode, copy/cut single character instead of whole line to avoid newlines
vim.keymap.set('n', '<C-c>', '"+yli', opts)  -- Copy single character and return to insert
vim.keymap.set('n', '<C-x>', '"+dli', opts)  -- Cut single character and return to insert
vim.keymap.set('n', '<C-v>', '"+pi', opts)   -- Paste and return to insert

-- Movement with column preservation
vim.g.preferred_column = nil

function _G.move_vertically(direction)
  vim.g.in_vertical_move = true
  local current_col = vim.fn.col('.')
  local current_line = vim.fn.line('.')
  
  if vim.g.preferred_column == nil then
    vim.g.preferred_column = current_col
  end
  
  if direction == 'up' then
    vim.cmd('normal! gk')
  else
    vim.cmd('normal! gj')
  end
  
  local new_line = vim.fn.line('.')
  local line_length = vim.fn.col('$') - 1
  
  if new_line ~= current_line then
    local target_col = math.min(vim.g.preferred_column, math.max(1, line_length))
    vim.fn.cursor(new_line, target_col)
  end
  
  vim.g.in_vertical_move = false
end

-- Arrow key mappings
vim.keymap.set('i', '<Left>', function()
  local col = vim.fn.col('.')
  local line = vim.fn.line('.')
  vim.g.preferred_column = nil
  
  if line == 1 and col == 1 then
    return ''
  elseif col == 1 then
    return '<C-o>k<C-o>$'
  else
    return '<Left>'
  end
end, { expr = true })

vim.keymap.set('i', '<Right>', function()
  local col = vim.fn.col('.')
  local line = vim.fn.line('.')
  local line_length = vim.fn.col('$') - 1
  local last_line = vim.fn.line('$')
  vim.g.preferred_column = nil
  
  if line == last_line and col > line_length then
    return ''
  elseif col > line_length then
    return '<C-o>j<C-o>0'
  else
    return '<Right>'
  end
end, { expr = true })

vim.keymap.set('i', '<Up>', function()
  local line = vim.fn.line('.')
  if line == 1 then
    vim.g.preferred_column = nil
    vim.cmd('normal! gg0')
    vim.cmd('startinsert')
  else
    move_vertically('up')
    vim.cmd('startinsert')
  end
end, opts)

vim.keymap.set('i', '<Down>', function()
  local line = vim.fn.line('.')
  local last_line = vim.fn.line('$')
  if line == last_line then
    vim.g.preferred_column = nil
    vim.cmd('normal! G$')
    vim.cmd('startinsert!')
  else
    move_vertically('down')
    vim.cmd('startinsert')
  end
end, opts)

-- Text selection with Shift+arrows
vim.keymap.set('i', '<S-Left>', function()
  -- Move left first, then start visual selection and move right to avoid including character under cursor
  return '<C-o><Left><C-o>v<Right>'
end, { expr = true })
vim.keymap.set('i', '<S-Right>', '<C-o>v<Right>', opts)
vim.keymap.set('i', '<S-Up>', '<C-o>vgk', opts)
vim.keymap.set('i', '<S-Down>', '<C-o>vgj', opts)
vim.keymap.set('v', '<S-Left>', '<Left>', opts)
vim.keymap.set('v', '<S-Right>', '<Right>', opts)
vim.keymap.set('v', '<S-Up>', function()
  local line = vim.fn.line('.')
  if line == 1 then
    vim.g.preferred_column = nil
    return 'gg0'
  else
    return 'gk'
  end
end, { expr = true })
vim.keymap.set('v', '<S-Down>', function()
  local line = vim.fn.line('.')
  local last_line = vim.fn.line('$')
  if line == last_line then
    vim.g.preferred_column = nil
    return 'G$'
  else
    return 'gj'
  end
end, { expr = true })

-- Backspace deletes selection (Windows behavior)
vim.keymap.set('v', '<BS>', 'd', opts)
vim.keymap.set('v', '<Del>', 'd', opts)

-- Clear selection with arrow keys (with proper first/last line handling)
vim.keymap.set('v', '<Left>', '<Esc>i<Left>', opts)
vim.keymap.set('v', '<Right>', '<Esc>i<Right>', opts)
vim.keymap.set('v', '<Up>', function()
  local line = vim.fn.line('.')
  if line == 1 then
    vim.g.preferred_column = nil
    return '<Esc>gg0i'
  else
    return '<Esc>i<C-o>gk'
  end
end, { expr = true })
vim.keymap.set('v', '<Down>', function()
  local line = vim.fn.line('.')
  local last_line = vim.fn.line('$')
  if line == last_line then
    vim.g.preferred_column = nil
    return '<Esc>G$a'
  else
    return '<Esc>i<C-o>gj'
  end
end, { expr = true })

-- Word movement
vim.keymap.set('i', '<C-Left>', function()
  vim.g.preferred_column = nil
  return '<C-o>b'
end, { expr = true })
vim.keymap.set('i', '<C-Right>', function()
  vim.g.preferred_column = nil
  return '<C-o>e'
end, { expr = true })

-- Ctrl+Up/Down for paragraph navigation with centering
vim.keymap.set('i', '<C-Up>', '<C-o>{<C-o>zz', opts)
vim.keymap.set('i', '<C-Down>', '<C-o>}<C-o>zz', opts)
vim.keymap.set('n', '<C-Up>', '{zz', opts)
vim.keymap.set('n', '<C-Down>', '}zz', opts)

-- Home/End
vim.keymap.set('i', '<Home>', function()
  vim.g.preferred_column = nil
  return '<C-o>0'
end, { expr = true })
vim.keymap.set('i', '<End>', function()
  vim.g.preferred_column = nil
  return '<C-o>$'
end, { expr = true })
vim.keymap.set('i', '<S-Home>', '<C-o>v0', opts)
vim.keymap.set('i', '<S-End>', '<C-o>v$', opts)

-- Page navigation
vim.keymap.set('i', '<PageUp>', '<C-o><C-b>', opts)
vim.keymap.set('i', '<PageDown>', '<C-o><C-f>', opts)

-- Comprehensive insert mode shield - return to insert mode from anywhere
vim.keymap.set('n', '<Esc>', 'i', opts)
vim.keymap.set('v', '<Esc>', '<Esc>i', opts)

-- Disable Escape from leaving insert mode (Windows text editor behavior)
vim.keymap.set('i', '<Esc>', '<Nop>', opts)

-- Additional insert mode protection
vim.keymap.set('n', '<CR>', 'i<CR>', opts)  -- Enter in normal mode
vim.keymap.set('n', 'o', 'o', opts)         -- Keep 'o' behavior but it starts in insert
vim.keymap.set('n', 'O', 'O', opts)         -- Keep 'O' behavior but it starts in insert
vim.keymap.set('n', 'a', 'a', opts)         -- Keep 'a' behavior
vim.keymap.set('n', 'A', 'A', opts)         -- Keep 'A' behavior
vim.keymap.set('n', 'I', 'I', opts)         -- Keep 'I' behavior
vim.keymap.set('n', 'c', 'c', opts)         -- Keep 'c' behavior (change commands)
vim.keymap.set('n', 's', 'cl', opts)        -- 's' should substitute character and enter insert
vim.keymap.set('n', 'S', 'cc', opts)        -- 'S' should substitute line and enter insert

-- Catch common normal mode commands and return to insert
vim.keymap.set('n', 'x', 'xi', opts)        -- Delete character and return to insert
vim.keymap.set('n', 'X', 'Xi', opts)        -- Backspace and return to insert
vim.keymap.set('n', 'r', 'ri', opts)        -- Replace character (though it should stay in normal after replace)
vim.keymap.set('n', 'dd', 'ddi', opts)      -- Delete line and return to insert
vim.keymap.set('n', 'yy', 'yyi', opts)      -- Yank line and return to insert

-- Ensure search operations return to insert mode
vim.keymap.set('n', 'n', 'ni', opts)        -- Next search result, then insert
vim.keymap.set('n', 'N', 'Ni', opts)        -- Previous search result, then insert
vim.keymap.set('n', '*', '*i', opts)        -- Search word under cursor, then insert
vim.keymap.set('n', '#', '#i', opts)        -- Search word under cursor backwards, then insert

-- Command mode should return to insert after execution
vim.api.nvim_create_autocmd('CmdlineLeave', {
  callback = function()
    vim.defer_fn(function()
      if vim.fn.mode() == 'n' then
        vim.cmd('startinsert')
      end
    end, 10)
  end
})

-- Ensure we return to insert mode after any operation that might leave us in normal mode
vim.api.nvim_create_autocmd({'TextChanged', 'TextChangedI'}, {
  callback = function()
    -- Only if we're in normal mode and not in the middle of an operation
    vim.defer_fn(function()
      if vim.fn.mode() == 'n' and not vim.g.in_vertical_move then
        vim.cmd('startinsert')
      end
    end, 50)
  end
})

-- Comprehensive keyboard input interception - catch virtually everything
-- Map all printable characters to enter insert mode and type the character
local function map_printable_chars()
  -- Letters
  for i = string.byte('a'), string.byte('z') do
    local char = string.char(i)
    if char ~= 'o' and char ~= 'i' and char ~= 'a' and char ~= 'c' and char ~= 's' and char ~= 'r' then
      vim.keymap.set('n', char, 'i' .. char, opts)
    end
  end
  
  for i = string.byte('A'), string.byte('Z') do
    local char = string.char(i)
    if char ~= 'O' and char ~= 'I' and char ~= 'A' and char ~= 'C' and char ~= 'S' and char ~= 'R' then
      vim.keymap.set('n', char, 'i' .. char, opts)
    end
  end
  
  -- Numbers
  for i = string.byte('0'), string.byte('9') do
    local char = string.char(i)
    vim.keymap.set('n', char, 'i' .. char, opts)
  end
  
  -- Common symbols
  local symbols = {'!', '@', '#', '$', '%', '^', '&', '(', ')', '-', '=', '+', 
                   '[', ']', '{', '}', '\\', '|', ';', "'", '"', ',', '.', 
                   '/', '?', '<', '>', '`', '~', ' '}
  for _, symbol in ipairs(symbols) do
    vim.keymap.set('n', symbol, 'i' .. symbol, opts)
  end
end

-- Apply the comprehensive mapping
map_printable_chars()

-- Command mode access - preserve colon for commands
vim.keymap.set('n', ':', ':', opts)

-- Quick command mode access from insert mode  
vim.keymap.set('i', '<C-;>', '<Esc>:', opts)


-- Toggle word wrap
vim.keymap.set({'i', 'n'}, '<M-w>', function()
  vim.opt.wrap = not vim.opt.wrap:get()
  if vim.opt.wrap:get() then
    print('Word wrap: ON')
  else
    print('Word wrap: OFF')
  end
  vim.cmd('startinsert')
end, opts)

-- Enable built-in syntax highlighting
vim.cmd('syntax enable')
vim.cmd('filetype plugin indent on')

-- Hide the mode line since we're always in insert mode
vim.opt.showmode = false

-- Remove status bar entirely for maximum minimalism
vim.opt.laststatus = 0

-- Disable informational messages for cleaner command area
vim.opt.shortmess:append('filnxtToOFWIcC')
vim.opt.report = 9999  -- Never report lines changed

-- Custom dark color scheme with more muted colors
local function setup_colors()
  vim.cmd('set background=dark')
  vim.cmd('highlight Normal guifg=#c5c5c5 guibg=#1a1a1a')
  vim.cmd('highlight LineNr guifg=#505050 guibg=#1a1a1a')
  vim.cmd('highlight CursorLineNr guifg=#56b6c2 guibg=#1a1a1a')
  vim.cmd('highlight Visual guibg=#3a3a3a')
  vim.cmd('highlight Cursor guibg=#3a3a3a guifg=#c5c5c5')  -- Match visual selection
  vim.cmd('highlight lCursor guibg=#3a3a3a guifg=#c5c5c5')  -- Language cursor
  vim.cmd('highlight CursorIM guibg=#3a3a3a guifg=#c5c5c5')  -- Input method cursor
  vim.cmd('highlight TermCursor guibg=#3a3a3a guifg=#c5c5c5')  -- Terminal cursor
  vim.cmd('highlight TermCursorNC guibg=#3a3a3a guifg=#c5c5c5')  -- Terminal cursor not current
  vim.cmd('highlight vCursor guibg=#3a3a3a guifg=#c5c5c5')  -- Visual cursor
  vim.cmd('highlight CursorLine guibg=#3a3a3a')  -- Cursor line
  vim.cmd('highlight CursorColumn guibg=#3a3a3a')  -- Cursor column
  -- Set cursor to thin line in visual mode, thick line in insert mode
  vim.cmd('highlight InsertCursor guibg=#d4a5a5 guifg=#ffffff')  -- Dusty sakura cursor for insert mode
  vim.opt.guicursor = 'v:hor20-Cursor,i:ver25-InsertCursor,o:hor20-Cursor,n:block-Cursor'
  vim.cmd('highlight StatusLine guifg=#c5c5c5 guibg=#222222')
  vim.cmd('highlight Comment guifg=#707070 gui=italic')
  vim.cmd('highlight Constant guifg=#b8956b')  -- More muted orange
  vim.cmd('highlight String guifg=#8aa86b')   -- More muted green
  vim.cmd('highlight Number guifg=#b8956b')   -- More muted orange
  vim.cmd('highlight Identifier guifg=#c77579')  -- More muted red
  vim.cmd('highlight Function guifg=#5b9bc7')   -- More muted blue
  vim.cmd('highlight Statement guifg=#b378c1')  -- More muted purple
  vim.cmd('highlight Keyword guifg=#b378c1')    -- More muted purple
  vim.cmd('highlight Operator guifg=#5a9ca6')   -- More muted cyan
  vim.cmd('highlight Type guifg=#5a9ca6')       -- More muted cyan
  vim.cmd('highlight Special guifg=#5b9bc7')    -- More muted blue
  vim.cmd('highlight Search guifg=#1a1a1a guibg=#c2a66b')  -- More muted yellow
  vim.cmd('highlight IncSearch guifg=#1a1a1a guibg=#b8956b')  -- More muted orange
  vim.cmd('highlight Pmenu guifg=#c5c5c5 guibg=#2a2a2a')
  vim.cmd('highlight PmenuSel guifg=#1a1a1a guibg=#56b6c2')
  vim.cmd('highlight PmenuSbar guibg=#3a3a3a')
  vim.cmd('highlight PmenuThumb guibg=#56b6c2')
  vim.cmd('highlight NonText guifg=#2a2a2a guibg=#1a1a1a')  -- Make ~ characters subtle
  
  -- Bracket matching highlights (red color)
  vim.cmd('highlight MatchParen guifg=#ff6b6b guibg=#404040 gui=bold')
end

setup_colors()

-- Simple Tab completion
vim.keymap.set('i', '<Tab>', function()
  if vim.fn.pumvisible() == 1 then
    return '<C-n>'
  else
    local col = vim.fn.col('.') - 1
    if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
      return '<Tab>'
    else
      return '<C-n>'  -- Built-in keyword completion
    end
  end
end, { expr = true })

-- Tab for indenting selected lines (multi-line support)
vim.keymap.set('v', '<Tab>', '>>gv', opts)  -- Indent and maintain selection
vim.keymap.set('v', '<S-Tab>', '<<gv', opts)  -- Deindent and maintain selection
vim.keymap.set('i', '<S-Tab>', function()
  -- In insert mode, just deindent current line
  return '<C-o><<'
end, { expr = true })

-- Ctrl+Shift+Up/Down for moving lines up/down (working version)
vim.keymap.set('v', '<C-S-Up>', ":m '<-2<CR>gv", opts)
vim.keymap.set('v', '<C-S-Down>', ":m '>+1<CR>gv", opts)

-- Ctrl+Shift+Up/Down for moving single line in insert mode with boundary checking
vim.keymap.set('i', '<C-S-Up>', function()
  local current_line = vim.fn.line('.')
  if current_line > 1 then
    vim.cmd('move .-2')
    vim.cmd('normal! ==')
    vim.cmd('startinsert')
  else
    vim.cmd('startinsert')
  end
end, opts)

vim.keymap.set('i', '<C-S-Down>', function()
  local current_line = vim.fn.line('.')
  local last_line = vim.fn.line('$')
  if current_line < last_line then
    vim.cmd('move .+1')
    vim.cmd('normal! ==')
    vim.cmd('startinsert')
  else
    vim.cmd('startinsert')
  end
end, opts)

-- Enhanced bracket matching - highlight when cursor is inside brackets
vim.opt.showmatch = true
vim.opt.matchtime = 2

-- Custom bracket highlighting when cursor is inside brackets (multi-line support)
local function highlight_surrounding_brackets_multiline()
  vim.fn.clearmatches()
  
  local cursor = vim.api.nvim_win_get_cursor(0)
  local bracket_types = {
    {'(', ')', 'paren'},
    {'[', ']', 'bracket'},
    {'{', '}', 'brace'}
  }
  
  local best_match = nil
  local smallest_span = math.huge
  
  -- Try each bracket type and find the innermost match
  for _, bracket_info in ipairs(bracket_types) do
    local open = bracket_info[1]
    local close = bracket_info[2]
    
    -- Save cursor position
    local saved_pos = vim.api.nvim_win_get_cursor(0)
    
    -- Search for surrounding brackets
    local open_pos = vim.fn.searchpairpos(
      vim.fn.escape(open, '[]'), '', vim.fn.escape(close, '[]'),
      'bnW', '', 0, 100
    )
    
    if open_pos[1] > 0 then
      -- Restore cursor position before searching for closing bracket
      vim.api.nvim_win_set_cursor(0, saved_pos)
      
      local close_pos = vim.fn.searchpairpos(
        vim.fn.escape(open, '[]'), '', vim.fn.escape(close, '[]'),
        'nW', '', 0, 100
      )
      
      if close_pos[1] > 0 then
        -- Check if cursor is between the brackets
        local cursor_before_close = (cursor[1] < close_pos[1]) or 
          (cursor[1] == close_pos[1] and cursor[2] < close_pos[2])
        local cursor_after_open = (cursor[1] > open_pos[1]) or 
          (cursor[1] == open_pos[1] and cursor[2] >= open_pos[2])
        
        if cursor_before_close and cursor_after_open then
          -- Calculate span (distance between brackets)
          local span = 0
          if close_pos[1] == open_pos[1] then
            -- Same line
            span = close_pos[2] - open_pos[2]
          else
            -- Multiple lines - use line difference as primary metric
            span = (close_pos[1] - open_pos[1]) * 1000 + close_pos[2]
          end
          
          -- Keep track of the innermost (smallest span) match
          if span < smallest_span then
            smallest_span = span
            best_match = {
              open_pos = open_pos,
              close_pos = close_pos
            }
          end
        end
      end
    end
    
    -- Restore cursor position for next iteration
    vim.api.nvim_win_set_cursor(0, saved_pos)
  end
  
  -- Highlight the innermost brackets
  if best_match then
    vim.fn.matchadd('MatchParen', '\\%' .. best_match.open_pos[1] .. 'l\\%' .. best_match.open_pos[2] .. 'c.')
    vim.fn.matchadd('MatchParen', '\\%' .. best_match.close_pos[1] .. 'l\\%' .. best_match.close_pos[2] .. 'c.')
  end
end

-- Set up autocmd for bracket highlighting with debouncing
local bracket_timer = nil

vim.api.nvim_create_autocmd({'CursorMoved', 'CursorMovedI'}, {
  callback = function()
    -- Cancel previous timer if it exists
    if bracket_timer then
      bracket_timer:stop()
      bracket_timer:close()
    end
    
    -- Set a short delay to avoid excessive highlighting during rapid cursor movement
    bracket_timer = vim.loop.new_timer()
    bracket_timer:start(100, 0, vim.schedule_wrap(function()
      highlight_surrounding_brackets_multiline()
      bracket_timer:close()
      bracket_timer = nil
    end))
  end
})

-- Auto-wrapping function for selected text
local function wrap_selection(open_char, close_char)
  -- Get current visual selection using vim commands (more reliable)
  vim.cmd('normal! "vy')  -- Yank visual selection to v register
  local selected_text = vim.fn.getreg('v')
  
  -- Trim leading and trailing whitespace from selection
  local trimmed_text = selected_text:match('^%s*(.-)%s*$')
  
  -- Replace selection with wrapped text
  local wrapped_text = open_char .. trimmed_text .. close_char
  
  -- Use a simpler replacement method: paste over selection
  vim.fn.setreg('w', wrapped_text)
  vim.cmd('normal! gv"wp')  -- Restore selection and paste over it
  
  -- Return to insert mode
  vim.cmd('startinsert')
end

-- Visual mode mappings for auto-wrapping
vim.keymap.set('v', '(', function() wrap_selection('(', ')') end, opts)
vim.keymap.set('v', ')', function() wrap_selection('(', ')') end, opts)
vim.keymap.set('v', '[', function() wrap_selection('[', ']') end, opts)
vim.keymap.set('v', ']', function() wrap_selection('[', ']') end, opts)
vim.keymap.set('v', '{', function() wrap_selection('{', '}') end, opts)
vim.keymap.set('v', '}', function() wrap_selection('{', '}') end, opts)
vim.keymap.set('v', '"', function() wrap_selection('"', '"') end, opts)
vim.keymap.set('v', "'", function() wrap_selection("'", "'") end, opts)
vim.keymap.set('v', '`', function() wrap_selection('`', '`') end, opts)

-- No startup message - keep command area clean



