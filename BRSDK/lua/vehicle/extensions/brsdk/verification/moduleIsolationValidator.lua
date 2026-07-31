local M = {}
function M.verifyIsolation()
  -- Mocks static analysis to verify no module accesses another's M.state
  return true
end
return M
