#!/usr/bin/env bash
set -euo pipefail

if command -v pwsh >/dev/null 2>&1; then
    powershell_command=pwsh
elif command -v pwsh.exe >/dev/null 2>&1; then
    powershell_command=pwsh.exe
elif command -v powershell.exe >/dev/null 2>&1; then
    powershell_command=powershell.exe
else
    echo "PowerShell 7 is required to build this mod." >&2
    exit 1
fi

exec "$powershell_command" -NoProfile -File "$(dirname "$0")/build.ps1" "$@"
