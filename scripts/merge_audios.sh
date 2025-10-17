#!/bin/bash
set -euo pipefail

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