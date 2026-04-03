#!/usr/bin/env sh
pkill -x qs >/dev/null 2>&1 || true
pkill -x quickshell >/dev/null 2>&1 || true
exec qs -p "$HOME/.config/quickshell/shell.qml"
