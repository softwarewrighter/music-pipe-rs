#!/bin/bash
# Wrapper script for explainer-demo.sh
# Runs the demo, converts MIDI to WAV, and plays the result

set -e
cd ~/github/softwarewrighter/music-pipe-rs

SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUT_DIR="/tmp/explainer-demo"

# Run the demo script
./explainer-demo.sh

# Convert MIDI to WAV
echo ""
echo "# Converting MIDI to WAV..."
fluidsynth -ni -F "$OUT_DIR/arrangement.wav" "$SF2" "$OUT_DIR/arrangement.mid" 2>/dev/null

DURATION=$(afinfo "$OUT_DIR/arrangement.wav" 2>/dev/null | grep "estimated duration" | awk '{print $3}')
echo "  → $OUT_DIR/arrangement.wav (${DURATION}s)"

# Play the result
echo ""
echo "# Playing..."
afplay "$OUT_DIR/arrangement.wav"

echo ""
echo "=== Playback complete ==="
