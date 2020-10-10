#! /bin/sh
#
# A script to get the genre from musicvideos release before they are pre'ed
# on a site using mvpack script by eur0dance. Ths scriptis  for dark0n3's 
# zipscript-c/project-zs, done by eur0dance.
# Version 1.0
#
# $1 - path to the release dir

### CONFIG ###

sitename="dS"


### CODE ##

genre="Unknown"
cd $1
for file in *.nfo; do
	if [ $file != "*.nfo" ]; then
		tempgenre=`/bin/getmvpreinfo "$1" "$file"`
		if [ $genre = "Unknown" ]; then
			genre=$tempgenre
		fi
	fi
done
touch "[$sitename] - ( $genre ) - [$sitename]"
echo "MUSICVIDEOS - Genre: $genre"


