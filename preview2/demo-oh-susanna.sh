#!/bin/bash
# Stephen Foster - Oh! Susanna (1848)
# Classic American folk song
# Public domain - composed nearly 180 years ago

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/preview2/demo-oh-susanna.wav"

echo "=== Stephen Foster: Oh! Susanna (1848) ==="
echo "Classic American folk - Banjo and Fiddle"
echo ""

# Key: D major (from 1851 Gumbo Chaff banjo tutor ABC notation)
# ABC: d/e/|fa ab|af d>e|ff ed|e3 d/e/|fa ab|af de|ff ee|d3||
# "I come from Alabama with my banjo on my knee"

# Banjo melody (patch 105) - exact ABC transcription, transposed to D4 range
# Pickup: d/e/ = D E (16ths)
MELODY="D4/16 E4/16"
# M1: fa ab = F# A A B
MELODY="${MELODY} F#4/8 A4/8 A4/8 B4/8"
# M2: af d>e = A F# D E (simplified - dotted becomes regular)
MELODY="${MELODY} A4/8 F#4/8 D4/8 E4/8"
# M3: ff ed = F# F# E D
MELODY="${MELODY} F#4/8 F#4/8 E4/8 D4/8"
# M4: e3 d/e/ = E(dotted quarter) D E (pickup)
MELODY="${MELODY} E4/4 D4/16 E4/16"
# M5-8 (repeat with variation): fa ab|af de|ff ee|d3
MELODY="${MELODY} F#4/8 A4/8 A4/8 B4/8"
MELODY="${MELODY} A4/8 F#4/8 D4/8 E4/8"
MELODY="${MELODY} F#4/8 F#4/8 E4/8 E4/8"
MELODY="${MELODY} D4/4 R/8"
# Chorus: g2g2|b b2b|aa fd|e3 d/e/|
MELODY="${MELODY} G4/4 G4/4"
MELODY="${MELODY} B4/8 B4/4 B4/8"
MELODY="${MELODY} A4/8 A4/8 F#4/8 D4/8"
MELODY="${MELODY} E4/4 D4/16 E4/16"
# fa ab|af de|ff ee|d3:|
MELODY="${MELODY} F#4/8 A4/8 A4/8 B4/8"
MELODY="${MELODY} A4/8 F#4/8 D4/8 E4/8"
MELODY="${MELODY} F#4/8 F#4/8 E4/8 E4/8"
MELODY="${MELODY} D4/4 R/4"

echo "Generating banjo melody..."
"${BIN}/seq" --notes "${MELODY}" --bpm 120 --ch 0 --patch 105 --vel 100 \
  > /tmp/sus-melody.jsonl

# Fiddle harmony (patch 40) - plays thirds above in D major
# Following banjo melody a third higher
FIDDLE="F#4/16 G4/16"
FIDDLE="${FIDDLE} A4/8 C#5/8 C#5/8 D5/8"
FIDDLE="${FIDDLE} C#5/8 A4/8 F#4/8 G4/8"
FIDDLE="${FIDDLE} A4/8 A4/8 G4/8 F#4/8"
FIDDLE="${FIDDLE} G4/8 R/8 F#4/16 G4/16"
FIDDLE="${FIDDLE} A4/8 C#5/8 C#5/8 D5/8"
FIDDLE="${FIDDLE} C#5/8 A4/8 F#4/8 G4/8"
FIDDLE="${FIDDLE} A4/8 A4/8 G4/8 G4/8"
FIDDLE="${FIDDLE} F#4/4 R/8"
# Chorus harmony
FIDDLE="${FIDDLE} B4/4 B4/4"
FIDDLE="${FIDDLE} D5/8 D5/4 D5/8"
FIDDLE="${FIDDLE} C#5/8 C#5/8 A4/8 F#4/8"
FIDDLE="${FIDDLE} G4/8 R/8 F#4/16 G4/16"
FIDDLE="${FIDDLE} A4/8 C#5/8 C#5/8 D5/8"
FIDDLE="${FIDDLE} C#5/8 A4/8 F#4/8 G4/8"
FIDDLE="${FIDDLE} A4/8 A4/8 G4/8 G4/8"
FIDDLE="${FIDDLE} F#4/4 R/4"

echo "Generating fiddle harmony..."
"${BIN}/seq" --notes "${FIDDLE}" --bpm 0 --ch 1 --patch 40 --vel 80 \
  > /tmp/sus-fiddle.jsonl

# Acoustic guitar bass (patch 25) - D major chord pattern
GUITAR="D2/8 A2/8 D2/8 A2/8 D2/8 A2/8 A2/8 E3/8"
GUITAR="${GUITAR} D2/8 A2/8 D2/8 A2/8 D2/8 A2/8 A2/8 E3/8"
GUITAR="${GUITAR} D2/8 A2/8 D2/8 A2/8 D2/8 A2/8 A2/8 E3/8"
GUITAR="${GUITAR} D2/8 A2/8 D2/8 A2/8 D2/4"
GUITAR="${GUITAR} D2/8 A2/8 D2/8 A2/8 D2/8 A2/8 A2/8 E3/8"
GUITAR="${GUITAR} D2/8 A2/8 D2/8 A2/8 D2/8 A2/8 A2/8 E3/8"
GUITAR="${GUITAR} D2/8 A2/8 D2/8 A2/8 D2/8 A2/8 A2/8 E3/8"
GUITAR="${GUITAR} D2/8 A2/8 D2/8 A2/8 D2/4"
# Chorus bass - G D A D
GUITAR="${GUITAR} G2/8 D3/8 G2/8 D3/8 G2/8 D3/8 G2/8 D3/8"
GUITAR="${GUITAR} D2/8 A2/8 A2/8 E3/8 D2/8 A2/8 D2/4"
# Final verse bass
GUITAR="${GUITAR} D2/8 A2/8 D2/8 A2/8 D2/8 A2/8 A2/8 E3/8"
GUITAR="${GUITAR} D2/8 A2/8 D2/8 A2/8 D2/4"

echo "Generating acoustic guitar..."
"${BIN}/seq" --notes "${GUITAR}" --bpm 0 --ch 2 --patch 25 --vel 70 \
  > /tmp/sus-guitar.jsonl

# Harmonica accent (patch 22) - joins at chorus in D major
HARMONICA="R/2 R/2 R/2 R/2 R/2 R/2 R/2 R/4"
# Chorus melody doubled: g2g2|b b2b|aa fd|e3 d/e/|...
HARMONICA="${HARMONICA} G4/4 G4/4"
HARMONICA="${HARMONICA} B4/8 B4/4 B4/8"
HARMONICA="${HARMONICA} A4/8 A4/8 F#4/8 D4/8"
HARMONICA="${HARMONICA} E4/8 R/8 D4/16 E4/16"
HARMONICA="${HARMONICA} F#4/8 A4/8 A4/8 B4/8"
HARMONICA="${HARMONICA} A4/8 F#4/8 D4/8 E4/8"
HARMONICA="${HARMONICA} F#4/8 F#4/8 E4/8 E4/8"
HARMONICA="${HARMONICA} D4/4 R/4"

echo "Generating harmonica..."
"${BIN}/seq" --notes "${HARMONICA}" --bpm 0 --ch 3 --patch 22 --vel 70 \
  > /tmp/sus-harmonica.jsonl

# Combine
echo "Combining voices..."
cat /tmp/sus-melody.jsonl /tmp/sus-fiddle.jsonl /tmp/sus-guitar.jsonl /tmp/sus-harmonica.jsonl \
  | "${BIN}/viz" 2>/dev/null \
  | "${BIN}/trim" --auto \
  > /tmp/sus-full.jsonl

# Stats
echo ""
echo "Events:"
echo "  Banjo:     $(grep -c NoteOn /tmp/sus-melody.jsonl)"
echo "  Fiddle:    $(grep -c NoteOn /tmp/sus-fiddle.jsonl)"
echo "  Guitar:    $(grep -c NoteOn /tmp/sus-guitar.jsonl)"
echo "  Harmonica: $(grep -c NoteOn /tmp/sus-harmonica.jsonl)"

# Convert to MIDI
echo ""
echo "Converting to MIDI..."
cat /tmp/sus-full.jsonl | "${BIN}/to-midi" --out /tmp/demo-oh-susanna.mid

# Render to WAV
echo "Rendering to WAV..."
if [[ -f "$SF2" ]]; then
    fluidsynth -ni -F /tmp/demo-oh-susanna-raw.wav "$SF2" /tmp/demo-oh-susanna.mid 2>/dev/null

    # Trim to ~12 seconds with fade
    echo "Trimming..."
    ffmpeg -y -i /tmp/demo-oh-susanna-raw.wav -t 12 -af "afade=t=out:st=10:d=2" "$OUTPUT" 2>/dev/null

    DURATION=$(afinfo "$OUTPUT" 2>/dev/null | grep "estimated duration" | awk '{print $3}')
    echo "Created: $OUTPUT (${DURATION}s)"

    echo ""
    echo "Playing..."
    afplay "$OUTPUT"
else
    echo "Soundfont not found: $SF2"
    echo "MIDI file: /tmp/demo-oh-susanna.mid"
fi

echo ""
echo "=== Done ==="
