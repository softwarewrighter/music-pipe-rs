#!/bin/bash
# Ragtime-esque - Algorithmic Generation
# Syncopated piano with stride bass (motif-based)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/preview2/demo-ragtime-motif.wav"

SEED=${1:-1899}

echo "=== Ragtime-esque (motif) ==="
echo "Seed: $SEED"

# Melody - syncopated, swing feel
"${BIN}/seed" $SEED \
  | "${BIN}/motif" --base 72 --notes 40 --complexity 6 --bpm 92 --ch 0 --vel 95 \
      --patch 3 --dur 0.5 --rest-prob 0.15 --swing 0.12 \
  | "${BIN}/scale" --root C --mode major > /tmp/rag-melody.jsonl

# Stride bass
"${BIN}/seed" $((SEED+1)) \
  | "${BIN}/motif" --base 48 --notes 35 --complexity 3 --bpm 0 --ch 1 --vel 70 \
      --patch 0 --dur 0.75 --chord-prob 0.4 \
  | "${BIN}/scale" --root C --mode major > /tmp/rag-bass.jsonl

cat /tmp/rag-melody.jsonl /tmp/rag-bass.jsonl \
  | "${BIN}/viz" 2>/dev/null | "${BIN}/trim" --auto \
  | "${BIN}/to-midi" --out /tmp/demo-ragtime.mid

fluidsynth -ni -F /tmp/rag-raw.wav "$SF2" /tmp/demo-ragtime.mid 2>/dev/null
ffmpeg -y -i /tmp/rag-raw.wav -t 12 -af "afade=t=out:st=10:d=2" "$OUTPUT" 2>/dev/null
echo "Created: $OUTPUT"
afplay "$OUTPUT"
