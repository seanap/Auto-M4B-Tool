#!/bin/bash
# set n to 1
n=1
# continue until $n  5
while [ $n -ge 0 ]
do
	if    ls -d */ 2> /dev/null
	then
		echo Folder Detected
		string1="/untagged/"
		string2=".m4b"
		string4=".log"
		for file in *; do
			if [ -d "$file" ]; then
		mpthree=$(find "$file" -maxdepth 2 -type f -name "*.mp3" | head -n 1)
		string3=$string1$file$string2
		string5=$string1$file$string4
		echo Sampling $mpthree
		bit=$(ffprobe -hide_banner -loglevel 0 -of flat -i "$mpthree" -select_streams a -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1)
		echo Bitrate = $bit
		echo The folder "$file" will be merged to  "$string3"
		echo Starting Conversion
		docker run -it --rm -u $(id -u):$(id -g) -v /path/to/temp/mp3merge:/mnt -v /path/to/temp/untagged:/untagged m4b-tool merge "$file" -n -q --audio-bitrate="$bit" --skip-cover --use-filenames-as-chapters --audio-codec=libfdk_aac --jobs=4 --output-file="$string3" --logfile="$string5"
		mv /path/to/temp/mp3merge/"$file" /path/to/temp/delete/
		mv /path/to/temp/untagged/"$file".chapters.txt /path/to/temp/untagged/chapters
		echo Finished Converting
		echo Deleting duplicate mp3 audiobook folder
		fi
		done
	else
		rm -r /path/to/temp/delete/* 2> /dev/null
		echo No folders detected, next run 5min...
		sleep 5m
	fi
done
