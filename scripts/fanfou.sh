#!/bin/bash 

CONFIG_FILE="$HOME/.fanfourc"
SEND_MSG_URL="http://api.fanfou.com/statuses/update.xml"

if [ -z $1 ];then
	echo "Usage: $s Message_to_send"
	exit 1
fi

if [ ! -e $CONFIG_FILE  ];then
	echo "Please write your username and password into ~/.fanfourc, and make it executable by chmod +x"
	echo "E.g."
	echo "#USERNAME=your_user_name"
	echo "#PASSWORD=your_password"
	exit 2
fi

source "$CONFIG_FILE"
curl -u $USERNAME:$PASSWORD -d status="$1" $SEND_MSG_URL
