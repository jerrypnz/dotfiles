#!/bin/bash

TARGET_DIR=$PWD

if [ -d "$1" ]; then
    TARGET_DIR=$1
fi

cd $TARGET_DIR
tmux new-session -d -s develop -n develop vim
tmux set-option default-path $TARGET_DIR
tmux split-window -h -p 30 ipython
tmux split-window -v
tmux select-pane -t 0
exec tmux -2 attach -d
