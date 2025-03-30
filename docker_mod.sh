#!/usr/bin/env bash
# shellcheck disable=SC2034

#########################################################################################################################
#### Make sure all volumes are mounted
if [[ -n "$container" || "$INCONTAINER" == "true" ]]; then
  [[ "$DEBUG" == "true" ]] && echo "### DEBUG Container detected"
  echo ">>> Container variables auto settings"

  mounts=(/audible_dl /audiobooks_dest /root/.audible)
  for dir in "${mounts[@]}"; do
    grep -q "$dir" /proc/mounts || { echo "=== ERROR: Missing '$dir'"; exit 2; }
  done

  unset DOWNLOAD_DIR
  unset DEST_BASE_DIR
  unset DEBUG_USEAAXSAMPLE
  unset DEBUG_USEAAXCSAMPLE

  declare -r DOWNLOAD_DIR="/audible_dl"
  declare -r DEST_BASE_DIR="/audiobooks_dest"
  declare -r DEBUG_USEAAXSAMPLE="sample.aax"
  declare -r DEBUG_USEAAXCSAMPLE="sample.aaxc"

  METADATA_TIKA=/BALD/tika-app-2.9.2.jar
else
  [[ "$DEBUG" == "true" ]] && echo "### DEBUG Not in container"
fi
