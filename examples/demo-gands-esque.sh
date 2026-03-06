#!/bin/bash
# =============================================================================
# Gilbert & Sullivan-esque British Operetta
# =============================================================================
#
# Composed in the style of Gilbert & Sullivan's comic operas:
#   - C major (bright, cheerful key)
#   - Bouncy, witty patter-song rhythms
#   - Light woodwind melodies
#   - Pizzicato strings for comic bounce
#   - Pompous bassoon for comedic effect
#
# Instruments:
#   Ch 0: Flute - playful melody
#   Ch 1: Oboe - comic counterpoint
#   Ch 2: Pizzicato Strings - bouncy accompaniment
#   Ch 3: Bassoon - pompous comic bass
#
# Output: examples/demo-gands-esque.wav

set -e
cd "$(dirname "$0")/.."

echo "=== Gilbert & Sullivan-esque British Operetta ==="
echo "Key: C major, bouncy patter-song style"
echo ""

# Flute - bright, playful melody with patter-song character
# Quick, articulated notes with witty rests
echo "Generating Flute (playful melody)..."
./target/release/seq --notes "C5/t160*82 D5/t160*80 E5/t160*82 G5/t320*85 E5/t160*80 C5/t160*78 R/t160 G5/t160*85 A5/t160*82 G5/t160*80 E5/t320*82 C5/t160*78 D5/t160*80 E5/t320*85 R/t160 F5/t160*80 E5/t160*78 D5/t160*80 C5/t160*78 B4/t160*75 C5/t320*82 R/t160 E5/t160*80 G5/t160*85 C6/t320*88 B5/t160*82 A5/t160*80 G5/t320*85 R/t160 C5/t160*80 D5/t160*78 E5/t160*82 G5/t320*85 E5/t160*80 C5/t160*78 R/t160 A5/t160*85 G5/t160*82 E5/t160*80 C5/t320*82 D5/t160*78 E5/t160*80 F5/t160*82 E5/t160*80 D5/t160*78 C5/t480*85" --bpm 132 --ch 0 --patch 73 > /tmp/gands-flute.jsonl

# Oboe - comic secondary line, imitative but cheeky
# Echoes the flute with slight delays and variations
echo "Generating Oboe (comic counterpoint)..."
./target/release/seq --notes "R/t320 E5/t160*72 G5/t160*75 E5/t160*72 C5/t320*75 R/t320 E5/t160*75 D5/t160*72 C5/t160*70 B4/t320*72 R/t160 C5/t160*75 E5/t160*78 G5/t320*80 R/t480 D5/t160*72 E5/t160*75 F5/t160*78 E5/t160*75 D5/t160*72 C5/t320*75 R/t320 G5/t160*78 E5/t160*75 C5/t320*78 R/t320 E5/t160*75 G5/t160*78 E5/t160*75 C5/t320*75 R/t320 F5/t160*78 E5/t160*75 D5/t160*72 C5/t160*70 B4/t160*68 C5/t320*75 E5/t160*72 C5/t480*78" --bpm 0 --ch 1 --patch 68 > /tmp/gands-oboe.jsonl

# Pizzicato Strings - bouncy rhythmic accompaniment
# Short, plucked chords on off-beats for that comic bounce
echo "Generating Pizzicato Strings (bouncy bass)..."
./target/release/seq --notes "R/t160 [C4,E4,G4]/t160*70 R/t160 [C4,E4,G4]/t160*68 R/t160 [C4,E4,G4]/t160*70 R/t160 [G3,B3,D4]/t160*68 R/t160 [C4,E4,G4]/t160*72 R/t160 [C4,E4,G4]/t160*68 R/t160 [F3,A3,C4]/t160*70 R/t160 [G3,B3,D4]/t160*72 R/t160 [C4,E4,G4]/t160*70 R/t160 [C4,E4,G4]/t160*68 R/t160 [E4,G4,C5]/t160*72 R/t160 [D4,F4,A4]/t160*70 R/t160 [C4,E4,G4]/t160*72 R/t160 [G3,B3,D4]/t160*68 R/t160 [C4,E4,G4]/t160*70 R/t160 [C4,E4,G4]/t160*68 R/t160 [C4,E4,G4]/t160*72 R/t160 [G3,B3,D4]/t160*70 R/t160 [C4,E4,G4]/t160*68 R/t160 [C4,E4,G4]/t160*72 R/t160 [F3,A3,C4]/t160*70 R/t160 [G3,B3,D4]/t160*72 R/t160 [C4,E4,G4]/t320*75" --bpm 0 --ch 2 --patch 45 > /tmp/gands-pizz.jsonl

# Bassoon - pompous comic bass, stately but silly
# Longer notes, pompous character, comic gravitas
echo "Generating Bassoon (pompous bass)..."
./target/release/seq --notes "C3/t320*78 R/t160 G3/t320*75 R/t160 C3/t320*78 E3/t160*72 G3/t320*75 R/t160 F3/t320*75 R/t160 G3/t320*78 R/t160 C3/t480*80 R/t160 E3/t160*72 G3/t160*75 C4/t320*78 R/t160 G3/t320*75 R/t160 C3/t320*78 R/t160 G3/t320*75 R/t160 C3/t320*78 E3/t160*72 G3/t320*75 R/t160 F3/t320*75 R/t160 G3/t320*78 R/t160 C3/t480*82" --bpm 0 --ch 3 --patch 70 > /tmp/gands-bassoon.jsonl

# Combine all voices
echo "Combining voices..."
cat /tmp/gands-flute.jsonl /tmp/gands-oboe.jsonl /tmp/gands-pizz.jsonl /tmp/gands-bassoon.jsonl | \
    ./target/release/viz > /tmp/gands-full.jsonl

# Convert to MIDI
echo "Converting to MIDI..."
cat /tmp/gands-full.jsonl | ./target/release/to-midi --out /tmp/demo-gands-esque.mid

# Render to WAV
echo "Rendering to WAV..."
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
fluidsynth -ni -F /tmp/gands-raw.wav "$SF2" /tmp/demo-gands-esque.mid

# Trim with fade
ffmpeg -y -i /tmp/gands-raw.wav -t 12 -af "volume=1.4,afade=t=out:st=10:d=2" examples/demo-gands-esque.wav 2>/dev/null

echo ""
echo "Created: examples/demo-gands-esque.wav"
echo "Style: C major bouncy patter-song, British operetta style"
echo ""
echo "Playing..."
afplay examples/demo-gands-esque.wav
