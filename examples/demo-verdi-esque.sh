#!/bin/bash
# Verdi-esque Italian Opera - Algorithmic Background Music
# Lyrical melodies, passionate strings, dramatic contrasts
# Inspired by La Traviata, Rigoletto, Aida

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/examples/demo-verdi-esque.wav"

SEED=1813  # Verdi's birth year (same as Wagner!)

echo "=== Verdi-esque Italian Opera ==="
echo "Lyrical melodies, passionate expression"
echo ""

# Solo Violin - aria-like lyrical melody (patch 40 = Violin)
echo "Generating Solo Violin (aria melody)..."
"${BIN}/seed" $SEED \
  | "${BIN}/motif" --base 67 --notes 24 --complexity 6 --bpm 72 --ch 0 --vel 90 \
      --patch 40 --dur 1.0 --rest-prob 0.2 --swing 0.1 \
  | "${BIN}/scale" --root G --mode major \
  > /tmp/verdi-violin.jsonl

# Cello - warm, singing bass line (patch 42 = Cello)
echo "Generating Cello (singing bass)..."
"${BIN}/seed" $((SEED+1)) \
  | "${BIN}/motif" --base 48 --notes 16 --complexity 3 --bpm 0 --ch 1 --vel 85 \
      --patch 42 --dur 1.5 \
  | "${BIN}/scale" --root G --mode major \
  > /tmp/verdi-cello.jsonl

# String Ensemble - lush harmonic support (patch 48 = Strings)
echo "Generating String Ensemble (harmonic bed)..."
"${BIN}/seed" $((SEED+2)) \
  | "${BIN}/motif" --base 55 --notes 20 --complexity 4 --bpm 0 --ch 2 --vel 70 \
      --patch 48 --dur 2.0 --chord-prob 0.4 \
  | "${BIN}/scale" --root G --mode major \
  > /tmp/verdi-ensemble.jsonl

# Clarinet - woodwind color (patch 71 = Clarinet)
echo "Generating Clarinet (woodwind color)..."
"${BIN}/seed" $((SEED+3)) \
  | "${BIN}/motif" --base 60 --notes 12 --complexity 5 --bpm 0 --ch 3 --vel 75 \
      --patch 71 --dur 0.75 --rest-prob 0.3 \
  | "${BIN}/scale" --root G --mode major \
  > /tmp/verdi-clarinet.jsonl

# Combine all voices
echo "Combining voices..."
cat /tmp/verdi-violin.jsonl /tmp/verdi-cello.jsonl /tmp/verdi-ensemble.jsonl /tmp/verdi-clarinet.jsonl \
  | "${BIN}/viz" \
  > /tmp/verdi-full.jsonl

# Stats
echo ""
echo "Events:"
echo "  Violin:   $(grep -c NoteOn /tmp/verdi-violin.jsonl)"
echo "  Cello:    $(grep -c NoteOn /tmp/verdi-cello.jsonl)"
echo "  Ensemble: $(grep -c NoteOn /tmp/verdi-ensemble.jsonl)"
echo "  Clarinet: $(grep -c NoteOn /tmp/verdi-clarinet.jsonl)"

# Convert to MIDI
echo ""
echo "Converting to MIDI..."
cat /tmp/verdi-full.jsonl | "${BIN}/to-midi" --out /tmp/demo-verdi-esque.mid

# Render to WAV
echo "Rendering to WAV..."
if [[ -f "$SF2" ]]; then
    fluidsynth -ni -F "$OUTPUT" "$SF2" /tmp/demo-verdi-esque.mid 2>/dev/null

    DURATION=$(afinfo "$OUTPUT" 2>/dev/null | grep "estimated duration" | awk '{print $3}')
    echo "Created: $OUTPUT (${DURATION}s)"

    echo ""
    echo "Playing..."
    afplay "$OUTPUT"
else
    echo "Soundfont not found: $SF2"
    echo "MIDI file: /tmp/demo-verdi-esque.mid"
fi

echo ""
echo "=== Done ==="
