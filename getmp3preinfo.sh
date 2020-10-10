#! /bin/sh
#
# A script for dark0n3's zipscript-c/project-zs by eur0dance
# which retrieves the genre from mp3 releases before the pre.
# Version 1.0
# Note: $1 - a dir where the 0-byte tagline file is located

### CONFIG ###

sitename="dS"


### CODE ###

fname=`ls "$1" | grep \[$sitename\]`

first=`echo $fname | awk -F" - COMPLETE - " '{ print $1 }'`
second=`echo $fname | awk -F" - COMPLETE - " '{ print $2 }'`
output=`echo $second | awk -F" ) - " '{ print $1 }'`
echo $output
