# BufComm

BufComm is a Vim plugin that compares two buffers or files using the Unix `comm` utility and displays the results in a tab with three splits:

- lines unique to the first buffer
- lines unique to the second buffer
- lines common to both

## Requirements

- Vim compiled with `+terminal` support for running external commands.
- The standard `comm` command available in your shell environment (part of GNU coreutils on macOS/Linux).

## Installation

[Lazy](https://github.com/folke/lazy.nvim)

```lua
{ "haodarohh/bufcomm.vim" }
```

re-open your vim

[vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'haodarohh/bufcomm.vim'
```

Then run `:PlugInstall` (or the equivalent command for your plugin manager) and restart Vim.

## Usage

Open two buffers (or provide two file paths) and run:

```vim
:BufComm
```

When no arguments are provided, BufComm compares the two listed buffers. You can also compare arbitrary files:

```vim
:BufComm path/to/file1 path/to/file2
```

BufComm opens a new tabpage with three vertically stacked windows showing the comparison results. Use `:BufCommPaths` to display the full paths of the files that were compared, or trigger the `<Leader>bc` mapping (defined unless already mapped) to start a comparison quickly.
