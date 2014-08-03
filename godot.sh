#!/bin/bash


##################################################################################################################
# godot.sh - aka: GET GODOT
#
# DESCRIPTION:
#
# This script will download the latest build of Godot Engine.
# This includes getting the server and client binaries, demos, templates.
# It keeps the old builds, in case you need one due to breakage or somesuch.
# After downloading, the latest Linux binary will launch.
#
# USAGE:
#
# To download the latest build and launch it:
#       ./godot.sh
# To download the latest build and exit:
#       ./godot.sh update
# To launch the latest installed build:
#       ./godot.sh launch
# To get the latest development code from Github, compile it, and launch it:
#       ./godot.sh git
#
# CONFIG:
#
# An optional config file can be created as ~/.getgodot.conf.
# Setting the following option will change the working directory when launching Godot:
#       PROJECTPATH=/path/to/projects
# Setting the following option will change where the Godot builds get downloaded to:
#       ENGINEPATH=/path/to/godot
# Setting the following option will change where we download the temporary copy of the latest version of this script:
#	TMPDIR=/tmp
# Setting the following option will change the URL where OKAM hosts the builds.html file (advise against changing this manually):
#	ENGINEURL=https://godot.blob.core.windows.net/builds/builds.html
#
# NOTES:
#
# This script is written and maintained by Dana Olson of ShineUponThee
# http://www.shineuponthee.com/
#
# As of version 2.3, the script will check for newer versions. However, you can always find
# the latest version yourself on Github here:
#
# https://github.com/adolson/godot-stuff/blob/master/godot.sh
# https://raw.githubusercontent.com/adolson/godot-stuff/master/godot.sh
#
# It is licensed under the X11/Expat/"MIT" terms (whatever the Godot Engine uses)
#
# CHANGELOG:
#
# 1.0 - initial release
# 1.1 - fix failure on systems without previous build installed in $ENGINEPATH/build-????/
#     - make directories if they don't already exist
# 1.2 - add MacOSX build to download list
# 1.3 - add URL for downloads, as it is now public
# 1.4 - version.txt file no longer generated on server, script now uses timestamp on Linux binary
# 1.5 - fixed bug where timestamp builds weren't considered newer than old version.txt builds
#     - added option to check for updates only, do not launch Godot. call ./godot.sh update
#     - added option to skip updates and just launch latest installed. call ./godot.sh launch
# 1.6 - changed interpreter to bash to fix another bug
# 1.7 - added 32-bit Linux binary to the download list
# 1.8 - export templates filename and location has changed
#     - added option to pull, build, and run latest code from github. call ./godot.sh git
# 1.9 - Okam uses a new build server, updated code to pull from there
#     - added support for ~/.getgodot.conf config file for the path variables
# 2.0 - MAJOR RELEASE: fixed a typo in an echo statement
# 2.1 - fixed a bug where empty, false new build directories were sometimes created
# 2.2 - added notes at the top about license and where to find latest version of this script
#     - fixed bug in changes made in 2.1 release
# 2.3 - added usage info to comments
#     - script will now check for newer versions of itself, based on md5sum mismatch
#     - added some zenity stuff to inform the user when a new build or script is available
# 2.4 - Okam again uses a new build server, updated URL
# 2.5 - Okam played tricks on us and changed the downloads to individual webpages
#     - script detects architecture automatically now
#     - only downloads the appropriate Linux binary + demos + templates by default
#     - options to disable/enable download of any files (except the Linux build for the current architecture)
#
##################################################################################################################

#------------------------VARS------------------------

# where to keep the Godot Engine builds
ENGINEPATH=~/.bin/GodotEngine/

# where to keep Godot projects - the script will simply change to this directory before launching Godot
PROJECTPATH=~/Projects/

# where the engine build reside
ENGINEURL=https://godot.blob.core.windows.net

# temporary directory, used for fetching latest script for comparison purposes
TMPDIR=/tmp/getgodot

# check if we should launch 64-bit or 32-bit
ARCH=`uname -m`

# don't download OSX, Windows, non-arch Linux, or server builds by default
GET_NONARCHLIN=0
GET_SERVER=0
GET_OSX32=0
GET_WIN32=0
GET_WIN64=0

# download templates and demos by default
GET_DEMOS=1
GET_TEMPLATES=1

# override any of the above vars in a user config file
if [[ -r ~/.getgodot.conf ]]
then
	if [[ -t 0 ]]
        then
                echo "Loading user config file."
        fi
	source ~/.getgodot.conf
fi

# files to download
BUILDFILES=( export_templates-1.0devel.tpz godot_demos-1.0devel.zip godot_x11-1.0devel.32 godot_x11-1.0devel.64 linux_server-1.0devel.64 GodotOSX32-1.0devel.zip godot_win32-1.0devel.exe godot_win64-1.0devel.exe )

if [[ $GET_WIN64 -eq 0 ]]; then BUILDFILES=(${BUILDFILES[@]:0:7} ${BUILDFILES[@]:8}); fi

if [[ $GET_WIN32 -eq 0 ]]; then BUILDFILES=(${BUILDFILES[@]:0:6} ${BUILDFILES[@]:7}); fi

if [[ $GET_OSX32 -eq 0 ]]; then BUILDFILES=(${BUILDFILES[@]:0:5} ${BUILDFILES[@]:6}); fi

if [[ $GET_SERVER -eq 0 ]]; then BUILDFILES=(${BUILDFILES[@]:0:4} ${BUILDFILES[@]:5}); fi

if [[ $GET_NONARCHLIN -eq 0 ]]
then
        if [[ $ARCH == 'x86_64' ]]
        then
                BUILDFILES=(${BUILDFILES[@]:0:2} ${BUILDFILES[@]:3})
        else
                BUILDFILES=(${BUILDFILES[@]:0:3} ${BUILDFILES[@]:4})
        fi
fi

if [[ $GET_DEMOS -eq 0 ]]; then BUILDFILES=(${BUILDFILES[@]:0:1} ${BUILDFILES[@]:2}); fi

if [[ $GET_TEMPLATES -eq 0 ]]; then BUILDFILES=(${BUILDFILES[@]:1}); fi

# make and change to engine directory
mkdir -p $ENGINEPATH
cd $ENGINEPATH


# start of checking for newer versions of this script

ZENITY=`which zenity`

SELF=`readlink -f $0`
SELFSUM=`md5sum $SELF | cut -d" " -f1`

mkdir -p $TMPDIR
wget -q https://raw.githubusercontent.com/adolson/godot-stuff/master/godot.sh -O $TMPDIR/godot.sh
LATESTSUM=`md5sum $TMPDIR/godot.sh | cut -d" " -f1`

# make sure the downloaded file is reasonably long (should always be longer than at least 1000 characters)
LATESTCOUNT=`wc -c $TMPDIR/godot.sh | cut -d" " -f1`
if [[ $LATESTCOUNT < 1000 ]]
then
	LATESTSUM=$SELFSUM
fi

# md5sums don't match, print a notice to the user
if [[ $SELFSUM != $LATESTSUM ]]
then
	if [[ -t 0 ]]
	then
		echo
		echo "[NEW SCRIPT RELEASE]"
		echo "It looks like there is a newer version of this script available!"
		echo "This was determined due to an MD5 checksum mismatch between the latest version of the script"
		echo "and the copy currently running. Note that if you modified this script yourself (instead of"
		echo "using a config file, for example), then this notice will also be triggered."
		echo
		echo "You can update it right now by following these steps:"
		echo "	* Press Ctrl+C to quit this script"
		echo "	* Check the changes yourself (optional): diff --suppress-common-lines -dyW150 $SELF $TMPDIR/godot.sh"
		echo "	* Copy the new version: mv $TMPDIR/godot.sh $SELF"
		echo "	* Run the script again."
		echo "Press Enter to continue with the current version of the script."
		read
	elif [[ -x $ZENITY ]]
        then
                $ZENITY --notification --text="A new version of the Get Godot script is available. Run in a terminal for more information." &
	fi
fi

# end of checking for newer version of this script

# new option to automate pulling, building, and running the current git version of Godot
if [[ $@ == "git" ]]
then
        if [[ -t 0 ]]
        then
                echo "Will pull and build the current Godot Engine code from github."
        fi
        if [[ ! -d build-git ]]
        then
                git clone https://github.com/okamstudio/godot.git build-git
        fi
        cd build-git
        git pull
        scons bin/godot target=release_debug
        if [[ -t 0 ]]
        then
                echo "All done. If this failed, make sure you have all the necessary tools and"
                echo "libraries installed and try again."
        fi
        bin/godot
fi

# if we did not choose to only launch, let's run the update block
if [[ $@ != "launch" ]] && [[ $@ != "git" ]]
then
        if [[ $ARCH == 'x86_64' ]]
        then
	        LOCALBUILD=`find build-*/godot_x11*.64 2> /dev/null | sort -V | tail -1 | awk -F- '{ print $2  }' | awk -F/ '{ print $1  }'`
        else
	        LOCALBUILD=`find build-*/godot_x11*.32 2> /dev/null | sort -V | tail -1 | awk -F- '{ print $2  }' | awk -F/ '{ print $1  }'`
        fi
	LOCALBUILD=${LOCALBUILD:-0}

        # grab the latest release date from the builds.html page
	REMOTEDATE=`wget --server-response --spider $ENGINEURL/builds/builds.html 2>&1 | grep -i last-modified | awk -F": " '{ print $2 }'`

	LATESTBUILD=`date -d "$REMOTEDATE" +%Y%m%d%H%M`
	LATESTBUILD=${LATESTBUILD:-0}

	if [[ -t 0 ]]
        then
                echo "Local build: $LOCALBUILD, Latest release: $LATESTBUILD."
        fi
	if [ $LATESTBUILD -gt $LOCALBUILD ]
	then
		mkdir -p build-$LATESTBUILD
		cd build-$LATESTBUILD
		if [[ -x $ZENITY ]]
                then
                        $ZENITY --notification --text="Downloading new version of Godot Engine ($LATESTBUILD)." &
                fi
                if [[ -t 0 ]]
                then
                        echo -n "Downloading new release: "
                fi

	        BUILDDATE=`date -d "$REMOTEDATE" +%Y-%m-%d`
		for i in ${BUILDFILES[@]}
		do
                        if [[ -t 0 ]]
                        then
			        echo -n "*"
                        fi
                        wget $ENGINEURL/devel/$BUILDDATE/$i -q -c
		done
                if [[ -t 0 ]]
                then
			echo "*"
		        echo "Done!"
                fi
	fi
fi


# if we aren't only updating, launch the latest version
if [[ $@ != "update" ]] && [[ $@ != "git"  ]]
then
	mkdir -p $PROJECTPATH
	cd $PROJECTPATH

        # detect which arch to launch
        if [[ $ARCH == 'x86_64' ]]
        then
	        CURRENTBUILD=`find $ENGINEPATH/build-*/godot_x11*.64 | sort -V | tail -1`
        else
	        CURRENTBUILD=`find $ENGINEPATH/build-*/godot_x11*.32 | sort -V | tail -1`
        fi

	chmod +x $CURRENTBUILD
	exec $CURRENTBUILD
fi
