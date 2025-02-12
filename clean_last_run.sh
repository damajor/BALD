#!/usr/bin/env bash
#
# BALD: the Brand new Audible Library Downloader
#
# MIT License
# Copyright (c) [2025] [damajor @ <https://github.com/damajor/BALD>]
#
# Description:
#  This script will force removal of all transition files from the last run,
#  to ensure that no stale data is left behind.

#########################################################################################################################
#### Function of what trap command calls
function ctrl_c() {
    echo -e "\n*** Received CTRL-C - Interrupting script. ***\n"
    exit 1
}
trap ctrl_c INT
#########################################################################################################################
#### Source docker_mod.sh for container execution safety
SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
if [[ -f "$SCRIPT_DIR"/docker_mod.sh ]]; then
  [[ "$DEBUG" == "true" ]] && echo "### DEBUG Load docker_mod.sh for container compat."
  source "$SCRIPT_DIR"/docker_mod.sh
elif [[ -n "$container" || "$INCONTAINER" == "true" ]]; then
  echo "=== ERROR: Running in container without 'docker_mod.sh'"
  exit 1
fi
#########################################################################################################################
#### Load external config if any
if [[ -f "$SCRIPT_DIR"/myconfig ]]; then
  [[ "$DEBUG" == "true" ]] && echo "### DEBUG Load custom settings from external file."
  source "$SCRIPT_DIR"/myconfig 2>/dev/null
fi
#########################################################################################################################
#### Cleaning
last_modified_dl_dir=$(find "${DOWNLOAD_DIR}" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' | sort -k1,1nr | head -n 1 | cut -d ' ' -f 2)
if [[ -n "$last_modified_dl_dir" ]]; then
  echo ">>> Last modified directory: $last_modified_dl_dir"
  cd "$last_modified_dl_dir" || { echo "=== ERROR: Unable to change directory to $last_modified_dl_dir."; exit 1; }
  echo "=== Deleting metadata (*_metadata / *_metadata_new / *_mediainfo.json)"
  while read -r line; do
    rm -f "$line"
  done < <(find "$last_modified_dl_dir" -type f -name '*_metadata' -o -name '*_metadata_new' -o -name '*_mediainfo.json')
  echo "=== Deleting cover art blobs (*.base64)"
  while read -r line; do
    rm -f "$line"
  done < <(find "$last_modified_dl_dir" -type f -name '*.base64')
  echo "=== Deleting remaining converted OGA files (*.oga)"
  while read -r line; do
    rm -f "$line"
  done < <(find "$last_modified_dl_dir" -type f -name '*.oga')
#########################################################################################################################
#### Cleaning local db
  read -rp ">>> Clean local db entries found in last run download directory (yes/no) ? " clean_localdb
  if [[ "$clean_localdb" == "yes" && -f "$LOCAL_DB" ]]; then
    rexp=""
    while read -r line; do
      tmp=$(basename "$line")
      asin=${tmp%%_*}
      if [[ -z "$rexp" ]]; then
        rexp="$asin"
      else
        rexp+="|${asin}"
      fi
    done < <(find "$last_modified_dl_dir" -type f -name '*aax' -o -name '*aaxc')
    grep -vE "$rexp" "$LOCAL_DB" > "$SCRIPT_DIR"/tmp/local_db.tsv
    mv "$SCRIPT_DIR"/tmp/local_db.tsv "$LOCAL_DB"
  fi
else
  echo "=== ERROR: Unable to find last modified directory."
fi
