#!/bin/bash
# =============================================================================
# Bach-esque Organ Music - Toccata and Fugue style
# =============================================================================
#
# Composed in the style of J.S. Bach's organ works, featuring:
#   - D minor (Bach's dramatic key)
#   - Fugal counterpoint with subject and answer
#   - Pedal bass supporting the harmony
#   - Baroque ornamentation and sequences
#
# Instruments:
#   Ch 0: Church Organ - Upper manual (subject/melody)
#   Ch 1: Church Organ - Lower manual (countersubject)
#   Ch 2: Church Organ - Pedal (bass foundation)
#
# Output: examples/demo-bach-esque.wav

set -e
cd "$(dirname "$0")/.."

echo "=== Bach-esque Organ Music ==="
echo "Key: D minor, Toccata and Fugue style"
echo ""

# Upper manual - fugue subject with baroque flourishes
# Classic Bach pattern: scalar runs, sequences, dramatic pauses
echo "Generating upper voice (fugue subject)..."
./target/release/seq --notes "D5/t240*95 C#5/t120*85 D5/t120*90 E5/t240*92 F5/t360*95 E5/t120*85 D5/t120*88 C#5/t120*85 D5/t480*98 R/t240 A4/t120*88 B4/t120*85 C#5/t120*88 D5/t120*90 E5/t120*88 F5/t120*90 G5/t120*92 A5/t360*95 G5/t120*88 F5/t120*85 E5/t120*88 D5/t240*92 R/t120 D5/t120*90 E5/t120*88 F5/t240*92 G5/t240*90 A5/t480*95 R/t240 G5/t120*85 F5/t120*82 E5/t120*85 D5/t120*88 C#5/t120*85 D5/t120*88 E5/t120*90 F5/t360*95 E5/t120*85 D5/t240*92 C#5/t240*88 D5/t720*100" --bpm 120 --ch 0 --patch 19 > /tmp/bach-upper.jsonl

# Lower manual - countersubject (enters after subject, imitative)
# Starts on A (the answer in fugue tradition), mirrors the subject
echo "Generating lower voice (countersubject)..."
./target/release/seq --notes "R/t960 A4/t240*88 G#4/t120*78 A4/t120*82 B4/t240*85 C5/t360*88 B4/t120*78 A4/t120*80 G#4/t120*78 A4/t480*90 R/t240 E4/t120*80 F4/t120*78 G4/t120*80 A4/t120*82 B4/t120*80 C5/t120*82 D5/t120*85 E5/t360*88 D5/t120*80 C5/t120*78 B4/t120*80 A4/t240*85 R/t120 A4/t120*82 B4/t120*80 C5/t240*85 D5/t240*82 E5/t480*88 R/t240 D5/t120*78 C5/t120*75 B4/t120*78 A4/t120*80 G#4/t120*78 A4/t120*80 B4/t120*82 C5/t360*88 B4/t120*78 A4/t240*85 G#4/t240*80 A4/t720*92" --bpm 0 --ch 1 --patch 19 > /tmp/bach-lower.jsonl

# Pedal bass - foundational, slower, emphasizes harmonic rhythm
# Moves in half notes and whole notes, outlines D minor progression
echo "Generating pedal bass..."
./target/release/seq --notes "D2/t720*85 A2/t480*80 D2/t480*85 F2/t480*82 A2/t720*85 D3/t480*88 A2/t480*82 D2/t720*85 G2/t480*80 C3/t480*78 F2/t720*82 Bb2/t480*78 A2/t720*85 D2/t480*82 G2/t480*80 A2/t720*88 D2/t960*92" --bpm 0 --ch 2 --patch 19 > /tmp/bach-pedal.jsonl

# Combine all voices
echo "Combining voices..."
cat /tmp/bach-upper.jsonl /tmp/bach-lower.jsonl /tmp/bach-pedal.jsonl | \
    ./target/release/viz > /tmp/bach-full.jsonl

# Convert to MIDI
echo "Converting to MIDI..."
cat /tmp/bach-full.jsonl | ./target/release/to-midi --out /tmp/demo-bach-esque.mid

# Render to WAV
echo "Rendering to WAV..."
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
fluidsynth -ni -F /tmp/bach-raw.wav "$SF2" /tmp/demo-bach-esque.mid

# Trim with fade
ffmpeg -y -i /tmp/bach-raw.wav -t 18 -af "volume=1.3,afade=t=out:st=16:d=2" examples/demo-bach-esque.wav 2>/dev/null

echo ""
echo "Created: examples/demo-bach-esque.wav"
echo "Style: D minor fugue, Toccata and Fugue style"
echo ""
echo "Playing..."
afplay examples/demo-bach-esque.wav
