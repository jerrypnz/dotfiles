#!/bin/bash

if [ -z "$1" ];then
	echo "Usage: $s [file]"
	exit 1
fi
WALLPAPER="$HOME/.mywallpaper"
ln -sf "$1" "$WALLPAPER"
# Set the wallpaper
feh --bg-scale "$WALLPAPER"
