#!/bin/sh

ffmpeg -y -loglevel error -i /dev/video0 -vframes 1 "$1"

