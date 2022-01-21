#!/bin/bash

ASSEMBLIES=$1
PAF=$2
GFA=$3
k=$4
B=$5
LOG=$6
SECS=$7

hostname

cd /scratch

# Start the process to fill the log file
(while true; do (date +%s; du -s .; ls -s; echo) >>"$LOG"; sleep "$SECS"; done) &
SIZE_DEMON_PID=$!

# Run seqwish
\time -v ~/tools/seqwish/bin/seqwish-ccfefb016fcfc9937817ce61dc06bbcf382be75e -t 48 -s "$ASSEMBLIES" -p "$PAF" -g "$GFA" -k "$k" -B "$B" -P

# Stop filling the log file
kill $SIZE_DEMON_PID

# Clean the directory (in case seqwish ends incorrectly)
rm -f "$GFA".{sqa,sqi,sql,sqn,sqp,sqq,sqs}
