#!/bin/bash

export DIR=`date`

mkdir "$DIR"

echo -n 0 > i

watch -p -n 60 'FILE="$DIR/`cat i`.jpg" && ./snap.sh "$FILE" && I=`cat i` && I=`echo "$I+1" | bc` && echo -n $I > i'
