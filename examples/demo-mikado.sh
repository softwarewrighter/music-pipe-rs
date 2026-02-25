#!/bin/bash
# Gilbert & Sullivan - The Mikado
# "Three Little Maids from School" - Actual melody
# Light, bouncy operetta classic

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/examples/demo-mikado.wav"

echo "=== The Mikado - Three Little Maids from School ==="
echo ""

# "Three little maids from school are we"
# Key: G major, bouncy 6/8 feel
# Melody transcription (simplified)

# Main melody - Flute (patch 73)
MELODY="G5/8 G5/8 G5/8 F#5/8 E5/8 D5/8"          # Three lit-tle maids from
MELODY="${MELODY} G5/4 B5/8 A5/4 G5/8"            # school are we
MELODY="${MELODY} G5/8 G5/8 G5/8 F#5/8 E5/8 D5/8" # Pert as a school-girl
MELODY="${MELODY} G5/4 A5/8 B5/2"                   # well can be

# Second phrase
MELODY="${MELODY} R/8 D5/8 D5/8 D5/8 E5/8 F#5/8 G5/8"  # Filled to the brim with
MELODY="${MELODY} A5/4 G5/8 F#5/4 E5/8"                 # girl-ish glee
MELODY="${MELODY} D5/8 G5/8 B5/8 A5/8 G5/8 F#5/8"      # Three lit-tle maids from
MELODY="${MELODY} G5/1"                                   # school!

echo "Generating melody (Flute)..."
"${BIN}/seq" --notes "${MELODY}" --bpm 144 --ch 0 --patch 73 --vel 90 \
  > /tmp/mikado-melody.jsonl

# Harmony - Oboe (patch 68) - simplified accompaniment
HARMONY="R/4 D5/8 R/4 D5/8 R/4 B4/8 R/4 D5/8"
HARMONY="${HARMONY} R/4 D5/8 R/4 D5/8 R/4 E5/8 R/4 D5/8"
HARMONY="${HARMONY} R/4 B4/8 R/4 C5/8 R/4 D5/8 R/4 B4/8"
HARMONY="${HARMONY} R/4 D5/8 R/4 D5/8 B4/1"

echo "Generating harmony (Oboe)..."
"${BIN}/seq" --notes "${HARMONY}" --bpm 0 --ch 1 --patch 68 --vel 70 \
  > /tmp/mikado-harmony.jsonl

# Bass - Pizzicato (patch 45) - bouncy oom-pah
BASS="G3/8 D4/8 B3/8 G3/8 D4/8 B3/8"
BASS="${BASS} G3/8 D4/8 B3/8 D3/8 A3/8 F#3/8"
BASS="${BASS} G3/8 D4/8 B3/8 G3/8 D4/8 B3/8"
BASS="${BASS} G3/8 D4/8 B3/8 G3/2"
BASS="${BASS} D3/8 A3/8 F#3/8 G3/8 B3/8 D4/8"
BASS="${BASS} A3/8 E4/8 C#4/8 D4/8 A3/8 F#3/8"
BASS="${BASS} G3/8 B3/8 D4/8 D3/8 A3/8 F#3/8"
BASS="${BASS} G3/1"

echo "Generating bass (Pizzicato)..."
"${BIN}/seq" --notes "${BASS}" --bpm 0 --ch 2 --patch 45 --vel 80 \
  > /tmp/mikado-bass.jsonl

# Combine
echo "Combining voices..."
cat /tmp/mikado-melody.jsonl /tmp/mikado-harmony.jsonl /tmp/mikado-bass.jsonl \
  | "${BIN}/viz" \
  > /tmp/mikado-full.jsonl

# Stats
echo ""
echo "Events:"
echo "  Melody:  $(grep -c NoteOn /tmp/mikado-melody.jsonl)"
echo "  Harmony: $(grep -c NoteOn /tmp/mikado-harmony.jsonl)"
echo "  Bass:    $(grep -c NoteOn /tmp/mikado-bass.jsonl)"

# Convert to MIDI
echo ""
echo "Converting to MIDI..."
cat /tmp/mikado-full.jsonl | "${BIN}/to-midi" --out /tmp/demo-mikado.mid

# Render to WAV
echo "Rendering to WAV..."
if [[ -f "$SF2" ]]; then
    fluidsynth -ni -F "$OUTPUT" "$SF2" /tmp/demo-mikado.mid 2>/dev/null

    DURATION=$(afinfo "$OUTPUT" 2>/dev/null | grep "estimated duration" | awk '{print $3}')
    echo "Created: $OUTPUT (${DURATION}s)"

    echo ""
    echo "Playing..."
    afplay "$OUTPUT"
else
    echo "Soundfont not found: $SF2"
    echo "MIDI file: /tmp/demo-mikado.mid"
fi

echo ""
echo "=== Done ==="
