local M = {}

local function query_files(lang, query_name)
  return vim.treesitter.query.get_files(lang, query_name)
end

function M.has_locals(lang)
  return #query_files(lang, "locals") > 0
end

function M.has_indents(lang)
  return #query_files(lang, "indents") > 0
end

function M.get_query(lang, query_name)
  return vim.treesitter.query.get(lang, query_name)
end

function M.get_query_files(lang, query_name)
  return query_files(lang, query_name)
end

function M.invalidate_query_file() end

function M.available_query_groups()
  return { "highlights", "injections", "locals", "indents", "folds" }
end

return M
