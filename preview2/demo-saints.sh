#!/bin/bash
# When the Saints Go Marching In (Traditional)
# New Orleans brass band style
# Public domain - traditional spiritual/hymn

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
OUTPUT="${SCRIPT_DIR}/preview2/demo-saints.wav"

echo "=== When the Saints Go Marching In (Traditional) ==="
echo "New Orleans brass band arrangement"
echo ""

# Key: C major (from abcnotation.com ABC transcription)
# ABC: CEF|G4|z CEF|G4|z CEF|G2E2|C2E2|D4|z EED|C4|E2G2|GF3|z2 EF|G2E2|C2 D2|C4|z|
# M:C (4/4), L:1/4 (quarter note base)

# Trumpet lead (patch 56) - exact ABC transcription
# Pickup: CEF = C E F quarter notes
TRUMPET="C5/4 E5/4 F5/4"
# M1: G4 = G whole note
TRUMPET="${TRUMPET} G5/1"
# M2: z CEF = rest C E F
TRUMPET="${TRUMPET} R/4 C5/4 E5/4 F5/4"
# M3: G4 = G whole note
TRUMPET="${TRUMPET} G5/1"
# M4: z CEF = rest C E F
TRUMPET="${TRUMPET} R/4 C5/4 E5/4 F5/4"
# M5: G2E2 = G half, E half
TRUMPET="${TRUMPET} G5/2 E5/2"
# M6: C2E2 = C half, E half
TRUMPET="${TRUMPET} C5/2 E5/2"
# M7: D4 = D whole note
TRUMPET="${TRUMPET} D5/1"
# M8: z EED = rest E E D
TRUMPET="${TRUMPET} R/4 E5/4 E5/4 D5/4"
# M9: C4 = C whole note
TRUMPET="${TRUMPET} C5/1"
# M10: E2G2 = E half, G half
TRUMPET="${TRUMPET} E5/2 G5/2"
# M11: GF3 = G quarter, F dotted half
TRUMPET="${TRUMPET} G5/4 F5/2 R/4"
# M12: z2 EF = half rest, E F
TRUMPET="${TRUMPET} R/2 E5/4 F5/4"
# M13: G2E2 = G half, E half
TRUMPET="${TRUMPET} G5/2 E5/2"
# M14: C2 D2 = C half, D half
TRUMPET="${TRUMPET} C5/2 D5/2"
# M15: C4 = C whole note (ending)
TRUMPET="${TRUMPET} C5/1"

echo "Generating trumpet lead..."
"${BIN}/seq" --notes "${TRUMPET}" --bpm 100 --ch 0 --patch 56 --vel 100 \
  > /tmp/saints-trumpet.jsonl

# Trombone harmony (patch 57) - thirds below trumpet, matching ABC structure
# Pickup harmony
TROMBONE="G4/4 C5/4 D5/4"
# M1: E whole
TROMBONE="${TROMBONE} E5/1"
# M2: rest G C D
TROMBONE="${TROMBONE} R/4 G4/4 C5/4 D5/4"
# M3: E whole
TROMBONE="${TROMBONE} E5/1"
# M4: rest G C D
TROMBONE="${TROMBONE} R/4 G4/4 C5/4 D5/4"
# M5: E half, C half
TROMBONE="${TROMBONE} E5/2 C5/2"
# M6: G half, C half
TROMBONE="${TROMBONE} G4/2 C5/2"
# M7: B whole
TROMBONE="${TROMBONE} B4/1"
# M8: rest C C B
TROMBONE="${TROMBONE} R/4 C5/4 C5/4 B4/4"
# M9: G whole
TROMBONE="${TROMBONE} G4/1"
# M10: C half, E half
TROMBONE="${TROMBONE} C5/2 E5/2"
# M11: E quarter, D dotted half
TROMBONE="${TROMBONE} E5/4 D5/2 R/4"
# M12: rest, C D
TROMBONE="${TROMBONE} R/2 C5/4 D5/4"
# M13: E half, C half
TROMBONE="${TROMBONE} E5/2 C5/2"
# M14: G half, B half
TROMBONE="${TROMBONE} G4/2 B4/2"
# M15: G whole
TROMBONE="${TROMBONE} G4/1"

echo "Generating trombone..."
"${BIN}/seq" --notes "${TROMBONE}" --bpm 0 --ch 1 --patch 57 --vel 85 \
  > /tmp/saints-trombone.jsonl

# Clarinet fills (patch 71) - fills between held notes, matching 15-bar structure
CLARINET="R/4 R/4 R/4"  # during pickup
CLARINET="${CLARINET} R/1"  # M1
CLARINET="${CLARINET} G5/4 A5/4 B5/4 C6/4"  # M2 fill
CLARINET="${CLARINET} R/1"  # M3
CLARINET="${CLARINET} C6/4 B5/4 A5/4 G5/4"  # M4 fill
CLARINET="${CLARINET} R/1"  # M5
CLARINET="${CLARINET} R/1"  # M6
CLARINET="${CLARINET} R/2 F5/4 G5/4"  # M7 fill
CLARINET="${CLARINET} A5/4 G5/4 F5/4 E5/4"  # M8 fill
CLARINET="${CLARINET} R/1"  # M9
CLARINET="${CLARINET} G5/4 A5/4 B5/4 C6/4"  # M10 fill
CLARINET="${CLARINET} R/1"  # M11
CLARINET="${CLARINET} R/1"  # M12
CLARINET="${CLARINET} R/1"  # M13
CLARINET="${CLARINET} E5/4 F5/4 G5/4 A5/4"  # M14 fill
CLARINET="${CLARINET} G5/1"  # M15 final

echo "Generating clarinet..."
"${BIN}/seq" --notes "${CLARINET}" --bpm 0 --ch 2 --patch 71 --vel 75 \
  > /tmp/saints-clarinet.jsonl

# Tuba bass (patch 58) - march bass matching 15-bar ABC structure
TUBA="C2/4 G2/4 C2/4"  # pickup (3 beats)
# M1-4: C chord
TUBA="${TUBA} C2/4 G2/4 C2/4 G2/4"
TUBA="${TUBA} C2/4 G2/4 C2/4 G2/4"
TUBA="${TUBA} C2/4 G2/4 C2/4 G2/4"
TUBA="${TUBA} C2/4 G2/4 C2/4 G2/4"
# M5-6: still C
TUBA="${TUBA} C2/4 G2/4 C2/4 G2/4"
TUBA="${TUBA} C2/4 G2/4 C2/4 G2/4"
# M7-8: G chord
TUBA="${TUBA} G2/4 D3/4 G2/4 D3/4"
TUBA="${TUBA} G2/4 D3/4 G2/4 D3/4"
# M9-10: C chord
TUBA="${TUBA} C2/4 G2/4 C2/4 G2/4"
TUBA="${TUBA} C2/4 G2/4 C2/4 G2/4"
# M11-12: F chord
TUBA="${TUBA} F2/4 C3/4 F2/4 C3/4"
TUBA="${TUBA} F2/4 C3/4 F2/4 C3/4"
# M13-14: C G
TUBA="${TUBA} C2/4 G2/4 C2/4 G2/4"
TUBA="${TUBA} C2/4 G2/4 G2/4 D3/4"
# M15: C final
TUBA="${TUBA} C2/1"

echo "Generating tuba..."
"${BIN}/seq" --notes "${TUBA}" --bpm 0 --ch 3 --patch 58 --vel 100 \
  > /tmp/saints-tuba.jsonl

# Snare drum march pattern (channel 9)
echo "Generating drums..."
"${BIN}/seed" 1865 \
  | "${BIN}/euclid" --steps 8 --pulses 4 --note 38 --ch 9 --bpm 0 --repeat 18 \
      --vel 85 --vel-var 15 --accent 0.3 \
  > /tmp/saints-snare.jsonl

# Bass drum on beats
"${BIN}/seed" 1901 \
  | "${BIN}/euclid" --steps 4 --pulses 2 --note 36 --ch 9 --bpm 0 --repeat 18 \
      --vel 100 --vel-var 10 \
  > /tmp/saints-kick.jsonl

# Combine
echo "Combining voices..."
cat /tmp/saints-trumpet.jsonl /tmp/saints-trombone.jsonl /tmp/saints-clarinet.jsonl \
    /tmp/saints-tuba.jsonl /tmp/saints-snare.jsonl /tmp/saints-kick.jsonl \
  | "${BIN}/viz" 2>/dev/null \
  | "${BIN}/trim" --auto \
  > /tmp/saints-full.jsonl

# Stats
echo ""
echo "Events:"
echo "  Trumpet:   $(grep -c NoteOn /tmp/saints-trumpet.jsonl)"
echo "  Trombone:  $(grep -c NoteOn /tmp/saints-trombone.jsonl)"
echo "  Clarinet:  $(grep -c NoteOn /tmp/saints-clarinet.jsonl)"
echo "  Tuba:      $(grep -c NoteOn /tmp/saints-tuba.jsonl)"
echo "  Drums:     $(($(grep -c NoteOn /tmp/saints-snare.jsonl) + $(grep -c NoteOn /tmp/saints-kick.jsonl)))"

# Convert to MIDI
echo ""
echo "Converting to MIDI..."
cat /tmp/saints-full.jsonl | "${BIN}/to-midi" --out /tmp/demo-saints.mid

# Render to WAV
echo "Rendering to WAV..."
if [[ -f "$SF2" ]]; then
    fluidsynth -ni -F /tmp/demo-saints-raw.wav "$SF2" /tmp/demo-saints.mid 2>/dev/null

    # Trim to ~12 seconds with fade
    echo "Trimming..."
    ffmpeg -y -i /tmp/demo-saints-raw.wav -t 12 -af "afade=t=out:st=10:d=2" "$OUTPUT" 2>/dev/null

    DURATION=$(afinfo "$OUTPUT" 2>/dev/null | grep "estimated duration" | awk '{print $3}')
    echo "Created: $OUTPUT (${DURATION}s)"

    echo ""
    echo "Playing..."
    afplay "$OUTPUT"
else
    echo "Soundfont not found: $SF2"
    echo "MIDI file: /tmp/demo-saints.mid"
fi

echo ""
echo "=== Done ==="
