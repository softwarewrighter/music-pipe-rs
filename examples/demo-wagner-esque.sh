#!/bin/bash
# Wagner-esque Germanic Opera - Algorithmic Background Music
# "Kill the Wabbit!" - Ride of the Valkyries style
# Inspired by What's Opera, Doc? and Der Ring des Nibelungen

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/examples/demo-wagner-esque.wav"

SEED=1813  # Wagner's birth year

echo "=== Wagner-esque Germanic Opera ==="
echo "\"Kill the Wabbit!\" - Ride of the Valkyries style"
echo ""

# French Horn - heroic fanfare (patch 60 = French Horn)
echo "Generating French Horn (Valkyrie fanfare)..."
"${BIN}/seed" $SEED \
  | "${BIN}/motif" --base 53 --notes 20 --complexity 5 --bpm 152 --ch 0 --vel 105 \
      --patch 60 --dur 0.5 --rest-prob 0.15 \
  | "${BIN}/scale" --root B --mode minor \
  > /tmp/wagner-horn.jsonl

# Tuba - pompous cartoony bass (patch 58 = Tuba)
echo "Generating Tuba (pompous villain bass)..."
"${BIN}/seed" $((SEED+1)) \
  | "${BIN}/motif" --base 36 --notes 14 --complexity 2 --bpm 0 --ch 1 --vel 100 \
      --patch 58 --dur 0.75 \
  | "${BIN}/scale" --root B --mode minor \
  > /tmp/wagner-tuba.jsonl

# Xylophone - cartoony accents (patch 13 = Xylophone)
echo "Generating Xylophone (cartoony accents)..."
"${BIN}/seed" $((SEED+2)) \
  | "${BIN}/motif" --base 72 --notes 16 --complexity 7 --bpm 0 --ch 2 --vel 85 \
      --patch 13 --dur 0.25 --rest-prob 0.3 \
  | "${BIN}/scale" --root B --mode minor \
  > /tmp/wagner-xylo.jsonl

# Vibraphone - magical shimmer (patch 11 = Vibraphone)
echo "Generating Vibraphone (magical shimmer)..."
"${BIN}/seed" $((SEED+3)) \
  | "${BIN}/motif" --base 65 --notes 12 --complexity 4 --bpm 0 --ch 3 --vel 70 \
      --patch 11 --dur 1.0 --chord-prob 0.3 \
  | "${BIN}/scale" --root B --mode minor \
  > /tmp/wagner-vibe.jsonl

# Combine all voices
echo "Combining voices..."
cat /tmp/wagner-horn.jsonl /tmp/wagner-tuba.jsonl /tmp/wagner-xylo.jsonl /tmp/wagner-vibe.jsonl \
  | "${BIN}/viz" \
  > /tmp/wagner-full.jsonl

# Stats
echo ""
echo "Events:"
echo "  Horn:       $(grep -c NoteOn /tmp/wagner-horn.jsonl)"
echo "  Tuba:       $(grep -c NoteOn /tmp/wagner-tuba.jsonl)"
echo "  Xylophone:  $(grep -c NoteOn /tmp/wagner-xylo.jsonl)"
echo "  Vibraphone: $(grep -c NoteOn /tmp/wagner-vibe.jsonl)"

# Convert to MIDI
echo ""
echo "Converting to MIDI..."
cat /tmp/wagner-full.jsonl | "${BIN}/to-midi" --out /tmp/demo-wagner-esque.mid

# Render to WAV
echo "Rendering to WAV..."
if [[ -f "$SF2" ]]; then
    fluidsynth -ni -F "$OUTPUT" "$SF2" /tmp/demo-wagner-esque.mid 2>/dev/null

    DURATION=$(afinfo "$OUTPUT" 2>/dev/null | grep "estimated duration" | awk '{print $3}')
    echo "Created: $OUTPUT (${DURATION}s)"

    echo ""
    echo "Playing..."
    afplay "$OUTPUT"
else
    echo "Soundfont not found: $SF2"
    echo "MIDI file: /tmp/demo-wagner-esque.mid"
fi

echo ""
echo "=== Done ==="
