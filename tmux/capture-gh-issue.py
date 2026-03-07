#!/usr/bin/env python3
"""Read a captured idea from stdin and create a GitHub issue."""

# /// script
# dependencies = [
#   "libtmux",
# ]
# ///

import argparse
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(__file__))
from capture_utils import parse_idea, tmux_display  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(description="Create a GitHub issue from stdin.")
    parser.add_argument("--repo", "-R", help="Target repo (OWNER/REPO)")
    args = parser.parse_args()

    raw = sys.stdin.read()
    parsed = parse_idea(raw)
    if not parsed:
        tmux_display("GitHub issue: nothing to create.")
        return 1
    title, body_lines = parsed
    body = "\n".join(body_lines)

    cmd = ["gh", "issue", "create", "--title", title, "--body", body]
    if args.repo:
        cmd += ["--repo", args.repo]
    return subprocess.run(cmd, check=False).returncode


if __name__ == "__main__":
    sys.exit(main())
