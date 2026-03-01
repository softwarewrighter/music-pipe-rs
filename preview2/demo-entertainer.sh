#!/bin/bash
# Scott Joplin - The Entertainer (1902)
# Classic ragtime piano - "A Rag Time Two Step"
# Public domain - composed over 120 years ago
#
# Notes extracted from reference MIDI with tick-based timing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/preview2/demo-entertainer.wav"

echo "=== Scott Joplin: The Entertainer (1902) ==="
echo "Using tick-based timing from reference MIDI"
echo ""

# Notes extracted from reference MIDI with exact tick positions
# Format: R/t<ticks> for rests, [chord]/t<dur>*<vel> for simultaneous notes
# 109 notes covering first ~12 seconds

NOTES='R/t1925 D5/t213*86 D6/t226*107 E5/t226*82 E6/t251*92 C5/t248*82 C6/t236*96 [A4,A5]/t506*91 B5/t236*96 B4/t224*70 G5/t208*96 G4/t201*86 R/t277 [D4,D5]/t241*93 E5/t233*85 E4/t234*70 C5/t241*96 C4/t246*78 A4/t471*96 A3/t476*86 R/t2 B4/t241*96 B3/t229*78 R/t9 G3/t193*82 G4/t181*92 R/t299 [D3,D4]/t231*96 E4/t233*88 E3/t226*82 R/t9 C4/t219*92 C3/t236*82 R/t1 A3/t481*100 A2/t491*86 B3/t246*96 B2/t226*86 R/t11 [A2,A3]/t224*93 R/t9 G#3/t221*84 G#2/t228*82 R/t2 G3/t281*100 G2/t309*94 R/t641 [G4,B4,D5]/t274*98 G5/t236*96 [G1,G2]/t166*88 R/t312 [D4,G4,B4]/t236*84 D#4/t218*78 R/t32 [C3,E4]/t226*91 C5/t458*104 [E3,G3,C4]/t209*74 R/t24 E4/t256*81 [G2,G3]/t203*86 C5/t436*100 R/t32 E4/t258*84 [G3,C4]/t203*82 A#3/t184*67 R/t39 C5/t1171*104 [F2,F3]/t213*84 R/t267 [A3,C4]/t178*86 R/t304 [E2,E3]/t191*84 R/t41 C5/t126*88 [E5,C6]/t126*100 R/t91 [G3,C4,D5,F5,D6]/t211*88 R/t22 F#5/t115*88 [D#5,D#6]/t115*83 R/t87 [E5,G5,E6]/t115*104 G2/t154*94 R/t86 [C5,E5,C6]/t115*87 R/t123 [E3,G3,C4,D5,F5,D6]/t238*90 [E5,G5,E6]/t319*97 G2/t181*94 R/t52 B5/t115*100 [B4,D5]/t115*100 R/t125 [D5,F5,D6]/t299*96 [F3,G3,B3]/t206*78 R/t271 C3/t241*90'

echo "Generating with tick-based timing..."
echo "" | "${BIN}/seq" --notes "${NOTES}" --bpm 200 --ch 0 --patch 0 \
  > /tmp/entertainer-tick.jsonl

NOTE_COUNT=$(grep -c NoteOn /tmp/entertainer-tick.jsonl)
echo "Generated ${NOTE_COUNT} notes"

# Light humanize - don't over-process since timing is already human
echo "Adding subtle humanize..."
cat /tmp/entertainer-tick.jsonl \
  | "${BIN}/humanize" --jitter-ticks 4 --jitter-vel 5 \
  | "${BIN}/trim" --auto \
  > /tmp/entertainer-full.jsonl

# Convert to MIDI
echo "Converting to MIDI..."
cat /tmp/entertainer-full.jsonl | "${BIN}/to-midi" --out /tmp/demo-entertainer.mid

# Render to WAV
echo "Rendering to WAV..."
if [[ -f "$SF2" ]]; then
    fluidsynth -ni -F /tmp/demo-entertainer-raw.wav "$SF2" /tmp/demo-entertainer.mid 2>/dev/null

    # Trim to ~12 seconds with fade
    echo "Trimming..."
    ffmpeg -y -i /tmp/demo-entertainer-raw.wav -t 12 -af "afade=t=out:st=10:d=2" "$OUTPUT" 2>/dev/null

    DURATION=$(afinfo "$OUTPUT" 2>/dev/null | grep "estimated duration" | awk '{print $3}')
    echo "Created: $OUTPUT (${DURATION}s)"

    echo ""
    echo "Playing..."
    afplay "$OUTPUT"
else
    echo "Soundfont not found: $SF2"
    echo "MIDI file: /tmp/demo-entertainer.mid"
fi

echo ""
echo "=== Done ==="
