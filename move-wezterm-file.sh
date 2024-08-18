# Was not able to do the symbolic link for some reason, so this script will
# move or update the wezterm file to the correct location
local WEZTERM_FILE=.wezterm.lua
local WEZTERM_LOCATION=/mnt/c/Users/William/$WEZTERM_FILE

# if it exists, remove it
if [ -f $WEZTERM_LOCATION ]; then
	rm $WEZTERM_LOCATION
fi

# Copy the local file to that location
cp ./$WEZTERM_FILE $WEZTERM_LOCATION

echo "Copied $WEZTERM_FILE to $WEZTERM_LOCATION"
