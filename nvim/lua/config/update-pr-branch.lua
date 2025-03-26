local gh = require "octo.gh"

local M = {}

local query = [[
mutation(
  $id: ID!,
  $method: PullRequestBranchUpdateMethod = MERGE,
){
  updatePullRequestBranch(input: {
    pullRequestId: $id,
    updateMethod: $method,
  }) {
    pullRequest {
      id
    }
  }
}
]]

M.update_branch = function(opts)
  gh.api.graphql {
    query = query,
    fields = opts,
    jq = ".data.updatePullRequestBranch.pullRequest.id",
    opts = {
      cb = gh.create_callback {},
    },
  }
end

return M
