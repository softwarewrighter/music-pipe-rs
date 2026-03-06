#!/bin/bash
# =============================================================================
# Wagner-esque Germanic Opera - Ride of the Valkyries style
# =============================================================================
#
# Composed in the style of Richard Wagner's heroic brass writing:
#   - B minor (dramatic, heroic key)
#   - Driving triplet rhythm (the galloping Valkyries)
#   - Bold brass fanfares with French horn calls
#   - Building intensity with layered entrances
#
# Instruments:
#   Ch 0: French Horn - heroic fanfare melody
#   Ch 1: Trombone - harmonic support and countermelody
#   Ch 2: Tuba - bass foundation with rhythmic drive
#   Ch 3: Timpani - thunderous accents
#
# Output: examples/demo-wagner-esque.wav

set -e
cd "$(dirname "$0")/.."

echo "=== Wagner-esque Germanic Opera ==="
echo "Key: B minor, Ride of the Valkyries style"
echo ""

# French Horn - the iconic Valkyrie fanfare
# Heroic leaps, triplet gallop rhythm, dramatic phrases
echo "Generating French Horn (Valkyrie fanfare)..."
./target/release/seq --notes "B4/t160*100 B4/t160*95 B4/t160*90 F#5/t320*105 D5/t160*95 B4/t160*90 B4/t160*88 B4/t160*85 F#5/t320*102 D5/t160*92 B4/t480*98 R/t160 B4/t160*95 D5/t160*92 F#5/t320*105 B5/t480*110 A5/t160*100 F#5/t160*95 D5/t320*98 B4/t480*95 R/t320 B4/t160*98 B4/t160*92 B4/t160*88 F#5/t320*105 D5/t160*95 B4/t160*90 B4/t160*88 B4/t160*85 F#5/t320*102 D5/t160*92 B4/t320*95 D5/t160*90 F#5/t160*95 B5/t480*110 A5/t320*100 G5/t320*98 F#5/t640*105" --bpm 152 --ch 0 --patch 60 > /tmp/wagner-horn.jsonl

# Trombone - powerful harmonic countermelody
# Enters after horn, provides depth and harmonic weight
echo "Generating Trombone (heroic harmony)..."
./target/release/seq --notes "R/t480 D4/t320*95 D4/t160*88 F#4/t320*98 D4/t160*90 B3/t480*95 R/t160 D4/t160*92 F#4/t160*90 A4/t320*98 F#4/t160*92 D4/t480*95 B3/t320*90 D4/t160*88 F#4/t480*98 R/t320 D4/t320*95 D4/t160*88 F#4/t320*98 D4/t160*90 B3/t320*92 D4/t160*88 B3/t160*85 D4/t160*90 F#4/t320*98 A4/t480*100 G4/t160*92 F#4/t160*90 E4/t160*88 D4/t480*95 F#4/t640*100" --bpm 0 --ch 1 --patch 57 > /tmp/wagner-trombone.jsonl

# Tuba - thunderous bass with galloping rhythm
# Provides the rhythmic foundation, outlining B minor
echo "Generating Tuba (thunderous bass)..."
./target/release/seq --notes "B2/t160*92 B2/t160*85 B2/t160*80 B2/t320*95 F#2/t160*88 B2/t160*85 B2/t160*80 B2/t160*78 B2/t320*92 F#2/t160*85 B2/t480*95 R/t160 D3/t160*88 D3/t160*82 F#3/t320*92 D3/t160*85 B2/t480*95 B2/t160*88 D3/t160*85 F#3/t320*92 B2/t480*95 R/t320 B2/t160*92 B2/t160*85 B2/t160*80 B2/t320*95 F#2/t160*88 B2/t160*85 B2/t160*80 B2/t160*78 B2/t320*92 F#2/t160*85 B2/t320*95 D3/t160*88 F#3/t160*90 B3/t480*98 A2/t320*88 G2/t320*85 F#2/t640*92" --bpm 0 --ch 2 --patch 58 > /tmp/wagner-tuba.jsonl

# Timpani - dramatic accents on strong beats
# C2=kick position used for timpani roll effect, emphasizes downbeats
echo "Generating Timpani (thunderous accents)..."
./target/release/seq --notes "B2/t160*100 R/t320 R/t480 B2/t160*95 R/t320 R/t480 B2/t160*98 R/t640 F#2/t160*90 B2/t160*95 R/t640 B2/t160*100 R/t320 R/t480 B2/t160*95 R/t320 R/t480 B2/t160*98 R/t320 R/t160 B2/t160*92 R/t160 B2/t160*100 R/t320 R/t480 B2/t160*95 R/t320 R/t480 B2/t160*98 R/t640 F#2/t160*90 B2/t160*95 R/t480 B2/t160*105 B2/t160*100 B2/t160*95 B2/t640*110" --bpm 0 --ch 3 --patch 47 > /tmp/wagner-timpani.jsonl

# Combine all voices
echo "Combining voices..."
cat /tmp/wagner-horn.jsonl /tmp/wagner-trombone.jsonl /tmp/wagner-tuba.jsonl /tmp/wagner-timpani.jsonl | \
    ./target/release/viz > /tmp/wagner-full.jsonl

# Convert to MIDI
echo "Converting to MIDI..."
cat /tmp/wagner-full.jsonl | ./target/release/to-midi --out /tmp/demo-wagner-esque.mid

# Render to WAV
echo "Rendering to WAV..."
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
fluidsynth -ni -F /tmp/wagner-raw.wav "$SF2" /tmp/demo-wagner-esque.mid

# Trim with fade
ffmpeg -y -i /tmp/wagner-raw.wav -t 14 -af "volume=1.4,afade=t=out:st=12:d=2" examples/demo-wagner-esque.wav 2>/dev/null

echo ""
echo "Created: examples/demo-wagner-esque.wav"
echo "Style: B minor heroic brass, Ride of the Valkyries style"
echo ""
echo "Playing..."
afplay examples/demo-wagner-esque.wav
