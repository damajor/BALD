#!/usr/bin/env bash
# shellcheck disable=SC2034

#########################################################################################################################
#### Make sure all volumes are mounted
if [[ -n "$container" || "$INCONTAINER" == "true" ]]; then
  [[ "$DEBUG" == "true" ]] && echo "### DEBUG Container detected"
  echo ">>> Container variables auto settings"

  mounts=(/audible_history /status_file /audible_dl /audiobooks_dest /BALD/myconfig /BALD/tmp /BALD/personal_library.tsv /root/.audible)
  for dir in "${mounts[@]}"; do
    grep -q "$dir" /proc/mounts || { echo "=== ERROR: Missing '$dir'"; exit 2; }
  done

  unset HIST_LIB_DIR
  unset STATUS_FILE
  unset DOWNLOAD_DIR
  unset DEST_BASE_DIR
  unset DEBUG_USEAAXSAMPLE
  unset DEBUG_USEAAXCSAMPLE
  unset LOCAL_DB

  declare -r HIST_LIB_DIR="/audible_history"
  declare -r STATUS_FILE="/status_file"
  declare -r DOWNLOAD_DIR="/audible_dl"
  declare -r DEST_BASE_DIR="/audiobooks_dest"
  declare -r DEBUG_USEAAXSAMPLE="sample.aax"
  declare -r DEBUG_USEAAXCSAMPLE="sample.aaxc"
  declare -r LOCAL_DB="/BALD/personal_library.tsv"

  METADATA_TIKA=/BALD/tika-app-2.9.3.jar
  FFMPEG_STATS=-nostats
  PARALLEL_PROGRESS=
else
  [[ "$DEBUG" == "true" ]] && echo "### DEBUG: Not in container"
  FFMPEG_STATS=-stats
  PARALLEL_PROGRESS=--bar
fi
