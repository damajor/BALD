#!/usr/bin/env bash

# MIT License
# Copyright (c) [2025] [damajor @ <https://github.com/damajor/BALD>]

# This script extract sampling rate from mediainfo.json file
# Then it takes all chapters information from Audible chapters.json file
# All basic metadata are taken from source ffmpef metadata file
# And rewrite the basic metadata+chapters+titles in the dest ffmpeg metadata file

# $1 source chapters.json
# $2 source mediainfo.json
# $3 source ffmetadata
# $4 dest ffmetadata

if [[ ! -f "$1" || ! -f "$2" || ! -f "$3" ]]; then
  echo "### ERROR: One or more file are missing, or one or more argument is missing"
  exit 1
fi

if [[ -z "$4" ]]; then
  echo "### ERROR: Destination file missing"
  ecit 1
fi

chapters=$(jq -r '.content_metadata.chapter_info.chapters' "${1}")
chapters_num=$(jq -r '.content_metadata.chapter_info.chapters | length' "${1}")
sample_rate=$(jq -r '.media.track[] | select(."@type" == "Audio") | .SamplingRate' "${2}")

if [[ -z "$chapters_num" || -z "$chapters" ]]; then
  echo "### ERROR: Chapters not found in '$1'"
  exit 1
fi

if [[ -z "$sample_rate" ]]; then
  echo "### ERROR: Sampling rate not found in '$2'"
  exit 1
fi

base_metadata=$(sed -n '/;FFMETADATA1/,/\[CHAPTER\]/{/\[CHAPTER\]/b;p}' "${3}")

dest_chapters=$(
  idx=0
  while [ "$idx" -lt "$chapters_num" ]; do
    start_offset_ms=$(echo "$chapters" | jq -r ".[$idx].start_offset_ms")
    length_ms=$(echo "$chapters" | jq -r ".[$idx].length_ms")
    title=$(echo "$chapters" | jq -r ".[$idx].title")
    start=$((start_offset_ms * sample_rate / 1000))
    end=$(((start_offset_ms + length_ms) * sample_rate / 1000))
    echo "[CHAPTER]"
    echo "TIMEBASE=1/${sample_rate}"
    echo "START=$start"
    echo "END=$end"
    echo "title=$title"
    idx=$((idx + 1))
  done
)

{
  echo "$base_metadata"
  echo "$dest_chapters"
} > "${4}"
