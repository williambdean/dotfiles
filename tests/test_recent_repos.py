"""Tests for recent_repos module."""

import pytest
from recent_repos import RecentRepositories


class TestRecentRepositories:
    """Test cases for RecentRepositories class."""

    def test_initialization(self):
        """Test that RecentRepositories initializes correctly."""
        manager = RecentRepositories()
        assert manager.max_repos == 10
        assert manager.repositories == []
        assert manager.callbacks == []

    def test_initialization_with_custom_max(self):
        """Test initialization with custom max_repos."""
        manager = RecentRepositories(max_repos=5)
        assert manager.max_repos == 5

    def test_add_repository(self):
        """Test adding a repository."""
        manager = RecentRepositories()
        manager.add_repository("test-repo", "https://github.com/user/test-repo", "Test repo")
        
        repos = manager.get_recent_repositories()
        assert len(repos) == 1
        assert repos[0]["name"] == "test-repo"
        assert repos[0]["url"] == "https://github.com/user/test-repo"
        assert repos[0]["description"] == "Test repo"

    def test_add_multiple_repositories(self):
        """Test adding multiple repositories."""
        manager = RecentRepositories()
        manager.add_repository("repo1", "https://github.com/user/repo1")
        manager.add_repository("repo2", "https://github.com/user/repo2")
        manager.add_repository("repo3", "https://github.com/user/repo3")
        
        repos = manager.get_recent_repositories()
        assert len(repos) == 3
        assert repos[0]["name"] == "repo3"  # Most recent first
        assert repos[1]["name"] == "repo2"
        assert repos[2]["name"] == "repo1"

    def test_repository_order(self):
        """Test that repositories are ordered by recency."""
        manager = RecentRepositories()
        manager.add_repository("repo1", "https://github.com/user/repo1")
        manager.add_repository("repo2", "https://github.com/user/repo2")
        
        # Add repo1 again - it should move to the front
        manager.add_repository("repo1", "https://github.com/user/repo1")
        
        repos = manager.get_recent_repositories()
        assert len(repos) == 2
        assert repos[0]["name"] == "repo1"
        assert repos[1]["name"] == "repo2"

    def test_max_repos_limit(self):
        """Test that max_repos limit is enforced."""
        manager = RecentRepositories(max_repos=3)
        
        for i in range(5):
            manager.add_repository(f"repo{i}", f"https://github.com/user/repo{i}")
        
        repos = manager.get_recent_repositories()
        assert len(repos) == 3
        assert repos[0]["name"] == "repo4"
        assert repos[1]["name"] == "repo3"
        assert repos[2]["name"] == "repo2"

    def test_get_recent_repositories_with_limit(self):
        """Test getting repositories with a custom limit."""
        manager = RecentRepositories()
        for i in range(5):
            manager.add_repository(f"repo{i}", f"https://github.com/user/repo{i}")
        
        repos = manager.get_recent_repositories(limit=2)
        assert len(repos) == 2
        assert repos[0]["name"] == "repo4"
        assert repos[1]["name"] == "repo3"

    def test_register_callback(self):
        """Test registering a callback."""
        manager = RecentRepositories()
        
        def test_callback(issue_data):
            return {"status": "success"}
        
        manager.register_callback(test_callback)
        assert len(manager.callbacks) == 1
        assert manager.callbacks[0] == test_callback

    def test_register_multiple_callbacks(self):
        """Test registering multiple callbacks."""
        manager = RecentRepositories()
        
        def callback1(issue_data):
            return {"callback": 1}
        
        def callback2(issue_data):
            return {"callback": 2}
        
        manager.register_callback(callback1)
        manager.register_callback(callback2)
        
        assert len(manager.callbacks) == 2

    def test_register_duplicate_callback(self):
        """Test that duplicate callbacks are not added."""
        manager = RecentRepositories()
        
        def test_callback(issue_data):
            return {"status": "success"}
        
        manager.register_callback(test_callback)
        manager.register_callback(test_callback)
        
        assert len(manager.callbacks) == 1

    def test_create_issue_for_repository(self):
        """Test creating an issue for a repository."""
        manager = RecentRepositories()
        manager.add_repository("test-repo", "https://github.com/user/test-repo")
        
        callback_data = []
        
        def test_callback(issue_data):
            callback_data.append(issue_data)
            return {"status": "created", "issue_id": 123}
        
        manager.register_callback(test_callback)
        
        results = manager.create_issue_for_repository(
            "test-repo",
            "Bug Report",
            "Found a bug"
        )
        
        assert len(results) == 1
        assert results[0]["status"] == "created"
        assert results[0]["issue_id"] == 123
        
        assert len(callback_data) == 1
        assert callback_data[0]["repository"]["name"] == "test-repo"
        assert callback_data[0]["title"] == "Bug Report"
        assert callback_data[0]["body"] == "Found a bug"

    def test_create_issue_with_multiple_callbacks(self):
        """Test creating an issue with multiple callbacks."""
        manager = RecentRepositories()
        manager.add_repository("test-repo", "https://github.com/user/test-repo")
        
        def callback1(issue_data):
            return {"callback": 1, "title": issue_data["title"]}
        
        def callback2(issue_data):
            return {"callback": 2, "repo": issue_data["repository"]["name"]}
        
        manager.register_callback(callback1)
        manager.register_callback(callback2)
        
        results = manager.create_issue_for_repository("test-repo", "Test Issue")
        
        assert len(results) == 2
        assert results[0]["callback"] == 1
        assert results[0]["title"] == "Test Issue"
        assert results[1]["callback"] == 2
        assert results[1]["repo"] == "test-repo"

    def test_create_issue_for_nonexistent_repository(self):
        """Test that creating an issue for a non-existent repo raises an error."""
        manager = RecentRepositories()
        manager.add_repository("repo1", "https://github.com/user/repo1")
        
        def test_callback(issue_data):
            return {"status": "success"}
        
        manager.register_callback(test_callback)
        
        with pytest.raises(ValueError, match="Repository 'nonexistent' not found"):
            manager.create_issue_for_repository("nonexistent", "Test Issue")

    def test_clear_callbacks(self):
        """Test clearing callbacks."""
        manager = RecentRepositories()
        
        def test_callback(issue_data):
            return {"status": "success"}
        
        manager.register_callback(test_callback)
        assert len(manager.callbacks) == 1
        
        manager.clear_callbacks()
        assert len(manager.callbacks) == 0

    def test_clear_repositories(self):
        """Test clearing repositories."""
        manager = RecentRepositories()
        manager.add_repository("repo1", "https://github.com/user/repo1")
        manager.add_repository("repo2", "https://github.com/user/repo2")
        
        assert len(manager.get_recent_repositories()) == 2
        
        manager.clear_repositories()
        assert len(manager.get_recent_repositories()) == 0

    def test_add_repository_without_description(self):
        """Test adding a repository without description."""
        manager = RecentRepositories()
        manager.add_repository("test-repo", "https://github.com/user/test-repo")
        
        repos = manager.get_recent_repositories()
        assert repos[0]["description"] == ""

    def test_callback_receives_correct_data(self):
        """Test that callbacks receive all expected data fields."""
        manager = RecentRepositories()
        manager.add_repository("test-repo", "https://github.com/user/test-repo", "Test description")
        
        received_data = None
        
        def test_callback(issue_data):
            nonlocal received_data
            received_data = issue_data
            return {"status": "ok"}
        
        manager.register_callback(test_callback)
        manager.create_issue_for_repository("test-repo", "Issue Title", "Issue Body")
        
        assert received_data is not None
        assert "repository" in received_data
        assert "title" in received_data
        assert "body" in received_data
        assert received_data["repository"]["name"] == "test-repo"
        assert received_data["repository"]["url"] == "https://github.com/user/test-repo"
        assert received_data["repository"]["description"] == "Test description"
        assert received_data["title"] == "Issue Title"
        assert received_data["body"] == "Issue Body"


@pytest.mark.parametrize("max_repos", [1, 5, 10, 20])
def test_various_max_repos_limits(max_repos):
    """Test with various max_repos values."""
    manager = RecentRepositories(max_repos=max_repos)
    
    # Add more than max_repos
    for i in range(max_repos + 5):
        manager.add_repository(f"repo{i}", f"https://github.com/user/repo{i}")
    
    repos = manager.get_recent_repositories()
    assert len(repos) == max_repos


@pytest.mark.parametrize("repo_count,limit,expected", [
    (5, 3, 3),
    (5, 10, 5),
    (10, 5, 5),
    (0, 5, 0),
])
def test_get_recent_with_various_limits(repo_count, limit, expected):
    """Test get_recent_repositories with various limits."""
    manager = RecentRepositories()
    
    for i in range(repo_count):
        manager.add_repository(f"repo{i}", f"https://github.com/user/repo{i}")
    
    repos = manager.get_recent_repositories(limit=limit)
    assert len(repos) == expected
