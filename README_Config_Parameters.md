BALD Configuration Parameters
=============================

**Make sure you read all setting descriptions and usage.**

Change the variables in the script section **User config** according to your needs.

**All the parameters MUST have a value set** (there is only basic validation).

You can avoid to change settings in the script itself by creating a file named `myconfig` and put all the settings in it. The script will load this file if it exists, otherwise it will use default values from script itself.
`myconfig` file takes precedence over internal settings.

Table of content
================
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=3 orderedList=false} -->
<!-- code_chunk_output -->

- [Script main settings](#script-main-settings)
  - [AUDIBLECLI_PROFILE](#audiblecli_profile)
  - [HIST_LIB_DIR](#hist_lib_dir)
  - [HIST_FULL_LIB](#hist_full_lib)
  - [STATUS_FILE](#status_file)
  - [LOCAL_DB](#local_db)
  - [SKIP_IFIN_LOCAL_DB](#skip_ifin_local_db)
- [Download settings](#download-settings)
  - [DOWNLOAD_PDF](#download_pdf)
  - [DOWNLOAD_ANNOT](#download_annot)
  - [DOWNLOAD_COVERS](#download_covers)
  - [DOWNLOAD_COVERS_SIZE](#download_covers_size)
  - [DOWNLOAD_WISHLIST](#download_wishlist)
  - [DOWNLOAD_JOBS](#download_jobs)
  - [DOWNLOAD_RETRIES](#download_retries)
  - [DOWNLOAD_DIR](#download_dir)
  - [DOWNLOAD_CLEAN_EMPTY_DIRS](#download_clean_empty_dirs)
  - [DOWNLOAD_AAX_OPTS](#download_aax_opts)
- [Metadata related settings](#metadata-related-settings)
  - [METADATA_PARALLEL](#metadata_parallel)
  - [METADATA_SOURCE](#metadata_source)
  - [METADATA_TIKA](#metadata_tika)
  - [METADATA_CLEAN_AUTHOR_PATTERN](#metadata_clean_author_pattern)
  - [METADATA_SINGLENAME_AUTHORS](#metadata_singlename_authors)
  - [METADATA_SKIP_IFEXISTS](#metadata_skip_ifexists)
  - [METADATA_CHAPTERS](#metadata_chapters)
- [Conversion settings](#conversion-settings)
  - [CONVERT_CONTAINER](#convert_container)
  - [CONVERT_BITRATE](#convert_bitrate)
  - [CONVERT_BITRATE_RATIO](#convert_bitrate_ratio)
  - [CONVERT_CBRVBR](#convert_cbrvbr)
  - [CONVERT_PARALLEL](#convert_parallel)
  - [CONVERT_SKIP_IFOGAEXISTS](#convert_skip_ifogaexists)
  - [CONVERT_SKIP_IFM4BEXISTS](#convert_skip_ifm4bexists)
  - [CONVERT_DECRYPTONLY](#convert_decryptonly)
  - [CONVERT_DECRYPTONLY_WITHMETA](#convert_decryptonly_withmeta)
- [File move settings](#file-move-settings)
  - [Available keys for the naming schemes](#available-keys-for-the-naming-schemes)
  - [DEST_BASE_DIR](#dest_base_dir)
  - [DEST_DIR_NAMING_SCHEME_AUDIOBOOK](#dest_dir_naming_scheme_audiobook)
  - [DEST_BOOKDIR_NAMING_SCHEME_AUDIOBOOK](#dest_bookdir_naming_scheme_audiobook)
  - [DEST_BOOK_NAMING_SCHEME_AUDIOBOOK](#dest_book_naming_scheme_audiobook)
  - [DEST_DIR_OVERWRITE](#dest_dir_overwrite)
  - [DEST_COPY_COVER](#dest_copy_cover)
  - [DEST_COPY_PDF](#dest_copy_pdf)
  - [DEST_COPY_CHAPTERS_FILE](#dest_copy_chapters_file)
  - [DEST_COPY_ANNOT_FILE](#dest_copy_annot_file)
  - [CLEAN_TMPLOGS](#clean_tmplogs)
  - [KEEP_DOWNLOADS](#keep_downloads)
- [Debug settings](#debug-settings)
  - [Main debug flags](#main-debug-flags)
    - [DEBUG](#debug)
    - [DEBUG_REPEAT_LAST_RUN](#debug_repeat_last_run)
    - [DEBUG_DONT_UPDATE_LASTRUN](#debug_dont_update_lastrun)
    - [DEBUG_STEP](#debug_step)
    - [DEBUG_SKIPDOWNLOADS](#debug_skipdownloads)
    - [DEBUG_SKIPBOOKCONVERT](#debug_skipbookconvert)
    - [DEBUG_SKIPBOOKMETADATA](#debug_skipbookmetadata)
    - [DEBUG_SKIPMOVEBOOKS](#debug_skipmovebooks)
    - [DEBUG_DONTEMBEDCOVER](#debug_dontembedcover)
    - [DEBUG_METADATA](#debug_metadata)
  - [Audiobook debug samples](#audiobook-debug-samples)
    - [DEBUG_USEAAXSAMPLE](#debug_useaaxsample)
    - [DEBUG_USEAAXCSAMPLE](#debug_useaaxcsample)

<!-- /code_chunk_output -->

# Script main settings

## AUDIBLECLI_PROFILE

This variable holds the profile name created with `audible-cli`.
It should match one of the existing JSON file in `~/audible/`

> **Example config (`~/audible/myprofile.json`):**  
> `AUDIBLECLI_PROFILE=myprofile`

## HIST_LIB_DIR

Location of the downloaded library history files. Those files are TSV files containing your entire list of Audiobooks (and Podcasts) and delta TSV files.

> **Snapshot of what it looks:**
> ```
> 2024-02-01_library_full.tsv
> 2024-02-01_library_new.tsv
> 2024-03-01_library_full.tsv
> 2024-03-01_library_new.tsv
> 2024-04-01_library_full.tsv
> ```

> **Example config:**  
> `HIST_LIB_DIR=$HOME/Audible/lib_history`

## HIST_FULL_LIB

This flag allows to download the full history TSV file of your Audible library each time the script is run.
If you run the script every day I recommend disabling it. If you run every week or month then you can keep it to 'true'.

Allowed values:  
- 'true'  
- 'false' or anything else

> **Example config:**  
> `HIST_FULL_LIB=true`

> **Note:**
> This setting is ignored when using the container. You MUST use volume mapping instead.

## STATUS_FILE

This is the full path and filename where the script stores the two last execution times.
The next run will use the last execution time to download only new audiobooks.
**If you want to force a full sync, delete the file and run again.**

The status file stores the complete date of the script's last execution (the date is formulated as `+%Y-%m-%d`).

> **Example config:**  
> `STATUS_FILE=$HOME/Audible/audible_last_sync`

> **Note:**
> This setting is ignored when using the container. You MUST use volume mapping instead.

## LOCAL_DB

This is the file location where is stored all information about the audiobooks moved to your personal library.

> **Example config:**  
> `LOCAL_DB=$HOME/Audible/personal_library.tsv`

## SKIP_IFIN_LOCAL_DB

This flag tells the script to skip any kind of processing (download / metadata / conversion & file move) if the Audiobook is found in personal library.

> **Example config:**  
> `SKIP_IFIN_LOCAL_DB=true`

# Download settings

## DOWNLOAD_PDF

This flag allows downloading companion PDF file for each audiobook (if there is any).

Allowed values:  
- 'true'  
- 'false' or anything else

> **Example config:**  
> `DOWNLOAD_PDF=true`

## DOWNLOAD_ANNOT

This flag allows downloading annotations (bookmarks) for each audiobook (if there is any).

Allowed values:  
- 'true'  
- 'false' or anything else

> **Example config:**  
> `DOWNLOAD_ANNOT=true`

## DOWNLOAD_COVERS

This flag allows downloading art covers for each audiobook.

Allowed values:  
- 'true'  
- 'false' or anything else

> **Example config:**  
> `DOWNLOAD_COVERS=true`

## DOWNLOAD_COVERS_SIZE

This parameter allows to specify the cover sizes to download for each audiobook. Multiple values are allowed.
500 seems the default size for every Audible audiobooks.

Allowed values, any mix of the following:  
252 315 360 408 500 558 570 882 900 1215

> **Example config:**  
> `DOWNLOAD_COVERS_SIZE=(500 1215)`

## DOWNLOAD_WISHLIST

This flag allows to download your Audible account wishlist.

Allowed values:  
- 'true'  
- 'false' or anything else

> **Example config:**  
> `DOWNLOAD_WISHLIST=false`

## DOWNLOAD_JOBS

This setting is the concurrency level during Audiobook download. At this moment it doesn't do much because all audiobooks are not downloaded in parallel because of an issue with `audible-cli` (<https://github.com/mkb79/audible-cli/issues/218>)

It sets the parallel level inside `audible-cli` (for example it parallelizes download of covers, AXX, annotations for a single audiobook).

> **Example config:**  
> `DOWNLOAD_JOBS=2`

## DOWNLOAD_RETRIES

Numbers of retries if a download fails.
Careful of not hammering Amazon servers by keeping this setting low as there is no cooldown in the script.

> **Example config:**  
> `DOWNLOAD_RETRIES=3`

## DOWNLOAD_DIR

AAX & AAXC Audible files will be downloaded here

> **Example config:**  
> `DOWNLOAD_DIR=$HOME/Audible/MyDownloads`

> **Note:**
> This setting is ignored when using the container. You MUST use volume mapping instead.

## DOWNLOAD_CLEAN_EMPTY_DIRS

Tells the script to clean all empty download directories if any. This is pretty useful if you run the script daily and do not want to keep the empty directories.

Allowed values:  
- 'true' => Delete empty directories (default behavior)
- 'false' or anything else => Keep all created download directories

> **Example config:**  
> `DOWNLOAD_CLEAN_EMPTY_DIRS=true`

## DOWNLOAD_AAX_OPTS

This setting allow to force the download option during audiobook download.

Allowed values:
| Value          | Description                                                                   |
|----------------|-------------------------------------------------------------------------------|
| --aax-fallback | Download book in aax format and fallback to aaxc, if former is not supported. |
| --aax          | Download book in aax format.                                                  |
| --aaxc         | Download book in aaxc format incl. voucher file.                              |

> **Example config:**  
> `DOWNLOAD_AAX_OPTS=--aax-fallback`

# Metadata related settings

## METADATA_PARALLEL

Parallelization setting for metadata processing. This parameter allows the user to specify the number of jobs for metadata extraction.

Allowed values: any number >= 1

> **Example config:**  
> `METADATA_PARALLEL=3`

## METADATA_SOURCE

This setting allow to specify the source of metadata. It can be `aax`, meaning that only metadata from AAX/AAXC files will be considered, or `all` which means metadata will be fetched from original AAX/AAXC files, but also from `mediainfo` tool extraction, and finally also from library file.

Allowed values:  
- 'aax'  
- 'all'

> **Example config:**  
> `METADATA_SOURCE=all`

## METADATA_TIKA

Use Tika for language detection if title description/comments is long enough.

**(slow)** For local java execution, the jar file **must be** in the same directory of this script.

**(faster)** For remote execution, just put the URL of your Tika server.

Allowed values:  
 - Full path of jar file name  
 - HTTP URL of Tika server

> **Example config:**  
> `METADATA_TIKA=tika-app-2.9.2.jar`

> **Example config:**  
>  `METADATA_TIKA=http://mytikahost:9998`

## METADATA_CLEAN_AUTHOR_PATTERN

I noticed that author/narrators metadata was not always clean, so I added a pattern matching. If you want to remove all authors that match this regex, set it here.  
The script first split author between ',' and then remove all authors that match this regex (*this is a non-case-sensitive regex match*).  
Basically any authors/narrators matching any of the regex words will be removed from the list.
This applies also to narrators.

Allowed values: regex string  
- '*' => keep all authors  
- 'traducteur|traductrice|editeur|editrice' => remove all authors matching any of these words

> **Example config:**  
> `METADATA_CLEAN_AUTHOR_PATTERN='traducteur|traductrice|editeur|editrice|editor|illustrateur|éditeur|éditrice'`

## METADATA_SINGLENAME_AUTHORS

If an audiobook has multiple authors, this flag allows the script to discard all authors that are identified by a single word name (like pseudo/nicknames/etc.).  
This setting is ignored if there is only a single author.  
This applies also to narrators.

> **Note:** This was a dirty workaround to bad AudioBookShelf metadata parser. But it gets fixed.

Allowed values:  
- 'true' or anything else => Keep single name authors
- 'false' => Discard single name authors

> **Example config:**  
> `METADATA_SINGLENAME_AUTHORS=false`

## METADATA_SKIP_IFEXISTS

This flag allows the script to skip current metadata processing if the final metadata final is already present.

Allowed values:  
- 'true'
- 'false'

> **Example config (default value):**  
> `METADATA_SKIP_IFEXISTS=false`

## METADATA_CHAPTERS

Behavior of the script while processing audiobook chapters.

Possible values are:
- 'keep' => do not modify chapters, keep the chapters defined in the AAX/AAXC files
- 'updatetitles' => only try to update chapter titles with the python helper script
- 'rebuild' => fully rebuild all the chapters based on Audible chapters.json file

> **Example config (default value):**  
> `METADATA_CHAPTERS=rebuild`

# Conversion settings

## CONVERT_CONTAINER

This parameter allows the user to select the output format of the converted audiobooks.

Allowed values:  
- OGG => Convert audiobooks to OGA files
- MP4 => Convert audiobooks to M4B files

> **Example config:**  
> `CONVERT_CONTAINER=OGG`

## CONVERT_BITRATE

This parameter sets the target bit rate of the converted file.
Lower bit rates mean smaller sizes but also lower quality.

Allowed values: any string that can be parsed by `ffmpeg` (ex: 96k, 128k, etc.)

> **Example config:**  
> `CONVERT_BITRATE=96k`

## CONVERT_BITRATE_RATIO

This setting delegates to the script the calculation of the target bitrates of all converted files.

Allowed values:  
- 'false' => disable this feature and use only fixed bitrate
- or a ratio like 1/2, 1/3, 2/3 etc.... 

> **Example config:**  
> `CONVERT_BITRATE_RATIO=2/3`

## CONVERT_CBRVBR

This parameter allows the user to select VBR or CBR for the final encoding.
OGG and MP4 containers accepts different values.

Allowed values:

For OGG container:
| Allowed value | Description               |
|---------------|---------------------------|
| cbr           | Constant bitrate encoding |
| vbr           | Variable bitrate encoding |

For MP4 container:
| Allowed value                       | Description                                                   |
|-------------------------------------|---------------------------------------------------------------|
| cbr                                 | Constant bitrate encoding                                     |
| any decimal value between 0.1 and 2 | Variable bitrate encoding (higher value means higher quality) |

> **Example config (for OGG container):**  
> `CONVERT_CBRVBR=vbr`

> **Example config (for MP4 container):**  
> `CONVERT_CBRVBR=cbr`

## CONVERT_PARALLEL

Parallelization setting for file conversion. This parameter allows the user to specify the number of jobs for audiobook conversion.
This is entirely independent of METADATA_PARALLEL.

Optimal setting depends on how many cores and memory you have. Usually `ffmpeg` takes 1 to 2 threads and ~800 MB of memory per encoding process.

Allowed values: any number >= 1

> **Example config:**  
> `CONVERT_PARALLEL=3`

## CONVERT_SKIP_IFOGAEXISTS

If an audiobook was previously converted to OGA but not moved to target library, it may be still present in download directory, this flag tells the script to skip conversion of such Audiobooks.  
This setting is only valid when you select OGG as container.

Allowed values:  
- 'true'  
- 'false' or anything else

> **Example config:**  
> `CONVERT_SKIP_IFOGAEXISTS=false`

## CONVERT_SKIP_IFM4BEXISTS

If an audiobook was previously converted to M4B but not moved to target library, it may be still present in download directory, this flag tells the script to skip conversion of such Audiobooks.  
This setting is only valid when you select MP4 as container.

Allowed values:  
- 'true'  
- 'false' or anything else

> **Example config:**  
> `CONVERT_SKIP_IFM4BEXISTS=false`

## CONVERT_DECRYPTONLY

This flag allows only decrypt AAX/AAXC when using MP4 container, it also overrides all bitrate options.
It also requires `CONVERT_CONTAINER=MP4`.

Allowed values:  
- 'true'  
- 'false' or anything else

> **Example config:**  
> `CONVERT_DECRYPTONLY=false`

## CONVERT_DECRYPTONLY_WITHMETA

When using CONVERT_DECRYPTONLY option, this parameter tells the script to add full metadata in the decrypted file.

Allowed values:  
- 'true'  
- 'false' or anything else

> **Example config:**  
> `CONVERT_DECRYPTONLY_WITHMETA=true`

# File move settings

## Available keys for the naming schemes

| Key           | Description |
|---------------|-------------|
| title         | audiobook title |
| album         | audiobook title |
| subtitle      | audiobook subtitle |
| year          | publish year |
| lang          | language country code (e.g.: en, de, fr, etc.) |
| language      | language country code (e.g.: en, de, fr, etc.) |
| genre         | genre list (should not be used in any scheme) |
| artist        | author |
| album_artist  | author |
| composer      | narrator |
| asin          | ASIN |
| audible_asin  | ASIN |
| copyright     | Copyright text (should not be used in any scheme) |
| publisher     | publisher (not relevant in any naming scheme) |
| comment       | long description of the audiobooks (should not be used in any scheme) |
| series        | Series name |
| mvnm          | Series name |
| series-part   | Series volume |
| mvin          | Series volume |

It is recommended to stick with the following ones:  
 - title  
 - subtitle  
 - lang  
 - artist  
 - asin  
 - series  
 - series-part

In short the script will produce dynamic directory names based on metadata and aggregated based on user settings.

*Directory as follows:*
`DEST_BASE_DIR + DEST_DIR_NAMING_SCHEME_AUDIOBOOK + DEST_BOOKDIR_NAMING_SCHEME_AUDIOBOOK`

*Audiobook filename:*
`DEST_BOOK_NAMING_SCHEME_AUDIOBOOK`

**These settings can be confusing pay attention to the parameter names!**

## DEST_BASE_DIR

Base directory for converted files (will be created if it doesn't exist).
If you want your converted files in a different location, change this setting.

> **Example config:**  
> `DEST_BASE_DIR=$HOME/AudioBookShelf/audiobooks`

> **Note:**
> This setting is ignored when using the container. You MUST use volume mapping instead.

## DEST_DIR_NAMING_SCHEME_AUDIOBOOK

Directory path for audiobooks, it will be created under [DEST_BASE_DIR](#dest_base_dir).

*Example:* `(artist series)` will produce `/Isaac Asimov/Foundation`.

Keep the keys inside parentheses. If a key is non-existent for an audiobook then it's ignored.

To have only one directory per audiobook then use empty value like `()` and look for next parameter to configure the naming scheme of the audiobook directory.

Allowed values:  
 - any combination of [the available keys](#available-keys-for-the-naming-schemes)  
 - or empty ()

> **Example config will produce /artists/series directory:**  
> `DEST_DIR_NAMING_SCHEME_AUDIOBOOK=(artist series)`

## DEST_BOOKDIR_NAMING_SCHEME_AUDIOBOOK

Audiobook DIRECTORY naming scheme (**cannot be empty**).

This is the directory where the audiobook will be moved, it is created under [DEST_DIR_NAMING_SCHEME_AUDIOBOOK](#dest_dir_naming_scheme_audiobook).

Use `"%string"` to insert custom text in the file name example: `(series-part "% - " title)` will produce a directory named `1 - audiobook_title`.

Custom string parameters are ignored if they are in the start of the naming scheme, in previous example `(series-part "% - " title)` if 'series-part' is not defined for an audiobook then only 'title' will be used.

Keep the keys inside parentheses.

Allowed values:  
 - any combination of [the available keys](#available-keys-for-the-naming-schemes)  
 - and custom user strings starting with '%' (example: '% - ')

> **Example config:**  
> `DEST_BOOKDIR_NAMING_SCHEME_AUDIOBOOK=(series-part "% - " title)`

## DEST_BOOK_NAMING_SCHEME_AUDIOBOOK

Audiobook FILE naming scheme (**cannot be empty**).

Use `"%string"` to insert custom text in the file name example: `(series-part "% - " title)`.

The same rules apply here as in [DEST_BOOKDIR_NAMING_SCHEME_AUDIOBOOK](#dest_bookdir_naming_scheme_audiobook).

Allowed values:  
 - any combination of [the available keys](#available-keys-for-the-naming-schemes)  
 - and custom user strings starting with '%' (example: '% - ')

> **Example config:**  
> `DEST_BOOK_NAMING_SCHEME_AUDIOBOOK=(title)`

## DEST_DIR_OVERWRITE

Destination directory overwrite mode (**cannot be empty**)

Allowed values:  
 - **'true' or 'ignore'**: If audiobook destination directory exists then overwrite files in it, other files in directory are preserved  
 - **'remove'**: If audiobook destination directory exists then remove it and recreate it (all existing files in it will be deleted)  
 - **'keep'**: If audiobook destination directory exists then create a new one with an incremental suffix  
 - **'false' or any other value**: If audiobook destination directory exists then skip processing to next audiobook

> **Example config:**  
> `DEST_DIR_OVERWRITE=true`

## DEST_COPY_COVER

This flag allows the user to specify if cover image should be copied to audiobook destination directory.
If the flag is set then a copy of the largest cover will be created in the audiobook destination directory.
Does nothing if no covers are found.

Allowed values:  
- 'true'  
- 'false' or anything else

> **Example config:**  
> `DEST_COPY_COVER=true`

## DEST_COPY_PDF

This flag allows the user to specify if PDF should be copied to audiobook destination directory.
Does nothing if no PDF exists.

Allowed values:  
- 'true'  
- 'false' or anything else

> **Example config:**  
> `DEST_COPY_PDF=true`

## DEST_COPY_CHAPTERS_FILE

This flag allows the user to specify if JSON chapters file should be copied to audiobook destination directory.
Does nothing if no PDF exists.

Allowed values:  
- 'true'  
- 'false' or anything else

> **Example config:**  
> `DEST_COPY_CHAPTERS_FILE=true`

## DEST_COPY_ANNOT_FILE

This flag allows the user to specify if JSON annotations/bookmarks file should be copied to audiobook destination directory.
Does nothing if no PDF exists.

Allowed values:  
- 'true'  
- 'false' or anything else

> **Example config:**  
> `DEST_COPY_ANNOT_FILE=true`

## CLEAN_TMPLOGS

Delete logs generated during the current run (old ones are kept)
It is safe to keep to 'true'

Allowed values:  
- 'true'  
- 'false' or anything else

> **Example config:**  
> `CLEAN_TMPLOGS=true`

## KEEP_DOWNLOADS

This flag allows the script to delete downloaded files once they are converted and pushed to final target directory.

Only converted files may be deleted, not converted audiobook remaining are not deleted. 

Allowed values:  
- 'true' or anything else => Keep downloaded files.  
- 'false' => Deleted only files that have been converted

> **Example config:**  
> `KEEP_DOWNLOADS=true`

# Debug settings

Parameters below are for debugging purposes (**default for all boolean parameters is 'false'**).

Keep all settings below to `false` for normal behavior.

## Main debug flags

### DEBUG

Global debug flag, also change behavior while moving files to target directory, instead files are copied.

Allowed values:  
- 'true'  
- 'false' or anything else

> **Example config:**  
> `DEBUG=false`

### DEBUG_REPEAT_LAST_RUN

This flag is used to repeat the last run without updating the [STATUS_FILE](#status_file).

Allowed values:  
- 'true'  
- 'false' or anything else

> **Example config:**  
> `DEBUG_REPEAT_LAST_RUN=false`

### DEBUG_DONT_UPDATE_LASTRUN

Flag to tell if the script should update the [STATUS_FILE](#status_file).
This is handy if you want to run a script multiple times for debugging purposes.

Allowed values:  
- 'true'  
- 'false' or anything else

> **Example config:**  
> `DEBUG_DONT_UPDATE_LASTRUN=false`

### DEBUG_STEP

When DEBUG is enabled and STATUS_FILE contains an old date, this setting only increments the STATUS_FILE date with the specified period of time.
This allows manual stepped runs over specified time periods.
Requires [STATUS_FILE](#status_file) exists and populated.

Allowed values:  
- '1 month'  
- '2 week'  
- '4 days'  
- any time period understood by 'date' console command

> **Example config:**  
>  `DEBUG_STEP="1 month"`

### DEBUG_SKIPDOWNLOADS

This flag disables all Audible downloads for the current run.
If other parts of the scripts are enabled then the scripts expect to find the correct download folder with all the required files in it.

Allowed values:  
 - 'true' => Disable ALL downloads  
 - 'false' or any other value => normal behavior

> **Example config:**  
> `DEBUG_SKIPDOWNLOADS=false`

### DEBUG_SKIPBOOKCONVERT

This flag disables all audiobook conversions for the current run.
If other parts of the scripts are enabled then the scripts expect to find the correct download folder with all the required files in it.

Allowed values:  
 - 'true' => disable audiobook conversion  
 - 'false' or any other value => normal behavior

> **Example config:**  
> `DEBUG_SKIPBOOKCONVERT=false`

### DEBUG_SKIPBOOKMETADATA

This flag disables all audiobook metadata gathering for the current run.
If other parts of the scripts are enabled then the scripts expect to find the correct download folder with all the required files in it.

Allowed values:  
 - 'true' => disable metadata gathering for audiobooks  
 - 'false' or any other value => normal behavior

> **Example config:**  
> `DEBUG_SKIPBOOKMETADATA=false`

### DEBUG_SKIPMOVEBOOKS

This flag disables the last part of the script and no file will be moved to destination directory for the current run.

Allowed values:  
 - 'true' => disable moving audiobooks  
 - 'false' or any other value => normal behavior

> **Example config:**  
> `DEBUG_SKIPMOVEBOOKS=false`

### DEBUG_DONTEMBEDCOVER

This flag, if enabled, prevents the art cover file to be embedded in the converted audiobook.
It does not prevent the copy of the cover JPG file into destination directory (use this instead [DEST_COPY_COVER](#dest_copy_cover)).

Allowed values:  
 - 'true' => disable moving audiobooks  
 - 'false' or any other value => normal behavior

> **Example config:**  
> `DEBUG_DONTEMBEDCOVER=false`

### DEBUG_METADATA

This flag allows more detailed debug output of metadata to be print during script execution.
It also allows you to create a debug file with all the metadata extracted by `ffprobe` for each converted file.

Allowed values:  
 - 'true' => disable moving audiobooks  
 - 'false' or any other value => normal behavior

> **Example config:**  
> `DEBUG_METADATA=false`

## Audiobook debug samples

Debug samples are small AAX and AAXC files that will be used during audiobook conversions instead of using big original files.
The metadata is still fetched from the original files and inserted in converted samples.

It is recommended to take the smallest AAX and the smallest AAXC files + voucher.

### DEBUG_USEAAXSAMPLE

Full path and file name of the AAX sample file. The file must come from your own Audible account or the script will not be able to process it.

Allowed values:  
 - `sample.aax` => file name (must be in BALD directory)  
 - 'false' => normal behavior

> **Example config:**  
> `DEBUG_USEAAXSAMPLE=sample.aax`

> **Note:**
> This setting is ignored when using the container. You MUST use volume mapping instead.

### DEBUG_USEAAXCSAMPLE

File name of the AAXC sample file. The file must come from your own Audible account or the script will not be able to process it.
Do not forget to put aside the voucher file for it.

Allowed values:  
 - `sample.aaxc` => file name (must be in BALD directory)  
 - 'false' => normal behavior

> **Example config:**  
> `DEBUG_USEAAXCSAMPLE=sample.aaxc`

> **Note:**
> This setting is ignored when using the container. You MUST use volume mapping instead.
