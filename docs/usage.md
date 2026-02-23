# music-pipe-rs Usage Guide

This guide covers human and AI agent usage of music-pipe-rs for generating MIDI music.

## Quick Reference

```bash
# Generate a 10-second intro melody
motif --base 60 --bpm 120 --pattern arpeggio --repeat 8 \
  | scale --root C --mode major \
  | humanize --seed 42 \
  | to-midi --out intro.mid

# Generate drum pattern
euclid --steps 16 --pulses 4 --note 36 --repeat 4 \
  | humanize --seed 123 \
  | to-midi --out drums.mid
```

---

## AI Agent Instructions

### Overview

music-pipe-rs is a Unix-style pipeline for generating MIDI music. Each stage reads JSONL from stdin and writes JSONL to stdout. The final stage converts to a .mid file.

### Getting Help

```bash
# Get help for any stage
motif --help
euclid --help
transpose --help
scale --help
humanize --help
to-midi --help

# Quick help (shorter)
motif -h
```

### Pipeline Pattern

```
[generator] | [transform...] | to-midi --out file.mid
```

**Generators** (create events):
- `motif` - Melodic patterns (arpeggio, scale, chord)
- `euclid` - Euclidean rhythms (drums, percussion)

**Transforms** (modify events):
- `transpose` - Shift pitch by semitones
- `scale` - Constrain to musical scale
- `humanize` - Add timing/velocity variation

**Output**:
- `to-midi` - Write MIDI file

### Key Parameters

| Stage | Key Parameters |
|-------|----------------|
| motif | `--base` (note), `--bpm`, `--pattern`, `--repeat` |
| euclid | `--steps`, `--pulses`, `--note`, `--bpm`, `--repeat` |
| transpose | `--semitones` |
| scale | `--root`, `--mode` |
| humanize | `--seed`, `--jitter-ticks`, `--jitter-vel` |
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

**5-second intro melody:**
```bash
motif --base 60 --bpm 120 --pattern arpeggio --repeat 5 \
  | scale --root C --mode major \
  | humanize --seed 42 --jitter-ticks 8 \
  | to-midi --out intro.mid
```

**10-second outro (slower, fading feel):**
```bash
motif --base 60 --bpm 80 --pattern arpeggio --repeat 8 --vel 80 \
  | scale --root A --mode minor \
  | humanize --seed 99 --jitter-ticks 12 --jitter-vel 15 \
  | to-midi --out outro.mid
```

**Layered drums (kick + hihat):**
```bash
{
  euclid --steps 16 --pulses 4 --note 36 --ch 9 --bpm 120 --repeat 4;
  euclid --steps 16 --pulses 8 --note 42 --ch 9 --vel 60 --bpm 0 --repeat 4;
} | humanize --seed 77 | to-midi --out drums.mid
```

**Full arrangement (melody + bass + drums):**
```bash
# Melody
motif --base 72 --bpm 110 --pattern arpeggio --repeat 6 --ch 0 > /tmp/mel.jsonl

# Bass (octave lower, channel 1)
motif --base 48 --bpm 0 --pattern arpeggio --repeat 6 --ch 1 --vel 90 > /tmp/bass.jsonl

# Drums
{
  euclid --steps 16 --pulses 4 --note 36 --ch 9 --bpm 0 --repeat 3;
  euclid --steps 16 --pulses 6 --note 42 --ch 9 --vel 55 --bpm 0 --repeat 3;
} > /tmp/drums.jsonl

# Combine and output
cat /tmp/mel.jsonl /tmp/bass.jsonl /tmp/drums.jsonl \
  | humanize --seed 42 \
  | to-midi --out arrangement.mid
```

---

## Stage Reference

### motif - Generate Melodic Patterns

Generates musical motifs as JSONL events.

```bash
motif [OPTIONS]
```

| Option | Default | Description |
|--------|---------|-------------|
| `--base` | 60 | Base MIDI note (60 = middle C) |
| `--ch` | 0 | MIDI channel (0-15) |
| `--tpq` | 480 | Ticks per quarter note |
| `--bpm` | 120 | Tempo in BPM |
| `--vel` | 96 | Velocity (1-127) |
| `--pattern` | arpeggio | Pattern type: arpeggio, scale, chord |
| `--repeat` | 1 | Number of repetitions |

**Patterns:**
- `arpeggio` - Root, 3rd, 5th, octave (4 notes)
- `scale` - Major scale up one octave (8 notes)
- `chord` - Root, 3rd, 5th (3 notes, sequential)

**Examples:**
```bash
# Simple C major arpeggio
motif --base 60 --pattern arpeggio

# G major scale at 140 BPM
motif --base 67 --pattern scale --bpm 140

# Repeated pattern for 10 seconds at 120 BPM
# 4 notes per pattern, eighth notes = 1 second per pattern
motif --base 60 --bpm 120 --repeat 10
```

### euclid - Generate Euclidean Rhythms

Generates Euclidean rhythms - evenly distributed pulses across steps.

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
euclid --steps 16 --pulses 4 --note 36

# Hi-hat pattern
euclid --steps 16 --pulses 8 --note 42 --vel 60

# Snare on 2 and 4
euclid --steps 16 --pulses 2 --note 38 --rotation 4
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
motif | transpose --semitones 7

# Down an octave (-12)
motif | transpose --semitones -12
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
motif | scale --root C --mode major

# Constrain to A minor pentatonic
motif | scale --root A --mode pentatonic-minor

# Snap up only (never lower)
motif | scale --root G --mode dorian --snap up
```

### humanize - Add Variation

Adds human-like timing and velocity variation using deterministic RNG.

```bash
humanize [OPTIONS]
```

| Option | Default | Description |
|--------|---------|-------------|
| `--seed` | 42 | Random seed (same seed = same output) |
| `--jitter-ticks` | 8 | Max timing variation (+/-) |
| `--jitter-vel` | 10 | Max velocity variation (+/-) |

**Examples:**
```bash
# Subtle humanization
humanize --seed 42 --jitter-ticks 5 --jitter-vel 5

# More loose/human feel
humanize --seed 123 --jitter-ticks 15 --jitter-vel 20

# Reproducible output (same seed)
motif | humanize --seed 999 | to-midi --out test.mid
# Running again produces identical output
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
motif | to-midi --out melody.mid
euclid | to-midi --out drums.mid
```

---

## Video Intro/Outro Music Recipes

### Bright, Energetic Intro (5 seconds)

```bash
motif --base 72 --bpm 130 --pattern arpeggio --repeat 6 --vel 100 \
  | scale --root C --mode major \
  | humanize --seed 42 --jitter-ticks 6 \
  | to-midi --out bright-intro.mid
```

### Calm, Professional Intro (8 seconds)

```bash
motif --base 60 --bpm 90 --pattern arpeggio --repeat 6 --vel 80 \
  | scale --root G --mode major \
  | humanize --seed 55 --jitter-ticks 10 --jitter-vel 8 \
  | to-midi --out calm-intro.mid
```

### Dramatic/Cinematic Intro (6 seconds)

```bash
motif --base 48 --bpm 100 --pattern scale --repeat 4 --vel 90 \
  | scale --root D --mode harmonic-minor \
  | humanize --seed 77 --jitter-ticks 8 \
  | to-midi --out dramatic-intro.mid
```

### Upbeat Outro with Drums (10 seconds)

```bash
# Melody
motif --base 67 --bpm 120 --pattern arpeggio --repeat 10 --ch 0 --vel 85 > /tmp/mel.jsonl

# Drums
{
  euclid --steps 16 --pulses 4 --note 36 --ch 9 --bpm 0 --repeat 5;
  euclid --steps 16 --pulses 8 --note 42 --ch 9 --vel 50 --bpm 0 --repeat 5;
} > /tmp/drm.jsonl

# Combine
cat /tmp/mel.jsonl /tmp/drm.jsonl \
  | scale --root G --mode major \
  | humanize --seed 88 \
  | to-midi --out upbeat-outro.mid
```

### Mellow Fade-Out Outro (12 seconds)

```bash
motif --base 60 --bpm 70 --pattern arpeggio --repeat 8 --vel 70 \
  | scale --root A --mode minor \
  | humanize --seed 33 --jitter-ticks 15 --jitter-vel 12 \
  | to-midi --out mellow-outro.mid
```

### Tech/Electronic Intro (6 seconds)

```bash
{
  # Synth arpeggio
  motif --base 60 --bpm 128 --pattern arpeggio --repeat 8 --ch 0 --vel 90;
  # Bass pulse
  euclid --steps 16 --pulses 4 --note 36 --ch 1 --bpm 0 --repeat 4 --vel 100;
  # Hi-hat
  euclid --steps 16 --pulses 8 --note 42 --ch 9 --bpm 0 --repeat 4 --vel 45;
} | scale --root C --mode pentatonic-minor \
  | humanize --seed 64 --jitter-ticks 4 \
  | to-midi --out tech-intro.mid
```

---

## Playback

### Using FluidSynth (recommended)

```bash
# Install
brew install fluid-synth  # macOS
apt install fluidsynth    # Linux

# Play with soundfont
fluidsynth -a coreaudio -ni /path/to/soundfont.sf2 output.mid

# Common soundfont locations
# ~/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2
# /usr/share/sounds/sf2/
```

### Converting to Audio

```bash
# MIDI to WAV using FluidSynth
fluidsynth -F output.wav -ni soundfont.sf2 input.mid

# MIDI to MP3 (requires ffmpeg)
fluidsynth -F output.wav -ni soundfont.sf2 input.mid
ffmpeg -i output.wav output.mp3
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No output | Check pipeline with `motif \| head` to see JSONL |
| Notes out of range | Use `transpose` to shift octaves |
| Sounds robotic | Increase `humanize --jitter-ticks` |
| Wrong key | Use `scale --root X --mode Y` |
| Too fast/slow | Adjust `--bpm` on first generator |
| Wrong length | Calculate `--repeat` based on timing |

### Debugging Pipeline

```bash
# See raw events
motif | head -10

# Count events
motif --repeat 4 | wc -l

# Pretty-print JSON
motif | jq .

# Check timing
motif | jq '.t'
```

---

## Event Format Reference

Each event is a JSON object on its own line (JSONL):

```json
{"type":"Tempo","t":0,"bpm":120}
{"type":"NoteOn","t":0,"ch":0,"key":60,"vel":96}
{"type":"NoteOff","t":240,"ch":0,"key":60}
{"type":"End","t":480}
```

| Field | Description |
|-------|-------------|
| `type` | Event type: Tempo, NoteOn, NoteOff, End |
| `t` | Absolute time in ticks |
| `bpm` | Beats per minute (Tempo only) |
| `ch` | MIDI channel 0-15 |
| `key` | MIDI note number 0-127 |
| `vel` | Velocity 1-127 |
