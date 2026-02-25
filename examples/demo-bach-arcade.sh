#!/bin/bash
# Bach Toccata and Fugue - 8-bit Arcade Style (Gyruss-inspired)
# Single channel, square wave lead, fast and punchy

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/examples/demo-bach-arcade.wav"

echo "=== Bach Toccata - 8-bit Arcade Style ==="
echo "Single channel, square wave lead (patch 80)"
echo ""

# THE FAMOUS OPENING - single melody line, arcade tempo
# patch 80 = Square Lead (closest to 8-bit square wave)

# First phrase: D -> mordent -> rapid descending run
MELODY="D5/4*127 C#5/32*120 D5/32*120 A4/32*115 G4/32*110 F4/32*110 E4/32*105 D4/32*105 C#4/32*110 D4/8*120"

# Brief pause then second phrase on A
MELODY="${MELODY} R/8 A4/4*125 G#4/32*115 A4/32*115 E4/32*110 D4/32*105 C4/32*105 B3/32*100 A3/32*100 G#3/32*105 A3/8*115"

# Third phrase back to D - quick repeat
MELODY="${MELODY} R/8 D5/4*127 C#5/32*120 D5/32*127 A4/32*115 G4/32 F4/32 E4/32 D4/32 C#4/32*115 D4/4*127"

# Low D finish (arcade games often end on a low note)
MELODY="${MELODY} R/8 D3/2*127"

echo "Generating 8-bit melody..."
"${BIN}/seq" --notes "${MELODY}" --bpm 140 --ch 0 --patch 80 --vel 120 \
  | "${BIN}/viz" \
  > /tmp/bach-arcade.jsonl

# Stats
NOTES=$(grep -c NoteOn /tmp/bach-arcade.jsonl || echo 0)
echo ""
echo "Events: ${NOTES} notes"

# Convert to MIDI
echo ""
echo "Converting to MIDI..."
cat /tmp/bach-arcade.jsonl | "${BIN}/to-midi" --out /tmp/demo-bach-arcade.mid

# Render to WAV
echo "Rendering to WAV..."
if [[ -f "$SF2" ]]; then
    fluidsynth -ni -F "$OUTPUT" "$SF2" /tmp/demo-bach-arcade.mid 2>/dev/null

    DURATION=$(afinfo "$OUTPUT" 2>/dev/null | grep "estimated duration" | awk '{print $3}')
    echo "Created: $OUTPUT (${DURATION}s)"

    # Play
    echo ""
    echo "Playing..."
    afplay "$OUTPUT"
else
    echo "Soundfont not found: $SF2"
    echo "MIDI file: /tmp/demo-bach-arcade.mid"
fi

echo ""
echo "=== Done ==="
