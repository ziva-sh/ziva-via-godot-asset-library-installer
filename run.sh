#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export ZIVA_INSTALLER_TEST_API=1

# Kill any process on port 8099
if [[ "$(uname -s)" == MINGW* ]] || [[ "$(uname -s)" == MSYS* ]]; then
    for pid in $(netstat -ano 2>/dev/null | grep ':8099 ' | grep LISTENING | awk '{print $5}' | sort -u); do
        taskkill //F //PID "$pid" 2>/dev/null || true
    done
else
    fuser -k 8099/tcp 2>/dev/null || true
fi

mkdir -p /tmp/ziva-installer-logs
echo "Starting Godot editor with Ziva Installer plugin..."
echo "Logs: /tmp/ziva-installer-logs/godot.log"
godot -e --path "$SCRIPT_DIR" > /tmp/ziva-installer-logs/godot.log 2>&1
