---
name: uv-scripts
description: >
  Run one-off Python scripts with inline dependencies using uv and PEP 723 (`/// script`)
  metadata. Covers inline metadata format, specifying Python version and dependencies,
  running with `uv run`, and using `--with` for throwaway/trial scripts.
---

# uv Scripts (PEP 723 Inline Metadata)

Use `uv` to run single-file Python scripts with embedded dependency metadata — no
`pyproject.toml`, no virtual env setup, no pip install.

## PEP 723 Format

The [PEP 723](https://peps.python.org/pep-0723/) inline metadata standard. Add a `# /// script` comment block at the top of your script:

```python
# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "numpy",
#   "pytensor",
#   "pymc",
# ]
# ///
```

The block is standard TOML. Supported fields:

| Field            | Description                                |
| ---------------- | ------------------------------------------ |
| `requires-python` | Python version constraint (PEP 440)        |
| `dependencies`    | List of PEP 508 dependency strings         |
| `[tool]`          | Tool-specific config (e.g. `[tool.uv]`)    |

## Running

```bash
uv run script.py
uv run script.py -- --arg value     # pass args to script
```

`uv` creates an isolated ephemeral environment, installs dependencies, and runs the
script. No cleanup needed.

## `--with` for Throwaway / Trial Scripts

Use `--with` when you're trialing a library and don't want to modify the script:

```bash
uv run --with numpy --with pytensor --with pymc script.py
```

This injects dependencies *at runtime* without touching the file. The script stays
clean — no metadata block needed at all.

### Tradeoff: Inline vs `--with`

| Approach   | When to use                                                                 |
| ---------- | --------------------------------------------------------------------------- |
| Inline     | Script is shared, committed, or re-run later. Reproducible.                 |
| `--with`   | Quick trial, throwaway exploration, or when you'd otherwise `pip install` first. |

Rule of thumb: If you'd save the script, use inline metadata. If you'd delete it
after one run, use `--with`.

## `uvx` for One-Liners

For truly ephemeral scripts (or running from a URL):

```bash
uvx --with numpy --with pytensor script.py
```

`uvx` is shorthand that can also run scripts directly from URLs or gists:

```bash
uvx https://gist.github.com/user/abc123/raw/script.py
```

## Real Examples (this repo)

The `tmux/` directory uses PEP 723 scripts:

- `tmux/capture-idea.py` — `# dependencies = ["libtmux"]`
- `tmux/capture-post.py` — `# dependencies = ["libtmux"]`
- `tmux/capture-gh-issue.py` — `# dependencies = ["libtmux"]`

They're invoked via `tmux.conf`:

```bash
uv run $DOTFILES/tmux/capture-idea.py | uv run $DOTFILES/tmux/capture-post.py
```

## Full Example

```python
#!/usr/bin/env python3
"""Compute with PyTensor and PyMC."""

# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "numpy<2",
#   "pytensor",
#   "pymc",
# ]
# ///

import numpy as np
import pytensor.tensor as pt
import pymc as pm

# ... your script logic ...

if __name__ == "__main__":
    print("Done!")
```

The `#!/usr/bin/env python3` shebang is optional — `uv run` ignores it and uses its own
Python. Include it if you also want to run the script directly (`./script.py`) without
uv, or if you're sharing it outside a uv context.
