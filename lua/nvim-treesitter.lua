local plugin_init = vim.fs.joinpath(
  vim.env.LUNARVIM_RUNTIME_DIR or vim.fn.stdpath "data",
  "site",
  "pack",
  "lazy",
  "opt",
  "nvim-treesitter",
  "lua",
  "nvim-treesitter",
  "init.lua"
)

local M = dofile(plugin_init)

M.define_modules = function(modules)
  local compat = require "lvim.core.treesitter_compat"
  local state = _G.__lvim_treesitter_compat or { modules = {} }
  state.modules = vim.tbl_deep_extend("force", state.modules or {}, modules or {})
  _G.__lvim_treesitter_compat = state
  compat.setup(state.modules)
end

M.is_module_enabled = function(name)
  local state = _G.__lvim_treesitter_compat or { modules = {} }
  local module = state.modules and state.modules[name]
  return module and module.enable ~= false
end

return M
