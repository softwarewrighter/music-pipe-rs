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

# Demo 1: Simple arpeggio
echo "1. Simple arpeggio (C major)"
"${BIN_DIR}/motif" --base 60 --bpm 120 --repeat 2 \
    | "${BIN_DIR}/to-midi" --out demo-arpeggio.mid
echo "   -> demo-arpeggio.mid"

# Demo 2: Transposed arpeggio (G major)
echo "2. Transposed arpeggio (G major, +7 semitones)"
"${BIN_DIR}/motif" --base 60 --bpm 120 --repeat 2 \
    | "${BIN_DIR}/transpose" --semitones 7 \
    | "${BIN_DIR}/to-midi" --out demo-transposed.mid
echo "   -> demo-transposed.mid"

# Demo 3: Humanized
echo "3. Humanized arpeggio (with timing/velocity variation)"
"${BIN_DIR}/motif" --base 60 --bpm 120 --repeat 4 \
    | "${BIN_DIR}/humanize" --seed 123 --jitter-ticks 12 --jitter-vel 15 \
    | "${BIN_DIR}/to-midi" --out demo-humanized.mid
echo "   -> demo-humanized.mid"

# Demo 4: Full pipeline
echo "4. Full pipeline (transposed + humanized)"
"${BIN_DIR}/motif" --base 60 --bpm 140 --pattern scale --repeat 2 \
    | "${BIN_DIR}/transpose" --semitones 5 \
    | "${BIN_DIR}/humanize" --seed 42 --jitter-ticks 8 --jitter-vel 10 \
    | "${BIN_DIR}/to-midi" --out demo-full.mid
echo "   -> demo-full.mid"

# Demo 5: Inspect JSONL stream
echo "5. Inspect event stream (first 10 events)"
"${BIN_DIR}/motif" --base 60 --bpm 120 | head -10
echo "   ..."

echo ""
echo "=== Demo Complete ==="
echo "Open .mid files in your DAW or MIDI player to hear the results."
