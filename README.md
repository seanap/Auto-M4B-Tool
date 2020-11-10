# M4B-Tool Automation
### Table of Contents

1. [Overview](#overview)  
    * [Computer Architecture](#computer-architecture)  
    * [Important folders](#important-folders)  
2. [Linux Install](https://github.com/seanap/Auto-M4B-Tool#linux-docker-server-vm)  
    1. [Install m4b-tool](https://github.com/seanap/Auto-M4B-Tool#install-m4b-tool-via-docker)  
    2. [Docker Run Command](https://github.com/seanap/Auto-M4B-Tool#understanding-the-docker-run-command)  
    3. [Create the auto-m4b-tool.sh script](https://github.com/seanap/Auto-M4B-Tool#create-the-auto-m4b-toolsh-script)  
    4. [Running the auto-m4b-tool.sh script](https://github.com/seanap/Auto-M4B-Tool#run-the-auto-m4b-toolsh-script)  
3. [Windows Install](https://github.com/seanap/Auto-M4B-Tool#windows-htpc-install)  
4. [Tagging](#tagging)  
5. [Notes](#notes)  

---

## Overview:
A method to watch a directory for newly added audiobooks, which triggers a script that converts the contents of that new folder into an m4b, and saves it to mp3tag's default directory ready for post processing.

I use multiple OSes for this particular automation. As such, this particular method may be impractical to some, but there's nothing special about these steps that requires multiple computers, and everything could be done solely on windows.
> Please consider contributing a Windows Only method if you write a similar windows script.

#### Computer Architecture
This is how my system is set up. I have a fileserver/nas that uses SMB to share my folders with all my computers.

| Computer | OS | Noteable Installs |
|--|--|--|
| Fileserver VM | OMV (debian linux) | SMB network share, MergerFS+SnapRAID |
| Docker Server VM | Ubuntu 20.04 | M4b-tool docker and `auto-m4b-tool.sh` script |
| HTPC | Windows | Mp3tag, Dropit |

#### Important folders:
* `/original` - Folder where I keep my untagged/unmodified original copies
* `/temp/mp3merge` - Folder where I copy recently added mp3 audiobook folders
* `/temp/untagged` - Folder where I copy m4b files from `/original`, also where I optput the m4b file created from `/mp3merge`. This is the folder I set mp3tag to open by default.
* `/temp/delete` - Purely a temp folder, used as a lazy way to delete the mp3 audiobook folder copied to `/mp3merge` after conversion to m4b.
* `/audiobooks` - Folder where I keep properly tagged and organized audiobooks. This is what Plex/Booksonic looks at.

#### Automated workflow:
1. Newly acquired audiobooks are put in `/original`  
2. Auto Copy new books to appropriate folder based on filetype  
    * If book is already an m4b, then copy to `/untagged/Book1.m4b`  
    * If book is mp3, then copy to `/mp3merge/Book1/*.mp3`  
3. Every 5 min the `auto-m4b-tool.sh` script checks `/mp3merge` for new folders, when found creates a single chapterized M4b  
4. This newly created m4b file is saved to `/untagged`  
5. `/mp3merge/Book1` folder is moved to `/delete` and the contents of `/delete` is deleted  
6. Open mp3tag, all books that need processing will be loaded  
7. Use mp3tag audible websource script to tag  
8. Use mp3tag action script to rename/relocate to `/audiobooks`  

---
## Install
First let's prepare the Linux machine (Docker Server VM) .  We will be installing the m4b-tool docker, configuring a docker run command, and creating the automation script.
### Linux (Docker Server VM):

#### Install m4b-tool via docker
Docker is by far the easiest way to install and use m4b-tool.  Other methods will not be covered in this guide.

```bash
# clone m4b-tool repository
git clone https://github.com/sandreas/m4b-tool.git

# change directory
cd m4b-tool

# build docker image - this will take a while
docker build . -t m4b-tool

# testing the command
docker run -it --rm -u $(id -u):$(id -g) -v "$(pwd)":/mnt m4b-tool --version

```

> For other methods of installing m4b-tool see https://github.com/sandreas/m4b-tool#installation
---
#### Understanding the docker run command
The docker run command is the heart of this operation.  There are two sets of variables we need to define that correspond to a Docker portion and a m4b-tool portion of this command.  The docker portion requires us to set the paths (-v volumes) that we will be working with.  The m4b-tool portion will define how to encode and combine the mp3 files.

**Example:**

```bash
docker run -it --rm -u $(id -u):$(id -g) -v /path/to/temp/mp3merge:/mnt -v /path/to/temp/untagged:/untagged m4b-tool merge "$file" -n -q --audio-bitrate=92k --audio-samplerate=22050 --skip-cover --use-filenames-as-chapters --audio-codec=libfdk_aac --jobs=6 --output-file="$string3" --logfile="$string5"
```

**Options Explained:**
* `-v /path/to/temp/mp3merge:/mnt` - MP3 Source folder (mapped to /mnt inside the docker)
* `-v /path/to/temp/untagged:/untagged` - M4B Destination folder (mapped to /untagged inside the docker)
* `-n` - No Interruptions
* `-q` - Quiet
* `--audio-bitrate=92k` - Bitrate
* `--audio-samplerate=22050` - Samplerate
* `--skip-cover` - We will add a cover in mp3tag, no need to add it here it will be written over.
* `--use-filenames-as-chapters` - Depends on your source material, If your mp3 has chapter names (TITLE) tagged to your liking then do not use
* `--audio-codec=libfdk_aac` - High quality codec
* `--jobs=6` - How many CPU Cores to use, do not set higher than available
* More m4b-tool options https://github.com/sandreas/m4b-tool#reference

> All you need to do is update the two `-v` paths to your own

---
#### Create the `auto-m4b-tool.sh` script
This is a Linux Bash script.  You will need to update lines 19, 20, 21, and 27 of the script to your specific directories.
```Bash
#!/bin/bash
# set n to 1
n=1
# continue until $n  5
while [ $n -ge 0 ]
do
	if    ls -d */ 2> /dev/null
	then
		echo Starting Conversion
		string1="/untagged/"
		string2=".m4b"
		string4=".log"
		for file in *; do
    		if [ -d "$file" ]; then
		string3=$string1$file$string2
		string5=$string1$file$string4
		echo "$file" will be merged into  "$string3"
		docker run -it --rm -u $(id -u):$(id -g) -v /path/to/temp/mp3merge:/mnt -v /path/to/temp/untagged:/untagged m4b-tool merge "$file" -n -q --audio-bitrate=92k --audio-samplerate=22050 --skip-cover --use-filenames-as-chapters --audio-codec=libfdk_aac --jobs=6 --output-file="$string3" --logfile="$string5"
        mv /path/to/temp/mp3merge/"$file" /path/to/temp/delete/
		mv /path/to/temp/untagged/"$file".chapters.txt /path/to/temp/untagged/chapters
		echo Finished Converting
		fi
		done
	else
		echo No Folders Found. 5min to next run...
		rm -r /path/to/temp/delete/* 2> /dev/null
		sleep 5m
	fi
done
```
* Change to the `/mp3merge` directory  
```bash
cd /path/to/temp/mp3merge
```
* Create auto-m4b-tool script  
```bash
nano auto-m4b-tool.sh
```
* Copy and paste the above code, and update lines 19, 20, 21, and 27 with your own paths everywhere you see `/path/to/`,  
  * Save `ctrl-s`  
  * Exit `ctrl-x`  
---
#### Run the `auto-m4b-tool.sh` script
* Change to the `/mp3merge` directory  
`cd /path/to/temp/mp3merge`
* Run the script  
`./auto-m4b-tool.sh`

This will run the script in a terminal window. To exit the script type `ctrl-c`. You can get fancy and run the script as a service, or set a cron job to start this script when the computer starts, but for my pursposes having an extra terminal window open with this running helps to see what's actually happening and keep tabs on the conversion.

---

## Windows (HTPC) Install
So far we have a script that watches a directory for new folders, converts the contents of that new folder into an m4b, and saves it to mp3tag's default directory ready for post processing.

The Windows portion of this process uses a program called Dropit to monitor your `/original` folder for recent additions and will copy mp3 book

### Install Dropit
Dropit is a very configurable, lightweight, windows utility, that will help us monitor `/original` for changes and copy the files and folders to the right locations.
* Download, Install, and Run [Dropit](http://www.dropitproject.com/#download)
* In the System Tray: Right-Click `Dropit` > `Profiles` > `Customize`
<p float="left">
  <img src="https://i.imgur.com/H7MUIar.png" width="40%" />
</p>

* Create a new Profile  
![New Profile](https://i.imgur.com/mZwyfTS.png)
* In the System Tray: Right-Click `Dropit` > `Associations` Create the two associations shown below with your specific folder  
![Update Monitored Folder Path](https://i.imgur.com/cV8mVCR.png)  
  * The first entry moves .m4b files directly to `/untagged`
  * The second entry moves .mp3 book folders to `/mp3merge/Book1` where our `auto-m4b-tool.sh` script will take over  
  * Click the Check button to Save
* In the System Tray: Right-Click `Dropit` > `Options` > `Monitoring`  
  * `Check` Enable scan of monitored folders  
  * Select `immediate on-change` from the drop down menu  
  * Update the path to your `/original`
  * Select the `Mp3merge` profile from the drop down menu
  * Click `Save` and `OK`  
![Options](https://i.imgur.com/VUOPcqo.png)
---
### Tagging
Return to [Guide](https://github.com/seanap/Plex-Audiobook-Guide/blob/master/README.md#configure-mp3tag) to configure Mp3tag.

---
### Notes:
There are many ways to customize this workflow. I'd love to hear what you've come up with.

Huge shout-out to `sandreas` who created the amazing m4b-tool and to `tylerdotdo` for sharing the original `auto-m4b-tool.sh` script!

---
<a href="https://www.buymeacoffee.com/seanap" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-green.png" alt="Buy Me A Book" height="41" width="174"></a>
