local plugin_parsers = vim.fs.joinpath(
  vim.env.LUNARVIM_RUNTIME_DIR or vim.fn.stdpath "data",
  "site",
  "pack",
  "lazy",
  "opt",
  "nvim-treesitter",
  "lua",
  "nvim-treesitter",
  "parsers.lua"
)

local M = dofile(plugin_parsers)

M.list = M

function M.get_parser_configs()
  return M
end

function M.available_parsers()
  local available = vim.tbl_keys(M)
  table.sort(available)
  return available
end

function M.has_parser(lang)
  lang = lang or vim.treesitter.language.get_lang(vim.bo.filetype) or vim.bo.filetype
  return pcall(vim.treesitter.language.add, lang)
end

function M.get_parser(bufnr, lang)
  bufnr = bufnr or 0
  lang = lang or vim.treesitter.language.get_lang(vim.bo[bufnr].filetype) or vim.bo[bufnr].filetype
  return vim.treesitter.get_parser(bufnr, lang)
end

return M
