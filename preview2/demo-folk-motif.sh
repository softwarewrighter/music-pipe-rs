#!/bin/bash
# American Folk-esque - Algorithmic Generation
# Banjo and fiddle style (motif-based)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/preview2/demo-folk-motif.wav"

SEED=${1:-1848}

echo "=== American Folk-esque (motif) ==="
echo "Seed: $SEED"

# Banjo melody
"${BIN}/seed" $SEED \
  | "${BIN}/motif" --base 67 --notes 35 --complexity 4 --bpm 120 --ch 0 --vel 95 \
      --patch 105 --dur 0.5 --rest-prob 0.1 \
  | "${BIN}/scale" --root G --mode major > /tmp/folk-banjo.jsonl

# Fiddle harmony
"${BIN}/seed" $((SEED+1)) \
  | "${BIN}/motif" --base 72 --notes 30 --complexity 5 --bpm 0 --ch 1 --vel 80 \
      --patch 40 --dur 0.5 --rest-prob 0.15 \
  | "${BIN}/scale" --root G --mode major > /tmp/folk-fiddle.jsonl

# Guitar chords
"${BIN}/seed" $((SEED+2)) \
  | "${BIN}/motif" --base 55 --notes 25 --complexity 2 --bpm 0 --ch 2 --vel 65 \
      --patch 25 --dur 1.0 --chord-prob 0.5 \
  | "${BIN}/scale" --root G --mode major > /tmp/folk-guitar.jsonl

cat /tmp/folk-banjo.jsonl /tmp/folk-fiddle.jsonl /tmp/folk-guitar.jsonl \
  | "${BIN}/viz" 2>/dev/null | "${BIN}/trim" --auto \
  | "${BIN}/to-midi" --out /tmp/demo-folk.mid

fluidsynth -ni -F /tmp/folk-raw.wav "$SF2" /tmp/demo-folk.mid 2>/dev/null
ffmpeg -y -i /tmp/folk-raw.wav -t 12 -af "afade=t=out:st=10:d=2" "$OUTPUT" 2>/dev/null
echo "Created: $OUTPUT"
afplay "$OUTPUT"
