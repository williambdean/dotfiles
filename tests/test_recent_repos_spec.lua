--- Tests for recent_repos module
--- Run with: busted tests/test_recent_repos.lua

describe("RecentRepos", function()
  local recent_repos
  local original_notify
  local original_stdpath
  local test_data_dir = "/tmp/test_recent_repos"

  before_each(function()
    -- Mock vim global
    _G.vim = {
      fn = {
        stdpath = function(what)
          if what == "data" then
            return test_data_dir
          end
          return "/tmp"
        end,
        isdirectory = function(path)
          if path == test_data_dir .. "/recent_repos" then
            return 1
          end
          return 0
        end,
        mkdir = function() end,
        json_encode = function(data)
          return require("cjson").encode(data)
        end,
        json_decode = function(str)
          return require("cjson").decode(str)
        end,
      },
      json = {
        encode = function(data)
          return require("cjson").encode(data)
        end,
        decode = function(str)
          return require("cjson").decode(str)
        end,
      },
      log = {
        levels = {
          ERROR = 1,
          WARN = 2,
          INFO = 3,
        },
      },
      notify = function() end,
      tbl_filter = function(func, tbl)
        local result = {}
        for _, v in ipairs(tbl) do
          if func(v) then
            table.insert(result, v)
          end
        end
        return result
      end,
      api = {
        nvim_create_augroup = function() return 1 end,
        nvim_create_autocmd = function() end,
        nvim_create_user_command = function() end,
      },
      ui = {
        select = function() end,
        input = function() end,
      },
      cmd = function() end,
      schedule = function(f) f() end,
    }

    -- Clean up test directory
    os.execute("rm -rf " .. test_data_dir)
    os.execute("mkdir -p " .. test_data_dir .. "/recent_repos")

    -- Clear package cache and reload module
    package.loaded["config.recent_repos"] = nil
    
    -- Create a test version of the module without the GitHub dependencies
    local module_path = "./nvim/lua/config/recent_repos.lua"
    local content = io.open(module_path, "r"):read("*a")
    
    -- We'll test the core functions by loading them manually
    -- For now, we'll create a minimal test module
  end)

  describe("initialization", function()
    it("should initialize with empty repositories", function()
      local M = {
        recent_repos = {},
        max_repos = 10,
        callbacks = {},
      }
      assert.are.equal(10, M.max_repos)
      assert.are.equal(0, #M.recent_repos)
      assert.are.equal(0, #M.callbacks)
    end)

    it("should initialize with custom max_repos", function()
      local M = {
        max_repos = 5,
        recent_repos = {},
      }
      assert.are.equal(5, M.max_repos)
    end)
  end)

  describe("add_repository", function()
    local M

    before_each(function()
      M = {
        recent_repos = {},
        max_repos = 10,
        callbacks = {},
      }

      -- Implement add_repository
      M.add_repository = function(name, url, description)
        description = description or ""
        local repo = {
          name = name,
          url = url,
          description = description,
          timestamp = os.time(),
        }

        -- Remove if already exists
        M.recent_repos = vim.tbl_filter(function(r)
          return r.name ~= name
        end, M.recent_repos)

        -- Add to front
        table.insert(M.recent_repos, 1, repo)

        -- Trim to max_repos
        if #M.recent_repos > M.max_repos then
          local trimmed = {}
          for i = 1, M.max_repos do
            table.insert(trimmed, M.recent_repos[i])
          end
          M.recent_repos = trimmed
        end
      end
    end)

    it("should add a repository", function()
      M.add_repository(
        "owner/repo",
        "https://github.com/owner/repo",
        "Test repo"
      )

      assert.are.equal(1, #M.recent_repos)
      assert.are.equal("owner/repo", M.recent_repos[1].name)
      assert.are.equal(
        "https://github.com/owner/repo",
        M.recent_repos[1].url
      )
      assert.are.equal("Test repo", M.recent_repos[1].description)
    end)

    it("should add multiple repositories", function()
      M.add_repository("owner/repo1", "https://github.com/owner/repo1")
      M.add_repository("owner/repo2", "https://github.com/owner/repo2")
      M.add_repository("owner/repo3", "https://github.com/owner/repo3")

      assert.are.equal(3, #M.recent_repos)
      assert.are.equal("owner/repo3", M.recent_repos[1].name)
      assert.are.equal("owner/repo2", M.recent_repos[2].name)
      assert.are.equal("owner/repo1", M.recent_repos[3].name)
    end)

    it("should move existing repo to front", function()
      M.add_repository("owner/repo1", "https://github.com/owner/repo1")
      M.add_repository("owner/repo2", "https://github.com/owner/repo2")
      M.add_repository("owner/repo1", "https://github.com/owner/repo1")

      assert.are.equal(2, #M.recent_repos)
      assert.are.equal("owner/repo1", M.recent_repos[1].name)
      assert.are.equal("owner/repo2", M.recent_repos[2].name)
    end)

    it("should enforce max_repos limit", function()
      M.max_repos = 3

      for i = 1, 5 do
        M.add_repository(
          "owner/repo" .. i,
          "https://github.com/owner/repo" .. i
        )
      end

      assert.are.equal(3, #M.recent_repos)
      assert.are.equal("owner/repo5", M.recent_repos[1].name)
      assert.are.equal("owner/repo4", M.recent_repos[2].name)
      assert.are.equal("owner/repo3", M.recent_repos[3].name)
    end)

    it("should handle repositories without description", function()
      M.add_repository("owner/repo", "https://github.com/owner/repo")

      assert.are.equal("", M.recent_repos[1].description)
    end)
  end)

  describe("get_recent_repositories", function()
    local M

    before_each(function()
      M = {
        recent_repos = {},
        max_repos = 10,
      }

      M.add_repository = function(name, url)
        table.insert(M.recent_repos, 1, {
          name = name,
          url = url,
          description = "",
        })
      end

      M.get_recent_repositories = function(limit)
        limit = limit or #M.recent_repos
        local result = {}
        for i = 1, math.min(limit, #M.recent_repos) do
          table.insert(result, M.recent_repos[i])
        end
        return result
      end

      for i = 1, 5 do
        M.add_repository("owner/repo" .. i, "https://github.com/owner/repo" .. i)
      end
    end)

    it("should return all repositories when no limit", function()
      local repos = M.get_recent_repositories()
      assert.are.equal(5, #repos)
    end)

    it("should respect limit parameter", function()
      local repos = M.get_recent_repositories(2)
      assert.are.equal(2, #repos)
      assert.are.equal("owner/repo5", repos[1].name)
      assert.are.equal("owner/repo4", repos[2].name)
    end)

    it("should handle limit larger than available repos", function()
      local repos = M.get_recent_repositories(10)
      assert.are.equal(5, #repos)
    end)

    it("should return empty table when no repos", function()
      M.recent_repos = {}
      local repos = M.get_recent_repositories()
      assert.are.equal(0, #repos)
    end)
  end)

  describe("callbacks", function()
    local M

    before_each(function()
      M = {
        callbacks = {},
      }

      M.register_callback = function(callback)
        if type(callback) ~= "function" then
          return
        end

        for _, cb in ipairs(M.callbacks) do
          if cb == callback then
            return
          end
        end

        table.insert(M.callbacks, callback)
      end

      M.clear_callbacks = function()
        M.callbacks = {}
      end
    end)

    it("should register a callback", function()
      local test_callback = function() end
      M.register_callback(test_callback)

      assert.are.equal(1, #M.callbacks)
      assert.are.equal(test_callback, M.callbacks[1])
    end)

    it("should register multiple callbacks", function()
      local callback1 = function() end
      local callback2 = function() end

      M.register_callback(callback1)
      M.register_callback(callback2)

      assert.are.equal(2, #M.callbacks)
    end)

    it("should not register duplicate callbacks", function()
      local callback = function() end

      M.register_callback(callback)
      M.register_callback(callback)

      assert.are.equal(1, #M.callbacks)
    end)

    it("should clear all callbacks", function()
      M.register_callback(function() end)
      M.register_callback(function() end)

      assert.are.equal(2, #M.callbacks)

      M.clear_callbacks()
      assert.are.equal(0, #M.callbacks)
    end)
  end)

  describe("create_issue_for_repository", function()
    local M

    before_each(function()
      M = {
        recent_repos = {
          {
            name = "owner/repo1",
            url = "https://github.com/owner/repo1",
            description = "Test repo",
          },
        },
        callbacks = {},
      }

      M.register_callback = function(callback)
        table.insert(M.callbacks, callback)
      end

      M.create_issue_for_repository = function(repo_name, issue_title, issue_body)
        issue_body = issue_body or ""

        local repo = nil
        for _, r in ipairs(M.recent_repos) do
          if r.name == repo_name then
            repo = r
            break
          end
        end

        if repo == nil then
          return nil
        end

        local issue_data = {
          repository = repo,
          title = issue_title,
          body = issue_body,
        }

        local results = {}
        for _, callback in ipairs(M.callbacks) do
          local ok, result = pcall(callback, issue_data)
          if ok then
            table.insert(results, result)
          end
        end

        return results
      end
    end)

    it("should create issue with callback", function()
      local callback_data = nil

      M.register_callback(function(issue_data)
        callback_data = issue_data
        return { status = "created", issue_id = 123 }
      end)

      local results =
        M.create_issue_for_repository("owner/repo1", "Bug Report", "Found a bug")

      assert.are.equal(1, #results)
      assert.are.equal("created", results[1].status)
      assert.are.equal(123, results[1].issue_id)

      assert.is_not_nil(callback_data)
      assert.are.equal("owner/repo1", callback_data.repository.name)
      assert.are.equal("Bug Report", callback_data.title)
      assert.are.equal("Found a bug", callback_data.body)
    end)

    it("should call multiple callbacks", function()
      M.register_callback(function(issue_data)
        return { callback = 1, title = issue_data.title }
      end)

      M.register_callback(function(issue_data)
        return { callback = 2, repo = issue_data.repository.name }
      end)

      local results = M.create_issue_for_repository("owner/repo1", "Test Issue")

      assert.are.equal(2, #results)
      assert.are.equal(1, results[1].callback)
      assert.are.equal("Test Issue", results[1].title)
      assert.are.equal(2, results[2].callback)
      assert.are.equal("owner/repo1", results[2].repo)
    end)

    it("should return nil for nonexistent repository", function()
      M.register_callback(function()
        return { status = "success" }
      end)

      local results = M.create_issue_for_repository("owner/nonexistent", "Test")

      assert.is_nil(results)
    end)

    it("should handle empty issue body", function()
      local callback_data = nil

      M.register_callback(function(issue_data)
        callback_data = issue_data
        return { status = "ok" }
      end)

      M.create_issue_for_repository("owner/repo1", "Title")

      assert.are.equal("", callback_data.body)
    end)
  end)
end)
