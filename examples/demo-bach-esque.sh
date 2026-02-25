#!/bin/bash
# Bach-esque Organ Music - Algorithmic Background Music
# Uses church organ with dramatic, high-complexity passages
# Inspired by baroque organ style

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/examples/demo-bach-esque.wav"

SEED=1685  # Bach's birth year

echo "=== Bach-esque Organ Background Music ==="
echo ""

# Upper manual - dramatic flourishes (patch 19 = Church Organ)
echo "Generating upper voice (dramatic flourishes)..."
"${BIN}/seed" $SEED \
  | "${BIN}/motif" --base 62 --notes 48 --complexity 9 --bpm 132 --ch 0 --vel 100 \
      --patch 19 --dur 0.5 --rest-prob 0.1 \
  | "${BIN}/scale" --root D --mode minor \
  > /tmp/bachesque-upper.jsonl

# Lower manual - sustained bass pedal tones
echo "Generating pedal bass..."
"${BIN}/seed" $((SEED+1)) \
  | "${BIN}/motif" --base 38 --notes 12 --complexity 2 --bpm 0 --ch 1 --vel 90 \
      --patch 19 --dur 2.0 \
  | "${BIN}/scale" --root D --mode minor \
  > /tmp/bachesque-bass.jsonl

# Middle voice - counterpoint
echo "Generating middle voice..."
"${BIN}/seed" $((SEED+2)) \
  | "${BIN}/motif" --base 50 --notes 24 --complexity 6 --bpm 0 --ch 2 --vel 85 \
      --patch 19 --dur 0.75 --chord-prob 0.15 \
  | "${BIN}/scale" --root D --mode minor \
  > /tmp/bachesque-mid.jsonl

# Combine all voices
echo "Combining voices..."
cat /tmp/bachesque-upper.jsonl /tmp/bachesque-bass.jsonl /tmp/bachesque-mid.jsonl \
  | "${BIN}/viz" \
  > /tmp/bachesque-full.jsonl

# Stats
echo ""
echo "Events:"
echo "  Upper: $(grep -c NoteOn /tmp/bachesque-upper.jsonl)"
echo "  Bass:  $(grep -c NoteOn /tmp/bachesque-bass.jsonl)"
echo "  Mid:   $(grep -c NoteOn /tmp/bachesque-mid.jsonl)"

# Convert to MIDI
echo ""
echo "Converting to MIDI..."
cat /tmp/bachesque-full.jsonl | "${BIN}/to-midi" --out /tmp/demo-bach-esque.mid

# Render to WAV
echo "Rendering to WAV..."
if [[ -f "$SF2" ]]; then
    fluidsynth -ni -F "$OUTPUT" "$SF2" /tmp/demo-bach-esque.mid 2>/dev/null

    DURATION=$(afinfo "$OUTPUT" 2>/dev/null | grep "estimated duration" | awk '{print $3}')
    echo "Created: $OUTPUT (${DURATION}s)"

    # Play
    echo ""
    echo "Playing..."
    afplay "$OUTPUT"
else
    echo "Soundfont not found: $SF2"
    echo "MIDI file: /tmp/demo-bach-esque.mid"
fi

echo ""
echo "=== Done ==="
