#!/bin/bash
# Scott Joplin - The Entertainer (1902)
# Classic ragtime piano - "A Rag Time Two Step"
# Public domain - composed over 120 years ago
# Note: Joplin wrote "Do not play this piece fast"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/preview2/demo-entertainer.wav"

echo "=== Scott Joplin: The Entertainer (1902) ==="
echo "A Rag Time Two Step"
echo ""

# Key: C major (from abcnotation.com - Colin Hume arrangement)
# ABC: |: D^D | Ec-cE c2Ec- | c4- ccd^d | ecde- eBd2 | c6 D^D |
# Tempo: 76 half-notes/min = moderate ragtime (Joplin: "Do not play fast")

# Right hand - Honky-tonk Piano (patch 3)
# Pickup: D^D = D4 D#4 (uppercase = octave 4)
# Main notes: c = C5, e = E5, E = E4 (lowercase = octave 5)

# M1 pickup + measure: D^D | Ec-cE c2Ec-
MELODY="D4/8 D#4/8"
MELODY="${MELODY} E4/8 C5/4 E4/8 C5/4 E4/8 C5/8"
# M2: c4- ccd^d (C5 held, then C5 C5 D5 D#5)
MELODY="${MELODY} C5/2 C5/8 C5/8 D5/8 D#5/8"
# M3: ecde- eBd2 (E5 C5 D5 E5, E5 B4 D5-quarter)
MELODY="${MELODY} E5/8 C5/8 D5/8 E5/8 E5/8 B4/8 D5/4"
# M4: c6 D^D (C5 dotted-half, pickup D4 D#4)
MELODY="${MELODY} C5/2 C5/4 D4/8 D#4/8"

# M5-8 (repeat with variation ending)
MELODY="${MELODY} E4/8 C5/4 E4/8 C5/4 E4/8 C5/8"
MELODY="${MELODY} C5/2 C5/4 A4/8 G4/8"
# M7: ^FAce- edcA (F#4 A4 C5 E5, E5 D5 C5 A4)
MELODY="${MELODY} F#4/8 A4/8 C5/8 E5/8 E5/8 D5/8 C5/8 A4/8"
# M8: d6 D^D
MELODY="${MELODY} D5/2 D5/4 D4/8 D#4/8"

# M9-12 (same as M1-4)
MELODY="${MELODY} E4/8 C5/4 E4/8 C5/4 E4/8 C5/8"
MELODY="${MELODY} C5/2 C5/8 C5/8 D5/8 D#5/8"
MELODY="${MELODY} E5/8 C5/8 D5/8 E5/8 E5/8 B4/8 D5/4"
MELODY="${MELODY} C5/2 C5/4 C5/8 D5/8"

# M13-16 (ending): ecde- ecdc | ecde- ecdc | ecde- eBd2 | c6
MELODY="${MELODY} E5/8 C5/8 D5/8 E5/8 E5/8 C5/8 D5/8 C5/8"
MELODY="${MELODY} E5/8 C5/8 D5/8 E5/8 E5/8 C5/8 D5/8 C5/8"
MELODY="${MELODY} E5/8 C5/8 D5/8 E5/8 E5/8 B4/8 D5/4"
MELODY="${MELODY} C5/1"

echo "Generating melody (Honky-tonk Piano)..."
"${BIN}/seq" --notes "${MELODY}" --bpm 120 --ch 0 --patch 3 --vel 95 \
  > /tmp/ent-melody.jsonl

# Left hand stride bass - Acoustic Piano (patch 0)
# Classic ragtime stride: bass on 1 and 3, chord on 2 and 4
# Following ABC chord changes: C | C C7 | F C/E | C G7 | C ...

# Pickup (2 8ths) + M1: C chord
BASS="R/4"
BASS="${BASS} C2/8 E3/8 G3/8 E3/8 C2/8 E3/8 G3/8 E3/8"
# M2: F chord to C/E
BASS="${BASS} F2/8 A3/8 C3/8 A3/8 E2/8 G3/8 C3/8 G3/8"
# M3: C to G7
BASS="${BASS} C2/8 E3/8 G3/8 E3/8 G2/8 B3/8 D3/8 B3/8"
# M4: C chord
BASS="${BASS} C2/8 E3/8 G3/8 E3/8 C2/4"

# M5: C chord
BASS="${BASS} C2/8 E3/8 G3/8 E3/8 C2/8 E3/8 G3/8 E3/8"
# M6: F chord to C
BASS="${BASS} F2/8 A3/8 C3/8 A3/8 C2/8 E3/8 G3/8 E3/8"
# M7: D7 chord
BASS="${BASS} D2/8 F#3/8 A3/8 F#3/8 D2/8 F#3/8 A3/8 F#3/8"
# M8: G chord
BASS="${BASS} G2/8 B3/8 D3/8 B3/8 G2/4"

# M9-12: same as M1-4
BASS="${BASS} C2/8 E3/8 G3/8 E3/8 C2/8 E3/8 G3/8 E3/8"
BASS="${BASS} F2/8 A3/8 C3/8 A3/8 E2/8 G3/8 C3/8 G3/8"
BASS="${BASS} C2/8 E3/8 G3/8 E3/8 G2/8 B3/8 D3/8 B3/8"
BASS="${BASS} C2/8 E3/8 G3/8 E3/8 C2/4"

# M13-16: ending - C C7 | F Fm | C/G G7 | C
BASS="${BASS} C2/8 E3/8 G3/8 E3/8 C2/8 E3/8 Bb3/8 E3/8"
BASS="${BASS} F2/8 A3/8 C3/8 A3/8 F2/8 Ab3/8 C3/8 Ab3/8"
BASS="${BASS} G2/8 C3/8 E3/8 C3/8 G2/8 B3/8 D3/8 B3/8"
BASS="${BASS} C2/1"

echo "Generating stride bass..."
"${BIN}/seq" --notes "${BASS}" --bpm 0 --ch 1 --patch 0 --vel 70 \
  > /tmp/ent-bass.jsonl

# Combine
echo "Combining voices..."
cat /tmp/ent-melody.jsonl /tmp/ent-bass.jsonl \
  | "${BIN}/viz" 2>/dev/null \
  | "${BIN}/trim" --auto \
  > /tmp/ent-full.jsonl

# Stats
echo ""
echo "Events:"
echo "  Melody: $(grep -c NoteOn /tmp/ent-melody.jsonl)"
echo "  Bass:   $(grep -c NoteOn /tmp/ent-bass.jsonl)"

# Convert to MIDI
echo ""
echo "Converting to MIDI..."
cat /tmp/ent-full.jsonl | "${BIN}/to-midi" --out /tmp/demo-entertainer.mid

# Render to WAV
echo "Rendering to WAV..."
if [[ -f "$SF2" ]]; then
    fluidsynth -ni -F /tmp/demo-entertainer-raw.wav "$SF2" /tmp/demo-entertainer.mid 2>/dev/null

    # Trim to ~12 seconds with fade
    echo "Trimming..."
    ffmpeg -y -i /tmp/demo-entertainer-raw.wav -t 12 -af "afade=t=out:st=10:d=2" "$OUTPUT" 2>/dev/null

    DURATION=$(afinfo "$OUTPUT" 2>/dev/null | grep "estimated duration" | awk '{print $3}')
    echo "Created: $OUTPUT (${DURATION}s)"

    echo ""
    echo "Playing..."
    afplay "$OUTPUT"
else
    echo "Soundfont not found: $SF2"
    echo "MIDI file: /tmp/demo-entertainer.mid"
fi

echo ""
echo "=== Done ==="
