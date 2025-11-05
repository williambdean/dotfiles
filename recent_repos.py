"""Module for pulling recent repositories and creating issues."""

import os
from typing import Callable, Dict, List, Optional


class RecentRepositories:
    """Class to manage recent repositories and callbacks."""

    def __init__(self, max_repos: int = 10):
        """Initialize the recent repositories manager.
        
        Args:
            max_repos: Maximum number of repositories to track
        """
        self.max_repos = max_repos
        self.repositories: List[Dict[str, str]] = []
        self.callbacks: List[Callable] = []

    def add_repository(self, name: str, url: str, description: str = "") -> None:
        """Add a repository to the recent list.
        
        Args:
            name: Repository name
            url: Repository URL
            description: Optional repository description
        """
        repo = {
            "name": name,
            "url": url,
            "description": description,
        }
        
        # Remove if already exists (to move it to front)
        self.repositories = [r for r in self.repositories if r["name"] != name]
        
        # Add to front
        self.repositories.insert(0, repo)
        
        # Trim to max_repos
        if len(self.repositories) > self.max_repos:
            self.repositories = self.repositories[:self.max_repos]

    def get_recent_repositories(self, limit: Optional[int] = None) -> List[Dict[str, str]]:
        """Get the list of recent repositories.
        
        Args:
            limit: Optional limit on number of repositories to return
            
        Returns:
            List of repository dictionaries
        """
        if limit is None:
            return self.repositories.copy()
        return self.repositories[:limit]

    def register_callback(self, callback: Callable) -> None:
        """Register a callback function for repository events.
        
        Args:
            callback: Function to call when creating an issue
        """
        if callback not in self.callbacks:
            self.callbacks.append(callback)

    def create_issue_for_repository(self, repo_name: str, issue_title: str, issue_body: str = "") -> List[Dict]:
        """Create an issue for a repository by invoking all registered callbacks.
        
        Args:
            repo_name: Name of the repository
            issue_title: Title for the issue
            issue_body: Body content for the issue
            
        Returns:
            List of results from all callbacks
        """
        # Find the repository
        repo = None
        for r in self.repositories:
            if r["name"] == repo_name:
                repo = r
                break
        
        if repo is None:
            raise ValueError(f"Repository '{repo_name}' not found in recent repositories")
        
        issue_data = {
            "repository": repo,
            "title": issue_title,
            "body": issue_body,
        }
        
        # Call all registered callbacks
        results = []
        for callback in self.callbacks:
            result = callback(issue_data)
            results.append(result)
        
        return results

    def clear_callbacks(self) -> None:
        """Clear all registered callbacks."""
        self.callbacks = []

    def clear_repositories(self) -> None:
        """Clear all repositories."""
        self.repositories = []
