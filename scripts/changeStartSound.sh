#!/bin/bash

if [ -z "$1" ];then
	echo "Usage: $s [file]"
	exit 1
fi
SOUND="$HOME/.myloginsound"
ln -sf "$1" "$SOUND"
# Play the sound so that the user could test it.
mplayer  "$SOUND"
