#!/bin/bash

echo "Killing pypanel process"
pkill -9 pypanel
echo "Starting pypanel"
pypanel &

