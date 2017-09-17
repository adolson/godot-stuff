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
# To update and build and launch the default branch:
#       ./godot.sh
# To update and build but NOT launch the default branch:
#       ./godot.sh build
# To launch the latest installed build of the default branch:
#       ./godot.sh launch
#
# CONFIG:
#
# An optional config file can be created as ~/.gitgodot.conf.
# Setting the following option will change the default engine branch (default is master):
#       BRANCH=master
# Setting the following option will change where the engine code is stored:
#       ENGINEPATH=/path/to/godot/code
# Setting the following option will enable downloading the demos:
#       GETDEMOS=1
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
# 4.0 - new release that focuses solely on building from source
#     - config file changed so as to not conflict with old versions
# 4.1 - added text about adding execute bit when new script version is available
# 4.2 - remove old downloaded script from temp directory if it exists
# 4.3 - added demo repo and options to enable automatically downloading them
#
# As of version 4.0, this script has been changed such that most of the old changelog is no
# longer relevant. You can check out older commits if you wish to adopt it and modify it
# such that it functions with the changes made in the years since it was last updated.
#
##################################################################################################################

#------------------------VARS------------------------

# where to keep the Godot Engine code
ENGINEPATH=~/.bin/GodotEngine/engine

# temporary directory, used for fetching latest script for comparison purposes
TMPDIR=/tmp/getgodot

# branch to track - default is "master"
BRANCH=master

# should we also checkout the demos?
GETDEMOS=0

# where to keep the demos
DEMOPATH=~/.bin/GodotEngine/demos

# branch for demos - default is "master"
DEMOBRANCH=master

# check if we should launch 64-bit or 32-bit
ARCH=`uname -m`

# support multiple jobs if the cpu is multicore
CORES=1

# override any of the above vars in a user config file
if [[ -r ~/.gitgodot.conf ]]
then
	if [[ -t 0 ]]
        then
                echo "Loading user config file."
        fi
	source ~/.gitgodot.conf
fi


#############################################################################################################
# start of checking for newer versions of this script

ZENITY=`which zenity`

SELFSCR=`readlink -f $0`
SELFSUM=`md5sum $SELFSCR | cut -d" " -f1`

mkdir -p $TMPDIR
rm -f $TMPDIR/godot.sh
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
		echo "	* Check the changes yourself (optional): diff -u $TMPDIR/godot.sh $SELFSCR"
		echo "	* Copy the new version: mv $TMPDIR/godot.sh $SELFSCR"
		echo "	* Make it executable: chmod +x $SELFSCR"
		echo "	* Run the script again."
		echo "Press Enter to continue with the current version of the script."
		read
	elif [[ -x $ZENITY ]]
        then
                $ZENITY --notification --text="A new version of the Get Godot script is available. Run in a terminal for more information." &
	fi
fi

# end of checking for newer version of this script
#############################################################################################################


# make and change to engine directory
mkdir -p $ENGINEPATH
cd $ENGINEPATH

git checkout $BRANCH

# user just wants to launch pre-existing binary
if [[ $@ == "launch" ]]
then

        if [[ $ARCH == 'x86_64' ]]
        then
                if [[ -x $ENGINEPATH/bin/godot.x11.tools.64 ]]
                then
                        $ENGINEPATH/bin/godot.x11.tools.64
                else
                        echo "Unable to find executable. Try building first!"
                fi
        else
                if [[ -x $ENGINEPATH/bin/godot.x11.tools.32 ]]
                then
                        $ENGINEPATH/bin/godot.x11.tools.32
                else
                        echo "Unable to find executable. Try building first!"
                fi
        fi
# user wants to checkout latest code and build it
else

        # first grab the demos, if user wants them
        if [[ $GETDEMOS != 0 ]]
        then
                if [[ -t 0 ]]
                then
                        echo "Will stash and pull the current demos from github."
                fi

                if [[ ! -d $DEMOBRANCH ]]
                then
                        git clone https://github.com/godotengine/godot-demo-projects.git $DEMOPATH
                fi

                cd $DEMOPATH

                git stash
                git checkout $DEMOBRANCH
                git stash
                git pull
        fi

        # now do the engine build
        if [[ -t 0 ]]
        then
                echo "Will pull and build the current Godot Engine code from github."
        fi

        if [[ ! -d $ENGINEPATH ]]
        then
                git clone https://github.com/okamstudio/godot.git $ENGINEPATH
        fi

        cd $ENGINEPATH
        
        git stash
        git checkout $BRANCH
        git stash
        git pull
        
        scons -j $CORES platform=x11 builtin_openssl=yes
        
        if [[ -t 0 ]]
        then
                echo "All done. If this failed, make sure you have all the necessary tools and"
                echo "libraries installed and try again."
        fi

        # launch it, unless user only wants to build
        if [[ $@ != 'build' ]]
        then
                if [[ $ARCH == 'x86_64' ]]
                then
                        bin/godot.x11.tools.64
                else
                        bin/godot.x11.tools.32
                fi
        fi
fi

# end of building the latest version
#############################################################################################################
