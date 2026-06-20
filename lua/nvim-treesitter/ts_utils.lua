local M = {}

function M.get_node_at_cursor(winnr, ignore_injections)
  winnr = winnr or 0
  local bufnr = vim.api.nvim_win_get_buf(winnr)
  local cursor = vim.api.nvim_win_get_cursor(winnr)
  return vim.treesitter.get_node {
    bufnr = bufnr,
    pos = { cursor[1] - 1, cursor[2] },
    ignore_injections = ignore_injections,
  }
end

function M.get_node_range(node)
  return node:range()
end

function M.is_in_node_range(node, line, col)
  return vim.treesitter.is_in_node_range(node, line, col)
end

function M.get_node_text(node, bufnr)
  return vim.treesitter.get_node_text(node, bufnr or 0)
end

function M.get_root_for_node(node)
  local root = node
  while root and root:parent() do
    root = root:parent()
  end
  return root
end

return M
