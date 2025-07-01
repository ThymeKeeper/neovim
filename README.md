# Neovim for People Who Hate Vim

> **"If you like Neovim, you'll hate this config."**

This is a Neovim configuration that systematically removes everything that makes Vim... Vim. It's for those who want Neovim's powerful syntax highlighting and extensibility but absolutely despise modal editing.

## What This Does

This config transforms Neovim into a Windows-like text editor by:

- **Permanently locking you in INSERT mode** - The Escape key is disabled. You literally cannot exit insert mode through normal means.
- **Making all normal mode commands immediately return to insert mode** - Even if you somehow end up in normal mode, any key press will throw you back into insert.
- **Implementing Windows-style keybindings** - Ctrl+S to save, Ctrl+A to select all, Ctrl+C/V for copy/paste, etc.
- **Supporting mouse interaction** - Click, drag, select text like a normal person.
- **Adding familiar text navigation** - Shift+arrows for selection, Ctrl+arrows for word jumping, Home/End keys work as expected.
- **Auto-indenting and bracket matching** - Some modern conveniences are preserved.

## Features

### File Operations
- `Ctrl+S` - Save file (prompts for filename if new)
- `Ctrl+Q` / `Alt+F4` - Quit (with save prompt if modified)
- `Ctrl+Tab` / `Ctrl+Shift+Tab` - Switch between tabs
- `Ctrl+T` - New tab

### Editing
- `Ctrl+C` - Copy (works on selection or single character)
- `Ctrl+X` - Cut (works on selection or single character)
- `Ctrl+V` - Paste
- `Ctrl+Z` - Undo
- `Ctrl+Y` - Redo
- `Ctrl+A` - Select all
- `Ctrl+F` - Find
- `Ctrl+H` - Find and replace
- `Tab` - Indent / autocomplete
- `Shift+Tab` - Unindent

### Navigation
- Arrow keys work normally (with line wrapping)
- `Shift+Arrows` - Select text
- `Ctrl+Left/Right` - Jump words
- `Ctrl+Up/Down` - Jump paragraphs
- `Home/End` - Beginning/end of line
- `PageUp/PageDown` - Scroll pages
- Mouse support for clicking and selecting

### Special Features
- `Alt+W` - Toggle word wrap
- `Ctrl+Shift+Up/Down` - Move lines up/down
- Visual mode auto-wraps selections in brackets/quotes when typed
- Automatic bracket highlighting when cursor is inside
- Terminal title shows current filename
- Dark color scheme optimized for long coding sessions

## Installation

1. Back up your existing Neovim config:
   ```bash
   mv ~/.config/nvim ~/.config/nvim.backup
   ```

2. Create new config directory:
   ```bash
   mkdir -p ~/.config/nvim
   ```

3. Copy the `init.lua` file to:
   ```bash
   ~/.config/nvim/init.lua
   ```

4. Launch Neovim and enjoy your heresy.

## Terminal Compatibility

This config works best with modern terminals. Tested with:
- Kitty (recommended)
- Alacritty  
- Windows Terminal
- iTerm2

Some keybindings (like Alt+arrows) may conflict with terminal or window manager shortcuts. Adjust your terminal settings or use the alternative bindings provided.

## Why Would Anyone Do This?

Sometimes you need Neovim's features (syntax highlighting, fast startup, extensibility, remote editing) but you're coming from VS Code, Sublime Text, or Notepad++ and modal editing feels like using a computer with oven mitts on.

This config is for:
- People forced to use Neovim on remote servers
- Those who want a consistent editor between local and SSH sessions  
- Developers who appreciate Neovim's speed but not its philosophy
- Anyone who thinks hitting 'i' to start typing is one key too many

## What You're Missing

By using this config, you're giving up:
- Efficient text manipulation commands
- The ability to look cool in front of other developers
- Vim macros and advanced movements
- About 90% of Neovim's features
- The respect of the Vim community

## Contributing

Feel free to submit PRs that make this config even less Vim-like. Ideas:
- Add a ribbon menu
- Implement Clippy
- Add auto-save every keystroke
- Make `:q` open a confirmation dialog with 17 buttons

## License

This config is released into the public domain. Do whatever you want with it. The Vim community has already disowned us anyway.

---

*"It's not a bug, it's a feature removal."*
