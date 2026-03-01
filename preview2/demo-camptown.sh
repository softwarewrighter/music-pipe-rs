#!/bin/bash
# Stephen Foster - Camptown Races (1850)
# "Doo-dah! Doo-dah!" - Lively American folk
# Public domain - composed over 175 years ago

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/preview2/demo-camptown.wav"

echo "=== Stephen Foster: Camptown Races (1850) ==="
echo "Doo-dah! Doo-dah! - Playful American folk"
echo ""

# Key: G major (from The Session ABC notation)
# "The Camptown ladies sing this song, doo-dah, doo-dah"
# ABC: |:ed Bd|ed B2|BA AG/A/|BA AB/d/|ed Bd|ed BG|AG/A/ BA|G2 G2:|

# Fiddle melody (patch 40) - using 16th notes for proper reel feel
# Part A - Verse: "The Camptown ladies sing this song"
MELODY="E5/16 D5/16 B4/16 D5/16 E5/16 D5/16 B4/8"
MELODY="${MELODY} B4/16 A4/16 A4/16 G4/16 A4/16 R/16"
MELODY="${MELODY} B4/16 A4/16 A4/16 B4/16 D5/16 R/16"
# "Doo-dah, doo-dah"
MELODY="${MELODY} E5/16 D5/16 B4/16 D5/16 E5/16 D5/16 B4/16 G4/16"
MELODY="${MELODY} A4/16 G4/16 A4/16 R/16 B4/16 A4/16 G4/8"
# Repeat Part A
MELODY="${MELODY} E5/16 D5/16 B4/16 D5/16 E5/16 D5/16 B4/8"
MELODY="${MELODY} B4/16 A4/16 A4/16 G4/16 A4/16 R/16"
MELODY="${MELODY} B4/16 A4/16 A4/16 B4/16 D5/16 R/16"
MELODY="${MELODY} E5/16 D5/16 B4/16 D5/16 E5/16 D5/16 B4/16 G4/16"
MELODY="${MELODY} A4/16 G4/16 A4/16 R/16 B4/16 A4/16 G4/8"

# Part B - Chorus: "Gonna run all night, gonna run all day"
# ABC: |:Bd ef|g2 g2|fe fe|d2 dB/d/|ed Bd|ed BG|AG/A/ BA|G2 G2:|
MELODY="${MELODY} B4/16 D5/16 E5/16 F#5/16 G5/8 G5/8"
MELODY="${MELODY} F#5/16 E5/16 F#5/16 E5/16 D5/8 D5/16 B4/16 D5/16 R/16"
MELODY="${MELODY} E5/16 D5/16 B4/16 D5/16 E5/16 D5/16 B4/16 G4/16"
MELODY="${MELODY} A4/16 G4/16 A4/16 R/16 B4/16 A4/16 G4/4"

echo "Generating fiddle melody..."
"${BIN}/seq" --notes "${MELODY}" --bpm 80 --ch 0 --patch 40 --vel 100 \
  > /tmp/camp-melody.jsonl

# Banjo rhythm (patch 105) - G major chord patterns
BANJO="G3/16 B3/16 D4/16 B3/16 G3/16 B3/16 D4/16 B3/16"
BANJO="${BANJO} G3/16 B3/16 D4/16 B3/16 D3/16 F#3/16 A3/16 F#3/16"
BANJO="${BANJO} G3/16 B3/16 D4/16 B3/16 G3/16 B3/16 D4/16 B3/16"
BANJO="${BANJO} D3/16 F#3/16 A3/16 F#3/16 G3/16 B3/16 D4/16 B3/16"
BANJO="${BANJO} G3/16 B3/16 D4/16 B3/16 G3/16 B3/16 D4/16 B3/16"
BANJO="${BANJO} G3/16 B3/16 D4/16 B3/16 D3/16 F#3/16 A3/16 F#3/16"
BANJO="${BANJO} G3/16 B3/16 D4/16 B3/16 G3/16 B3/16 D4/16 B3/16"
BANJO="${BANJO} D3/16 F#3/16 A3/16 F#3/16 G3/16 B3/16 D4/16 B3/16"
# Part B chords
BANJO="${BANJO} G3/16 B3/16 D4/16 B3/16 C4/16 E4/16 G4/16 E4/16"
BANJO="${BANJO} D3/16 F#3/16 A3/16 F#3/16 D3/16 F#3/16 A3/16 F#3/16"
BANJO="${BANJO} G3/16 B3/16 D4/16 B3/16 G3/16 B3/16 D4/16 B3/16"
BANJO="${BANJO} D3/16 F#3/16 A3/16 F#3/16 G3/8 B3/8"

echo "Generating banjo rhythm..."
"${BIN}/seq" --notes "${BANJO}" --bpm 0 --ch 1 --patch 105 --vel 75 \
  > /tmp/camp-banjo.jsonl

# Pizzicato bass (patch 45) - G major
BASS="G2/8 D3/8 G2/8 D3/8 G2/8 D3/8 D2/8 A2/8"
BASS="${BASS} G2/8 D3/8 G2/8 D3/8 D2/8 A2/8 G2/8 D3/8"
BASS="${BASS} G2/8 D3/8 G2/8 D3/8 G2/8 D3/8 D2/8 A2/8"
BASS="${BASS} G2/8 D3/8 G2/8 D3/8 D2/8 A2/8 G2/8 D3/8"
# Part B bass
BASS="${BASS} G2/8 D3/8 C3/8 G3/8 D2/8 A2/8 D2/8 A2/8"
BASS="${BASS} G2/8 D3/8 G2/8 D3/8 D2/8 A2/8 G2/4"

echo "Generating bass..."
"${BIN}/seq" --notes "${BASS}" --bpm 0 --ch 2 --patch 45 --vel 85 \
  > /tmp/camp-bass.jsonl

# Whistle/piccolo for "doo-dah" (patch 72) - G major
WHISTLE="R/2 R/2 R/2 R/2"
# Part B - "Gonna run all night..."
WHISTLE="${WHISTLE} B5/8 D6/8 E6/8 F#6/8 G6/4 G6/4"
WHISTLE="${WHISTLE} F#6/8 E6/8 F#6/8 E6/8 D6/4 D6/8 B5/8"
WHISTLE="${WHISTLE} D6/8 R/8 E6/8 D6/8 B5/8 D6/8 E6/8 D6/8 B5/8 G5/8"
WHISTLE="${WHISTLE} A5/8 G5/8 A5/8 R/8 B5/8 A5/8 G5/4"

echo "Generating whistle..."
"${BIN}/seq" --notes "${WHISTLE}" --bpm 0 --ch 3 --patch 72 --vel 80 \
  > /tmp/camp-whistle.jsonl

# Combine
echo "Combining voices..."
cat /tmp/camp-melody.jsonl /tmp/camp-banjo.jsonl /tmp/camp-bass.jsonl /tmp/camp-whistle.jsonl \
  | "${BIN}/viz" 2>/dev/null \
  | "${BIN}/trim" --auto \
  > /tmp/camp-full.jsonl

# Stats
echo ""
echo "Events:"
echo "  Fiddle:  $(grep -c NoteOn /tmp/camp-melody.jsonl)"
echo "  Banjo:   $(grep -c NoteOn /tmp/camp-banjo.jsonl)"
echo "  Bass:    $(grep -c NoteOn /tmp/camp-bass.jsonl)"
echo "  Whistle: $(grep -c NoteOn /tmp/camp-whistle.jsonl)"

# Convert to MIDI
echo ""
echo "Converting to MIDI..."
cat /tmp/camp-full.jsonl | "${BIN}/to-midi" --out /tmp/demo-camptown.mid

# Render to WAV
echo "Rendering to WAV..."
if [[ -f "$SF2" ]]; then
    fluidsynth -ni -F /tmp/demo-camptown-raw.wav "$SF2" /tmp/demo-camptown.mid 2>/dev/null

    # Trim to ~12 seconds with fade
    echo "Trimming..."
    ffmpeg -y -i /tmp/demo-camptown-raw.wav -t 12 -af "afade=t=out:st=10:d=2" "$OUTPUT" 2>/dev/null

    DURATION=$(afinfo "$OUTPUT" 2>/dev/null | grep "estimated duration" | awk '{print $3}')
    echo "Created: $OUTPUT (${DURATION}s)"

    echo ""
    echo "Playing..."
    afplay "$OUTPUT"
else
    echo "Soundfont not found: $SF2"
    echo "MIDI file: /tmp/demo-camptown.mid"
fi

echo ""
echo "=== Done ==="
