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
		echo Feed Me...
		rm -r /path/to/temp/delete/* 2> /dev/null
		sleep 5m
	fi
done
