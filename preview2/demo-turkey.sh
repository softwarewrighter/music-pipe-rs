#!/bin/bash
# Turkey in the Straw (Traditional, 1820s)
# Classic American square dance fiddle tune
# Public domain - traditional tune over 200 years old
# EXACT melody from The Session (thesession.org/tunes/2638)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/preview2/demo-turkey.wav"

echo "=== Turkey in the Straw (Traditional, 1820s) ==="
echo "Classic square dance fiddle tune"
echo ""

# Key: G major, 4/4 time, 120 BPM with 16th notes
# EXACT ABC notation from The Session:
# |:BA|GFGA G2 B,C|DEDB, D2 GA|B2 B2 BAGA|B2 A2 A2 BA|
# GFGA G2 B,C|DEDB, D2 GA|B d2 e dBGA|B2 A2 G2:|
#
# ABC L:1/8 -> my 16ths at 120 BPM (ABC 8th = my 16th, ABC quarter = my 8th)

# Lead fiddle (patch 40)
# Pickup: BA
FIDDLE="B4/16 A4/16"
# M1: GFGA G2 B,C
FIDDLE="${FIDDLE} G4/16 F#4/16 G4/16 A4/16 G4/8 B3/16 C4/16"
# M2: DEDB, D2 GA
FIDDLE="${FIDDLE} D4/16 E4/16 D4/16 B3/16 D4/8 G4/16 A4/16"
# M3: B2 B2 BAGA
FIDDLE="${FIDDLE} B4/8 B4/8 B4/16 A4/16 G4/16 A4/16"
# M4: B2 A2 A2 BA
FIDDLE="${FIDDLE} B4/8 A4/8 A4/8 B4/16 A4/16"
# M5: GFGA G2 B,C (repeat of M1)
FIDDLE="${FIDDLE} G4/16 F#4/16 G4/16 A4/16 G4/8 B3/16 C4/16"
# M6: DEDB, D2 GA (repeat of M2)
FIDDLE="${FIDDLE} D4/16 E4/16 D4/16 B3/16 D4/8 G4/16 A4/16"
# M7: B d2 e dBGA
FIDDLE="${FIDDLE} B4/16 D5/8 E5/16 D5/16 B4/16 G4/16 A4/16"
# M8: B2 A2 G2
FIDDLE="${FIDDLE} B4/8 A4/8 G4/4"

# B Part:
# |:d2|B d2 B d2 d2|B d2 B d2 d2|c e2 c e2 e2|c e2 c e2 e2|
# g2 g2 d2 d2|B2 B2 A2 GA|B d2 e dBGA|B2 A2 G2:|

# Pickup: d2
FIDDLE="${FIDDLE} D5/8"
# M1: B d2 B d2 d2
FIDDLE="${FIDDLE} B4/16 D5/8 B4/16 D5/8 D5/8"
# M2: B d2 B d2 d2 (same)
FIDDLE="${FIDDLE} B4/16 D5/8 B4/16 D5/8 D5/8"
# M3: c e2 c e2 e2
FIDDLE="${FIDDLE} C5/16 E5/8 C5/16 E5/8 E5/8"
# M4: c e2 c e2 e2 (same)
FIDDLE="${FIDDLE} C5/16 E5/8 C5/16 E5/8 E5/8"
# M5: g2 g2 d2 d2
FIDDLE="${FIDDLE} G5/8 G5/8 D5/8 D5/8"
# M6: B2 B2 A2 GA
FIDDLE="${FIDDLE} B4/8 B4/8 A4/8 G4/16 A4/16"
# M7: B d2 e dBGA
FIDDLE="${FIDDLE} B4/16 D5/8 E5/16 D5/16 B4/16 G4/16 A4/16"
# M8: B2 A2 G2
FIDDLE="${FIDDLE} B4/8 A4/8 G4/4"

echo "Generating lead fiddle..."
"${BIN}/seq" --notes "${FIDDLE}" --bpm 120 --ch 0 --patch 40 --vel 100 \
  > /tmp/turkey-fiddle.jsonl

# Second fiddle - harmony a third/sixth below (patch 40)
# A part harmony
FIDDLE2="G4/16 F#4/16"
FIDDLE2="${FIDDLE2} E4/16 D4/16 E4/16 F#4/16 E4/8 G3/16 A3/16"
FIDDLE2="${FIDDLE2} B3/16 C4/16 B3/16 G3/16 B3/8 E4/16 F#4/16"
FIDDLE2="${FIDDLE2} G4/8 G4/8 G4/16 F#4/16 E4/16 F#4/16"
FIDDLE2="${FIDDLE2} G4/8 F#4/8 F#4/8 G4/16 F#4/16"
FIDDLE2="${FIDDLE2} E4/16 D4/16 E4/16 F#4/16 E4/8 G3/16 A3/16"
FIDDLE2="${FIDDLE2} B3/16 C4/16 B3/16 G3/16 B3/8 E4/16 F#4/16"
FIDDLE2="${FIDDLE2} G4/16 B4/8 C5/16 B4/16 G4/16 E4/16 F#4/16"
FIDDLE2="${FIDDLE2} G4/8 F#4/8 E4/4"
# B part harmony
FIDDLE2="${FIDDLE2} B4/8"
FIDDLE2="${FIDDLE2} G4/16 B4/8 G4/16 B4/8 B4/8"
FIDDLE2="${FIDDLE2} G4/16 B4/8 G4/16 B4/8 B4/8"
FIDDLE2="${FIDDLE2} A4/16 C5/8 A4/16 C5/8 C5/8"
FIDDLE2="${FIDDLE2} A4/16 C5/8 A4/16 C5/8 C5/8"
FIDDLE2="${FIDDLE2} E5/8 E5/8 B4/8 B4/8"
FIDDLE2="${FIDDLE2} G4/8 G4/8 F#4/8 E4/16 F#4/16"
FIDDLE2="${FIDDLE2} G4/16 B4/8 C5/16 B4/16 G4/16 E4/16 F#4/16"
FIDDLE2="${FIDDLE2} G4/8 F#4/8 E4/4"

echo "Generating second fiddle..."
"${BIN}/seq" --notes "${FIDDLE2}" --bpm 0 --ch 1 --patch 40 --vel 75 \
  > /tmp/turkey-fiddle2.jsonl

# Banjo - chord strums on the beat (patch 105)
# Simplified accompaniment pattern
BANJO="R/16 R/16"
# 8 measures of A part + 8 measures of B part = 16 measures
# Each measure: G chord or D chord
BANJO="${BANJO} G3/8 B3/8 G3/8 B3/8"
BANJO="${BANJO} G3/8 B3/8 D3/8 A3/8"
BANJO="${BANJO} G3/8 B3/8 G3/8 B3/8"
BANJO="${BANJO} G3/8 B3/8 D3/8 A3/8"
BANJO="${BANJO} G3/8 B3/8 G3/8 B3/8"
BANJO="${BANJO} G3/8 B3/8 D3/8 A3/8"
BANJO="${BANJO} G3/8 B3/8 G3/8 B3/8"
BANJO="${BANJO} G3/8 D3/8 G3/4"
# B part
BANJO="${BANJO} R/8"
BANJO="${BANJO} G3/8 B3/8 G3/8 B3/8"
BANJO="${BANJO} G3/8 B3/8 G3/8 B3/8"
BANJO="${BANJO} C3/8 E3/8 C3/8 E3/8"
BANJO="${BANJO} C3/8 E3/8 C3/8 E3/8"
BANJO="${BANJO} G3/8 B3/8 D3/8 A3/8"
BANJO="${BANJO} G3/8 B3/8 D3/8 A3/8"
BANJO="${BANJO} G3/8 B3/8 G3/8 B3/8"
BANJO="${BANJO} G3/8 D3/8 G3/4"

echo "Generating banjo..."
"${BIN}/seq" --notes "${BANJO}" --bpm 0 --ch 2 --patch 105 --vel 70 \
  > /tmp/turkey-banjo.jsonl

# Upright bass - root notes (patch 32)
BASS="R/16 R/16"
BASS="${BASS} G2/4 G2/4 G2/4 D2/4 G2/4 G2/4 G2/4 D2/4"
BASS="${BASS} G2/4 G2/4 G2/4 D2/4 G2/4 D2/4 G2/2"
# B part
BASS="${BASS} R/8"
BASS="${BASS} G2/4 G2/4 G2/4 G2/4 C3/4 C3/4 C3/4 C3/4"
BASS="${BASS} G2/4 G2/4 D2/4 D2/4 G2/4 D2/4 G2/2"

echo "Generating bass..."
"${BIN}/seq" --notes "${BASS}" --bpm 0 --ch 3 --patch 32 --vel 90 \
  > /tmp/turkey-bass.jsonl

# Combine
echo "Combining voices..."
cat /tmp/turkey-fiddle.jsonl /tmp/turkey-fiddle2.jsonl /tmp/turkey-banjo.jsonl /tmp/turkey-bass.jsonl \
  | "${BIN}/viz" 2>/dev/null \
  | "${BIN}/trim" --auto \
  > /tmp/turkey-full.jsonl

# Stats
echo ""
echo "Events:"
echo "  Fiddle 1: $(grep -c NoteOn /tmp/turkey-fiddle.jsonl)"
echo "  Fiddle 2: $(grep -c NoteOn /tmp/turkey-fiddle2.jsonl)"
echo "  Banjo:    $(grep -c NoteOn /tmp/turkey-banjo.jsonl)"
echo "  Bass:     $(grep -c NoteOn /tmp/turkey-bass.jsonl)"

# Convert to MIDI
echo ""
echo "Converting to MIDI..."
cat /tmp/turkey-full.jsonl | "${BIN}/to-midi" --out /tmp/demo-turkey.mid

# Render to WAV
echo "Rendering to WAV..."
if [[ -f "$SF2" ]]; then
    fluidsynth -ni -F /tmp/demo-turkey-raw.wav "$SF2" /tmp/demo-turkey.mid 2>/dev/null

    # Trim to ~12 seconds with fade
    echo "Trimming..."
    ffmpeg -y -i /tmp/demo-turkey-raw.wav -t 12 -af "afade=t=out:st=10:d=2" "$OUTPUT" 2>/dev/null

    DURATION=$(afinfo "$OUTPUT" 2>/dev/null | grep "estimated duration" | awk '{print $3}')
    echo "Created: $OUTPUT (${DURATION}s)"

    echo ""
    echo "Playing..."
    afplay "$OUTPUT"
else
    echo "Soundfont not found: $SF2"
    echo "MIDI file: /tmp/demo-turkey.mid"
fi

echo ""
echo "=== Done ==="
