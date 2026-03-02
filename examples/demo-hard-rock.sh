#!/bin/bash
# =============================================================================
# Hard Rock - Arensky String Quartet No. 2 Theme Inverted & Reversed
# =============================================================================
#
# SOURCE: Anton Arensky - String Quartet No. 2 in A minor, Op. 35 (1894)
#         Arensky (1861-1906) was a contemporary of Tchaikovsky but far more
#         obscure today. His String Quartet No. 2 features a melancholic Russian
#         theme with four distinct voices that interweave contrapuntally.
#
# ORIGINAL QUARTET VOICES (opening 4 bars, A minor):
#   Violin 1:  A4-B4-C5-D5 | E5-D5-C5-B4 | A4-G#4-A4-B4 | C5-D5-E5-A5
#   Violin 2:  E4-F4-G4-A4 | B4-A4-G4-F4 | E4-D#4-E4-F4 | G4-A4-B4-E5
#   Viola:     C4-D4-E4-F4 | G4-F4-E4-D4 | C4-B3-C4-D4 | E4-F4-G4-C5
#   Cello:     A2-A2-A2-A2 | E3-E3-E3-E3 | A2-A2-A2-A2 | A2-B2-C3-A3
#
# TRANSFORMATION:
#   1. INVERTED around A4 (MIDI 69): each pitch mirrored
#   2. REVERSED: sequences played backwards
#   3. Rock adaptation: Violin 1→Lead, Violin 2→Rhythm melody, Cello→Bass
#
# COPYRIGHT: Arensky died in 1906, public domain for 115+ years.
#            This is a transformative arrangement.
#
# Instruments:
#   Ch 0: Distortion Guitar (lead) - patch 30 - Violin 1 inverted/reversed
#   Ch 1: Overdriven Guitar (rhythm) - patch 29 - Violin 2 inverted/reversed
#   Ch 2: Electric Bass (picked) - patch 34 - Cello inverted/reversed
#   Ch 9: Drums (heavy rock kit)
#
# Style: 150 BPM, power chords, aggressive dynamics

set -e
cd "$(dirname "$0")/.."

# Lead Guitar - Violin 1 inverted around A4 and reversed (3 repetitions + variation)
# Original: A4-B4-C5-D5-E5-D5-C5-B4-A4-G#4-A4-B4-C5-D5-E5-A5
# Inverted: A4-G4-F4-E4-D4-E4-F4-G4-A4-A#4-A4-G4-F4-E4-D4-A3
# Reversed: A3-D4-E4-F4-G4-A4-A#4-A4-G4-F4-E4-D4-E4-F4-G4-A4
./target/release/seq --notes "A3/t60*115 D4/t60*118 E4/t60*120 F4/t60*122 G4/t60*125 A4/t120*127 A#4/t60*125 A4/t60*127 G4/t60*125 F4/t60*122 E4/t60*120 D4/t120*118 R/t60 E4/t60*120 F4/t60*122 G4/t60*125 A4/t180*127 R/t120 A3/t60*115 D4/t60*118 E4/t60*120 F4/t60*122 G4/t60*125 A4/t120*127 A#4/t60*125 A4/t60*127 G4/t60*125 F4/t60*122 E4/t60*120 D4/t120*118 R/t60 E4/t60*120 F4/t60*122 G4/t60*125 A4/t180*127 R/t240 A5/t60*127 G5/t60*125 F5/t60*122 E5/t60*120 D5/t120*118 E5/t60*120 F5/t60*122 G5/t60*125 A5/t240*127 R/t120 A#5/t60*127 A5/t60*125 G5/t60*122 F5/t60*120 E5/t120*118 D5/t180*115 R/t240 A3/t60*115 D4/t60*118 E4/t60*120 F4/t60*122 G4/t60*125 A4/t120*127 A#4/t60*125 A4/t60*127 G4/t60*125 F4/t60*122 E4/t60*120 D4/t120*118 R/t60 E4/t60*120 F4/t60*122 G4/t60*125 A4/t180*127 R/t120 A3/t60*115 D4/t60*118 E4/t60*120 F4/t60*122 G4/t60*125 A4/t120*127 A#4/t60*125 A4/t60*127 G4/t60*125 F4/t60*122 E4/t60*120 D4/t120*118 R/t60 E4/t60*120 F4/t60*122 G4/t60*125 A4/t180*127 R/t240 A5/t60*127 G5/t60*125 F5/t60*122 E5/t60*120 D5/t120*118 E5/t60*120 F5/t60*122 G5/t60*125 A5/t240*127 R/t120 A#5/t60*127 A5/t60*125 G5/t60*122 F5/t60*120 E5/t120*118 D5/t180*115 R/t240 A5/t120*127 G5/t60*125 F5/t60*122 E5/t60*120 D5/t60*118 C5/t60*120 D5/t60*122 E5/t120*125 F5/t60*127 G5/t60*125 A5/t180*127 R/t120 A3/t60*115 D4/t60*118 E4/t60*120 F4/t60*122 G4/t60*125 A4/t120*127 A#4/t60*125 A4/t60*127 G4/t60*125 F4/t60*122 E4/t60*120 D4/t120*118 R/t60 E4/t60*120 F4/t60*122 G4/t60*125 A4/t180*127 R/t120 A5/t60*127 G5/t60*125 F5/t60*122 E5/t60*120 D5/t120*118 E5/t60*120 F5/t60*122 G5/t60*125 A5/t240*127 R/t120 A#5/t60*127 A5/t60*125 G5/t60*122 F5/t60*120 E5/t120*118 D5/t180*115 R/t240 A5/t120*127 G5/t60*125 F5/t60*122 E5/t60*120 D5/t60*118 C5/t60*120 D5/t60*122 E5/t120*125 F5/t60*127 G5/t60*125 A5/t180*127 R/t120 A3/t60*115 D4/t60*118 E4/t60*120 F4/t60*122 G4/t60*125 A4/t120*127 A#4/t60*125 A4/t60*127 G4/t60*125 F4/t60*122 E4/t60*120 D4/t120*118 R/t60 E4/t60*120 F4/t60*122 G4/t60*125 A4/t180*127 R/t120 A5/t60*127 G5/t60*125 F5/t60*122 E5/t60*120 D5/t120*118 E5/t60*120 F5/t60*122 G5/t60*125 A5/t240*127 R/t120 A#5/t60*127 A5/t60*125 G5/t60*122 F5/t60*120 E5/t60*118 D5/t60*120 E5/t60*122 F5/t60*125 G5/t60*127 A5/t720*127" --bpm 150 --ch 0 --patch 30 > /tmp/hard-rock-lead.jsonl

# Rhythm Guitar - Violin 2 inverted/reversed as funky syncopated power chords
# Original: E4-F4-G4-A4-B4-A4-G4-F4-E4-D#4-E4-F4-G4-A4-B4-E5
# Inverted around A4: D5-C5-Bb4-A4-G4-A4-Bb4-C5-D5-D#5-D5-C5-Bb4-A4-G4-D4
# Reversed as syncopated power chords with funk scratches (R for muted hits)
./target/release/seq --notes "[D3,A3,D4]/t90*110 R/t30 [D3,A3,D4]/t30*80 R/t30 [G3,D4,G4]/t60*108 R/t30 [A3,E4,A4]/t60*110 R/t30 [A#3,F4,A#4]/t90*115 R/t30 [A#3,F4,A#4]/t30*85 R/t60 [C4,G4,C5]/t90*118 R/t30 [C4,G4,C5]/t30*88 R/t30 [D4,A4,D5]/t60*112 R/t30 [D#4,A#4,D#5]/t90*120 R/t30 [D4,A4,D5]/t90*118 R/t30 [D4,A4,D5]/t30*90 R/t30 [C4,G4,C5]/t60*115 R/t30 [A#3,F4,A#4]/t60*112 R/t30 [A3,E4,A4]/t90*110 R/t30 [A3,E4,A4]/t30*85 R/t60 [G3,D4,G4]/t90*112 R/t30 [A3,E4,A4]/t60*108 R/t30 [A#3,F4,A#4]/t90*115 R/t30 [C4,G4,C5]/t90*118 R/t30 [D4,A4,D5]/t180*122 R/t60 [D3,A3,D4]/t90*110 R/t30 [D3,A3,D4]/t30*80 R/t30 [G3,D4,G4]/t60*108 R/t30 [A3,E4,A4]/t60*110 R/t30 [A#3,F4,A#4]/t90*115 R/t30 [A#3,F4,A#4]/t30*85 R/t60 [C4,G4,C5]/t90*118 R/t30 [C4,G4,C5]/t30*88 R/t30 [D4,A4,D5]/t60*112 R/t30 [D#4,A#4,D#5]/t90*120 R/t30 [D4,A4,D5]/t90*118 R/t30 [D4,A4,D5]/t30*90 R/t30 [C4,G4,C5]/t60*115 R/t30 [A#3,F4,A#4]/t60*112 R/t30 [A3,E4,A4]/t90*110 R/t30 [A3,E4,A4]/t30*85 R/t60 [G3,D4,G4]/t90*112 R/t30 [A3,E4,A4]/t60*108 R/t30 [A#3,F4,A#4]/t90*115 R/t30 [C4,G4,C5]/t90*118 R/t30 [D4,A4,D5]/t180*122 R/t60 [D3,A3,D4]/t90*110 R/t30 [D3,A3,D4]/t30*80 R/t30 [G3,D4,G4]/t60*108 R/t30 [A3,E4,A4]/t60*110 R/t30 [A#3,F4,A#4]/t90*115 R/t30 [A#3,F4,A#4]/t30*85 R/t60 [C4,G4,C5]/t90*118 R/t30 [C4,G4,C5]/t30*88 R/t30 [D4,A4,D5]/t60*112 R/t30 [D#4,A#4,D#5]/t90*120 R/t30 [D4,A4,D5]/t90*118 R/t30 [D4,A4,D5]/t30*90 R/t30 [C4,G4,C5]/t60*115 R/t30 [A#3,F4,A#4]/t60*112 R/t30 [A3,E4,A4]/t90*110 R/t30 [A3,E4,A4]/t30*85 R/t60 [G3,D4,G4]/t90*112 R/t30 [A3,E4,A4]/t60*108 R/t30 [A#3,F4,A#4]/t90*115 R/t30 [C4,G4,C5]/t90*118 R/t30 [D4,A4,D5]/t180*122 R/t60 [D3,A3,D4]/t90*110 R/t30 [D3,A3,D4]/t30*80 R/t30 [G3,D4,G4]/t60*108 R/t30 [A3,E4,A4]/t60*110 R/t30 [A#3,F4,A#4]/t90*115 R/t30 [A#3,F4,A#4]/t30*85 R/t60 [C4,G4,C5]/t90*118 R/t30 [C4,G4,C5]/t30*88 R/t30 [D4,A4,D5]/t60*112 R/t30 [D#4,A#4,D#5]/t90*120 R/t30 [D4,A4,D5]/t180*122 R/t60 [D3,A3,D4]/t90*110 R/t30 [D3,A3,D4]/t30*80 R/t30 [G3,D4,G4]/t60*108 R/t30 [A3,E4,A4]/t60*110 R/t30 [A#3,F4,A#4]/t90*115 R/t30 [A#3,F4,A#4]/t30*85 R/t60 [C4,G4,C5]/t90*118 R/t30 [C4,G4,C5]/t30*88 R/t30 [D4,A4,D5]/t60*112 R/t30 [D#4,A#4,D#5]/t90*120 R/t30 [D4,A4,D5]/t90*118 R/t30 [D4,A4,D5]/t30*90 R/t30 [C4,G4,C5]/t60*115 R/t30 [A#3,F4,A#4]/t60*112 R/t30 [A3,E4,A4]/t90*110 R/t30 [D4,A4,D5]/t720*127" --bpm 0 --ch 1 --patch 29 > /tmp/hard-rock-rhythm.jsonl

# Bass - Cello inverted/reversed with FUNKY slap-style syncopation
# Original: A2-A2-A2-A2-E3-E3-E3-E3-A2-A2-A2-A2-A2-B2-C3-A3
# Inverted: A3-A3-A3-A3-D3-D3-D3-D3-A3-A3-A3-A3-A3-G3-F3-A2
# Reversed with funk: A2-F2-G2-A2 with 16th note ghost notes and syncopation
./target/release/seq --notes "A2/t60*120 R/t30 A2/t30*70 R/t30 F2/t60*115 R/t30 F2/t30*65 G2/t60*118 R/t30 A2/t90*122 R/t30 A2/t30*72 R/t30 A2/t60*118 R/t30 A2/t30*68 A2/t60*120 R/t30 D2/t60*115 R/t30 D2/t30*65 D2/t60*118 R/t30 D2/t90*120 R/t30 D2/t30*70 R/t60 A2/t60*118 R/t30 A2/t30*68 A2/t60*120 R/t30 A2/t90*122 R/t60 A2/t60*120 R/t30 A2/t30*70 R/t30 F2/t60*115 R/t30 F2/t30*65 G2/t60*118 R/t30 A2/t90*122 R/t30 A2/t30*72 R/t30 A2/t60*118 R/t30 A2/t30*68 A2/t60*120 R/t30 D2/t60*115 R/t30 D2/t30*65 D2/t60*118 R/t30 D2/t90*120 R/t30 D2/t30*70 R/t60 A2/t60*118 R/t30 A2/t30*68 A2/t60*120 R/t30 A2/t90*122 R/t60 A2/t60*120 R/t30 A2/t30*70 R/t30 F2/t60*115 R/t30 F2/t30*65 G2/t60*118 R/t30 A2/t90*122 R/t30 A2/t30*72 R/t30 A2/t60*118 R/t30 A2/t30*68 A2/t60*120 R/t30 D2/t60*115 R/t30 D2/t30*65 D2/t60*118 R/t30 D2/t90*120 R/t30 D2/t30*70 R/t60 A2/t60*118 R/t30 A2/t30*68 A2/t60*120 R/t30 A2/t90*122 R/t60 A2/t60*120 R/t30 A2/t30*70 R/t30 F2/t60*115 R/t30 F2/t30*65 G2/t60*118 R/t30 A2/t90*122 R/t30 A2/t30*72 R/t30 A2/t60*118 R/t30 A2/t30*68 A2/t60*120 R/t30 D2/t60*115 R/t30 D2/t30*65 D2/t60*118 R/t30 D2/t90*120 R/t30 D2/t30*70 R/t60 A2/t60*120 R/t30 A2/t30*70 R/t30 F2/t60*115 R/t30 F2/t30*65 G2/t60*118 R/t30 A2/t90*122 R/t30 A2/t30*72 R/t30 A2/t60*118 R/t30 A2/t30*68 A2/t60*120 R/t30 D2/t60*115 R/t30 D2/t30*65 D2/t60*118 R/t30 D2/t90*120 R/t30 D2/t30*70 R/t60 A2/t720*127" --bpm 0 --ch 2 --patch 34 > /tmp/hard-rock-bass.jsonl

# Heavy Drums - driving beat with funk syncopation and crashes
# C2=kick(36), D2=snare(38), F#2=hihat(42), A#2=open-hat(46), C#3=crash(49)
# Funk pattern: syncopated kick, ghost notes on snare, 16th hi-hat
./target/release/seq --notes "C#3/t30*127 C2/t30*120 F#2/t30*90 F#2/t30*70 C2/t30*100 F#2/t30*85 D2/t30*75 F#2/t30*90 D2/t30*120 F#2/t30*85 F#2/t30*70 C2/t30*115 F#2/t30*90 F#2/t30*75 D2/t30*80 F#2/t30*90 C2/t30*118 F#2/t30*85 F#2/t30*70 C2/t30*110 F#2/t30*90 D2/t30*75 F#2/t30*85 D2/t30*122 F#2/t30*90 A#2/t30*95 C2/t30*115 F#2/t30*85 F#2/t30*70 D2/t30*78 F#2/t30*90 C2/t30*120 F#2/t30*90 F#2/t30*70 C2/t30*100 F#2/t30*85 D2/t30*75 F#2/t30*90 D2/t30*120 F#2/t30*85 F#2/t30*70 C2/t30*115 F#2/t30*90 F#2/t30*75 D2/t30*80 F#2/t30*90 C2/t30*118 F#2/t30*85 F#2/t30*70 C2/t30*110 F#2/t30*90 D2/t30*75 F#2/t30*85 D2/t30*122 C#3/t60*127 C2/t30*120 F#2/t30*90 F#2/t30*70 C2/t30*100 F#2/t30*85 D2/t30*75 F#2/t30*90 D2/t30*120 F#2/t30*85 F#2/t30*70 C2/t30*115 F#2/t30*90 F#2/t30*75 D2/t30*80 F#2/t30*90 C2/t30*118 F#2/t30*85 F#2/t30*70 C2/t30*110 F#2/t30*90 D2/t30*75 F#2/t30*85 D2/t30*122 F#2/t30*90 A#2/t30*95 C2/t30*115 F#2/t30*85 F#2/t30*70 D2/t30*78 F#2/t30*90 C2/t30*120 F#2/t30*90 F#2/t30*70 C2/t30*100 F#2/t30*85 D2/t30*75 F#2/t30*90 D2/t30*120 F#2/t30*85 F#2/t30*70 C2/t30*115 F#2/t30*90 F#2/t30*75 D2/t30*80 F#2/t30*90 C2/t30*118 F#2/t30*85 F#2/t30*70 C2/t30*110 F#2/t30*90 D2/t30*75 F#2/t30*85 D2/t30*122 C#3/t60*127 C2/t30*120 F#2/t30*90 F#2/t30*70 C2/t30*100 F#2/t30*85 D2/t30*75 F#2/t30*90 D2/t30*120 F#2/t30*85 F#2/t30*70 C2/t30*115 F#2/t30*90 F#2/t30*75 D2/t30*80 F#2/t30*90 C2/t30*118 F#2/t30*85 F#2/t30*70 C2/t30*110 F#2/t30*90 D2/t30*75 F#2/t30*85 D2/t30*122 F#2/t30*90 A#2/t30*95 C2/t30*115 F#2/t30*85 F#2/t30*70 D2/t30*78 F#2/t30*90 C2/t30*120 F#2/t30*90 F#2/t30*70 C2/t30*100 F#2/t30*85 D2/t30*75 F#2/t30*90 D2/t30*120 F#2/t30*85 F#2/t30*70 C2/t30*115 F#2/t30*90 F#2/t30*75 D2/t30*80 F#2/t30*90 C2/t30*118 F#2/t30*85 F#2/t30*70 C2/t30*110 F#2/t30*90 D2/t30*75 F#2/t30*85 D2/t30*125 C#3/t60*127 C2/t30*120 F#2/t30*90 F#2/t30*70 C2/t30*100 F#2/t30*85 D2/t30*75 F#2/t30*90 D2/t30*120 F#2/t30*85 F#2/t30*70 C2/t30*115 F#2/t30*90 F#2/t30*75 D2/t30*80 F#2/t30*90 C2/t30*118 F#2/t30*85 F#2/t30*70 C2/t30*110 F#2/t30*90 D2/t30*75 F#2/t30*85 D2/t30*122 F#2/t30*90 A#2/t30*95 C2/t30*115 F#2/t30*85 F#2/t30*70 D2/t30*78 F#2/t30*90 C2/t30*120 F#2/t30*90 F#2/t30*70 C2/t30*100 F#2/t30*85 D2/t30*75 F#2/t30*90 D2/t30*120 F#2/t30*85 F#2/t30*70 C2/t30*115 F#2/t30*90 F#2/t30*75 D2/t30*125 C#3/t120*127" --bpm 0 --ch 9 --patch 0 > /tmp/hard-rock-drums.jsonl

# Merge and create MIDI
cat /tmp/hard-rock-lead.jsonl /tmp/hard-rock-rhythm.jsonl /tmp/hard-rock-bass.jsonl /tmp/hard-rock-drums.jsonl | \
    ./target/release/viz | \
    ./target/release/to-midi --out /tmp/hard-rock.mid

# Render with FluidSynth
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
fluidsynth -ni -F /tmp/hard-rock-raw.wav "$SF2" /tmp/hard-rock.mid

# Pad to 20 seconds with fade out, boost volume for impact
ffmpeg -y -i /tmp/hard-rock-raw.wav -af "volume=2.0,apad=whole_dur=20,afade=t=out:st=18:d=2" -t 20 examples/demo-hard-rock.wav

echo "Created: examples/demo-hard-rock.wav (20 seconds)"
echo "Style: Hard Rock - Bach Toccata inverted and reversed"
