#!/bin/bash
set -euo pipefail

PLAYLIST="$1"
COUNT="$2"
DEST="$3"
REMOTE_RAW_AUDIO="cafe-asil:Asil-Records/cafe-asil/raw_audios/${PLAYLIST}"

mkdir -p "$DEST"#!/bin/bash
set -euo pipefail

PLAYLIST="$1"
COUNT="$2"
SESSION_DIR="$3"
DEST="${SESSION_DIR}/assets/audios"
REMOTE_RAW_AUDIO="cafe-asil:Asil-Records/cafe-asil/raw_audios/${PLAYLIST}"

# Ensure the remote destination directory exists
rclone mkdir "$DEST"

FILES=$(rclone lsf "$REMOTE_RAW_AUDIO" --files-only | shuf | head -n "$COUNT")
if [ -z "$FILES" ]; then
  echo "⚠️ No audio files found in $REMOTE_RAW_AUDIO"
  exit 1
fi

for f in $FILES; do
  echo "Copying: $f to $DEST"
  rclone copy "$REMOTE_RAW_AUDIO/$f" "$DEST/"
done

echo "✅ Copied $COUNT audio files to $DEST"

FILES=$(rclone lsf "$REMOTE_RAW_AUDIO" --files-only | shuf | head -n "$COUNT")
if [ -z "$FILES" ]; then
  echo "⚠️ No audio files found in $REMOTE_RAW_AUDIO"
  exit 1
fi

for f in $FILES; do
  echo "Downloading: $f"
  rclone copy "$REMOTE_RAW_AUDIO/$f" "$DEST/"
done

echo "✅ Pulled $COUNT audio files to $DEST"