#!/bin/bash
# Scott Joplin - Maple Leaf Rag (1899)
# The most famous ragtime composition
# Public domain - composed over 125 years ago
#
# Notes extracted from reference MIDI with tick-based timing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/preview2/demo-maple-leaf.wav"

echo "=== Scott Joplin: Maple Leaf Rag (1899) ==="
echo "Using tick-based timing from reference analysis"
echo ""

# Notes extracted from reference MIDI with exact tick positions
# Format: R/t<ticks> for rests, [chord]/t<dur>*<vel> for simultaneous notes
# 86 notes covering first ~12 seconds

NOTES='R/t712 [D#2,D#3]/t60*96 R/t184 G#3/t60*86 G#2/t60*86 R/t88 G#4/t60*73 R/t24 [G#3,C4]/t60*83 D#3/t60*69 D#4/t60*86 D#5/t60*81 R/t76 G#4/t60*66 R/t28 [G#3,C4]/t60*68 D#3/t60*52 C5/t60*77 R/t76 D#5/t60*77 D#4/t60*91 R/t24 [A2,A3]/t60*86 R/t96 G4/t60*81 R/t28 [A#2,A#3]/t60*86 [D#4,D#5]/t60*81 R/t68 G4/t60*73 R/t36 [G3,C#4]/t60*68 A#4/t60*77 R/t72 D#4/t60*91 D#5/t60*81 R/t20 C#4/t60*52 D#3/t60*57 G3/t60*54 R/t184 D#3/t60*86 D#2/t60*91 R/t172 G#3/t60*81 G#2/t60*81 R/t92 G#4/t60*66 R/t20 [D#3,G#3,C4]/t60*69 D#5/t60*86 D#4/t60*86 R/t80 G#4/t60*59 R/t28 [G#3,C4]/t60*59 [D#3,C5]/t60*54 R/t76 D#5/t60*77 D#4/t60*91 R/t16 [A2,A3]/t60*94 R/t100 G4/t60*86 R/t28 [A#2,A#3]/t60*83 D#4/t60*86 D#5/t60*86 R/t72 G4/t60*77 R/t36 [D#3,G3]/t60*60 C#4/t60*41 A#4/t60*59 R/t72 D#5/t60*77 D#4/t60*81 R/t20 C#4/t60*37 D#3/t60*66 R/t184 D#3/t60*77 D#2/t60*86 R/t92 D#4/t60*86 D#5/t60*86 R/t20 E3/t60*108 E2/t60*102 R/t88 G#4/t60*73 R/t52 B4/t60*69 R/t80 [E4,E5]/t60*86 R/t28 D#2/t60*81 D#3/t60*73 R/t84 D#5/t60*91 D#4/t60*81 R/t16 [D#2,D#3]/t60*91 R/t92 D#5/t60*91 D#4/t60*91 R/t24 E3/t60*108 E2/t60*108'

echo "Generating with tick-based timing..."
echo "" | "${BIN}/seq" --notes "${NOTES}" --bpm 116 --ch 0 --patch 0 \
  > /tmp/maple-tick.jsonl

NOTE_COUNT=$(grep -c NoteOn /tmp/maple-tick.jsonl)
echo "Generated ${NOTE_COUNT} notes"

# Light humanize - don't over-process since timing is already human
echo "Adding subtle humanize..."
cat /tmp/maple-tick.jsonl \
  | "${BIN}/humanize" --jitter-ticks 4 --jitter-vel 5 \
  | "${BIN}/trim" --auto \
  > /tmp/maple-full.jsonl

# Convert to MIDI
echo "Converting to MIDI..."
cat /tmp/maple-full.jsonl | "${BIN}/to-midi" --out /tmp/demo-maple-leaf.mid

# Render to WAV
echo "Rendering to WAV..."
if [[ -f "$SF2" ]]; then
    fluidsynth -ni -F /tmp/demo-maple-leaf-raw.wav "$SF2" /tmp/demo-maple-leaf.mid 2>/dev/null

    # Trim to ~12 seconds with fade
    echo "Trimming..."
    ffmpeg -y -i /tmp/demo-maple-leaf-raw.wav -t 12 -af "afade=t=out:st=10:d=2" "$OUTPUT" 2>/dev/null

    DURATION=$(afinfo "$OUTPUT" 2>/dev/null | grep "estimated duration" | awk '{print $3}')
    echo "Created: $OUTPUT (${DURATION}s)"

    echo ""
    echo "Playing..."
    afplay "$OUTPUT"
else
    echo "Soundfont not found: $SF2"
    echo "MIDI file: /tmp/demo-maple-leaf.mid"
fi

echo ""
echo "=== Done ==="
