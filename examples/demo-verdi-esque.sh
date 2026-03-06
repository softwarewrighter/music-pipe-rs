#!/bin/bash
# =============================================================================
# Verdi-esque Italian Opera - Lyrical bel canto style
# =============================================================================
#
# Composed in the style of Giuseppe Verdi's romantic operas:
#   - G major (warm, lyrical key)
#   - Singable, flowing melodies (bel canto)
#   - Lush string accompaniment
#   - Passionate dynamic swells
#
# Instruments:
#   Ch 0: Violin - aria-like solo melody
#   Ch 1: Cello - warm singing bass
#   Ch 2: String Ensemble - harmonic support
#   Ch 3: Clarinet - woodwind color and countermelody
#
# Output: examples/demo-verdi-esque.wav

set -e
cd "$(dirname "$0")/.."

echo "=== Verdi-esque Italian Opera ==="
echo "Key: G major, lyrical bel canto style"
echo ""

# Solo Violin - aria-like melody, singable and passionate
# Long phrases, expressive intervals, operatic climaxes
echo "Generating Solo Violin (aria melody)..."
./target/release/seq --notes "G5/t480*85 A5/t240*88 B5/t480*92 A5/t240*85 G5/t240*82 F#5/t240*80 E5/t480*85 R/t240 D5/t360*82 E5/t120*80 F#5/t240*85 G5/t480*90 A5/t480*95 B5/t720*100 R/t240 A5/t240*88 G5/t240*85 F#5/t240*82 G5/t480*88 A5/t240*85 B5/t240*88 C6/t480*95 B5/t240*90 A5/t360*88 G5/t600*92 R/t240 E5/t240*80 F#5/t240*82 G5/t360*88 A5/t360*92 B5/t480*98 C6/t240*95 B5/t240*92 A5/t360*90 G5/t720*95" --bpm 72 --ch 0 --patch 40 > /tmp/verdi-violin.jsonl

# Cello - warm, singing bass line supporting the melody
# Moves in longer values, outlines the harmony
echo "Generating Cello (singing bass)..."
./target/release/seq --notes "G3/t720*78 D3/t480*75 G3/t480*78 E3/t480*75 D3/t720*78 R/t240 G3/t480*75 B3/t480*78 A3/t720*80 D3/t480*75 G3/t720*78 R/t240 E3/t480*75 F#3/t480*78 G3/t720*82 C4/t480*80 B3/t480*78 A3/t720*80 D3/t480*75 G3/t720*82" --bpm 0 --ch 1 --patch 42 > /tmp/verdi-cello.jsonl

# String Ensemble - lush sustained chords
# Provides harmonic warmth, swells with the melody
echo "Generating String Ensemble (harmonic bed)..."
./target/release/seq --notes "[G3,B3,D4]/t960*68 [D3,F#3,A3]/t720*65 [G3,B3,D4]/t720*70 [E3,G3,B3]/t720*68 [D3,F#3,A3]/t960*70 R/t240 [G3,B3,D4]/t720*68 [B3,D4,F#4]/t720*72 [A3,C4,E4]/t960*75 [D3,F#3,A3]/t720*70 [G3,B3,D4]/t960*72 R/t240 [E3,G3,B3]/t720*68 [F#3,A3,C4]/t720*70 [G3,B3,D4]/t960*75 [C4,E4,G4]/t720*78 [B3,D4,F#4]/t720*75 [A3,C4,E4]/t960*72 [D3,F#3,A3]/t720*68 [G3,B3,D4]/t960*75" --bpm 0 --ch 2 --patch 48 > /tmp/verdi-strings.jsonl

# Clarinet - gentle countermelody, fills between phrases
# Plays in the rests of the violin, adds woodwind color
echo "Generating Clarinet (woodwind color)..."
./target/release/seq --notes "R/t1200 B4/t240*65 A4/t240*62 G4/t360*68 R/t960 D5/t240*68 E5/t240*70 F#5/t360*72 R/t1440 G4/t240*65 A4/t240*68 B4/t480*72 R/t960 E5/t240*70 D5/t240*68 C5/t240*65 B4/t480*70 R/t720 D5/t360*72 E5/t240*70 D5/t600*75" --bpm 0 --ch 3 --patch 71 > /tmp/verdi-clarinet.jsonl

# Combine all voices
echo "Combining voices..."
cat /tmp/verdi-violin.jsonl /tmp/verdi-cello.jsonl /tmp/verdi-strings.jsonl /tmp/verdi-clarinet.jsonl | \
    ./target/release/viz > /tmp/verdi-full.jsonl

# Convert to MIDI
echo "Converting to MIDI..."
cat /tmp/verdi-full.jsonl | ./target/release/to-midi --out /tmp/demo-verdi-esque.mid

# Render to WAV
echo "Rendering to WAV..."
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
fluidsynth -ni -F /tmp/verdi-raw.wav "$SF2" /tmp/demo-verdi-esque.mid

# Trim with fade
ffmpeg -y -i /tmp/verdi-raw.wav -t 20 -af "volume=1.5,afade=t=out:st=18:d=2" examples/demo-verdi-esque.wav 2>/dev/null

echo ""
echo "Created: examples/demo-verdi-esque.wav"
echo "Style: G major lyrical bel canto, Italian opera style"
echo ""
echo "Playing..."
afplay examples/demo-verdi-esque.wav
