#!/bin/bash
# Fiddle Reel-esque - Algorithmic Generation
# Fast square dance style (motif-based)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/preview2/demo-reel-motif.wav"

SEED=${1:-1820}

echo "=== Fiddle Reel-esque (motif) ==="
echo "Seed: $SEED"

# Lead fiddle - fast 16ths
"${BIN}/seed" $SEED \
  | "${BIN}/motif" --base 74 --notes 50 --complexity 6 --bpm 130 --ch 0 --vel 100 \
      --patch 40 --dur 0.25 --rest-prob 0.05 \
  | "${BIN}/scale" --root G --mode major > /tmp/reel-f1.jsonl

# Second fiddle
"${BIN}/seed" $((SEED+1)) \
  | "${BIN}/motif" --base 67 --notes 45 --complexity 5 --bpm 0 --ch 1 --vel 75 \
      --patch 40 --dur 0.25 --rest-prob 0.1 \
  | "${BIN}/scale" --root G --mode major > /tmp/reel-f2.jsonl

# Banjo
"${BIN}/seed" $((SEED+2)) \
  | "${BIN}/motif" --base 55 --notes 40 --complexity 3 --bpm 0 --ch 2 --vel 70 \
      --patch 105 --dur 0.5 --chord-prob 0.3 \
  | "${BIN}/scale" --root G --mode major > /tmp/reel-banjo.jsonl

# Bass
"${BIN}/seed" $((SEED+3)) \
  | "${BIN}/motif" --base 43 --notes 30 --complexity 2 --bpm 0 --ch 3 --vel 90 \
      --patch 32 --dur 1.0 \
  | "${BIN}/scale" --root G --mode major > /tmp/reel-bass.jsonl

cat /tmp/reel-f1.jsonl /tmp/reel-f2.jsonl /tmp/reel-banjo.jsonl /tmp/reel-bass.jsonl \
  | "${BIN}/viz" 2>/dev/null | "${BIN}/trim" --auto \
  | "${BIN}/to-midi" --out /tmp/demo-reel.mid

fluidsynth -ni -F /tmp/reel-raw.wav "$SF2" /tmp/demo-reel.mid 2>/dev/null
ffmpeg -y -i /tmp/reel-raw.wav -t 12 -af "afade=t=out:st=10:d=2" "$OUTPUT" 2>/dev/null
echo "Created: $OUTPUT"
afplay "$OUTPUT"
