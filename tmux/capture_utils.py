"""Shared utilities for capture-*.py scripts."""

import libtmux


def tmux_display(message: str) -> None:
    server = libtmux.Server()
    server.cmd("display-message", message)


def tmux_session() -> str:
    server = libtmux.Server()
    result = server.cmd("display-message", "-p", "#S")
    return result.stdout[0].strip() if result.stdout else "(unknown)"


def parse_idea(raw: str) -> tuple[str, list[str]] | None:
    """Parse raw text into (title, body_lines).

    First non-empty line is the title. Remaining lines (after stripping
    leading blanks) are the body.
    """
    if not raw.strip():
        return None

    lines = raw.splitlines()
    while lines and not lines[0].strip():
        lines.pop(0)
    while lines and not lines[-1].strip():
        lines.pop()
    if not lines:
        return None

    title = lines[0].strip()
    body_lines = lines[1:]
    while body_lines and not body_lines[0].strip():
        body_lines.pop(0)

    return title, body_lines
