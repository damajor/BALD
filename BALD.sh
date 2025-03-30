#!/usr/bin/env bash
#set -e
#
#     _____               _                     _____       _ _ _   _          
#    | __  |___ ___ ___ _| |   ___ ___ _ _ _   |  _  |_ _ _| |_| |_| |___      
#    | __ -|  _| .'|   | . |  |   | -_| | | |  |     | | | . | | . | | -_|     
#    |_____|_| |__,|_|_|___|  |_|_|___|_____|  |__|__|___|___|_|___|_|___|     
#                                                                              
#   __    _ _                      ____                _           _         
#  |  |  |_| |_ ___ ___ ___ _ _   |    \ ___ _ _ _ ___| |___ ___ _| |___ ___ 
#  |  |__| | . |  _| .'|  _| | |  |  |  | . | | | |   | | . | .'| . | -_|  _|
#  |_____|_|___|_| |__,|_| |_  |  |____/|___|_____|_|_|_|___|__,|___|___|_|  
#                          |___|                                             
#
# BALD: the Brand new Audible Library Downloader
#
# MIT License
# Copyright (c) [2025] [damajor @ <https://github.com/damajor/BALD>]
#
#    Automatic download / convert / metadata / renaming of Audible books

# Description:
#  This script uses various tools to download your Audible library, enrich metadata,
#  convert audiobooks, rename files and move them to target location.

# IMPORTANT: Read README.md for pre-requisites, required and optional tools.
#########################################################################################################################
#### Set Script, DB amd Config Directories
SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
DB_DIR=$SCRIPT_DIR/db
CONFIG_DIR=$SCRIPT_DIR/config

#### Set Configs that will be replaced by docker mod
DOWNLOAD_DIR=$SCRIPT_DIR/downloads    # AAX & AAXC Audible files will be downloaded here
DEST_BASE_DIR=$SCRIPT_DIR/audiobooks  # Directory for converted files (will be created if it doesnt exist)
DEBUG_USEAAXSAMPLE=false              # AAX sample file to be encoded instead of big Audiobook (fast convert) (false to disable)
DEBUG_USEAAXCSAMPLE=false             # AAXC sample file (false to disable) dont forget to put 'sample.voucher' in same dir
METADATA_TIKA=http://tikahost:9998    # Tika http url without trailing slash short timeouts (1 sec for validation, 2s for lang detection)

#### Source docker_mod.sh for container execution safety
if [[ -f "$SCRIPT_DIR"/docker_mod.sh ]]; then
  [[ "$DEBUG" == "true" ]] && echo "### DEBUG Load docker_mod.sh for container compat."
  source "$SCRIPT_DIR"/docker_mod.sh
elif [[ -n "$container" || "$INCONTAINER" == "true" ]]; then
  echo "=== ERROR: Running in container without 'docker_mod.sh'"
  exit 1
fi

#########################################################################################################################
#### User config
AUDIBLECLI_PROFILE=profile            # Profile created with audible-cli
HIST_LIB_DIR=$DB_DIR/lib_history      # Directory to store library history downloads
HIST_FULL_LIB=true                    # Always download all library history list
STATUS_FILE=$DB_DIR/audible_last_sync # File to store last sync status
LOCAL_DB=$DB_DIR/personal_library.tsv # Check README.md
SKIP_IFIN_LOCAL_DB=true               # Skip download / metadata processing / conversion & file move if Audiobook is found in personal library
DOWNLOAD_PDF=true                     # Download companion files if any
DOWNLOAD_ANNOT=true                   # Download bookmarks
DOWNLOAD_COVERS=true                  # Download covers, you can specify sizes below
DOWNLOAD_COVERS_SIZE=(500 1215)       # 500 seems the most used size but you can specify multiple sizes
DOWNLOAD_WISHLIST=false               # Wishlist is downloaded in HIST_LIB_DIR
DOWNLOAD_JOBS=2                       # (disabled for now) 1 less errors, 2 seems good, higher is hazardous
DOWNLOAD_RETRIES=3                    # Careful of not hammering Amazon servers by keeping this param low
METADATA_PARALLEL=4                   # Number of parallel jobs for metadata workload >= 1 (1 to do sequential conversion)
METADATA_SOURCE=all                   # 'aax' (source metadata from aax or aaxc) or 'all' (metadata from every possible sources)
METADATA_CLEAN_AUTHOR_PATTERN='*'     # Read README.md
METADATA_SINGLENAME_AUTHORS=true      # Keep single name authors or not
METADATA_SKIP_IFEXISTS=false          # Skip metadata processing if AAXFILE_metadata_new exists
METADATA_CHAPTERS=rebuild             # keep (keep aax chapters) / updatetitles (use python, may fail) / rebuild (recreate chapters)
CONVERT_BITRATE=96k                   # Bitrate for audio conversion
CONVERT_BITRATE_RATIO=2/3             # Bitrate ratio from original bitrate (false to disable and always use CONVERT_BITRATE)
CONVERT_PARALLEL=4                    # Number of parallel jobs for conversion >= 1 (1 to do sequential conversion)
CONVERT_DECRYPTONLY=false             # Only decrypt AAX/AAXC files (no additional metadata inserted, no conversion, just pure copy)
CONVERT_SKIP_IFOGAEXISTS=false        # Skip OGA exists
DEST_DIR_NAMING_SCHEME_AUDIOBOOK=(artist series)                  # Read README.md
DEST_BOOKDIR_NAMING_SCHEME_AUDIOBOOK=(series-part "% - " title "% {" composer "%}")   # Read README.md
DEST_BOOK_NAMING_SCHEME_AUDIOBOOK=(title)                         # Read README.md
# Audiobook destination directory overwrite mode (cannot be empty)
# 'true' or 'ignore':         If audiobook destination directory exists then overwrite files in it, other files in directory are preserved
# 'remove':                   If audiobook destination directory exists then remove it and recreate it (all existing files in it will be deleted)
# 'keep':                     If audiobook destination directory exists then create a new one with an incremantal suffix
# 'false' or any other value: If audiobook destination directory exists then skip processing to next audiobook
DEST_DIR_OVERWRITE=false
DEST_COPY_COVER=true              # Copy cover. If multiples cover sizes are present then select the largest file
DEST_COPY_PDF=true                # Copy PDF
DEST_COPY_CHAPTERS_FILE=true      # Copy chapters json file
DEST_COPY_ANNOT_FILE=true         # Copy annotations json file
KEEP_DOWNLOADS=true               # Keep original files in download dir
CLEAN_TMPLOGS=true                # Delete logs generated for the current run (old ones are kept)
# Parameters below are for debugging purposes (default for all bool params is 'false')
DEBUG=false                       # Manual debug
DEBUG_REPEAT_LAST_RUN=false       # This flag is used to repeat the last run without updating the STATUS_FILE
DEBUG_STEPPED_RUN=false           # TODO Debug with stepped updates (only works if STATUS_FILE does already exist)
DEBUG_DONT_UPDATE_LASTRUN=false   # Update status file or not
DEBUG_SKIPDOWNLOADS=false         # true: Disable ALL downloads, false or any other value: normal behavior
DEBUG_SKIPBOOKCONVERT=false       # true: Disable audiobooks conversion, false or any other value: normal behavior
DEBUG_SKIPBOOKMETADATA=false      # true: Disable audiobooks metadata, false or any other value: normal behavior
DEBUG_SKIPMOVEBOOKS=false         # true: Skip moving & renaming Audiobooks, false or any other value: normal behavior
DEBUG_DONTEMBEDCOVER=false        # Do not embed cover jpg in metadata
DEBUG_METADATA=false              # extract metadata from converted file with ffprobe
DEBUG_STEP="1 month"              # TODO "1 month" "1 week" "1 day" (require DEBUG_STEPPED_RUN=true)
#### End of user config
#########################################################################################################################
#### Load external config if any
if [[ -f "$CONFIG_DIR"/config ]]; then
  [[ "$DEBUG" == "true" ]] && echo "### DEBUG Load custom settings from external file."
  source "$CONFIG_DIR"/config 2>/dev/null
fi
#########################################################################################################################
#### Check list
echo ">>> Requirements check"
reqs_done=true
if [[ ! -f "$HOME/.audible/config.toml" ]]; then
  echo "=== ERROR: audible-cli does not seems to be initialized, or if in container you may have wrong volume mapped."
  reqs_done=false
fi
for req in ffmpeg ffprobe mediainfo audible python jq parallel sed grep find xxd tr; do
  if command -v "$req" &> /dev/null; then
    [[ "$DEBUG" == "true" ]] && echo "=== $req is installed."
  else
    echo "=== ERROR: $req is not installed."
    reqs_done=false
  fi
done
if [ -f "$SCRIPT_DIR/ogg-image-blobber.sh" ] && [ -x "$SCRIPT_DIR/ogg-image-blobber.sh" ]; then
  [[ "$DEBUG" == "true" ]] && echo "=== ogg-image-blobber.sh found."
else
  echo "=== ogg-image-blobber.sh is missing or missing executable bit."
  reqs_done=false
fi
if [ -f "$SCRIPT_DIR/update_chapter_titles.py" ]; then
  [[ "$DEBUG" == "true" ]] && echo "=== update_chapter_titles.py found."
else
  echo "=== update_chapter_titles.py is missing."
  reqs_done=false
fi
TIKA_METHOD=""
if [[ -f "$METADATA_TIKA" ]]; then
  [[ "$DEBUG" == "true" ]] && echo "=== Tika jar is found."
  if command -v java &> /dev/null; then
    [[ "$DEBUG" == "true" ]] && echo "=== Java is found."
    TIKA_METHOD="java"
  else
    echo "=== Tika jar found but Java IS NOT found. Language detection will be disabled."
  fi
else [[ "$METADATA_TIKA" =~ http.* ]];
  tika_ret=$(curl -s -I --connect-timeout 2 ${METADATA_TIKA}/version --header "Accept: text/plain" | head -n 1|cut -d$' ' -f2)
  if [[ "$tika_ret" == 200 ]]; then
    [[ "$DEBUG" == "true" ]] && echo "=== Tika server 200 Ok"
    TIKA_METHOD="server"
  elif [[ -z "$tika_ret" ]]; then
    echo "=== Tika server error, check Tika url. Language detection will be disabled."
  else
    echo "=== Tika server error, /version endpoint did not return 200 Ok but ($tika_ret). Language detection will be disabled."
  fi
fi
if [[ ! -f ~/.audible/${AUDIBLECLI_PROFILE}.json ]]; then
  echo "=== WARNING: audible-cli profile '${AUDIBLECLI_PROFILE}' not found."
fi
if [[ "${#DEST_BOOKDIR_NAMING_SCHEME_AUDIOBOOK[@]}" == 0 ]]; then
  echo "=== DEST_BOOKDIR_NAMING_SCHEME_AUDIOBOOK cannot be empty, this is the target audiobook **directory** naming scheme."
  reqs_done=false
fi
if [[ "${#DEST_BOOK_NAMING_SCHEME_AUDIOBOOK[@]}" == 0 ]]; then
  echo "=== DEST_BOOK_NAMING_SCHEME_AUDIOBOOK cannot be empty, this is the target audiobook **file** naming scheme."
  reqs_done=false
fi
[[ "$reqs_done" == "false" ]] && exit 1
if [[ ! -f ~/.parallel/will-cite ]]; then
    echo "=== Recommended => run 'parallel --citation' and follow instructions"; exit 1
fi
#########################################################################################################################
#### Internals preparation
ACTIVATION_BYTES=$(jq -r .activation_bytes ~/.audible/${AUDIBLECLI_PROFILE}.json)
[[ -z "$ACTIVATION_BYTES" || "$ACTIVATION_BYTES" == "null" ]] && ACTIVATION_BYTES=$(audible activation-bytes | tail -1)
# Exit early if activation-bytes is not set
[[ -z "$ACTIVATION_BYTES" || "$ACTIVATION_BYTES" == "null" ]] && (echo ">> ERROR Cannot get 'activation-bytes'"; exit 255)
DOWNLOAD_PDF_OPT=""
[[ "$DOWNLOAD_PDF" == "true" ]] && DOWNLOAD_PDF_OPT="--pdf"
DOWNLOAD_ANNOT_OPT=""
[[ "$DOWNLOAD_ANNOT" == "true" ]] && DOWNLOAD_ANNOT_OPT="--annotation"
DOWNLOAD_COVERS_OPT=()
if [[ "$DOWNLOAD_COVERS" == "true" ]]; then
  IFS=" " read -r -a tmp <<< "${DOWNLOAD_COVERS_SIZE[@]/#/--cover-size }"
  DOWNLOAD_COVERS_OPT=(--cover "${tmp[@]}")
fi
LAST_RUN=$(tail -n 1 "${STATUS_FILE}" 2>/dev/null)
# Last synchronization options (with force full sync on first run)
# Create "audible_last_sync" manually if you want to avoid full sync
LAST_SYNC_OPT=(--start-date "$LAST_RUN")
if [[ "$DEBUG_STEPPED_RUN" == "true" ]]; then
  if [[ "$DEBUG_STEP" == "1 month" || "$DEBUG_STEP" == "1 week" || "$DEBUG_STEP" == "1 day" ]]; then
    NOW=$(date -d "$(date -d "$LAST_RUN" +%Y-%m-%d) + ${DEBUG_STEP}" +%Y-%m-%d)
    LAST_SYNC_OPT+=(--end-date "${NOW}")
    echo "### DEBUG STEP: Start date => $LAST_RUN"
    echo "### DEBUG STEP: End date   => $NOW"
  fi
elif [[ "$DEBUG_REPEAT_LAST_RUN" == "true" ]]; then
    LAST_RUN=$(head -n 1 "${STATUS_FILE}" 2>/dev/null)
    NOW=$(tail -n 1 "${STATUS_FILE}" 2>/dev/null)
    [[ "$LAST_RUN" == "$NOW" ]] && LAST_RUN=""
    LAST_SYNC_OPT=()
    [[ -n "$LAST_RUN" ]] && LAST_SYNC_OPT+=(--start-date "$LAST_RUN")
    [[ -n "$NOW" ]] && LAST_SYNC_OPT+=(--end-date "$NOW")
    echo "### DEBUG REPEAT: Start date => $LAST_RUN"
    echo "### DEBUG REPEAT: End date   => $NOW"
else
  NOW=$(date +%Y-%m-%d)
fi
if [[ "$LAST_RUN" == "$NOW" ]]; then
  LAST_RUN=${NOW}T00:00:01Z
  LAST_SYNC_OPT=(--start-date "$LAST_RUN" --end-date "${NOW}T23:59:59Z")
fi
# Full sync
[[ -z "$LAST_RUN" ]] && LAST_SYNC_OPT=()
[[ "$DEBUG" == "true" || "$DEBUG_REPEAT_LAST_RUN" == "true" || "$DEBUG_STEPPED_RUN" == "true" ]] && echo "### DEBUG: LAST_SYNC_OPT ${LAST_SYNC_OPT[*]}"
# Make working dirs
mkdir -p "$SCRIPT_DIR/tmp" || { echo "=== ERROR: Cannot create tmp directory. Exiting."; exit 1; }
mkdir -p "$HIST_LIB_DIR" || { echo "=== ERROR: Cannot create library directory. Exiting."; exit 1; }
mkdir -p "$DEST_BASE_DIR" || { echo "=== ERROR: Cannot create personal audiobook library directory. Exiting."; exit 1; }
touch "$LOCAL_DB"
#Function of what trap command calls
function ctrl_c() {
    echo -e "\n*** Received CTRL-C - Interrupting script. ***\n"
    exit 1
}
trap ctrl_c INT
#########################################################################################################################
# Download wishlist
if [[ "$DEBUG_SKIPDOWNLOADS" != "true" ]]; then
  if [[ "$DOWNLOAD_WISHLIST" == "true" ]]; then
    # Cannot use output path "-o PATH" (wait until fix https://github.com/mkb79/audible-cli/issues/219)
    audible wishlist export && mv "$SCRIPT_DIR/wishlist.tsv" "$HIST_LIB_DIR/${NOW}_wishlist.tsv"
  fi
fi
#########################################################################################################################
# Full library TSV download (if enabled)
if [[ "$DEBUG_SKIPDOWNLOADS" != "true" ]]; then
  if [[ "$HIST_FULL_LIB" == "true" ]]; then
    echo ">>> TSV Download full library"
    audible library export --resolve-podcasts -o "$HIST_LIB_DIR/${NOW}_library_full.tsv" && echo "=== File saved to: $HIST_LIB_DIR/${NOW}_library_full.tsv"
  fi
fi
#########################################################################################################################
# Download library update since last run
if [[ "$DEBUG_SKIPDOWNLOADS" != "true" ]]; then
  echo ">>> TSV Download library update since last run"
  audible library export "${LAST_SYNC_OPT[@]}" -o "$SCRIPT_DIR/tmp/${NOW}_library_new.tsv"
  # Workaround to clean podcasts or unwanted audiobooks, waiting for fix in audible-cli (https://github.com/mkb79/audible-cli/issues/218)
  # Discard all entries not in the requested time range + discard entries with no duration
  head -n 1 "$SCRIPT_DIR/tmp/${NOW}_library_new.tsv" > "$HIST_LIB_DIR/${NOW}_library_new.tsv"
  awk -v FS='\t' -v OFS='\n' -v date_start="$LAST_RUN" -v date_end="${NOW}T23:59:59Z" '{if ($18>=date_start && $18<=date_end && $10>1) { print $0 }}' "$SCRIPT_DIR/tmp/${NOW}_library_new.tsv" >> "$HIST_LIB_DIR/${NOW}_library_new.tsv"
  echo "=== File saved to: $HIST_LIB_DIR/${NOW}_library_new.tsv"
fi
#########################################################################################################################
# Download AAX/AAXC
if [[ "$DEBUG_SKIPDOWNLOADS" != "true" ]]; then
  echo ">>> Download files !!!"
  mkdir -p "$DOWNLOAD_DIR/$NOW"
  # Download ASINs one by one until audible-cli fix (https://github.com/mkb79/audible-cli/issues/218)
  first_entry=true
  awk -v FS='\t' '{print $1}' "$HIST_LIB_DIR/${NOW}_library_new.tsv" | while IFS= read -r asin; do
    # Discard first entry (column name)
    if $first_entry; then
      first_entry=false
      continue
    fi
    [[ "$DEBUG" == "true" ]] && echo "### DEBUG: ASIN => $asin"
    # Skip if asin in local db
    if [[ "$SKIP_IFIN_LOCAL_DB" == "true" ]] && grep -q -m1 "$asin" "$LOCAL_DB"; then
      echo "=== ASIN already in personal library, skipping downloads..."
      continue
    fi
    for (( i=1; i<=DOWNLOAD_RETRIES; i++)); do
      echo "=== Download (try $i/$DOWNLOAD_RETRIES): $asin"
      [[ "$DEBUG" != "true" ]] && echo "audible download -f asin_ascii -j $DOWNLOAD_JOBS --timeout 40 --aax-fallback --ignore-errors $DOWNLOAD_PDF_OPT ${DOWNLOAD_COVERS_OPT[*]} --chapter $DOWNLOAD_ANNOT_OPT -o $DOWNLOAD_DIR/$NOW -a $asin"
      audible download -f asin_ascii -j $DOWNLOAD_JOBS --timeout 40 --aax-fallback --ignore-errors $DOWNLOAD_PDF_OPT "${DOWNLOAD_COVERS_OPT[@]}" --chapter --chapter-type Flat $DOWNLOAD_ANNOT_OPT -o "$DOWNLOAD_DIR/$NOW" -a "$asin" | tee "$SCRIPT_DIR/tmp/${NOW}_download_${asin}.log" | grep --color -e '^error: Error downloading' -e '^'
      if grep -q '^error: Error downloading' "$SCRIPT_DIR/tmp/${NOW}_download_${asin}.log"; then
        echo "=== ERROR detected during try $i/$DOWNLOAD_RETRIES, while downloading $asin,  retrying!"
        continue
      else
        echo "=== No error detected while downloading $asin, try $i/$DOWNLOAD_RETRIES"
        break
      fi
    done
  done
fi
# Should work after audible-cli fix (https://github.com/mkb79/audible-cli/issues/218)
#for (( i=0; i<$DOWNLOAD_RETRIES; i++)); do
#  audible download -j $DOWNLOAD_JOBS --timeout 40 --aax-fallback --ignore-errors --all "${LAST_SYNC_OPT[@]}" $DOWNLOAD_PDF_OPT "${DOWNLOAD_COVERS_OPT[@]}" --chapter $DOWNLOAD_ANNOT_OPT -o $DOWNLOAD_DIR/$NOW | tee $SCRIPT_DIR/tmp/${NOW}_download.log | grep --color -e '^error' -e '^'
#  grep '^error' $SCRIPT_DIR/tmp/${NOW}_download.log && continue || break
#done
#########################################################################################################################
# Save last run
if [[ "$DEBUG_DONT_UPDATE_LASTRUN" != "true" ]]; then
  previous_run=$(tail -n 1 "${STATUS_FILE}")
  if [[ "$previous_run" == "$NOW" ]]; then
    head -n 1 "${STATUS_FILE}" > "$SCRIPT_DIR/tmp/status"
  else
    echo "$previous_run" > "$SCRIPT_DIR/tmp/status"
  fi
  echo "$NOW" >> "$SCRIPT_DIR/tmp/status"
  cp "$SCRIPT_DIR/tmp/status" "${STATUS_FILE}"
  rm "$SCRIPT_DIR/tmp/status"
fi
#########################################################################################################################
# Export required env for parallel execution
export ACTIVATION_BYTES
export NOW
export TIKA_METHOD
export SCRIPT_DIR
export HIST_LIB_DIR
export LOCAL_DB
export SKIP_IFIN_LOCAL_DB
export DEST_COPY_COVER
export DEST_COPY_PDF
export DEST_COPY_CHAPTERS_FILE
export DEST_COPY_ANNOT_FILE
export CONVERT_BITRATE
export CONVERT_BITRATE_RATIO
export CONVERT_SKIP_IFOGAEXISTS
export CONVERT_DECRYPTONLY
export METADATA_SOURCE
export METADATA_TIKA
export METADATA_SINGLENAME_AUTHORS
export METADATA_CLEAN_AUTHOR_PATTERN
export METADATA_SKIP_IFEXISTS
export METADATA_CHAPTERS
export DEBUG
export DEBUG_USEAAXSAMPLE
export DEBUG_USEAAXCSAMPLE
export DEBUG_METADATA
export DEBUG_DONTEMBEDCOVER
#########################################################################################################################
# Clean Author metadata based on pattern (remove translator/editor/etc...)
# And remove single name authors (if enabled in user settings)
# $1 Author metadata
# $2 String separator
# Return Author metadata string
function metadata_clean_authors() {
  local new_artists tmp_artists artist clean_author
  IFS=',' read -r -a tmp_artists <<< "$1"
  new_artists=()
  shopt -s nocasematch
  for artist in "${tmp_artists[@]}"; do
    if [[ ! "$artist" =~ $METADATA_CLEAN_AUTHOR_PATTERN ]]; then
      new_artists+=("${artist}")
    fi
  done
  shopt -u nocasematch
  clean_author=""
  if [[ "${#new_artists[@]}" -gt 1 ]]; then
    for artist in "${new_artists[@]}"; do
      tmp_artist=$(echo "$artist" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      if [[ "$METADATA_SINGLENAME_AUTHORS" == "false" && "$tmp_artist" =~ ^[a-zA-Z0-9]+$ ]]; then
        continue
      fi
      if [ -z "$clean_author" ]; then
        clean_author="$tmp_artist"
      else
        clean_author+="$2$tmp_artist"
      fi
    done
  else
    clean_author="${new_artists[*]}"
  fi
  echo "$clean_author"
}
export -f metadata_clean_authors
#########################################################################################################################
# Extract translators/editors from Author metadata based on pattern
# $1 metadata
# $2 pattern
# Return string
function metadata_get_pattern() {
  local tmp tmp_output item clean_output
  IFS=',' read -r -a tmp <<< "$1"
  tmp_output=()
  shopt -s nocasematch
  for item in "${tmp[@]}"; do
    if [[ "$item" =~ $2 ]]; then
      tmp_output+=("${item%-*}")
    fi
  done
  shopt -u nocasematch
  IFS=';'
  clean_output="${tmp_output[*]}"
  unset IFS
  echo "$clean_output"
}
export -f metadata_get_pattern
#########################################################################################################################
# Truncate string to a maximum length
# $1 string
# $2 maximum length
# Return string
function truncate_string() {
  local str="$1"
  local max_length="$2"
  # shellcheck disable=SC2000
  if [ "$(echo "$str" | wc -c)" -gt "$max_length" ]; then
    str=${str::max_length}
  fi
  echo "$str"
}
#########################################################################################################################
# Build file or directory name based on a naming scheme input
# $1 name or directory naming scheme
# $2 metadata
# Return string
function build_string_from_scheme() {
  local output size_output size_meta
  local -n naming_scheme=$1
  local -n lmetadata=$2
  output=""
  for metaname in "${naming_scheme[@]}"; do
    if [[ "$metaname" == "%"* && -n "$output" ]]; then
      output+="${metaname:1}"
    elif [[ -z "${lmetadata["$metaname"]}" ]]; then
      continue
    else
      # shellcheck disable=SC2000
      size_output=$(echo "$output" | wc -c)
      # shellcheck disable=SC2000
      size_meta=$(echo "${lmetadata["$metaname"]}" | wc -c)
      if [[ "$(( size_output + size_meta ))" -gt 240 ]]; then
        output+=$(truncate_string "${lmetadata["$metaname"]}" "$((240 - size_output))" )
      else
        output+="${lmetadata["$metaname"]}"
      fi
    fi
  done
  echo "$output"
}
#########################################################################################################################
# Remove file
# $1 file to remove
function remove_file() {
  if cd "$(dirname "$1")"; then # || { echo "=== ERROR: Cannot 'cd' to '$1', audiobook skipped."; continue; }
    rm -fr "$(basename "$1")"
    if cd "$SCRIPT_DIR"; then # || { echo "=== ERROR: Cannot 'cd' back to '$SCRIPT_DIR', audiobook skipped."; continue; }
      true
    else
      false
    fi
  else
    false
  fi
}
#########################################################################################################################
# Move files to destination
# $1 audiobook full path & name
# $2 destination directory
# $3 destination file name
function move_files() {
  local tmp chapters_file annots_file pdf_file
  tmp=$(basename "$1")
  dirnam=$(dirname "$1")
  title=${tmp%-*}
  chapters_file="$dirnam/$title-chapters.json"
  annots_file="$dirnam/$title-annotations.json"
  pdf_file="$dirnam/$title.pdf"
  cover_file=$(du "$dirnam/${title}"*jpg | sort -nr | head -1 | cut -f2)

  if [[ "$CONVERT_DECRYPTONLY" == "true" ]]; then
    move_to_file="$2/$3.m4b"
  else
    move_to_file="$2/$3.oga"
  fi

  # Move audio file
  if [[ "$DEBUG" == "true" ]]; then
    echo "### DEBUG: Copy converted audiobook: $1 to $move_to_file"
    cp "$1" "$move_to_file"
  else
    mv "$1" "$move_to_file"
  fi
  # Copy cover
  if [[ "$DEST_COPY_COVER" == true ]]; then
    if [[ -f "$cover_file" ]]; then
      if [[ "$DEBUG" == "true" ]]; then
        echo "### DEBUG: Copy cover: $cover_file"
        cp "$cover_file" "$2/Cover.jpg"
      else
        mv "$cover_file" "$2/Cover.jpg"
      fi
    fi
  fi
  # Copy PDF
  if [[ "$DEST_COPY_PDF" == true ]]; then
    if [[ -f "$pdf_file" ]]; then
      if [[ "$DEBUG" == "true" ]]; then
        echo "### DEBUG: Copy PDF: $pdf_file"
        cp "$pdf_file" "$2/$3.pdf"
      else
        mv "$pdf_file" "$2/$3.pdf"
      fi
    fi
  fi
  # Copy chapters
  if [[ "$DEST_COPY_CHAPTERS_FILE" == true ]]; then
    if [[ -f "$chapters_file" ]]; then
      if [[ "$DEBUG" == "true" ]]; then
        echo "### DEBUG: Copy chapters: $chapters_file"
        cp "$chapters_file" "$2/$3-chapters.json"
      else
        mv "$chapters_file" "$2/$3-chapters.json"
      fi
    fi
  fi
  # Copy annotations
  if [[ "$DEST_COPY_ANNOT_FILE" == true ]]; then
    if [[ -f "$annots_file" ]]; then
      if [[ "$DEBUG" == "true" ]]; then
        echo "### DEBUG: Copy annotations: $annots_file"
        cp "$annots_file" "$2/$3-annotations.json"
      else
        mv "$annots_file" "$2/$3-annotations.json"
      fi
    fi
  fi
}
#########################################################################################################################
# Update ffmpeg metadata file
# $1 ffmpeg metadata file
# $2 tag name
# $3 tag value
function update_metadata() {
  local metadata_end clean_tagval
  # Sanitize tagval for sed substitution
  clean_tagval=$(echo "$3" | sed -e 's/[]\/$*.^[]/\\&/g')
  [[ "$DEBUG_METADATA" == "true" ]] && echo "### DEBUG: $2 // $clean_tagval"
  # Dont add empty metadata
  [[ -z "$clean_tagval" ]] && return
  # Replace or insert metadata
  metadata_end=$(grep -n -m 1 "\[CHAPTER\]" "$1" | cut -d: -f1)
  [[ -z "$metadata_end" ]] && metadata_end=$(wc -l < "$1")
  if head -n "$metadata_end" "$1" | grep -q "^$2=" "$1"; then
    sed -i "1,${metadata_end} s/^$2=.*/$2=$clean_tagval/" "$1"
  else
    sed -i "2 i $2=$3" "$1"
  fi
}
export -f update_metadata
#########################################################################################################################
# Build metadata
# $1 Audiobook/Podcasts file (with full path)
function build_metadata() {
  local title asin chapters_file art tmp columns libdata description lang
  tmp=$(basename "$1")
  title=${tmp%-*}
  asin=${tmp%%_*}
  chapters_file=$(dirname "$1")/$title-chapters.json
  # Skip if asin in local db
  if [[ "$SKIP_IFIN_LOCAL_DB" == "true" ]] && grep -q -m1 "$asin" "$LOCAL_DB"; then
    echo "=== ASIN already in personal library, skipping metadata processing..."
    return
  fi
  if [[ "$METADATA_SKIP_IFEXISTS" == "true" && -f "${1}_metadata_new" ]]; then
    echo "=== Metadata already exists for '$1', skipping..."
    return
  fi
  # If multiple covers get downloaded then select the best quality (largest one :)
  art=$(du "$(dirname "$1")/${asin}"*jpg | sort -nr | head -1 | cut -f2)
  echo "=== Building metadata for $title ($asin)"
  # Extract metadata
  if ! ffmpeg -y -nostdin -loglevel warning -i "$1" -f ffmetadata "${1}_metadata"; then
    echo "=== ERROR: ffmpeg failed to extract metadata from $1, skiping..."
    return
  fi
  mediainfo --Output=JSON "$1" | jq . - > "$1"_mediainfo.json
  # Enrich chapters
  case "$METADATA_CHAPTERS" in
    "keep")
      cp "${1}_metadata" "${1}_metadata_new" ;;
    "updatetitles")
      if [[ -f "$chapters_file" ]]; then
        python "$SCRIPT_DIR"/update_chapter_titles.py -f "${1}_metadata" \
                                        -a "$chapters_file" \
                                        -o "${1}_metadata_new" 2>/dev/null || echo "=== ERROR Modifying chapters failed, using original file metadata."
      fi ;;
    "rebuild")
      "$SCRIPT_DIR"/rebuild_chapters.sh "$chapters_file" "${1}_mediainfo.json" "${1}_metadata" "${1}_metadata_new" \
      || echo "=== ERROR Modifying chapters failed, using original file metadata." ;;
  esac
  if [[ ! -f "${1}_metadata_new" ]]; then
    cp "${1}_metadata" "${1}_metadata_new"
  fi
  if [[ "$METADATA_SOURCE" == "all" ]]; then
    echo "=== Using all possible metadata (original aax/aaxc file with ffmpeg/mediainfo and library)"
    # Extract additional metadata from history file
    IFS=$'\t' read -r -a columns < <(head -n 1 "$HIST_LIB_DIR/${NOW}_library_new.tsv")
    # Replace tabs with another special char to avoid blank spaces collapse
    IFS=$'\a' read -r -a libdata < <(grep -m1 "^$asin" "$HIST_LIB_DIR/${NOW}_library_new.tsv" | tr \\11 \\7)
    for i in "${!libdata[@]}"; do
      case "${columns[i]//$'\r'/}" in
        asin)
          #asin / audible_asin           ASIN
          update_metadata "${1}_metadata_new" asin "${libdata[i]}"
          update_metadata "${1}_metadata_new" audible_asin "${libdata[i]}" ;;
        title)
          #album / title                 Title
          update_metadata "${1}_metadata_new" title "${libdata[i]}"
          update_metadata "${1}_metadata_new" album "${libdata[i]}" ;;
        subtitle)
          #subtitle                      Subtitle
          update_metadata "${1}_metadata_new" subtitle "${libdata[i]}" ;;
        extended_product_description) ;;
          # enrich description/comment ???
        authors) {
          #artist / album-artist         Author
          local tmp
          if [[ -z "${libdata[i]}" ]]; then
            tmp="${libdata[i]}"
          else
            tmp=$(jq -r '.media.track[] | select(."@type" == "General") | .Album_Performer' "${1}_mediainfo.json")
          fi
          update_metadata "${1}_metadata_new" artist "$(metadata_clean_authors "${tmp}" ' ; ')"
          update_metadata "${1}_metadata_new" album_artist "$(metadata_clean_authors "${tmp}" ' ; ')"
        } ;;
        narrators) {
          #composer                      Narrator
          local tmp
          if [[ -z "${libdata[i]}" ]]; then
            tmp="${libdata[i]}"
          else
            tmp="$(jq -r '.media.track[] | select(."@type" == "General") | .extra.nrt' "${1}_mediainfo.json")"
          fi
          update_metadata "${1}_metadata_new" composer "$(metadata_clean_authors "${tmp}" ' ; ')"
          } ;;
        series_title)
          #series / mvnm                 Series
          update_metadata "${1}_metadata_new" series "${libdata[i]}"
          update_metadata "${1}_metadata_new" mvnm "${libdata[i]}" ;;
        series_sequence)
          #series-part / mvin            Series Sequence
          update_metadata "${1}_metadata_new" series-part "${libdata[i]}"
          update_metadata "${1}_metadata_new" mvin "${libdata[i]}" ;;
        genres)
          #genre                         Genres
          update_metadata "${1}_metadata_new" genre "${libdata[i]//,/;}" ;;
        runtime_length_min) ;;
        is_finished) ;;
        percent_complete) ;;
        rating) ;;
        num_ratings) ;;
        date_added) ;;
        release_date)
          #year                          Publish Year
          update_metadata "${1}_metadata_new" year "${libdata[i]}" ;;
        cover_url) ;;
        purchase_date) ;;
      esac
    done
    # publisher
    update_metadata "$1"_metadata_new publisher "$(jq -r '.media.track[] | select(."@type" == "General") | .extra.pub' "${1}_mediainfo.json")"
    # description (afaik ffmpeg 7.1 cant write 'description' instead uses 'comment' to write description)
    description=$(jq -r '.media.track[] | select(."@type" == "General") | .Track_More' "${1}_mediainfo.json")
    update_metadata "${1}_metadata_new" comment "$description"
    # Language seems always wrong in Audible tags (at least for international releases)
    # Workaround with Tika (detect language from title description text if text is long enough)
    if [[ "${#description}" -gt "100" ]]; then
      lang=""
      if [[ "$TIKA_METHOD" == "java" ]]; then
        lang=$(java -jar "$METADATA_TIKA" -l - <<< "$description")
      elif [[ "$TIKA_METHOD" == "server" ]]; then
        lang=$(curl -s --connect-timeout 2 -T- ${METADATA_TIKA}/meta/language --header "Accept: text/plain" <<< "$description")
      fi
      if [[ -n "$lang" ]]; then
        update_metadata "${1}_metadata_new" language "$lang"
        update_metadata "${1}_metadata_new" lang "$lang"
      fi
    fi
    # Add custom tag
    update_metadata "${1}_metadata_new" "encoded_using" "BALD (Brand new Audible Library Downloader)"
  fi
  # Create OGG cover metadata
  if [[ "$DEBUG_DONTEMBEDCOVER" != "true" ]]; then
    "$SCRIPT_DIR"/ogg-image-blobber.sh "$art"
    # art in metadata new
    sed -i '1s/^/METADATA_BLOCK_PICTURE=/' "${art%.*}.base64"   # Add metadata prefix
    echo >> "${art%.*}.base64"                                  # Add new line at the end
    sed -i "2e cat '${art%.*}.base64'\n" "${1}_metadata_new"      # Insert cover art in main metadata file
  fi
  # Delete intermediate file, keep if DEBUG true
  if [[ "$DEBUG" != "true" ]]; then
    rm -f "${1}_metadata"
    rm -f "${art%.*}.base64"
  fi
}
export -f build_metadata
#########################################################################################################################
# Convert AAX/AAXC files & insert metadata
# $1 Audiobook/Podcast file (with full path)
function convert_audio() {
  local my_audiobook title asin type decrypt_param tmp voucher aaxc_iv aaxc_key input_file lang langopt original_bitrate new_bitrate
  my_audiobook=$1
  tmp=$(basename "$my_audiobook")
  title=${tmp%-*}
  asin=${tmp%%_*}
  type=${tmp##*.}
  input_file="$my_audiobook"
  echo "=== Converting $title ($asin) ($type)"
  [[ "$DEBUG" == "true" ]] && echo "### DEBUG: $my_audiobook"
  # Skip if asin in local db
  if [[ "$SKIP_IFIN_LOCAL_DB" == "true" ]] && grep -q -m1 "$asin" "$LOCAL_DB"; then
    echo "=== ASIN already in personal library, skipping conversion..."
    return
  fi
  if [[ ! -f "${my_audiobook}_metadata_new" ]]; then
    echo "=== ERROR: Missing metadata file for ${my_audiobook}, skipping..."
    return
  elif [[ ! -f "${my_audiobook}_mediainfo.json" ]]; then
    echo "=== ERROR: Missing mediainfo file for ${my_audiobook}, skipping..."
    return
  fi
  if [[ "$CONVERT_SKIP_IFOGAEXISTS" == "true" && -f "${my_audiobook}.oga" ]]; then
    echo "=== OGA file exists (but not moved), skipping conversion..."
    return
  fi
  # Preparing ffmpeg decrypting opts
  if [[ "$type" == "aaxc" ]]; then
    if [[ "$DEBUG_USEAAXCSAMPLE" != "false" && -f "$DEBUG_USEAAXCSAMPLE" ]]; then
      echo "### DEBUG: Input AAXC replaced with sample => $DEBUG_USEAAXCSAMPLE"
      input_file="$SCRIPT_DIR/$DEBUG_USEAAXCSAMPLE"
    fi
    voucher=${input_file%.*}.voucher
    aaxc_key=$(jq -r '.content_license.license_response.key' "${voucher}")
    aaxc_iv=$(jq -r '.content_license.license_response.iv' "${voucher}")    
    decrypt_param=(-audible_key "${aaxc_key}" -audible_iv "${aaxc_iv}")
  else
    if [[ "$DEBUG_USEAAXSAMPLE" != "false" && -f "$DEBUG_USEAAXSAMPLE" ]]; then
      echo "### DEBUG: Input AAX replaced with sample => $DEBUG_USEAAXSAMPLE"
      input_file="$SCRIPT_DIR/$DEBUG_USEAAXSAMPLE"
    fi
    decrypt_param=(-activation_bytes "${ACTIVATION_BYTES}")
  fi
  # Decrypt only OR Convert
  if [[ "$CONVERT_DECRYPTONLY" == "true" ]]; then
    ffmpeg -y -nostdin -loglevel warning -stats "${decrypt_param[@]}" \
           -i "$my_audiobook" -c copy \
           "$my_audiobook".m4b
  else
    # Fetch language metadata if available (ffmpeg seems buggy setting this from ffmetadata file, but works from command line)
    lang=$(grep language "${my_audiobook}_metadata_new")
    langopt=()
    if [[ -n "$lang" ]]; then
      langopt=(-metadata:s:0 "$lang")
    fi
    # Custom bitrate
    original_bitrate=$(jq -r '.media.track[] | select(."@type" == "Audio") | .BitRate' "${my_audiobook}_mediainfo.json")
    if [[ "$CONVERT_BITRATE_RATIO" != "false" ]]; then
      new_bitrate="$(echo "scale=10; $original_bitrate * $CONVERT_BITRATE_RATIO / 1024" | bc | awk '{print int($1+0.5)}')"k
    else
      new_bitrate="$CONVERT_BITRATE"
    fi
    # Convert file to ogg (opus) using ffmpeg
    ffmpeg -y -nostdin -loglevel warning -stats "${decrypt_param[@]}" \
          -i "$input_file" -i "${my_audiobook}_metadata_new" \
          -map_metadata 1 -map_chapters 1 \
          "${langopt[@]}" \
          -c:v copy -c:a libopus -b:a "$new_bitrate" -vbr on \
          "${my_audiobook}.oga"
    # Debug metadata
    if [[ "$DEBUG_METADATA" == "true" ]]; then
      echo "### DEBUG METADATA: ${my_audiobook}.oga_metadata"
      ffprobe -v quiet -print_format default -show_format -show_streams -select_streams a -i "${my_audiobook}.oga" | grep TAG | sed 's/^TAG://' > "${my_audiobook}.oga_metadata"
    fi
  fi
}
export -f convert_audio
#########################################################################################################################
# Audiobooks list for next loops
my_audiofiles=$(find "$DOWNLOAD_DIR/$NOW" -maxdepth 1 -type f -iname '*aax' -or -iname '*aaxc' | sort)
if [[ -n "$my_audiofiles" ]]; then
#########################################################################################################################
# Build metadata for every new audiobooks
  if [[ "$DEBUG_SKIPBOOKMETADATA" != "true" ]]; then
    if [[ "$METADATA_PARALLEL" == 1 ]]; then
      echo ">>> Building audiobooks metadata (sequential processing)"
    else
      echo ">>> Building audiobooks metadata ($METADATA_PARALLEL jobs)"
    fi
    parallel --bar -j"$METADATA_PARALLEL" build_metadata <<< "$my_audiofiles"
  else
    [[ "$DEBUG" == "true" ]] && echo "### DEBUG AUDIOBOOKS METADATA SKIPPED"
  fi
  echo "##################### END OF METADATA BUILDING #####################"
#########################################################################################################################
# Convert all audiobooks
  if [[ "$DEBUG_SKIPBOOKCONVERT" != "true" ]]; then
    if [[ "$CONVERT_PARALLEL" == 1 ]]; then
      echo ">>> Convert audiobooks (sequential processing)"
    else
      echo ">>> Convert audiobooks ($CONVERT_PARALLEL jobs)"
    fi
    parallel --bar -j"$CONVERT_PARALLEL" convert_audio <<< "$my_audiofiles"
  else
    [[ "$DEBUG" == "true" ]] && echo "### DEBUG AUDIOBOOKS CONVERSION SKIPPED"
  fi
#########################################################################################################################
# End processing for audiobooks
else
  echo ">>> No audiobooks to process."
fi
#########################################################################################################################
# Tmp stats
rm -f "$SCRIPT_DIR/tmp/${NOW}_statistics.txt"
{
  echo "> Total AAX/AAXC:        $(find "$DOWNLOAD_DIR/$NOW" -name '*aax' -o -name '*aaxc' | wc -l)"
  echo "> Total Chap files:      $(find "$DOWNLOAD_DIR/$NOW" -name '*chapters.json' | wc -l)"
  echo "> Total Metadata:        $(find "$DOWNLOAD_DIR/$NOW" -name '*aax' -o -name '*aaxc' | while read -r file; do find "$DOWNLOAD_DIR/$NOW" -name "$(basename "${file}")_metadata_new"; done | wc -l)"
  echo "> Missing Metadata (ignore this if processing was skipped):"
  while read -r file; do
    if [[ ! -f "${file}_metadata_new" ]]; then
      echo "  =>  ${file}"
    fi
  done < <(find "$DOWNLOAD_DIR/$NOW" -name '*aax' -o -name '*aaxc')
  echo "> Missing Mediainfo (ignore this if processing was skipped):"
  while read -r file; do
    if [[ ! -f "${file}_mediainfo.json" ]]; then
      echo "  =>  ${file}"
    fi
  done < <(find "$DOWNLOAD_DIR/$NOW" -name '*aax' -o -name '*aaxc')
  echo "> Total OGA:             $(find "$DOWNLOAD_DIR/$NOW" -name '*oga' | wc -l)"
  echo "> Missing OGA (ignore this if processing was skipped):"
  while read -r file; do
    if [[ ! -f "${file}.oga" ]]; then
      echo "  =>  ${file}"
    fi
  done < <(find "$DOWNLOAD_DIR/$NOW" -name '*aax' -o -name '*aaxc')
  echo "> Missing AAX/AAXC:"
  while read -r file; do
    tmp=$(basename "${file}")
    prefix="${tmp%-*}"
    audiobook=$(find "$DOWNLOAD_DIR/$NOW" -name "${prefix}*aax" -o -name "${prefix}*aaxc")
    if [[ -z "$audiobook" ]]; then
      echo "  =>  ${prefix}"
    fi
  done < <(find "$DOWNLOAD_DIR/$NOW" -name '*chapters.json')
  echo "> Total AAX/AAXC size:   $(du -hc "$DOWNLOAD_DIR/$NOW"/*aax "$DOWNLOAD_DIR/$NOW"/*aaxc 2>/dev/null | tail -n 1 | cut -f 1)"
  echo "> Total OGA size:        $(du -hc "$DOWNLOAD_DIR/$NOW"/*oga 2>/dev/null | tail -n 1 | cut -f 1)"
} > "$SCRIPT_DIR/tmp/${NOW}_statistics.txt"
#########################################################################################################################
# Converted audiobooks list
if [[ "$CONVERT_DECRYPTONLY" == "true" ]]; then
  my_audiobooks=$(find "$DOWNLOAD_DIR/$NOW" -maxdepth 1 -type f -name '*m4b' | sort)
else 
  my_audiobooks=$(find "$DOWNLOAD_DIR/$NOW" -maxdepth 1 -type f -name '*oga' | sort)
fi
if [[ -n "$my_audiobooks" ]]; then
#########################################################################################################################
# Move converted audiobooks to final destination & delete downloaded files
  if [[ "$DEBUG_SKIPMOVEBOOKS" != "true" ]]; then
    echo ">>> Moving & renaming audiobooks to: $DEST_BASE_DIR"
    while read -r audiobook; do
      echo ">>> Moving $audiobook"
      declare -A move_metadata
      # Publish metadata into array
      [[ "$DEBUG_METADATA" == "true" ]] && echo "### DEBUG: move_metadata = ${move_metadata[*]}"
      while IFS='=' read -r key value; do
        # Clean author metadata (authors & translator)
        [[ "$DEBUG_METADATA" == "true" ]] && echo "### DEBUG: $key = $value"
        if [[ "${key,,}" == "artist" ]]; then
          move_metadata["${key,,}"]=$(metadata_clean_authors "${value}" ' ; ')
        else
          move_metadata["${key,,}"]="${value//\//-}"
        fi
      done < <(ffprobe -v quiet -print_format default -show_format -show_streams -select_streams a -i "$audiobook" | grep TAG | sed 's/^TAG://')
      # Skip if asin in local db
      if [[ "$SKIP_IFIN_LOCAL_DB" == "true" ]] && grep -q -m1 "${move_metadata[asin]}" "$LOCAL_DB"; then
        echo "=== ASIN already in personal library, skipping move files..."
        unset move_metadata
        continue
      fi
      # Build target directory path
      dir=()
      for metaname in "${DEST_DIR_NAMING_SCHEME_AUDIOBOOK[@]}"; do
        [[ -n "${move_metadata["$metaname"]}" ]] && dir+=("${move_metadata["$metaname"]}")
      done
      # Build target book directory
      bookdir=$(build_string_from_scheme DEST_BOOKDIR_NAMING_SCHEME_AUDIOBOOK move_metadata)
      dir+=("$bookdir")
      # Build target book file name
      bookfilename=$(build_string_from_scheme DEST_BOOK_NAMING_SCHEME_AUDIOBOOK move_metadata)
      # Full directory path
      IFS="/"
      dest_dir="${DEST_BASE_DIR}/${dir[*]}"
      unset IFS
      # If destination directory exists
      if [[ -d "$dest_dir" ]]; then
        case "$DEST_DIR_OVERWRITE" in
          # Default behavior: overwrite existing preserving files other than the copied ones
          "true" | "ignore") ;;
          # Remove & recreate directory
          "remove")
            # Remove existing target directory
            if ! remove_file "$dest_dir"; then
              echo "=== ERROR: Cannot remove '$dest_dir', audiobook skipped."
              continue
            fi ;;
          # Create incremental directory
          "keep")
            idx=1
            while [ -d "${dest_dir} (${idx})" ]; do
              idx=$((idx + 1))
            done
            dest_dir="${dest_dir} (${idx})" ;;
          # Skip current audiobook files
          "false" | *) continue ;;
        esac
      fi
      mkdir -p "$dest_dir"
      move_files "$audiobook" "$dest_dir" "$bookfilename"
      # Update local db (tmp)
      if ! grep -q -m1 "${move_metadata[asin]}" "$LOCAL_DB"; then
        awk -v asin="${move_metadata[asin]}" -v dest="$dest_dir" -F'\t' ' BEGIN { OFS = FS }
          { gsub(/\r/, "") }
          $0 ~ asin { $0 = $0 FS dest
            print $0
        }' "$HIST_LIB_DIR/${NOW}_library_new.tsv" >> "$SCRIPT_DIR/tmp/${NOW}_local_db.tsv"
      fi
      # Clear local metadata
      unset move_metadata
      # Keep downloads
      if [[ "$KEEP_DOWNLOADS" == "false" ]]; then
        tmptmp=$(basename "$audiobook")
        tmp_asin=${tmptmp%%_*}
        [[ "$DEBUG" == "true" ]] && echo "### DEBUG Delete => $(dirname "$audiobook")/${tmp_asin}*"
        cd "$(dirname "$audiobook")" && rm -f "${tmp_asin}"*
        cd "$SCRIPT_DIR" || { echo "=== ERROR Cannot cd back to script directory"; exit 255; }
      fi
    done <<< "$my_audiobooks"
    # Update local db
    cat "$SCRIPT_DIR/tmp/${NOW}_local_db.tsv" >> "$LOCAL_DB"
  else
    [[ "$DEBUG" == "true" ]] && echo "### DEBUG MOVE & RENAME AUDIOBOOKS SKIPPED"
  fi
  [[ "$DEBUG" == "true" ]] && tree "${DEST_BASE_DIR}"
#########################################################################################################################
# End move & rename audiobooks
else
  echo ">>> No audiobooks to move."
fi
#########################################################################################################################
# Show statistics
echo ">>> Basic statistics"
if [[ -f "$SCRIPT_DIR/tmp/${NOW}_statistics.txt" ]]; then
  cat "$SCRIPT_DIR/tmp/${NOW}_statistics.txt"
  echo "> Total moved OGA:       $(wc -l "$SCRIPT_DIR/tmp/${NOW}_local_db.tsv" 2>/dev/null | cut -f 1 -d ' ')"
else
  echo "=== Statistics file not found."
fi
#########################################################################################################################
# Remove logs
[[ "$CLEAN_TMPLOGS" == "true" ]] && rm -f "$SCRIPT_DIR/tmp/${NOW}"_*

