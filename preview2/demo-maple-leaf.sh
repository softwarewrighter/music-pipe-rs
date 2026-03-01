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
echo "Using tick-based timing from reference MIDI"
echo ""

# Notes extracted from reference MIDI with exact tick positions
# Format: R/t<ticks> for rests, [chord]/t<dur>*<vel> for simultaneous notes
# 127 notes covering first ~12 seconds at 97 BPM

NOTES='R/t712 [D#2,D#3]/t40*96 R/t204 G#3/t156*86 G#2/t164*86 G#4/t88*73 [G#3,C4]/t56*83 D#3/t32*69 D#4/t152*86 D#5/t120*81 R/t16 G#4/t236*66 [G#3,C4]/t72*68 D#3/t40*52 C5/t96*77 R/t40 D#5/t236*77 D#4/t240*91 [A2,A3]/t72*86 R/t84 G4/t88*81 [A#2,A#3]/t192*86 [D#4,D#5]/t184*81 G4/t200*73 [G3,C#4]/t72*68 A#4/t104*77 R/t28 D#4/t580*91 D#5/t480*81 C#4/t76*52 D#3/t140*57 G3/t44*54 R/t200 D#3/t40*86 D#2/t32*91 R/t200 G#3/t156*81 G#2/t156*81 G#4/t84*66 [D#3,G#3,C4]/t40*69 D#5/t156*86 D#4/t184*86 G#4/t248*59 [G#3,C4]/t72*59 [D#3,C5]/t36*54 R/t44 D#5/t240*77 D#4/t232*91 [A2,A3]/t104*94 R/t56 G4/t104*86 [A#2,A#3]/t136*83 D#4/t196*86 D#5/t108*86 R/t24 G4/t208*77 [D#3,G3]/t64*60 C#4/t36*41 A#4/t92*59 R/t40 D#5/t360*77 D#4/t344*81 C#4/t44*37 D#3/t112*66 R/t132 D#3/t48*77 D#2/t48*86 R/t104 D#4/t272*86 D#5/t208*86 E3/t280*108 E2/t288*102 G#4/t284*73 B4/t120*69 R/t20 [E4,E5]/t72*86 R/t16 D#2/t72*81 D#3/t56*73 R/t88 D#5/t56*91 D#4/t48*81 R/t28 [D#2,D#3]/t56*91 R/t96 D#5/t192*91 D#4/t240*91 E3/t200*108 E2/t196*108 G#4/t260*77 B4/t148*77 E5/t76*86 E4/t60*77 R/t36 [D#2,D#3]/t304*83 [D#4,D#5]/t36*105 R/t196 G#1/t208*91 G#2/t176*69 B2/t160*54 G#3/t76*73 R/t28 G#2/t164*108 G#3/t244*66 B3/t152*59 G#4/t120*69 G#3/t164*120 G#4/t252*59 B4/t148*66 G#5/t100*77 G#4/t164*120 G#5/t200*81 B5/t164*65 G#6/t120*81 G#5/t48*86 [D4,G#4]/t60*83 B4/t40*81 F4/t36*77 R/t196 [D4,B4,G#5]/t44*87 [F4,G#4]/t40*75 G#6/t44*91 R/t196 [G#4,B4,G#5]/t48*86 [D4,F4,G#6]/t32*87'

echo "Generating with tick-based timing..."
echo "" | "${BIN}/seq" --notes "${NOTES}" --bpm 130 --ch 0 --patch 0 \
  > /tmp/maple-tick.jsonl

NOTE_COUNT=$(grep -c NoteOn /tmp/maple-tick.jsonl)
echo "Generated ${NOTE_COUNT} notes"

# Light humanize
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
