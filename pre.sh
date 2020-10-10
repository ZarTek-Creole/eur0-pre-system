#! /bin/sh
#
# This is a pre script by eur0dance which comes as a part
# of eur0-pre-system. Was inspired by early and unreleased
# pre-script by Jehsom. This script is far more advanced than
# jehsom's script and the only thing left is basicly the idea :)         
# Version 1.0
#
# Notes:
# 1) Make sure that all pre dir names are exactly the same as the
#    group names they are linked to.
# 2) The following bins are required in glftpd's bin dir:
#    sed, echo, touch, chmod, pwd, grep, basename, date, mv, bash,
#    dupediradd, find
# 3) If you don't have it already compiled in your glftpd's bin dir,
#    you must compile glftpd/bin/sources/dupediradd.c as
#    gfltpd/bin/dupediradd, then chmod 666 ftp-data/logs/dupelog
#    and chmod 666 ftp-data/logs/glftpd.log so they can be written
#    to by all users when they pre.
# 4) Make sure glftpd/dev/null is world writable or you will
#    get strange errors.
# 5) All paths specified in the configuration section of this script
#    should be chrooted to glftpd dir. In other words, you specify
#    /ftp-data and not /glftpd/ftp-data or /jail/glftpd/ftp-data.
# 
# Command parameters for this script as they are being passed by glftpd:
# $1 = The directory to pre.
# $2 = Section.
#
# Logging to glftpd.log (for the sitebot) is being done
# in the following format: 
# PRE: <target_path/dirname> <user> <group> <files_num> <dir_size <pre_info>


### CONFIG ###

# Short site name (as it appears in your zipscript)
sitename="dS"

# Location of your glftpd.conf file. It will fully work only if
# this path is both the real path and the CHROOTED path to your
# glftpd dir. In other words: put your glftpd.conf inside
# /glftpd/etc dir and make a symlink to i in /etc.
glftpd_conf="/etc/glftpd.conf"

# As specified in glftpd.conf (you shouldn't usually touch this)
datapath="/ftp-data"

# This is how the dated dirs are being created in your glftpd
# setup: day (usually mp3/0day) or week (usually musicvideos).
# Edit these ONLY if your dates are in different format.

date_0day_format=`date +%m%d`
date_mp3_format=`date +%m%d`
date_mv_format=`date +%V`

# Preing sections configuration:
# 'section_name' is the name of the preing section. Use upper-case
# characters only please (when you pre you can specify lower-case chars
# and they will be upper-cased).
# 'section_target_path' is the path the release is being transfered to.
# 'section_script_path' is the path to the script which returns some
# preing information. Two preing info scripts are supplied by me
# which you can use: getmp3preinfo.sh and getmvpreinfo.sh.
# These scripts will accept one parameter which is the full path
# of the release dir (as it's located in the pre dir). They should
# return one text string which holds some information about the release
# and this information will be displayed during the pre and it will 
# be also logged as <pre_info> for the sitebot. The returned information
# can be an empty line as well. If you don't want to specify a script
# for some section, just set it to be an empty line. 
# Make sure you use sequential indexes starting from 0.

# This is a sample config, CHANGE this according to your site setup.

section_name[0]="MP3"
section_target_path[0]="/site/MP3/$date_mp3_format"
section_script_path[0]="/bin/getmp3preinfo.sh"

section_name[1]="GAMES"
section_target_path[1]="/site/ISO/GAMES"
section_script_path[1]=""

section_name[2]="UTILS"
section_target_path[2]="/site/ISO/UTILS"
section_script_path[2]=""

section_name[3]="DIVX"
section_target_path[3]="/site/DIVX"
section_script_path[3]=""

section_name[4]="PS2"
section_target_path[4]="/site/ISO/PS2"
section_script_path[4]=""

section_name[3]="0DAY"
section_target_path[5]="/site/0DAY/$date_0day_format"
section_target_script[5]=""

section_name[4]="MUSICVIDEOS"
section_target_path[6]="/site/MUSICVIDEOS/$date_mv_format"
section_script_path[6]="/bin/getmvpreinfo.sh"


# Set this to be '1' if you want to allow the "SITE PRE <dirname>" command
# which will pre to the default section (set below). If you set it to '0'
# the default section preing will be disabled (This is useful if you only
# have one preing section).
allowdefaultsection=1

# Set this one to the number of your default preing section.
# It means that when 
defaultsection=0

### CODE ###

## Functions and Procedures ##

checklogfile() {
    # Check for existence and writability of logfile.
    if [ -f $1 ]; then                         
        [ -w $1 ] || {                         
                echo "Logfile $1 exists, but"                       
                echo "is not writable by you. Please verify its permissions."
                exit 1
        }
    else
        if [ -w "`dirname $1`" ]; then                       
                touch $1                       
                chmod 666 $1                       
        else
                echo "Logfile $1 does not exist,"                       
                echo "and you do not have permission to create it."
                exit 1
        fi
    fi
}

## Main block ##

{ [ -z "$1" ]; } && {
	echo ",--------------------------------------------="
	echo '| Usage: SITE PRE <dirname> <section>'

        echo '| Valid sections:'
	echo -n '| '
	for sect in ${section_name[@]}; do
		echo -n "$sect "
	done
	echo ""   
 
        if [ $allowdefaultsection -eq 1 ]; then
		echo '|'
		echo '| If you do not specify a section then'
        	echo "| the release will be pre-ed to ${section_name[$defaultsection]}."
	fi

        echo '|'
	echo '| This moves a directory from a pre-dir to'
	echo '| the provided section dir, and logs it.'
	echo '`--------------------------------------------='
	exit 0
}

if [ $# -lt 2 ]; then
	if [ $allowdefaultsection -eq 1 ]; then
        	sect=${section_name[$defaultsection]}
        	echo "Second parameter wasn't specified, using $sect by default ..."
	else
		echo "Second parameter wasn't specified and there is no default section defined. Aborting ..."
		exit 0
	fi
else
        sect=$2
fi

# Converting section to uppercase
sect=`echo $sect | tr [a-z] [A-Z]`

# Check for existence and writability of the glftpd. 
checklogfile "$datapath/logs/glftpd.log"

# Check for existence and writability of the dupelog.
checklogfile "$datapath/logs/dupelog"

pwd=$PWD
predirs=`cat $glftpd_conf | grep privpath | grep "=STAFFPRE" | awk '{print $2}'`

# Check that the user is currently in a valid pre directory.
inpredir=0
for predir in $predirs; do
	[ "$pwd" = "$predir" ] && {
		inpredir=1
		break
	}
done
[ "$inpredir" = "0" ] && {
	echo "Please enter a pre dir before running SITE PRE."
	echo "Current dir is $pwd."
	exit 0
}

# Check that the specified pre-release dir does in fact exist.
[ -d "$1" ] || {
	echo "\"$1\" is not a valid directory."
	exit 1
}
(cd $1; pwd) | grep "$pwd/" > /dev/null || {
	echo "The specified dir does not reside below the pre dir you are in."
	exit 1
}

# Check that the current directory is writable so we can move stuff from it.
[ -w "$pwd" ] || {
	echo "You do not have write permissions to the current directory,"
	echo "$pwd, so you can't pre here."
	exit 1
}

# Check that we actually have write permission to the rls dir, so we
# can move it properly
[ -w "$1" ] || {
	echo "You do not have write permissions to the release dir specified,"
	echo "\"$1\"."
	exit 1
}

pregrp=`basename $pwd`
# The -sk is used instead of -sm for BSD and Solaris compartibility
size_k=$(($(du -sk $1 | cut -f1)))
size=`expr $size_k / 1024`

found=0
index=0
sections_num=${#section_name[@]}
while [ $index -lt $sections_num -a $found -eq 0 ]; do
    if [ ${section_name[$index]} = "$sect" ]; then
	found=1
    else
	index=`expr $index + 1`
    fi
done

if [ $found -eq 1 ]; then
	target=${section_target_path[$index]}
	preinfo_script=${section_script_path[$index]}
        # Check if the preing dir actually exist
        [ -d "$target" ] || {
                echo "Target dir for preing doesn't exist!"
                exit 1   
        }
        # Check that another release by the current name doesn't already exist
        [ -d "$target/`basename $1`" ] && {
                echo "`basename $1` already exists in today's dir!"
                exit 1
        }
	# Calculating different values
        files=`find "$1" | grep -cE "*\.[[:alnum:]]{3}$"`
	if [ "$preinfo_script" != "" ]; then
        	preinfo=`$preinfo_script "$pwd/$1"`
	else
		preinfo="$sect"
	fi
	# Adding to dupelog
        /bin/dupediradd "$1" $datapath > /dev/null 2>&1
        echo "[$sitename] Release Info: $preinfo [$sitename]"
	# Setting the current time on the release dir
        touch "$1"
	# Moving the release
	mv "$1" "$target"
	# Putting a record in glftpd.log
	echo `date "+%a %b %d %T %Y"` PRE: \"$target/$1\" \"$USER\" \"$pregrp\" \"$files\" \"$size\" \"$preinfo\" >> $datapath/logs/glftpd.log
	echo "[$sitename] Success! Release has been pre'd. [$sitename]"
else
	echo "Section $sect doesn't exist. Aborting ..."
	exit 1
fi
