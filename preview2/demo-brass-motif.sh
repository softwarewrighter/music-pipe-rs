#!/bin/bash
# New Orleans Brass-esque - Algorithmic Generation
# March/second line style (motif-based)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/preview2/demo-brass-motif.wav"

SEED=${1:-1901}

echo "=== New Orleans Brass-esque (motif) ==="
echo "Seed: $SEED"

# Trumpet lead
"${BIN}/seed" $SEED \
  | "${BIN}/motif" --base 72 --notes 30 --complexity 5 --bpm 112 --ch 0 --vel 100 \
      --patch 56 --dur 0.75 --rest-prob 0.2 \
  | "${BIN}/scale" --root C --mode major > /tmp/brass-trumpet.jsonl

# Trombone harmony
"${BIN}/seed" $((SEED+1)) \
  | "${BIN}/motif" --base 60 --notes 25 --complexity 4 --bpm 0 --ch 1 --vel 85 \
      --patch 57 --dur 1.0 --rest-prob 0.15 \
  | "${BIN}/scale" --root C --mode major > /tmp/brass-trombone.jsonl

# Clarinet fills
"${BIN}/seed" $((SEED+2)) \
  | "${BIN}/motif" --base 72 --notes 20 --complexity 6 --bpm 0 --ch 2 --vel 70 \
      --patch 71 --dur 0.5 --rest-prob 0.3 \
  | "${BIN}/scale" --root C --mode major > /tmp/brass-clarinet.jsonl

# Tuba bass
"${BIN}/seed" $((SEED+3)) \
  | "${BIN}/motif" --base 36 --notes 25 --complexity 2 --bpm 0 --ch 3 --vel 110 \
      --patch 58 --dur 1.0 \
  | "${BIN}/scale" --root C --mode major > /tmp/brass-tuba.jsonl

# Drums - march pattern
"${BIN}/seed" $((SEED+4)) \
  | "${BIN}/euclid" --steps 8 --pulses 4 --note 38 --ch 9 --bpm 0 --repeat 20 \
      --vel 85 --vel-var 15 > /tmp/brass-snare.jsonl

"${BIN}/seed" $((SEED+5)) \
  | "${BIN}/euclid" --steps 4 --pulses 2 --note 36 --ch 9 --bpm 0 --repeat 20 \
      --vel 100 > /tmp/brass-kick.jsonl

cat /tmp/brass-trumpet.jsonl /tmp/brass-trombone.jsonl /tmp/brass-clarinet.jsonl \
    /tmp/brass-tuba.jsonl /tmp/brass-snare.jsonl /tmp/brass-kick.jsonl \
  | "${BIN}/viz" 2>/dev/null | "${BIN}/trim" --auto \
  | "${BIN}/to-midi" --out /tmp/demo-brass.mid

fluidsynth -ni -F /tmp/brass-raw.wav "$SF2" /tmp/demo-brass.mid 2>/dev/null
ffmpeg -y -i /tmp/brass-raw.wav -t 12 -af "afade=t=out:st=10:d=2" "$OUTPUT" 2>/dev/null
echo "Created: $OUTPUT"
afplay "$OUTPUT"
