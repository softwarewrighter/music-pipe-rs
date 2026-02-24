#!/bin/bash
# Jazz trio demo - piano, bass, drums
# Plays each instrument solo, then the full trio

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${SCRIPT_DIR}/target/release"
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"

SEED=7777

play_midi() {
    local midi_file="$1"
    local wav_file="${midi_file%.mid}.wav"
    if [[ -f "$SF2" ]]; then
        fluidsynth -ni -F "$wav_file" "$SF2" "$midi_file" 2>/dev/null
        afplay "$wav_file"
    else
        echo "Soundfont not found: $SF2"
    fi
}

echo "=== Jazz Trio Demo ==="
echo ""

# Piano - bluesy, with rests, chords, and swing
# Using: rest-prob for space, chord-prob for voicings, swing for triplet feel
echo "Generating piano (ch 0)..."
"${BIN}/seed" $SEED \
  | "${BIN}/motif" --base 60 --notes 24 --complexity 7 --bpm 130 --ch 0 --vel 70 \
      --repeat 2 --rest-prob 0.25 --chord-prob 0.2 --swing 0.15 --dur 0.75 \
  | "${BIN}/scale" --root C --mode blues \
  | "${BIN}/viz" \
  > /tmp/piano.jsonl

# Walking bass - quarter notes, simple, steady (patch 32 = acoustic bass, plucked)
# Using: dur 1.0 for quarter notes (slower walk)
echo "Generating bass (ch 1)..."
"${BIN}/seed" $((SEED+1)) \
  | "${BIN}/motif" --base 36 --notes 24 --complexity 2 --bpm 0 --ch 1 --vel 95 \
      --repeat 2 --patch 32 --dur 1.0 \
  | "${BIN}/scale" --root C --mode minor \
  | "${BIN}/viz" \
  > /tmp/bass.jsonl

# Drums - with dynamics and variation
# Using: vel-var, accent, ghost, skip for human feel
echo "Generating drums (ch 9)..."

# Hi-hat - steady pulse with ghost notes
"${BIN}/seed" $SEED \
  | "${BIN}/euclid" --steps 16 --pulses 8 --note 42 --ch 9 --bpm 130 --repeat 12 \
      --vel 50 --vel-var 10 --ghost 0.2 \
  > /tmp/drums-hihat.jsonl

# Snare on 2 and 4 with accents
"${BIN}/seed" $((SEED+2)) \
  | "${BIN}/euclid" --steps 8 --pulses 2 --note 38 --ch 9 --bpm 0 --repeat 24 \
      --vel 65 --vel-var 8 --accent 0.15 --rotation 2 \
  > /tmp/drums-snare.jsonl

# Kick - solid foundation with occasional skip for groove
"${BIN}/seed" $((SEED+3)) \
  | "${BIN}/euclid" --steps 8 --pulses 3 --note 36 --ch 9 --bpm 0 --repeat 24 \
      --vel 80 --vel-var 5 --skip 0.08 \
  > /tmp/drums-kick.jsonl

# Ride cymbal - jazz pattern with swing feel
"${BIN}/seed" $((SEED+4)) \
  | "${BIN}/euclid" --steps 12 --pulses 5 --note 51 --ch 9 --bpm 0 --repeat 16 \
      --vel 45 --vel-var 12 --accent 0.1 --ghost 0.15 \
  > /tmp/drums-ride.jsonl

# Combine drum parts
cat /tmp/drums-hihat.jsonl /tmp/drums-snare.jsonl /tmp/drums-kick.jsonl /tmp/drums-ride.jsonl \
  | "${BIN}/viz" \
  > /tmp/drums.jsonl

# Stats
echo ""
echo "Events:"
echo "  Piano: $(grep -c NoteOn /tmp/piano.jsonl)"
echo "  Bass:  $(grep -c NoteOn /tmp/bass.jsonl)"
echo "  Drums: $(grep -c NoteOn /tmp/drums.jsonl)"

echo ""
echo "--- Playing Piano Solo ---"
cat /tmp/piano.jsonl | "${BIN}/to-midi" --out /tmp/piano-solo.mid
play_midi /tmp/piano-solo.mid

echo ""
echo "--- Playing Bass Solo ---"
# Add tempo for bass solo playback
(echo '{"type":"Tempo","t":0,"bpm":130}'; cat /tmp/bass.jsonl) \
  | "${BIN}/to-midi" --out /tmp/bass-solo.mid
play_midi /tmp/bass-solo.mid

echo ""
echo "--- Playing Drums Solo ---"
cat /tmp/drums.jsonl | "${BIN}/to-midi" --out /tmp/drums-solo.mid
play_midi /tmp/drums-solo.mid

echo ""
echo "--- Playing Full Trio ---"
cat /tmp/piano.jsonl /tmp/bass.jsonl /tmp/drums.jsonl \
  | "${BIN}/humanize" --jitter-ticks 12 --jitter-vel 8 \
  | "${BIN}/to-midi" --out /tmp/jazz-trio.mid
play_midi /tmp/jazz-trio.mid

echo ""
echo "=== Done ==="
echo "MIDI files in /tmp: piano-solo.mid, bass-solo.mid, drums-solo.mid, jazz-trio.mid"
