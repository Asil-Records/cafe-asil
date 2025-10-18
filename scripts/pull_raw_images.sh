#!/bin/bash
set -euo pipefail

PLAYLIST="$1"
COUNT="$2"
SESSION_DIR="$3"
DEST="${SESSION_DIR}/assets/images"
REMOTE_RAW_IMAGE="cafe-asil:Asil-Records/cafe-asil/raw_images/${PLAYLIST}"

# Ensure the remote destination directory exists
rclone mkdir -p "$DEST"
echo "✅ Ensured remote directory $DEST exists."

# Get the first file from the shuffled list
FIRST_FILE=$(rclone lsf "$REMOTE_RAW_AUDIO" --files-only --fast-list | sort | head -n 1)

# Extract the base pattern (everything before the last underscore and extension)
BASE_PATTERN=$(echo "$FIRST_FILE" | sed -E 's/_[^_]+(\.[a-zA-Z0-9]+)$/*\1/')

# List all files matching the pattern
FILES=$(rclone lsf "$REMOTE_RAW_AUDIO" --files-only --fast-list | grep "^$BASE_PATTERN$")

# Debugging: Print the files being selected
echo "FILES=$FILES"

if [ -z "$FILES" ]; then
  echo "⚠️ No image files found in $REMOTE_RAW_IMAGE"
  exit 1
fi

# Loop through files and copy them
echo "$FILES" | while IFS= read -r f; do
  # Trim whitespace and ensure the file name is clean
  f=$(echo "$f" | xargs)
  echo "Copying: $f to $DEST"
  rclone move --transfers=5 "$REMOTE_RAW_IMAGE/$f" "$DEST/"
done