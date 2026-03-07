#!/usr/bin/env python3
"""Capture an idea in a vim popup and write it to stdout."""

# /// script
# dependencies = [
#   "libtmux",
# ]
# ///

import os
import sys
import tempfile
import subprocess
from pathlib import Path

sys.path.insert(0, os.path.dirname(__file__))
from capture_utils import tmux_display  # noqa: E402


def open_editor(path: str) -> int:
    editor = os.environ.get("EDITOR", "vim")
    with open("/dev/tty", "r+") as tty:
        return subprocess.run(
            [editor, path],
            stdin=tty,
            stdout=tty,
            check=False,
        ).returncode


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
