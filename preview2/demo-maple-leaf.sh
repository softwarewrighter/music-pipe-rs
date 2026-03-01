#!/bin/bash
# Scott Joplin - Maple Leaf Rag (1899)
# The most famous ragtime composition
# Public domain - composed over 125 years ago
#
# Using new seq features: chord syntax, beat-based timing, per-note velocity

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/preview2/demo-maple-leaf.wav"

echo "=== Scott Joplin: Maple Leaf Rag (1899) ==="
echo "Using new seq features: chords, beat timing, per-note velocity"
echo ""

# Reference MIDI analysis - exact timing and velocity from human performance
# Key: Ab major, TIME: 2/4, Tempo: ~100 BPM

# Build the sequence using precise beat positioning
# Format: note/b<beats>*<velocity> or [chord]/b<beats>*<velocity>

# Measure 1-2: Opening bass and melody
NOTES=""
# Beat 1.48: Bass octave D#2+D#3
NOTES="${NOTES} R/b1.48 [D#2,D#3]/8*95"
# Beat 2.00: Bass octave G#2+G#3
NOTES="${NOTES} R/b0.52 [G#2,G#3]/8*86"
# Beat 2.31: Melody G#4
NOTES="${NOTES} R/b0.31 G#4/16*73"
# Beat 2.48: Chord G#3,C4,D#3,D#4
NOTES="${NOTES} R/b0.17 [G#3,C4,D#3,D#4]/16*80"
# Beat 2.52: Melody D#5
NOTES="${NOTES} R/b0.04 D#5/16*81"
# Beat 2.80: Melody G#4
NOTES="${NOTES} R/b0.28 G#4/16*66"
# Beat 2.98: Chord
NOTES="${NOTES} R/b0.18 [G#3,C4,D#3]/16*65"
# Beat 3.02: Melody C5
NOTES="${NOTES} R/b0.04 C5/16*77"
# Beat 3.30: Melody D#5
NOTES="${NOTES} R/b0.28 D#5/16*77"
# Beat 3.32: Melody D#4
NOTES="${NOTES} R/b0.02 D#4/16*91"
# Beat 3.49: Bass A2+A3
NOTES="${NOTES} R/b0.17 [A2,A3]/8*86"
# Beat 3.82: Melody G4
NOTES="${NOTES} R/b0.33 G4/16*81"
# Beat 4.00: Bass A#2+A#3
NOTES="${NOTES} R/b0.18 [A#2,A#3]/8*86"
# Beat 4.02: Melody D#4+D#5
NOTES="${NOTES} R/b0.02 [D#4,D#5]/16*82"
# Beat 4.28: Melody G4
NOTES="${NOTES} R/b0.26 G4/16*73"
# Beat 4.48: Chord G3,C#4 (secondary dominant)
NOTES="${NOTES} R/b0.20 [G3,C#4]/16*68"
# Beat 4.51: Melody A#4
NOTES="${NOTES} R/b0.03 A#4/16*77"
# Beat 4.78: Melody D#4+D#5
NOTES="${NOTES} R/b0.27 [D#4,D#5]/16*86"

# Measure 3-4: Repeat of A section
# Beat 5.50: Bass D#2+D#3
NOTES="${NOTES} R/b0.72 [D#2,D#3]/8*88"
# Beat 6.00: Bass G#2+G#3
NOTES="${NOTES} R/b0.50 [G#2,G#3]/8*81"
# Beat 6.32: Melody G#4
NOTES="${NOTES} R/b0.32 G#4/16*66"
# Beat 6.48: Chord
NOTES="${NOTES} R/b0.16 [G#3,C4,D#3,D#4]/16*75"
# Beat 6.51: Melody D#5
NOTES="${NOTES} R/b0.03 D#5/16*86"
# Beat 6.81: Melody G#4
NOTES="${NOTES} R/b0.30 G#4/16*59"
# Beat 6.99: Chord
NOTES="${NOTES} R/b0.18 [G#3,C4,D#3]/16*60"
# Beat 7.03: Melody C5
NOTES="${NOTES} R/b0.04 C5/16*73"
# Beat 7.31: Melody D#5
NOTES="${NOTES} R/b0.28 D#5/16*77"
# Beat 7.33: Melody D#4
NOTES="${NOTES} R/b0.02 D#4/16*91"
# Beat 7.48: Bass A2+A3
NOTES="${NOTES} R/b0.15 [A2,A3]/8*94"
# Beat 7.82: Melody G4
NOTES="${NOTES} R/b0.34 G4/16*86"
# Beat 8.00: Bass A#2+A#3
NOTES="${NOTES} R/b0.18 [A#2,A#3]/8*84"
# Beat 8.02: Melody D#4+D#5
NOTES="${NOTES} R/b0.02 [D#4,D#5]/16*80"
# Beat 8.28: Melody G4
NOTES="${NOTES} R/b0.26 G4/16*77"
# Beat 8.48: Chord
NOTES="${NOTES} R/b0.20 [G3,C#4]/16*65"
# Beat 8.52: Melody A#4
NOTES="${NOTES} R/b0.04 A#4/16*81"
# Beat 8.79: Melody D#4+D#5
NOTES="${NOTES} R/b0.27 [D#4,D#5]/16*84"

# Measure 5-6: Continue pattern
NOTES="${NOTES} R/b0.71 [D#2,D#3]/8*86"
NOTES="${NOTES} R/b0.50 [G#2,G#3]/8*81"
NOTES="${NOTES} R/b0.32 G#4/16*66"
NOTES="${NOTES} R/b0.16 [G#3,C4,D#3,D#4]/16*78"
NOTES="${NOTES} R/b0.03 D#5/16*81"
NOTES="${NOTES} R/b0.28 G#4/16*66"
NOTES="${NOTES} R/b0.18 [G#3,C4,D#3]/16*62"
NOTES="${NOTES} R/b0.04 C5/16*77"
NOTES="${NOTES} R/b0.28 D#5/16*77"
NOTES="${NOTES} R/b0.02 D#4/16*86"
NOTES="${NOTES} R/b0.17 [A2,A3]/8*88"
NOTES="${NOTES} R/b0.33 G4/16*81"
NOTES="${NOTES} R/b0.18 [A#2,A#3]/8*84"
NOTES="${NOTES} R/b0.02 [D#4,D#5]/16*80"
NOTES="${NOTES} R/b0.26 G#4/8*75"

echo "Generating with new seq features..."
echo "" | "${BIN}/seq" --notes "${NOTES}" --bpm 116 --ch 0 --patch 0 \
  > /tmp/maple-new.jsonl

# Stats
NOTE_COUNT=$(grep -c NoteOn /tmp/maple-new.jsonl)
echo "Generated ${NOTE_COUNT} notes"

# Add humanize for micro-timing variation
echo "Adding humanize..."
cat /tmp/maple-new.jsonl \
  | "${BIN}/humanize" --jitter-ticks 8 --jitter-vel 8 \
  | "${BIN}/trim" --auto \
  > /tmp/maple-full.jsonl

# Convert to MIDI
echo "Converting to MIDI..."
cat /tmp/maple-full.jsonl | "${BIN}/to-midi" --out /tmp/demo-maple-leaf.mid

# Render to WAV
echo "Rendering to WAV..."
if [[ -f "$SF2" ]]; then
    fluidsynth -ni -F /tmp/demo-maple-leaf-raw.wav "$SF2" /tmp/demo-maple-leaf.mid 2>/dev/null

    # Trim to ~12 seconds with fade
    echo "Trimming..."
    ffmpeg -y -i /tmp/demo-maple-leaf-raw.wav -t 12 -af "afade=t=out:st=10:d=2" "$OUTPUT" 2>/dev/null

    DURATION=$(afinfo "$OUTPUT" 2>/dev/null | grep "estimated duration" | awk '{print $3}')
    echo "Created: $OUTPUT (${DURATION}s)"

    echo ""
    echo "Playing..."
    afplay "$OUTPUT"
else
    echo "Soundfont not found: $SF2"
    echo "MIDI file: /tmp/demo-maple-leaf.mid"
fi

echo ""
echo "=== Done ==="
