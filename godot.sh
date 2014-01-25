#!/bin/sh

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
#
#------------------------START VARS------------------------

# where you keep your Godot Engine builds.
ENGINEPATH=~/.bin/GodotEngine/

# where you keep your projects.
# the script will simply change to this directory before launching Godot)
PROJECTPATH=~/Projects/

# the next line is the URL to the Linux binary, without "/godot_x11.64" on the end.
# you need to add it yourself, because it's not public yet.
ENGINEURL=http://you-should-know-this

#-------------------------END VARS-------------------------
#

mkdir -p $ENGINEPATH
cd $ENGINEPATH
LOCALBUILD=`cat build*/version.txt 2> /dev/null | sort | tail -1`
LOCALBUILD=${LOCALBUILD:-0}
LATESTRELEASE=`wget -q -O - $ENGINEURL/../templates/version.txt`

echo "Local build: $LOCALBUILD, Latest release: $LATESTRELEASE."

if [ $LATESTRELEASE -gt $LOCALBUILD ]
then
        mkdir -p build-$LATESTRELEASE
        cd build-$LATESTRELEASE
        echo -n "Downloading new build: "
        for i in \
                $ENGINEURL/../templates/export_templates.zip \
                $ENGINEURL/../demos/godot_demos.zip \
                $ENGINEURL/godot \
                $ENGINEURL/godot_win32.exe \
                $ENGINEURL/godot_win64.exe \
                $ENGINEURL/godot_x11.64 \
                $ENGINEURL/linux_server \
                $ENGINEURL/linux_server.64 \
                $ENGINEURL/../templates/version.txt
        do
                wget -q -c $i
                echo -n "*"
        done
        echo "*"
        echo "Done!"
fi


# now launch the latest version

mkdir -p $PROJECTPATH
cd $PROJECTPATH

CURRENTBUILD=`find $ENGINEPATH/*/godot_x11.64 | sort | tail -1`

chmod +x $CURRENTBUILD
exec $CURRENTBUILD
