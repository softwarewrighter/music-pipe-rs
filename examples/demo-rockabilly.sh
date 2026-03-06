#!/bin/bash
# =============================================================================
# Rockabilly Demo - 1950s rock and roll meets country twang
# =============================================================================
#
# Classic rockabilly style inspired by Carl Perkins, Eddie Cochran, and
# early Elvis recordings. Features the distinctive shuffle rhythm and
# walking bass patterns of the genre.
#
# Instruments:
#   Ch 0: Acoustic Piano - boogie-woogie left hand
#   Ch 1: Clean Guitar - rhythm chops
#   Ch 2: Steel Guitar - twangy fills
#   Ch 7: Acoustic Bass - walking/slap pattern
#   Ch 9: Drums - shuffle with backbeat
#
# Key: E major (classic rockabilly key)
# Tempo: 160 BPM with shuffle feel
#
# Output: examples/gend-rockabilly.wav (14 seconds)

set -e
cd "$(dirname "$0")/.."

echo "=== Rockabilly Generator ==="
echo "Key: E major, 160 BPM shuffle"
echo ""

# All parts are composed to work together in E major
# Using ticks for precise shuffle timing (swing = long-short pattern)
# Quarter note = 480 ticks, swing eighth = 320+160

# Piano - boogie-woogie bass pattern (left hand walking octaves)
# Classic boogie pattern: root-fifth-sixth-fifth
echo "Generating: Piano (boogie-woogie)..."
./target/release/seq --notes "E2/t160*85 E3/t160*75 G#2/t160*85 E3/t160*75 A2/t160*85 E3/t160*75 G#2/t160*85 E3/t160*75 E2/t160*85 E3/t160*75 G#2/t160*85 E3/t160*75 A2/t160*85 E3/t160*75 B2/t160*85 E3/t160*75 A2/t160*85 A3/t160*75 C#3/t160*85 A3/t160*75 D3/t160*85 A3/t160*75 C#3/t160*85 A3/t160*75 E2/t160*85 E3/t160*75 G#2/t160*85 E3/t160*75 B2/t160*85 E3/t160*75 G#2/t160*85 E3/t160*75 E2/t160*85 E3/t160*75 G#2/t160*85 E3/t160*75 A2/t160*85 E3/t160*75 G#2/t160*85 E3/t160*75 E2/t160*85 E3/t160*75 G#2/t160*85 E3/t160*75 A2/t160*85 E3/t160*75 B2/t160*85 E3/t160*75 A2/t160*85 A3/t160*75 C#3/t160*85 A3/t160*75 D3/t160*85 A3/t160*75 C#3/t160*85 A3/t160*75 B2/t160*90 B3/t160*80 D#3/t160*90 B3/t160*80 E3/t320*95 R/t160 E2/t480*100" --bpm 160 --ch 0 --patch 0 > /tmp/rockabilly-piano.jsonl

# Rhythm Guitar - chunky shuffle chords on upbeats
echo "Generating: Clean Guitar (rhythm chops)..."
./target/release/seq --notes "R/t320 [E4,G#4,B4]/t160*70 R/t320 [E4,G#4,B4]/t160*72 R/t320 [E4,G#4,B4]/t160*68 R/t320 [E4,G#4,B4]/t160*70 R/t320 [E4,G#4,B4]/t160*72 R/t320 [E4,G#4,B4]/t160*70 R/t320 [E4,G#4,B4]/t160*68 R/t320 [E4,G#4,B4]/t160*72 R/t320 [A4,C#5,E5]/t160*70 R/t320 [A4,C#5,E5]/t160*72 R/t320 [A4,C#5,E5]/t160*68 R/t320 [A4,C#5,E5]/t160*70 R/t320 [E4,G#4,B4]/t160*72 R/t320 [E4,G#4,B4]/t160*70 R/t320 [B4,D#5,F#5]/t160*74 R/t320 [E4,G#4,B4]/t160*72 R/t320 [E4,G#4,B4]/t160*70 R/t320 [E4,G#4,B4]/t160*72 R/t320 [E4,G#4,B4]/t160*68 R/t320 [E4,G#4,B4]/t160*70 R/t320 [E4,G#4,B4]/t160*72 R/t320 [E4,G#4,B4]/t160*70 R/t320 [E4,G#4,B4]/t160*68 R/t320 [E4,G#4,B4]/t160*72 R/t320 [A4,C#5,E5]/t160*70 R/t320 [A4,C#5,E5]/t160*72 R/t320 [A4,C#5,E5]/t160*68 R/t320 [A4,C#5,E5]/t160*70 R/t320 [B4,D#5,F#5]/t160*75 R/t320 [B4,D#5,F#5]/t160*78 R/t320 [E4,G#4,B4]/t240*80 R/t240" --bpm 0 --ch 1 --patch 27 > /tmp/rockabilly-rhythm.jsonl

# Steel Guitar - melodic fills between phrases (sparse, twangy)
echo "Generating: Steel Guitar (twang lead)..."
./target/release/seq --notes "R/t1920 B4/t240*65 G#4/t160*60 E4/t320*68 R/t1280 E5/t160*70 D#5/t160*65 C#5/t160*62 B4/t320*68 R/t1440 G#4/t240*65 A4/t160*62 B4/t480*70 R/t960 E5/t320*72 D#5/t160*68 B4/t240*65 G#4/t480*70 R/t640 B4/t160*68 C#5/t160*65 D#5/t160*68 E5/t480*75 R/t320 B4/t320*70 G#4/t320*68 E4/t480*72" --bpm 0 --ch 2 --patch 25 > /tmp/rockabilly-lead.jsonl

# Walking Bass - classic rockabilly slap pattern (root-root-fifth-approach)
echo "Generating: Acoustic Bass (walking)..."
./target/release/seq --notes "E2/t320*90 E2/t160*85 B2/t320*88 D#2/t160*82 E2/t320*90 E2/t160*85 G#2/t320*88 A2/t160*82 E2/t320*90 E2/t160*85 B2/t320*88 D#2/t160*82 E2/t320*90 G#2/t160*85 A2/t320*88 B2/t160*85 A2/t320*90 A2/t160*85 E3/t320*88 G#2/t160*82 A2/t320*90 A2/t160*85 C#3/t320*88 E2/t160*82 E2/t320*90 E2/t160*85 B2/t320*88 G#2/t160*82 B2/t320*92 B2/t160*88 F#2/t320*90 A2/t160*85 E2/t320*90 E2/t160*85 B2/t320*88 D#2/t160*82 E2/t320*90 E2/t160*85 G#2/t320*88 A2/t160*82 E2/t320*90 E2/t160*85 B2/t320*88 D#2/t160*82 E2/t320*90 G#2/t160*85 A2/t320*88 B2/t160*85 A2/t320*90 A2/t160*85 E3/t320*88 G#2/t160*82 A2/t320*90 C#3/t160*85 D3/t160*82 D#3/t160*85 B2/t320*95 B2/t160*90 F#2/t320*92 B2/t160*88 E2/t640*100" --bpm 0 --ch 7 --patch 32 > /tmp/rockabilly-bass.jsonl

# Drums - shuffle pattern with strong backbeat
# C2=kick, D2=snare, F#2=closed hi-hat, A#2=open hi-hat, C#3=crash
echo "Generating: Drums (shuffle)..."
./target/release/seq --notes "C2/t160*95 F#2/t160*60 F#2/t160*55 D2/t160*90 F#2/t160*60 F#2/t160*55 C2/t160*92 F#2/t160*58 F#2/t160*55 D2/t160*88 F#2/t160*60 A#2/t160*65 C2/t160*95 F#2/t160*60 F#2/t160*55 D2/t160*90 F#2/t160*60 F#2/t160*55 C2/t160*92 F#2/t160*58 F#2/t160*55 D2/t160*88 F#2/t160*60 A#2/t160*65 C2/t160*95 F#2/t160*60 F#2/t160*55 D2/t160*90 F#2/t160*60 F#2/t160*55 C2/t160*92 F#2/t160*58 F#2/t160*55 D2/t160*88 F#2/t160*60 A#2/t160*65 C2/t160*95 F#2/t160*60 F#2/t160*55 D2/t160*90 F#2/t160*60 F#2/t160*55 C2/t160*92 F#2/t160*58 F#2/t160*55 D2/t160*92 F#2/t160*62 D2/t160*70 C2/t160*95 F#2/t160*60 F#2/t160*55 D2/t160*90 F#2/t160*60 F#2/t160*55 C2/t160*92 F#2/t160*58 F#2/t160*55 D2/t160*88 F#2/t160*60 A#2/t160*65 C2/t160*95 F#2/t160*60 F#2/t160*55 D2/t160*90 F#2/t160*60 F#2/t160*55 C2/t160*92 F#2/t160*58 F#2/t160*55 D2/t160*88 F#2/t160*60 A#2/t160*65 C2/t160*95 F#2/t160*60 F#2/t160*55 D2/t160*90 F#2/t160*60 F#2/t160*55 C2/t160*92 F#2/t160*58 F#2/t160*55 D2/t160*88 F#2/t160*60 A#2/t160*65 C2/t160*98 F#2/t160*65 D2/t160*75 D2/t160*95 C2/t160*90 D2/t160*70 C2/t320*100 R/t160 C#3/t320*80" --bpm 0 --ch 9 --patch 0 > /tmp/rockabilly-drums.jsonl

# Combine all tracks
echo "Combining tracks..."
cat /tmp/rockabilly-piano.jsonl \
    /tmp/rockabilly-rhythm.jsonl \
    /tmp/rockabilly-lead.jsonl \
    /tmp/rockabilly-bass.jsonl \
    /tmp/rockabilly-drums.jsonl | \
    ./target/release/viz > /tmp/rockabilly-full.jsonl

# Convert to MIDI
echo "Converting to MIDI..."
cat /tmp/rockabilly-full.jsonl | ./target/release/to-midi --out /tmp/rockabilly.mid

# Render with FluidSynth
echo "Rendering to WAV..."
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
fluidsynth -ni -F /tmp/rockabilly-raw.wav "$SF2" /tmp/rockabilly.mid

# Trim to 14 seconds with fade out
ffmpeg -y -i /tmp/rockabilly-raw.wav -t 14 -af "volume=1.5,afade=t=out:st=12:d=2" examples/gend-rockabilly.wav 2>/dev/null

echo ""
echo "Created: examples/gend-rockabilly.wav (14 seconds)"
echo "Style: E major rockabilly shuffle at 160 BPM"
echo ""
echo "Playing..."
afplay examples/gend-rockabilly.wav
