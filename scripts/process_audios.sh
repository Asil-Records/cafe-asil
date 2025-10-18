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
FILES=$(rclone lsf "$REMOTE_RAW_AUDIO" --files-only --fast-list --include "*.mp3" | shuf | head -n "$COUNT")

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
  if ! rclone copy --transfers=5 "./session_audio/$f" "$DEST/"; then
      echo "⚠️ Failed to copy $f to $DEST"
      exit 1
  fi
done

echo "✅ Copied $COUNT audio files to $DEST"

# Merge the audio files using FFmpeg
echo "🎵 Creating FFmpeg file list..."
find ./session_audio -type f -name "*.mp3" | sort | while read f; do
    echo "file '$f'" >> mp3_file_list.txt
done

if [ ! -s mp3_file_list.txt ]; then
    echo "No MP3 files found — aborting merge."
    exit 1
fi

echo "- Found $(wc -l < mp3_file_list.txt) tracks for merging." >> $GITHUB_STEP_SUMMARY

echo "Merging MP3s into one file..."
ffmpeg -f concat -safe 0 -i mp3_file_list.txt -c copy merged_output.mp3 -y || { echo "FFmpeg merge failed"; exit 1; }
echo "Merge completed successfully!"
echo "- Audio merge completed successfully!" >> $GITHUB_STEP_SUMMARY 
echo "Uploading merged_output.mp3 to drive..."
rclone copy merged_output.mp3 "${SESSION_DIR}/merged" --drive-chunk-size=256M --transfers=1 --checkers=4
echo "Successfully uploaded merged_output.mp3 to drive."

# Delete the copied files to the destination
echo "$FILES" | while IFS= read -r f; do
  # Trim whitespace and ensure the file name is clean
  f=$(echo "$f" | xargs)
  echo "Deleting: $f from $REMOTE_RAW_AUDIO"
  rclone delete "$REMOTE_RAW_AUDIO/$f"
done

echo "✅ Processed $COUNT audio files and cleared them from $REMOTE_RAW_AUDIO"