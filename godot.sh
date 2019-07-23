#!/bin/bash


##################################################################################################################
# godot.sh - aka: GET GODOT
#
# DESCRIPTION:
#
# This script will check out and build the source for Godot Engine.
# After downloading, the compiled Linux binary will launch.
#
# USAGE:
#
# To launch the latest installed build of the default branch:
#       ./godot.sh [launch]
# To update the default branch:
#       ./godot.sh pull [godot|demos|self]
# To build the default branch:
#       ./godot.sh build
# To pull and build the default branch:
#       ./godot.sh upgrade
#
# CONFIG:
#
# An optional config file can be created as ~/.gitgodot.conf.
# Setting the following option will change the default engine branch (default is master):
#       ENGINEBRANCH=master
# Setting the following option will change where the engine code is stored:
#       ENGINEPATH=/path/to/godot/code
# Setting the following option will change the default demos branch (default is master):
#       DEMOBRANCH=master
# Setting the following option will change where the demo projects are stored:
#       DEMOPATH=/path/to/godot/demos
# Setting the following option will change where we download the temporary copy of the latest version of this script:
#	TMPDIR=/tmp
# Setting the following option will allow multi-job compiling for the git option. Set to number of CPU cores to use:
#       CORES=4
#
# NOTES:
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
# 5.0 - Fully rewritten
#
# As of version 5.0, this script has been changed such that most of the old changelog is no
# longer relevant. You can check out older commits if you wish to adopt it and modify it
# such that it functions with the changes made in the years since it was last updated.
#
##################################################################################################################


configure()
{
	# where to keep the Godot Engine code
	if [ -z ${ENGINEPATH+x} ]; then ENGINEPATH=~/.bin/GodotEngine/engine; fi

	# temporary directory, used for fetching latest script for comparison purposes
	if [ -z ${TMPDIR+x} ]; then TMPDIR=/tmp/getgodot; fi

	# branch to track - default is "master"
	if [ -z ${ENGINEBRANCH+x} ]; then ENGINEBRANCH=master; fi

	# where to keep the demos
	if [ -z ${DEMOPATH+x} ]; then DEMOPATH=~/.bin/GodotEngine/demos; fi

	# branch for demos - default is "master"
	if [ -z ${DEMOBRANCH+x} ]; then DEMOBRANCH=master; fi

	# check if we should launch 64-bit or 32-bit
	if [ -z ${ARCH+x} ]; then ARCH=`uname -m`; fi

	# support multiple jobs if the cpu is multicore
	if [ -z ${CORES+x} ]; then CORES=1; fi

	# allows to switch remote origin to check updates from
	if [ -z ${REMOTE_ORIGIN+x} ]; then REMOTE_ORIGIN=https://raw.githubusercontent.com/adolson/godot-stuff/master/godot.sh; fi


	# override any of the above vars in a user config file
	if [[ -r ~/.gitgodot.conf ]]
	then
		say "Loading user config file."
		source ~/.gitgodot.conf
	fi


	# Non overridable variables
	ZENITY=`which zenity`

	SELFSCR=`readlink -f $0`
	SELFSUM=`md5sum $SELFSCR | cut -d" " -f1`
}


# $1 MESSAGE
say()
{
	if [[ -t 0 ]]
	then
		echo "$1"
	else
		$ZENITY --notification --text="$1" &
	fi
}


selfCheckForUpdates()
{
	mkdir -p $TMPDIR
	rm -f $TMPDIR/godot.sh
	wget -q $REMOTE_ORIGIN -O $TMPDIR/godot.sh
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
			echo "[NEW SCRIPT RELEASE]"
			echo "It looks like there is a newer version of this script available!"
			echo "This was determined due to an MD5 checksum mismatch between the latest version of the script"
			echo "and the copy currently running. Note that if you modified this script yourself (instead of"
			echo "using a config file, for example), then this notice will also be triggered."
			echo
			echo "You can update it right now by following these steps:"
			echo "	* Press Ctrl+C to quit this script"
			echo "	* Check the changes yourself (optional): diff -u $TMPDIR/godot.sh $SELFSCR"
			echo "	* Copy the new version: mv $TMPDIR/godot.sh $SELFSCR"
			echo "	* Make it executable: chmod +x $SELFSCR"
			echo "	* Run the script again."
			echo "Press Enter to continue with the current version of the script."
			read
		elif [[ -x $ZENITY ]]
		then
			say "A new version of the Get Godot script is available. Run in a terminal for more information." &
		fi
	fi
}



# $1 PATH
clone()
{
	if [[ ! -d $1/.git ]]
	then
		git clone https://github.com/godotengine/godot.git $1
	fi
}

# $1 PATH
# $2 BRANCH
pull()
{
	# make and change to directory
	mkdir -p $1
	cd $1

	# make sure we're on the desired branch, if there is a repo here
	if [[ -d $1/.git ]]
	then
		git stash
		git checkout $2
		git pull
	fi
}


pullGodot()
{
	say "# Will pull the current Godot Engine code from github."
	clone $ENGINEPATH
	pull $ENGINEPATH $ENGINEBRANCH
}

buildGodot()
{
	say "# Will build the current Godot Engine code from github."
	cd $ENGINEPATH
	scons -j $CORES platform=x11 builtin_openssl=yes

	say "# All done. If this failed, make sure you have all the necessary tools and libraries installed and try again."
}


pullDemos()
{
	say "# Will stash and pull the current demos from github."
	clone $DEMOPATH
	pull $DEMOPATH $DEMOBRANCH
}


launch()
{
	if [[ $ARCH == 'x86_64' ]]
	then
		if [[ -x $ENGINEPATH/bin/godot.x11.tools.64 ]]
		then
			$ENGINEPATH/bin/godot.x11.tools.64

		else
			say "Unable to find executable. Try building first!"
		fi

	else
		if [[ -x $ENGINEPATH/bin/godot.x11.tools.32 ]]
		then
			$ENGINEPATH/bin/godot.x11.tools.32

		else
			say "Unable to find executable. Try building first!"
		fi
	fi
}


main()
{
	configure $@

	if [[ $1 == "pull" ]]
	then
		if [[ $2 == "godot" ]]
		then
			pullGodot

		elif [[ $2 == "demos" ]]
		then
			pullDemos

		elif [[ $2 == "self" ]]
		then
			selfCheckForUpdates

		else
			pullGodot
			say
			pullDemos
		fi

	elif [[ $1 == "build" ]]
	then
		buildGodot

	elif [[ $1 == "upgrade" ]]
	then
		pullGodot
		say
		pullDemos
		say
		buildGodot

	elif [[ $1 == "which" ]]
	then
		echo "$ENGINEPATH/bin/godot.x11.tools.64"

	else
		launch
	fi
}

main $@
