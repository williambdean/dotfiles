# scripts/

macOS automation scripts. Each automation has an AppleScript source file and a shell installer.

## heic-to-png

Automatically converts HEIC files to PNG when dropped into `~/Downloads`. The original HEIC is deleted after successful conversion.

**Files:**
- `heic-to-png.applescript` — source (version controlled)
- `heic-to-png.scpt` — compiled binary (generated, not version controlled)
- `install-heic-to-png.sh` — compiles the script, symlinks it, and attaches the Folder Action

**Requirements:** ImageMagick (`brew install imagemagick`)

**Install:**
```bash
bash scripts/install-heic-to-png.sh
```

This is also called automatically by `setup.sh`.
