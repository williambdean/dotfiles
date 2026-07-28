---
name: headless-kernel
description: >
  A SLIME-like workflow for interacting with persistent Python kernels via ZMQ.
  Agnostic of terminal multiplexers (works with herdr, tmux, zellij, or raw shells).
---

# Headless Kernel (Agnostic)

## Overview

**New to the headless kernel? See `examples.md` for two full worked
walkthroughs (Asheville tree analysis + Marvel movie box office).**

The Headless Kernel allows you to:
1. Start one or more persistent Python kernels in the background.
2. Inject code or entire files into a specific kernel from any terminal.
3. Synchronize state with "Visible REPLs" (like `jupyter console` or `ipython`).
4. Leverage UNIX properties (piping, standard streams) for workflow automation.

## Locate the Harness

Locate the harness and alias it for easy access:

```bash
HARNESS=$(find . -name harness.py -path "*/headless-kernel/*" 2>/dev/null | head -1)
```

Or use the script directly from its known location relative to the dotfiles root:

```bash
HARNESS=skills/headless-kernel/scripts/harness.py
```

Then use `$HARNESS` in all commands below. To verify: `uv run $HARNESS path`.

## Usage

### 1. Start a Kernel
Launch a kernel session. Connection files and temp artifacts live in `/tmp/harness/<project-dir>/` — no project root pollution.

#### Option A: Managed (tmux)
```bash
tmux new-window -d -n kernel-alpha
tmux send-keys -t kernel-alpha "uv run $HARNESS --session alpha start --repl" C-m
```

#### Option B: Manual (herdr or raw)
```bash
uv run $HARNESS start &
```

#### Restarting (--force)
If a connection file already exists (e.g. from a crashed session), `start` will refuse. Pass `--force` to automatically stop the existing session and restart:
```bash
uv run $HARNESS --session alpha start --force
```

### 2. Connect a Visible REPL (SLIME Style)
```bash
# Attach to default
uv run $HARNESS console

# Or attach to a named session
uv run $HARNESS --session alpha console
```

### 3. Execute Code
```bash
# Execute a one-liner (fastest)
uv run $HARNESS exec "print(df.columns)"

# Pipe from stdin
echo "x = 10" | uv run $HARNESS exec -

# Send a file
uv run $HARNESS send my_analysis.py

# Send a code string (alternative syntax)
uv run $HARNESS send --code "print(df.columns)"

# Pipe from stdin (alternative syntax)
echo "x = 10" | uv run $HARNESS send -
```

#### Multi-line Code (Heredoc)

For multi-line Python, the heredoc pattern is the most reliable — it avoids shell escaping issues with `$`, backticks, and curly braces:

```bash
cat <<'PYEOF' | uv run $HARNESS send -
import matplotlib.pyplot as plt, os
import pandas as pd

df = pd.DataFrame({"x": [1, 2, 3], "y": [4, 5, 6]})
print(df.describe())

plt.plot(df["x"], df["y"])
plt.savefig(os.path.join(os.environ["HARNESS_TMP"], "plot.png"))
PYEOF
```

The quoted delimiter (`'PYEOF'`) prevents shell expansion of `$` inside the heredoc. This is the recommended pattern for any code containing `$`, backticks, or complex string literals.

#### Detached Mode
Submit code and return immediately — the kernel queues the work and runs it when free:
```bash
# Fire and forget
uv run $HARNESS exec -d "model.fit(X, y); model.save('$HARNESS_TMP/model.nc')"
uv run $HARNESS send -d long_training_script.py
```

Useful for kicking off a long model fit, then switching to another session:
```bash
uv run $HARNESS --session alpha exec -d "model.sample(2000)"
uv run $HARNESS --session beta exec "data.groupby('region').sum()"
uv run $HARNESS --session alpha exec "print('alpha is done, checking results')"   # blocks until free
```

*Note: detached output isn't streamed to the terminal. Write results to `$HARNESS_TMP/` and check them later.*

For long-running detached jobs, use a sentinel file pattern to poll for completion:
```bash
# Submit a long job that writes a sentinel when done
cat <<'PYEOF' | uv run $HARNESS send -d -
import os, pickle
result = model.sample(2000)
pickle.dump(result, open(os.environ["HARNESS_TMP"] + "/result.pkl", "wb"))
open(os.environ["HARNESS_TMP"] + "/done.flag", "w").close()
PYEOF

# Poll for completion (from another terminal or after other work)
while [ ! -f "$(uv run $HARNESS exec "import os; print(os.environ['HARNESS_TMP'])" 2>/dev/null)/done.flag" ]; do sleep 5; done
echo "Job complete!"
```

### 4. Session Management

```bash
# List active sessions (shows alive/dead status)
uv run $HARNESS ps

# Stop a session
uv run $HARNESS --session alpha stop
```

Check if a session is still alive before executing:
```bash
uv run $HARNESS ps | grep alpha
```

### 5. Multi-Session Support
```bash
uv run $HARNESS --session model_a send train.py
uv run $HARNESS --session model_b send train.py
```

### 6. Plotting (Clean Root)
Background kernels lack a display buffer. Kernel init sets `$HARNESS_TMP` to `/tmp/harness/<project-dir>/`:

```bash
cat <<'PYEOF' | uv run $HARNESS send -
import matplotlib.pyplot as plt, os
plt.plot([1, 2, 3], [4, 5, 6])
plt.savefig(os.path.join(os.environ["HARNESS_TMP"], "plot.png"))
print(os.path.join(os.environ["HARNESS_TMP"], "plot.png"))
PYEOF

# macOS (use the printed path from above)
open /tmp/harness/dotfiles/plot.png
# Linux: xdg-open /tmp/harness/dotfiles/plot.png
```

### 7. Cleanup
Always stop kernels when done to free resources:

```bash
# Stop default session
uv run $HARNESS stop

# Stop a named session
uv run $HARNESS --session alpha stop

# List any lingering sessions first
uv run $HARNESS ps
```

## UNIX Properties
- **Exit Codes**: Returns `0` on success, `1` if the kernel encounters an exception.
- **Streams**: Pipes kernel `stdout` and `stderr` directly to your local terminal.
- **Pipes**: Fully supports `stdin` via the `-` argument.

## Best Practices
- **Autoreload**: Sessions start with `%load_ext autoreload` and `%autoreload 2`.
- **Overwrite Pattern**: Sending a file overwrites existing variables. Use this to update your model or data without losing expensive objects already in memory.
- **Status Summary**: After starting or updating a kernel, always provide a "Useful Commands" block.
- **Avoid `$` in `exec`**: Shell interprets `$` in `exec "..."` strings, causing breakage (e.g., `exec "print(f'${x}')"`). Use the heredoc pattern (`cat <<'PYEOF' | uv run $HARNESS send -`) for any code containing `$`, backticks, or curly braces.
- **State Persistence**: The kernel holds variables across calls indefinitely. For expensive objects (large DataFrames, fitted models), save them between sessions:
  ```bash
  uv run $HARNESS exec "df.to_pickle(os.path.join(os.environ['HARNESS_TMP'], 'data.pkl'))"
  # Next session:
  uv run $HARNESS exec "df = pd.read_pickle(os.path.join(os.environ['HARNESS_TMP'], 'data.pkl'))"
  ```
- **Cleanup**: Kernels are persistent processes. Run `uv run $HARNESS stop` when done, or `uv run $HARNESS ps` to check for orphaned sessions.

Example:
```bash
# Quick inspect
uv run $HARNESS exec "print(df.info())"

# Connect Interactive Console
uv run $HARNESS --session <name> console

# Stop Kernel
uv run $HARNESS --session <name> stop
```

## Troubleshooting

### Connection file already exists
```bash
# Use --force to restart
uv run $HARNESS start --force

# Or manually clean up
rm -rf /tmp/harness/$(basename $(pwd))
```

### "Too many open files" ZMQ errors
This can occur after many rapid `exec`/`send` calls due to lingering ZMQ socket threads. The harness now adds a cleanup delay and garbage collection after each command. If it persists, insert a brief pause between commands:
```bash
uv run $HARNESS exec "print('hello')"
sleep 0.2
uv run $HARNESS exec "print('world')"
```

### Kernel not responding
```bash
# Check if session is alive
uv run $HARNESS ps

# If marked "dead", restart with --force
uv run $HARNESS start --force
```
