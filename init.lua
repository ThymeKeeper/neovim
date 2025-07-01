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

-- Smart save function
local function smart_save()
  vim.cmd('write')
  print('Saved: ' .. vim.fn.expand('%:t'))
  vim.cmd('startinsert')
end

-- Smart quit function
local function smart_quit()
  if vim.bo.modified then
    vim.cmd('write')
  end
  vim.cmd('quit')
end

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
  if vim.fn.expand('%') == '' then
    get_user_input('Save as: ', function(input)
      if input and input ~= '' then
        vim.cmd('write ' .. input)
        print('Saved as: ' .. input)
      end
      vim.cmd('startinsert')
    end)
  else
    vim.cmd('write')
    print('Saved: ' .. vim.fn.expand('%:t'))
    vim.cmd('startinsert')
  end
end

-- Enhanced smart quit function
local function smart_quit()
  if vim.bo.modified then
    local filename = vim.fn.expand('%:t')
    if filename == '' then filename = 'Untitled' end
    
    local choice = vim.fn.confirm(
      'Do you want to save the changes to ' .. filename .. '?',
      '&Yes\n&No\n&Cancel',
      3
    )
    
    if choice == 1 then
      if vim.fn.expand('%') ~= '' then
        vim.cmd('write')
        vim.cmd('quit')
      else
        get_user_input('Save as: ', function(input)
          if input and input ~= '' then
            vim.cmd('write ' .. input)
            vim.cmd('quit')
          else
            vim.cmd('startinsert')
          end
        end)
      end
    elseif choice == 2 then
      vim.cmd('quit!')
    else
      vim.cmd('startinsert')
    end
  else
    vim.cmd('quit')
  end
end

-- File operations
vim.keymap.set({'i', 'n'}, '<C-s>', function() smart_save() end, opts)
vim.keymap.set({'i', 'n'}, '<C-q>', function() smart_quit() end, opts)
vim.keymap.set({'i', 'n'}, '<M-F4>', function() smart_quit() end, opts)

-- Standard editing shortcuts
vim.keymap.set({'i', 'n'}, '<C-z>', '<Esc>ui', opts)
vim.keymap.set({'i', 'n'}, '<C-y>', '<Esc><C-r>i', opts)
vim.keymap.set({'i', 'n'}, '<C-a>', '<Esc>ggVG', opts)
vim.keymap.set({'i', 'n'}, '<C-f>', '<Esc>/', opts)
vim.keymap.set({'i', 'n'}, '<C-h>', '<Esc>:%s/', opts)

-- Copy/Paste
-- Visual mode: copy/cut with proper newline handling and Windows-like selection
vim.keymap.set('v', '<C-c>', function()
  -- Simple approach: yank, get content, trim, set clipboard
  vim.cmd('normal! y')
  local content = vim.fn.getreg('"')
  
  -- Remove trailing newline if present
  if content:sub(-1) == '\n' then
    content = content:sub(1, -2)
  end
  
  -- For Windows-like behavior, also remove the last character if it seems like
  -- an extra character from inclusive selection
  -- This is a simple heuristic - if content ends with a non-newline character
  -- and we're doing a simple selection, trim one character
  local mode = vim.fn.visualmode()
  if mode == 'v' and #content > 1 and content:sub(-1) ~= '\n' then
    -- Check if this looks like we grabbed an extra character
    -- Only trim if the content doesn't end with whitespace (which would be intentional)
    local last_char = content:sub(-1)
    if not last_char:match('%s') then
      content = content:sub(1, -2)
    end
  end
  
  -- Set to system clipboard
  vim.fn.setreg('+', content)
  vim.cmd('normal! gv')  -- Restore selection
end, opts)

vim.keymap.set('v', '<C-x>', function()
  -- First, delete the selection (this also yanks it to the default register)
  vim.cmd('normal! d')
  
  -- Get what was deleted from the default register
  local content = vim.fn.getreg('"')
  
  -- Remove trailing newline if it exists
  if content:sub(-1) == '\n' then
    content = content:sub(1, -2)
  end
  
  -- Set cleaned content to system clipboard
  vim.fn.setreg('+', content)
  
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
vim.keymap.set('i', '<S-Left>', '<C-o>v<Left>', opts)
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

-- Tab navigation
vim.keymap.set({'i', 'n'}, '<C-Tab>', '<Esc>:tabnext<CR>', opts)
vim.keymap.set({'i', 'n'}, '<C-S-Tab>', '<Esc>:tabprevious<CR>', opts)
vim.keymap.set({'i', 'n'}, '<C-t>', '<Esc>:tabnew<CR>a', opts)

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

-- Set up autocmd for bracket highlighting
vim.api.nvim_create_autocmd({'CursorMoved', 'CursorMovedI'}, {
  callback = highlight_surrounding_brackets_multiline
})

-- Auto-wrapping function for selected text
local function wrap_selection(open_char, close_char)
  -- Get current visual selection
  vim.cmd('normal! "vy')  -- Yank visual selection to v register
  local selected_text = vim.fn.getreg('v')
  
  -- Replace selection with wrapped text
  local wrapped_text = open_char .. selected_text .. close_char
  vim.fn.setreg('v', wrapped_text)
  vim.cmd('normal! "vp')  -- Paste wrapped text
  
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



