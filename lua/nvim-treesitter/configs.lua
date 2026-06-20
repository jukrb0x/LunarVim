local compat = require "lvim.core.treesitter_compat"

local M = {}

function M.setup(opts)
  opts = opts or {}
  compat.setup(opts)
  require("nvim-treesitter").setup {
    install_dir = opts.parser_install_dir or (vim.fn.stdpath "data" .. "/site"),
  }
end

function M.get_module(name)
  return compat.get_module(name)
end

function M.available_modules()
  return compat.available_modules()
end

function M.define_modules() end
function M.attach_module() end
function M.detach_module() end
function M.reattach_module() end

return M
