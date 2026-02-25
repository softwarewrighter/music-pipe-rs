#!/bin/bash
# Wagner - Ride of the Valkyries (WWV 86B)
# Full late-Romantic orchestration
# "Kill the Wabbit!" - The famous galloping theme

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/examples/demo-valkyries.wav"

echo "=== Wagner: Ride of the Valkyries ==="
echo "Full orchestral arrangement"
echo ""

# The iconic theme: B B B | D -- B | rising through D-F#-A
# Key: B minor, 9/8 galloping rhythm

# === BRASS SECTION ===

# French Horns - the iconic melody (patch 60)
HORN="B4/8 B4/8 B4/8 D5/4 B4/8 B4/8 B4/8 B4/8 D5/4 B4/8"
HORN="${HORN} D5/8 D5/8 D5/8 F#5/4 D5/8 D5/8 D5/8 D5/8 F#5/4 D5/8"
HORN="${HORN} F#5/8 F#5/8 F#5/8 A5/4 F#5/8 F#5/8 F#5/8 F#5/8 A5/4 F#5/8"
HORN="${HORN} D5/8 D5/8 D5/8 F#5/4 D5/8 B4/8 B4/8 B4/8 D5/2"

echo "Generating French Horns..."
"${BIN}/seq" --notes "${HORN}" --bpm 152 --ch 0 --patch 60 --vel 115 \
  > /tmp/valk-horn.jsonl

# Trumpets - heroic fanfare doubling (patch 56)
TRUMPET="R/2 R/4 D5/4 B4/8 B4/8 B4/8 B4/8 D5/4 B4/8"
TRUMPET="${TRUMPET} D5/8 D5/8 D5/8 F#5/4 D5/8 D5/8 D5/8 D5/8 F#5/4 D5/8"
TRUMPET="${TRUMPET} F#5/8 F#5/8 F#5/8 A5/4 F#5/8 F#5/8 F#5/8 F#5/8 A5/4 F#5/8"
TRUMPET="${TRUMPET} D5/8 D5/8 D5/8 F#5/4 D5/8 B4/8 B4/8 B4/8 D5/2"

echo "Generating Trumpets..."
"${BIN}/seq" --notes "${TRUMPET}" --bpm 0 --ch 1 --patch 56 --vel 105 \
  > /tmp/valk-trumpet.jsonl

# Trombones - power in lower register (patch 57)
TROMBONE="B3/8 B3/8 B3/8 D4/4 B3/8 B3/8 B3/8 B3/8 D4/4 B3/8"
TROMBONE="${TROMBONE} D4/8 D4/8 D4/8 F#4/4 D4/8 D4/8 D4/8 D4/8 F#4/4 D4/8"
TROMBONE="${TROMBONE} F#4/8 F#4/8 F#4/8 A4/4 F#4/8 F#4/8 F#4/8 F#4/8 A4/4 F#4/8"
TROMBONE="${TROMBONE} D4/8 D4/8 D4/8 F#4/4 D4/8 B3/8 B3/8 B3/8 D4/2"

echo "Generating Trombones..."
"${BIN}/seq" --notes "${TROMBONE}" --bpm 0 --ch 2 --patch 57 --vel 100 \
  > /tmp/valk-trombone.jsonl

# Tuba - deep foundation (patch 58) - BOOSTED VELOCITY
TUBA="B2/4 B2/8 B2/4 B2/8 B2/4 B2/8 B2/4 B2/8"
TUBA="${TUBA} D3/4 D3/8 D3/4 D3/8 D3/4 D3/8 D3/4 D3/8"
TUBA="${TUBA} F#3/4 F#3/8 F#3/4 F#3/8 F#3/4 F#3/8 F#3/4 F#3/8"
TUBA="${TUBA} B2/4 B2/8 B2/4 B2/8 B2/2"

echo "Generating Tuba..."
"${BIN}/seq" --notes "${TUBA}" --bpm 0 --ch 3 --patch 58 --vel 120 \
  > /tmp/valk-tuba.jsonl

# === WOODWINDS ===

# Flutes/Piccolo - soaring above (patch 72 = Piccolo)
FLUTE="R/2 B5/8 B5/8 B5/8 D6/4 B5/8 B5/8 B5/8 B5/8 D6/4 B5/8"
FLUTE="${FLUTE} D6/8 D6/8 D6/8 F#6/4 D6/8 D6/8 D6/8 D6/8 F#6/4 D6/8"
FLUTE="${FLUTE} F#6/8 F#6/8 F#6/8 A6/4 F#6/8 F#6/8 F#6/8 F#6/8 A6/4 F#6/8"
FLUTE="${FLUTE} D6/4 F#6/4 D6/4 B5/2"

echo "Generating Flutes/Piccolo..."
"${BIN}/seq" --notes "${FLUTE}" --bpm 0 --ch 4 --patch 72 --vel 90 \
  > /tmp/valk-flute.jsonl

# Clarinets - swirling figures (patch 71)
CLARINET="R/4 F#5/8 D5/8 F#5/8 D5/8 B4/8 D5/8 F#5/8 D5/8 B4/8 D5/8"
CLARINET="${CLARINET} A5/8 F#5/8 A5/8 F#5/8 D5/8 F#5/8 A5/8 F#5/8 D5/8 F#5/8"
CLARINET="${CLARINET} B5/8 A5/8 F#5/8 A5/8 F#5/8 D5/8 F#5/8 D5/8 B4/8 D5/8"
CLARINET="${CLARINET} F#5/8 D5/8 B4/8 D5/4 B4/2"

echo "Generating Clarinets..."
"${BIN}/seq" --notes "${CLARINET}" --bpm 0 --ch 5 --patch 71 --vel 80 \
  > /tmp/valk-clarinet.jsonl

# === STRINGS ===

# Violins - driving tremolo figures (patch 48 = Strings)
VIOLIN="B4/8 F#4/8 D4/8 B4/8 F#4/8 D4/8 B4/8 F#4/8 D4/8 B4/8 F#4/8 D4/8"
VIOLIN="${VIOLIN} D5/8 A4/8 F#4/8 D5/8 A4/8 F#4/8 D5/8 A4/8 F#4/8 D5/8 A4/8 F#4/8"
VIOLIN="${VIOLIN} F#5/8 D5/8 A4/8 F#5/8 D5/8 A4/8 F#5/8 D5/8 A4/8 F#5/8 D5/8 A4/8"
VIOLIN="${VIOLIN} D5/8 A4/8 F#4/8 B4/8 F#4/8 D4/8 B4/2"

echo "Generating Violins..."
"${BIN}/seq" --notes "${VIOLIN}" --bpm 0 --ch 6 --patch 48 --vel 85 \
  > /tmp/valk-violin.jsonl

# Cellos - powerful bass line (patch 42) - BOOSTED VELOCITY
CELLO="B2/4 B2/8 B2/4 B2/8 B2/4 B2/8 B2/4 B2/8"
CELLO="${CELLO} D3/4 D3/8 D3/4 D3/8 D3/4 D3/8 D3/4 D3/8"
CELLO="${CELLO} F#3/4 F#3/8 F#3/4 F#3/8 F#3/4 F#3/8 F#3/4 F#3/8"
CELLO="${CELLO} B2/4 B2/8 B2/4 B2/8 B2/2"

echo "Generating Cellos..."
"${BIN}/seq" --notes "${CELLO}" --bpm 0 --ch 7 --patch 42 --vel 115 \
  > /tmp/valk-cello.jsonl

# === PERCUSSION ===

# Timpani - dramatic accents on downbeats (note 47 = low tom, ch 9)
echo "Generating Timpani..."
"${BIN}/seed" 1883 \
  | "${BIN}/euclid" --steps 12 --pulses 2 --note 41 --ch 9 --bpm 0 --repeat 10 \
      --vel 110 --vel-var 15 --accent 0.4 --skip 0.1 \
  > /tmp/valk-timpani.jsonl

# Cymbals - crashes on climactic moments (note 49 = crash)
echo "Generating Cymbals..."
"${BIN}/seed" 1876 \
  | "${BIN}/euclid" --steps 24 --pulses 2 --note 49 --ch 9 --bpm 0 --repeat 5 \
      --vel 90 --vel-var 20 --skip 0.2 \
  > /tmp/valk-cymbal.jsonl

# Combine all voices
echo "Combining full orchestra..."
cat /tmp/valk-horn.jsonl /tmp/valk-trumpet.jsonl /tmp/valk-trombone.jsonl /tmp/valk-tuba.jsonl \
    /tmp/valk-flute.jsonl /tmp/valk-clarinet.jsonl \
    /tmp/valk-violin.jsonl /tmp/valk-cello.jsonl \
    /tmp/valk-timpani.jsonl /tmp/valk-cymbal.jsonl \
  | "${BIN}/viz" \
  > /tmp/valk-full.jsonl

# Stats
echo ""
echo "Orchestration:"
echo "  Brass:     Horns $(grep -c NoteOn /tmp/valk-horn.jsonl), Trumpets $(grep -c NoteOn /tmp/valk-trumpet.jsonl), Trombones $(grep -c NoteOn /tmp/valk-trombone.jsonl), Tuba $(grep -c NoteOn /tmp/valk-tuba.jsonl)"
echo "  Woodwinds: Flutes $(grep -c NoteOn /tmp/valk-flute.jsonl), Clarinets $(grep -c NoteOn /tmp/valk-clarinet.jsonl)"
echo "  Strings:   Violins $(grep -c NoteOn /tmp/valk-violin.jsonl), Cellos $(grep -c NoteOn /tmp/valk-cello.jsonl)"
echo "  Percussion: Timpani+Cymbals"

# Convert to MIDI
echo ""
echo "Converting to MIDI..."
cat /tmp/valk-full.jsonl | "${BIN}/to-midi" --out /tmp/demo-valkyries.mid

# Render to WAV
echo "Rendering to WAV..."
if [[ -f "$SF2" ]]; then
    fluidsynth -ni -F "$OUTPUT" "$SF2" /tmp/demo-valkyries.mid 2>/dev/null

    DURATION=$(afinfo "$OUTPUT" 2>/dev/null | grep "estimated duration" | awk '{print $3}')
    echo "Created: $OUTPUT (${DURATION}s)"

    echo ""
    echo "Playing..."
    afplay "$OUTPUT"
else
    echo "Soundfont not found: $SF2"
    echo "MIDI file: /tmp/demo-valkyries.mid"
fi

echo ""
echo "=== Done ==="
