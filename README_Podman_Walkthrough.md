BALD Complete walkthrough for Podman
====================================

This guide will cover full BALD walkthrough on standard Linux with Podman and also on Linux with SELinux enabled (Windows and Ubuntu AppArmor are not a part of this guide).

For Windows Podman please refer to [Podman for Windows](https://github.com/containers/podman/blob/main/docs/tutorials/podman-for-windows.md) (scheduling is on your own).

Table of content
================
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=true} -->
<!-- code_chunk_output -->

1. [Pre-requisites](#pre-requisites)
2. [Preparations](#preparations)
    1. [Directories](#directories)
    2. [Audible CLI setup](#audible-cli-setup)
    3. [Create default BALD configuration file](#create-default-bald-configuration-file)
    4. [Edit common settings](#edit-common-settings)
3. [Run BALD !!!](#run-bald-)
    1. [Foreground run](#foreground-run)
    2. [Background run](#background-run)
4. [Setup automation](#setup-automation)
    1. [Enable user lingering](#enable-user-lingering)
    2. [Create BALD service](#create-bald-service)
    3. [Create BALD timer](#create-bald-timer)
    4. [Update systemd services & enable timer](#update-systemd-services--enable-timer)
5. [Audiobookshelf](#audiobookshelf)
    1. [Preparations](#preparations-1)
    2. [Create Audiobookshelf service](#create-audiobookshelf-service)
    3. [Update systemd services & start Audiobookshelf](#update-systemd-services--start-audiobookshelf)
    4. [Enjoy](#enjoy)

<!-- /code_chunk_output -->

> **General note:**
> 
> This guide will use Podman volume binds as if SELinux is enabled.
> 
> That means all volume bind will be shown as `/path:/container/path:z` or `/path:/container/path:Z`.
> 
> You can check if you have SELinux enabled with the command `getenforce` if the result is `Enforcing` then you have SELinux enabled, if the command is not found or if the result is `Permissive` then SELinux is either missing or disabled.
> 
> If you do not use SELinux you will have to remove the last part of the volume bind (remove `:z` or `:Z`).

# Pre-requisites

- A Linux box/server
- A working internet connection
- A non-root user
- Podman installed

# Preparations

## Directories

BALD requires a bunch of pre-existing files and directory. These are:

| Local                         | Container                   | Type    |
|-------------------------------|-----------------------------|---------|
| History directory             | /audible_history            | dir     |
| BALD Status file              | /status_file                | file    |
| Download directory            | /audible_dl                 | dir     |
| Destination library           | /audiobooks_dest            | dir     |
| Local database                | /BALD/personal_library.tsv  | dir     |
| BALD Config file              | /BALD/myconfig              | file    |
| tmp logs directory            | /BALD/tmp                   | dir     |
| audible-cli config dir        | /root/.audible              | dir     |

We will create a directory to host all of these.

- Base directory:         `mkdir -p /home/YOURUSER/BALD`
- History directory:      `mkdir -p /home/YOURUSER/BALD/audible_history`
- BALD Status file:       `touch /home/YOURUSER/BALD/status_file`
- Download directory:     `mkdir -p /home/YOURUSER/BALD/audible_dl`
- Destination library:    `mkdir -p /home/YOURUSER/Audiobookshelf/audiobooks`
- Local database:         `touch /home/YOURUSER/BALD/personal_library.tsv`
- BALD Config file:       `touch /home/YOURUSER/BALD/myconfig`
- Logs directory:         `mkdir -p /home/YOURUSER/BALD/tmp`
- Audible-cli config dir: `mkdir -p /home/YOURUSER/BALD/audible-cli`

> *For copy/paste convenience:*
> ```
> mkdir -p /home/YOURUSER/BALD
> mkdir -p /home/YOURUSER/BALD/audible_history
> touch /home/YOURUSER/BALD/status_file
> mkdir -p /home/YOURUSER/BALD/audible_dl
> mkdir -p /home/YOURUSER/Audiobookshelf/audiobooks
> touch /home/YOURUSER/BALD/personal_library.tsv
> touch /home/YOURUSER/BALD/myconfig
> mkdir -p /home/YOURUSER/BALD/tmp
> mkdir -p /home/YOURUSER/BALD/audible-cli
> ```

## Audible CLI setup

Run the following command to create a new config file for the audible-cli (this will open an interactive setup):

`podman run -it --rm -v /home/YOURUSER/BALD/audible-cli:/root/.audible quay.io/damajor/bald:latest audible quickstart`

This will bring this interactive message:

```
Welcome to the audible-cli 0.3.2b3 quickstart utility.
=======================================================

Quickstart will guide you through the process of build a basic
config, create a first profile and assign an auth file to the profile now.

The profile created by quickstart will set as primary. It will be used, if no
other profile is chosen.

An auth file can be shared between multiple profiles. Simply enter the name of
an existing auth file when asked about it. Auth files have to be stored in the
config dir. If the auth file doesn't exists, it will be created. In this case,
an authentication to the audible server is necessary to register a new device.

Selected dir to proceed with:
/root/.audible

Please enter values for the following settings (just press Enter to accept a default value, if one is given in brackets).

Please enter a name for your primary profile [audible]:
```

Choose a profile name. I chose `bald`. Then press Enter.

```
Please enter a name for your primary profile [audible]: bald

Enter a country code for the profile:
```

Choose a country code (one of 'de', 'us', 'uk', 'fr', 'ca', 'it', 'au', 'in', 'jp', 'es', 'br'). I chose `us`. Then press Enter.

```
Enter a country code for the profile: us

Please enter a name for the auth file [bald.json]:
```

Just press enter to accept the default value (which is the same as your profile name).

```
Do you want to encrypt the auth file? [y/N]:
```

Choose `n` and then Enter.

```
Do you want to encrypt the auth file? [y/N]: n

Do you want to login with external browser? [y/N]:
```

Choose `y` and then Enter.

```
Do you want to login with external browser? [y/N]: y

Do you want to login with a pre-amazon Audible account? [y/N]:
```

This depends on whether you were using Audible before it was acquired by Amazon. I choose `n`.

```
Do you want to login with a pre-amazon Audible account? [y/N]:

+--------------------+-----------+
| Option             | Value     |
+--------------------+-----------+
| profile_name       | bald      |
| auth_file          | bald.json |
| country_code       | us        |
| auth_file_password | -         |
| audible_username   |           |
| audible_password   | ***       |
+--------------------+-----------+
Do you want to continue? [y/N]:
```

This shows a summary of your choice before going through the authentication.
Choose `y` and then Enter.

```
Login with amazon to your audible account now.
Please copy the following url and insert it into a web browser of your choice:

https://www.amazon.com/ap/signin?openid.oa2.____VERY_LONG_URL____.max_auth_age=0

Now you have to login with your Amazon credentials. After submit your username
and password you have to do this a second time and solving a captcha before
sending the login form.

After login, your browser will show you an error page (Page not found). Do not
worry about this. It has to be like this. Please copy the url from the address
bar in your browser now.

IMPORTANT:
If you are using MacOS and have trouble insert the login result url, simply
import the readline module in your script.

Please insert the copied url (after login):
```

Follow carefully the instructions on screen to get a valid auth file for Audible.

Finish the quick-start process by pressing Enter when asked about it.

## Create default BALD configuration file

Run this command to create a new configuration file with all default settings:

`podman run -it --rm -v /home/YOURUSER/BALD/audible-cli:/root/.audible quay.io/damajor/bald:latest cat /BALD/myconfig > /home/YOURUSER/BALD/myconfig`

## Edit common settings

Open the configuration file `/home/YOURUSER/BALD/myconfig` with your favorite editor and change the following values to match your preferences.

- Use the audible-cli profile name chosen in the previous chapter.

  `AUDIBLECLI_PROFILE=bald`

- Choose between a predefined audio encoding bitrate or a ratio of the original audiobook bitrate.

  - *Predefined bitrate example:*

    `CONVERT_BITRATE=96k`  
    `CONVERT_BITRATE_RATIO=false`

  - *Dynamic bitrate ratio example (reduce the size of the original files by 1/3 approx):*

    `CONVERT_BITRATE_RATIO=2/3`

- The following settings will drive the entire directory structure for the destination library. The default settings seem to fit perfectly with the usage of [Audiobookshelf](https://www.audiobookshelf.org/). Check the main README.md file for a detailed description of these parameters.

  `DEST_DIR_NAMING_SCHEME_AUDIOBOOK=(artist series)`  
  `DEST_BOOKDIR_NAMING_SCHEME_AUDIOBOOK=(series-part "% - " title "% {" composer "%}")`  
  `DEST_BOOK_NAMING_SCHEME_AUDIOBOOK=(title)`

- Choose if you want to keep the original audiobooks file or not. Beware keeping all downloads can take a lot of disk space.

  `KEEP_DOWNLOADS=true`

A lot more settings can be changed or tuned to perfectly match your needs, check the main `README.md` file.

> *Note:* The following `myconfig` settings are ignored as they are managed by mapping podman volumes.
> ```
> HIST_LIB_DIR
> STATUS_FILE
> DOWNLOAD_DIR
> DEST_BASE_DIR
> DEBUG_USEAAXSAMPLE
> DEBUG_USEAAXCSAMPLE
> LOCAL_DB
> ```

# Run BALD !!!

The first run can take a while as BALD will download and convert your entire library, go take a break after starting it :).

Next runs will only download newly added audiobooks.

## Foreground run

Use the following command (*change local paths to match your needs*).

```
podman run -it --rm \
    -v /home/YOURUSER/BALD/audible-cli:/root/.audible:Z \
    -v /home/YOURUSER/BALD/audible_history:/audible_history:Z \
    -v /home/YOURUSER/BALD/status_file:/status_file:Z \
    -v /home/YOURUSER/BALD/audible_dl:/audible_dl:Z \
    -v /home/YOURUSER/BALD/personal_library.tsv:/BALD/personal_library.tsv:Z \
    -v /home/YOURUSER/Audiobookshelf/audiobooks:/audiobooks_dest:z \
    -v /home/YOURUSER/BALD/myconfig:/BALD/myconfig:Z \
    -v /home/YOURUSER/BALD/tmp:/BALD/tmp:Z \
    quay.io/damajor/bald:latest
```

## Background run

```
podman run -d --name bald --rm \
    -v /home/YOURUSER/BALD/audible-cli:/root/.audible:Z \
    -v /home/YOURUSER/BALD/audible_history:/audible_history:Z \
    -v /home/YOURUSER/BALD/status_file:/status_file:Z \
    -v /home/YOURUSER/BALD/audible_dl:/audible_dl:Z \
    -v /home/YOURUSER/BALD/personal_library.tsv:/BALD/personal_library.tsv:Z \
    -v /home/YOURUSER/Audiobookshelf/audiobooks:/audiobooks_dest:z \
    -v /home/YOURUSER/BALD/myconfig:/BALD/myconfig:Z \
    -v /home/YOURUSER/BALD/tmp:/BALD/tmp:Z
    quay.io/damajor/bald:latest
```

To monitor the progress of the process you can run:

`podman logs -f bald`

Once the processing is finished, the container is automatically removed, and you can start it again with the same command.

# Setup automation

Automation is handled by systemd.

## Enable user lingering

As `root` run this command (replace `YOURUSER` with your username):

`loginctl enable-linger YOURUSER`

This will enable systemd to start services defined for your user.

## Create BALD service

Create a file `/home/YOURUSER/.config/containers/systemd/bald.container` with the content below. Update the paths and the timezone to your personal preferences.

```
[Unit]
Description=Podman BALD

[Install]

[Service]
Restart=no
Type=oneshot

[Container]
Image=quay.io/damajor/bald:latest
ContainerName=bald
HostName=bald
AutoUpdate=registry
LogDriver=passthrough
Volume=/home/YOURUSER/BALD/audible_history:/audible_history:Z
Volume=/home/YOURUSER/BALD/status_file:/status_file:Z
Volume=/home/YOURUSER/BALD/audible_dl:/audible_dl:Z
Volume=/home/YOURUSER/Audiobookshelf/audiobooks:/audiobooks_dest:z
Volume=/home/YOURUSER/BALD/personal_library.tsv:/BALD/personal_library.tsv:Z
Volume=/home/YOURUSER/BALD/myconfig:/BALD/myconfig:Z
Volume=/home/YOURUSER/BALD/tmp:/BALD/tmp:Z
Volume=/home/YOURUSER/BALD/audible-cli:/root/.audible:Z
Environment="GENERIC_TIMEZONE=Europe/Rome" "TZ=Europe/Rome"
```

For more information on Podman Quadlets <https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html>

## Create BALD timer

Create the timer file `/home/YOURUSER/.config/systemd/user/bald.timer` with the following content:

```
[Unit]
Description=Podman BALD timer
RefuseManualStart=no
RefuseManualStop=no

[Timer]
# Runs sync every day at 23:30
OnCalendar=Mon..Sun 23:30
Persistent=false
Unit=bald.service

[Install]
WantedBy=timers.target
```

For more information on systemd timers <https://www.freedesktop.org/software/systemd/man/latest/systemd.timer.html>.

For more information on the `OnCalendar` format <https://www.freedesktop.org/software/systemd/man/latest/systemd.time.html#Calendar%20Events>

## Update systemd services & enable timer

Run:

```
systemctl --user daemon-reload
systemctl --user enable bald.timer
```

Start the timer (this will start BALD automatically):

`systemctl --user start bald.timer`

# Audiobookshelf

As a bonus the following part will help you to setup your audiobookshelf instance and connect it with BALD destination library.

## Preparations

Create the required directories:

```
mkdir -p /home/YOURUSER/Audiobookshelf/audiobooks
mkdir -p /home/YOURUSER/Audiobookshelf/books
mkdir -p /home/YOURUSER/Audiobookshelf/config
mkdir -p /home/YOURUSER/Audiobookshelf/metadata
mkdir -p /home/YOURUSER/Audiobookshelf/podcasts
```

## Create Audiobookshelf service

Create a file `/home/YOURUSER/.config/containers/systemd/audiobookshelf.container` with the content below. Update the paths and the timezone to your personal preferences.

```
[Unit]
Description=Podman Audiobookshelf

[Install]
WantedBy=default.target

[Service]
Restart=always
TimeoutStartSec=900

[Container]
Image=ghcr.io/advplyr/audiobookshelf:latest
ContainerName=audiobookshelf
NoNewPrivileges=true
AutoUpdate=registry
Environment="TZ=Europe/Rome"
PublishPort=13378:80
Volume=/home/home/YOURUSER/Audiobookshelf/audiobooks:/audiobooks:z
Volume=/home/home/YOURUSER/Audiobookshelf/books:/books:z
Volume=/home/home/YOURUSER/Audiobookshelf/podcasts:/podcasts:z
Volume=/home/home/YOURUSER/Audiobookshelf/config:/config:Z
Volume=/home/home/YOURUSER/Audiobookshelf/metadata:/metadata:Z
```

## Update systemd services & start Audiobookshelf

Run:

```
systemctl --user daemon-reload
systemctl --user start audiobookshelf.service
```

## Enjoy

Open your browser and go to <http://localhost:13378/> (if Audiobookshelf runs on your own computer or replace with localhost the IP of your machine) and enjoy!