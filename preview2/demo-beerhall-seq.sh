#!/bin/bash
# Beer Barrel Polka (Rosamunde) - Traditional
# "Roll Out the Barrel" - Czech/German polka classic
# Public domain melody (1927 Czech, 1939 English lyrics)
#
# Notes extracted from reference MIDI bar 68 (chorus)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/preview2/demo-beerhall-seq.wav"

echo "=== Beer Barrel Polka (seq) ==="
echo "Roll Out the Barrel - chorus from reference MIDI"

# Notes extracted from reference MIDI bar 68 onwards (chorus)
# 245 notes, ~32 seconds at 220 BPM

NOTES='A#4/t3840*23 [E4,G4]/t480*23 G2/t480*23 [E4,G4]/t480*23 C2/t480*23 [E4,G4]/t480*23 [G2,D5]/t480*23 [E4,A#4]/t480*23 C2/t480*23 [E4,A#4]/t480*23 [G2,D5]/t480*23 [E4,A#4]/t480*23 C2/t360*23 R/t120 [E4,A#4,C#5]/t480*23 [G2,E4,A#4,D5]/t480*23 [G4,A#4,E5]/t480*23 C2/t480*23 [G4,A#4]/t480*23 G2/t480*23 [G4,A#4]/t480*23 C2/t480*23 [G4,A#4]/t480*23 [G2,G4,A#4,D5]/t480*23 [G4,A#4,E5]/t960*23 C2/t480*23 [G4,A#4,D5]/t480*23 [G2,G4,A#4,E5]/t480*23 [G4,A#4,D5]/t960*23 C2/t480*23 [G4,A#4,C#5]/t480*23 [F2,F4,A4,C5]/t480*23 C2/t480*23 R/t480 F2/t480*23 R/t480 C2/t480*23 R/t480 [F2,C5]/t480*23 [F4,A4]/t480*23 C2/t480*23 [F4,A4]/t480*23 [F2,C5]/t480*23 [F4,A4]/t480*23 C2/t480*23 [F4,G#4,B4]/t480*23 [F2,F4,A4,C5]/t480*23 [F4,A4,D5]/t960*23 C2/t480*23 [F4,A4]/t480*23 F2/t480*23 [F4,A4]/t480*23 C2/t480*23 [F4,A4]/t480*23 [F2,F4,A4,C5]/t480*23 [F4,A4,D5]/t960*23 C2/t480*23 [F4,A4,C5]/t480*23 [F2,D#4,A4,D5]/t480*23 [D#4,A4,C5]/t960*23 F2/t480*23 [D#4,F4]/t480*23 [A#2,F4,A#4,D5]/t960*23 [A2,F#4,C5]/t960*23 [G2,G4,A#4]/t960*23 D3/t960*23 [A#2,D4,G4]/t480*23 [D4,A4]/t480*23 [A#2,D4,A#4]/t480*23 [D4,C5]/t480*23 [B2,F4,G#4,E5]/t480*23 B2/t480*23 [F4,G#4,D5]/t480*23 [C3,F4,A4,D5]/t600*23 [F4,A4,C5]/t1440*23 F3/t480*23 D#3/t480*23 [D3,F#4]/t480*23 [D2,F#4,B4]/t480*23 [F#4,C5]/t480*23 [G2,F4,B4,D5]/t480*23 A2/t480*23 B2/t480*23 G2/t480*23 [C3,G4,A#4,E5]/t480*23 C2/t480*23 D2/t480*23 E2/t480*23 [F2,F4,A4,F5]/t480*23 C5/t240*24 D5/t240*24 [F#2,D#4,A4,C5]/t480*24 C5/t240*24 D5/t240*24 [G2,E4,A#4,C5]/t480*24 [C4,E4]/t240*25 [D4,F4]/t240*25 [C2,C3,E4,G4]/t960*25 [F4,A4]/t240*25 [G4,A#4]/t240*25 [G#4,B4]/t240*25 [F2,C5]/t480*23 [F4,A4]/t480*23 C3/t480*23 [F4,A4]/t480*23 [F2,C5]/t480*23 [F4,A4]/t480*23 C2/t480*23 [F4,G#4,B4]/t480*23 [F2,F4,A4,C5]/t480*23 [F4,A4,D5]/t960*23 C2/t480*23 [F4,A4]/t480*23 F2/t480*23 [F4,A4]/t480*23 C2/t480*23 [F4,A4]/t480*23 [F2,F4,A4,C5]/t480*23'

echo "Generating with tick-based timing..."
echo "" | "${BIN}/seq" --notes "${NOTES}" --bpm 220 --ch 0 --patch 21 \
  > /tmp/beer-tick.jsonl

NOTE_COUNT=$(grep -c NoteOn /tmp/beer-tick.jsonl)
echo "Generated ${NOTE_COUNT} notes"

# Light humanize
echo "Adding subtle humanize..."
cat /tmp/beer-tick.jsonl \
  | "${BIN}/humanize" --jitter-ticks 4 --jitter-vel 5 \
  | "${BIN}/trim" --auto \
  > /tmp/beer-full.jsonl

# Convert to MIDI
echo "Converting to MIDI..."
cat /tmp/beer-full.jsonl | "${BIN}/to-midi" --out /tmp/demo-beerhall.mid

# Render to WAV
echo "Rendering to WAV..."
fluidsynth -ni -F /tmp/beer-raw.wav "$SF2" /tmp/demo-beerhall.mid 2>/dev/null
ffmpeg -y -i /tmp/beer-raw.wav -t 32 -af "afade=t=out:st=30:d=2" "$OUTPUT" 2>/dev/null
echo "Created: $OUTPUT"
afplay "$OUTPUT"
