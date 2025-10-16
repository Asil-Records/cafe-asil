#!/bin/bash
set -euo pipefail

# Arguments
REMOTE_SESSION_BASE_DIR="$1"
REMOTE_SESSION_BASE="$2"

echo "🔍 Checking existing session folders on Drive..."
EXISTING_JSON=$(rclone lsjson "$REMOTE_SESSION_BASE" || echo "[]")
echo "---- EXISTING FOLDERS ----"
echo "$EXISTING_JSON"
echo "---------------------------"

# Convert JSON to bash array (lowercase)
REMOTE_NAMES=($(echo "$EXISTING_JSON" | jq -r '.[].Name | ascii_downcase'))

exists_in_remote() {
    REL_NAME="${1##*:}"
    REL_NAME="${REL_NAME##*/}"
    REL_NAME=$(echo "$REL_NAME" | tr '[:upper:]' '[:lower:]')
    for name in "${REMOTE_NAMES[@]}"; do
        if [[ "$name" == "$REL_NAME" ]]; then
            return 0
        fi
    done
    return 1
}

FINAL_REMOTE_DIR="$REMOTE_SESSION_BASE_DIR"
COUNTER=1
while exists_in_remote "$FINAL_REMOTE_DIR"; do
    FINAL_REMOTE_DIR="${REMOTE_SESSION_BASE_DIR}_${COUNTER}"
    COUNTER=$((COUNTER+1))
done

echo "SESSION_DIR=$FINAL_REMOTE_DIR" >> $GITHUB_ENV
echo "✅ Session folder: $FINAL_REMOTE_DIR"