#!/bin/bash
set -euo pipefail

PLAYLIST="$1"
SESSION_DIR="$2"
DEST="${SESSION_DIR}/assets/images"
REMOTE_RAW_IMAGE="cafe-asil:Asil-Records/asils-lofi-world/raw_videos/${PLAYLIST}"

# Ensure the remote destination directory exists
rclone mkdir "$DEST"
echo "✅ Ensured remote directory $DEST exists."

# Get the first file from the sorted list
FIRST_FILE=$(rclone lsf "$REMOTE_RAW_IMAGE" --files-only | LC_ALL=C sort | head -n 1)
echo "FIRST_FILE=$FIRST_FILE"

# Extract the base pattern (everything up to the second underscore and append _*)
BASE_PATTERN=$(echo "$FIRST_FILE" | sed -E 's/^(([^_]+_){2})[^_]+(\.[a-zA-Z0-9]+)$/\1/')
echo "BASE_PATTERN=$BASE_PATTERN"

# List all files matching the pattern
FILES=$(rclone lsf "$REMOTE_RAW_IMAGE" --files-only | grep -E "^${BASE_PATTERN}[0-9]+\.png$")

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
  rclone --transfers=5 copy "$REMOTE_RAW_IMAGE/$f" ./session_image --include "*.png" --progress
done

# Move the copied files to the destination
echo "$FILES" | while IFS= read -r f; do
  # Trim whitespace and ensure the file name is clean
  f=$(echo "$f" | xargs)
  echo "Moving: $f to $DEST"
  rclone copy --transfers=5 "./session_image/$f" "$DEST/"
done

# ## Merge the MP4 files using FFmpeg
# echo "Merging MP4s into one file..."
# # Create file list for ffmpeg
# find "./session_image" -maxdepth 1 -type f -name "*.png" | sort | while read f; do
#   echo "file '$f'" >> image_file_list.txt
# done

# echo "File list for ffmpeg:"
# cat image_file_list.txt

# if [ ! -s image_file_list.txt ]; then
#   echo "No png files found — aborting merge."
#   exit 1
# fi

# echo "- Found $(wc -l < image_file_list.txt) tracks for merging." >> $GITHUB_STEP_SUMMARY

echo "Merging MP4s into one file..."
ffmpeg -loop 1 -i "./session_image/$FILES" -t 60 -c:v libx264 -r 30 -pix_fmt yuv420p merged_video.mp4 || { echo "FFmpeg merge failed"; exit 1; }
echo "Merge completed successfully!"
echo "- Video merge completed successfully!" >> $GITHUB_STEP_SUMMARY

echo "Uploading merged_video.mp4 to drive..."
rclone copy merged_video.mp4 "${SESSION_DIR}/merged" --drive-chunk-size=256M --transfers=1 --checkers=4
echo "Successfully uploaded merged_video.mp4 to drive."

# Delete the copied files to the destination
echo "$FILES" | while IFS= read -r f; do
  # Trim whitespace and ensure the file name is clean
  f=$(echo "$f" | xargs)
  echo "Deleting: $f from $REMOTE_RAW_IMAGE"
  rclone delete "$REMOTE_RAW_IMAGE/$f"
done

echo "✅ Processed image files and cleared them from $REMOTE_RAW_IMAGE"