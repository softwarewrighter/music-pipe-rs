#!/bin/bash
# Jazz trio demo - piano, bass, drums

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"

SEED=7777

echo "=== Jazz Trio Demo ==="
echo ""

# Piano - bluesy, complex
echo "Piano (ch 0)..."
"${BIN}/seed" $SEED \
  | "${BIN}/motif" --base 60 --notes 32 --complexity 8 --bpm 130 --ch 0 --vel 75 --repeat 2 \
  | "${BIN}/scale" --root C --mode blues \
  | "${BIN}/viz" \
  > /tmp/piano.jsonl

# Walking bass - simple, steady
echo "Bass (ch 1)..."
"${BIN}/seed" $((SEED+1)) \
  | "${BIN}/motif" --base 36 --notes 32 --complexity 2 --bpm 0 --ch 1 --vel 90 --repeat 2 \
  | "${BIN}/scale" --root C --mode minor \
  | "${BIN}/viz" \
  > /tmp/bass.jsonl

# Drums - brushes feel
echo "Drums (ch 9)..."
"${BIN}/seed" $SEED | {
  # Snare on 2 and 4 (soft)
  "${BIN}/euclid" --steps 8 --pulses 2 --note 38 --ch 9 --bpm 0 --repeat 16 --vel 45 --rotation 2;
  # Ride cymbal
  "${BIN}/euclid" --steps 8 --pulses 4 --note 51 --ch 9 --bpm 0 --repeat 16 --vel 40;
  # Soft kick
  "${BIN}/euclid" --steps 8 --pulses 2 --note 36 --ch 9 --bpm 0 --repeat 16 --vel 50;
} > /tmp/drums.jsonl

# Combine all parts
echo ""
echo "Combining and humanizing..."
cat /tmp/piano.jsonl /tmp/bass.jsonl /tmp/drums.jsonl \
  | "${BIN}/humanize" --jitter-ticks 15 --jitter-vel 10 \
  | "${BIN}/to-midi" --out /tmp/jazz-trio.mid

# Stats
echo ""
echo "Events:"
echo "  Piano: $(grep -c NoteOn /tmp/piano.jsonl)"
echo "  Bass:  $(grep -c NoteOn /tmp/bass.jsonl)"
echo "  Drums: $(grep -c NoteOn /tmp/drums.jsonl)"

# Play
echo ""
echo "Rendering and playing..."
if [[ -f "$SF2" ]]; then
    fluidsynth -ni -F /tmp/jazz-trio.wav "$SF2" /tmp/jazz-trio.mid 2>/dev/null
    afplay /tmp/jazz-trio.wav
else
    echo "Soundfont not found: $SF2"
    echo "To play: fluidsynth -ni -F out.wav /path/to/soundfont.sf2 /tmp/jazz-trio.mid && afplay out.wav"
fi

echo ""
echo "=== Done ==="
echo "MIDI file: /tmp/jazz-trio.mid"
