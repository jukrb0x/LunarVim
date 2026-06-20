local M = {}

local state = {
  modules = {},
}

function M.setup(opts)
  state.modules = vim.deepcopy(opts or {})
  _G.__lvim_treesitter_compat = state

  local ok_treesitter, treesitter = pcall(require, "nvim-treesitter")
  if ok_treesitter then
    treesitter.define_modules = function(modules)
      state.modules = vim.tbl_deep_extend("force", state.modules, modules or {})
    end

    treesitter.is_module_enabled = function(name)
      local module = state.modules[name]
      return module and module.enable ~= false
    end
  end

  local ok, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok then
    return
  end

  parsers.list = parsers

  parsers.get_parser_configs = function()
    return parsers
  end

  parsers.available_parsers = function()
    local available = vim.tbl_keys(parsers)
    table.sort(available)
    return available
  end

  parsers.has_parser = function(lang)
    lang = lang or vim.treesitter.language.get_lang(vim.bo.filetype) or vim.bo.filetype
    return pcall(vim.treesitter.language.add, lang)
  end

  parsers.get_parser = function(bufnr, lang)
    bufnr = bufnr or 0
    lang = lang or vim.treesitter.language.get_lang(vim.bo[bufnr].filetype) or vim.bo[bufnr].filetype
    return vim.treesitter.get_parser(bufnr, lang)
  end
end

function M.get_module(name)
  return state.modules[name] or {}
end

function M.available_modules()
  return vim.tbl_keys(state.modules)
end

return M
