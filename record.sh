#!/bin/bash

export I=0
export DIR=`date`

if ! mkdir "$DIR"; then
    exit 1
fi

watch -p -n 1 'FILE="$DIR/$I" && ./snap.sh $FILE && let I=$I+1'
