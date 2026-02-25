#!/bin/bash
# Bach Toccata and Fugue in D minor (BWV 565) - The ICONIC Opening
# The famous dramatic opening used in Gyruss, horror movies, etc.
# Played in OCTAVES with rapid descending runs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/examples/demo-bach.wav"

echo "=== Bach: Toccata and Fugue in D Minor (BWV 565) ==="
echo "The iconic dramatic opening - played in octaves"
echo ""

# THE FAMOUS OPENING - played in octaves (high + low together)
# Pattern: held note -> mordent -> rapid descending run -> resolution
# All notes doubled an octave apart for that massive organ sound

# First phrase: D5+D4 octaves with mordent and descending run
# The mordent is C#-D played lightning fast, then the dramatic descending scale
HIGH1="D5/2*127 C#5/32*120 D5/32*120 A4/32*115 G4/32*110 F4/32*110 E4/32*110 D4/32*110 C#4/32*115 D4/4*120"

# Same thing an octave lower (played simultaneously for octave doubling)
LOW1="D4/2*127 C#4/32*120 D4/32*120 A3/32*115 G3/32*110 F3/32*110 E3/32*110 D3/32*110 C#3/32*115 D3/4*120"

# Second phrase: Same pattern starting on A (down a fourth)
HIGH2="R/4 A4/2*125 G#4/32*115 A4/32*115 E4/32*110 D4/32*105 C4/32*105 B3/32*105 A3/32*105 G#3/32*110 A3/4*115"
LOW2="R/4 A3/2*125 G#3/32*115 A3/32*115 E3/32*110 D3/32*105 C3/32*105 B2/32*105 A2/32*105 G#2/32*110 A2/4*115"

# Third phrase: Back to D, even more dramatic - the big finish
HIGH3="R/4 D5/2*127 C#5/32*120 D5/32*127"
LOW3="R/4 D4/2*127 C#4/32*120 D4/32*127"

# MASSIVE FINAL CHORD - full D minor
CHORD="R/8 D3/1*127 A3/1*127 D4/1*127 F4/1*127 A4/1*127 D5/1*127"

# DEEP PEDAL BASS - the thunderous low D
PEDAL="R/2 D2/1*127 R/4 A1/1*127 R/4 D2/1*127"

echo "Generating upper octave (Ch 0)..."
"${BIN}/seq" --notes "${HIGH1} ${HIGH2} ${HIGH3}" --bpm 66 --ch 0 --patch 19 --vel 127 \
  > /tmp/bach-high.jsonl

echo "Generating lower octave (Ch 1)..."
"${BIN}/seq" --notes "${LOW1} ${LOW2} ${LOW3}" --bpm 0 --ch 1 --patch 19 --vel 120 \
  > /tmp/bach-low.jsonl

echo "Generating final chord (Ch 2)..."
"${BIN}/seq" --notes "${CHORD}" --bpm 0 --ch 2 --patch 19 --vel 127 \
  > /tmp/bach-chord.jsonl

echo "Generating pedal bass (Ch 3)..."
"${BIN}/seq" --notes "${PEDAL}" --bpm 0 --ch 3 --patch 19 --vel 127 \
  > /tmp/bach-pedal.jsonl

# Combine all voices
echo "Combining all voices..."
cat /tmp/bach-high.jsonl /tmp/bach-low.jsonl /tmp/bach-chord.jsonl /tmp/bach-pedal.jsonl \
  | "${BIN}/viz" \
  > /tmp/bach-full.jsonl

# Stats
echo ""
echo "Events:"
grep -c NoteOn /tmp/bach-high.jsonl | xargs -I{} echo "  Upper octave: {}"
grep -c NoteOn /tmp/bach-low.jsonl | xargs -I{} echo "  Lower octave: {}"
grep -c NoteOn /tmp/bach-chord.jsonl | xargs -I{} echo "  Final chord:  {}"
grep -c NoteOn /tmp/bach-pedal.jsonl | xargs -I{} echo "  Pedal bass:   {}"

# Convert to MIDI
echo ""
echo "Converting to MIDI..."
cat /tmp/bach-full.jsonl | "${BIN}/to-midi" --out /tmp/demo-bach.mid

# Render to WAV
echo "Rendering to WAV..."
if [[ -f "$SF2" ]]; then
    fluidsynth -ni -F "$OUTPUT" "$SF2" /tmp/demo-bach.mid 2>/dev/null

    DURATION=$(afinfo "$OUTPUT" 2>/dev/null | grep "estimated duration" | awk '{print $3}')
    echo "Created: $OUTPUT (${DURATION}s)"

    # Play
    echo ""
    echo "Playing..."
    afplay "$OUTPUT"
else
    echo "Soundfont not found: $SF2"
    echo "MIDI file: /tmp/demo-bach.mid"
fi

echo ""
echo "=== Done ==="
