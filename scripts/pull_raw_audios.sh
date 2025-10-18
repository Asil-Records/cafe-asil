#!/bin/bash
set -euo pipefail

PLAYLIST="$1"
COUNT="$2"
SESSION_DIR="$3"
DEST="${SESSION_DIR}/assets/audios"
REMOTE_RAW_AUDIO="cafe-asil:Asil-Records/cafe-asil/raw_audios/${PLAYLIST}"

# Ensure the remote destination directory exists
rclone mkdir -p "$DEST"
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

# Loop through files and copy them
echo "$FILES" | while IFS= read -r f; do
  # Trim whitespace and ensure the file name is clean
  f=$(echo "$f" | xargs)
  echo "Copying: $f to $DEST"
  rclone move --transfers=5 "$REMOTE_RAW_AUDIO/$f" "$DEST/"
done

echo "✅ Copied $COUNT audio files to $DEST"