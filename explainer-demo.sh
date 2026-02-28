#!/bin/bash
# GarageBand Pipeline Demo - matches slide 06a-ii
# Generates a 3-track arrangement with visualization
#
# Instruments:
#   - Melody: String Ensemble (GM program 48)
#   - Bass: Upright Studio Bass (GM program 32)
#   - Percussion: Wood Blocks (GM drum notes 76, 77) - Euclidean rhythm

set -e
cd ~/github/softwarewrighter/music-pipe-rs

BIN="./target/release"
OUT_DIR="/tmp/explainer-demo"
mkdir -p "$OUT_DIR"

echo "=== GarageBand Pipeline Demo ==="
echo ""

# Melody - String Ensemble (program 48)
echo "# Melody - String Ensemble"
$BIN/seed 800 | $BIN/motif --base 72 --bpm 110 --notes 16 --complexity 6 --ch 0 --patch 48 > "$OUT_DIR/melody.jsonl"
echo "  → $OUT_DIR/melody.jsonl"

# Bass - Upright Studio (program 32)
echo ""
echo "# Bass - Upright Studio"
$BIN/seed 800 | $BIN/motif --base 48 --notes 16 --complexity 2 --ch 1 --vel 90 --patch 32 > "$OUT_DIR/bass.jsonl"
echo "  → $OUT_DIR/bass.jsonl"

# Percussion - Wood Blocks (Euclidean rhythm)
echo ""
echo "# Percussion - Wood Blocks (Euclidean)"
{
  $BIN/seed 800 | $BIN/euclid --steps 16 --pulses 4 --note 76 --ch 9 --repeat 4
  $BIN/seed 800 | $BIN/euclid --steps 16 --pulses 6 --note 77 --ch 9 --repeat 4
} > "$OUT_DIR/drums.jsonl"
echo "  → $OUT_DIR/drums.jsonl"

# Combine and process
echo ""
echo "# Combine, scale, and humanize"
cat "$OUT_DIR/melody.jsonl" "$OUT_DIR/bass.jsonl" "$OUT_DIR/drums.jsonl" \
  | $BIN/scale --root G --mode minor \
  | $BIN/humanize \
  > "$OUT_DIR/combined.jsonl"
echo "  → $OUT_DIR/combined.jsonl"

# Visualize
echo ""
echo "# Visualizations (sparkline and piano-roll):"
echo ""
cat "$OUT_DIR/combined.jsonl" | $BIN/viz > /dev/null
echo ""
cat "$OUT_DIR/combined.jsonl" | $BIN/viz --roll > /dev/null

# Output MIDI
echo ""
echo "# MIDI output"
cat "$OUT_DIR/combined.jsonl" | $BIN/to-midi --out "$OUT_DIR/arrangement.mid"

echo ""
echo "=== Done ==="
echo "MIDI: $OUT_DIR/arrangement.mid"
echo ""
echo "→ Import arrangement.mid into GarageBand"
echo "→ Assign instruments: String Ensemble, Upright Bass, Hammered Wood"
