#!/bin/bash
set -euo pipefail

PLAYLIST_NAME="$1"
SESSION_DATE="$2"
SESSION_DIR="$3"
DEST="${SESSION_DIR}/merged"
FINAL_MP4_FILE="rendered-${PLAYLIST_NAME}-${SESSION_DATE}.mp4"

echo "Merging mp4 and mp3 into final_output.mp4..."

# Ensure both files exist
if [ ! -f merged_video.mp4 ]; then
echo "merged_video.mp4 not found!"
exit 1
fi

if [ ! -f merged_output.mp3 ]; then
echo "merged_output.mp3 not found!"
exit 1
fi

# Merge audio and video
ffmpeg -stream_loop -1 -i merged_video.mp4 -i merged_output.mp3 \
-shortest -c:v libx264 -c:a aac -pix_fmt yuv420p final_output.mp4 -y

echo "✅ Final video created successfully at final_output.mp4"
echo "- Merged final_output.mp4 successfully." >> $GITHUB_STEP_SUMMARY

echo "Uploading final version to Drive..."
rclone copy final_output.mp4 "${SESSION_DIR}/merged/${FINAL_MP4_FILE}" --drive-chunk-size=256M --transfers=1 --checkers=4
echo "Finished video uploaded successfully."
echo "Finished video ${FINAL_MP4_FILE} uploaded successfully." >> $GITHUB_STEP_SUMMARY