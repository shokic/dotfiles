vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = false

local set = vim.opt

set.number = true
set.relativenumber = true
set.mouse = "a"
set.showmode = false
set.breakindent = true
set.undofile = true
set.ignorecase = true
set.smartcase = true
set.signcolumn = "yes"
set.updatetime = 250
set.timeoutlen = 300
set.splitright = true
set.splitbelow = true
set.list = true
set.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
set.inccommand = "split"
set.cursorline = true
set.scrolloff = 10
set.shiftwidth = 2
set.expandtab = true
set.smartindent = true
set.clipboard = "unnamedplus"
