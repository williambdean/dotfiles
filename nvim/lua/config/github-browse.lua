local gh = require "octo.gh"

local function pick_github_repo(callback)
  vim.ui.input({
    prompt = "Search GitHub repos: ",
  }, function(query)
    if not query or query == "" then
      return
    end

    vim.notify("Searching GitHub for: " .. query, vim.log.levels.INFO)

    gh.search.repos {
      query,
      json = "fullName,description",
      limit = 30,
      opts = {
        cb = gh.create_callback {
          success = function(output)
            local ok, repos = pcall(vim.json.decode, output)
            if not ok then
              vim.notify(
                "Failed to parse repos: " .. repos,
                vim.log.levels.ERROR
              )
              return
            end

            if #repos == 0 then
              vim.notify("No repos found for: " .. query, vim.log.levels.WARN)
              return
            end

            vim.ui.select(repos, {
              prompt = "Select a repository:",
              format_item = function(item)
                return item.fullName .. ": " .. item.description
              end,
            }, function(selected)
              if not selected then
                return
              end

              callback(selected)
            end)
          end,
          failure = function(err)
            vim.notify("Search failed: " .. err, vim.log.levels.ERROR)
          end,
        },
      },
    }
  end)
end

local function browse_github_repos()
  pick_github_repo(function(selected)
    local full_name = selected.fullName
    local owner, repo_name = full_name:match "([^/]+)/(.+)"
    local target_dir = string.format("/tmp/github-%s-%s", owner, repo_name)

    if vim.fn.isdirectory(target_dir) == 1 then
      vim.notify(
        "Already cloned: " .. target_dir .. " - opening in oil",
        vim.log.levels.INFO
      )
      require("oil").open(target_dir)
      return
    end

    vim.notify(
      "Cloning " .. full_name .. " to " .. target_dir,
      vim.log.levels.INFO
    )

    local clone_cmd = {
      "git",
      "clone",
      "--depth",
      "1",
      "--filter=blob:none",
      "https://github.com/" .. full_name .. ".git",
      target_dir,
    }

    vim.fn.system(clone_cmd)

    if vim.v.shell_error ~= 0 then
      vim.notify("Failed to clone repo", vim.log.levels.ERROR)
      return
    end

    vim.notify("Opened: " .. full_name, vim.log.levels.INFO)
    require("oil").open(target_dir)
  end)
end

local function browse_github_issues()
  pick_github_repo(function(selected)
    require("octo.picker").issues { repo = selected.fullName }
  end)
end

vim.keymap.set("n", "<leader>gs", browse_github_repos, {
  desc = "Search GitHub repos and browse in oil",
})
vim.keymap.set("n", "<leader>gi", browse_github_issues, {
  desc = "Search GitHub repos and browse its issues",
})

return { pick_github_repo = pick_github_repo }
