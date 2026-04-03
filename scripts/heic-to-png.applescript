-- Folder Action: Auto-convert HEIC files to PNG on drop to Downloads
-- Attach this script to /Users/will/Downloads via Folder Actions Setup
-- Requires: ImageMagick (`magick`) at /opt/homebrew/bin/magick
--
-- Setup:
--   1. Copy/symlink heic-to-png.scpt to ~/Library/Scripts/Folder Action Scripts/
--   2. Right-click ~/Downloads in Finder > Services > Folder Actions Setup
--      (or run: osascript setup.sh equivalent)
--   3. Enable Folder Actions and attach this script to ~/Downloads

on adding folder items to this_folder after receiving added_items
    tell application "Finder"
        repeat with aFile in added_items
            try
                set fileName to name of aFile
                set ext to name extension of aFile

                log "Processing file: " & fileName & " (ext: " & ext & ")"

                if ext is "heic" or ext is "HEIC" then
                    set filePosix to POSIX path of (aFile as alias)
                    set pngPath to (text 1 thru -6 of filePosix) & ".png"

                    log "Converting: " & filePosix & " -> " & pngPath

                    do shell script "/opt/homebrew/bin/magick " & quoted form of filePosix & " " & quoted form of pngPath

                    -- Delete original HEIC after successful conversion
                    delete aFile

                    log "Conversion complete, original deleted."

                    -- Show notification
                    tell application "System Events"
                        display notification "Converted " & fileName & " to PNG" with title "HEIC to PNG"
                    end tell
                else
                    log "Skipping non-HEIC file: " & fileName
                end if
            on error errMsg
                log "Error processing " & fileName & ": " & errMsg
                tell application "System Events"
                    display notification "Error converting " & fileName & ": " & errMsg with title "HEIC to PNG"
                end tell
            end try
        end repeat
    end tell
end adding folder items to
