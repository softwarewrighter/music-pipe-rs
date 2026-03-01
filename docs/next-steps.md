# Next Steps - Session State

**Date:** 2026-03-01

## What Was Completed

1. **mid2seq utility created and committed**
   - Location: `crates/mid2seq/`
   - Extracts seq notation from MIDI files
   - Usage: `./target/release/mid2seq input.mid --bars 8`
   - Output: `NOTES='[A4,A5,A6]/t28*89 ...'`

2. **Documentation updated and pushed**
   - README.md: Added trim, rubato, mid2seq
   - docs/usage.md: Added seq, trim, rubato, mid2seq docs
   - docs/status.md: Updated to feature-complete status
   - CLAUDE.md: Added soundfont path

## What Was In Progress (Incomplete)

Testing mid2seq on complex MIDI file (Toccata and Fugue):
- File: `~/Downloads/Toccata and Fugue in D minor, BWV 565. (Busoni Piano Arr.mid`
- mid2seq extraction works correctly
- MIDI generation works
- Audio rendering was producing silence due to wrong soundfont path

## Key Information

**Soundfont (MUST USE):**
```bash
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
```

**Test mid2seq properly:**
```bash
cd /Users/mike/github/softwarewrighter/music-pipe-rs
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"

# Extract 8 bars
eval $(./target/release/mid2seq ~/Downloads/"Toccata and Fugue in D minor, BWV 565. (Busoni Piano Arr.mid" --bars 8)

# Generate and render
./target/release/seq --notes "$NOTES" --bpm 72 --patch 0 | ./target/release/to-midi --out /tmp/toccata.mid
fluidsynth -ni -F /tmp/toccata.wav "$SF2" /tmp/toccata.mid
ffplay -autoexit /tmp/toccata.wav
```

## Git Status

- All changes committed and pushed
- Branch: main
- Last commit: docs update for seq, trim, rubato, mid2seq
