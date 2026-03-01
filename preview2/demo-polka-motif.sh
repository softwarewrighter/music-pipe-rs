#!/bin/bash
# Polish/German Polka-esque - Algorithmic Generation
# Oom-pah beer hall style (motif-based)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/preview2/demo-polka-motif.wav"

SEED=${1:-1850}

echo "=== Polka-esque (motif) ==="
echo "Seed: $SEED"

# Accordion melody (patch 21 = Accordion)
"${BIN}/seed" $SEED \
  | "${BIN}/motif" --base 72 --notes 40 --complexity 5 --bpm 124 --ch 0 --vel 95 \
      --patch 21 --dur 0.5 --rest-prob 0.1 \
  | "${BIN}/scale" --root F --mode major > /tmp/polka-accordion.jsonl

# Clarinet countermelody (patch 71)
"${BIN}/seed" $((SEED+1)) \
  | "${BIN}/motif" --base 67 --notes 25 --complexity 4 --bpm 0 --ch 1 --vel 75 \
      --patch 71 --dur 0.5 --rest-prob 0.2 \
  | "${BIN}/scale" --root F --mode major > /tmp/polka-clarinet.jsonl

# Tuba oom-pah bass (patch 58)
"${BIN}/seed" $((SEED+2)) \
  | "${BIN}/motif" --base 41 --notes 35 --complexity 2 --bpm 0 --ch 2 --vel 100 \
      --patch 58 --dur 1.0 \
  | "${BIN}/scale" --root F --mode major > /tmp/polka-tuba.jsonl

# Oom-pah rhythm - trombone chords on offbeats (patch 57)
"${BIN}/seed" $((SEED+3)) \
  | "${BIN}/motif" --base 53 --notes 30 --complexity 2 --bpm 0 --ch 3 --vel 70 \
      --patch 57 --dur 0.5 --chord-prob 0.6 \
  | "${BIN}/scale" --root F --mode major > /tmp/polka-trombone.jsonl

cat /tmp/polka-accordion.jsonl /tmp/polka-clarinet.jsonl /tmp/polka-tuba.jsonl /tmp/polka-trombone.jsonl \
  | "${BIN}/viz" 2>/dev/null | "${BIN}/trim" --auto \
  | "${BIN}/to-midi" --out /tmp/demo-polka.mid

fluidsynth -ni -F /tmp/polka-raw.wav "$SF2" /tmp/demo-polka.mid 2>/dev/null
ffmpeg -y -i /tmp/polka-raw.wav -t 12 -af "afade=t=out:st=10:d=2" "$OUTPUT" 2>/dev/null
echo "Created: $OUTPUT"
afplay "$OUTPUT"
