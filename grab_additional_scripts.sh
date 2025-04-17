#!/usr/bin/env bash
#
# MIT License
# Copyright (c) [2025] [damajor @ <https://github.com/damajor/BALD>]
#

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)


if [[ ! -f "$SCRIPT_DIR"/myconfig ]]; then
  echo ">>> Creating myconfig file with default parameters..."
  echo "### PUT YOUR SETTING PARAMETERS HERE ###" > "$SCRIPT_DIR"/myconfig
                                                                                                                          # TODO CHANGE NAME
  sed -n "/#### User config/,/#### End of user config/ {/#### User config/b;/#### End of user config/b;p}" "$SCRIPT_DIR"/BALD.sh >> "$SCRIPT_DIR"/myconfig
fi

if [ ! -f "$SCRIPT_DIR/ogg-image-blobber.sh" ]; then
  echo ">>> Downloading ogg-image-blobber.sh"
  curl -o "$SCRIPT_DIR"/ogg-image-blobber.sh \
    https://raw.githubusercontent.com/twopoint71/ogg-image-blobber/refs/heads/master/ogg-image-blobber.sh
  chmod +x "$SCRIPT_DIR"/ogg-image-blobber.sh
fi

if [ ! -f "$SCRIPT_DIR/update_chapter_titles.py" ]; then
  echo ">>> Downloading update_chapter_titles.py"
  curl -o "$SCRIPT_DIR"/update_chapter_titles.py \
    https://raw.githubusercontent.com/mkb79/audible-cli/refs/heads/master/utils/update_chapter_titles.py
fi

if [[ ! -f "$(find "$SCRIPT_DIR" -name 'tika-app-*.jar')" ]]; then
  echo ">>> Downloading Apache Tika jar"
  curl -o "$SCRIPT_DIR"/tika-app-2.9.3.jar \
    https://dlcdn.apache.org/tika/2.9.3/tika-app-2.9.3.jar
fi
