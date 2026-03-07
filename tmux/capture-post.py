#!/usr/bin/env python3
"""Read a captured idea from stdin and append it to post-ideas.md."""

# /// script
# dependencies = [
#   "libtmux",
# ]
# ///

import datetime
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from capture_utils import tmux_display, tmux_session, parse_idea  # noqa: E402


IDEAS_DIR = "/Users/will/github/personal/posts"
IDEAS_FILE = os.path.join(IDEAS_DIR, "post-ideas.md")


def append_entry(idea: str, summary: list[str]) -> None:
    timestamp = datetime.datetime.now().astimezone().isoformat()
    session = tmux_session()
    path = os.getcwd()
    os.makedirs(IDEAS_DIR, exist_ok=True)
    entry = [
        "---",
        f"Timestamp: {timestamp}",
        f"Session: {session}",
        f"Path: {path}",
        f"Idea: {idea}",
        "Summary:",
    ]
    if summary:
        entry.extend(summary)
    else:
        entry.append("(no summary)")
    entry.append("")

    with open(IDEAS_FILE, "a", encoding="utf-8") as fh:
        fh.write("\n".join(entry) + "\n")


def main() -> int:
    raw = sys.stdin.read()
    parsed = parse_idea(raw)
    if not parsed:
        tmux_display("Post idea: nothing to save.")
        return 1
    idea, summary = parsed
    append_entry(idea, summary)
    tmux_display(f"Post idea saved: {idea[:40]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
