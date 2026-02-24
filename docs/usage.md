# music-pipe-rs Usage Guide

This guide covers human and AI agent usage of music-pipe-rs for generating MIDI music.

## Quick Reference

```bash
# Generate a melody (auto-random seed)
seed | motif --notes 16 --bpm 120 | humanize | to-midi --out melody.mid

# Reproducible melody (explicit seed)
seed 12345 | motif --notes 16 --bpm 120 | humanize | to-midi --out melody.mid

# With visualization
seed 12345 | motif --notes 16 | viz | humanize | to-midi --out melody.mid

# Generate drum pattern
seed | euclid --steps 16 --pulses 4 --note 36 --repeat 4 | humanize | to-midi --out drums.mid
```

---

## AI Agent Instructions

### Overview

music-pipe-rs is a Unix-style pipeline for generating MIDI music. Each stage reads JSONL from stdin and writes JSONL to stdout. The final stage converts to a .mid file.

### Getting Help

```bash
# Get help for any stage
seed --help
motif --help
euclid --help
viz --help
humanize --help
to-midi --help
```

### Pipeline Pattern

```
seed [N] | [generator] | [transform...] | to-midi --out file.mid
```

**Seed** (always first):
- `seed` - Set random seed for entire pipeline (auto if omitted)

**Generators** (create events):
- `motif` - Melodic patterns (uses pipeline seed)
- `euclid` - Euclidean rhythms (drums, percussion)

**Transforms** (modify events):
- `transpose` - Shift pitch by semitones
- `scale` - Constrain to musical scale
- `humanize` - Add timing/velocity variation (uses pipeline seed)
- `viz` - Show sparkline/piano roll visualization

**Output**:
- `to-midi` - Write MIDI file

### Key Parameters

| Stage | Key Parameters |
|-------|----------------|
| seed | `[N]` positional (auto if omitted) |
| motif | `--base`, `--bpm`, `--notes`, `--complexity`, `--repeat`, `--patch`, `--dur`, `--rest-prob`, `--chord-prob`, `--swing` |
| euclid | `--steps`, `--pulses`, `--note`, `--bpm`, `--repeat`, `--vel-var`, `--accent`, `--ghost`, `--skip` |
| transpose | `--semitones` |
| scale | `--root`, `--mode` |
| humanize | `--jitter-ticks`, `--jitter-vel` |
| viz | `--roll` (piano roll mode), `--width` |
| to-midi | `--out` (required) |

### Timing Calculations

- Default ticks per quarter note (TPQ): 480
- At 120 BPM: 1 quarter note = 0.5 seconds
- motif eighth notes: 240 ticks = 0.25 seconds at 120 BPM
- euclid default step: 120 ticks = 0.125 seconds at 120 BPM

**Duration formulas:**
- Seconds = (ticks / TPQ) * (60 / BPM)
- For N seconds at BPM: repeats = N * BPM / 60 / notes_per_pattern

### MIDI Note Numbers

| Note | MIDI | Note | MIDI |
|------|------|------|------|
| C3 | 48 | C4 (middle) | 60 |
| D3 | 50 | D4 | 62 |
| E3 | 52 | E4 | 64 |
| F3 | 53 | F4 | 65 |
| G3 | 55 | G4 | 67 |
| A3 | 57 | A4 | 69 |
| B3 | 59 | B4 | 71 |

**Drum notes (channel 9):**
| Drum | Note |
|------|------|
| Kick | 36 |
| Snare | 38 |
| Closed Hi-hat | 42 |
| Open Hi-hat | 46 |
| Crash | 49 |
| Ride | 51 |

### Common Recipes

**5-second intro melody (auto-seed for variety):**
```bash
seed | motif --base 60 --bpm 120 --notes 16 --complexity 5 --repeat 2 \
  | scale --root C --mode major \
  | humanize --jitter-ticks 8 \
  | to-midi --out intro.mid
```

**Reproducible intro (same output every time):**
```bash
seed 12345 | motif --base 60 --bpm 120 --notes 16 --complexity 5 --repeat 2 \
  | scale --root C --mode major \
  | humanize --jitter-ticks 8 \
  | to-midi --out intro.mid
```

**10-second outro (slower, minor key):**
```bash
seed | motif --base 60 --bpm 80 --notes 20 --complexity 3 --repeat 2 --vel 80 \
  | scale --root A --mode minor \
  | humanize --jitter-ticks 12 --jitter-vel 15 \
  | to-midi --out outro.mid
```

**Layered drums (kick + hihat):**
```bash
seed 12345 | {
  euclid --steps 16 --pulses 4 --note 36 --ch 9 --bpm 120 --repeat 4;
  euclid --steps 16 --pulses 8 --note 42 --ch 9 --vel 60 --bpm 0 --repeat 4;
} | humanize | to-midi --out drums.mid
```

**Full arrangement (melody + bass + drums):**
```bash
# Use same seed for all parts
SEED=12345

# Melody (channel 0)
seed $SEED | motif --base 72 --bpm 110 --notes 16 --complexity 6 --repeat 2 --ch 0 > /tmp/mel.jsonl

# Bass (channel 1, octave lower)
seed $SEED | motif --base 48 --bpm 0 --notes 16 --complexity 3 --repeat 2 --ch 1 --vel 90 > /tmp/bass.jsonl

# Drums
seed $SEED | {
  euclid --steps 16 --pulses 4 --note 36 --ch 9 --bpm 0 --repeat 4;
  euclid --steps 16 --pulses 6 --note 42 --ch 9 --vel 55 --bpm 0 --repeat 4;
} > /tmp/drums.jsonl

# Combine and output
cat /tmp/mel.jsonl /tmp/bass.jsonl /tmp/drums.jsonl \
  | humanize \
  | to-midi --out arrangement.mid
```

---

## Stage Reference

### seed - Set Pipeline Seed

Sets a single random seed for the entire pipeline. All downstream stages (motif, humanize) use this seed for deterministic randomness.

```bash
seed [SEED]
```

| Argument | Description |
|----------|-------------|
| `[SEED]` | Optional seed value. If omitted, auto-generates and prints to stderr |

**Examples:**
```bash
# Auto-generate seed (prints to stderr for later use)
seed | motif --notes 16 | to-midi --out melody.mid

# Use specific seed for reproducibility
seed 12345 | motif --notes 16 | to-midi --out melody.mid
```

### motif - Generate Melodic Patterns

Generates seed-driven musical motifs. Uses the pipeline seed from `seed` stage.

```bash
motif [OPTIONS]
```

| Option | Default | Description |
|--------|---------|-------------|
| `--base` | 60 | Base MIDI note (60 = middle C) |
| `--ch` | 0 | MIDI channel (0-15) |
| `--patch` | (none) | MIDI program/instrument (0=piano, 32=acoustic bass, 33=electric bass) |
| `--tpq` | 480 | Ticks per quarter note |
| `--bpm` | 120 | Tempo in BPM (0 = no tempo event) |
| `--vel` | 96 | Velocity (1-127) |
| `--notes` | 8 | Number of notes to generate |
| `--complexity` | 5 | Melodic complexity (1-10). Higher = more variation |
| `--repeat` | 1 | Number of repetitions |
| `--dur` | 0.5 | Note duration multiplier (0.5=eighth, 1.0=quarter, 2.0=half) |
| `--rest-prob` | 0.0 | Probability of rest instead of note (0.0-1.0) |
| `--chord-prob` | 0.0 | Probability of chord instead of single note (0.0-1.0) |
| `--swing` | 0.0 | Swing amount for triplet feel (0.0=straight, 0.33=triplet) |

**Complexity:**
- 1-3: Simple, chord-focused melodies
- 4-6: Balanced melodic lines
- 7-10: Complex, adventurous patterns with larger intervals

**Common MIDI Programs:**
| Program | Instrument |
|---------|------------|
| 0 | Acoustic Grand Piano |
| 25 | Acoustic Guitar (steel) |
| 32 | Acoustic Bass |
| 33 | Electric Bass (finger) |
| 34 | Electric Bass (pick) |

**Examples:**
```bash
# Simple melody
seed 12345 | motif --base 60 --notes 16

# Complex, energetic pattern
seed 12345 | motif --base 72 --notes 24 --complexity 8 --bpm 140

# Simple, calm phrase
seed 12345 | motif --base 60 --notes 12 --complexity 2 --bpm 80

# Jazz piano with rests, chords, and swing
seed 12345 | motif --base 60 --notes 24 --rest-prob 0.25 --chord-prob 0.2 --swing 0.15

# Walking bass (quarter notes, acoustic bass)
seed 12345 | motif --base 36 --notes 16 --dur 1.0 --patch 32 --complexity 2
```

### euclid - Generate Euclidean Rhythms

Generates Euclidean rhythms - evenly distributed pulses across steps. Uses pipeline seed for variation parameters.

```bash
euclid [OPTIONS]
```

| Option | Default | Description |
|--------|---------|-------------|
| `--steps` | 16 | Steps in pattern |
| `--pulses` | 5 | Hits to distribute |
| `--rotation` | 0 | Shift pattern start |
| `--note` | 36 | MIDI note (36=kick) |
| `--ch` | 9 | Channel (9=drums) |
| `--vel` | 100 | Velocity |
| `--step-ticks` | 120 | Ticks per step |
| `--duration` | 0 | Note duration (0=auto) |
| `--bpm` | 120 | Tempo (0=no tempo event) |
| `--repeat` | 1 | Repetitions |
| `--vel-var` | 0 | Velocity variation range (+/-) |
| `--accent` | 0.0 | Probability of accent (1.3x velocity) |
| `--ghost` | 0.0 | Probability of ghost note (0.5x velocity) |
| `--skip` | 0.0 | Probability of skipping a hit |

**Common patterns:**
| Name | Steps | Pulses | Style |
|------|-------|--------|-------|
| 4-on-floor | 16 | 4 | House kick |
| Tresillo | 8 | 3 | Cuban/Latin |
| Cinquillo | 8 | 5 | Afro-Cuban |
| Bossa | 16 | 5 | Bossa nova |

**Examples:**
```bash
# House kick pattern
seed | euclid --steps 16 --pulses 4 --note 36

# Hi-hat pattern with ghost notes
seed | euclid --steps 16 --pulses 8 --note 42 --vel 60 --ghost 0.2

# Snare on 2 and 4 with accents
seed | euclid --steps 16 --pulses 2 --note 38 --rotation 4 --accent 0.15

# Human-feel kick with velocity variation and occasional skips
seed | euclid --steps 8 --pulses 3 --note 36 --vel 80 --vel-var 10 --skip 0.08
```

### transpose - Shift Pitch

Shifts all notes by N semitones.

```bash
transpose --semitones <N>
```

| Option | Description |
|--------|-------------|
| `--semitones` | Semitones to shift (negative = down) |

**Examples:**
```bash
# Up a perfect fifth (+7)
seed | motif | transpose --semitones 7

# Down an octave (-12)
seed | motif | transpose --semitones -12
```

### scale - Constrain to Scale

Snaps notes to the nearest degree of a musical scale.

```bash
scale [OPTIONS]
```

| Option | Default | Description |
|--------|---------|-------------|
| `--root` | C | Root note (C, C#, D, etc.) |
| `--mode` | major | Scale type |
| `--snap` | nearest | Direction: nearest, up, down |

**Modes:**
- `major` - Bright, happy (Ionian)
- `minor` - Sad, dark (Aeolian)
- `dorian` - Minor with raised 6th
- `phrygian` - Spanish, exotic
- `lydian` - Dreamy, floating
- `mixolydian` - Bluesy major
- `pentatonic` - Major pentatonic
- `pentatonic-minor` - Blues/rock pentatonic
- `blues` - Blues scale
- `harmonic-minor` - Classical, dramatic

**Examples:**
```bash
# Constrain to C major
seed | motif | scale --root C --mode major

# Constrain to A minor pentatonic
seed | motif | scale --root A --mode pentatonic-minor
```

### humanize - Add Variation

Adds human-like timing and velocity variation. Uses the pipeline seed from `seed` stage.

```bash
humanize [OPTIONS]
```

| Option | Default | Description |
|--------|---------|-------------|
| `--jitter-ticks` | 8 | Max timing variation (+/-) |
| `--jitter-vel` | 10 | Max velocity variation (+/-) |

**Examples:**
```bash
# Subtle humanization
seed 12345 | motif | humanize --jitter-ticks 5 --jitter-vel 5

# More loose/human feel
seed 12345 | motif | humanize --jitter-ticks 15 --jitter-vel 20
```

### viz - Visualize Notes

Prints a sparkline or piano roll visualization to stderr, passes events through unchanged.

```bash
viz [OPTIONS]
```

| Option | Default | Description |
|--------|---------|-------------|
| `--width` | 60 | Sparkline width |
| `--roll` | false | Show piano roll instead of sparkline |

**Examples:**
```bash
# Sparkline (default)
seed 12345 | motif --notes 16 | viz | to-midi --out out.mid
# Output: C5 ▁▄▄█▇█▁▁▁▂▂▃▄▁▂▁ G6

# Piano roll
seed 12345 | motif --notes 16 | viz --roll | to-midi --out out.mid
# Output:
# G5 │·····█··········│
# F5 │███··█··········│
# E5 │···█···█████████│
```

### to-midi - Write MIDI File

Converts JSONL events to a standard MIDI file.

```bash
to-midi --out <PATH> [OPTIONS]
```

| Option | Default | Description |
|--------|---------|-------------|
| `--out` | (required) | Output file path |
| `--tpq` | 480 | Ticks per quarter note |

**Examples:**
```bash
seed | motif | to-midi --out melody.mid
seed | euclid | to-midi --out drums.mid
```

---

## Video Intro/Outro Music Recipes

### Bright, Energetic Intro (5 seconds)

```bash
seed 42 | motif --base 72 --bpm 130 --notes 16 --complexity 6 --repeat 2 --vel 100 \
  | scale --root C --mode major \
  | humanize --jitter-ticks 6 \
  | to-midi --out bright-intro.mid
```

### Calm, Professional Intro (8 seconds)

```bash
seed 55 | motif --base 60 --bpm 90 --notes 20 --complexity 4 --repeat 2 --vel 80 \
  | scale --root G --mode major \
  | humanize --jitter-ticks 10 --jitter-vel 8 \
  | to-midi --out calm-intro.mid
```

### Dramatic/Cinematic Intro (6 seconds)

```bash
seed 77 | motif --base 48 --bpm 100 --notes 16 --complexity 5 --repeat 2 --vel 90 \
  | scale --root D --mode harmonic-minor \
  | humanize --jitter-ticks 8 \
  | to-midi --out dramatic-intro.mid
```

### Upbeat Outro with Drums (10 seconds)

```bash
SEED=88

# Melody
seed $SEED | motif --base 67 --bpm 120 --notes 20 --complexity 5 --repeat 2 --ch 0 --vel 85 > /tmp/mel.jsonl

# Drums
seed $SEED | {
  euclid --steps 16 --pulses 4 --note 36 --ch 9 --bpm 0 --repeat 5;
  euclid --steps 16 --pulses 8 --note 42 --ch 9 --vel 50 --bpm 0 --repeat 5;
} > /tmp/drm.jsonl

# Combine
cat /tmp/mel.jsonl /tmp/drm.jsonl \
  | scale --root G --mode major \
  | humanize \
  | to-midi --out upbeat-outro.mid
```

### Mellow Fade-Out Outro (12 seconds)

```bash
seed 33 | motif --base 60 --bpm 70 --notes 24 --complexity 3 --repeat 2 --vel 70 \
  | scale --root A --mode minor \
  | humanize --jitter-ticks 15 --jitter-vel 12 \
  | to-midi --out mellow-outro.mid
```

---

## Playback

### Using FluidSynth (recommended)

```bash
# Install
brew install fluid-synth  # macOS
apt install fluidsynth    # Linux

# Play directly
fluidsynth -a coreaudio -i /path/to/soundfont.sf2 output.mid

# Convert MIDI to WAV
fluidsynth -ni -F output.wav /path/to/soundfont.sf2 input.mid

# Then play WAV
afplay output.wav  # macOS
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No output | Check pipeline with `seed \| motif \| head` to see JSONL |
| Notes out of range | Use `transpose` to shift octaves |
| Sounds robotic | Increase `humanize --jitter-ticks` |
| Wrong key | Use `scale --root X --mode Y` |
| Too fast/slow | Adjust `--bpm` on generator |
| Wrong length | Calculate `--repeat` based on timing |

---

## Event Format Reference

Each event is a JSON object on its own line (JSONL):

```json
{"type":"Seed","seed":12345}
{"type":"Tempo","t":0,"bpm":120}
{"type":"ProgramChange","t":0,"ch":0,"program":32}
{"type":"NoteOn","t":0,"ch":0,"key":60,"vel":96}
{"type":"NoteOff","t":240,"ch":0,"key":60}
{"type":"End","t":480}
```

| Field | Description |
|-------|-------------|
| `type` | Event type: Seed, Tempo, ProgramChange, NoteOn, NoteOff, End |
| `seed` | Pipeline seed value (Seed only) |
| `t` | Absolute time in ticks |
| `bpm` | Beats per minute (Tempo only) |
| `program` | MIDI program/instrument 0-127 (ProgramChange only) |
| `ch` | MIDI channel 0-15 |
| `key` | MIDI note number 0-127 |
| `vel` | Velocity 1-127 |
