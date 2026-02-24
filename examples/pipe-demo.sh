#!/bin/bash
# Simple music-pipe demo

# Set paths
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2=~/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2

# Generate MIDI with visualization
echo "Generating melody..."
echo ""
echo "Sparkline:"
"${BIN}/seed" 12345 | "${BIN}/motif" --notes 16 --bpm 120 | "${BIN}/viz" | "${BIN}/humanize" | "${BIN}/to-midi" --out /tmp/demo.mid
echo ""
echo "Piano roll:"
"${BIN}/seed" 12345 | "${BIN}/motif" --notes 16 --bpm 120 | "${BIN}/viz" --roll >/dev/null
echo ""

# Convert to WAV
echo "Converting to WAV..."
fluidsynth -ni -F /tmp/demo.wav "$SF2" /tmp/demo.mid 2>/dev/null

# Play
echo "Playing..."
afplay /tmp/demo.wav

echo "Done."
