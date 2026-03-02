#!/bin/bash
# =============================================================================
# Soft Progressive Rock - inspired by Erik Satie's Gnossiennes (1890)
# =============================================================================
#
# SOURCE: Erik Satie - Gnossiennes (composed 1890-1897)
#         Satie (1866-1925) was a contemporary of Claude Debussy, but far more
#         obscure in his time. His Gnossiennes are modal, free-flowing pieces
#         without bar lines or time signatures - revolutionary for 1890.
#
# ADAPTATION: This piece reimagines Satie's modal harmonies and suspended
#             dreamlike atmosphere as soft progressive rock:
#             - D Dorian mode (Satie's favorite mode)
#             - Syncopated rhythms (the "progressive" element)
#             - Modern rock instrumentation with soft dynamics
#             - Slow tempo (60 BPM) preserving the contemplative feel
#
# COPYRIGHT: Satie died in 1925, so his work entered public domain in 1995.
#            This arrangement is an original interpretation.
#
# Instruments:
#   Ch 0: Electric Piano (Rhodes) - patch 4
#   Ch 1: Clean Electric Guitar - patch 27
#   Ch 2: Fretless Bass - patch 35
#   Ch 9: Drums (soft kit)
#
# Style: D Dorian mode, 60 BPM, syncopated rhythms, progressive structure

set -e
cd "$(dirname "$0")/.."

# Electric Piano - dreamy chords with Satie-like suspensions (D Dorian)
# Syncopated hits on off-beats for prog feel
./target/release/seq --notes "R/t60 [D3,A3,E4]/t420*70 R/t240 [D3,A3,F4]/t180*65 R/t60 [E3,B3,G4]/t480*72 R/t240 [F3,C4,A4]/t420*68 R/t60 [D3,A3,E4]/t240*70 R/t120 [E3,G3,D4]/t360*65 R/t120 [D3,A3,F4]/t480*72 R/t240 [C3,G3,E4]/t420*68 R/t60 [D3,A3,D4]/t600*75" --bpm 60 --ch 0 --patch 4 > /tmp/soft-prog-piano.jsonl

# Clean Guitar - melodic fills with gentle bends implied by velocity
./target/release/seq --notes "R/t480 A4/t360*55 R/t120 G4/t120*50 F4/t120*52 E4/t480*58 R/t240 D4/t240*55 E4/t120*52 F4/t240*54 R/t120 G4/t360*56 R/t240 A4/t480*60 R/t120 G4/t180*55 E4/t180*52 D4/t600*58" --bpm 0 --ch 1 --patch 27 > /tmp/soft-prog-guitar.jsonl

# Fretless Bass - smooth, sustained notes with slight syncopation
./target/release/seq --notes "D2/t420*75 R/t60 A2/t240*70 R/t240 D2/t480*78 R/t120 E2/t360*72 R/t120 F2/t480*75 R/t120 D2/t360*78 R/t120 E2/t240*72 R/t120 C2/t420*75 R/t60 D2/t720*80" --bpm 0 --ch 2 --patch 35 > /tmp/soft-prog-bass.jsonl

# Soft Drums - brushed feel, syncopated hi-hat, gentle kick/snare
# C2=kick, D2=snare, F#2=closed hi-hat, A#2=open hi-hat, D#3=ride
./target/release/seq --notes "C2/t240*60 F#2/t120*40 F#2/t120*35 D2/t240*50 F#2/t120*40 A#2/t120*45 C2/t120*55 F#2/t120*38 C2/t120*58 F#2/t120*40 D2/t240*52 F#2/t120*42 F#2/t120*38 C2/t240*60 F#2/t120*40 F#2/t120*35 D2/t240*50 F#2/t120*40 A#2/t120*45 C2/t240*58 D#3/t120*45 D#3/t120*42 D2/t240*55 F#2/t120*40 C2/t120*60 F#2/t240*38" --bpm 0 --ch 9 --patch 0 > /tmp/soft-prog-drums.jsonl

# Merge and create MIDI
cat /tmp/soft-prog-piano.jsonl /tmp/soft-prog-guitar.jsonl /tmp/soft-prog-bass.jsonl /tmp/soft-prog-drums.jsonl | \
    ./target/release/viz | \
    ./target/release/to-midi --out /tmp/soft-prog.mid

# Render with FluidSynth
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
fluidsynth -ni -F /tmp/soft-prog-raw.wav "$SF2" /tmp/soft-prog.mid

# Trim to 12 seconds with fade out
ffmpeg -y -i /tmp/soft-prog-raw.wav -t 12 -af "volume=1.8,afade=t=out:st=10:d=2" examples/demo-soft-prog.wav

echo "Created: examples/demo-soft-prog.wav (12 seconds)"
echo "Style: Soft Progressive Rock inspired by Erik Satie's Gnossiennes (1890)"
