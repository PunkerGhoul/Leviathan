#!/bin/bash

# Script to set cursor theme reliably in Hyprland
# This ensures the cursor is set even if the initial exec-once fails

# Wait for Hyprland to be fully loaded
sleep 2

# Set cursor theme multiple times to ensure it sticks
hyprctl setcursor Adwaita 24
sleep 1
hyprctl setcursor Adwaita 24

# Log the result
echo "Cursor theme set to Adwaita" >> /tmp/hypr-cursor.log
