#!/bin/bash
# =============================================================================
# Soft Cello Duet - inspired by Erik Satie's Gnossiennes (1890)
# =============================================================================
#
# SOURCE: Erik Satie - Gnossiennes (composed 1890-1897)
#         Satie (1866-1925) was a contemporary of Claude Debussy, but far more
#         obscure in his time. His Gnossiennes are modal, free-flowing pieces
#         without bar lines or time signatures - revolutionary for 1890.
#
# ADAPTATION: This piece reimagines Satie's modal harmonies and suspended
#             dreamlike atmosphere as a contemplative cello duet:
#             - D Dorian mode (Satie's favorite mode)
#             - Slow tempo (60 BPM) preserving the contemplative feel
#             - Rich cello timbres with expressive dynamics
#             - Interweaving melodic lines between the two cellos
#
# COPYRIGHT: Satie died in 1925, so his work entered public domain in 1995.
#            This arrangement is an original interpretation.
#
# Instruments:
#   Ch 0: Cello 1 (melody) - patch 42
#   Ch 1: Cello 2 (harmony/countermelody) - patch 42
#
# Style: D Dorian mode, 60 BPM, legato phrasing, intimate chamber music

set -e
cd "$(dirname "$0")/.."

# Cello 1 - Primary melody (adapted from guitar line, shifted to cello range)
# Expressive, singing line in the tenor/alto register
./target/release/seq --notes "R/t480 A3/t360*70 R/t120 G3/t120*65 F3/t120*67 E3/t480*72 R/t240 D3/t240*68 E3/t120*65 F3/t240*67 R/t120 G3/t360*70 R/t240 A3/t480*75 R/t120 G3/t180*68 E3/t180*65 D3/t600*72" --bpm 60 --ch 0 --patch 42 > /tmp/cello-soft-melody.jsonl

# Cello 2 - Harmony/countermelody (adapted from piano chords, arpeggiated as single notes)
# Lower register, providing harmonic foundation with gentle movement
./target/release/seq --notes "R/t60 D2/t420*60 R/t240 A2/t180*55 R/t60 D2/t480*62 R/t240 E2/t420*58 R/t60 F2/t240*60 R/t120 A2/t360*55 R/t120 D2/t480*62 R/t240 C2/t420*58 R/t60 D2/t600*65" --bpm 0 --ch 1 --patch 42 > /tmp/cello-soft-harmony.jsonl

# Merge and create MIDI
cat /tmp/cello-soft-melody.jsonl /tmp/cello-soft-harmony.jsonl | \
    ./target/release/viz | \
    ./target/release/to-midi --out /tmp/cello-soft.mid

# Render with FluidSynth
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
fluidsynth -ni -F /tmp/cello-soft-raw.wav "$SF2" /tmp/cello-soft.mid

# Trim to 12 seconds with fade out (same duration as soft-prog)
ffmpeg -y -i /tmp/cello-soft-raw.wav -t 12 -af "volume=1.8,afade=t=out:st=10:d=2" examples/demo-cello-soft.wav

echo "Created: examples/demo-cello-soft.wav (12 seconds)"
echo "Style: Soft Cello Duet inspired by Erik Satie's Gnossiennes (1890)"
