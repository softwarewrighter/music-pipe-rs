#!/bin/bash
# music-pipe-rs demo script
#
# Generates example MIDI files demonstrating different pipeline combinations.
#
# Usage:
#   ./examples/demo.sh
#
# Output files are created in the current directory.

set -euo pipefail

# Find the project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"
BIN_DIR="${PROJECT_DIR}/target/release"

# Check if built
if [[ ! -x "${BIN_DIR}/motif" ]]; then
    echo "Building music-pipe-rs..."
    (cd "${PROJECT_DIR}" && cargo build --release)
fi

echo "=== music-pipe-rs Demo ==="
echo ""

# Demo 1: Simple melody with visualization
echo "1. Simple melody (seed 100)"
"${BIN_DIR}/seed" 100 \
    | "${BIN_DIR}/motif" --base 60 --bpm 120 --notes 16 \
    | "${BIN_DIR}/viz" \
    | "${BIN_DIR}/to-midi" --out demo-melody.mid
echo "   -> demo-melody.mid"

# Demo 2: Melody constrained to scale
echo "2. Melody in C major scale"
"${BIN_DIR}/seed" 200 \
    | "${BIN_DIR}/motif" --base 60 --bpm 120 --notes 16 --complexity 7 \
    | "${BIN_DIR}/viz" \
    | "${BIN_DIR}/scale" --root C --mode major \
    | "${BIN_DIR}/to-midi" --out demo-scale.mid
echo "   -> demo-scale.mid"

# Demo 3: Humanized melody
echo "3. Humanized melody (timing/velocity variation)"
"${BIN_DIR}/seed" 300 \
    | "${BIN_DIR}/motif" --base 60 --bpm 120 --notes 20 --repeat 2 \
    | "${BIN_DIR}/humanize" --jitter-ticks 12 --jitter-vel 15 \
    | "${BIN_DIR}/to-midi" --out demo-humanized.mid
echo "   -> demo-humanized.mid"

# Demo 4: Full pipeline
echo "4. Full pipeline (transposed + scaled + humanized)"
"${BIN_DIR}/seed" 400 \
    | "${BIN_DIR}/motif" --base 60 --bpm 140 --notes 16 --complexity 5 --repeat 2 \
    | "${BIN_DIR}/transpose" --semitones 5 \
    | "${BIN_DIR}/scale" --root F --mode major \
    | "${BIN_DIR}/humanize" --jitter-ticks 8 --jitter-vel 10 \
    | "${BIN_DIR}/to-midi" --out demo-full.mid
echo "   -> demo-full.mid"

# Demo 5: Euclidean rhythm (Cuban tresillo)
echo "5. Euclidean rhythm E(3,8) - Cuban tresillo"
"${BIN_DIR}/seed" 500 \
    | "${BIN_DIR}/euclid" --steps 8 --pulses 3 --repeat 4 \
    | "${BIN_DIR}/to-midi" --out demo-euclid-3-8.mid
echo "   -> demo-euclid-3-8.mid"

# Demo 6: Euclidean rhythm (4-on-the-floor)
echo "6. Euclidean rhythm E(4,16) - 4-on-the-floor kick"
"${BIN_DIR}/seed" 600 \
    | "${BIN_DIR}/euclid" --steps 16 --pulses 4 --note 36 --repeat 2 \
    | "${BIN_DIR}/humanize" --jitter-ticks 4 --jitter-vel 8 \
    | "${BIN_DIR}/to-midi" --out demo-euclid-4-16.mid
echo "   -> demo-euclid-4-16.mid"

# Demo 7: Layered drums (kick + snare + hihat)
echo "7. Layered drums (kick + snare + hihat)"
"${BIN_DIR}/seed" 700 \
    | {
        "${BIN_DIR}/euclid" --steps 16 --pulses 4 --note 36 --ch 9 --bpm 120 --repeat 2;
        "${BIN_DIR}/euclid" --steps 16 --pulses 2 --note 38 --ch 9 --bpm 0 --repeat 2 --rotation 4;
        "${BIN_DIR}/euclid" --steps 16 --pulses 8 --note 42 --ch 9 --vel 70 --bpm 0 --repeat 2;
    } | "${BIN_DIR}/humanize" --jitter-ticks 6 \
    | "${BIN_DIR}/to-midi" --out demo-layered-drums.mid
echo "   -> demo-layered-drums.mid"

# Demo 8: Full arrangement
echo "8. Full arrangement (melody + bass + drums)"
"${BIN_DIR}/seed" 800 | "${BIN_DIR}/motif" --base 72 --bpm 110 --notes 16 --complexity 6 --ch 0 > /tmp/mel.jsonl
"${BIN_DIR}/seed" 800 | "${BIN_DIR}/motif" --base 48 --bpm 0 --notes 16 --complexity 2 --ch 1 --vel 90 > /tmp/bass.jsonl
"${BIN_DIR}/seed" 800 | {
    "${BIN_DIR}/euclid" --steps 16 --pulses 4 --note 36 --ch 9 --bpm 0 --repeat 4;
    "${BIN_DIR}/euclid" --steps 16 --pulses 6 --note 42 --ch 9 --vel 55 --bpm 0 --repeat 4;
} > /tmp/drums.jsonl
cat /tmp/mel.jsonl /tmp/bass.jsonl /tmp/drums.jsonl \
    | "${BIN_DIR}/scale" --root G --mode minor \
    | "${BIN_DIR}/humanize" \
    | "${BIN_DIR}/to-midi" --out demo-arrangement.mid
echo "   -> demo-arrangement.mid"

# Demo 9: Piano roll visualization
echo "9. Piano roll visualization"
"${BIN_DIR}/seed" 900 \
    | "${BIN_DIR}/motif" --base 60 --notes 16 --complexity 4 \
    | "${BIN_DIR}/viz" --roll > /dev/null

echo ""

# Demo 10: Play one of the generated files
echo "10. Playing demo-melody.mid..."
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
if [[ -f "$SF2" ]]; then
    fluidsynth -ni -F /tmp/demo-melody.wav "$SF2" demo-melody.mid 2>/dev/null
    afplay /tmp/demo-melody.wav
else
    echo "    Soundfont not found at $SF2"
    echo "    To play: fluidsynth -ni -F out.wav /path/to/soundfont.sf2 demo-melody.mid && afplay out.wav"
fi

echo ""
echo "=== Demo Complete ==="
echo "Generated MIDI files in current directory."
echo ""
echo "To play any file:"
echo "  fluidsynth -ni -F /tmp/out.wav /path/to/soundfont.sf2 <file>.mid && afplay /tmp/out.wav"
