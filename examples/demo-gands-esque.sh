#!/bin/bash
# Gilbert & Sullivan-esque British Operetta - Algorithmic Background Music
# Light, witty, bouncy rhythms, cheerful major keys
# Inspired by The Pirates of Penzance, HMS Pinafore, The Mikado

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/examples/demo-gands-esque.wav"

SEED=1842  # Sullivan's birth year

echo "=== Gilbert & Sullivan-esque British Operetta ==="
echo "Light, witty, bouncy rhythms"
echo ""

# Flute - bright, playful melody (patch 73 = Flute)
echo "Generating Flute (playful melody)..."
"${BIN}/seed" $SEED \
  | "${BIN}/motif" --base 72 --notes 32 --complexity 7 --bpm 132 --ch 0 --vel 85 \
      --patch 73 --dur 0.5 --rest-prob 0.15 --swing 0.05 \
  | "${BIN}/scale" --root C --mode major \
  > /tmp/gands-flute.jsonl

# Oboe - comic secondary line (patch 68 = Oboe)
echo "Generating Oboe (comic counterpoint)..."
"${BIN}/seed" $((SEED+1)) \
  | "${BIN}/motif" --base 67 --notes 20 --complexity 5 --bpm 0 --ch 1 --vel 75 \
      --patch 68 --dur 0.5 --rest-prob 0.25 \
  | "${BIN}/scale" --root C --mode major \
  > /tmp/gands-oboe.jsonl

# Pizzicato Strings - bouncy accompaniment (patch 45 = Pizzicato)
echo "Generating Pizzicato Strings (bouncy bass)..."
"${BIN}/seed" $((SEED+2)) \
  | "${BIN}/motif" --base 48 --notes 24 --complexity 3 --bpm 0 --ch 2 --vel 80 \
      --patch 45 --dur 0.25 \
  | "${BIN}/scale" --root C --mode major \
  > /tmp/gands-pizz.jsonl

# Bassoon - pompous comic bass (patch 70 = Bassoon)
echo "Generating Bassoon (pompous bass)..."
"${BIN}/seed" $((SEED+3)) \
  | "${BIN}/motif" --base 41 --notes 16 --complexity 2 --bpm 0 --ch 3 --vel 85 \
      --patch 70 --dur 0.75 --rest-prob 0.1 \
  | "${BIN}/scale" --root C --mode major \
  > /tmp/gands-bassoon.jsonl

# Combine all voices (woodwinds and pizzicato provide all the bounce needed)
echo "Combining voices..."
cat /tmp/gands-flute.jsonl /tmp/gands-oboe.jsonl /tmp/gands-pizz.jsonl /tmp/gands-bassoon.jsonl \
  | "${BIN}/viz" \
  > /tmp/gands-full.jsonl

# Stats
echo ""
echo "Events:"
echo "  Flute:    $(grep -c NoteOn /tmp/gands-flute.jsonl)"
echo "  Oboe:     $(grep -c NoteOn /tmp/gands-oboe.jsonl)"
echo "  Pizz:     $(grep -c NoteOn /tmp/gands-pizz.jsonl)"
echo "  Bassoon:  $(grep -c NoteOn /tmp/gands-bassoon.jsonl)"

# Convert to MIDI
echo ""
echo "Converting to MIDI..."
cat /tmp/gands-full.jsonl | "${BIN}/to-midi" --out /tmp/demo-gands-esque.mid

# Render to WAV
echo "Rendering to WAV..."
if [[ -f "$SF2" ]]; then
    fluidsynth -ni -F "$OUTPUT" "$SF2" /tmp/demo-gands-esque.mid 2>/dev/null

    DURATION=$(afinfo "$OUTPUT" 2>/dev/null | grep "estimated duration" | awk '{print $3}')
    echo "Created: $OUTPUT (${DURATION}s)"

    echo ""
    echo "Playing..."
    afplay "$OUTPUT"
else
    echo "Soundfont not found: $SF2"
    echo "MIDI file: /tmp/demo-gands-esque.mid"
fi

echo ""
echo "=== Done ==="
