#!/usr/bin/env zsh
# install-heic-to-png.sh
# Compiles heic-to-png.applescript, symlinks it into Folder Action Scripts,
# and attaches it to ~/Downloads via macOS Folder Actions.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FOLDER_ACTIONS_DIR="$HOME/Library/Scripts/Folder Action Scripts"
SCPT="$SCRIPT_DIR/heic-to-png.scpt"
SCPT_LINK="$FOLDER_ACTIONS_DIR/heic-to-png.scpt"
DOWNLOADS="$HOME/Downloads"

echo "Compiling heic-to-png.applescript..."
osacompile -o "$SCPT" "$SCRIPT_DIR/heic-to-png.applescript"

echo "Symlinking into Folder Action Scripts..."
mkdir -p "$FOLDER_ACTIONS_DIR"
ln -sf "$SCPT" "$SCPT_LINK"

echo "Attaching Folder Action to $DOWNLOADS..."
osascript <<OSASCRIPT
tell application "System Events"
    set folder actions enabled to true
    set scriptPath to (POSIX file "$SCPT_LINK") as text

    -- Create folder action for Downloads if it doesn't exist
    set faExists to false
    repeat with fa in folder actions
        if path of fa is "$DOWNLOADS" then
            set faExists to true
            exit repeat
        end if
    end repeat
    if not faExists then
        make new folder action at end of folder actions with properties {name:"$DOWNLOADS", path:"$DOWNLOADS"}
    end if

    -- Attach script if not already attached
    set targetFA to missing value
    repeat with fa in folder actions
        if path of fa is "$DOWNLOADS" then
            set targetFA to fa
            exit repeat
        end if
    end repeat

    tell targetFA
        set alreadyAttached to false
        repeat with s in scripts
            if name of s is "heic-to-png.scpt" then
                set alreadyAttached to true
                exit repeat
            end if
        end repeat
        if not alreadyAttached then
            make new script at end of scripts with properties {name:"heic-to-png.scpt", path:scriptPath}
        end if
        set enabled to true
    end tell
end tell
OSASCRIPT

echo "Done. HEIC files dropped into ~/Downloads will be auto-converted to PNG."
