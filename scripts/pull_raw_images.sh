#!/bin/bash
set -euo pipefail

PLAYLIST="$1"
COUNT="$2"
SESSION_DIR="$3"
DEST="${SESSION_DIR}/assets/images"
REMOTE_RAW_IMAGE="cafe-asil:Asil-Records/cafe-asil/raw_videos/${PLAYLIST}"

# Ensure the remote destination directory exists
rclone mkdir "$DEST"
echo "✅ Ensured remote directory $DEST exists."

# Get the first file from the sorted list
FIRST_FILE=$(rclone lsf "$REMOTE_RAW_IMAGE" --files-only | sort -V | head -n 1)
echo "FIRST_FILE=$FIRST_FILE"

# Extract the base pattern (everything up to the second underscore and append _*)
BASE_PATTERN=$(echo "$FIRST_FILE" | sed -E 's/^(([^_]+_){2})[^_]+(\.[a-zA-Z0-9]+)$/\1*/')
echo "BASE_PATTERN=$BASE_PATTERN"

# List all files matching the pattern
FILES=$(rclone lsf "$REMOTE_RAW_IMAGE" --files-only | grep -E "^${BASE_PATTERN//\*/.*}$")

# Debugging: Print the files being selected
echo "FILES=$FILES"

if [ -z "$FILES" ]; then
  echo "⚠️ No image files found in $REMOTE_RAW_IMAGE"
  exit 1
fi

# Copy the selected files locally first
echo "$FILES" | while IFS= read -r f; do
  # Trim whitespace and ensure the file name is clean
  f=$(echo "$f" | xargs)
  echo "Copying: $f to local session_audio directory"
  rclone --transfers=5 copy "$REMOTE_RAW_IMAGE/$f" ./session_image --include "*.mp4" --progress
done

# Move the copied files to the destination
echo "$FILES" | while IFS= read -r f; do
  # Trim whitespace and ensure the file name is clean
  f=$(echo "$f" | xargs)
  echo "Moving: $f to $DEST"
  rclone copy --transfers=5 "./session_image/$f" "$DEST/"
done