#!/bin/bash
# Wagner - Ride of the Valkyries (WWV 86B)
# The famous "Kill the Wabbit!" theme from What's Opera, Doc?
# Actual melody transcription

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/examples/demo-valkyries.wav"

echo "=== Wagner: Ride of the Valkyries ==="
echo "\"Kill the Wabbit!\" - The famous galloping theme"
echo ""

# The Ride of the Valkyries is in B minor, 9/8 time
# The iconic theme: da-da-da-DUM-da, da-da-da-DUM-da
# Key motif rises: B-D, then D-F#, then continues upward

# Main theme - French Horn (patch 60) - the iconic melody
# First phrase: B B B | D -- B | B B B | D -- B
THEME="B4/8 B4/8 B4/8 D5/4 B4/8 B4/8 B4/8 B4/8 D5/4 B4/8"
# Second phrase rises: D D D | F# -- D | D D D | F# -- D
THEME="${THEME} D5/8 D5/8 D5/8 F#5/4 D5/8 D5/8 D5/8 D5/8 F#5/4 D5/8"
# Third phrase peaks: F# F# F# | A -- F# | continues
THEME="${THEME} F#5/8 F#5/8 F#5/8 A5/4 F#5/8 F#5/8 F#5/8 F#5/8 A5/4 F#5/8"
# Resolution back down
THEME="${THEME} D5/8 D5/8 D5/8 F#5/4 D5/8 B4/8 B4/8 B4/8 D5/2"

echo "Generating French Horn (main theme)..."
"${BIN}/seq" --notes "${THEME}" --bpm 152 --ch 0 --patch 60 --vel 110 \
  > /tmp/valkyries-horn.jsonl

# Second horn - octave lower for power
THEME_LOW="B3/8 B3/8 B3/8 D4/4 B3/8 B3/8 B3/8 B3/8 D4/4 B3/8"
THEME_LOW="${THEME_LOW} D4/8 D4/8 D4/8 F#4/4 D4/8 D4/8 D4/8 D4/8 F#4/4 D4/8"
THEME_LOW="${THEME_LOW} F#4/8 F#4/8 F#4/8 A4/4 F#4/8 F#4/8 F#4/8 F#4/8 A4/4 F#4/8"
THEME_LOW="${THEME_LOW} D4/8 D4/8 D4/8 F#4/4 D4/8 B3/8 B3/8 B3/8 D4/2"

echo "Generating Second Horn (octave doubling)..."
"${BIN}/seq" --notes "${THEME_LOW}" --bpm 0 --ch 1 --patch 60 --vel 100 \
  > /tmp/valkyries-horn2.jsonl

# Strings - driving accompaniment (patch 48 = String Ensemble)
# Galloping rhythm on the tonic
STRINGS="B3/8 F#3/8 D3/8 B3/8 F#3/8 D3/8 B3/8 F#3/8 D3/8 B3/8 F#3/8 D3/8"
STRINGS="${STRINGS} B3/8 F#3/8 D3/8 B3/8 F#3/8 D3/8 B3/8 F#3/8 D3/8 B3/8 F#3/8 D3/8"
STRINGS="${STRINGS} D4/8 A3/8 F#3/8 D4/8 A3/8 F#3/8 D4/8 A3/8 F#3/8 D4/8 A3/8 F#3/8"
STRINGS="${STRINGS} B3/8 F#3/8 D3/8 B3/8 F#3/8 D3/8 B3/2"

echo "Generating Strings (galloping accompaniment)..."
"${BIN}/seq" --notes "${STRINGS}" --bpm 0 --ch 2 --patch 48 --vel 85 \
  > /tmp/valkyries-strings.jsonl

# Bass - Cello/Contrabass foundation (patch 42 = Cello)
BASS="B2/4 B2/8 B2/4 B2/8 B2/4 B2/8 B2/4 B2/8"
BASS="${BASS} D3/4 D3/8 D3/4 D3/8 D3/4 D3/8 D3/4 D3/8"
BASS="${BASS} F#3/4 F#3/8 F#3/4 F#3/8 F#3/4 F#3/8 F#3/4 F#3/8"
BASS="${BASS} B2/4 B2/8 B2/4 B2/8 B2/2"

echo "Generating Cello (bass foundation)..."
"${BIN}/seq" --notes "${BASS}" --bpm 0 --ch 3 --patch 42 --vel 95 \
  > /tmp/valkyries-bass.jsonl

# Combine all voices
echo "Combining voices..."
cat /tmp/valkyries-horn.jsonl /tmp/valkyries-horn2.jsonl /tmp/valkyries-strings.jsonl /tmp/valkyries-bass.jsonl \
  | "${BIN}/viz" \
  > /tmp/valkyries-full.jsonl

# Stats
echo ""
echo "Events:"
echo "  Horn 1:  $(grep -c NoteOn /tmp/valkyries-horn.jsonl)"
echo "  Horn 2:  $(grep -c NoteOn /tmp/valkyries-horn2.jsonl)"
echo "  Strings: $(grep -c NoteOn /tmp/valkyries-strings.jsonl)"
echo "  Bass:    $(grep -c NoteOn /tmp/valkyries-bass.jsonl)"

# Convert to MIDI
echo ""
echo "Converting to MIDI..."
cat /tmp/valkyries-full.jsonl | "${BIN}/to-midi" --out /tmp/demo-valkyries.mid

# Render to WAV
echo "Rendering to WAV..."
if [[ -f "$SF2" ]]; then
    fluidsynth -ni -F "$OUTPUT" "$SF2" /tmp/demo-valkyries.mid 2>/dev/null

    DURATION=$(afinfo "$OUTPUT" 2>/dev/null | grep "estimated duration" | awk '{print $3}')
    echo "Created: $OUTPUT (${DURATION}s)"

    echo ""
    echo "Playing..."
    afplay "$OUTPUT"
else
    echo "Soundfont not found: $SF2"
    echo "MIDI file: /tmp/demo-valkyries.mid"
fi

echo ""
echo "=== Done ==="
