#!/usr/bin/env bash
# Cut one 5-second window out of a slide-transition bed (examples/video-beds.py).
#
#   examples/slice-5s.sh CLIP.wav START [OUT.wav]
#
# START is seconds (e.g. 10 or 12.5), or "first" (0 to 5) or "last" (L-5 to L).
# Starts on a cell boundary (0, 5, 10, ...) give a complete musical phrase and
# never repeat each other; 2.5-s steps are also bar lines at 96 BPM.
# Adds 8 ms fades at both ends (no clicks) and, for a middle window, a 0.4 s
# fade-out so the phrase does not stop dead; "first" keeps its hard downbeat,
# "last" keeps the clip's own ending.
set -euo pipefail
in=${1:?usage: slice-5s.sh CLIP.wav START|first|last [OUT.wav]}
start=${2:?usage: slice-5s.sh CLIP.wav START|first|last [OUT.wav]}
len=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$in")
case "$start" in
  first) ss=0 ;;
  last)  ss=$(awk -v l="$len" 'BEGIN { printf "%.3f", l - 5 }') ;;
  *)     ss=$start ;;
esac
awk -v s="$ss" -v l="$len" 'BEGIN { exit !(s >= 0 && s + 5 <= l + 0.001) }' \
  || { echo "window $ss..$ss+5 is outside 0..$len" >&2; exit 1; }
tag=$(awk -v s="$ss" 'BEGIN { printf "%05.1f", s }')
out=${3:-"${in%.wav}-${tag}s.wav"}
if [ "$start" = last ]; then
  af="afade=t=in:d=0.008"
else
  af="afade=t=in:d=0.008,afade=t=out:st=4.6:d=0.4"
fi
ffmpeg -y -loglevel error -ss "$ss" -t 5 -i "$in" -af "$af" -c:a pcm_s16le "$out"
echo "$out"
