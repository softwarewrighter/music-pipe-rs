#!/bin/bash
# Baroque Chamber Music - Period Instruments
# Style: Bach/Vivaldi concerto grosso
# ~15 seconds, D major

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/examples/demo-baroque.wav"

echo "=== Baroque Chamber Music ==="
echo "Period instruments, D major"
echo ""

# Tempo: 100 BPM (Allegro moderato)
# Key: D major (D E F# G A B C# D)

# === VIOLIN I - Primary melody (patch 40) ===
# Vivaldi-style running passages
VIOLIN1="D5/8 F#5/8 A5/8 D6/4 C#6/8 B5/8 A5/8"
VIOLIN1="${VIOLIN1} G5/8 F#5/8 E5/8 D5/4 E5/8 F#5/8 G5/8"
VIOLIN1="${VIOLIN1} A5/8 B5/8 C#6/8 D6/4 A5/8 F#5/8 D5/8"
VIOLIN1="${VIOLIN1} E5/8 F#5/8 G5/8 A5/4 D5/2"

echo "Generating Violin I..."
"${BIN}/seq" --notes "${VIOLIN1}" --bpm 100 --ch 0 --patch 40 --vel 95 \
  > /tmp/baroque-violin1.jsonl

# === VIOLIN II - Harmony/echo (patch 40) ===
VIOLIN2="R/4 D5/8 F#5/8 A5/4 G5/8 F#5/8 E5/8"
VIOLIN2="${VIOLIN2} D5/8 C#5/8 B4/8 A4/4 B4/8 C#5/8 D5/8"
VIOLIN2="${VIOLIN2} F#5/8 G5/8 A5/8 F#5/4 D5/8 A4/8 F#4/8"
VIOLIN2="${VIOLIN2} G4/8 A4/8 B4/8 C#5/4 D5/2"

echo "Generating Violin II..."
"${BIN}/seq" --notes "${VIOLIN2}" --bpm 0 --ch 1 --patch 40 --vel 85 \
  > /tmp/baroque-violin2.jsonl

# === VIOLA - Inner voice (patch 41) ===
VIOLA="A4/4 A4/8 A4/4 A4/8 G4/4 G4/8"
VIOLA="${VIOLA} F#4/4 F#4/8 F#4/4 F#4/8 G4/4 G4/8"
VIOLA="${VIOLA} A4/4 A4/8 A4/4 A4/8 F#4/4 F#4/8"
VIOLA="${VIOLA} E4/4 E4/8 F#4/4 F#4/2"

echo "Generating Viola..."
"${BIN}/seq" --notes "${VIOLA}" --bpm 0 --ch 2 --patch 41 --vel 80 \
  > /tmp/baroque-viola.jsonl

# === CELLO - Basso continuo bass (patch 42) ===
CELLO="D3/4 D3/8 A2/4 A2/8 B2/4 B2/8"
CELLO="${CELLO} G2/4 G2/8 D3/4 D3/8 G2/4 G2/8"
CELLO="${CELLO} F#2/4 F#2/8 D3/4 D3/8 F#2/4 F#2/8"
CELLO="${CELLO} A2/4 A2/8 D3/4 D3/2"

echo "Generating Cello..."
"${BIN}/seq" --notes "${CELLO}" --bpm 0 --ch 3 --patch 42 --vel 90 \
  > /tmp/baroque-cello.jsonl

# === HARPSICHORD - Continuo chords (patch 6) ===
# Arpeggiated chords
HARPSI="D4/16 F#4/16 A4/16 D5/16 F#4/16 A4/16 D5/16 F#5/16"
HARPSI="${HARPSI} A3/16 C#4/16 E4/16 A4/16 C#4/16 E4/16 A4/16 C#5/16"
HARPSI="${HARPSI} B3/16 D4/16 G4/16 B4/16 D4/16 G4/16 B4/16 D5/16"
HARPSI="${HARPSI} G3/16 B3/16 D4/16 G4/16 B3/16 D4/16 G4/16 B4/16"
HARPSI="${HARPSI} D4/16 F#4/16 A4/16 D5/16 F#4/16 A4/16 D5/16 F#5/16"
HARPSI="${HARPSI} D4/16 F#4/16 A4/16 D5/16 F#4/16 A4/16 D5/16 F#5/16"
HARPSI="${HARPSI} A3/16 D4/16 F#4/16 A4/16 D4/16 F#4/16 A4/16 D5/16"
HARPSI="${HARPSI} D4/8 F#4/8 A4/8 D5/2"

echo "Generating Harpsichord..."
"${BIN}/seq" --notes "${HARPSI}" --bpm 0 --ch 4 --patch 6 --vel 70 \
  > /tmp/baroque-harpsi.jsonl

# === RECORDER - Ornamental line (patch 74) ===
RECORDER="R/2 A5/8 B5/16 A5/16 G5/8 F#5/8"
RECORDER="${RECORDER} E5/8 F#5/16 E5/16 D5/8 C#5/8 D5/4 E5/8"
RECORDER="${RECORDER} F#5/8 G5/16 F#5/16 E5/8 D5/8 C#5/8 D5/16 E5/16"
RECORDER="${RECORDER} F#5/4 E5/8 D5/2"

echo "Generating Recorder..."
"${BIN}/seq" --notes "${RECORDER}" --bpm 0 --ch 5 --patch 74 --vel 75 \
  > /tmp/baroque-recorder.jsonl

# Combine all voices
echo ""
echo "Combining voices..."
cat /tmp/baroque-violin1.jsonl /tmp/baroque-violin2.jsonl \
    /tmp/baroque-viola.jsonl /tmp/baroque-cello.jsonl \
    /tmp/baroque-harpsi.jsonl /tmp/baroque-recorder.jsonl \
  | "${BIN}/viz" \
  | "${BIN}/trim" --auto \
  > /tmp/baroque-full.jsonl

# Stats
echo ""
echo "Instrumentation:"
echo "  Strings:  Violin I $(grep -c NoteOn /tmp/baroque-violin1.jsonl), Violin II $(grep -c NoteOn /tmp/baroque-violin2.jsonl), Viola $(grep -c NoteOn /tmp/baroque-viola.jsonl), Cello $(grep -c NoteOn /tmp/baroque-cello.jsonl)"
echo "  Continuo: Harpsichord $(grep -c NoteOn /tmp/baroque-harpsi.jsonl)"
echo "  Wind:     Recorder $(grep -c NoteOn /tmp/baroque-recorder.jsonl)"

# Convert to MIDI
echo ""
echo "Converting to MIDI..."
cat /tmp/baroque-full.jsonl | "${BIN}/to-midi" --out /tmp/demo-baroque.mid

# Render to WAV
echo "Rendering to WAV..."
if [[ -f "$SF2" ]]; then
    fluidsynth -ni -F /tmp/demo-baroque-raw.wav "$SF2" /tmp/demo-baroque.mid 2>/dev/null

    # Trim to ~15 seconds with fade out
    echo "Trimming..."
    ffmpeg -y -i /tmp/demo-baroque-raw.wav -t 15 -af "afade=t=out:st=13:d=2" "$OUTPUT" 2>/dev/null

    DURATION=$(afinfo "$OUTPUT" 2>/dev/null | grep "estimated duration" | awk '{print $3}')
    echo "Created: $OUTPUT (${DURATION}s)"

    echo ""
    echo "Playing..."
    afplay "$OUTPUT"
else
    echo "Soundfont not found: $SF2"
    echo "MIDI file: /tmp/demo-baroque.mid"
fi

echo ""
echo "=== Done ==="
