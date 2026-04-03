#!/usr/bin/env sh
pkill -x ironbar >/dev/null 2>&1 || true
exec ironbar
