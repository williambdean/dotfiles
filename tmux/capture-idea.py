#!/usr/bin/env python3
"""Capture an idea in a tmux popup and append it to post-ideas.md."""

# /// script
# dependencies = [
#   "libtmux",
# ]
# ///

import os
from pathlib import Path

import sys
import tempfile
import subprocess

import libtmux


def tmux_display(message: str) -> None:
    server = libtmux.Server()
    server.cmd("display-message", message)


def tmux_session() -> str:
    server = libtmux.Server()
    # Get the current session using libtmux API
    result = server.cmd("display-message", "-p", "#S")
    return result.stdout[0].strip() if result.stdout else "(unknown)"


def open_editor(path: str) -> int:
    editor = os.environ.get("EDITOR", "vim")
    with open("/dev/tty", "r+") as tty:
        return subprocess.run(
            [editor, path],
            stdin=tty,
            stdout=tty,
            check=False,
        ).returncode


def read_idea(path: str) -> tuple[str, list[str]] | None:
    with open(path, encoding="utf-8") as fh:
        raw = fh.read()

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


def main() -> int:
    tmux_display("Capture idea: write your idea, save and quit.")
    temp = tempfile.NamedTemporaryFile(mode="w+", suffix=".md", delete=False)
    temp_path = temp.name
    temp.close()
    try:
        open_editor(temp_path)
        content = Path(temp_path).read_text()
        if not content.strip():
            tmux_display("Idea capture cancelled (nothing written).")
            return 1
        sys.stdout.write(content)
        return 0
    finally:
        try:
            os.unlink(temp_path)
        except OSError:
            pass


if __name__ == "__main__":
    sys.exit(main())
