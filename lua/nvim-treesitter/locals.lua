local M = {}

function M.containing_scope(node)
  local current = node
  while current do
    local node_type = current:type()
    if node_type:find "function" or node_type:find "method" or node_type:find "block" or node_type:find "scope" then
      return current
    end
    current = current:parent()
  end
  return node
end

function M.find_definition(node)
  return node, M.containing_scope(node), nil
end

function M.find_usages()
  return {}
end

return M
