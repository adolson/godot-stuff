#!/bin/bash

PROJECTPATH=~/Projects

##################################################################################################################
# replicate-file.sh
#
# DESCRIPTION:
#
# This is a script that will update all copies of a reusable file
# from one master file, specified on the command line.
# The primary use case is for updating one module into many projects.
#
# USAGE:
#
# To replicate <file> to all copies found in the projects directory:
#       ./replicate-file.sh <file>
#
# CONFIG:
#
# An optional config file can be created as ~/.getgodot.conf. This
# file is shared with Shine Upon Thee's godot.sh (Get Godot) script.
# Set the project path to search for replicants with this:
#       PROJECTPATH=/path/to/projects
#
# NOTES:
#
# This script is written and maintained by Dana Olson of Shine Upon Thee
# http://www.shineuponthee.com/
# 
# https://github.com/adolson/godot-stuff/blob/master/replicate-file.sh
# https://raw.githubusercontent.com/adolson/godot-stuff/master/replicate-file.sh
#
# It is licensed under the X11/Expat/"MIT" terms (whatever the Godot Engine uses)
#
# CHANGELOG:
#
# 1.0 - initial release
# 1.1 - verbiage fixes
# 1.2 - link fix, renamed script
#
##################################################################################################################

# allow sync of the project path with the getgodot script config file
if [[ -r ~/.getgodot.conf ]]
then
        source ~/.getgodot.conf
fi


echo
echo

# ensure the master file exists
if [[ ! -f $1 || ! -r $1 ]]
then
        echo "No master file specified."
        echo "Usage:"
        echo "          ./replicate-file.sh <file>"
        echo
        exit
fi

MASTER=`readlink -m $1`
if [[ ! -f $MASTER || ! -r $MASTER ]]
then
        echo "Specified master file could not be read."
        echo "Usage:"
        echo "          ./replicate-file.sh <file>"
        echo
        exit
fi

if [[ ! -d $PROJECTPATH || ! -x $PROJECTPATH || ! -r $PROJECTPATH ]]
then
        echo "Problem reading $PROJECTPATH. Check your configuration."
        echo
        exit
fi

MODULE=`basename $MASTER`
INSTALLED=`find $PROJECTPATH -name "$MODULE" ! -path $MASTER`
if [[ $INSTALLED == "" ]]
then
	echo "No copies of $MODULE to update in $PROJECTPATH."
	echo
	exit
fi

echo "Update files:"
echo
find $PROJECTPATH -name "$MODULE" ! -path $MASTER -exec echo " * {}" \;

echo
echo "With master: $MASTER"
echo -n "Proceed? (y/N) "
read -n 1 KEY
echo

if [[ $KEY = y || $KEY = Y ]]
then
        echo -n "Updating: "
        find $PROJECTPATH -name "$MODULE" ! -path $MASTER -exec cp "$MASTER" {} \; -exec echo -n "*" \;
        echo " Done!"
else
        echo "Canceled."
fi
echo
exit
