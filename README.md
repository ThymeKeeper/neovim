# Neovim for People Who Hate Vim

This is a Neovim configuration that systematically removes everything that makes Vim... Vim. It's for those who want Neovim's syntax highlighting and extensibility but absolutely despise modal editing.

## What This Does

This config transforms Neovim into a Windows-like text editor by:

- **Permanently locking you in INSERT mode** - The Escape key is disabled. You literally cannot exit insert mode through normal means.
- **Making all normal mode commands immediately return to insert mode** - Even if you somehow end up in normal mode, any key press will throw you back into insert.
- **Implementing Windows-style keybindings** - Ctrl+S to save, Ctrl+A to select all, Ctrl+C/V for copy/paste, etc.Most keys work as expected for a windows user.

## Features

### File Operations
- `Ctrl+S` - Save file (prompts for filename if new)
- `Ctrl+Q` / `Alt+F4` - Quit (with save prompt if modified)

### Editing
- `Ctrl+C` - Copy (works on selection or single character)
- `Ctrl+X` - Cut (works on selection or single character)
- `Ctrl+V` - Paste
- `Ctrl+Z` - Undo
- `Ctrl+Y` - Redo
- `Ctrl+A` - Select all
- `Ctrl+F` - Find / replace
- `Tab` - Indent / autocomplete
- `Shift+Tab` - Unindent

### Navigation
- Arrow keys work normally
- `Shift+Arrows` - Select text
- `Ctrl+Left/Right` - Jump words
- `Ctrl+Up/Down` - Jump paragraphs
- `Home/End` - Beginning/end of line
- `PageUp/PageDown` - Scroll pages
- Mouse support for clicking and selecting
- `Alt+W` - Toggle word wrap
- `Ctrl+Shift+Up/Down` - Move lines up/down

## This config is for:

- People forced to use Neovim on remote servers
- Those who want a consistent editor between local and SSH sessions  
- Developers who appreciate Neovim's speed and customizabiltiy but not its philosophy
- Anyone who thinks hitting 'i' to start typing is one key too many

## What You're Missing

- Efficient text manipulation commands
- The ability to look cool in front of other developers
- Vim macros and advanced movements
- About 90% of Neovim's features
- The respect of the Vim community

## Contributing

Feel free to submit PRs that make this config even less Vim-like. Ideas:
- Add a ribbon menu
- Implement Clippy
- Make `:q` open a confirmation dialog with 17 context relevant bindings

## License

This config is released into the public domain. Do whatever you want with it. The Vim community has already disowned us anyway.

---

*"It's not a bug, it's a feature removal."*
