#!/bin/bash
set -euo pipefail

PLAYLIST="$1"
COUNT="$2"
SESSION_DIR="$3"
DEST="${SESSION_DIR}/assets/audios"
REMOTE_RAW_AUDIO="cafe-asil:Asil-Records/cafe-asil/raw_audios/${PLAYLIST}"

# Ensure the remote destination directory exists
rclone mkdir "$DEST"
echo "✅ Ensured remote directory $DEST exists."

# Debugging: Print the remote raw audio path
echo "REMOTE_RAW_AUDIO=$REMOTE_RAW_AUDIO"
echo "DEST=$DEST"

# List files, shuffle, and select the requested count
FILES=$(rclone lsf "$REMOTE_RAW_AUDIO" --files-only --fast-list | shuf | head -n "$COUNT")

# Debugging: Print the files being selected
echo "FILES=$FILES"

if [ -z "$FILES" ]; then
  echo "⚠️ No audio files found in $REMOTE_RAW_AUDIO"
  exit 1
fi

# Copy the selected files locally first
echo "$FILES" | while IFS= read -r f; do
  # Trim whitespace and ensure the file name is clean
  f=$(echo "$f" | xargs)
  echo "Copying: $f to local session_audio directory"
  rclone --transfers=5 copy "$REMOTE_RAW_AUDIO/$f" ./session_audio --include "*.mp3" --progress
done

# Move the copied files to the destination
echo "$FILES" | while IFS= read -r f; do
  # Trim whitespace and ensure the file name is clean
  f=$(echo "$f" | xargs)
  echo "Moving: $f to $DEST"
  rclone copy --transfers=5 "./session_audio/$f" "$DEST/"
done

echo "✅ Copied $COUNT audio files to $DEST"