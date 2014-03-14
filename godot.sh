#!/bin/bash

# this script will download the latest build of Godot Engine.
# this includes getting the server and client binaries, demos, templates.
# it keeps the old builds, in case you need one due to breakage or somesuch.
# after downloading, the latest 64-bit Linux binary will launch.
#
# NOTE: edit the variables below as needed!
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
#
#------------------------START VARS------------------------

# where you keep your Godot Engine builds.
ENGINEPATH=~/.bin/GodotEngine/

# where you keep your projects.
# the script will simply change to this directory before launching Godot)
PROJECTPATH=~/Projects/

# the URL to the Godot Engine binary builds.
ENGINEURL=http://www.godotengine.org/builds

#-------------------------END VARS-------------------------
#

# if we did not choose to only launch, let's run the update block
if [[ $@ != launch ]]
then

	mkdir -p $ENGINEPATH
	cd $ENGINEPATH

	LOCALBUILD=`find build-*/godot_x11.64 2> /dev/null | sort -V | tail -1 | sed 's/build-//g;s/\/godot_x11.64//g'`
	LOCALBUILD=${LOCALBUILD:-0}

	REMOTEDATE=`wget --server-response --spider http://www.godotengine.org/builds/release/godot_x11.64 2>&1 | grep -i last-modified | awk -F": " '{ print $2 }'`
	LATESTBUILD=`date -d "$REMOTEDATE" +%Y%m%d%H%M`
	LATESTBUILD=${LATESTBUILD:-0}

	echo "Local build: $LOCALBUILD, Latest release: $LATESTBUILD."

	if [ $LATESTBUILD -gt $LOCALBUILD ]
	then
		mkdir -p build-$LATESTBUILD
		cd build-$LATESTBUILD
		echo -n "Downloading new build: "
		for i in \
			$ENGINEURL/release/godot \
			$ENGINEURL/release/godot_x11.64 \
			$ENGINEURL/release/godot_x11.32 \
			$ENGINEURL/release/linux_server \
			$ENGINEURL/release/linux_server.64 \
			$ENGINEURL/release/godot_win32.exe \
			$ENGINEURL/release/godot_win64.exe \
			$ENGINEURL/release/GodotOSX32.zip \
			$ENGINEURL/templates/export_templates.zip \
			$ENGINEURL/demos/godot_demos.zip
		do
			wget -q -c $i
			echo -n "*"
		done
		echo "*"
		echo "Done!"
	fi
fi


# if we aren't only updating, launch the latest version
if [[ $@ != update ]]
then
	mkdir -p $PROJECTPATH
	cd $PROJECTPATH

	CURRENTBUILD=`find $ENGINEPATH/build-*/godot_x11.64 | sort -V | tail -1`

	chmod +x $CURRENTBUILD
	exec $CURRENTBUILD
fi
