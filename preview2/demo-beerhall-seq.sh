#!/bin/bash
# Beer Barrel Polka (Rosamunde) - Traditional
# "Roll Out the Barrel" - Czech/German polka classic
# Public domain melody (1927 Czech, 1939 English lyrics)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/preview2/demo-beerhall-seq.wav"

echo "=== Beer Barrel Polka (seq) ==="
echo "Roll Out the Barrel - traditional oom-pah"

# Key: F major, 2/4 polka time, ~120 BPM
# The famous "Roll out the barrel" chorus

# Accordion melody (patch 21)
# "Roll out the barrel, we'll have a barrel of fun"
MELODY="C5/8 C5/8 C5/4 D5/8 C5/8 A4/4"
MELODY="${MELODY} G4/8 G4/8 G4/4 A4/8 G4/8 F4/4"
MELODY="${MELODY} F4/8 G4/8 A4/8 A#4/8 C5/4 A4/4"
MELODY="${MELODY} G4/2 R/2"
# "Roll out the barrel, we've got the blues on the run"
MELODY="${MELODY} C5/8 C5/8 C5/4 D5/8 C5/8 A4/4"
MELODY="${MELODY} G4/8 G4/8 G4/4 A4/8 G4/8 F4/4"
MELODY="${MELODY} A4/8 G4/8 F4/8 E4/8 D4/4 C4/4"
MELODY="${MELODY} F4/2 R/2"

echo "Generating accordion..."
"${BIN}/seq" --notes "${MELODY}" --bpm 120 --ch 0 --patch 21 --vel 95 \
  > /tmp/beer-melody.jsonl

# Tuba - oom (bass notes on beat 1)
TUBA="F2/4 R/4 C2/4 R/4 C2/4 R/4 F2/4 R/4"
TUBA="${TUBA} F2/4 R/4 C2/4 R/4 C2/4 R/4 F2/4 R/4"
TUBA="${TUBA} F2/4 R/4 C2/4 R/4 C2/4 R/4 F2/4 R/4"
TUBA="${TUBA} C2/4 R/4 C2/4 R/4 F2/2"

echo "Generating tuba..."
"${BIN}/seq" --notes "${TUBA}" --bpm 0 --ch 1 --patch 58 --vel 100 \
  > /tmp/beer-tuba.jsonl

# Trombone - pah (chords on beat 2)
PAH="R/4 A3/8 C4/8 R/4 G3/8 C4/8 R/4 G3/8 C4/8 R/4 A3/8 C4/8"
PAH="${PAH} R/4 A3/8 C4/8 R/4 G3/8 C4/8 R/4 G3/8 C4/8 R/4 A3/8 C4/8"
PAH="${PAH} R/4 A3/8 C4/8 R/4 G3/8 C4/8 R/4 G3/8 C4/8 R/4 A3/8 C4/8"
PAH="${PAH} R/4 G3/8 C4/8 R/4 G3/8 C4/8 A3/2"

echo "Generating trombone..."
"${BIN}/seq" --notes "${PAH}" --bpm 0 --ch 2 --patch 57 --vel 75 \
  > /tmp/beer-trombone.jsonl

# Combine
cat /tmp/beer-melody.jsonl /tmp/beer-tuba.jsonl /tmp/beer-trombone.jsonl \
  | "${BIN}/viz" 2>/dev/null | "${BIN}/trim" --auto \
  | "${BIN}/to-midi" --out /tmp/demo-beerhall.mid

fluidsynth -ni -F /tmp/beer-raw.wav "$SF2" /tmp/demo-beerhall.mid 2>/dev/null
ffmpeg -y -i /tmp/beer-raw.wav -t 12 -af "afade=t=out:st=10:d=2" "$OUTPUT" 2>/dev/null
echo "Created: $OUTPUT"
afplay "$OUTPUT"
