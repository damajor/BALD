BALD Encoding Options Examples
==============================

Table of content
================
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=3 orderedList=true} -->
<!-- code_chunk_output -->

1. [For the impatient](#for-the-impatient)
2. [All encoding options](#all-encoding-options)
3. [OGG Encoding with dynamic bitrate downsizing](#ogg-encoding-with-dynamic-bitrate-downsizing)
4. [OGG Encoding with fixed bitrate](#ogg-encoding-with-fixed-bitrate)
5. [MP4 Decrypt only (fastest processing)](#mp4-decrypt-only-fastest-processing)
6. [MP4 Encoding (for iPhone / iPad etc.)](#mp4-encoding-for-iphone--ipad-etc)

<!-- /code_chunk_output -->

# For the impatient

- For users who want to save disk space [OGG Encoding](#ogg-encoding-with-dynamic-bitrate-downsizing)
- For iPad / iPhone users who cannot play OGG and want to save space [MP4 AAC Compression](#mp4-encoding-for-iphone--ipad-etc)
- Fastest conversion [MP4 Decrypt Only](#mp4-decrypt-only-fastest-processing)

# All encoding options

```
CONVERT_CONTAINER
CONVERT_BITRATE
CONVERT_BITRATE_RATIO
CONVERT_CBRVBR
CONVERT_DECRYPTONLY
CONVERT_DECRYPTONLY_WITHMETA
```

Check details here [Conversion Settings in README_Config_Parameters.md](README_Config_Parameters.md#conversion-settings).

# OGG Encoding with dynamic bitrate downsizing

The following settings will produce OGA audiobooks, reducing the bitrate by a factor of 2/3 and so approximatively reducing final audiobook size by 1/3.

```
CONVERT_CONTAINER=OGG
CONVERT_BITRATE_RATIO=2/3
CONVERT_CBRVBR=vbr
CONVERT_DECRYPTONLY=false
CONVERT_DECRYPTONLY_WITHMETA=false
```

# OGG Encoding with fixed bitrate

The following settings will produce OGA audiobooks, bitrate is fixed to 96k.

```
CONVERT_CONTAINER=OGG
CONVERT_BITRATE=96k
CONVERT_BITRATE_RATIO=false
CONVERT_CBRVBR=vbr
CONVERT_DECRYPTONLY=false
CONVERT_DECRYPTONLY_WITHMETA=false
```

> **Notes:**
> Be careful with fixed bitrate, some original audiobooks may have lower bitrate than the one you specified in the config file, and if that is the case the encoded audiobook will end in bigger file than the original one.  
> It is recommended to use dynamic bitrate setting instead.

# MP4 Decrypt only (fastest processing)

The following settings will only decrypt the original audiobook, add full metadatas and cover.

This is the fastest conversion settings, but the resulting audiobook will have approximatively the same size as the original file.

```
CONVERT_CONTAINER=MP4
CONVERT_DECRYPTONLY=true
CONVERT_DECRYPTONLY_WITHMETA=true
```

# MP4 Encoding (for iPhone / iPad etc.)

These settings will re-encode the original audiobook decreasing bitrate by 1/3.

```
CONVERT_CONTAINER=MP4
CONVERT_BITRATE_RATIO=2/3
CONVERT_CBRVBR=cbr
CONVERT_DECRYPTONLY=false
CONVERT_DECRYPTONLY_WITHMETA=false
```

> **Notes:**
> 
> *Pro:*
> - converted audioboook will be iPad / iPhone compatible
> - some disk space saved
> 
> *Drawbacks:*
> - Re-encoding AAC in MP4 is very slow.
> - ffmpeg AAC encoder is not the best one for quality.