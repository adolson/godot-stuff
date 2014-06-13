#!/bin/bash

# this script will download the latest build of Godot Engine.
# this includes getting the server and client binaries, demos, templates.
# it keeps the old builds, in case you need one due to breakage or somesuch.
# after downloading, the latest 64-bit Linux binary will launch.
#
# script by Dana Olson of ShineUponThee - www.shineuponthee.com
#
# license: MIT (same as Godot Engine)
#
# you can always find the latest version of this script at:
#
# https://github.com/adolson/godot-stuff/blob/master/godot.sh
# https://raw.githubusercontent.com/adolson/godot-stuff/master/godot.sh
#
# CHANGELOG:
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
#
#------------------------START VARS------------------------

# where you keep your Godot Engine builds.
ENGINEPATH=~/.bin/GodotEngine/

# where you keep your projects.
# the script will simply change to this directory before launching Godot.
PROJECTPATH=~/Projects/

#-------------------------END VARS-------------------------
#

# override the above vars in a user config file
if [ -r ~/.getgodot.conf ]
then
	echo "Loading user config file."
	source ~/.getgodot.conf
fi

mkdir -p $ENGINEPATH
cd $ENGINEPATH


# new option to automate pulling, building, and running the current git version of Godot
if [[ $@ == "git" ]]
then
        echo "Will pull and build the current Godot Engine code from github."
        if [[ ! -d build-git ]]
        then
                git clone https://github.com/okamstudio/godot.git build-git
        fi
        cd build-git
        git pull
        scons bin/godot target=release_debug
        echo "All done. If this failed, make sure you have all the necessary tools and"
        echo "libraries installed and try again."
        bin/godot
fi

# if we did not choose to only launch, let's run the update block
if [[ $@ != "launch" ]] && [[ $@ != "git" ]]
then


	LOCALBUILD=`find build-*/godot_x11*.64 2> /dev/null | sort -V | tail -1 | awk -F- '{ print $2  }' | awk -F/ '{ print $1  }'`
	LOCALBUILD=${LOCALBUILD:-0}

	REMOTEDATE=`wget --server-response --spider http://builds.godotengine.org/builds.html 2>&1 | grep -i last-modified | awk -F": " '{ print $2 }'`
	LATESTBUILD=`date -d "$REMOTEDATE" +%Y%m%d%H%M`
	LATESTBUILD=${LATESTBUILD:-0}

	echo "Local build: $LOCALBUILD, Latest release: $LATESTBUILD."
	if [ $LATESTBUILD -gt $LOCALBUILD ]
	then
		ENGINEFILES=`wget -q http://builds.godotengine.org/builds.html -O - | sed 's/</\n/g' | grep "^a href" | sed 's/a href="//g' | awk -F\" '{ print $1  }'`
		if [[ $ENGINEFILES == "" ]]
		then
			echo "False alarm. No new files found at this time."
		else
			mkdir -p build-$LATESTBUILD
			cd build-$LATESTBUILD
			echo -n "Downloading new release: "
			for i in $ENGINEFILES
			do
				echo -n "*"
				wget $i -q -c
			done
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

	CURRENTBUILD=`find $ENGINEPATH/build-*/godot_x11*.64 | sort -V | tail -1`

	chmod +x $CURRENTBUILD
	exec $CURRENTBUILD
fi
