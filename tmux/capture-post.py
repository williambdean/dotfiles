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

import libtmux


IDEAS_DIR = "/Users/will/github/personal/posts"
IDEAS_FILE = os.path.join(IDEAS_DIR, "post-ideas.md")


def tmux_display(message: str) -> None:
    server = libtmux.Server()
    server.cmd("display-message", message)


def tmux_session() -> str:
    server = libtmux.Server()
    result = server.cmd("display-message", "-p", "#S")
    return result.stdout[0].strip() if result.stdout else "(unknown)"


def parse_idea(raw: str) -> tuple[str, list[str]] | None:
    if not raw.strip():
        return None

    lines = raw.splitlines()
    while lines and not lines[0].strip():
        lines.pop(0)
    while lines and not lines[-1].strip():
        lines.pop()
    if not lines:
        return None

    idea_line = lines[0].strip()
    summary_lines = lines[1:]
    while summary_lines and not summary_lines[0].strip():
        summary_lines.pop(0)

    return idea_line, summary_lines


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
