-- vim: set tabstop=2 shiftwidth=2 expandtab :

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- This is also a good place to setup other settings (vim.opt)
local options = {
  autoindent = false,
  background = 'dark',
  clipboard = 'unnamedplus',
  expandtab = true,
  hidden = true,
  shiftwidth = 4,
  splitbelow = true,
  splitright = true,
  tabstop = 4,
  termguicolors = false,
  undofile = true,
  wrap = false,

  backupdir = vim.fn.expand('~/.cache/nvim/backup'),
  directory = vim.fn.expand('~/.cache/nvim/swap'),
  undodir = vim.fn.expand('~/.cache/nvim/undo'),
}
for k,v in pairs(options) do
    vim.opt[k] = v
end

-- Setup lazy.nvim
require("lazy").setup({
  'nvim-lualine/lualine.nvim',
  'lewis6991/gitsigns.nvim',
  { "ellisonleao/gruvbox.nvim", priority = 1000, config = true }
})

require('gruvbox').setup()
vim.cmd("colorscheme gruvbox")

require('lualine').setup({
  options = {
    theme = 'gruvbox',
  },
})
